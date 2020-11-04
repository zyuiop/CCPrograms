-- This router automatically relays messages

modem_position = settings.get("modem_position", "front")

modem = peripheral.wrap(modem_position)

BROADCAST_CHAN = 65535

modem.open(BROADCAST_CHAN) 
modem.open(os.computerID())

actions = {
	["hello"] = function()
	
	end,

}


connected_clients = {}
routing_table = {}

-- structure: {id={hops=.., via=..}}

function receive_routing_table(router_id, other_table)
	for id, entry in pairs(other_table) do
		if entry.via ~= os.computerID() then
			if not routing_table[id] or routing_table[id].hops + 1 > entry.hops then
				routing_table[id] = {via=router_id, hops=entry.hops + 1}
			end
		end
	end
end


while true do
	kind, _, chan, rep_to, dist, msg = os.pullEvent()

	if kind == "modem_message" then
		if type(msg) == "table" and msg.arpType then

		end
	end
end


		if chan == BROADCAST_CHAN and type(msg) == "string" and msg == "ARP" then
			if not modem.isOpen(rep_to) then
				modem.open(rep_to) -- starts listening to packets sent by that client
			end
		else
			-- message sent on a channel we listen to
			-- we need to relay the message
			if not modem.isOpen(rep_to) then
				modem.open(rep_to)
			end
		end
	end
end

-- Address Relay Protocol (yay!)
-- Packets are encapsulated if they cannot be sent easily

-- Process:
-- At boot computers broadcast ARP HELLO <id>
-- When sending, clients issues a ARP FIND <id> broadcast with the id of the computer
-- Devices can reply:
--  DIRECT <id>, if they are that computer
--  VIA <id> <hops> if they are not that computer
-- actually tables, but you get the idea
-- the computer lib caches the response