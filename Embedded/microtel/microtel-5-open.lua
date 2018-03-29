net.timeout = 60
function net.open(address,vport)
 local st,from,port,data=computer.uptime()
 net.send(address,port,"openstream")
 repeat
  _, from, port, data = computer.pullSignal(0.5)
  if computer.uptime() > st+net.timeout then return false end
 until from == address and port == vport and tonumber(data)
 vport=tonumber(data)
 repeat
  _, from, port, data = computer.pullSignal(0.5)
 until from == address and port == vport
 return socket(address,vport,data)
end
