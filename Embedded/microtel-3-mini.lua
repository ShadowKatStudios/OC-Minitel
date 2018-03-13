_G.net={}
net.port=4096
net.hostname=computer.address():sub(1,8)
net.debug=false
net.rctime=30
net.pctime=30
net.retry=30
do
local rcpe,PC,RC,pQ,M=computer.pullSignal,{},{},{},{}
local cI,cU,cPS=component.invoke,computer.uptime,computer.pushSignal
for a,t in component.list("modem") do
M[#M+1]=component.proxy(a)
M[#M].open(net.port)
end
local function gP()
local npID=""
for i=1,16 do
npID=npID .. string.char(math.random(32,126))
end
return npID
end
local function sP(pID,pT,D,S,vP,dA)
if RC[D] then
cI(RC[D][1],"send",RC[D][2],net.port,pID,pT,D,S,vP,dA)
else
for k,v in pairs(M) do
v.broadcast(net.port,pID,pT,D,S,vP,dA)
end
end
end
local function pC()
for k,v in pairs(RC) do
if v[3]<cU() then
RC[k]=nil
end
end
for k,v in pairs(PC) do
if v<cU() then
PC[k]=nil
end
end
end
local function cPC(pID)
for k,v in pairs(PC) do
if k==pID then return true end
end
return false
end
local function pP()
for k,v in pairs(pQ) do
if v[5]<cU() then
sP(k,v[1],v[2],net.hostname,v[3],v[4])
if v[1]~=1 or v[6]==255 then
pQ[k]=nil
else
pQ[k][5]=cU()+net.retry
pQ[k][6]=pQ[k][6]+1
end
end
end
end
function computer.pullSignal(t)
pC()
pP()
local tev={rcpe(t)}
if tev[1]=="modem_message" and tev[4]==net.port and not cPC(tev[6]) then
if tev[8]==net.hostname then
if tev[7]==1 then
sP(gP(),2,tev[9],net.hostname,tev[10],tev[6])
end
if tev[7]==2 then
pQ[tev[11]]=nil
cPS("net_ack",tev[11])
end
if tev[7]~=2 then
cPS("net_msg",tev[9],tev[10],tev[11])
end
else
sP(tev[6],tev[7],tev[8],tev[9],tev[10],tev[11])
end
if not RC[tev[9]] then
RC[tev[9]]={tev[2],tev[3],cU()+net.rctime}
end
if not PC[tev[6]] then
PC[tev[6]]=cU()+net.pctime
end
end
return table.unpack(tev)
end
function net.usend(to,vP,dA,npID)
npID=npID or gP()
pQ[npID]={0,to,vP,dA,0,0}
end
function net.rsend(to,vP,dA,npID)
npID=npID or gP()
pQ[npID]={1,to,vP,dA,0,0}
repeat
local te={computer.pullSignal()}
until te[1]=="net_ack" and te[2]==npID
end
end
