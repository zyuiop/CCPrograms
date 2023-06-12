-- pastebin get 4n0u6M3F startup

rs_controller_side = "bottom"

containers = {
	-- Items on the sides of the computer
	["peripheral"] = {
		["back"] = {
			"bigreactors:yellorite_ore",
			"minecraft:raw_iron",
			"mekanism:raw_osmium",
			"minecraft:raw_gold",
			"mekanism:raw_tin",
			"create:raw_zinc",
			"minecraft:raw_copper",
			"immersiveengineering:raw_nickel",
			"occultism:raw_silver"
		}
	},
	-- Items on the side of the RS controller
	["side"] = {}
}

--


rs = peripheral.wrap(rs_controller_side)
-- smelter = peripheral.wrap(smelter_side)

function process_kind(kind, sides)
	for side, content in pairs(sides) do
		process_side(kind, side, content)
	end
end

function try_send_item(kind, side, item_data)
	if item_data == nil or item_data.amount == 0 then return end

	name = item_data["name"]
	display = item_data["displayName"]
	amount = item_data["amount"]

	-- Is there space remaining?
	print("Exporting " .. amount .. " of " .. name .. " / " .. display .. " to " .. side .. " " .. kind)

	if kind == "side" then
		rs.exportItem({name=name, amount=amount}, side)
	elseif kind == "peripheral" then
		rs.exportItemToPeripheral({name=name, amount=amount}, side)
	end
end

function process_side(kind, side, tbl)
	for _,item in pairs(tbl) do
		data = rs.getItem({name=item})
		try_send_item(kind, side, data)
	end
end

while true do
	for kind, content in pairs(containers) do
		process_kind(kind, content)
	end

	os.sleep(10)
end

