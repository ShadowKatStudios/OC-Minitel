local event = require "event"
local serial = require "serialization"
local computer = require "computer"
local havenet, net = pcall(require,"minitel")

local hostname = os.getenv("HOSTNAME") or computer.address:sub(1,8)
local cfg = {}
cfg.port = 514
cfg.relay = false
cfg.relayhost = ""
cfg.receive = false
cfg.write = true
cfg.destination = "/dev/null"
cfg.minlevel = 6
cfg.beeplevel = -1
cfg.displevel = 2
cfg.filter = {} -- todo

local listeners = {}
local timers = {}

local function filter(msg,level,service)
 if level <= cfg.minlevel then
  return cfg.write, (cfg.relay and havenet)
 end
 return false, false
end

function reload()
 local f = io.open("/etc/syslogd.cfg","rb")
 if f then
  local newcfg = serial.unserialize(f:read("*a"))
  f:close()
  for k,v in pairs(newcfg) do
   cfg[k] = v
  end
 else
  local f = io.open("/etc/syslogd.cfg","wb")
  if f then
   f:write(serial.serialize(cfg))
   f:close()
  end
 end
 hostname = os.getenv("HOSTNAME") or computer.address:sub(1,8)
end

local function wentry(_,msg,level,service,host)
 host = host or hostname
 local ut = computer.uptime()
 local msg, service = tostring(msg), tostring(service)
 local entry = string.format("%s\t%i\t%s\n",service,level,msg)
 local dwrite, drelay = filter(msg,level,service)
 if dwrite then
  local f = io.open(cfg.destination, "ab")
  if f then
   f:write(string.format("%.2f\t%s\t",ut,host)..entry)
   f:close()
  end
 end
 if drelay then
  net.usend(cfg.relayhost, cfg.port, entry)
 end
 if level <= cfg.beeplevel then
  computer.beep()
 end
 if level <= cfg.displevel then
  io.write(string.format("%.2f\t%s\t",ut,host)..entry)
 end
end

local function remote_listener(_,from,port,data)
 if port ~= cfg.port then return false end
 local service, level, msg = data:match("(.-)\t(%d)\t(.+)")
 if not service or not level or not msg then return false end
 msg, level, service = tostring(msg),tonumber(level),tostring(service)
 wentry(nil,msg,level,service,from)
end

local function local_listener(_,msg,level,service)
 if not service or not level or not msg then return false end
 msg, level, service = tostring(msg),tonumber(level),tostring(service)
 wentry(nil,msg,level,service,hostname)
end

function start()
 reload()
 if #listeners > 0 then return end
 event.listen("syslog",local_listener)
 listeners[#listeners+1] = {"syslog",local_listener}
 if havenet and cfg.receive then
  event.listen("net_msg",remote_listener)
  listeners[#listeners+1] = {"net_msg",remote_listener}
 end
end

function stop()
 for k,v in pairs(listeners) do
  event.ignore(v[1],v[2])
 end
 for k,v in pairs(timers) do
  event.cancel(v)
 end
end
