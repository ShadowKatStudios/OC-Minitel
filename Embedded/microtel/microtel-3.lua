_G.net={}

do
local modems,packetQueue,packetCache,routeCache,C,Y = {},{},{},{},COMPUTER,UNPACK
net.port,net.hostname,net.route,net.hook,U=4096,computer.address():sub(1,8),true,{},UPTIME

for a in component.list("modem") do
 modems[a] = component.proxy(a)
 modems[a].open(net.port)
end

local function genPacketID()
 local packetID = ""
 for i = 1, 16 do
  packetID = packetID .. string.char(math.random(32,126))
 end
 return packetID
end

local function rawSendPacket(packetID,packetType,to,from,vport,data)
 if routeCache[to] then
  modems[routeCache[to][1]].send(routeCache[to][2],net.port,packetID,packetType,to,from,vport,data)
 else
  for k,v in pairs(modems) do
   v.broadcast(net.port,packetID,packetType,to,from,vport,data)
  end
 end
end

local function sendPacket(packetID,packetType,to,vport,data)
 packetCache[packetID] = computer.uptime()
 rawSendPacket(packetID,packetType,to,net.hostname,vport,data)
end

function net.send(to,vport,data,packetType,packetID)
 packetType,packetID = packetType or 1, packetID or genPacketID()
 packetQueue[packetID] = {packetType,to,vport,data,0}
 sendPacket(packetID,packetType,to,vport,data)
end

local function checkCache(packetID)
 for k,v in pairs(packetCache) do
  if k == packetID then
   return false
  end
 end
 return true
end

local realComputerPullSignal = computer.pullSignal
function computer.pullSignal(t)
 local eventTab = {realComputerPullSignal(t)}
 for k,v in pairs(net.hook) do
  pcall(v,table.unpack(eventTab))
 end
 for k,v in pairs(packetCache) do
  if computer.uptime() > v+30 then
   packetCache[k] = nil
  end
 end
 for k,v in pairs(routeCache) do
  if computer.uptime() > v[3]+30 then
   routeCache[k] = nil
  end
 end
 if eventTab[1] == "modem_message" and (eventTab[4] == net.port or eventTab[4] == 0) and checkCache(eventTab[6]) then
  routeCache[eventTab[9]] = {eventTab[2],eventTab[3],computer.uptime()}
  if eventTab[8] == net.hostname then
   if eventTab[7] ~= 2 then
    computer.pushSignal("net_msg",eventTab[9],eventTab[10],eventTab[11])
    if eventTab[7] == 1 then
     sendPacket(genPacketID(),2,eventTab[9],eventTab[10],eventTab[6])
    end
   else
    packetQueue[eventTab[11]] = nil
   end
  elseif eventTab[8]:sub(1,1) == "~" then
   if eventTab[8] == "~" then
    computer.pushSignal("net_broadcast", eventTab[9], eventTab[10], eventTab[11])
   else
    for d in eventTab[8]:gmatch("~([^~]+)") do
     if d == net.hostname then
      computer.pushSignal("net_msg",eventTab[9],eventTab[10],eventTab[11])
      break
     end
    end
   end
  elseif net.route and checkCache(eventTab[6]) then
   rawSendPacket(eventTab[6],eventTab[7],eventTab[8],eventTab[9],eventTab[10],eventTab[11])
  end
  packetCache[eventTab[6]] = computer.uptime()
 end
 for k,v in pairs(packetQueue) do
  if computer.uptime() > v[5] then
   sendPacket(k,table.unpack(v))
   v[5]=computer.uptime()+30
  end
 end
 return table.unpack(eventTab)
end

end
