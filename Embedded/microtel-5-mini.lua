do
local H={}
function computer.pullSignal(T)
tE={computer.pullSignal(T)}
for k,v in pairs(H) do
v(table.unpack(tE))
end
return table.unpack(tE)
end
local function cW(S,D)
if S.state=="open" then
net.send(S.A,S.P,D)
end
end
local function cR(S,lN)
local rD=""
rD=S.rB:sub(1,lN)
S.rB=S.rB:sub(lN+1)
return rD
end
local function socket(A,P,sC) local C={}
C.A,C.P=A,tonumber(P)
C.rB=""
C.write=cW
C.read=cR
C.state="open"
local function lI(_,f,p,d)
if f==C.A and p==C.P then
if d==sC then
C:close()
else
C.rB=C.rB .. d
end
end
end
sL=tostring(lI)
H[sL]=lI
function C.close(S)
H[sL]=nil
C.state="closed"
net.rsend(A,P,sC)
end
return C
end
function net.open(to,P)
net.rsend(to,P,"openstream")
local st=computer.uptime()+net.streamdelay
local est=false
while true do
_,F,rP,D=event.pull("net_msg")
if to==F and rP==P then
if tonumber(D) then
est=true
end
break
end
if st<computer.uptime() then
return nil,"timed out"
end
end
if not est then
return nil,"refused"
end
D=tonumber(D)
sC=""
repeat
_,F,nP,sC=event.pull("net_msg")
until F==to and nP==D
return socket(to,D,sC)
end
function net.listen(P)
repeat
_,F,rP,D=computer.pullSignal()
until rP==P and D=="openstream"
local nP=math.random(net.minP,net.maxP)
local sC=net.genPacketID()
net.rsend(F,rP,tostring(nP))
net.rsend(F,nP,sC)
return socket(F,nP,sC)
end
end
