# Minitel for OpenOS

This package includes the FRequest daemon, in etc/rc.d/frequest.lua, and the fget FRequest client, in usr/bin/fget.lua.

## fget client

### Installation

#### With OPPM

1. Run `oppm install fget`

#### Manual

1. Place fget.lua into /usr/bin

### Invocation

fget can be used to get both directory listings and files, provided the server allows it.

To use fget, run:

```
fget <host[:port]> <path>
```

## fserv daemon

fserv is the FRequest server. It provides directory listing and file transfer.

### Installation

#### With OPPM

1. Run `oppm install frequestd`

#### Manual

1. Place fserv.lua into /etc/rc.d
2. Run rc frequestd enable; rc minitel start

### Configuration

The fserv daemon does not keep a configuration file, so settings have to be set every boot.

To change a setting, one invokes:

`rc fserv set_<option> value`

#### Available settings

- port: the minitel port the FRequest server runs on
- path: the root path of the server

In addition, one can invoke *rc fserv debug* to get large amounts of debug output.
