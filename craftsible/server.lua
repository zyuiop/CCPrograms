-- CRAFTSIBLE Server v0.1
-- Pastebin ZWEMNDwq

PROTOCOL = "craftsible"
LOOKUP_CLIENT = "craftsible_client"
LOOKUP_SERVER = "craftsible_server"

-- Load configuration
modem_position = settings.get("modem_position", "front")
hostname = os.computerLabel()
if hostname == nil then 
	hostname = "host_" .. os.computerID()
end

-- Check directories

function mkpath(path)
	if not fs.isDir(path) then
		if fs.exists(path) then fs.delete(path) end

		fs.makeDir(path)
	end
end

BASE_PATH = "/craftsible"
DIST_PATH = BASE_PATH .. "/dist"
CONFIGS_PATH = BASE_PATH .. "/configs"
HOSTS_PATH = BASE_PATH .. "/hosts"
CLIENT_PATH = DIST_PATH .. "/client"

mkpath(BASE_PATH)
mkpath(DIST_PATH) -- directory in which files to send will be found
mkpath(CONFIGS_PATH) -- directory in which host kinds will be found
mkpath(HOSTS_PATH) -- directory in which hosts will be found


if not fs.exists(CLIENT_PATH) then
	print("Warning: the client MUST be stored under '" .. CLIENT_PATH .. "' for distribution.")
end

-- Init network connection

clients = {}
received_pings = {}
cmd = ""

function broadcast(message)
	for client, data in pairs(clients) do
		rednet.send(client, message, PROTOCOL)
	end
end

function load_state_from_file(file)
	settings.clear()
	settings.load(file)

	local state = load_state_from_settings()

	settings.clear()
	return state
end

function load_state_from_settings()
	local files = {}

	for name, path in pairs(settings.get("files", {})) do
		local f = io.open(DIST_PATH .. "/" .. path, "r")
		files[name] = f:read("a")
		f:close()
	end

	return {
		files=files,
		pastebins=settings.get("pastebins", {}),
		urls=settings.get("urls", {}),
		github=settings.get("github", {}),
		startup=settings.get("startup", {})
	}
end

function merge_recursive(src, into)
	local target = into
	for k, v in pairs(src) do
		if into[k] ~= nil and type(into[k]) == "table" then
			target[k] = merge_recursive(v, into[k])
		else
			target[k] = v
		end
	end
	return target
end

function get_state(hostname)
	if fs.exists(HOSTS_PATH .. "/" .. hostname) then
		settings.load(HOSTS_PATH .. "/" .. hostname)
	else 
		settings.load(HOSTS_PATH .. "/default")
	end

	local state = load_state_from_settings()
	local configs = settings.get("configs", {"default"})

	local final_state = {}
	for _, conf in pairs(configs) do
		local conf_state = load_state_from_file(CONFIGS_PATH .. "/" .. conf)
		final_state = merge_recursive(conf_state, final_state)
	end

	return merge_recursive(state, final_state)
end

function printshell()
	_, y = term.getCursorPos()
	term.setCursorPos(1, y)
	term.clearLine()
	write("> " .. cmd)
end

function log(str)
	_, y = term.getCursorPos()
	term.setCursorPos(1, y)
	term.clearLine()
	print(str)
	printshell()
end

