--[[
packet format:
packetID: random string to differentiate
packetType:
 - 0: unreliable
 - 1: reliable, requires ack
 - 2: ack packet
destination: end destination hostname
sender: original sender of packet
data: the actual packet data, duh.
]]--

local listeners = {}
local timers = {}

local cfg = {}

local event = require "event"
local component = require "component"
local computer = require "computer"
local serial = require "serialization"

local hostname = computer.address():sub(1,8)
local modems = {}

cfg.debug = false
cfg.port = 4096
cfg.retry = 10
cfg.retrycount = 3
cfg.route = true

--[[
LKR format:
address {
 local hardware address
 remote hardware address
 time last received
 vlan
}
]]--
cfg.sroutes = {}
local rcache = setmetatable({},{__index=cfg.sroutes})
cfg.rctime = 15

--[[
packet queue format:
{
 packetID,
 packetType
 destination,
 data,
 timestamp,
 attempts
}
]]--
local pqueue = {}

-- packet cache: [packet ID]=uptime
local pcache = {}
cfg.pctime = 30

--[[
vlans format:
["address"] = {
  [id] = false, -- no NAT
  [id] = "suffix", -- NAT suffix
  ...
}
]]
cfg.vlans = {}

local function dprint(...)
 if cfg.debug then
  print(...)
 end
end

local function saveconfig()
 local f = io.open("/etc/minitel.cfg","wb")
 if f then
  f:write(serial.serialize(cfg))
  f:close()
 end
end
local function loadconfig()
 local f = io.open("/etc/minitel.cfg","rb")
 if f then
  local newcfg = serial.unserialize(f:read("*a"))
  f:close()
  for k,v in pairs(newcfg) do
   cfg[k] = v
  end
  rcache = setmetatable(rcache,{__index=cfg.sroutes})
 else
  saveconfig()
 end
end

