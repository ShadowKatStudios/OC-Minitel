local computer = require "computer"
local realtime = {}
realtime.epoch, realtime.uptime, realtime.offset = 0, computer.uptime(), 0

function realtime.update(epoch,uptime,offset)
 if type(epoch) ~= "number" or type(uptime) ~= "number" then
  return false
 end
 realtime.epoch, realtime.uptime, realtime.offset = epoch, uptime, offset or realtime.offset
 return true
end

function realtime.time(utc)
 local ofs = realtime.offset
 if utc then
  ofs = 0
 end
 local ut = computer.uptime()
 return (realtime.epoch+(ut-realtime.uptime))+ofs
end

return realtime
