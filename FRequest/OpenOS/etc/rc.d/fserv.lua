local net = require "minitel"
local syslog = require "syslog"
local fs = require "filesystem"
local event = require "event"

local coro = {} -- table of coroutines, one per socket
local cfg = {}
local timer, listener
local isRunning = false -- simple lock

cfg.path = "/srv" -- default config
cfg.port = 70
cfg.looptimer = 0.5

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
 coro[#coro+1] = coroutine.create(function()
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
  path = fs.canonical(cfg.path.."/"..fs.canonical(path))
  sock.cname = sock.addr..":"..tostring(sock.port)
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
    sock:write(chunk)
    coroutine.yield()
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

local function sched() -- run coroutines
 if isRunning then return end
 isRunning = true
 for i = #coro, 1, -1 do -- prune dead coroutines
  if coroutine.status(coro[i]) == "dead" then
   table.remove(coro,i)
  end
 end
 for k,v in pairs(coro) do
  coroutine.resume(v)
 end
 isRunning = false
end

function start()
 if timer or listener then return end
 loadConfig()
 writeConfig()
 timer = event.timer(cfg.looptimer, sched, math.huge)
 listener = net.flisten(cfg.port, handleSocket)
end
function stop()
 if not timer or not listener then return end
 event.cancel(timer)
 event.ignore("net_msg",listener)
end
function restart()
 stop()
 start()
end
