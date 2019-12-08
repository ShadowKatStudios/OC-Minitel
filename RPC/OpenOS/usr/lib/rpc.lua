local serial = require "serialization"
local computer = require "computer"
local minitel = require "minitel"
local event = require "event"
local rpcf = {}
local rpcrunning = false
local rpc = {}
rpc.port = 111
function rpc.call(hostname,fn,...)
 if hostname == "localhost" then
  return rpcf[fn](...)
 end
 local rv = minitel.genPacketID()
 minitel.rsend(hostname,rpc.port,serial.serialize({fn,rv,...}),true)
 local st = computer.uptime()
 local rt = {}
 repeat
  local _, from, port, data = event.pull(30, "net_msg", hostname, rpc.port)
  rt = serial.unserialize(data) or {}
 until rt[1] == rv or computer.uptime() > st + 30
 if table.remove(rt,1) == rv then
  return table.unpack(rt)
 end
 return false
end
function rpc.proxy(hostname,filter)
 filter=(filter or "").."(.+)"
 local fnames = rpc.call(hostname,"list")
 if not fnames then return false end
 local rt = {}
 for k,v in pairs(fnames) do
  fv = v:match(filter)
  if fv then
   rt[fv] = function(...)
    return rpc.call(hostname,v,...)
   end
  end
 end
 return rt
end

function rpc.register(name,fn)
 if not rpcrunning then
  event.listen("net_msg",function(_, from, port, data)
   if port == rpc.port then
    local rpcrq = serial.unserialize(data)
    local rpcn, rpcid = table.remove(rpcrq,1), table.remove(rpcrq,1)
    if rpcf[rpcn] then
     local rt = {pcall(rpcf[rpcn],table.unpack(rpcrq))}
     if rt[1] == true then
      table.remove(rt,1)
     end
     minitel.send(from,port,serial.serialize({rpcid,table.unpack(rt)}))
    else
    end
   end
  end)
  function rpcf.list()
   local rt = {}
   for k,v in pairs(rpcf) do
    rt[#rt+1] = k
   end
   return rt
  end
  rpcrunning = true
 end
 rpcf[name] = fn
end


return rpc
