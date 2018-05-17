local serial = require "serialization"

local tArgs = {...}
local infile = tArgs[1]
local minfile = tArgs[1]..".min"
local outfile = tArgs[2]
local dbug = true
if not outfile then dbug = false end

local function dprint(...)
 if dbug then
  print(...)
 end
end

local replacements={
{"  "," "},
{"\n ","\n"},
{"\n\n","\n"},
{" == ","=="},
{" ~= ","~="},
{" >= ",">="},
{" <= ","<="},
{" > ",">"},
{" < ","<"},
{" = ","="},
{", ",","},
{" %+ ","+"},
{" %- ","-"},
{" %/ ","/"},
{" %* ","*"},
{" \n","\n"},
{"%-%-.-\n",""},
}

dprint("Loading replacements...")

local initr = #replacements

local fmin = io.open(minfile,"rb")
if fmin then
 local nreplacements = serial.unserialize(fmin:read("*a"))
 for k,v in ipairs(nreplacements) do
  table.insert(replacements,1+k,v)
 end
end

dprint(tostring(#replacements - initr).." replacements loaded.")

local fin = io.open(infile,"rb")
local ss = fin:read("*a")
fin:close()

local initl = ss:len()

for k,v in ipairs(replacements) do
 while ss:find(v[1]) ~= nil do
  ss=ss:gsub(v[1],v[2])
 end
end

dprint("Delta: "..tostring(initl - ss:len()).." bytes")

if outfile then
 local outf = io.open(outfile,"wb")
 outf:write(ss)
 outf:close()
else
print(ss)
end
