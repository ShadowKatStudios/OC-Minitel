# syslog for OpenOS

This package contains a syslog library, and a syslog daemon, for OpenOS. These are separated, as the daemon is optional and can be replaced at will.

## Installation

Library:

```
oppm install libsyslog
```

Daemon:

```
oppm install syslogd
```

## Usage

### Library

The syslog library only provides one function, so the library can be called. In addition, the library provides a number of pre-configured event levels:

 - syslog.emergency 
 - syslog.alert 
 - syslog.critical 
 - syslog.error 
 - syslog.warning 
 - syslog.notice 
 - syslog.info 
 - syslog.debug 

An example using syslog as both a function and a table:

```lua
local syslog = require "syslog"
syslog("message", syslog.emergency, "service name")
```

### Daemon

The syslog daemon lives in */etc/rc.d/syslogd.lua*, and as such is managed as an rc program:

```
rc syslogd enable
rc syslogd start
rc syslogd reload
```

In addition, the daemon keeps a configuration file in */etc/syslogd.cfg*. This is stored as a Lua table and may be edited in whatever way you see fit. It has the following fields and default values:

|Field		| Default value	|
| ---		| ---		|
|port		| 514		|
|relay		| false		|
|relayhost	| ""		|
|receive	| false		|
|write		| true		|
|destination	| "/dev/null"	|
|minlevel	| 6		|
|beeplevel	| -1		|
|displevel	| 2		|
|filter		| {}		|

## Technical details

The syslog library and daemon communicate via events, namely a *syslog* event. The format is as follows:

```
"syslog", message, level, service
```
