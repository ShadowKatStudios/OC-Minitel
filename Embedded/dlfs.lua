c=""
do
local host,port,FD=component.invoke(component.list("eeprom")(),"getData"):match("(.+)\n(.+)\n(.+)")
port=tonumber(port)
local fs,dirlist,filelist=component.proxy(computer.tmpAddress()),{FD},{}
for _,dir in pairs(dirlist) do
 local content,ftype = fget(host,dir,port)
 if ftype == "d" then
  for line in content:gmatch("[^\n]+") do
   if line:sub(-1) == "/" then
    dirlist[#dirlist+1] = dir..line
   else
    filelist[#filelist+1] = dir..line
   end
  end
 end
end
for _,dir in pairs(dirlist) do
 dir=dir:sub(#dirlist[1])
 fs.makeDirectory(dir)
end
for _,file in pairs(filelist) do
 local filename=file:sub(#dirlist[1]+1)
 local content,ftype = fget(host,file,port)
 f=fs.open(filename,"wb")
 fs.write(f,content)
 fs.close(f)
end
local fh,b = fs.open("boot.lua"),""
repeat
 b=fs.read(fh,4096) or ""
 c=c..b
until b == ""
end
computer.getBootAddress = computer.tmpAddress
load(c)()
