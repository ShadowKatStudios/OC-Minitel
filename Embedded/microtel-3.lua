_G.net = {}
net.port = 4096
net.hostname = computer.address():sub(1,8)
net.hostname = "micro"
net.debug = false
net.rctime = 30
net.pctime = 30
net.retry = 30

do

local rcpe, pcache, rcache, pqueue, modems = computer.pullSignal, {}, {}, {}, {}
--subhere

for a,t in component.list("modem") do
 modems[#modems+1] = component.proxy(a)
 modems[#modems].open(net.port)
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
  component.invoke(rcache[dest][1],"send",rcache[dest][2],net.port,packetID,packetType,dest,sender,vport,data)
 else
  for k,v in pairs(modems) do
   v.broadcast(net.port,packetID,packetType,dest,sender,vport,data)
  end
 end
end

local function pruneCache()
 for k,v in pairs(rcache) do
  if v[3] < computer.uptime() then
   rcache[k] = nil
  end
 end
 for k,v in pairs(pcache) do
  if v < computer.uptime() then
   pcache[k] = nil
  end
 end
end

local function checkPCache(packetID)
 for k,v in pairs(pcache) do
  if k == packetID then return true end
 end
 return false
end
local function packetPusher()
 for k,v in pairs(pqueue) do
  if v[5] < computer.uptime() then
   sendPacket(k,v[1],v[2],net.hostname,v[3],v[4])
   if v[1] ~= 1 or v[6] == 255 then
    pqueue[k] = nil
   else
    pqueue[k][5]=computer.uptime()+net.retry
    pqueue[k][6]=pqueue[k][6]+1
   end
  end
 end
end

function computer.pullSignal(t)
 pruneCache()
 packetPusher()
 local tev = {rcpe(t)}
 if tev[1] == "modem_message" and tev[4] == net.port and not checkPCache(tev[6]) then
  if tev[8] == net.hostname then
   if tev[7] == 1 then
    sendPacket(genPacketID(),2,tev[9],net.hostname,tev[10],tev[6])
   end
   if tev[7] == 2 then
    pqueue[tev[11]] = nil
    computer.pushSignal("net_ack",data)
   end
   if packetType ~= 2 then
    computer.pushSignal("net_msg",tev[9],tev[10],tev[11])
   end
  else
   sendPacket(tev[6],tev[7],tev[8],tev[9],tev[10],tev[11])
  end
  if not rcache[tev[9]] then
   rcache[tev[9]] = {tev[2],tev[3],computer.uptime()+net.rctime}
  end
  if not pcache[tev[6]] then
   pcache[tev[6]] = computer.uptime()+net.pctime
  end
 end
end

function net.send(ptype,to,vport,data,npID)
 npID = npID or genPacketID()
 pqueue[npID] = {ptype,to,vport,data,0,0}
end

end

while true do
 computer.pullSignal()
end
