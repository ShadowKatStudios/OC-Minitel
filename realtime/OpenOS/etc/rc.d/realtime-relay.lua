local serial = require "serialization"
local computer = require "computer"
local realtime = require "realtime"
local minitel = require "minitel"
local event = require "event"
local timer, listener = false, false
local cfg = {}

local startUptime = computer.uptime()

cfg.host = ""
cfg.port = 37
cfg.sync = false
cfg.frequency = 300
cfg.offset = 0

local function saveConfig()
 local f = io.open("/etc/realtime-relay.cfg","wb")
 if not f then
  return false
 end
 f:write(serial.serialize(cfg))
 f:close()
end
local function loadConfig()
 local f = io.open("/etc/realtime-relay.cfg","rb")
 if not f then
  saveConfig()
  return false
 end
 for k,v in pairs(serial.unserialize(f:read("*a"))) do
  cfg[k] = v
 end
 f:close()
end

local function updateTime()
 startUptime = computer.uptime()
 minitel.rsend(cfg.host,cfg.port,"rqtime",true)
end

local function recvMsg(_,from,port,data)
 if port == cfg.port and from == cfg.host then
  epoch = tonumber(data)
  if not epoch then return false end
  local ut = (computer.uptime() - startUptime)/2
  realtime.update(epoch, ut, cfg.offset*60*60)
 elseif port == cfg.port and not tonumber(data) then
  minitel.rsend(from,port,realtime.time(true),true)
 end
end

function start()
 loadConfig()
 if not timer and cfg.sync then
  timer = event.timer(cfg.frequency, updateTime, math.huge)
 end
 if not listener then
  listener = event.listen("net_msg",recvMsg)
 end
 updateTime()
end
function stop()
 event.cancel(timer)
 timer = nil
 event.ignore("net_msg",recvMsg)
 listener = false
end
