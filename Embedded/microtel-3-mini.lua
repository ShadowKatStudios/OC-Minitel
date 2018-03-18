_G.net={}
do
local M,packetQueue,pC,rC,C={},{},{},{},computer
net.port,net.hostname,net.route=4096,C.address():sub(1,8),true
for a in component.list("modem") do
M[a]=component.proxy(a)
M[a].open(net.port)
end
local function gP()
local pID=""
for i=1,16 do
pID=pID .. string.char(math.random(32,126))
end
return pID
end
local function sP(pID,pT,T,vP,D)
pC[pID]=C.uptime()
if rC[T] then
M[rC[T][1]].send(rC[T][2],net.port,pID,pT,T,net.hostname,vP,D)
else
for k,v in pairs(M) do
v.broadcast(net.port,pID,pT,T,net.hostname,vP,D)
end
end
end
function net.send(T,vP,D,pT,pID)
pT,pID=pT or 1,pID or gP()
packetQueue[pID]={pT,T,vP,D,0}
sP(pID,pT,T,vP,D)
end
local function cC(pID)
for k,v in pairs(pC) do
if k==pID then
return false
end
end
return true
end
local rCPE=C.pullSignal
function C.pullSignal(t)
local eT={rCPE(t)}
for k,v in pairs(pC) do
if C.uptime()>v+30 then
pC[k]=nil
end
end
for k,v in pairs(rC) do
if C.uptime()>v[3]+30 then
rC[k]=nil
end
end
if eT[1]=="modem_message" and (eT[4]==net.port or eT[4]==0) and cC(eT[6]) then
rC[eT[9]]={eT[2],eT[3],C.uptime()}
if eT[8]==net.hostname then
if eT[7]~=2 then
C.pushSignal("net_msg",eT[9],eT[10],eT[11])
if eT[7]==1 then
sP(gP(),2,eT[9],eT[10],eT[6])
end
else
packetQueue[eT[11]]=nil
end
elseif net.route and cC(eT[6]) then
sP(eT[6],eT[7],eT[8],eT[9],eT[10],eT[11])
end
pC[eT[6]]=C.uptime()
end
for k,v in pairs(packetQueue) do
if C.uptime()>v[5] then
sP(k,table.unpack(v))
v[5]=C.uptime()+30
end
end
return table.unpack(eT)
end
end
