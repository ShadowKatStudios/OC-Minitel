local net = require "net"
local fs = require "filesystem"
local event = require "event"

local prefix = "/var/maildir"
local process = nil
local listener = nil
local dbug = false
local hostname = os.getenv("HOSTNAME") or ""

local function dprint(...)
 if dbug then
  print(...)
 end
end

function start()
 fs.makeDirectory(prefix)
 process = net.flisten(25,function(s)
  local buffer = ""
  local function processBuffer()
   event.ignore("net_msg",listener)
   local to,from = nil,nil
   for l in buffer:gmatch("[^\n]+") do
    local tw={}
    for w in l:gmatch("%S+") do
     tw[#tw+1] = w
    end
    if tw[1] == "To:" then
     to=tw[2]
    elseif tw[1] == "From:" then
     from=tw[2]
    end
    to=to:match("(.+)@"..hostname) or to
   end
   if to and from then
    dprint(to,from)
    if fs.exists(prefix.."/"..to) then
     fs.makeDirectory(prefix.."/"..to.."/new")
     fs.makeDirectory(prefix.."/"..to.."/tmp")
     fs.makeDirectory(prefix.."/"..to.."/cur")
     local index = 0
     if fs.exists(prefix.."/"..to.."/tmp/index") then
      index=tonumber(io.open(prefix.."/"..to.."/tmp/index","rb"):read("*a")) or 0
     end
     local f = io.open(prefix.."/"..to.."/tmp/index","wb")
     f:write(tostring(index+1))
     dprint(tostring(index+1))
     dprint(index)
     f:close()
     f = io.open(prefix.."/"..to.."/tmp/"..tostring(index),"wb")
     f:write(buffer)
     dprint(buffer)
     f:close()
     fs.rename(prefix.."/"..to.."/tmp/"..tostring(index),prefix.."/"..to.."/new/"..tostring(index))
    end
   end
  end
  local function lf()
   buffer=buffer..s:read(16384)
   if s.state == "closed" then
    dprint("Beginning processing.")
    processBuffer()
   end
  end
  listener = lf
  event.listen("net_msg",lf)
 end)
end

function stop()
 event.ignore("net_msg",process)
 event.ignore("net_msg",listener)
end

function debug()
 dbug = not dbug
end
