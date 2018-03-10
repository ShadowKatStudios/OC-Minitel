# FRequest - Simple file transfer protocol - Revision 1

FRequest is a simple file transfer protocol for use on Minitel or similar networks.

## Requests

A client request consists of the following:

 - A single-character request type
 - The path for the file the client is requesting
 - A newline

Request types can be the following characters:

 - t - **t**ransfer - request file contents
 - s - **s**tat - request file size and type (format: (d or f)&lt;size&gt;)

## Server responses

The server should respond with:

 - A single character status code
 - The result of the request

Status codes can be the following characters:

 - y - **y**es - file found, read and sent
 - d - **d**irectory - directory listing sent
 - n - **n**ot found - no such file or directory
 - f - **f**ailure - other type of failure, reason sent

## Example exchange

1. The client initiates a connection to the server on the FRequest port (default 70)
2. The client sends *t* to ask for a transfer, the path *example.txt*, and a newline.
3. The server finds the file and responds with *y* followed by the file contents.
4. The server closes the connection when the transfer is completed.

Servers may wish to implement restricting users to a specific directory.

## Implementations

- [OpenOS reference implementation](OpenOS/README.md)
