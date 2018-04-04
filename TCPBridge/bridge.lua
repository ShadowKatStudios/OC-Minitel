local socket = require "socket"
local imt = require "interminitel"

local clients, coroutines, messages = {}, {}, {}

local function hasValidPacket(s)
 local w, pi, pt, ds, sn, po, da = pcall(imt.decodePacket,s)
 if w and pi and pt and ds and sn and po and da then
  return true
 end
end

function socketLoop()
 local server = socket.bind("*", 4096)
 server:settimeout(0)
 while true do
  local client,err = server:accept()
  if client then
   client:settimeout(0)
   clients[#clients+1] = {["conn"]=client,last=os.time()}
  end
  coroutine.yield()
 end
end

coroutines[#coroutines+1]=coroutine.create(socketLoop)

function clientLoop()
 while true do
  for _,client in pairs(clients) do
   local s=client.conn:receive(16384)
   if s then
    client.buffer = client.buffer .. s
   end
  end
  coroutine.yield()
 end
end

coroutines[#coroutines+1]=coroutine.create(clientLoop)

function pushLoop()
 while true do
  for id,msg in pairs(messages) do
   for _,client in pairs(clients) do
    client.conn:send(msg.."\n")
   end
   messages[id] = nil
   print(msg)
  end
  coroutine.yield()
 end
end

coroutines[#coroutines+1]=coroutine.create(pushLoop)

function bufferLoop()
 while true do
  for _,client in pairs(clients) do
   if hasValidPacket(client.buffer) then
    local tPacket = {imt.decodePacket(client.buffer)}
    client.buffer = table.remove(tPacket,#tPacket)
    messages[#messages+1] = imt.encodePacket(table.unpack(tPacket))
   end
  end
  coroutine.yield()
 end
end

coroutines[#coroutines+1]=coroutine.create(bufferLoop)

while #coroutines > 0 do
 for k,v in pairs(coroutines) do
  coroutine.resume(v)
 end
end
