
local function stonecutter_nearby(player)
	local p_pos = player:get_pos():round()
    p_pos.y = p_pos.y + 1

	return minetest.find_node_near(p_pos, 3, {"mcl_stonecutter:stonecutter"}, true)
end

minetest.register_on_mods_loaded(function()
	if (not mcl_stonecutter) or (not mcl_stonecutter.registered_recipes) then return end

	local all_stonecutter_recipes = mcl_stonecutter.registered_recipes

	-- print("Stone cutter recipes:")
	-- print_table(all_stonecutter_recipes)

	for input, outputs in pairs(all_stonecutter_recipes) do
		for output, count in pairs(outputs) do

			local fc_recipe = {
				output = {
					output,
					count,
				},
				input = {[input] = 1},
				condition = stonecutter_nearby,
			}

			fast_craft.register_craft(fc_recipe)
		end
	end
end)
