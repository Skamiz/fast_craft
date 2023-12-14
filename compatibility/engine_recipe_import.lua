-- imports crafting recipes registered by the hardcoded crafting system

-- Settings
local import_recipes = minetest.settings:get_bool("import_recipes", true)
local simplify_recipes = minetest.settings:get_bool("simplify_recipes", true)

local function is_3x3(recipe)
	if recipe.width == 0 then return false end
	if recipe.width == 1 then
		return recipe.items[1] and recipe.items[3]
	end
	if recipe.width == 2 then
		return (recipe.items[1] or recipe.items[2]) and (recipe.items[5] or recipe.items[6])
	end
	if recipe.width == 3 then return true end
end


-- baring exceptional circumstances there never will be a larger factor
local factors = {2, 3, 5, 7}
local function get_gcd(numbers)
	local fac = {99, 99, 99, 99}
	for _, number in pairs(numbers) do
		for i, f in pairs(factors) do
			local n = 0
			while number / f == math.floor(number / f) do
				n = n + 1
				number = number / f
			end
			fac[i] = math.min(fac[i], n)
		end
	end
	local gcd = 1
	for i, f in pairs(fac) do
		gcd = gcd * (factors[i] ^ f)
	end
	return gcd
end

if import_recipes then
	-- import recipes from default minetest crafting system
	minetest.register_on_mods_loaded(function()
		local t1 = minetest.get_us_time()

		for item, def in pairs(minetest.registered_items) do
			local recipes = minetest.get_all_craft_recipes(item) or {}
			for i, recipe in pairs(recipes) do
				if recipe.method == "normal" then

					-- output
					local output = string.split(recipe.output, " ")

					-- additional output
					local out, decrem = minetest.get_craft_result(recipe) -- this is slow
					-- if out.item:is_empty() then print("fast_craft: " .. item ) end
					local a_output = {}
					for _, stack in pairs(decrem.items) do
						if not stack:is_empty() then
							local item = stack:get_name()
							a_output[item] = a_output[item] and a_output[item] + 1 or 1
						end
					end
					-- for _, item in pairs(out.replacements) do
					-- 	a_output[item] = a_output[item] and a_output[item] + 1 or 1
					-- end

					-- input
					local input = {}
					for _, item in pairs(recipe.items) do
						input[item] = input[item] and input[item] + 1 or 1
					end

					local tags = {
						["engine_import"] = true,
					}
					if is_3x3(recipe) then
						tags["3x3"] = true
					end

					local fc_recipe = {
						output = {
							output[1],
							tonumber(output[2]) or 1,
						},
						additional_output = a_output,
						input = input,
						tags = tags,
					}

					if simplify_recipes then
						fc_recipe = fast_craft.simplify_recipe(fc_recipe)
					end

					fast_craft.register_craft(fc_recipe)
				end
			end
		end

		print("[MOD] 'fast_craft' recipes imported in " .. (minetest.get_us_time() - t1)/1000000 .. " s")
	end)
end
