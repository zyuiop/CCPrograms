-- Lava tank program

m = 15 -- Monitor computer id
rednet.open("top")
p = peripheral.wrap("bottom")

while true do
  from, msg = rednet.receive()
  if from == m then
    if msg == "ping" then
    	tank = p.getTanks("left")
    	if tank[1].amount == nil or tank[1].capacity == nil or tank[1].capacity == 0 then
    		prc=0
    	else
    		prc = math.floor((tank[1].amount / tank[1].capacity)*100)
      	end
      	rednet.send(m, prc)
    end
  end
end  
