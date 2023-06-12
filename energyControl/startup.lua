-- pastebin get HuMUvvRa startup

-- Configure the program below:
-- battery_side: side of the computer where the battery is located
-- switch_side: side of the computer where the energy detector is located
-- start_emptying_at_pct: emptying process will start when the energy percentage in the battery reaches this point
-- stop_emptying_at_pct: emptying process will stop when the energy percentage in the battery reaches this point

battery_side = "left"
switch_side = "top"

start_emptying_at_pct = 0.95
stop_emptying_at_pct = 0.5

emptying_rate = 100000
no_emptying_rate = 0

--

states = {
	WAITING = 0,
	EMPTYING = 1
}

state = states.WAITING

battery = peripheral.wrap(battery_side)
switch = peripheral.wrap(switch_side)

capacity = battery.getMaxEnergy()
start_emptying_at = capacity * start_emptying_at_pct
stop_emptying_at = capacity * stop_emptying_at_pct

print("Hello, I will manage your battery for you !")
print("Your battery has a " .. capacity .. " FE capacity.")
print("I will start emptying it at " .. start_emptying_at .. " FE")
print("I will stop emptying it at " .. stop_emptying_at .. " FE")

print("-----------------------")
print("")

switch.setTransferRateLimit(no_emptying_rate)

while true do
	amount = battery.getEnergy()

	if state == states.WAITING and amount >= start_emptying_at then
		print("Current amount: " .. amount .. " FE, start emptying!")
		switch.setTransferRateLimit(emptying_rate)
		state = states.EMPTYING
	elseif state == states.EMPTYING and amount <= stop_emptying_at then
		print("Current amount: " .. amount .. " FE, stop emptying")
		switch.setTransferRateLimit(no_emptying_rate)
		state = states.WAITING
	end

	os.sleep(1)
end