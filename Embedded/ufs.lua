fs = {}
fs.mounts = {}

-- basics
function fs.segments(path)
 local segments = {}
 for segment in path:gmatch("[^/]+") do
  segments[#segments+1] = segment
 end
 return segments
end
function fs.resolve(path)
 local segments, rpath = fs.segments(path), "/"
 for i = 2, #segments do
  rpath = rpath .. segments[i] .. "/"
 end
 rpath = rpath:match("(.+)/") or rpath
 return segments[1] or "root",rpath
end

-- generate some simple functions
for k,v in pairs({"makeDirectory","exists","isDirectory","list","lastModified","remove","size","spaceUsed","isReadOnly","getLabel"}) do
 fs[v] = function(path)
  local fsi,path = fs.resolve(path)
  return fs.mounts[fsi][v](path)
 end
end

local function fread(self,length)
 if length == "*a" then
  length = math.huge
 end
 local rstr, lstr = "", ""
 repeat
  lstr = fs.mounts[self.fs].read(self.fid,math.min(2^16,length-rstr:len())) or ""
  rstr = rstr .. lstr
 until rstr:len() == length or lstr == ""
 return rstr
end
local function fwrite(self,data)
 fs.mounts[self.fs].write(self.fid,data)
end
local function fclose(self)
 fs.mounts[self.fs].close(self.fid)
end

function fs.open(path,mode)
 mode = mode or "rb"
 local fsi,path = fs.resolve(path)
 if not fs.mounts[fsi] then return false end
 local fid = fs.mounts[fsi].open(path,mode)
 if fid then
  local fobj = {["fs"]=fsi,["fid"]=fid,["close"]=fclose}
  if mode:sub(1,1) == "r" then
   fobj.read = fread
  else
   fobj.write = fwrite
  end
  return fobj
 end
 return false
end

function fs.copy(from,to)
 local of = fs.open(from,"rb")
 local df = fs.open(to,"wb")
 if not of or not df then
  return false
 end
 df:write(of:read("*a"))
 df:close()
 of:close()
end

function fs.rename(from,to)
 local ofsi, opath = fs.resolve(from)
 local dfsi, dpath = fs.resolve(to)
 if ofsi == dfsi then
  fs.mounts[ofsi].rename(opath,dpath)
  return true
 end
 fs.copy(from,to)
 fs.remove(from)
 return true
end


fs.mounts.temp = component.proxy(computer.tmpAddress())
if computer.getBootAddress then
 fs.mounts.boot = component.proxy(computer.getBootAddress())
end
for addr, _ in component.list("filesystem") do
 fs.mounts[addr:sub(1,3)] = component.proxy(addr)
end

local function rf()
 return false
end
fs.mounts.root = {}

for k,v in pairs(fs.mounts.temp) do
 fs.mounts.root[k] = rf
end
function fs.mounts.root.list()
 local t = {}
 for k,v in pairs(fs.mounts) do
  t[#t+1] = k
 end
 t.n = #t
 return t
end
function fs.mounts.root.isReadOnly()
 return true
end
