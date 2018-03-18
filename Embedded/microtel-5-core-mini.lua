net.timeout=60
function net.open(A,V)
local st=computer.uptime()
net.send(A,P,"openstream")
repeat
_,F,P,D=computer.pullSignal(0.5)
if computer.uptime()>st+net.timeout then return false end
until F==A and P==V and tonumber(D)
V=tonumber(D)
repeat
_,F,P,D=computer.pullSignal(0.5)
until F==A and P==V
return socket(A,V,D)
end
