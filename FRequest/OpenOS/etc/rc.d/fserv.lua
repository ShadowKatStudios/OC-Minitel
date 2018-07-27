local net = require "net"
local event = require "event"
local syslog = require "syslog"
local fs = require "filesystem"
local computer = require "computer"
local serial = require "serialization"

local sockets = {}
local cfg = {}
cfg.path = "/srv"
cfg.looptime = 0.5
local timer = false

local function log(msg,level)
 syslog(msg,level,"frequestd")
end

local function loadConfig()
 local fobj = io.open("/etc/fserv.cfg","rb")
 if fobj then
  cfg = serial.unserialize(fobj:read("*a")) or cfg
  fobj:close()
 end
end

local function writeConfig()
 local fobj = io.open("/etc/fserv.cfg","wb")
 if fobj then
  fobj:write(serial.serialize(cfg))
  fobj:close()
 end
end

--[[
overview of how this works:
socketHandler listens for connections on port 70, places them into the sockets table
socketLoop runs quite regularly - every cfg.looptime or so.
It iterates over each socket in the sockets table, and if any of them contain a valid request, it attempts to handle it:
- calls getFile to get a status code and file contents if applicable
- writes either a failure code and message, the file contents, or the file size
Previously this was based on a listener but that caused a race condition

note to self: consider using the FS library for handling stat requests, and returning an iterator instead of an entire file for transfer requests
]]--

local function getFile(path)
 path = cfg.path .. path
 if not fs.exists(path) then
  log(path.." not found",syslog.notice)
  return "n",path.." not found"
 end
 if fs.isDirectory(path) then
  local dlist = ""
  for file in fs.list(path) do
   dlist = dlist .. file .. "\n"
  end
  return "d", dlist
 end
 local f = io.open(path,"rb")
 if not f then
  log("unable to open "..path,syslog.notice)
  return "f","unable to open "..path
 end
 local content = f:read("*a")
 f:close()
 return "y", content
end

local function socketLoop()
 for sn,socket in pairs(sockets) do
  local op, path = socket.rbuffer:match("([ts])(.+)\n")
  if op and path then
   path = fs.canonical(path)
   if path:sub(1,1) ~= "/" then
    path = "/" .. path
   end
   log("client "..tostring(socket.addr)..":"..tostring(socket.port).." requested "..path, syslog.debug)
   if op == "t" and path then
    local wf, file = getFile(path)
    socket:write(wf .. file)
    socket:close()
    sockets[sn] = nil
   elseif op == "s" and path then
    local wf, file = getFile(path)
    if wf == "y" then
     socket:write(wf..file:len())
    else
     socket:write(wf..file)
    end
    socket:close()
    sockets[sn] = nil
   end
  end
  if computer.uptime() > socket.opened + 60 then
   socket:close()
   sockets[sn] = nil
   log("dropped client "..tostring(socket.addr)..":"..tostring(socket.port).." for inactivity",syslog.debug)
  elseif socket.state ~= "open" then
   sockets[sn] = nil
   log("client "..tostring(socket.addr)..":"..tostring(socket.port).." closed socket",syslog.debug)
  end
 end
end

local function socketHandler(socket)
 log(tostring(socket.addr)..":"..tostring(socket.port).." opened",syslog.debug)
 socket.opened = computer.uptime()
 sockets[tostring(socket.addr)..":"..tostring(socket.port)] = socket
end

function start()
 loadConfig()
 writeConfig()
 net.flisten(70, socketHandler)
 timer = event.timer(cfg.looptime, socketLoop, math.huge)
end

function stop()
 event.ignore("net_msg", socketLoop)
 event.cancel(timer)
end

function set(k,v)
 if cfg[k] then
  cfg[k] = v
  print("cfg."..k.." = "..v)
 end
 writeConfig()
end
