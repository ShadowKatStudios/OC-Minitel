function net.flisten(vport,handler)
 function net.hook[vport](etype,from,port,data)
  if port == vport and data == "openstream" then
   local nport,sclose = math.random(2^15,2^16),tostring(math.random(-2^16,2^16))
   net.send(from,port,tostring(nport))
   net.send(from,nport,sclose)
   handler(net.socket(from,nport,sclose))
  end
 end
end
