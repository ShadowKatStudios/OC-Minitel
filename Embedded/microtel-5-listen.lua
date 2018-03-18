function net.listen(vport)
 repeat
  local etype, from, port, data = computer.pullSignal(0.5)
 until port == vport and data == "openstream"
 local nport,sclose = math.random(2^15,2^16),tostring(math.random(-2^16,2^16))
 net.send(from,port,tostring(nport))
 net.send(from,nport,sclose)
 return net.socket(from,nport,sclose)
end
