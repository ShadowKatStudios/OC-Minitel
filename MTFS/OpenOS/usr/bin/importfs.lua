local computer = require "computer"
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
 error("no such remote filesystem: "..rpath)
end
local statcache = {}
px.address = rpath
if px.dirstat then -- use single call for file info
 function px.list(path)
  local t,e = px.dirstat(path)
  if not t then return nil,e end
  local rt = {}
  for k,v in pairs(t) do
   rt[#rt+1] = k
   statcache[fs.canonical("/"..path.."/"..k)] = {computer.uptime(),v[1],v[2],v[3]}
  end
  return rt
 end
 local oid, osize, olm = px.isDirectory, px.size, px.lastModified
 local function gce(p,n)
  for k,v in pairs(statcache) do
   if computer.uptime() > v[1] + 1 then
    statcache[k] = nil
   end
  end
  local ci = statcache["/"..fs.canonical(p)]
  if ci then
   return ci[n]
  end
 end
 function px.isDirectory(path)
  return gce(path, 2) or oid(path)
 end
 function px.size(path)
  return gce(path, 3) or osize(path)
 end
 function px.lastModified(path)
  return gce(path, 4) or olm(path)
 end
end
local iro = px.isReadOnly()
function px.isReadOnly()
 return iro
end
fs.mount(px, lpath)
