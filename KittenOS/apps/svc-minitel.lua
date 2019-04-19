-- KittenOS NEO Wrapper for OpenOS Minitel

neo.requireAccess("s.h.modem_message","pulling packets")
local processes = {}
local hooks = {}
local computer = {["uptime"]=os.uptime,["address"]=os.address} -- wrap computer so the OpenOS code more or less works

if not computer.address then -- R1 compatibility
 computer.address = neo.requireAccess("k.computer","get address").address
end

local event = {}
function event.timer()
end
function event.listen(et,fn) -- add it to the hooks which is executed by the main event loop
 hooks["h."..et] = fn
end
function computer.pushSignal(...)
 for k,v in pairs(processes) do
  v(...)
 end
end
function print(...)
 for k,v in pairs({...}) do
  neo.emergency(v)
 end
end

-- OpenOS Minitel stuff, I guess.

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

local timers = {}
local hostname = computer.address():sub(1,8)
local dbug = false
local modems = {}
local port = 4096
local retry = 10
local route = true

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
local rctime = 15

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

local globals = neo.requestAccess("x.neo.pub.globals") -- KittenOS standard hostname stuff
if globals then
 hostname = globals.getSetting("hostname") or hostname
 globals.setSetting("hostname",hostname)
end

for p in neo.requireAccess("c.modem","networking").list() do -- fun stuff for KittenOS
 dprint(p.address)
 modems[p.address] = p
end
for k,v in pairs(modems) do
 v.open(port)
 print("Opened port "..port.." on "..v.address)
end
for p in neo.requireAccess("c.tunnel","networking").list() do
 dprint(p.address)
 modems[p.address] = p
end

local function genPacketID()
 local npID = ""
 for i = 1, 16 do
  npID = npID .. string.char(math.random(32,126))
 end
 return npID
end

local function sendPacket(packetID,packetType,dest,sender,vport,data,repeatingFrom)
 if rcache[dest] then
  dprint("Cached", rcache[dest][1],"send",rcache[dest][2],port,packetID,packetType,dest,sender,vport,data)
  if modems[rcache[dest][1]].type == "modem" then
   modems[rcache[dest][1]].send(rcache[dest][2],port,packetID,packetType,dest,sender,vport,data)
  elseif modems[rcache[dest][1]].type == "tunnel" then
   modems[rcache[dest][1]].send(packetID,packetType,dest,sender,vport,data)
  end
 else
  dprint("Not cached", port,packetID,packetType,dest,sender,vport,data)
  for k,v in pairs(modems) do
   -- do not send message back to the wired or linked modem it came from
   -- the check for tunnels is for short circuiting `v.isWireless()`, which does not exist for tunnels
   if v.address ~= repeatingFrom or (v.type ~= "tunnel" and v.isWireless()) then
    if v.type == "modem" then
     v.broadcast(port,packetID,packetType,dest,sender,vPort,data)
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

local function processPacket(_,localModem,from,pport,_,packetID,packetType,dest,sender,vport,data)
 pruneCache()
 if pport == port or pport == 0 then -- for linked cards
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
  elseif dest:sub(1,1) == "~" then -- broadcasts start with ~
   computer.pushSignal("net_broadcast",sender,vport,data)
  elseif route then -- repeat packets if route is enabled
   sendPacket(packetID,packetType,dest,sender,vport,data)
  end
  if not rcache[sender] then -- add the sender to the rcache
   dprint("rcache: "..sender..":", localModem,from,computer.uptime())
   rcache[sender] = {localModem,from,computer.uptime()+rctime}
  end
  if not pcache[packetID] then -- add the packet ID to the pcache
   pcache[packetID] = computer.uptime()+pctime
  end
 end
end

event.listen("modem_message",processPacket)

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

local function queuePacket(ptype,to,vport,data,npID)
 npID = npID or genPacketID()
 pqueue[npID] = {ptype,to,vport,data,0,0}
 dprint(npID,table.unpack(pqueue[npID]))
 packetPusher()
end

-- More KOS NEO stuff

neo.requireAccess("r.svc.minitel","minitel daemon")(function(pkg,pid,sendSig)
 processes[pid] = sendSig
 return {["sendPacket"]=queuePacket}
end)

while true do
 local ev = {coroutine.yield()}
 print(ev[1])
 packetPusher()
 pruneCache()
 if ev[1] == "k.procdie" then
  processes[ev[3]] = nil
 end
 if hooks[ev[1]] then
  pcall(hooks[ev[1]],table.unpack(ev))
 end
end
