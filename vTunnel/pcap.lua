local pcap = {}
local function uint32(n)
 s = ""
 for i = 3, 0, -1 do
  s=s..string.char((n>>(8*i))%256)
 end
 return s
end
local function uint16(n)
 s = ""
 for i = 1, 0, -1 do
  s=s..string.char((n>>(8*i))%256)
 end
 return s
end

function pcap.header(type)
 local s=uint32(0xa1b2c3d4) -- magic number
 s=s..uint16(2) -- major version
 s=s..uint16(4) -- minor version
 s=s..uint32(0) -- timezone
 s=s..uint32(0) -- accuracy
 s=s..uint32(2^16) -- snaplen
 s=s..uint32(type or 147)
 return s
end
function pcap.packet(d)
 local s = uint32(os.time()) -- timestamp
 s=s..uint32(0) -- usec
 s=s..uint32(d:len()) -- included length
 s=s..uint32(d:len()) -- actual length
 return s..d
end

return pcap
