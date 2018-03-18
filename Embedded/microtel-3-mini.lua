_G.net={}
do
local M,pQ,pC,rC,C,Y={},{},{},{},computer,table.unpack
net.port,net.hostname,net.route,net.hook,U=4096,C.address():sub(1,8),true,{},C.uptime
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
pC[pID]=U()
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
pQ[pID]={pT,T,vP,D,0}
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
local Z={rCPE(t)}
for k,v in pairs(net.hook) do
pcall(v,Y(Z))
end
for k,v in pairs(pC) do
if U()>v+30 then
pC[k]=nil
end
end
for k,v in pairs(rC) do
if U()>v[3]+30 then
rC[k]=nil
end
end
if Z[1]=="modem_message" and (Z[4]==net.port or Z[4]==0) and cC(Z[6]) then
rC[Z[9]]={Z[2],Z[3],U()}
if Z[8]==net.hostname then
if Z[7]~=2 then
C.pushSignal("net_msg",Z[9],Z[10],Z[11])
if Z[7]==1 then
sP(gP(),2,Z[9],Z[10],Z[6])
end
else
pQ[Z[11]]=nil
end
elseif net.route and cC(Z[6]) then
sP(Z[6],Z[7],Z[8],Z[9],Z[10],Z[11])
end
pC[Z[6]]=U()
end
for k,v in pairs(pQ) do
if U()>v[5] then
sP(k,Y(v))
v[5]=U()+30
end
end
return Y(Z)
end
end
