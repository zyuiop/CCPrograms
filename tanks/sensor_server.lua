-- This is a sensor software, that transmits on request the readings of a function in the readtank software

require("sensor")

settings.load("sensor.conf")

proto = settings.get("protocol")

-- Open rednet
rednet.open(settings.get("modem_position", "front"))
rednet.host(proto, os.computerLabel())

print("Listening to request...")

while true do
	from, msg = rednet.receive(proto)

	if msg == "read" or msg == "level" then
		rednet.send(from, read_sensor(), proto)
	end
end