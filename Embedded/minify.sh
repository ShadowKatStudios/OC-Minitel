#!/usr/bin/env bash
#microtel-3.lua
cp microtel-3.lua microtel-3-mini.lua
sed -i -e 's/pcache/PC/g' microtel-3-mini.lua
sed -i -e 's/rcache/RC/g' microtel-3-mini.lua
sed -i -e 's/pqueue/pQ/g' microtel-3-mini.lua
sed -i -e 's/modems/M/g' microtel-3-mini.lua
sed -i -e 's/genPacketID/gP/g' microtel-3-mini.lua
sed -i -e 's/sendPacket/sP/g' microtel-3-mini.lua
sed -i -e 's/pruneCache/pC/g' microtel-3-mini.lua
sed -i -e 's/checkPCache/cPC/g' microtel-3-mini.lua
sed -i -e 's/packetPusher/pP/g' microtel-3-mini.lua
sed -i -e 's/component.invoke/cI/g' microtel-3-mini.lua
sed -i -e 's/computer.uptime/cU/g' microtel-3-mini.lua
sed -i -e 's/--subhere/local cI,cU = component.invoke,computer.uptime/g' microtel-3-mini.lua
lua strip.lua microtel-3-mini.lua microtel-3-mini.lua

#microtel-4.lua
cp microtel-4.lua microtel-4-mini.lua
sed -i -e 's/to/T/g' microtel-4-mini.lua
sed -i -e 's/vport/P/g' microtel-4-mini.lua
sed -i -e 's/ldata/L/g' microtel-4-mini.lua
sed -i -e 's/tdata/D/g' microtel-4-mini.lua
lua strip.lua microtel-4-mini.lua microtel-4-mini.lua

#microtel-5.lua
cp microtel-5.lua microtel-5-mini.lua
sed -i -e 's/hooks/H/g' microtel-5-mini.lua
sed -i -e 's/cwrite/cW/g' microtel-5-mini.lua
sed -i -e 's/cread/cR/g' microtel-5-mini.lua
sed -i -e 's/conn/C/g' microtel-5-mini.lua
sed -i -e 's/listener/lI/g' microtel-5-mini.lua
sed -i -e 's/slisten/sL/g' microtel-5-mini.lua
sed -i -e 's/self/S/g' microtel-5-mini.lua
sed -i -e 's/addr/A/g' microtel-5-mini.lua
sed -i -e 's/rbuffer/rB/g' microtel-5-mini.lua
sed -i -e 's/rport/rP/g' microtel-5-mini.lua
sed -i -e 's/nport/nP/g' microtel-5-mini.lua
sed -i -e 's/port/P/g' microtel-5-mini.lua
sed -i -e 's/sclose/sC/g' microtel-5-mini.lua
sed -i -e 's/rdata/rD/g' microtel-5-mini.lua
sed -i -e 's/length/lN/g' microtel-5-mini.lua
sed -i -e 's/data/D/g' microtel-5-mini.lua
sed -i -e 's/from/F/g' microtel-5-mini.lua
lua strip.lua microtel-5-mini.lua microtel-5-mini.lua
