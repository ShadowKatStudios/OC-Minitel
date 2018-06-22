local net = require "net"
local event = require "event"

local function parseURL(url)
 local proto,addr = url:match("(.-)://(.+)")
 addr = addr or url
 local hp, path = addr:match("(.-)(/.*)")
 hp, path = hp or addr, path or "/"
 local host, port = hp:match("(.+):(.+)")
 host = host or hp
 return proto, host, port, path
end

local tArgs = {...}
local proto, host, port, path = parseURL(tArgs[1])
port = tonumber(port) or 70

local socket = net.open(host,port)
socket:write("t"..path.."\n")
local c = socket:read(1)
repeat
 c = socket:read(1)
 os.sleep(0.5)
until c ~= ""
if c == "n" then 
 print(path..": Not found.")
elseif c == "f" then 
 print("Failure: ")
elseif c == "d" then
 print("Directory listing for "..path)
end
repeat
 l = socket:read(1024)
 io.write(l)
 os.sleep(0.5)
until socket.state == "closed" and l == ""
