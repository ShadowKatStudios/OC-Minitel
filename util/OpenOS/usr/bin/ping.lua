local net = require "minitel"
local computer = require "computer"
local event = require "event"

local tArgs = {...}
local addr = tArgs[1]
local times = tonumber(tArgs[2]) or 5
local wait = tonumber(tArgs[3]) or 30

for i = 1, times do
 local ipt = computer.uptime()
 local pid = net.genPacketID()
 computer.pushSignal("net_send",1,tArgs[1],0,"ping",pid)
 local t,a = event.pull(wait,"net_ack",pid)
 if t == "net_ack" and a == pid then
  print("Ping reply: "..tostring(computer.uptime()-ipt).." seconds.")
 else
  print("Timed out.")
 end
end
