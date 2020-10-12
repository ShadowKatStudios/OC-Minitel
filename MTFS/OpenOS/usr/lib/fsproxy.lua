local fs = require "filesystem"
local fsproxy = {}
local fsfunc = {}

local function sanitisePath(path)
 local pt = {}
 for s in path:gmatch("([^/]+)") do
  if s == ".." then
   pt[#pt] = nil
  elseif s == "." then
  else
   pt[#pt+1] = s
  end
 end
 return table.concat(pt,"/")
end


function fsproxy.new(path,wp) -- string boolean -- table -- Returns a proxy object for a given path that acts like a filesystem.
 local cpath = fs.canonical(path).."/"
 if not fs.exists(path) or not fs.isDirectory(path) then
  error("invalid directory")
 end
 local originalProxy = fs.get(path)
 local proxy = {}
 for k,v in pairs(originalProxy) do
  if type(v) ~= "table" then
   proxy[k] = v
  end
 end
 local handles = {}
 function proxy.isReadOnly()
  return originalProxy.isReadOnly()
 end
 function proxy.getLabel()
  return originalProxy.getLabel()
 end
 function proxy.spaceUsed()
  return originalProxy.spaceUsed()
 end
 function proxy.spaceTotal()
  return originalProxy.spaceTotal()
 end
 function proxy.exists(path)
  return fs.exists(cpath..sanitisePath(path))
 end
 function proxy.isDirectory(path)
  return fs.isDirectory(cpath..sanitisePath(path))
 end
 function proxy.makeDirectory(path)
  if wp then return false, "read-only filesystem" end
  return fs.makeDirectory(cpath..sanitisePath(path))
 end
 function proxy.rename(from, to)
  if wp then return false, "read-only filesystem" end
  return fs.rename(cpath..sanitisePath(from),cpath..sanitisePath(to))
 end
 function proxy.list(path)
  local rt = {}
  local iter, err = fs.list(cpath..sanitisePath(path))
  if not iter then return nil, err end
  for name in iter do
   rt[#rt+1] = name
  end
  return rt
 end
 function proxy.lastModified(path)
  return fs.lastModified(cpath..sanitisePath(path))
 end
 function proxy.remove(path)
  if wp then return false, "read-only filesystem" end
  return fs.remove(cpath..sanitisePath(path))
 end
 function proxy.size(path)
  return fs.size(cpath..sanitisePath(path))
 end
 
 function proxy.open(path,mode)
  if wp and mode:find("[wa]") then return false, "read-only filesystem" end
  local h, e = fs.open(cpath..sanitisePath(path),mode)
  if not h then return h, e end
  handles[#handles+1] = h
  return #handles
 end
 function proxy.seek(handle, whence, offset)
  return handles[handle]:seek(whence,offset)
 end
 function proxy.write(handle, data)
  return handles[handle]:write(data)
 end
 function proxy.read(handle, count)
  return handles[handle]:read(count)
 end
 function proxy.close(handle)
  return handles[handle]:close()
 end
 return proxy
end

return fsproxy
