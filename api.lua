-- the meats of the mod

local registered_crafts = fast_craft.registered_crafts


function fast_craft.register_on_craft(func)
	table.insert(fast_craft.registered_on_crafts, func)
end
fast_craft.register_on_craft(function(player, itemstack, recipe)
	minetest.log("action", "player " .. player:get_player_name() .. " crafts " .. itemstack:to_string())
end)


-- RECIPE REGISTRATION

-- TODO: make a simmilar function which serializes complete recipe
-- helps to filter out duplicate recipes
local function recipe_to_string(recipe)
	local rs = {}
	rs[#rs + 1] = "o:" .. recipe.output[1] .. " " .. recipe.output[2]
	-- TODO: this needs to order the lists alphabetically first to avoid duplicates with switched order
	if #recipe.additional_output > 0 then
		rs[#rs + 1] = " ao:"
		for item, count in pairs(recipe.additional_output) do
			rs[#rs + 1] = item .. " " .. count .. ","
		end
	end
	rs[#rs + 1] = " i:"
	for item, count in pairs(recipe.input) do
		rs[#rs + 1] = item .. " " .. count .. ","
	end

	return table.concat(rs)
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

function fast_craft.simplify_recipe(recipe)
	-- try to simplify recipe if all item amounts are divisible by the same number
	local numbers = {tonumber(recipe.output[2]) or 1}
	for _, amount in pairs(recipe.additional_output) do
		numbers[#numbers + 1] = amount
	end
	for _, amount in pairs(recipe.input) do
		numbers[#numbers + 1] = amount
	end

	local gcd = get_gcd(numbers)
	if gcd > 1 then
		recipe.output[2] = recipe.output[2] / gcd
		for item, amount in pairs(recipe.additional_output) do
			recipe.additional_output[item] = amount / gcd
		end
		for item, amount in pairs(recipe.input) do
			recipe.input[item] = amount / gcd
		end
	end

	return recipe
end

local recipes_by_rs = {}
function fast_craft.register_craft(recipe)
	-- TODO: some validation that all the involved items exist, if not -> warning

	-- first, flest out the recipe definition, so we can count on all the field existing
	if not recipe.output[2] then recipe.output[2] = 1 end
	if not recipe.additional_output then recipe.additional_output = {} end
	if not recipe.tags then recipe.tags = {} end
	if not recipe.conditions then recipe.conditions = {["none"] = true} end

	local rs = recipe_to_string(recipe)
	if not recipes_by_rs[rs] then
		assert(recipe.conditions, dump(recipe))
		recipe.output.def = minetest.registered_items[recipe.output[1]]
		registered_crafts[#registered_crafts + 1] = recipe
		recipes_by_rs[rs] = recipe
	else
		-- if recipe is already registred, we just merge in tags and conditions
		assert(recipe.conditions, dump(recipe))
		local r_def = recipes_by_rs[rs]
		for tag, value in pairs(recipe.tags) do
			r_def.tags[tag] = value
		end
		for condition, _ in pairs(recipe.conditions) do
			r_def.conditions[condition] = true
		end
	end
end

function fast_craft.register_condition(name, def)
	if fast_craft.registered_conditions[name] then
		minetest.log("warning", "[fast_craft] Crafting condition: '" .. name .. "' is being overrident")
	end
	def.name = name
	fast_craft.registered_conditions[name] = def
end


-- FUNCTIONAL PART

-- simplify the inventory to a '[item_name] = amount' table
function fast_craft.inv_to_table(inv, list)
	local t = {}
	for _, stack in pairs(inv:get_list(list or "main")) do
		if not stack:is_empty() then
			local name, count = stack:get_name(), stack:get_count()
			if not t[name] then t[name] = 0 end
			t[name] = t[name] + count
		end
	end
	return t
end

-- checks wheter a recipes condition are met
-- returns true if ANY condition is met
function fast_craft.is_recipe_condition_fulfiled(recipe, player)
	for condition, _ in pairs(recipe.conditions) do
		if fast_craft.registered_conditions[condition].func(player) then
			return true
		end
	end
	return false
end

-- returns number of times recipe can be crafted from inventory
function fast_craft.get_craft_amount(recipe, inv)
	local n = 999
	for item, count in pairs(recipe.input) do
		-- some items could be counted twice here, see warning
		if item:find("group") then
			local groups = item:sub(7, -1):split()

			local total = 0
			for inv_item, inv_count in pairs(inv) do
				local suitable = true
				for _, group in pairs(groups) do
					if minetest.get_item_group(inv_item, group) == 0 then
						suitable = false
					end
				end
				if suitable then
					total = total + inv_count
				end
			end
			n = math.min(n, math.floor(total / count))
		else
			n = math.min(n, math.floor((inv[item] or 0) / count))
		end
	end

	return n
end

-- returns array of recipe indexes, the player can craft
-- checks for custom condition
function fast_craft.get_craftable_recipes(player)
	local r = {}
	local inv = fast_craft.inv_to_table(player:get_inventory())

	for i, recipe in ipairs(registered_crafts) do
		if fast_craft.get_craft_amount(recipe, inv) > 0 and fast_craft.is_recipe_condition_fulfiled(recipe, player) then
			r[#r + 1] = i
		end
	end

	return r
end

-- try to craft the recipe up to 'amount' times
-- actual item count depends on recipe output count
function fast_craft.craft(player, recipe_index, amount)
	local recipe = registered_crafts[recipe_index]
	local inv = player:get_inventory()
	local inv_list = fast_craft.inv_to_table(inv)

	amount = math.min(amount, fast_craft.get_craft_amount(recipe, inv_list))
	if amount == 0 then return end
	if not fast_craft.is_recipe_condition_fulfiled(recipe, player) then return end

	-- taking input
	for in_item, count in pairs(recipe.input) do
		local total = count * amount
		-- some items could be counted twice here, see warning
		if in_item:find("group") then
			local groups = in_item:sub(7, -1):split()

			for inv_item, inv_count in pairs(inv_list) do
				local suitable = true
				for _, group in pairs(groups) do
					if minetest.get_item_group(inv_item, group) == 0 then
						suitable = false
					end
				end
				if suitable then
					local taken = inv:remove_item("main", inv_item .. " " .. total)
					total = total - taken:get_count()
					if total == 0 then break end
				end
			end
		else
			inv:remove_item("main", in_item .. " " .. total)
		end
	end

	local total = recipe.output[2] * amount

	local craft_result = ItemStack(recipe.output[1] .. " " .. total)
	for _, on_craft in ipairs(fast_craft.registered_on_crafts) do
		on_craft(player, craft_result, table.copy(recipe))
	end

	-- giving ouput
	local pos = player:get_pos()
	local stack_max = recipe.output.def.stack_max
	-- is split up to avoid overly large itemstacks
	for i = 1, math.floor(total / stack_max) do
		local leftover = inv:add_item("main", recipe.output[1] .. " " .. stack_max)
		minetest.add_item(pos, leftover)
	end
	local leftover = inv:add_item("main", recipe.output[1] .. " " .. total % stack_max)
	minetest.add_item(pos, leftover)

	-- additional outputs
	for item, count in pairs(recipe.additional_output) do
		-- print(item)
		local total = count * amount
		local stack_max = minetest.registered_items[item].stack_max
		for i = 1, math.floor(total / stack_max) do
			local leftover = inv:add_item("main", item .. " " .. stack_max)
			minetest.add_item(pos, leftover)
		end
		local leftover = inv:add_item("main", item .. " " .. total % stack_max)
		minetest.add_item(pos, leftover)
	end
end
