net.mtu = 4096
function net.send(to,vport,ldata)
 local tdata = {}
 if ldata:len() > net.mtu then
  for i = 1, ldata:len(), net.mtu do
   tdata[#tdata+1] = ldata:sub(1,net.mtu)
   ldata = ldata:sub(net.mtu+1)
  end
 else
  tdata = {ldata}
 end
 for k,v in ipairs(tdata) do
  net.rsend(to,vport,v)
 end
end
