#!/usr/bin/env bash
#microtel-3.lua
cp microtel-3.lua microtel-3-mini.lua
sed -i -e 's/eventTab/Z/g' microtel-3-mini.lua
sed -i -e 's/modems/M/g' microtel-3-mini.lua
sed -i -e 's/qPacket/qP/g' microtel-3-mini.lua
sed -i -e 's/packetID/pID/g' microtel-3-mini.lua
sed -i -e 's/packetType/pT/g' microtel-3-mini.lua
sed -i -e 's/to/T/g' microtel-3-mini.lua
sed -i -e 's/vport/vP/g' microtel-3-mini.lua
sed -i -e 's/data/D/g' microtel-3-mini.lua
sed -i -e 's/rawSendPacket/rS/g' microtel-3-mini.lua
sed -i -e 's/sendPacket/sP/g' microtel-3-mini.lua
sed -i -e 's/genPacketID/gP/g' microtel-3-mini.lua
sed -i -e 's/packetCache/pC/g' microtel-3-mini.lua
sed -i -e 's/checkCache/cC/g' microtel-3-mini.lua
sed -i -e 's/routeCache/rC/g' microtel-3-mini.lua
sed -i -e 's/realComputerPullSignal/rCPE/g' microtel-3-mini.lua
sed -i -e 's/packetQueue/pQ/g' microtel-3-mini.lua
sed -i -e 's/computer/C/g' microtel-3-mini.lua
sed -i -e 's/C.uptime/U/g' microtel-3-mini.lua
sed -i -e 's/table.unpack/Y/g' microtel-3-mini.lua
sed -i -e 's/COMPUTER/computer/g' microtel-3-mini.lua
sed -i -e 's/UPTIME/C.uptime/g' microtel-3-mini.lua
sed -i -e 's/UNPACK/table.unpack/g' microtel-3-mini.lua
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
