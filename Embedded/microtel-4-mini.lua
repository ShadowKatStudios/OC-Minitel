net.mtu=4096
function net.send(T,P,L)
local D={}
if L:len()>net.mtu then
for i=1,L:len(),net.mtu do
D[#D+1]=L:sub(1,net.mtu)
L=L:sub(net.mtu+1)
end
else
D={L}
end
for k,v in ipairs(D) do
net.rsend(T,P,v)
end
end
