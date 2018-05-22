function fget(A,P,V)
 local b,tb,s="","",net.open(A,V or 70)
 s:w("t"..P.."\n")
 repeat
  UC.pullSignal()
  tb=s:r(2048)
  b=b..tb
 until tb == "" and s.s == "c"
 return b:sub(2)
end
