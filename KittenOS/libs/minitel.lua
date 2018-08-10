function returnNet(event,minitel)

local dbug = false
local computer = {}
computer.uptime = os.uptime

function print(...)
 if dbug then
  for k,v in pairs({...}) do
   neo.emergency(tostring(k)..": "..tostring(v))
  end
 end
end

event.listen("x.svc.minitel",print)

local function svcpull(id)
 repeat
  te={event.pull("x.svc.minitel")}
 until te[2] == id
 table.remove(te,1)
 return table.unpack(te)
end

function svclisten(id,fn)
 return event.listen("x.svc.minitel",function(...)
  tA = {...}
  if tA[2] == id then
   table.remove(tA,1)
   fn(table.unpack(tA))
  end
 end)
end

local net = {}
net.mtu = 4096
net.streamdelay = 60
net.minport = 32768
net.maxport = 65535
net.openports = {}

function net.genPacketID()
 local npID = ""
 for i = 1, 16 do
  npID = npID .. string.char(math.random(32,126))
 end
 return npID
end

function net.usend(to,port,data,npID)
 minitel.sendPacket(0,to,port,data,npID)
end

function net.rsend(to,port,data,block)
 local pid, stime = net.genPacketID(), computer.uptime() + net.streamdelay
 minitel.sendPacket(1,to,port,data,pid)
 if block then return pid end
 repeat
  _,rpid = svcpull("net_ack")
 until rpid == pid or computer.uptime() > stime
 if not rpid then return false end
 return true
end

-- ordered packet delivery, layer 4?

function net.send(to,port,ldata)
 local tdata = {}
 if ldata:len() > net.mtu then
  for i = 1, ldata:len(), net.mtu do
   tdata[#tdata+1] = ldata:sub(1,net.mtu)
   ldata = ldata:sub(net.mtu+1)
  end
 else
  tdata = {ldata}
 end
 for k,v in ipairs(tdata) do
  if not net.rsend(to,port,v) then return false end
 end
 return true
end

-- socket stuff, layer 5?

local function cwrite(self,data)
 if self.state == "open" then
  net.send(self.addr,self.port,data)
 end
end
local function cread(self,length)
 local rdata = ""
 rdata = self.rbuffer:sub(1,length)
 self.rbuffer = self.rbuffer:sub(length+1)
 return rdata
end

local function socket(addr,port,sclose) -- todo, add remote closing of sockets
 local conn = {}
 conn.addr,conn.port = addr,tonumber(port)
 conn.rbuffer = ""
 conn.write = cwrite
 conn.read = cread
 conn.state = "open"
 local function listener(t,f,p,d)
  if f == conn.addr and p == conn.port then
   if d == sclose then
    conn:close()
   else
    conn.rbuffer = conn.rbuffer .. d
   end
  end
 end
 local lf = svclisten("net_msg",listener)
 function conn.close(self)
  event.ignore("x.svc.minitel",lf)
  conn.state = "closed"
  net.rsend(addr,port,sclose)
 end
 return conn
end

function net.open(to,port)
 if not net.rsend(to,port,"openstream") then return false, "no ack from host" end
 local st = computer.uptime()+net.streamdelay
 local est = false
 while true do
  _,from,rport,data = svcpull("net_msg")
  print("from",from,"port",rport,"data",data)
  if to == from and rport == port then
   print("Connection",from,rport,data)
   if tonumber(data) then
    est = true
   end
   break
  end
  if st < computer.uptime() then
   return nil, "timed out"
  end
 end
 if not est then
  return nil, "refused"
 end
 data = tonumber(data)
 sclose = ""
 repeat
  _,from,nport,sclose = svcpull("net_msg")
 until from == to and nport == data
 return socket(to,data,sclose)
end

function net.listen(port)
 repeat
  _, from, rport, data = svcpull("net_msg")
 until rport == port and data == "openstream"
 local nport = math.random(net.minport,net.maxport)
 local sclose = net.genPacketID()
 net.rsend(from,rport,tostring(nport))
 net.rsend(from,nport,sclose)
 return socket(from,nport,sclose)
end

function net.flisten(port,listener)
 local function helper(_,t,from,rport,data)
  if rport == port and data == "openstream" then
   local nport = math.random(net.minport,net.maxport)
   local sclose = net.genPacketID()
   net.rsend(from,rport,tostring(nport))
   net.rsend(from,nport,sclose)
   listener(socket(from,nport,sclose))
  end
 end
 return svclisten("net_msg",helper)
end

return net

end
return returnNet
