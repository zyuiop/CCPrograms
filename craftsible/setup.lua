-- pastebin run jpJS3t6N

args = ...
STARTUP_PASTEBIN = args[1]

if STARTUP_PASTEBIN == nil then
	STARTUP_PASTEBIN = "2FeYawja"
end

if not multishell then
	print("This computer doesn't support multishell APIs.")
	print("This software cannot be installed on this computer.")
	return
end

retry = true
while retry do

	write("Please enter the hostname of the new computer: ")
	host = io.read()
	os.setComputerLabel(host)

	write("Please enter the modem side: ")
	side = io.read()

	settings.set("modem_position", side)

	print("Okay.")
	print("Hostname: " .. host)
	print("Modem position: " .. side)


	read = ""
	while read ~= "y" and read ~= "n" do
		write("Is this correct? [Y/N] ")
		read = io.read():lower()
	end

	if read == "y" then retry = false end
end

print("")
print("Downloading startup...")
shell.run("pastebin", "get", STARTUP_PASTEBIN, "startup")

print("Okay, rebooting in one second...")
os.sleep(1)
os.reboot()
