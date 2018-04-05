local vcomp = require "vcomponent"
local component = require "component"
local computer = require "computer"
local imt = require "interminitel"
local event = require "event"
local internet = component.internet
local tArgs = {...}

local addr, raddr = vcomp.uuid(),vcomp.uuid()

local socket = internet.connect(tArgs[1],tonumber(tArgs[2]))
repeat
 os.sleep(1)
until socket.finishConnect()

local proxy = {}
local rbuffer = ""

local timer = event.timer(5,function()
 rbuffer=rbuffer..(socket.read(4096) or "")
 if imt.decodePacket(rbuffer) then
  computer.pushSignal("modem_message",addr,raddr,0,0,imt.decodePacket(rbuffer))
  rbuffer = imt.getRemainder(rbuffer) or ""
 end
end,math.huge)

function proxy.send(...)
 socket.write(imt.encodePacket(...))
end

function proxy.maxPacketSize()
 return 12288
end

proxy.type = tunnel
proxy.slot = 4096

local docs = {
 send = "function(data...) -- Sends the specified data to the card this one is linked to.",
 maxPacketSize = "function():number -- Gets the maximum packet size (config setting)."
}
vcomp.register(addr,"tunnel",proxy,docs)
