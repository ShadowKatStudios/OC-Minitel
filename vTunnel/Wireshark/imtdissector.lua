local imtp = Proto("imt","InterMinitel")
local imt = require "interminitel"

local pid = ProtoField.string("imt.packet_id","Packet ID")
local ptype = ProtoField.int32("imt.packet_type","Packet type")
local dest = ProtoField.string("imt.destination","Destination address")
local src = ProtoField.string("imt.source","Source address")
local port = ProtoField.int32("imt.port","Port")
local data = ProtoField.string("imt.data","Data")
local conv = ProtoField.int32("imt.conversation","Conversation")
local cport = ProtoField.int32("imt.conversation_port","Conversation Port")

local seg = ProtoField.string("imt.segment","Segment")

imtp.fields = {pid, ptype, dest, src, port, data, conv, cport}

local conversations = {}
local function checkConversation(p,c)
 if p[5] == c.port and c.addresses[p[4]] and c.addresses[p[3]] then
  return true
 end
 return false
end
local conversationPackets = {}

function imtp.dissector(buffer,pinfo,tree)
 pinfo.cols.protocol=imtp.name
 local d = buffer():string()
 local dp, sp = imt.decodePacket(d)
 local subtree = tree:add(imtp,"InterMinitel Data")
 for k,v in pairs(dp) do
  subtree:add(imtp.fields[k], buffer(sp[k], tostring(v):len()), v)
 end
 pinfo.cols.src = dp[4]
 pinfo.cols.dst = dp[3]
 pinfo.cols.src_port = dp[5]
 pinfo.cols.dst_port = dp[5]
 if dp[2] == "0" then
  pinfo.cols.info = "Unreliable packet."
 elseif dp[2] == "1" then
  pinfo.cols.info = "Reliable packet."
 elseif dp[2] == "2" then
  pinfo.cols.info = "Acknowledgement packet for '"..dp[6].."'"
 end
 if dp[6] == "openstream" then
  local t = {addresses = {}, iport = dp[5]}
  t.addresses[dp[3]] = true
  t.addresses[dp[4]] = true
  t.id = conversationPackets[dp[1]] or #conversations+1
  print("Conversation started by "..dp[4].." talking to "..dp[3].." on port "..tostring(dp[5]))
  conversations[t.id] = t
  subtree:add(conv, t.id):set_generated()
  subtree:add(cport, t.iport):set_generated()
  conversationPackets[dp[1]] = t.id
 end
 for k,v in pairs(conversations) do
  if not v.port and v.iport == dp[5] and tonumber(dp[6]) and v.addresses[dp[3]] and v.addresses[dp[4]] then
   v.port = tostring(tonumber(dp[6]))
   print(string.format("Conversation %d port set to %d",k,v.port))
   subtree:add(conv, v.id):set_generated()
   subtree:add(cport, v.iport):set_generated()
   conversationPackets[dp[1]] = v.id
  elseif checkConversation(dp,v) then
   print(dp[1].." is part of "..tostring(k))
   subtree:add(conv, v.id):set_generated()
   subtree:add(cport, v.iport):set_generated()
   conversationPackets[dp[1]] = v.id
  end
 end
end
