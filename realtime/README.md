# realtime for OpenComputers

Given the lack of a good way to get the real-world time from an OpenComputers machine, the *realtime* library and protocol were created.

## OpenOS
The realtime package for OpenOS includes:

- The [realtime library](OpenOS/usr/lib/realtime.lua) itself, for OpenOS
- [realtime-sync](OpenOS/etc/rc.d/realtime-sync.lua), for synchronising with the real world
- [realtime-relay](OpenOS/etc/rc.d/realtime-relay.lua), for synchronising with another OpenComputers machine

These can be installed as oppm packages, and documentation can be found [here](OpenOS/usr/man)
