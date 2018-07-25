# Minitel for OpenOS

This package includes the Minitel daemon, in etc/rc.d/minitel.lua, and the net library for using minitel, in usr/lib/net.lua.

## Minitel daemon

### Installation

#### With OPPM

1. Run `oppm install minitel`

#### Manual

1. Place minitel.lua into /etc/rc.d
2. Place your hostname into /etc/hostname
3. Run rc minitel enable; rc minitel start

### Configuration

The minitel daemon does not keep a configuration file, so settings have to be set every boot.

To change a setting, one invokes:

`rc minitel set_<option> value`

#### Available settings

- port: the physical port the protocol runs over
- pctime: the amount of time packets are kept in the packet cache
- retry: how many seconds between resend attempts of reliable packets
- rctime: How long items are kept in the routing cache

In addition, one can invoke *rc minitel debug* to get large amounts of debug output, *rc minitel set_route <hostname> <local_modem> <remote_modem>* to add a static route, and *rc minitel del_route <hostname>* to delete a static route.

## Net library

The net library provides an easy way of interacting with the minitel daemon, and implements higher-level features of the stack.

### API

#### Layer 3

*net.genPacketID()* - returns a string of random data

*net.usend(host, port, data, pid)* - Sends an unreliable packet to *host* on *port* containing *data*, optionally with the packet ID *pid*.

*net.rsend(host, port, data, block)* - Sends a reliable packet to *host* on *port* containing *data*. If *block* is true, don't wait for a reply.

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
