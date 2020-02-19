local net = require "minitel"
local syslog = require "syslog"
local fs = require "filesystem"
local event = require "event"
local serial = require "serialization"
local thread = require "thread"
local internet = require "internet"

local coro = {} -- table of coroutines, one per socket
local cfg = {}
local timer, listener
local isRunning = false -- simple lock

cfg.path = "/srv" -- default config
cfg.port = 70
cfg.looptimer = 0.5
cfg.iproxy = false

local function log(msg,level)
 syslog(msg,level,"frequestd")
end

local function loadConfig() -- load config from file
 local fobj = io.open("/etc/fserv.cfg","rb")
 if fobj then
  local ncfg = serial.unserialize(fobj:read("*a"))
  if ncfg then
   for k,v in pairs(ncfg) do
    cfg[k] = v
   end
  end
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

local function handleSocket(sock) -- create a coroutine for a new socket
 coro[#coro+1] = thread.create(function()
  local line
  repeat
   coroutine.yield()
   line = sock:read()
  until line
  local ttype, path = line:match("([ts])(.+)")
  if not ttype or not path then
   sock:write("fIncomplete request")
   sock:close()
   return false
  end
  sock.cname = sock.addr..":"..tostring(sock.port)
  if path:match("^/?(http[s]?)/") and cfg.iproxy then
   local scheme, rpath = path:match("^/?(http[s]?)/(.+)")
   log("["..sock.cname.."] "..scheme.."://"..rpath,6)
   local r = internet.request(scheme.."://"..rpath)
   if r then
    log("["..sock.cname.."] Transferring remote file.",7)
    sock:write("y")
    for s in r do
     coroutine.yield()
     sock:write(s)
    end
   else
    log("["..sock.cname.."] Unable to open remote file.",7)
    sock:write("fUnable to open remote file.")
   end
   sock:close()
   return
  end
  path = fs.canonical(cfg.path.."/"..fs.canonical(path))
  log("["..sock.cname.."] "..ttype.." "..path,6)
  if ttype == "t" then -- transfer request
   if not fs.exists(path) then
    sock:write("nFile not found.")
    sock:close()
    log("["..sock.cname.."] Not found.",7)
    return
   end
   if fs.isDirectory(path) then
    local rs = "d"
    for file in fs.list(path) do
     rs = rs..file.."\n"
    end
    sock:write(rs)
    sock:close()
    log("["..sock.cname.."] Directory.",7)
    return
   end
   local f = io.open(path,"rb")
   if not f then
    sock:write("fUnable to open file for reading",7)
    sock:close()
    return
   end
   sock:write("y")
   log("["..sock.cname.."] Transferring file.",7)
   local chunk = f:read(net.mtu)
   repeat
    coroutine.yield()
    sock:write(chunk)
    chunk = f:read(net.mtu)
   until not chunk
   sock:close()
   f:close()
   log("["..sock.cname.."] file transferred.",7)
  elseif ttype == "s" then -- stat request
   if fs.exists(path) then
    local ftype = "f"
    if fs.isDirectory(path) then
     ftype = "d"
    end
    sock:write("y"..ftype..tostring(fs.size(path)))
    sock:close()
    log("["..sock.cname.."] stat request returned.",7)
   else
    sock:write("nFile not found.",7)
    sock:close()
    log("["..sock.cname.."] Not found.",7)
   end
  end
 end)
 log("New connection: "..sock.addr..":"..tostring(sock.port),7)
end

function start()
 if timer or listener then return end
 loadConfig()
 writeConfig()
 listener = net.flisten(cfg.port, handleSocket)
end
function stop()
 if not timer or not listener then return end
 thread.waitForAll(coro)
 event.ignore("net_msg",listener)
end
function restart()
 stop()
 start()
end
