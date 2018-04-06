# vTunnel - Protocol

vTunnel uses a (relatively) simple protocol to communicate over TCP, encoding packets as strings and adding a tag. The protocol is as follows:

```
<2 bytes length of packet><1 byte number of segments><2 bytes length of segment><1 byte type><data>
```

2-byte lengths are encoded as big-endian, as in the following code from interminitel.lua:

```
function imt.to16bn(n)
 return string.char(math.floor(n/256))..string.char(math.floor(n%256))
end
```

Each packet can have up to 255 segments, or indeed zero.

So, to encode a packet with the field "Hello, world!":

```
0       \0
17      \17     first two bytes are length
1       \1      third is number of segments
0       \0
13      \13     length of first segment
1       \1      type of first segment (string)
72      H       data from here
101     e
108     l
108     l
111     o
44      ,
32       
119     w
111     o
114     r
108     l
100     d
33      !
```

## Types

1. string
2. number
3. boolean
4. nil

## Defaults

By default, the bridge server:

- uses port 4096, as Minitel does on OpenComputers networks
- drops clients after 60 seconds of inactivity

This can be configured by appending a port number and timeout (in seconds) to the command you use to launch the bridge.
