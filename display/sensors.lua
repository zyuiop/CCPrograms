-- Sensor client

function read_sensors(protocol)
  lst = {rednet.lookup(protocol, nil)}

  if lst == nil then
    print("No connected computer")
    return nil
  end

  if type(lst) == "number" then
    lst = { lst }
  end

  num = 0
  sum = 0

  for i, v in ipairs(lst) do
    rednet.send(v, "level", protocol)

    id, rep = rednet.receive(protocol, 10)

    if id ~= nil then
      sum = sum + rep
      num = num + 1
      print("Node " .. v .. " reported level " .. rep .. " %")
    else
      print("Timeout from node " .. v)
    end
  end

  avg = sum / num

  return avg, num > 0
end