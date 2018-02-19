local net = require "net"
local event = require "event"

local tArgs = {...}
local host, path = tArgs[1], tArgs[2]
local port = 70

local sep = host:find(":")
if sep then
 port=tonumber(host:sub(sep+1))
 host=host:sub(1,sep-1)
end

local s = net.open(host,port)
s:write(path.."\n")
repeat
 l = s:read(1024)
 io.write(l)
 os.sleep(0.5)
until s.state == "closed" and l == ""
