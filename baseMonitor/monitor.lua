-- Main display monitor

function debug(msg)
	print("[DEBUG] "..msg)
end

-- Init monitor and network...
mon = peripheral.wrap("right")
rednet.open("top")

function ping(id, timeout)
	timeout = timeout or 2
	id = tonumber(id)
	timeout = tonumber(timeout)
	waiting = true
	rednet.send(id, "ping")
	while waiting do
		from, msg = rednet.receive(timeout)
		if from == id or from == nil or from == "" then
			return msg
		end
	end
end

function addSensor(name, id, type, color)
	debug("Adding sensor "..name.." with id "..id..", type "..type.." and color "..color)
	if ping(id) == "" then
		online = false
	else
		online = true
	end
	return {name = name, id = id, type = type, online = online, color = color}
end

function displayTank(name, percent, endX, color)
	oldX, oldY = mon.getCursorPos()
	beginX = endX-#name+1
	ty = 3
	mon.setCursorPos(beginX, ty)
	mon.write(name)
	j = 0

	mon.setCursorPos(beginX, 5)
	mon.write("#")
	while j < #name-2 do
		mon.write("-")
		j = j+1
	end
	mon.write("#")

	ty = 6
	i = 9

	while i >= 0 do
		mon.setCursorPos(beginX, ty)
		mon.write("|")
		if percent >= (i+1)*10 then
			j = 0
			mon.setBackgroundColor(color)
			while j < #name-1 do
				mon.write(" ")
				j = j+1
			end

			mon.setBackgroundColor(colors.black)
		end
		mon.setCursorPos(endX, ty)
		mon.write("|")
		ty = ty+1
		i = i-1
	end
	mon.setCursorPos(beginX, ty)
	mon.write("#")
	j = 0
	while j < #name-2 do
		mon.write("-")
		j = j+1
	end
	mon.write("#")
	ty = ty + 2
	percentDisp = percent.."%"
	if percent < 5 then
		mon.setTextColor(colors.red)
	elseif percent < 25 then
		mon.setTextColor(colors.orange)
	elseif percent > 80 then
		mon.setTextColor(colors.lime)
	end
	space = #name+1
	tx = math.floor(space-#percentDisp)/2 + beginX
	mon.setCursorPos(tx, ty)
	mon.write(percentDisp)
	mon.setCursorPos(oldX, oldY)
	mon.setTextColor(colors.white)
	return beginX-2
end
debug("Preparing to add sensors.")
sensors = {
addSensor("MFSU Sortie", 14, "MFSU", colors.orange),
addSensor("AE Controler", 17, "AEMON", colors.blue),
addSensor("Steam Turbine", 22, "TURBINE", colors.gray),
addSensor("Lave", 16, "TANK",colors.orange),
addSensor("Force", 13, "TANK", colors.yellow),
addSensor("Steam", 20, "TANK", colors.lightGray),
addSensor("Steam", 25, "TANK", colors.lightGray)}

debug("All sensors added to the system.")

-- Préparation de l'écran

monX, monY = mon.getSize()
debug("Mon size : {x="..monX..",y="..monY.."}")

while true do
	currentLastTank = monX-1
	x = 1
	y = 3
	

	returns = {}
	for i=1,#sensors do
		sens = sensors[i]
		debug("Pinging sensor "..i.." ("..sens.name..").")
		state = ping(sens.id,0.5)
		tab = {name=sens.name, type=sens.type, color=sens.color, state=state}
		returns[i] = tab
	end
	debug("Pinging weather station...")
	weather = ping(27)
	mon.clear()

	-- Show top bar
	debug("Displaying data")
	mon.setCursorPos(1,1)
	mon.setBackgroundColor(colors.cyan)
	mon.setTextColor(colors.white)
	mon.clearLine()
	str = "Infos base - Heure : "..textutils.formatTime(os.time(), true).." (Jour "..os.day()..")"
	if weather == false then
		str = str.." - Il pleut."
	end
	pos = math.floor((monX-#str)/2)
	mon.setCursorPos(pos,1)
	mon.write(str)
	mon.setBackgroundColor(colors.black)


	
	for i=1,#returns do
		sens = returns[i]
		state = sens.state
		if state == "" or state == nil then
			mon.setCursorPos(x,y)
			mon.setBackgroundColor(colors.green)
			mon.write(sens.name)
			mon.setBackgroundColor(colors.black)
			y = y+1
			mon.setCursorPos(3,y)
			mon.setBackgroundColor(colors.red)
			mon.write("Ping timed out :'(")
			y = y+2
		else
			if sens.type ~= "TANK" then
				mon.setCursorPos(x,y)
				mon.setBackgroundColor(sens.color)
				mon.write(sens.name)
				mon.setBackgroundColor(colors.black)
				y = y+1
			end
			if sens.type == "AEMON" then
		
				mon.setCursorPos(3,y)
				state = textutils.unserialize(state)
				if tonumber(state.total) == 0 then
					mon.setTextColor(colors.orange)
					mon.write("Aucun disque dur.")
				else
					per = math.floor((tonumber(state.free) / tonumber(state.total))*100)
					mon.write("Disque libre : "..per.."%")
				end
				mon.setTextColor(colors.white)
				y = y+1
				mon.setCursorPos(3,y)
				mon.write("It. stockés : "..state.storedItems)
				y = y+1
				mon.setCursorPos(3,y)
				mon.write("Esp libre : "..state.itemsSpace)
				x = 1
				y = y+2
			elseif sens.type == "MFSU" then
				mon.setCursorPos(3,y)
				mon.write("EUs stockés : "..state)
				y = y+2
			elseif sens.type == "TURBINE" then
				mon.setCursorPos(3,y)
				mon.write("Vapeur : "..state.."%")
				y=y+1
				mon.setCursorPos(3,y)
				if state < 5 then
					mon.setTextColor(colors.red)
					mon.write("Aucune énergie produite")
				else
					mon.setTextColor(colors.lime)
					mon.write("Production OK")
				end
				mon.setTextColor(colors.white)
				y = y+2
			elseif sens.type == "TANK" then
				currentLastTank = displayTank(sens.name, state, currentLastTank, sens.color)
			end
		end
		mon.setBackgroundColor(colors.black)
		
	end
	sleep(1)
end
