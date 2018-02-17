local computer = require "computer"
local event = require "event"
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
 computer.pushSignal("net_send",0,to,port,data,npID)
end

function net.rsend(to,port,data)
 local pid = net.genPacketID()
 computer.pushSignal("net_send",1,to,port,data,pid)
 repeat
  _,rpid = event.pull("net_ack")
 until rpid == pid
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
  net.rsend(to,port,v)
 end
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
 local function listener(_,f,p,d)
  if f == conn.addr and p == conn.port then
   if d == sclose then
    conn:close()
   else
    conn.rbuffer = conn.rbuffer .. d
   end
  end
 end
 event.listen("net_msg",listener)
 function conn.close(self)
  event.ignore("net_msg",listener)
  conn.state = "closed"
  net.rsend(addr,port,sclose)
 end
 return conn
end

function net.open(to,port)
 net.rsend(to,port,"openstream")
 local st = computer.uptime()+net.streamdelay
 local est = false
 while true do
  _,from,rport,data = event.pull("net_msg")
  if to == from and rport == port then
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
  _,from,nport,sclose = event.pull("net_msg")
 until from == to and nport == data
 return socket(to,data,sclose)
end

function net.listen(port)
 repeat
  _, from, rport, data = event.pull("net_msg")
 until rport == port
 local nport = math.random(net.minport,net.maxport)
 local sclose = net.genPacketID()
 net.rsend(from,rport,tostring(nport))
 net.rsend(from,nport,sclose)
 return socket(from,nport,sclose)
end

return net
