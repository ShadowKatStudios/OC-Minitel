local vcomp = require "vcomponent"
local component = require "component"
local computer = require "computer"
local imt = require "interminitel"
local event = require "event"
local internet = component.internet

local addr, raddr = vcomp.uuid(),vcomp.uuid()
local poll = 0.5
local listener, timer
local socket

-- dumb keepalive stuff
local keepalive = 30
local katimer

function start(iaddr,port)
 if listener then return end
 iaddr,port = iaddr or "shadowkat.net", tonumber(port) or 4096
 socket = internet.connect(iaddr,port)
 print("Connecting to "..iaddr..":"..tostring(port).."...")
 repeat
  os.sleep(0.5)
 until socket.finishConnect()
 print("Connected!")
 
 local proxy = {}
 local rbuffer = ""
 local timer = nil
 
 function listener(t)
  rbuffer=rbuffer..(socket.read(4096) or "")
  if imt.decodePacket(rbuffer) then
   computer.pushSignal("modem_message",addr,raddr,0,0,imt.decodePacket(rbuffer))
   rbuffer = imt.getRemainder(rbuffer) or ""
  end
  if t == "internet_ready" and timer then
   event.cancel(timer)
   timer = nil
  end
 end
 timer = event.timer(poll,listener,math.huge) -- this is only here because OCEmu doesn't do internet_ready
 event.listen("internet_ready",listener)
 
 -- also dumb keepalive stuff, fix this later
 katimer = event.timer(keepalive,function()
  socket.write("\0\1\0")
 end,math.huge)
 
 function proxy.send(...)
  socket.write(imt.encodePacket(...))
 end
 
 function proxy.maxPacketSize()
  return 12288
 end
 
 proxy.type = "tunnel"
 proxy.slot = 4096
 
 local docs = {
  send = "function(data...) -- Sends the specified data to the card this one is linked to.",
  maxPacketSize = "function():number -- Gets the maximum packet size (config setting)."
 }
 vcomp.register(addr,"tunnel",proxy,docs)
end

function stop()
 if listener then
  event.ignore("internet_ready",listener)
  listener = nil
 end
 if timer then
  event.cancel(timer)
  timer = nil
 end
 if katimer then
  event.cancel(katimer)
  katimer = nil
 end
 if component.type(addr) then
  vcomp.unregister(addr)
 end
 socket.close()
end
