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
 local function cc() -- clean the cache of old entries
  for k,v in pairs(statcache) do
   if computer.uptime() > v[1] + 1 then
    statcache[k] = nil
   end
  end
 end
 function px.isDirectory(path)
  cc()
  local ci = statcache["/"..fs.canonical(path)]
  if ci then
   return ci[3]
  end
  return oid(path)
 end
 function px.size(path)
  cc()
  local ci = statcache["/"..fs.canonical(path)]
  if ci then
   return ci[2]
  end
  return osize(path)
 end
 function px.lastModified(path)
  cc()
  local ci = statcache["/"..fs.canonical(path)]
  if ci then
   return ci[3]
  end
  return olm(path)
 end
end
fs.mount(px, lpath)
