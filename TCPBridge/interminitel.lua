local imt = {}

function imt.to16bn(n)
 return string.char(math.floor(n/256))..string.char(math.floor(n%256))
end
function imt.from16bn(s)
 return (string.byte(s,1,1)*256)+string.byte(s,2,2)
end

function imt.encodePacket(packetID, packetType, destination, sender, port, data)
 local rs = string.char(packetID:len()%256)..packetID..string.char(packetType)
 rs=rs..string.char(destination:len()%256)..destination
 rs=rs..string.char(sender:len()%256)..sender
 rs=rs..to16bn(port)
 rs=rs..to16bn(data:len())..data
 return rs
end

function imt.decodePacket(s)
 local pidlen, destlen, senderlen, datalen, packetID, packetType, destination, sender, port, data
 pidlen = string.byte(s:sub(1,1))
 s=s:sub(2)
 packetID = s:sub(1,pidlen)
 s=s:sub(pidlen+1)
 packetType = string.byte(s:sub(pidlen+1))
 s=s:sub(2)
 destlen = string.byte(s:sub(1,1))
 s=s:sub(2)
 destination = s:sub(1,destlen)
 s=s:sub(destlen+1)
 senderlen=string.byte(s:sub(1,1))
 s=s:sub(2)
 sender = s:sub(1,senderlen)
 s=s:sub(senderlen+1)
 port=from16bn(s:sub(1,2))
 s=s:sub(3)
 datalen=from16bn(s:sub(1,2))
 s=s:sub(3)
 data=s:sub(1,datalen)
 s=s:sub(datalen+1)
 return packetID, packetType, destination, sender, port, data, s
end

return imt
