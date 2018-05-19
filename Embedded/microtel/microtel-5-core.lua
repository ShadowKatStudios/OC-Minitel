function net.socket(address, port, sclose)
 local conn, rb = {}, ""
 conn.state, conn.buffer, conn.port, conn.address = "o", "", tonumber(port), address
 function conn.r(self,l)
  rb=self.buffer:sub(1,l)
  self.buffer=self.buffer:sub(l+1)
  return rb
 end
 function conn.w(self,data)
  net.lsend(self.address,self.port,data)
 end
 function conn.c(s)
  net.send(conn.address,conn.port,sclose)
 end
 function h(etype, from, port, data)
  if from == conn.address and port == conn.port then
   if data == sclose then
    net.hook[sclose] = nil
    conn.state = "c"
    return
   end
   conn.buffer = conn.buffer..data
  end
 end
 net.hook[sclose] = h
 return conn
end
