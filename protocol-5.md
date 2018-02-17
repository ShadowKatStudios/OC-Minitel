# Minitel - Layer 5

## Language

- Node: a device on a minitel network
- Client: node establishing a connection
- Server: node accepting a connection

## Establishing a connection

- Client sends "openstream" to the server on the port it would like to connect to
- Server can refuse, and respond with anything but a number
- Server, upon accepting, sends a string representation of another port, chosen by the server, on the same port, to the client
- Server sends a random string of its chosing to the client, which will be used to close the session
- Client and server can now exchange messages

## Ending a connection

- Upon either side deciding to close, it sends the previously generated random string
- Neither side should send packets now

## Example exchange:
Acknowledgements are implied.

Client bob sends request to open a connection on port 40:  
`"packet ID 1", 1, "alice", "bob", 40, "openstream"`

Server alice accepts and sends a port to client bob for further communications:  
`"packet ID 3", 1, "bob", "alice", 40, "32800"`

Server alice then sends a string on that port as a close session marker:  
`"packet ID 4", 1, "bob", "alice", 32800, "asdfghjkl"`

Nodes alice and bob can now freely exchange data on that port:
`"packet ID 5", 1, "alice", "bob", 32800, "random data and stuff"`  
`"packet ID 6", 1, "bob", "alice", 32800, "response data"`

Client bob decides to close the connection, and sends the close session marker:  
`"packet ID 7", 1, "alice", "bob", 32800, "asdfghjkl"`
