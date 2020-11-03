# CraftSible Protocols

Except when stated otherwise, **all packets use protocol `CRAFTSIBLE`**. Protocol here means "the third parameter in a `rednet.send(...)` call".

Packets all use the following format: 

```lua
{
	message="<packet name>", 
	data={ 
		-- more packet data
	}
}
```

The `data` field may be missing for simple packets.

## Discovery Protocol

The discovery protocol enables the client to locate servers.

It uses the standard `rednet.host(...)` and `rednet.lookup(...)` functions.

Clients host the `CRAFTSIBLE_CLIENT` protocol, and Servers host the `CRAFTSIBLE_SERVER` protocol.

## Stateless Init Protocol

This protocol enables a client to download the client code before actually connecting to the server. It is stateless, because the client broadcasts a packet and then doesn't talk to the server again.

### 1. Client -> Server (broadcast): `client_init`

This packet is broadcast by a booting client in protocol `CRAFTSIBLE`. All servers should reply with the next packet.

### 2. Server -> Client: `client_payload`

This packet contains the client code in the `data` field, as a **string**.

Example:

```lua
{message="client_payload", data="rednet.open(...)\n..."}
```

## Hello Protocol

This protocol is used when the client connects to a server.

After issuing `client_init` and successfully downloading the client code, the client will use the **Discovery protocol** to get a server. It will then try to start a connection with that server.

### 1. Client -> Server: `client_hello`

This packet contains the client hostname in the `data` field. The client expects a `server_hello` reply.

Example:

```lua
{message="client_hello", data="computer_01"}
```

### 2. Server -> Client: `server_hello`

This packet is returned by the server with the configuration of the client as a `data` field. Specifically, the `data` table may contain:
 - `pastebins`, a table in which each key is a target path on the client filesystem, and each value is the ID of a pastebin that must **replace** the file at that path
 - `files`, a table in which each key is a target path on the client filesystem, and each value is the content of the file that must **replace** the file at that path
 - `startup`, a list of programs that must be executed by the client after applying the two previous steps.

After receiving this packet, the client will expect regular pings from the server. Otherwise, it will consider that the server has crashed and reboot itself.

## Ping protocol

The server should regularly make sure that all clients are still online, by sending the `server_ping` packet. It should be sent every 15 seconds, and a client will crash if it is not received at least every 30 seconds.

After receiving a `server_ping`, the client will send back a `client_pong`. If the client doesn't respond within 5 seconds, it must be considered offline by the server. **[This behaviour may be updated so that the server keeps tracks of crashed clients instead of forgetting about them]**

### 1. Server -> Client `server_ping`

No data attached. Broadcast by the server to all connected clients (e.g. clients that sent a `client_hello` and that did not timeout).

### 2. Client -> Server `client_pong`

No data attached. Sent back by the client to the server **if and only if** the client is connected to that server (e.g. it has received a `server_hello` from that server and has not considered the server had timed out).

The client MUST be considered timed out if this packet is not received maximum 5 seconds after the `server_ping`.

## Update protocol

### 1. Server -> Client `update`

This packet can be sent by the server to a connected client (e.g. a client that sent a `client_hello` and did not timeout). 

Its data is equivalent to `server_hello`.

It enables the server to update the state of a running client. It is used by server commands that push new files or pastebins, or that execute commands on a client.

## Reboot protocol

### 1. Server -> Client `reboot`

This packet is sent by the server to a client to order it to restart itself. The client and server will not be connected anymore after that.

The packet has no data.