function executeshell()
	local args = {}
	for arg in cmd:gmatch("%w+") do table.insert(args, arg) end

	commands = {
		["list"] = function(args)
			print("List of connected clients:")
			for id, host in pairs(clients) do
				print(" - Host " .. host .. "\twith id " .. id)
			end
		end,

		["update"] = function(args)
			if args[1] == nil then
				print("Please provide the ID of a client to update")
				return
			end

			local client = clients[tonumber(args[1])]

			if client == nil then
				print("No client with this id. Please run 'list' to get a list of all clients.")
				return
			end

			local state = get_state(client)
			rednet.send(tonumber(args[1]), {message= "update", data= state}, PROTOCOL)
		end,

		["reboot"] = function(args)
			if args[1] == nil then
				print("Please provide the ID of a client to reboot")
				return
			end

			local client = clients[tonumber(args[1])]

			if client == nil then
				print("No client with this id. Please run 'list' to get a list of all clients.")
				return
			end
			rednet.send(tonumber(args[1]), {message= "reboot"}, PROTOCOL)
		end,

		["run"] = function(args)
			if #args < 2 then
				print("Please provide the ID of a client on which to run a program + the program to run")
				return
			end

			local client = clients[tonumber(args[1])]

			if client == nil then
				print("No client with this id. Please run 'list' to get a list of all clients.")
				return
			end

			local program_args = table.remove(table.remove(program_args, 1), 1)
			local state = {startup= program_args}
			rednet.send(tonumber(args[1]), {message= "update", data= state}, PROTOCOL)
		end,

		["push"] = function(args)
			if #args < 3 then
				print("Usage: push <client id> <local file path> <target file path>")
				return
			end

			local client = clients[tonumber(args[1])]

			if client == nil then
				print("No client with this id. Please run 'list' to get a list of all clients.")
				return
			end

			local f = io.open("/craftsible/dist/" .. args[2], "r")
			if f == nil then
				print("No such file found.")
				return
			end

			local data = f.read("a")
			f.close()

			local state = {files= {[args[3]] = data}}
			rednet.send(tonumber(args[1]), {message= "update", data= state}, PROTOCOL)
		end,

		["pastebin"] = function(args)
			if #args < 3 then
				print("Usage: pastebin <client id> <pastebin ID> <target file path>")
				return
			end

			local client = clients[tonumber(args[1])]

			if client == nil then
				print("No client with this id. Please run 'list' to get a list of all clients.")
				return
			end

			local state = {pastebins={}}
			state.pastebins[args[3]] = args[2]
			rednet.send(tonumber(args[1]), {message= "update", data= state}, PROTOCOL)
		end,

		["help"] = function(args)
			print("List of commands:")
			print("list: lists the connected clients")
			print("update <id>: updates a host with the most up to date config (reboot suggested instead)")
			print("reboot <id>: restarts a client")
			print("run <id> <program>: runs a program on a host")
			print("push <id> <local file> <target file>: sends a file to a host")
			print("pastebin <id> <pastebin ID> <target file>: asks the host to download a pastebin")
		end
	}

	local command = commands[args[1]]

	if command == nil then
		if args[1] == nil then args[1] = "nil" end
		print("Command not found '" .. args[1] .. "'")
	else 
		table.remove(args, 1)
		command(args)
	end
end

handlers = {
	["client_pong"] = function(id, data) 
			received_pings[id] = true
		end,
	["client_hello"] = function(id, data) 
			clients[id] = data.hostname
			log("[Connect] New client. ID=" .. id .. ", Hostname=" .. data.hostname)
			local state = get_state(data.hostname)

			rednet.send(id, {message= "server_hello", data= state}, PROTOCOL)
		end,
	["client_init"] = function(id, data)
			log("[Stateless] Client download from computer " .. id)

			local data = io.input(CLIENT_PATH):read("a")
			rednet.send(id, {message= "client_payload", data= data}, PROTOCOL)
		end,
	["client_goodbye"] = function(id, data)
			log("[Goodbye] Client " .. id .. " disconnected.")
			clients[id] = nil
		end,
}

rednet.open(modem_position)
rednet.host(LOOKUP_SERVER, hostname)

log("[Init] Network is ready, listening for new clients.")

ping_timer = os.startTimer(15)
pong_timer = 0

while true do
	local event, p1, p2, p3 = os.pullEventRaw()

	if event == "rednet_message" and p3 == PROTOCOL then
		local handler = handlers[p2.message]

		if handler == nil then
			log("[Network] Received unknown packet '" .. p2.message .. "'")
		else
			handler(p1, p2.data)
		end
	elseif event == "terminate" then
		broadcast({message= "reboot"})
		return
	elseif event == "timer" and p1 == ping_timer then
		received_pings = {}
		pong_timer = os.startTimer(5)
		ping_timer = os.startTimer(15)
		broadcast({message= "server_ping"})
	elseif event == "char" then
		cmd = cmd .. p1
		printshell()
	elseif event == "key" and p1 == keys.enter then
		print("")
		executeshell()
		cmd = ""
		printshell()
	elseif event == "key" and p1 == keys.backspace then
		cmd = cmd:sub(1, -2)
		printshell()
	elseif event == "timer" and p2 == pong_timer then
		for c, host in clients do
			if received_pings[c] ~= true then
				log("[Timeout] Client " .. c .. " (host: ".. host ..") timed out.")
				clients[c] = nil
			end
		end
	end
end