net.mtu=4096
function net.lsend(T,P,L)
local D={}
for i=1,L:len(),net.mtu do
D[#D+1]=L:sub(1,net.mtu)
L=L:sub(net.mtu+1)
end
for k,v in ipairs(D) do
net.send(T,P,v)
end
end
