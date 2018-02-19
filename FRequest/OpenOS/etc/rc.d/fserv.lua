local net = require "net"
local fs = require "filesystem"
local event = require "event"

local prefix = "/srv"
local process = nil
local listener = nil
local dbug = false

local function dprint(...)
 if dbug then
  print(...)
 end
end

function start()
 process = net.flisten(70,function(s)
 local buffer = ""
 local function lf()
  buffer=s:read(1024)
  local nl = buffer:find("\n")
  if nl then
   local path=prefix .. "/" .. buffer:sub(1,nl-1)
   dprint(path)
   if fs.exists(path) then
    if fs.isDirectory(path) then 
     if fs.exists(path.."/index") then
      s:write(f:read("*a"))
     end
     local dbuffer = ""
     for f in fs.list(path) do
      dbuffer = dbuffer..f.."\n"
      dprint(f)
     end
     s:write(dbuffer)
     s:close()
    else
     local f = io.open(path,"rb")
     s:write(f:read("*a"))
     f:close()
     s:close()
    end
   else
    dprint("404")
    s:write("file not found")
    s:close()
   end
  end
 end
 listener = lf
 event.listen("net_msg",lf)
 end)
end

function stop()
 event.ignore("net_msg",listener)
 event.ignore("net_msg",process)
end

function debug()
 dbug = not dbug
end
function set_path(newpath)
 if fs.exists(newpath) then
  prefix=newpath
  print("prefix = "..newpath)
 end
end
