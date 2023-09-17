local vcomponent = require "vcomponent"
local r2r = require "r2r"
local tA = {...}
local host, ctype, addr = tA[1], tA[2], tA[3]

if #tA < 3 then
 print("Usage: importcomponent <host> <component type> <component address>")
 return
end

local saddr = addr:gsub("%-","%%-")

if addr:len() < 36 then
 local flist = r2r.call(host,"list")
 for k,v in pairs(flist) do
  faddr = v:match(ctype.."_("..saddr..".*)_") or faddr
 end
end
print(faddr)
saddr = (faddr or addr):gsub("%-","%%-")
local px = r2r.proxy(host,ctype.."_"..saddr..".*_")
local mc = 0
for k,v in pairs(px) do
 mc = mc + 1
end
if mc < 1 then
 error("no such remote component: "..addr)
end
vcomponent.register(faddr or addr, ctype, px)
