local serial = require "serialization"
local component = require "component"
local event = require "event"

local timer = -1

local cfg = {}
cfg.broadcast = true
cfg.receive = true
cfg.delay = 60
cfg.port = 3442
cfg.message = "WoLBeacon"

local function saveConfig()
 local f = io.open("/etc/wolbeacon.lua","wb")
 if not f then
  return false
 end
 f:write(serial.serialize(cfg))
 f:close()
end

local function broadcast()
 for modem in component.list("modem") do
  component.invoke(modem,"broadcast",cfg.port,cfg.message)
 end
end

local function loadConfig()
 local f = io.open("/etc/wolbeacon.lua","rb")
 if not f then
  saveConfig()
  return false
 end
 cfg = serial.unserialize(f:read("*a")) or cfg
 f:close()
end

function start()
 loadConfig()
 if cfg.receive then
  for modem in component.list("modem") do
   component.invoke(modem,"setWakeMessage",cfg.message)
  end
 else
  for modem in component.list("modem") do
   component.invoke(modem,"setWakeMessage",nil)
  end
 end
 if cfg.broadcast then
  timer = event.timer(cfg.delay, broadcast, math.huge)
 end
end

function stop()
 event.cancel(timer)
 timer = -1
end

function reload()
 stop()
 start()
end

