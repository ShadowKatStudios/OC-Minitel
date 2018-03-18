function net.listen(V)
 repeat
  local E, F, P, D = computer.pullSignal(0.5)
 until P == V and D == "openstream"
 local nP,S = math.random(2^15,2^16),tostring(math.random(-2^16,2^16))
 net.send(F,P,tostring(nP))
 net.send(F,nP,S)
 return net.socket(F,nP,S)
end
