do
pwd = "/boot"
local shenv = {}
setmetatable(shenv,{__index=_G})

local function simplify(path)
 local npath, rstr = {}, ""
 for k,v in ipairs(fs.segments(path)) do
  if v == ".." then
   npath[#npath] = nil
  elseif v ~= "." then
   npath[#npath+1] = v
  end
 end
 for k,v in pairs(npath) do
  rstr = rstr .. "/" .. v
 end
 return rstr
end
local function lpath(path)
 if not path then return end
 if path:sub(1,1) == "/" then -- absolute path
  return simplify(path)
 else
  return simplify(pwd.."/"..path)
 end
end

function shenv.ls(path)
 path = lpath(path) or pwd
 return table.unpack(fs.list(path))
end
function shenv.mkdir(path)
 path = lpath(path) or pwd
 return fs.makeDirectory(path)
end
function shenv.rm(path)
 path = lpath(path) or pwd
 return fs.remove(path)
end
function cd(path)
 path = path or "."
 pwd = lpath(path)
end
shenv.shutdown = computer.shutdown

while true do
 write(pwd.."> ")
 local inp, tWords = read(), {}
 for word in inp:gmatch("%S+") do
  tWords[#tWords+1] = word
 end
 if tWords[1] then
  if type(shenv[tWords[1]]) == "function" then
   local fname = table.remove(tWords,1)
   local tres = {pcall(shenv[fname],table.unpack(tWords))}
   if tres[1] == true then
    table.remove(tres,1)
   end
   for k,v in pairs(tres) do print(v) end
  elseif fs.exists(lpath(tWords[1])) or fs.exists(tostring(lpath(tWords[1]))..".lua") then
   local fname = table.remove(tWords,1)
   local fobj = fs.open(lpath(fname),"rb") or fs.open(tostring(lpath(fname))..".lua","rb")
   if fobj then
    local fcontent = fobj:read("*a")
    fobj:close()
    local tres = {pcall(load(fcontent),table.unpack(tWords))}
    if tres[1] == true then
     table.remove(tres,1)
    end
    print(table.unpack(tres))
   else
    print("error opening file")
   end
  elseif load(inp) then
   print(pcall(load(inp,"input","t",shenv)))
  elseif #tWords > 0 then
   print("error: file or builtin function not found")
  end
 end
end
end
