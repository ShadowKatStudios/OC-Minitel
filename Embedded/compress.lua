local tArgs = {...}
local input = tArgs[1]
local output = tArgs[2]

local tKeywords = {"%[%[","]]","function","local","return","end","elseif","then","true","false"}
local tAvoid = {}
local tCodes = {}
local tReplace = {}
tAvoid[10] = true
tAvoid[27] = true

for i = 1, 31 do
 if not tAvoid[i] then
  tCodes[#tCodes+1] = i
 end
end

for k,v in pairs(tKeywords) do
 local newchar = table.remove(tCodes,1)
 tReplace[#tReplace+1] = {v,string.char(newchar)}
end

local f = io.open(input,"rb")
if not f then return false end
local c = f:read("*a")
f:close()
local origSize = c:len()
for k,v in pairs(tReplace) do
 v[3] = c:find(v[1])
 c=c:gsub(v[1],v[2])
end
local mSize = c:len()
c="c=[["..c.."]]for k,v in pairs({"
for k,v in pairs(tReplace) do
 if v[3] then
  c=c.."{'"..v[2].."','"..v[1].."'}"
  if k < #tReplace then
   c=c..","
  end
 end
end
c=c.."})do c=c:gsub(v[1],v[2])end load(c)()"
--c=c.."})do c=c:gsub(v[1],v[2])end print(c)"
local fullSize = c:len()
if output then
 f=io.open(output,"wb")
 f:write(c)
 f:close()
end
io.write("Original size: ")
print(origSize)
io.write("Minified size: ")
io.write(mSize)
io.write("; delta: ")
print(origSize - mSize)
io.write("RtR size: ")
io.write(fullSize)
io.write("; delta: ")
print(origSize - fullSize)
