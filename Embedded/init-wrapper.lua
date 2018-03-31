local c = ""
do
function net.hook.sender(et,packetID,packetType,to,vport,data)
 if et == "net_send" then
  net.send(packetID,packetType,to,vport,data)
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
