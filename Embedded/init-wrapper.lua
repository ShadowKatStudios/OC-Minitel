local c = ""
do
function net.hook.sender(to,vport,data,packetType,packetID)
 if et == "net_send" then
  net.send(to,vport,data,packetType,packetID)
 end
end
local fs = component.proxy(computer.getBootAddress())
local fh,b = fs.open("boot.lua"),""
repeat
 b=fs.read(fh,4096) or ""
 c=c..b
until b == ""
end
load(c)()
