local socket = require "socket"
local imt = require "interminitel"

local clients, coroutines, messages = {}, {}, {}

local function spawn(f)
 coroutines[#coroutines+1] = coroutine.create(function()
  while true do
   print(pcall(f))
  end
 end)
end

local function hasValidPacket(s)
 local w, res = pcall(imt.decodePacket,s)
 if res then return true end
end
hasValidPacket("")

function socketLoop()
 local server = socket.bind("*", 4096)
 server:settimeout(0)
 while true do
  local client,err = server:accept()
  if client then
   client:settimeout(0)
   clients[#clients+1] = {["conn"]=client,last=os.time(),buffer=""}
   print("Gained client: "..client:getsockname())
  end
  coroutine.yield()
 end
end

spawn(socketLoop)

function clientLoop()
 while true do
  for _,client in pairs(clients) do
   local s=client.conn:receive()
   if s then
    client.buffer = client.buffer .. s
    print(s)
   end
  end
  coroutine.yield()
 end
end

spawn(clientLoop)

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

spawn(pushLoop)

function bufferLoop()
 while true do
  for _,client in pairs(clients) do
   if client.buffer:len() > 0 then
    if hasValidPacket(client.buffer) then
     messages[#messages+1] = imt.encodePacket(imt.decodePacket(client.buffer))
     client.buffer = imt.getRemainder(client.buffer)
    end
   end
  end
  coroutine.yield()
 end
end

spawn(bufferLoop)

while #coroutines > 0 do
 for k,v in pairs(coroutines) do
  coroutine.resume(v)
 end
end
