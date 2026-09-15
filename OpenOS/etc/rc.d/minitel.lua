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
local privateModems = {}

cfg.debug = false
cfg.port = 4096
cfg.retry = 10
cfg.retrycount = 3
cfg.route = true
cfg.private = {}

--[[
LKR format:
address {
 local hardware address
 remote hardware address
 time last received
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

local function dprint(...)
 if cfg.debug then
  print(...)
 end
end

local function completeModem(prefix)
 local candidates = {}
 local prefixLen = #prefix
 if prefixLen == 36 then
  -- explicit UUID is provided, do not check whether it is currently present
  return {prefix}
 end
 for _,modem in ipairs(modems) do
  local laddr = modem.address
  if laddr:sub(1,prefixLen) == prefix then
   candidates[#candidates+1] = laddr
  end
 end
 return candidates
end

local function completeModemSingle(prefix)
 local candidates = completeModem(prefix)
 if #candidates == 1 then
  return candidates[1]
 elseif #candidates < 1 then
  print("No matching modems")
 else
  print("Candidate modems:")
  for _,laddr in ipairs(candidates) do
   print(laddr)
  end
 end
 return nil
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
   if k == "sroutes" then
    for to in pairs(cfg.sroutes) do
     cfg.sroutes[to] = nil
    end
    for to,route in pairs(v) do
     cfg.sroutes[to] = route
    end
   else
    cfg[k] = v
   end
  end
  for k in pairs(privateModems) do
   privateModems[k] = nil
  end
  for _,laddr in ipairs(cfg.private) do
   privateModems[laddr] = true
  end
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
  modems[#modems+1] = component.proxy(a)
 end
 for k,v in ipairs(modems) do
  v.open(cfg.port)
  print("Opened port "..cfg.port.." on "..v.address)
 end
 for a,t in component.list("tunnel") do
  modems[#modems+1] = component.proxy(a)
 end
 
 local function genPacketID()
  local npID = ""
  for i = 1, 16 do
   npID = npID .. string.char(math.random(32,126))
  end
  return npID
 end

 local function canUseModemFor(remoteHost,modemUUID)
  if not privateModems[modemUUID] then
   return true
  end
  if not cfg.sroutes[remoteHost] then
   return false
  end
  return cfg.sroutes[remoteHost][1] == modemUUID
 end
 
 local function sendPacket(packetID,packetType,dest,sender,vPort,data,repeatingFrom)
  if rcache[dest] then
   if rcache[dest][1] == repeatingFrom and packetType ~= 2 then
    dprint("Cached", rcache[dest][1], "send", "Packet came in on the same interface we use to send, not forwarding")
    return
   end
   dprint("Cached", rcache[dest][1],"send",rcache[dest][2],cfg.port,packetID,packetType,dest,sender,vPort,data)
   if component.type(rcache[dest][1]) == "modem" then
    component.invoke(rcache[dest][1],"send",rcache[dest][2],cfg.port,packetID,packetType,dest,sender,vPort,data)
   elseif component.type(rcache[dest][1]) == "tunnel" then
    component.invoke(rcache[dest][1],"send",packetID,packetType,dest,sender,vPort,data)
   end
  else
   dprint("Not cached", cfg.port,packetID,packetType,dest,sender,vPort,data)
   for k,v in pairs(modems) do
    -- do not send message back to the wired or linked modem it came from
    -- the check for tunnels is for short circuiting `v.isWireless()`, which does not exist for tunnels
    if (v.address ~= repeatingFrom or (v.type ~= "tunnel" and v.isWireless())) and canUseModemFor(dest,v.address) then
     if v.type == "modem" then
      v.broadcast(cfg.port,packetID,packetType,dest,sender,vPort,data)
     elseif v.type == "tunnel" then
      v.send(packetID,packetType,dest,sender,vPort,data)
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
  if pport == cfg.port or pport == 0 then -- for linked cards
   dprint(cfg.port,vPort,packetType,dest)
   if not canUseModemFor(sender,localModem) then return end
   if checkPCache(packetID) then return end
   -- update the route cache on every packet received, not just the first time we've seen it since expiring the cache.
   -- also moved it to before the ack-packets are sent out, which should help them to not flood the network with acks
   dprint("rcache: "..sender..":", localModem,from,computer.uptime())
   rcache[sender] = {localModem,from,computer.uptime()+cfg.rctime} 
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
    sendPacket(packetID,packetType,dest,sender,vPort,data,localModem)
   end
   if not pcache[packetID] then -- add the packet ID to the pcache
    pcache[packetID] = computer.uptime()+cfg.pctime
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

function set_route(to,laddr,raddr)
 laddr = completeModemSingle(laddr)
 if not laddr then return end
 cfg.sroutes[to] = {laddr,raddr,0}
 saveconfig()
end
function del_route(to)
 cfg.sroutes[to] = nil
 saveconfig()
end
function route()
 for k,v in pairs(rcache) do
  print(k,serial.serialize(v))
 end
end
function persist_route(to)
 local entry = rcache[to]
 if not entry then
  print("No cached route to "..tostring(to))
  return
 end
 set_route(to,entry[1],entry[2])
end
function private(laddr)
 laddr = completeModemSingle(laddr)
 if not laddr then return end
 if privateModems[laddr] then
  print("Modem "..laddr.." is already private")
  return
 else
  cfg.private[#cfg.private+1] = laddr
  privateModems[laddr] = true
  saveconfig()
 end
end
function unprivate(laddr)
 laddr = completeModemSingle(laddr)
 if not laddr then return end
 if not privateModems[laddr] then
  print("Modem "..laddr.." is already public")
  return
 else
  for k,v in ipairs(cfg.private) do
   if v == laddr then
    table.remove(cfg.private, k)
    break
   end
  end
  privateModems[laddr] = nil
  saveconfig()
 end
end
