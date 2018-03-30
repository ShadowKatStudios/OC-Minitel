# Minitel
An easy-to-implement networking protocol for OpenComputers. Not to be confused with the [French computer network of the same name](https://en.wikipedia.org/wiki/Minitel).

Minitel aims to implement layers 3, 4 and 5 of the OSI model.

## Layers
### Layer 3
[Layer 3](protocol-3.md) implements addressing, meshing and datagram transmission.

### Layer 4
[Layer 4](protocol-4.md) implements ordered message delivery

### Layer 5
[Layer 5](protocol-5.md) implements reliable, ordered, bidirectional streams.

## Implementations
### OpenOS
- [Reference implementation for OpenOS](OpenOS/README.md)
### Embedded devices
- [Microtel](Embedded/microtel/README.md)

## Application-layer protocols
This repository also contains a number of implementations and specifications for application-layer protocols using Minitel.

- [FRequest](FRequest/FRequest-protocol.md)
- [Minitel Mail](MMail/MMail-protocol.md)

## Development and discussion
Code and documentation is hosted in the [Github repository](https://github.com/XeonSquared/OC-Minitel).

Discussion takes place in, among other places, the [#SKS IRC channel on EsperNet](irc://irc.esper.net/#SKS) ([webchat](https://webchat.esper.net/?channels=SKS))
