# MMail - simple mail protocol

MMail, or Minitel Mail, is a simple electronic mail protocol for Minitel networks, using port 25.

## Messages

A message must contain:

 - A line with `From: ` and an address, specifying where this mail came from, in the form of `user@host`
 - A line with `To: ` and an address, specifying to whom this mail is addressed to, in the form of `user@host`
 - A line with `Subject: ` and a subject line, specifying the subject of the message.

The entire exchange will be written to the file, but those lines are required.

## Sending

Sending a MMail message is simple:

1. The client opens a connection to the server on the MMail port.
2. The client sends the header, with To, From and Subject lines.
3. The client sends the message contents.
4. The client closes the connection.

The server can then decide what to do with the message.
