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
			print("[Init] Writing file " .. name .. "...")
			write_file(name, file)
		end
	end

	if init_data.pastebins then
		for name, pastebin in pairs(init_data.pastebins) do
			fs.delete(name)
			shell.run("pastebin", "get", pastebin, name)
			print("[Init] Loading pastebin " .. pastebin .. " in file " .. name .. "...")
		end
	end

	if init_data.urls then
		for name, url in pairs(init_data.urls) do
			fs.delete(name)
			shell.run("wget", url, name)
			print("[Init] Loading URL " .. url .. " in file " .. name .. "...")
		end
	end

	if init_data.github then
		-- github= { "zyuiop/CCPrograms/master"= { "local_file"="target_file"}}
		-- github= { "zyuiop/CCPrograms"={"..."}}
		for repo, data in pairs(init_data.github) do
			-- Check if the branch is already in the repo name
			_, n = repo:gsub("/", "")

			if n == 0 or n > 2 then
				print("[Github] Invalid GitHub repo '" .. repo .. "'")
			else
				if n == 1 or s:sub(#s) == "/" then
					if n == 1 then repo = repo .. "/" end
					repo = repo .. "master"
				end

				for name, file in pairs(data) do			
					fs.delete(name)
					url = "https://raw.githubusercontent.com/" .. repo .. "/" .. file
					print("[GitHub] Downloading file " .. file .. " as " .. name .. " from repo " .. repo)
					shell.run("wget", url, name)
				end
			end
		end
	end

	if init_data.startup then
		for i, filename in pairs(init_data.startup) do
			print("[Init] Starting program " .. filename .. "...")
			local new_shell = shell.openTab(filename)
			multishell.setTitle(new_shell, filename)
		end
	end

	print("[Init] Initialization is complete.")
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
	print("		Host replied with init configuration.")
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
				print("[Info] Received reboot packet, ending.")
				loop = false
			end,
		["update"] = 
			function (sender, data) 
				print("[Info] Received update packet, applying states.")
				handle_init(data)
			end
	}

	while loop do
		local event, p1, p2, p3 = os.pullEvent()

		if event == "rednet_message" and p1 == sid and p3 == PROTOCOL then
			local handler = handlers[p2.message]

			if handler == nil then
				print("[Network] Received unknown packet " .. p2.message)
			else
				handler(p1, p2.data)
			end
		elseif p1 == last_ping_timer then
			print("[Error] No ping received in the last 30 seconds.")
			print("[Network] Cancelling connection.")
			return
		end
	end

end


-- Init network connection

rednet.open(modem_position)
rednet.host(LOOKUP_CLIENT, hostname)

while true do
	print("[Init] Trying to find a Craftsible Server...")
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