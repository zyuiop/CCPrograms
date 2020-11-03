-- This sensor function estimates the level of a tank
-- The tank must be configured with 4 buildcraft pipes + 4 chips, connecting to the following:
-- Tank is empty ==> top of the computer
-- Tank is < 25% ==> left of the computer
-- Tank is < 50% ==> back of the computer
-- Tank is < 75% ==> right of the computer

function read_sensor()
    empty = redstone.getInput("top")
    less25 = redstone.getInput("left")
    less50 = redstone.getInput("back")
    less75 = redstone.getInput("right")

    amt = 0

    if empty then
        amt = 0
    elseif less25 then
        amt = 20
    elseif less50 then
        amt = 45
    elseif less75 then
        amt = 70
    else
        amt = 100
    end

    return amt
end