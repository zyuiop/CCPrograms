-- Startup screen
-- v1.0.0 - works
-- v1.0.1 - retries 10 times
-- Hosted under 2FeYawja

PROTOCOL = "craftsible"

-- Clear files
print("Cleaning working directory...")
for _, f in pairs(fs.list("/")) do
	if not fs.isDir(f) and f ~= "startup" and f ~= ".settings" then
		print(" .. Removing file " .. f)
		fs.delete(f)
	end
end

-- Load configuration
print("Downloading client...")

modem_position = settings.get("modem_position", "front")
rednet.open(modem_position)

n_times = 0
id = nil

while n_times < 10 and id == nil do
	rednet.broadcast({message = "client_init"}, PROTOCOL)
	id, data = rednet.receive(PROTOCOL, 10)

	n_times = n_times + 1
	if id == nil then
		print("Timeout at attempt " .. n_times .. "...")
	end
end

if id == nil then
	print("Timeout. Restarting.")
	os.reboot()
	return
end

print("Saving client as '/net_startup.lua'")
local f = io.open("net_startup.lua", "w")
f:write(data.data)
f:flush()
f:close()

print("Done, starting.")

sh = shell.openTab("shell")
multishell.setTitle(sh, "Shell")
multishell.setTitle(multishell.getCurrent(), "Craftsible Client")

shell.run("net_startup.lua")

print("Terminated. Rebooting in 3 seconds.")
os.sleep(3)
os.reboot()