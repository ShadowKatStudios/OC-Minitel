# Minitel - Layer 3

## Language
Node - a device of some description on a Minitel network, ie a computer, server, microcontroller or drone.

## Behavior

### Receiving
Upon a node receiving a message addressed to itself, it should:

1. Check if the packet ID has been seen before, and if so, drop the packet
2. Check if the packet is addressed to the node, and if so, queue it as a net_msg event
3. If the packet is indeed addressed to this node, and the packet type is 1 (reliable), send an acknowledgement packet.
4. Optional: Add the sender to the address cache if it isn't already in the cache
5. Optional: If the packet is addressed to a different node, repeat the packet, preferably respecting the address cache

If the packet is, for some reason invalid, simply drop the packet.
### Optional: Meshing
If a message is not addressed to a node, and the node has not seen the packet ID before, the node should repeat it. Whether via the address in the cache or by broadcast, it should be passed on, and the hardware address added to the cache as the sender.

#### Important (Non-Optional) Notes
Broadcast packets MUST NOT be repeated, in order to keep them within the same layer 2 network, unless special precautions are taken.
If a packet is multicast and you don't support multicast, then you SHOULD NOT repeat the packet.

### Optional: Address caching
Each machine should keep a last known route cache. The exact format is up to the implementation, but it will need:

- hostname
- hardware address
- time when added to cache

It is recommended to keep the data in the cache for 30 seconds or so, then drop it, though being user-configurable is ideal.

When sending a message, check the cache for the given destination. If there is a hardware address in the cache for the destination, send the message straight to that address. Otherwise, broadcast the message.

### Optional: Broadcast address
Packets addressed to the broadcast address, an adress of just the tilde character, `~`, ASCII 126, can optionally be received by all nodes om the same layer 2 network. While a node MAY forward a broadcast packet to other nodes, it SHOULD NOT, unless both sides of the forward are prepared to handle such a packet, to avoid it going around the entire layer 3 network.

### Optional: Multicast
A multicast packet has a specially formatted address part.  
The address must be a list of valid addresses, seperated by the tilde character, `~`, ASCII 126.  
For example, to send to nodes `a` and `b`, the address in the packet would be `a~b`.

Each node should send multicasts as layer 2 broadcasts, unless it is known (using the address cache) that all layer 3 destination addresses have to be sent to or forwarded by one layer 2 address.

When a multicast packet is forwarded, the addresses already seen SHOULD be removed from the packet when possible, using the address cache as a guide.

The same address MUST NOT be repeated in a multicast destination, but the duplicate MAY be ignored and just considered one, but also MAY br dropped as an invalid packet. A duplicate address MUST NOT be considered as two packets with the same contents to the same address.

A multicast packet SHOULD also be able to be broken up into multiple packets with the same contents (but they need different packet IDs!) with different addresses.

### WIP, Optional: Network status packets

Currently undecided on specifics and taking input.

Network status messages could be used to notify other nodes that a node has come online or is going offline, and other similar information.

Requesting what nodes another node can talk to may also be an option.

## Packet Format
Packets are made up of separated parts, as allowed by OpenComputers modems.

- packetID: random string to differentiate packets from each other
- packetType, number:
 0. unreliable
 1. reliable, requires acknowledgement
 2. acknowledgement packet
- destination: end destination hostname, string
- sender: original sender of packet, string
- port: virtual port, number \< 65536
- data: the actual packet data, or in the case of an acknowledgement packet, the original packet ID, string

Strings in Minitel packets, with the exception of the data portion, have the following restrictions:

- Minimum length of 1 character
- Maximum length of 255 characters
- ASCII 0 through 31 are not allowed
- ASCII 127 is not allowed
- ASCII 128 and above (ie unicode) behavior is undefined and should be used with caution.

The address part of the packet has a furthur limitatation, the tidle character `~`, ASCII 126, may not be used as an address of a node, but is allowed in the address part as a seperator for multicast.  
An address of 0 length (an empty address) MUST be considered invalid and dropped.

The data part of the packet can contain any characters.

### Example exchange:

Node bob sends a reliable packet to node alice, on port 44:  
"asdsfghjkqwertyu", 1, "alice", "bob", 44, "Hello!"

Node alice acknowledges node bob's packet:  
"1234567890asdfgh", 2, "bob", "alice", 44, "asdsfghjkqwertyu"
