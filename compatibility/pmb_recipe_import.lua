local simplify_recipes = minetest.settings:get_bool("simplify_recipes", true)

minetest.register_on_mods_loaded(function()
	if (not pmb_tcraft) or (not pmb_tcraft.get_all_craft_recipes) then return end

	local all_pmb_recipes = pmb_tcraft.get_all_craft_recipes()

	for _, recipes in pairs(all_pmb_recipes) do
		for _, recipe in pairs(recipes) do
			if recipe.method[1] == "normal" then

				-- output
				local output = string.split(recipe.output, " ")

				-- input
				local input = table.copy(recipe.items)

				local fc_recipe = {
					output = {
						output[1],
						tonumber(output[2]) or 1,
					},
					additional_output = {},
					input = input,
				}

				if simplify_recipes then
					fc_recipe = fast_craft.simplify_recipe(fc_recipe)
				end

				fast_craft.register_craft(fc_recipe)
			else
				minetest.log("warning", "[fast_craft]: non normal pmb recipe detected")
			end
		end
	end
end)