function start()
 loadconfig()
 local f=io.open("/etc/hostname","rb")
 if f then
  hostname = f:read()
  f:close()
 end
 print("Hostname: "..hostname)

 if next(listeners) ~= nil then return end

 modems={}
 for a,t in component.list("modem") do
  for vlan,suffix in pairs(cfg.vlans[a] or {[cfg.port]=false}) do
   modems[#modems+1] = setmetatable({vlan=vlan,suffix=suffix or nil},{__index=component.proxy(a)})
  end
 end
 for k,v in ipairs(modems) do
  v.open(v.vlan)
  print("Opened port "..v.vlan.." on "..v.address)
 end
 for a,t in component.list("tunnel") do
  modems[#modems+1] = setmetatable({vlan=0, suffix=((vlans[a] or {})[0] or {}).suffix},{__index=component.proxy(a)})
 end
 
 local function genPacketID()
  local npID = ""
  for i = 1, 16 do
   npID = npID .. string.char(math.random(32,126))
  end
  return npID
 end

 local function checkVlan(addr,port)
  for k,v in ipairs(modems) do
   if v.address == addr and v.vlan == port then
    return v
   end
  end
 end
 
 local function sendPacket(packetID,packetType,dest,sender,vPort,data,repeatingFrom)
  if rcache[dest] then
   dprint("Cached", rcache[dest][1],"send",rcache[dest][2],rcache[dest][4],packetID,packetType,dest,sender,vPort,data)
   -- strip NAT suffix for sending without messing with the cache
   local vlan = checkVlan(rcache[dest][1], rcache[dest][4])
   local ndest = (vlan and vlan.suffix and dest:sub(-#vlan.suffix) == vlan.suffix and dest:sub(1,#vlan.suffix-1)) or dest
   if vlan ~= repeatingFrom or (vlan.type ~= "tunnel" and vlan.isWireless()) then
    if vlan.type == "modem" then
     vlan.send(rcache[dest][2],rcache[dest][4],packetID,packetType,ndest,sender,vPort,data)
    elseif vlan.type == "tunnel" then
     vlan.send(packetID,packetType,ndest,sender,vPort,data)
    end
   end
  else
   dprint("Not cached", cfg.port,packetID,packetType,dest,sender,vPort,data)
   for k,v in pairs(modems) do
    -- do not send message back to the wired or linked modem it came from
    -- the check for tunnels is for short circuiting `v.isWireless()`, which does not exist for tunnels
    if (v ~= repeatingFrom or (v.type ~= "tunnel" and v.isWireless()))
    -- also, if a NAT suffix is set, check the packet matches before broadcasting
    and (not v.suffix or dest:sub(-#v.suffix) == v.suffix) then
     -- strip NAT suffix before broadcast
     local ndest = (v.suffix and dest:sub(-#v.suffix) == v.suffix and dest:sub(1,#v.suffix-1)) or dest
     if v.type == "modem" then
      v.broadcast(v.vlan,packetID,packetType,ndest,sender,vPort,data)
     elseif v.type == "tunnel" then
      v.send(packetID,packetType,ndest,sender,vPort,data)
     end
    end
   end
  end
 end
 
 local function pruneCache()
  for k,v in pairs(rcache) do
   dprint(k,v[3],computer.uptime())
   if v[3] < computer.uptime() then
    rcache[k] = nil
    dprint("pruned "..k.." from routing cache")
   end
  end
  for k,v in pairs(pcache) do
   if v < computer.uptime() then
    pcache[k] = nil
    dprint("pruned "..k.." from packet cache")
   end
  end
 end

 local function checkPCache(packetID)
  dprint(packetID)
  for k,v in pairs(pcache) do
   dprint(k)
   if k == packetID then return true end
  end
  return false
 end

 local function processPacket(_,localModem,from,pport,_,packetID,packetType,dest,sender,vPort,data)
  pruneCache()
  -- add the NAT suffix
  local vlan = checkVlan(localModem, pport)
  sender = sender..(vlan.suffix or "")
  if vlan or pport == 0 then -- for linked cards
   dprint(cfg.port,vPort,packetType,dest)
   if checkPCache(packetID) then return end
   -- add the packet ID to the pcache
   pcache[packetID] = computer.uptime()+cfg.pctime
   -- add the sender to the rcache
   dprint("rcache: "..sender..":", localModem,from,computer.uptime(),vlan.vlan)
   rcache[sender] = cfg.sroutes[sender] == nil and {localModem,from,computer.uptime()+cfg.rctime,vlan.vlan} or nil
   if dest == hostname then
    if packetType == 1 then
     sendPacket(genPacketID(),2,sender,hostname,vPort,packetID)
    end
    if packetType == 2 then
     dprint("Dropping "..data.." from queue")
     pqueue[data] = nil
     computer.pushSignal("net_ack",data)
    end
    if packetType ~= 2 then
     computer.pushSignal("net_msg",sender,vPort,data)
    end
   elseif dest:sub(1,1) == "~" then -- broadcasts start with ~
    computer.pushSignal("net_broadcast",sender,vPort,data)
   elseif cfg.route then -- repeat packets if route is enabled
    sendPacket(packetID,packetType,dest,sender,vPort,data,vlan)
   end
  end
 end
 
 listeners["modem_message"]=processPacket
 event.listen("modem_message",processPacket)
 print("Started packet listening daemon: "..tostring(processPacket))
 
 local function queuePacket(_,ptype,to,vPort,data,npID)
  npID = npID or genPacketID()
  if to == hostname or to == "localhost" then
   computer.pushSignal("net_msg",to,vPort,data)
   computer.pushSignal("net_ack",npID)
   return
  end
  pqueue[npID] = {ptype,to,vPort,data,0,0}
  dprint(npID,table.unpack(pqueue[npID]))
 end
 
 listeners["net_send"]=queuePacket
 event.listen("net_send",queuePacket)
 print("Started packet queueing daemon: "..tostring(queuePacket))
 
 local function packetPusher()
  for k,v in pairs(pqueue) do
   if v[5] < computer.uptime() then
    dprint(k,v[1],v[2],hostname,v[3],v[4])
    sendPacket(k,v[1],v[2],hostname,v[3],v[4])
    if v[1] ~= 1 or v[6] == cfg.retrycount then
     pqueue[k] = nil
    else
     pqueue[k][5]=computer.uptime()+cfg.retry
     pqueue[k][6]=pqueue[k][6]+1
    end
   end
  end
 end
 
 timers[#timers+1]=event.timer(0,packetPusher,math.huge)
 print("Started packet pusher: "..tostring(timers[#timers]))
 
 listeners["net_ack"]=dprint
 event.listen("net_ack",dprint)
end

function stop()
 for k,v in pairs(listeners) do
  event.ignore(k,v)
  listeners[k] = nil
  print("Stopped listener: "..tostring(v))
 end
 for k,v in pairs(timers) do
  event.cancel(v)
  timers[k] = nil
  print("Stopped timer: "..tostring(v))
 end
end

function set(k,v)
 if type(cfg[k]) == "string" then
  cfg[k] = v
 elseif type(cfg[k]) == "number" then
  cfg[k] = tonumber(v)
 elseif type(cfg[k]) == "boolean" then
  if v:lower():sub(1,1) == "t" then
   cfg[k] = true
  else
   cfg[k] = false
  end
 end
 print("cfg."..k.." = "..tostring(cfg[k]))
 saveconfig()
end

function set_route(to,laddr,raddr, vlan)
 cfg.sroutes[to] = {component.get(laddr, "modem") or component.get(laddr, "tunnel") or laddr,raddr,0,tonumber(vlan) or cfg.port}
 saveconfig()
end
function del_route(to)
 cfg.sroutes[to] = nil
 saveconfig()
end
function route()
 print("Type\tDest\tInfo")
 for k,v in pairs(cfg.sroutes) do
  print("S",k,serial.serialize(v))
 end
 for k,v in pairs(rcache) do
  print("D",k,serial.serialize(v))
 end
end
function persist_route(to)
 local entry = rcache[to]
 if not entry then
  print("No cached route to "..tostring(to))
  return
 end
 set_route(to,entry[1],entry[2],entry[4])
end

function vlan()
 for k,v in pairs(cfg.vlans) do
  print(k,serial.serialize(v))
 end
end
function set_vlan(addr, id, suffix)
 addr = component.get(addr, "modem") or component.get(addr, "tunnel") or addr
 cfg.vlans[addr] = cfg.vlans[addr] or {[cfg.port]=false}
 cfg.vlans[addr][tonumber(id)] = suffix or false
 saveconfig()
end
function del_vlan(addr, id)
 addr = component.get(addr, "modem") or component.get(addr, "tunnel") or addr
 cfg.vlans[addr] = cfg.vlans[addr] or {[cfg.port]=false}
 cfg.vlans[addr][tonumber(id)] = nil
 saveconfig()
end
