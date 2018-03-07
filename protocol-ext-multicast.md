### Optional: Multicast
A multicast packet has a specially formatted address part.  
The address must be a list of valid addresses, beginning with `~` seperated by the tilde character, `~`, ASCII 126.  
For example, to send to nodes `a` and `b`, the address in the packet would be `~a~b`.

Each node should send multicasts as layer 2 broadcasts, unless it is known (using the address cache) that all layer 3 destination addresses have to be sent to or forwarded by one layer 2 address.

When a multicast packet is forwarded, the addresses already seen SHOULD be removed from the packet when possible, using the address cache as a guide.

The same address MUST NOT be repeated in a multicast destination, but the duplicate MAY be ignored and just considered one, but also MAY br dropped as an invalid packet. A duplicate address MUST NOT be considered as two packets with the same contents to the same address.

A multicast packet SHOULD also be able to be broken up into multiple packets with the same contents (but they need different packet IDs!) with different addresses.

