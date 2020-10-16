local fsproxy = require "fsproxy"
local fs = require "filesystem"
local shell = require "shell"
local rpc = require "rpc"

local tA, tO = shell.parse(...)
if #tA < 1 then
 print("Usage: exportfs <directory> [--rw] [--name=<name>]")
 return
end
local px = fsproxy.new(tA[1], not tO.rw)
local name = tO.name or tA[1]
for l,m in pairs(px) do
 rpc.register("fs_"..name.."_"..l,m)
end
print(string.format("%s (%s)", name, (tO.rw and "rw") or "ro"))
