#!/usr/bin/env bash
#microtel-3.lua
cp microtel-3.lua microtel-3-mini.lua
sed -i -e 's/eventTab/Z/g' \
-e 's/modems/M/g' \
-e 's/qPacket/qP/g' \
-e 's/packetID/pID/g' \
-e 's/packetType/pT/g' \
-e 's/to/T/g' \
-e 's/vport/vP/g' \
-e 's/data/D/g' \
-e 's/rawSendPacket/rS/g' \
-e 's/sendPacket/sP/g' \
-e 's/genPacketID/gP/g' \
-e 's/packetCache/pC/g' \
-e 's/checkCache/cC/g' \
-e 's/routeCache/rC/g' \
-e 's/realComputerPullSignal/rCPE/g' \
-e 's/packetQueue/pQ/g' \
-e 's/computer/C/g' \
-e 's/C.uptime/U/g' \
-e 's/table.unpack/Y/g' \
-e 's/COMPUTER/computer/g' \
-e 's/UPTIME/C.uptime/g' \
-e 's/UNPACK/table.unpack/g' microtel-3-mini.lua
lua strip.lua microtel-3-mini.lua microtel-3-mini.lua

#microtel-4.lua
cp microtel-4.lua microtel-4-mini.lua
sed -i -e 's/to/T/g' microtel-4-mini.lua
sed -i -e 's/vport/P/g' microtel-4-mini.lua
sed -i -e 's/ldata/L/g' microtel-4-mini.lua
sed -i -e 's/tdata/D/g' microtel-4-mini.lua
lua strip.lua microtel-4-mini.lua microtel-4-mini.lua

#microtel-5-core.lua
cp microtel-5-core.lua microtel-5-core-mini.lua
sed -i -e 's/address/A/g' microtel-5-core-mini.lua
sed -i -e 's/vport/V/g' microtel-5-core-mini.lua
sed -i -e 's/sclose/S/g' microtel-5-core-mini.lua
sed -i -e 's/port/P/g' microtel-5-core-mini.lua
sed -i -e 's/conn.state/conn.s/g' microtel-5-core-mini.lua
sed -i -e 's/conn.buffer/conn.b/g' microtel-5-core-mini.lua
sed -i -e 's/self.state/self.s/g' microtel-5-core-mini.lua
sed -i -e 's/self.buffer/self.b/g' microtel-5-core-mini.lua
sed -i -e 's/self/s/g' microtel-5-core-mini.lua
sed -i -e 's/conn/C/g' microtel-5-core-mini.lua
sed -i -e 's/etype/E/g' microtel-5-core-mini.lua
sed -i -e 's/from/F/g' microtel-5-core-mini.lua
sed -i -e 's/data/D/g' microtel-5-core-mini.lua
lua strip.lua microtel-5-core-mini.lua microtel-5-core-mini.lua

#microtel-5-listen.lua
cp microtel-5-listen.lua microtel-5-listen-mini.lua
sed -i -e 's/address/A/g' microtel-5-listen-mini.lua
sed -i -e 's/vport/V/g' microtel-5-listen-mini.lua
sed -i -e 's/sclose/S/g' microtel-5-listen-mini.lua
sed -i -e 's/port/P/g' microtel-5-listen-mini.lua
sed -i -e 's/conn.state/conn.s/g' microtel-5-listen-mini.lua
sed -i -e 's/conn.buffer/conn.b/g' microtel-5-listen-mini.lua
sed -i -e 's/conn/C/g' microtel-5-listen-mini.lua
sed -i -e 's/etype/E/g' microtel-5-listen-mini.lua
sed -i -e 's/from/F/g' microtel-5-listen-mini.lua
sed -i -e 's/data/D/g' microtel-5-listen-mini.lua
lua strip.lua microtel-5-listen-mini.lua microtel-5-listen-mini.lua

#microtel-5-flisten.lua
cp microtel-5-flisten.lua microtel-5-flisten-mini.lua
sed -i -e 's/address/A/g' microtel-5-flisten-mini.lua
sed -i -e 's/vport/V/g' microtel-5-flisten-mini.lua
sed -i -e 's/sclose/S/g' microtel-5-flisten-mini.lua
sed -i -e 's/port/P/g' microtel-5-flisten-mini.lua
sed -i -e 's/conn.state/conn.s/g' microtel-5-flisten-mini.lua
sed -i -e 's/conn.buffer/conn.b/g' microtel-5-flisten-mini.lua
sed -i -e 's/conn/C/g' microtel-5-flisten-mini.lua
sed -i -e 's/etype/E/g' microtel-5-flisten-mini.lua
sed -i -e 's/from/F/g' microtel-5-flisten-mini.lua
sed -i -e 's/data/D/g' microtel-5-flisten-mini.lua
lua strip.lua microtel-5-flisten-mini.lua microtel-5-flisten-mini.lua

#microtel-5-open.lua
cp microtel-5-open.lua microtel-5-open-mini.lua
sed -i -e 's/address/A/g' microtel-5-open-mini.lua
sed -i -e 's/vport/V/g' microtel-5-open-mini.lua
sed -i -e 's/sclose/S/g' microtel-5-open-mini.lua
sed -i -e 's/port/P/g' microtel-5-open-mini.lua
sed -i -e 's/conn.state/conn.s/g' microtel-5-open-mini.lua
sed -i -e 's/conn.buffer/conn.b/g' microtel-5-open-mini.lua
sed -i -e 's/conn/C/g' microtel-5-open-mini.lua
sed -i -e 's/etype/E/g' microtel-5-open-mini.lua
sed -i -e 's/from/F/g' microtel-5-open-mini.lua
sed -i -e 's/data/D/g' microtel-5-open-mini.lua
lua strip.lua microtel-5-open-mini.lua microtel-5-open-mini.lua
