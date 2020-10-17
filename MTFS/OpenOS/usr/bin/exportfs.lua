local fsproxy = require "fsproxy"
local fs = require "filesystem"
local shell = require "shell"
local rpc = require "rpc"

local tA, tO = shell.parse(...)
if #tA < 1 then
 print("Usage: exportfs <directory> [-d] [--rw] [--name=<name>] [--allow=hostname[,hostname,...]] [--deny=hostname[,hostname,...]]")
 return
end

local allow, deny = {}, {}
for host in (tO.allow or ""):gmatch("[^,]+") do
 allow[#allow+1] = host
end
for host in (tO.deny or ""):gmatch("[^,]+") do
 deny[#deny+1] = host
end

local px = fsproxy.new(tA[1], not tO.rw)
local name = tO.name or tA[1]
for l,m in pairs(px) do
 m = not tO.d and m or nil
 rpc.register("fs_"..name.."_"..l,m)
 for k,v in pairs(allow) do
  rpc.allow("fs_"..name.."_"..l,v)
 end
 for k,v in pairs(deny) do
  rpc.deny("fs_"..name.."_"..l,v)
 end
end
print(string.format("%s (%s)", name, (tO.rw and "rw") or "ro"))
