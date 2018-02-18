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

local event = require "event"
local component = require "component"
local computer = require "computer"
local hostname = computer.address()
local listener = false
local dbug = false
local modems = {}
local port = 4096
local retry = 30

--[[
LKR format:
address {
 local hardware address
 remote hardware address
 time last received
}
]]--
local sroutes = {}
local rcache = setmetatable({},{__index=sroutes})
local rctime = 30

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
local pctime = 30

local function dprint(...)
 if dbug then
  print(...)
 end
end

function start()
 local f=io.open("/etc/hostname","rb")
 if f then
  hostname = f:read()
  f:close()
 end
 print("Hostname: "..hostname)
 if listener then return end
 for a,t in component.list("modem") do
  modems[#modems+1] = component.proxy(a)
 end
 for k,v in ipairs(modems) do
  v.open(port)
  print("Opened port "..port.." on "..v.address)
 end
 
 local function genPacketID()
  local npID = ""
  for i = 1, 16 do
   npID = npID .. string.char(math.random(32,126))
  end
  return npID
 end
 
 local function sendPacket(packetID,packetType,dest,sender,vport,data)
  if rcache[dest] then
   dprint("Cached", rcache[dest][1],"send",rcache[dest][2],port,packetID,packetType,dest,sender,vport,data)
   component.invoke(rcache[dest][1],"send",rcache[dest][2],port,packetID,packetType,dest,sender,vport,data)
  else
   dprint("Not cached", port,packetID,packetType,dest,sender,vport,data)
   for k,v in pairs(modems) do
    v.broadcast(port,packetID,packetType,dest,sender,vport,data)
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
 
 local function processPacket(_,localModem,from,pport,_,packetID,packetType,dest,sender,vport,data)
  pruneCache()
  if pport == port then
   dprint(port,vport,packetType,dest)
   if checkPCache(packetID) then return end
   if dest == hostname then
    if packetType == 1 then
     sendPacket(genPacketID(),2,sender,hostname,vport,packetID)
    end
    if packetType == 2 then
     dprint("Dropping "..data.." from queue")
     pqueue[data] = nil
     computer.pushSignal("net_ack",data)
    end
    if packetType ~= 2 then
     computer.pushSignal("net_msg",sender,vport,data)
    end
   else
    sendPacket(packetID,packetType,dest,sender,vport,data)
   end
   if not rcache[sender] then
    dprint("rcache: "..sender..":", localModem,from,computer.uptime())
    rcache[sender] = {localModem,from,computer.uptime()+rctime}
   end
   if not pcache[packetID] then
    pcache[packetID] = computer.uptime()+pctime
   end
  end
 end
 
 listeners["modem_message"]=processPacket
 event.listen("modem_message",processPacket)
 print("Started packet listening daemon: "..tostring(processPacket))
 
 local function queuePacket(_,ptype,to,vport,data,npID)
  npID = npID or genPacketID()
  pqueue[npID] = {ptype,to,vport,data,0,0}
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
    if v[1] ~= 1 or v[6] == 255 then
     pqueue[k] = nil
    else
     pqueue[k][5]=computer.uptime()+retry
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
  print("Stopped listener: "..tostring(v))
 end
 for k,v in pairs(timers) do
  event.cancel(v)
  print("Stopped timer: "..tostring(v))
 end
end

function debug()
 dbug = not dbug
end
function set_retry(sn)
 retry = tonumber(sn) or 30
 print("retry = "..tostring(retry))
end
function set_pctime(sn)
 pctime = tonumber(sn) or 30
 print("pctime = "..tostring(pctime))
end
function set_rctime(sn)
 rctime = tonumber(sn) or 30
 print("rctime = "..tostring(rctime))
end
function set_port(sn)
 port = tonumber(sn) or 4096
 print("port = "..tostring(port))
end
function set_route(to,laddr,raddr)
 sroutes[to] = {laddr,raddr,0}
end
function del_route(to)
 sroutes[to] = nil
end
