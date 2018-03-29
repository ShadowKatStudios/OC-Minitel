tA={...}
f=io.open(tA[1])
ss=f:read("*a")
f:close()
print("Optimising source")
sl=tostring(ss:len())
no=0
replacements={
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
for k,v in ipairs(replacements) do
 while ss:find(v[1]) ~= nil do
  ss=ss:gsub(v[1],v[2])
  io.write(".")
  no=no+1
 end
end
print("\nBefore: "..sl.."\nAfter: "..tostring(ss:len()).."\nDelta: "..tostring(sl-ss:len()))

f=io.open(tA[2],"wb")
f:write(ss)
f:close()
