local component = require "component"
local r2r = require "r2r"
local tA = {...}


for k,v in component.list() do
 local px = component.proxy(component.get(k))
 print(px.type.."_"..px.address)
 for l,m in pairs(px) do
  r2r.register(px.type.."_"..px.address.."_"..l,m)
 end
end
