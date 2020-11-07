require("sensors")

-- Updated from baseMonitor/monitor.lua
-- Main display monitor

function debug(msg)
        print("[DEBUG] "..msg)
end

settings.load("display.conf")

-- Init monitor and network...
mon = peripheral.wrap(settings.get("monitor_position", "top"))
mon.clear()
mon.setCursorPos(1,1)
mon.write("Loading...")
rednet.open(settings.get("modem_position", "front"))

function probe(sensor)
        value, online = sensor.value_getter(sensor.proto)

        if value == nil or not online then
                sensor.online = false
                sensor.state = ""
        else
                sensor.online = true
                sensor.state = math.floor(value)
        end
end

function addSensor(name, proto, type, color, value_getter)
        debug("Adding sensor "..name.." with proto "..proto..", type "..type.." and color "..color)
        return {name = name, proto = proto, type = type, online = false, color = color, value_getter = value_getter, state = ""}
end

function displayTank(name, percent, endX, endY, color)
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

        maxY = (endY - ty - 3)
 i = maxY
 trait = 100 / i

        while i >= 0 do
                mon.setCursorPos(beginX, ty)
                mon.write("|")
                if percent >= (i+1)*trait then
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
        return beginX-3
end

debug("Preparing to add sensors.")

sensors = {
addSensor("Lave", "tanks", "TANK", colors.orange, read_sensors),
addSensor("Oil" , "oil"  , "TANK", colors.purple, read_sensors),
addSensor("Steam" , "steam"  , "TANK", colors.lightGray, read_sensors)
}

debug("All sensors added to the system.")

-- Préparation de l'écran

monX, monY = mon.getSize()
scale = mon.getTextScale()
debug("Mon size : {x="..monX..",y="..monY..",scale=" .. scale .. "}")

while true do
        currentLastTank = monX-1
        x = 1
        y = 3


        for i=1,#sensors do
                sens = sensors[i]
                debug("Pinging sensor "..i.." ("..sens.name..").")
                probe(sens)
        end

 mon.setBackgroundColor(colors.black)
 mon.clear()

        -- Show top bar
        debug("Displaying data")
        mon.setCursorPos(1,1)
        mon.setBackgroundColor(colors.cyan)
        mon.setTextColor(colors.white)
        mon.clearLine()
        str = "Infos - Time : "..textutils.formatTime(os.time(), true).." (Day "..os.day()..")"

        pos = math.floor((monX-#str)/2)
        mon.setCursorPos(pos,1)
        mon.write(str)
        mon.setBackgroundColor(colors.black)



        for i=1,#sensors do
                sens = sensors[i]
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
                                currentLastTank = displayTank(sens.name, state, currentLastTank, monY, sens.color)
                        end
                end
                mon.setBackgroundColor(colors.black)

        end
        sleep(1)
end