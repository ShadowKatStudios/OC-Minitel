local serial = require "serialization"
local component = require "component"
local computer = require "computer"
local realtime = require "realtime"
local event = require "event"
local timer = nil
local cfg = {}

cfg.url = "https://google.com"
cfg.frequency = 300
cfg.offset = 0

local function saveConfig()
 local f = io.open("/etc/realtime-sync.cfg","wb")
 if not f then
  return false
 end
 f:write(serial.serialize(cfg))
 f:close()
end
local function loadConfig()
 local f = io.open("/etc/realtime-sync.cfg","rb")
 if not f then
  saveConfig()
  return false
 end
 for k,v in pairs(serial.unserialize(f:read("*a"))) do
  cfg[k] = v
 end
 f:close()
end

local function convertToEpoch(s)
 p="%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT"
 day,month,year,hour,min,sec=s:match(p)
 months={Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
 month=months[month]
 return os.time({day=day,month=month,year=year,hour=hour,min=min,sec=sec})
end
local function updateTime()
 local ut,rq = computer.uptime(), component.internet.request(cfg.url)
 while true do
  if rq.finishConnect() then
   break
  end
 end
 local _, _, headers = rq.response()
 local date = headers.Date
 if type(date) == "table" then
  date=date[1]
 end
 realtime.update(convertToEpoch(date), ut, cfg.offset*60*60)
 rq.close()
end

function sync()
 updateTime()
 print(os.date("%Y-%m-%d %H:%M",realtime.time()))
end
function start()
 loadConfig()
 if not timer then
  timer = event.timer(cfg.frequency, updateTime, math.huge)
 end
 sync()
end
function stop()
 event.cancel(timer)
 timer = nil
end
