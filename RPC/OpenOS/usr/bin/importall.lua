local vcomponent = require "vcomponent"
local r2r = require "r2r"
local tA = {...}
local host = tA[1]

if #tA < 1 then
 print("Usage: importcomponent <host>")
 return
end

local cm = r2r.call(host,"listcomponents")

for k,v in cm do
    ctype = v
    addr = k
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
    os.sleep(2)
end

