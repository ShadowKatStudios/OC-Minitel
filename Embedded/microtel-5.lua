do
local hooks = {}
function computer.pullSignal(T)
 tE = {computer.pullSignal(T)}
 for k,v in pairs(hooks) do
  v(table.unpack(tE))
 end
 return table.unpack(tE)
end

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
 slisten = tostring(listener)
 hooks[slisten]=listener
 function conn.close(self)
  hooks[slisten]=nil
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
  _, from, rport, data = computer.pullSignal()
 until rport == port and data == "openstream"
 local nport = math.random(net.minport,net.maxport)
 local sclose = net.genPacketID()
 net.rsend(from,rport,tostring(nport))
 net.rsend(from,nport,sclose)
 return socket(from,nport,sclose)
end
end
