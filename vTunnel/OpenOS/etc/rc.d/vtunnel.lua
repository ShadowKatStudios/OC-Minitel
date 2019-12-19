local vcomponent = require "vcomponent"
local serial = require "serialization"
local component = require "component"
local computer = require "computer"
local event = require "event"
local imt = require "interminitel"

local cfg = {}
cfg.peers = {}
cfg.rtimer = 5
cfg.katimer = 30
local listeners = {}
local timers = {}
local proxies = {}

local function loadcfg()
 local f = io.open("/etc/vtunnel.cfg","rb")
 if not f then return false end
 for k,v in pairs(serial.unserialize(f:read("*a")) or {}) do
  cfg[k] = v
 end
 f:close()
end
local function savecfg()
 local f = io.open("/etc/vtunnel.cfg","wb")
 if not f then 
  print("Warning: unable to save configuration.")
  return false
 end
 f:write(serial.serialize(cfg))
 f:close()
end

local function createTunnel(host,port,addr,raddr)
 local proxy = {address=addr,buffer=""}
 function proxy.connect()
  if proxy.socket then
   proxy.socket.close()
  end
  proxy.socket = component.internet.connect(host,port)
  local st = computer.uptime()
  repeat
   coroutine.yield()
  until proxy.socket.finishConnect() or computer.uptime() > st+5
 end
 function proxy.send(...)
  rt = 0
  while not proxy.socket.write(imt.encodePacket(...)) and rt < 10 do
   proxy.connect()
   rt = rt + 1
  end
  proxy.last = computer.uptime()
 end
 function proxy.read()
  local rb, r
  local rt = 0
  while true do
   rb,r = proxy.socket.read(4096)
   if rb or rt > 10 then break end
   if type(rb) == "nil" then
    proxy.connect()
   end
   rt = rt + 1
  end
  proxy.buffer = proxy.buffer .. rb
  while imt.decodePacket(proxy.buffer) do
   computer.pushSignal("modem_message",addr,raddr,0,0,imt.decodePacket(proxy.buffer))
   proxy.buffer = imt.getRemainder(proxy.buffer) or ""
  end
  if computer.uptime() > proxy.last + cfg.katimer then
   proxy.socket.write("\0\1\0")
   proxy.last = computer.uptime()
  end
 end
 event.listen("internet_ready",proxy.read)
 listeners[addr] = {"internet_ready",proxy.read}
 timers[addr] = event.timer(cfg.rtimer, proxy.read, math.huge)
 proxy.connect()
 proxy.last = computer.uptime()
 return proxy
end

function start()
 loadcfg()
 for k,v in pairs(cfg.peers) do
  print(string.format("Connecting to %s:%d",v.host,v.port))
  v.addr = v.addr or vcomponent.uuid()
  v.raddr = v.raddr or vcomponent.uuid()
  local px = createTunnel(v.host, v.port, v.addr, v.raddr)
  vcomponent.register(v.addr, "tunnel", px)
  proxies[v.addr] = px
 end
end
function stop()
 for k,v in pairs(listeners) do
  event.ignore(v[1],v[2])
 end
 for k,v in pairs(timers) do
  event.cancel(v)
 end
 for k,v in pairs(proxies) do
  vcomponent.unregister(k)
 end
end

function settimer(time)
 time = tonumber(time)
 if not time then
  print("Timer must be a number.")
  return false
 end
 cfg.rtime = time
 savecfg()
end

function addpeer(host,port)
 port = tonumber(port) or 4096
 local t = {}
 t.host = host
 t.port = port
 t.addr = vcomponent.uuid()
 t.raddr = vcomponent.uuid()
 cfg.peers[#cfg.peers+1] = t
 print(string.format("Added peer #%d (%s:%d) to the configuration.\nRestart to apply changes.",#cfg.peers,host,port))
 savecfg()
end

function listpeers()
 for k,v in pairs(cfg.peers) do
  print(string.format("#%d (%s:%d)\n Local address: %s\n Remote address: %s",k,v.host,v.port,v.addr,v.raddr))
 end
end
function delpeer(n)
 n=tonumber(n)
 if not n then
  print("delpeer requires a number, representing the peer number, as an argument.")
  return false
 end
 local dp = table.remove(cfg.peers, n)
 savecfg()
 print(string.format("Removed peer %s:%d",dp.host, dp.port))
end
