local event = require("event")(neo)
local neoux = require("neoux")(event, neo)
local minitel = neo.requireAccess("x.svc.minitel","minitel daemon access")
local computer = neo.requireAccess("k.computer","pushing packets")
local net = require("net")(event,computer,minitel)

local tb = {}

local rtext = "FRequest Browser v2\nAlt-hjkl to resize\n^J and ^K to scroll"
local url = ""
local blines, dlines = {}, {}
local bbuttons, dbuttons = {}, {}
local wwidth, wheight = 30,10
local hheight = 2
local cscroll = 1
local minwidth, minheight = 16, 8
local ctrl, alt = false, false

function tb.fget(host,port,path)
 local socket = net.open(host,port)
 socket:write("t"..path.."\n")
 local c
 repeat
  c = socket:read(1)
  event.pull()
 until c ~= ""
 local buffer = ""
 repeat
  l = socket:read(1024)
  buffer=buffer..l
  event.sleepTo(os.uptime()+1)
 until socket.state == "closed" and l == ""
 if c == "n" then 
  return path..": Not found."
 elseif c == "f" then
  return "Failure: "..buffer
 elseif c == "d" then
  local t = {}
  for s in buffer:gmatch("[^\r?\n]+") do
   t[#t+1] = s
  end
  return t
 end
 return buffer
end

function tb.parseURL(url)
 local hp, path = url:match("(.-)(/.+)")
 hp, path = hp or url, path or "/"
 local host, port = hp:match("(.+):(.+)")
 host, port = host or hp, port or 70
 return host, port, path
end

function tb.loadpage()
 if url:sub(-1) == "/" then
  url = url:sub(1,-2)
 end
 local host, port, path = tb.parseURL(url)
 local page = tb.fget(host, port, path)
 if type(page) == "string" then
  rtext = page
  bbuttons = {}
 elseif type(page) == "table" then
  rtext = "Index of "..path
  bbuttons = page
 end
 cscroll = 1
 tb.format()
 tb.redraw()
end

-- UI stuff

function tb.mkbutton(name,x,y)
 x = x or 1
 return neoux.tcbutton(x,y,name,function(w)
  if name:sub(-1) == "/" then
   name = name:sub(1,-2)
  end
  url = url .."/".. name
  tb.loadpage()
 end)
end

function tb.format()
 blines = neoux.fmtText(rtext, wwidth)
 dlines = {}
 for i = cscroll, cscroll + wheight do
  dlines[#dlines+1] = blines[i]
 end
 dbuttons = {}
 for i = cscroll, cscroll + wheight do
  dbuttons[#dbuttons+1] = bbuttons[i]
 end
end

function tb.genwindow()
 local r1,r2,r2o,r2l = 1,2,1,wwidth
 fillh = 0
 hheight = 2
 if wwidth > 25 then
  r2 = 1
  r2o = 7
  r2l = wwidth - 6
  hheight = 1
 end
 tb.format()
 local wtab = {
  neoux.tcbutton(1,r1,unicode.char(8593),tb.bup),
  neoux.tcbutton(4,r1,unicode.char(9661),tb.bsave),
  --neoux.tcbutton(wwidth-2,r1,unicode.char(9711),tb.breload)
  neoux.tcfield(r2o,r2,r2l-3,tb.furl),
  neoux.tcbutton(r2o+r2l-3,r2,unicode.char(9655),tb.loadpage),
  neoux.tcrawview(1,hheight+1,dlines,wwidth)
 }
 for k,v in pairs(dbuttons) do
  wtab[#wtab+1] = tb.mkbutton(v,1,hheight+1+k)
 end
 return wtab
end

-- button callbacks

function tb.bup(w)
 local tURL = {}
 for s in url:gmatch("[^/]+") do
  tURL[#tURL+1] = s
 end
 if #tURL > 1 then
  tURL[#tURL] = nil
 end
 url = ""
 for k,v in ipairs(tURL) do
  url = url .. "/" .. v
 end
 url=url:sub(2)
 tb.breload()
end

function tb.breload(w)
 tb.loadpage()
 tb.redraw()
end

function tb.bsave()
 local f = neoux.fileDialog(true)
 if f then
  f.write(rtext.."\n")
  for k,v in pairs(bbuttons) do
   f.write(v.."\n")
  end
  f.close()
 end
end

function tb.furl(nv)
 if not nv then return url end
 url = nv
end

tb.window = neoux.create(wwidth, wheight, "FGet", neoux.tcwindow(wwidth,wheight,tb.genwindow(),function (w) w.close() done = true end, 0xFFFFFF, 0))

function tb.redraw()
 for i = 1, 2 do -- I'm a bad person.
  tb.window.reset(wwidth, wheight, "FGet", neoux.tcwindow(wwidth,wheight,tb.genwindow(),function (w) w.close() done = true end, 0xFFFFFF, 0))
 end
end

while not done do
 local et, _, et2, k1, k2 = event.pull()
 if et == "x.neo.pub.window" and et2 == "key" then
  if k1 == 0 and k2 == 56 then -- alt pressed
   alt = not alt
  elseif k1 == 0 and k2 == 157 then -- ctrl pressed
   ctrl = not ctrl
  elseif alt and k1 == 104 and k2 == 35 then -- alt-h, reduce width
   wwidth = wwidth - 1
   if wwidth < minwidth then
    wwidth = minwidth
   end
   tb.redraw()
  elseif alt and k1 == 106 and k2 == 36 then -- alt-j, increase height
   wheight = wheight + 1
   tb.redraw()
  elseif alt and k1 == 107 and k2 == 37 then -- alt-k, decrease height
   wheight = wheight - 1
   if wheight < minheight then
    wheight = minheight
   end
   tb.redraw()
  elseif alt and k1 == 108 and k2 == 38 then -- alt-l, increase width
   wwidth = wwidth + 1
   tb.redraw()
  elseif k1 == 10 and k2 == 36 then -- ctrl-j, scroll down
   cscroll = cscroll + 1
   if cscroll > #blines+#bbuttons then cscroll = #tlines end
   tb.redraw()
  elseif k1 == 11 and k2 == 37 then -- ctrl-k scroll up
   cscroll = cscroll - 1
   if cscroll < 1 then cscroll = 1 end
   tb.redraw()
  end
 end
end
