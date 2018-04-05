local imt = {}

imt.ttypes = {}
imt.ttypes.string=1
imt.ttypes.number=2

imt.ftypes = {tostring,tonumber}

function imt.to16bn(n)
 return string.char(math.floor(n/256))..string.char(math.floor(n%256))
end
function imt.from16bn(s)
 return (string.byte(s,1,1)*256)+string.byte(s,2,2)
end

function imt.encodePacket(...)
 local tArgs = {...}
 local packet = string.char(#tArgs%256)
 for _,segment in ipairs(tArgs) do
  local segtype = type(segment)
  segment = tostring(segment)
  packet = packet .. imt.to16bn(segment:len()) .. string.char(imt.ttypes[segtype]) .. tostring(segment)
 end
 packet = imt.to16bn(packet:len()) .. packet
 return packet
end

function imt.decodePacket(s)
 local function getfirst(n)
  local ns = s:sub(1,n)
  s=s:sub(n+1)
  return ns
 end
 if s:len() < 2 then return false end
 local plen = imt.from16bn(getfirst(2))
 local segments = {}
 if s:len() < plen then return false end
 local nsegments = string.byte(getfirst(1))
 --print(tostring(plen).." bytes, "..tostring(nsegments).." segments")
 for i = 1, nsegments do
  local seglen = imt.from16bn(getfirst(2))
  local segtype = imt.ftypes[string.byte(getfirst(1))]
  local segment = segtype(getfirst(seglen))
  --print(seglen,segtype,segment,type(segment))
  segments[#segments+1] = segment
 end
 return table.unpack(segments)
end
function imt.getRemainder(s)
 local function getfirst(n)
  local ns = s:sub(1,n)
  s=s:sub(n+1)
  return ns
 end
 local plen = imt.from16bn(getfirst(2))
 if s:len() > plen then
  getfirst(plen)
  return s
 end
 return nil
end

return imt
