# FRequest - Simple file transfer protocol

FRequest is a <del>dumb</del> simple file transfer protocol for use on Minitel networks. A file transfer occurs as follows:

1. The client initiates a connection to the server on the FRequest port (default 70)
2. The client sends the path to the file they want, followed by a newline.
3. The server responds with either the contents of the requested file, a directory listing, or "file not found" if there is an error.
4. The server closes the connection.

Servers may wish to implement restricting users to a specific directory.
