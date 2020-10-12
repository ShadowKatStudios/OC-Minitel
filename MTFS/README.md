# MTFS

MTFS is, in effect, a standardised set of names for function endpoints implementing the [API of an OpenComputers filesystem component](https://ocdoc.cil.li/component:filesystem), over Minitel RPC.

## Function names

Names for filesystem "component" functions should follow the form `fs_<identifier>_<function>`, so, for example, `fs_/usr_isDirectory`.

## Functions

Unless otherwise specified, functions should be inherited from, or implemented to emulate, an [OpenComputers filesystem component](https://ocdoc.cil.li/component:filesystem). More specifically:

- spaceUsed
- seek
- makeDirectory
- exists
- isReadOnly
- write
- spaceTotal
- isDirectory
- rename
- list
- lastModified
- getLabel
- setLabel
- remove
- size
- open
- read
- write
- close

### Optional extensions

#### dirstat

An optional extra function, `dirstat`, may be implemented on the server side to allow clients to access directory listings with less RPC calls; it should return data in a Lua table of the following structure:

```
{
 [filename: string] = {isDirectory: boolean, size: boolean, lastModified: number},
 ...
}
```
