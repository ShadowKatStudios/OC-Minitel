local socket = require "socket"
local imt = require "interminitel"

local tArgs = {...}

local port, timeout = tonumber(tArgs[1]) or 4096, tonumber(tArgs[2]) or 60

local clients, coroutines, messages = {}, {}, {}

local function spawn(f)
 coroutines[#coroutines+1] = coroutine.create(function()
  pid = #coroutines
  while true do
   print(pid,pcall(f))
  end
 end)
end

function reprint(...)
 local tA = {...}
 for k,v in pairs(tA) do
  local s = ""
  v=tostring(v)
  for i = 1, v:len() do
   if string.byte(v:sub(i,i)) < 32 or string.byte(v:sub(i,i)) > 127 then
    s=s .. "\\" .. tostring(string.byte(v:sub(i,i)))
   else
    s=s..v:sub(i,i)
   end
  end
  print(s)
 end
end

local function hasValidPacket(s)
 local w, res = pcall(imt.decodePacket,s)
 if res then return true end
end
hasValidPacket("")

function socketLoop()
 local server = socket.bind("*", port)
 server:settimeout(0)
 print("vTunnel bridge server listening on port "..tostring(port))
 while true do
  local client,err = server:accept()
  if client then
   client:settimeout(0)
   clients[#clients+1] = {["conn"]=client,last=os.time(),buffer=""}
   local i,p = client:getsockname()
   print("Gained client #"..tostring(#clients)..": "..i..":"..tostring(p))
  end
  coroutine.yield()
 end
end

spawn(socketLoop)

function clientLoop()
 while true do
  for id,client in pairs(clients) do
   local s,b,c=client.conn:receive(1)
   if s then
    client.buffer = client.buffer .. s
    client.last=os.time()
   end
   if client.buffer:len() > 16384 then
    print("Dropping client "..tostring(id).." for wasting resources")
    client.conn:close()
    clients[id] = nil
   end
   if client.last+timeout < os.time() then
    print("Dropping client "..tostring(id).." for inactivity")
    client.conn:close()
    clients[id] = nil
   end
  end
  coroutine.yield()
 end
end

spawn(clientLoop)

function pushLoop()
 while true do
  for id,msg in pairs(messages) do
   for k,client in pairs(clients) do
    client.conn:send(msg)
    reprint("Message #"..tostring(id).." -> Client #"..tostring(k).." - "..msg)
   end
   messages[id] = nil
  end
  coroutine.yield()
 end
end

spawn(pushLoop)

function bufferLoop()
 while true do
  for _,client in pairs(clients) do
   if client.buffer:len() > 0 then
    if imt.decodePacket(client.buffer) then
    messages[#messages+1] = imt.encodePacket(imt.decodePacket(client.buffer))
    client.buffer = imt.getRemainder(client.buffer) or ""
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
