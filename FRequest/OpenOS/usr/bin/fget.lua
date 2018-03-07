local net = require "net"
local event = require "event"

local tArgs = {...}
local address, path = tArgs[1], tArgs[2]
local port = 70

local host,nport = host:match("(.+):(%d+)")
port = nport or port
host = host or address

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
