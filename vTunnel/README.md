# vTunnel - TCP-based Linked Card Emulator

vTunnel can be used to add bridging over the internet to any existing OpenOS software that uses linked cards.

Despite originally being written for Minitel, vTunnel implements a fully-functional linked card emulator and a server that will run under most unix-likes (OpenBSD is currently somewhat flaky, Linux is recommended).

The protocol is documented [here](vtunnel-protocol.md)

## Setup

### Server

#### Requirements

- Some form of unix-like
- Lua 5.2 or 5.3
- Luasocket

#### Running the server

At present, all you need to do is run bridge.lua, for example:

```
lua53 bridge.lua [port] [timeout]
```

### Client

#### OPPM

```
oppm install vtunnel
```

#### Manual
1. Install vtunnel.lua to /usr/bin
2. Install interminitel.lua to /usr/lib

#### Starting

vTunnel is invoked as follows:

```
vtunnel <server address> <server port> [poll timer] [keepalive timer]
```

This will create a virtual linked card component connected to server\_address:server\_port

#### Minitel configuration

1. Disable minitel with rc - `rc minitel disable`
2. Add the following to your .shrc:

```
vtunnel <server address> <server port> [poll timer] [keepalive timer]
rc minitel start
```

