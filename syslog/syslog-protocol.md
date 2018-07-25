# Syslog - Simple, network-capable event logging.

Logging is an important part of monitoring and maintaining a computer system. In the Unix world, you have [syslog](https://en.wikipedia.org/wiki/Syslog), which is, indeed, the inspiration of the Minitel syslog protocol.

Syslog for Minitel is a simple protocol designed for ease of implementation and filtering, and uses port 514 by default.

## Packet format

A syslog packet may be reliable or unreliable, and may not be larger than 4096 bytes. Each packet consists of 3 sections, separated by tabs:

- The *service* field, containing the name of the service or other software that generated the event.
- The *level* field, a number indicating the severity of the event, as specified in [RFC 5424, section 6.2.1, table 2.](https://tools.ietf.org/html/rfc5424#section-6.2.1)
- The *message* field, containing information about the event.

## Behavior of syslog servers

Once an event is received over the network, the server may choose to save, relay, filter or drop an event as it chooses.
