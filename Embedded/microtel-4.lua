net.mtu = 4096
function net.lsend(to,vport,ldata)
 local tdata = {}
 for i = 1, ldata:len(), net.mtu do
  tdata[#tdata+1] = ldata:sub(1,net.mtu)
  ldata = ldata:sub(net.mtu+1)
 end
 for k,v in ipairs(tdata) do
  net.send(to,vport,v)
 end
end
