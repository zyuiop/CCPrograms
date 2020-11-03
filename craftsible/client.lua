-- CRAFTSIBLE Client v0.1
-- Currently under Kcb4fuDV

PROTOCOL = "craftsible"
LOOKUP_CLIENT = "craftsible_client"
LOOKUP_SERVER = "craftsible_server"

-- Load configuration
modem_position = settings.get("modem_position", "front")
hostname = os.computerLabel()

if hostname == nil then 
	hostname = "host_" .. os.computerID()
end

function write_file(name, content)
	local handle = fs.open(name, "w")
	handle.write(content)
	handle.flush()
	handle.close()
end

function handle_init(init_data)
	if init_data.files then
		for name, file in pairs(init_data.files) do
			print("[Network::Init] Writing file " .. name .. "...")
			write_file(name, file)
		end
	end

	if init_data.pastebins then
		for name, pastebin in pairs(init_data.pastebins) do
			fs.delete(name)
			shell.run("pastebin", "get", pastebin, name)
			print("[Network::Init] Loading pastebin " .. pastebin .. " in file " .. name .. "...")
		end
	end

	if init_data.startup then
		for i, filename in pairs(init_data.startup) do
			print("[Network::Init] Starting program " .. filename .. "...")
			local new_shell = shell.openTab(filename)
			multishell.setTitle(new_shell, filename)
		end
	end

	print("[Network::Init] Initialization is complete.")
end

function connect(server_id)
	rednet.send(server_id, {message="client_hello", data={hostname=hostname}}, PROTOCOL)
	local sid, msg = rednet.receive(PROTOCOL, 5)

	if sid == nil then
		print("		Host timeout.")
		return
	end

	if msg == nil or msg.message ~= "server_hello" then
		print("		Invalid message received.")
		return
	end

	-- Parse message
	print("		Host successfully replied with init configuration.")
	handle_init(msg.data)


	-- Start main loop
	last_ping_timer = os.startTimer(30)
	loop = true

	handlers = {
		["server_ping"] = 
			function (sender, data)
				rednet.send(sender, {message="client_pong"}, PROTOCOL)
				os.cancelTimer(last_ping_timer)
				last_ping_timer = os.startTimer(30)
			end,
		["reboot"] = 
			function (sender, data) 
				rednet.send(sender, {message="client_goodbye", data={hostname=hostname}}, PROTOCOL)
				print("[Network::Info] Received reboot packet, ending.")
				loop = false
			end,
		["update"] = 
			function (sender, data) 
				print("[Network::Info] Received update packet, applying new init states.")
				handle_init(data)
			end
	}

	while loop do
		local event, p1, p2, p3 = os.pullEvent()

		if event == "rednet_message" and p1 == sid and p3 == PROTOCOL then
			local handler = handlers[p2.message]

			if handler == nil then
				print("[Network::Warn] Received unknown packet " .. p2.message)
			else
				handler(p1, p2.data)
			end
		elseif p1 == last_ping_timer then
			print("[Network::Error] No ping received in the last 30 seconds.")
			print("[Network] Cancelling connection.")
			return
		end
	end

end


-- Init network connection

rednet.open(modem_position)
rednet.host(LOOKUP_CLIENT, hostname)

while true do
	print("[INIT] Trying to find a Craftsible Server...")
	host = rednet.lookup(LOOKUP_SERVER)

	if host == nil then
		print("		Error: cannot get a valid server. Will retry in 3 seconds.")
		sleep(3)
		print("")
	else
		print("		Found host " .. host .. ", announcing.")
		connect(host)
		print("[Network::Closed] Connection to " .. host .. " was terminated. Rebooting in 3 seconds.")
		sleep(3)
		os.reboot()
	end
end