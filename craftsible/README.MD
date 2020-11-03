# CraftSible

CraftSible (inspired from Red Hat's Ansible) is a light client/server protocol that enables centralized management of a fleet of computers.

One (or multiple) servers provide all the files that computers need to boot.

When booting, computers retrieve the files they need from the central server.

# Deployment

CraftSible relies on `multishell` APIs and therefore requires advanced computers to work (or turtles).

## Deploy the server

1. Create the server. You will need to deploy the `server.lua` file on the target computer. You can use `pastebin get ZWEMNDwq server`.
2. Start the server
3. Stop the server using `CTRL + T`.
4. In `craftsible/dist`, create the file `client` that will contain the client software. Usually, you want to use the standard `craftible` client (`client.lua`). You can use `pastebin get Kcb4fuDV /craftsible/dist/client`
5. You can now restart the server. We suggest doing so in an other tab: `fg server`. 

## Deploy the client

> :warning: The startup script of CraftSible **erases** all files in the root directory at boot, except the `startup` and `.settings` file. 

> :warning: The install script replaces the `startup` file of the computer. 

A client is easy to deploy. Simply attach a rednet modem to a side, then run the install script (`setup.lua`): `pastebin run jpJS3t6N`.

This script will download and install the startup script you can find in `startup.lua`. 

## Deployment configurations

When a client starts, it will first broadcast a `client_init` command. Any server can reply, sending back the content of the `/craftsible/dist/client` file. This file is saved as `/net_startup.lua` and immediately executed.

The default client then tries to connect to a server. It will stay connected to that server for the rest of its lifetime. When connecting, it will send a `client_hello` message with its hostname.

The server will reply with a list of states to apply. These states are configured on the server.

When a host connects, the following file is loaded first: `/craftsible/hosts/<hostname>`. If this file doesn't exist, `/craftsible/hosts/default` is loaded instead. If this file doesn't exist either, the default configuration `{ configs = { "default" }` is loaded instead.

This file is a standard ComputerCraft settings file. It **CAN** contain the following fields:
 - `pastebins`: a table ; requires the client to download some pastebin files. The key of each element is the **target file name/path** and the value is the **pastebin id**. For example, to replace startup script at boot you can do `{ pastebins = { ["startup"] = "2FeYawja"}}`.
 - `files`: a table ; sends files from the server to the client. The key of each element is the **target file name/path** on the client, and the value is the **local file path on the server, relative to `/craftsible/dist/`.**
 - `startup`: a list ; lists programs that must be executed on startup. These programs will be executed **after** downloading files and pastebins. They will each be executed in a new multishell.
 - `configs`: a list ; lists general configuration that must apply to this host (see below).

The `configs` list is used to load "generic" configuration values. Each configuration must correspond to a file in `/craftsible/configs/` (for example, config `default` is in file `/craftsible/configs/default`). Adding a config that doesn't exist in a `configs` list has no effect.

A `config` file is a standard ComputerCraft settings file. It can contain `pastebins`, `files` and `startup` fields. Please note that recursive `configs` fields are not implemented yet (e.g. a configuration cannot have a `configs` field itself).

If multiple values clash (e.g. two different configs set the same program to a different pastebin ID), the last config has precedence. The host configuration always has precedence on all the configurations.

### Advice

We suggest you to always add the `default` config in your `configs` array, and to set it (at least) as follows:

```lua
{
	["pastebins"] = {
		["startup"] = "2FeYawja"
	}
}
```

This means that at boot, all clients will update their `startup` script (the one that downloads and starts the client). This allows you to update all the files on your clients seamlessly :)

## Commands

The server has commands. Type `help` in the server console to see them.