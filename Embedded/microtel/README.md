# Microtel
Minitel for embedded devices.

## API

### microtel-3

#### net.send(*dest*,*vport*,*data*,*packetType*,*packetID*)
Sends a packet to *dest* on *vport*, containing *data*, optionally with packet type and ID as specified in *packetType* and *packetID* (defaults to 1 and randomly generated)

### microtel-4

#### net.lsend(*dest*,*vport*,*data*)
Sends an arbitrary length of data, reliably and in order, to *dest* on *port*.

### microtel-5-core

#### net.socket(*address*,*port*,*sclose*)
Creates a socket object connected to *address* on *port*, with the close message as *sclose*. Shouldn't be used by programs.

### microtel-5-open

#### net.open(*address*,*port*)
Tries to connect a socket to *address* on *port*.

### microtel-5-listen

#### net.listen(*port*)
Listens for socket connections on *port*, in a blocking manner, and returns a socket object on success.

### microtel-5-flisten

#### net.flisten(*port*,*handler*)
Adds a hook to run a *handler* function when a client tries to initiate a socket connection on *port*, giving the handler a socket object.

## Configuration

### microtel-3

#### net.port
Setting net.port changes which physical network port the Microtel stack listens on. If changed after initial loading of Microtel, you'll need to open the ports on the modems yourself. Defaults to 4096.

#### net.hostname
The name of this minitel node. Defaults to the first 8 characters of the computer address, so, for example, *15744e80*.

#### net.route
Boolean controlling whether to forward packets.

#### net.hook
Table containing functions to run on receiving an event.

### microtel-4

#### net.mtu
This controls the maximum size of the data portion of packets for *net.lsend*. Defaults to 4096, half the default physical MTU.

### microtel-5-open

#### net.timeout
The maximum time the machine will wait to initialize a connection. Defaults to 60. Not actually functional right now.
