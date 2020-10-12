local fsproxy = require "fsproxy"
local rpc = require "rpc"
local fs = require "filesystem"

local tA = {...}
if #tA < 1 then
 print("Usage: exportfs <directory> [directory] ...")
 return
end

for k,v in pairs(tA) do
 local px = fsproxy.new(v)
 for l,m in pairs(px) do
  rpc.register("fs_"..v.."_"..l,m)
 end
 print(v)
end
