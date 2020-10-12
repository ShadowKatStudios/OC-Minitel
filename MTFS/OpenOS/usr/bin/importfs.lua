local fs = require "filesystem"
local rpc = require "rpc"
local tA = {...}
local rpath, lpath = tA[1], tA[2], tA[3]

if #tA < 2 then
 print("Usage: importfs <remote path> <local path>")
 return
end

local function parsePath(path)
 return path:match("(.+):(.+)")
end

local host, saddr = parsePath(rpath)
local px = rpc.proxy(host,"fs_"..saddr.."_")
local mc = 0
for k,v in pairs(px) do
 mc = mc + 1
end
if mc < 1 then
 error("no such remote filesystem: "..addr)
end
px.address = rpath
fs.mount(px, lpath)
