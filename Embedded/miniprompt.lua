local ga,sa = component.list("gpu")(),component.list("screen")()
GPU = component.proxy(ga)
GPU.bind(sa)

write = vt100emu(GPU)
function print(...)
 for k,v in pairs({...}) do
  write(tostring(v).."\n")
 end
end
function read()
 local sBuffer = ""
 repeat
  local tSignal = {computer.pullSignal()}
  if tSignal[1] == "key_down" then
   if tSignal[3] > 31 and tSignal[3] < 127 then
    write(string.char(tSignal[3]))
    sBuffer = sBuffer .. string.char(tSignal[3])
   elseif tSignal[3] == 8 and tSignal[4] == 14 and S:len() > 0 then
    write("\8 \8")
    sBuffer = sBuffer:sub(1,-2)
   end
  end
 until tSignal[1] == "key_down" and tSignal[3] == 13 and tSignal[4] == 28
 write("\n")
 return sBuffer
end
--API
while true do
 write(_VERSION.."> ")
 tResult = {pcall(load(read()))}
 for k,v in pairs(tResult) do
  print(v)
 end
end
