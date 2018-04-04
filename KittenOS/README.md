# Minitel for KittenOS NEO
This package includes the Minitel service, in apps/svc-minitel.lua, and the net library, in libs/net.lua.

## Minitel service

The Minitel service provides packet sending and receiving abilities.

### Installation

1. Place apps/svc-minitel.lua into `NEO Disk/apps/svc-minitel.lua`
2. Set the preference run.svc-minitel to "yes"

## Net library

The net library provides an easy way of interacting with the minitel service, and implements higher-level features of the stack.

### Installation

Place libs/net.lua into `NEO Disk/libs/net.lua`

### Usage

Due to how KittenOS's security model works, you have to initialise the library in an unusual way:

```
local minitel = neo.requireAccess("x.svc.minitel","minitel daemon access")
local computer = neo.requireAccess("k.computer","pushing packets")
local event = require("event")(neo)

local net = require("net")(event,computer,minitel)
```

This gives access to the event API, computer API and Minitel service to the net library.

### API

Being a direct port of the OpenOS version, the API is the same.

#### Layer 3

*net.genPacketID()* - returns a string of random data

*net.usend(host, port, data, pid)* - Sends an unreliable packet to *host* on *port* containing *data*, optionally with the packet ID *pid*.

*net.rsend(host, port, data)* - Sends a reliable packet to *host* on *port* containing *data*.

#### Layer 4

*net.send(host, port, data)* - Sends *data* reliably and in order to *host* on *port*.

#### Layer 5

*net.open(to,port)* - Establishes a stream to *host* on *port* and returns a stream object

*net.listen(port)* - Waits for another node to establish a stream, and returns the stream object.

#### Stream objects

*stream:write(data)* - Sends *data* to the node at the other end of the stream

*stream:read(length)* - Reads data from the stream, up to *length* bytes.

*stream:close()* - Ends the stream and prevents further writing.

#### Variables

*net.mtu = 4096* - The maximum length of the data portion of a packet for *net.send*

*net.streamdelay = 60* - The time, in seconds, *net.open* will wait for a response while trying to establish a connection.

*net.minport = 32768* - The lowest port *net.listen* will allocate to a new connection.

*net.maxport = 65535* - The highest port *net.listen* will allocate to a new connection.
