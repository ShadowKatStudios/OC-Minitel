local net = require "net"
local event = require "event"

local function parseURL(url)
 local hp, path = url:match("(.-)(/.+)")
 hp, path = hp or url, path or "/"
 local host, port = hp:match("(.+):(.+)")
 host, port = host or hp, port or 70
 return host, port, path
end

local tArgs = {...}
local host, port, path = parseURL(tArgs[1])

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
