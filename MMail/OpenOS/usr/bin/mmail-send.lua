local net = require "net"

local tArgs = {...}
local hostname = io.open("/etc/hostname","rb"):read()

if not tArgs[1] then
 io.write("To: ")
 tArgs[1] = io.read()
end

if not tArgs[2] then
 io.write("From: ")
 tArgs[2] = io.read()
 print("\n")
end

if not tArgs[3] then
 io.write("Subject: ")
 tArgs[3] = io.read()
end

local user,host = tArgs[1]:match("(.+)@(.+)")
local from = tArgs[2] .. "@" .. hostname
subject = tArgs[3]

print("To: "..user.."@"..host)
print("From: "..from)
print("Subject: "..subject)

local fileID = tArgs[4]
if not fileID then
 fileID = "/tmp/mail-"..tostring(math.random(1000000,9999999))
 os.execute("edit "..fileID)
end

local f = io.open(fileID,"rb")
local message = f:read("*a")
f:close()

socket = net.open(host,25)
socket:write("To: "..user.."@"..host.."\n")
socket:write("From: "..from.."\n")
socket:write("Subject: "..subject.."\n")
socket:write(message)
socket:close()
