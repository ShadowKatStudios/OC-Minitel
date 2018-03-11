#!/usr/bin/env bash
cp $1 $2
sed -i -e 's/pcache/PC/g' $2
sed -i -e 's/rcache/RC/g' $2
sed -i -e 's/pqueue/pQ/g' $2
sed -i -e 's/modems/M/g' $2
sed -i -e 's/genPacketID/gP/g' $2
sed -i -e 's/sendPacket/sP/g' $2
sed -i -e 's/pruneCache/pC/g' $2
sed -i -e 's/checkPCache/cPC/g' $2
sed -i -e 's/packetPusher/pP/g' $2
sed -i -e 's/component.invoke/cI/g' $2
sed -i -e 's/computer.uptime/cU/g' $2
sed -i -e 's/--subhere/local cI,cU = component.invoke,computer.uptime/g' $2
lua strip.lua $2 $2
