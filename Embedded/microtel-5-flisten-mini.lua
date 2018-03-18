function net.flisten(V,handler)
 function net.hook[V](E,F,P,D)
  if P == V and D == "openstream" then
   local nP,S = math.random(2^15,2^16),tostring(math.random(-2^16,2^16))
   net.send(F,P,tostring(nP))
   net.send(F,nP,S)
   handler(net.socket(F,nP,S))
  end
 end
end
