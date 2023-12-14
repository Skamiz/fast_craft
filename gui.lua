-- everyting related to formspecs
-- allowing the player to interact with the mod



local S = fast_craft.translator
local pixel = 1/64 -- in terms of inventory slots this coresponds to one pixel
local p16 = 1/16

-- keeps track of players selected recipe
local players = {}
local registered_crafts = fast_craft.registered_crafts



fast_craft.group_icons = {
	planks = "cicrev:planks_oak",
	log = "cicrev:log_oak",
}

minetest.register_on_mods_loaded(function()
	for item, def in pairs(minetest.registered_items) do
		for group, level in pairs(def.groups or {}) do
			if not fast_craft.group_icons[group] then fast_craft.group_icons[group] = item end
		end
	end
end)

-- FORMSPEC STUFF
--------------------------------------------------------------------------------
-- recipe selection gui
function fast_craft.get_recipe_list_fs(player, width, scroll_index)
	local recipes = fast_craft.get_craftable_recipes(player)

	local f = {
		"box[0,0;" .. width .. ",4.75;#FFF0]",
		"box[" .. width + 0.25 .. ",0;0.5,4.75;#0000]",
		"image[0,0;" .. width .. ",4.75;[combine:" .. width * 16 .. "x" .. 4.75 * 16 .. ":0,0=fc_grid.png^[multiply:" .. fast_craft.grid_color .. ";]",
	}

	if #recipes > width * 4 then
		f[#f + 1] = "scrollbaroptions[max=" .. (math.floor((#recipes-1)/width) * 10) - 30 .. "]"
		f[#f + 1] = "scrollbar[" .. width + 0.25 .. ",0;0.5,4.75;vertical;scrlb;" .. (scroll_index or 0) .. "]"
		f[#f + 1] = "scroll_container[0,0;" .. width .. ",4.75;scrlb;vertical;0.1]"
	end
	for i, craft_index in ipairs(recipes) do
		local x_pos = (i - 1) % width
		local y_pos = math.floor((i - 1) / width)
		local recipe = registered_crafts[craft_index]
		local item = recipe.output[1]
		local count = recipe.output[2] == 1 and "" or recipe.output[2]

		f[#f + 1] = "item_image_button[" .. x_pos .. "," .. y_pos .. ";1,1;" .. item .. ";recipe_" .. craft_index .. ";" .. count .. "]"
	end

	if #recipes > width * 4 then
		f[#f + 1] = "scroll_container_end[]"
	end

	return table.concat(f)
end

-- formspec string for item image and asociated item count
local function item_image_fs(x_pos, y_pos, item, count)
	local f = {}
	if item:find("group") then
		local groups = item:sub(7, -1):split()
		f[#f + 1] = "item_image[" .. x_pos .. "," .. y_pos .. ";1,1;" .. fast_craft.group_icons[groups[1]] .. "]"
		f[#f + 1] = "label[" .. x_pos + 0.390625 .. "," .. y_pos + 0.5 .. ";G]"
		f[#f + 1] = "tooltip[" .. x_pos .. "," .. y_pos .. ";1,1;" .. item .. "]"
	else
		f[#f + 1] = "item_image[" .. x_pos .. "," .. y_pos .. ";1,1;" .. item .. "]"
		f[#f + 1] = "tooltip[" .. x_pos .. "," .. y_pos .. ";1,1;" .. minetest.registered_items[item].description .. "]"
	end
	if count and count > 9 then
		f[#f + 1] = "label[" .. x_pos + 46 * pixel .. "," .. y_pos + 54 * pixel .. ";" .. count .. "]"
	elseif count and count > 1 then
		f[#f + 1] = "label[" .. x_pos + 55 * pixel .. "," .. y_pos + 54 * pixel .. ";" .. count .. "]"
	end
	return table.concat(f)
end

-- visual display of recipe
function fast_craft.get_recipe_fs(width, recipe_index)
	local fs = {
		"box[0,0;" .. width .. ",1;#FFF0]",
		"box[0,1.5;" .. width .. ",3;#FFF0]",
		"image[0,0;" .. width .. ",1;[combine:" .. width * 16 .. "x" .. 1 * 16 .. ":0,0=fc_grid.png^[multiply:" .. fast_craft.grid_color .. ";]",
		"image[0,0;1,1;[combine:" .. 1 * 16 .. "x" .. 1 * 16 .. ":0,0=fc_grid.png^[multiply:" .. fast_craft.highlight_color .. ";]",
		"image[0,1.5;" .. width .. ",3;[combine:" .. width * 16 .. "x" .. 3 * 16 .. ":0,0=fc_grid.png^[multiply:" .. fast_craft.grid_color .. ";]",
	}

	if recipe_index then
		local recipe = registered_crafts[recipe_index]
		fs[#fs + 1] = item_image_fs(0, 0, recipe.output[1], recipe.output[2])
		local n = 0
		for item, count in pairs(recipe.additional_output) do
			n = n + 1
			fs[#fs + 1] = item_image_fs(n, 0, item, count)
		end
		n = 0
		for item, count in pairs(recipe.input) do
			local x_pos = (n % width)
			local y_pos = math.floor(n / width) + 1.5
			fs[#fs + 1] = item_image_fs(x_pos, y_pos, item, count)
			n = n + 1
		end
	end

	return table.concat(fs)
end

-- buttons which initiate crafting action
function fast_craft.get_craft_buttons_fs(player, recipe_index)
	local fs = {}
	local recipe = registered_crafts[recipe_index]
	if recipe then
		for i = 1, 4 do
			fs[#fs + 1] = "box[0," .. (i-1) * 0.75 .. ";0.5,0.5;#0000]"
			fs[#fs + 1] = "button[0," .. (i-1) * 0.75 .. ";0.5,0.5;craft_" .. fast_craft.craft_sizes[i] .. "_" .. recipe_index .. ";" .. fast_craft.craft_sizes[i] .. "]"
			fs[#fs + 1] = "tooltip[craft_" .. fast_craft.craft_sizes[i] .. "_" .. recipe_index .. ";" .. S("Craft @1", fast_craft.craft_sizes[i]) .. "]"
		end
		local max = fast_craft.get_craft_amount(recipe, fast_craft.inv_to_table(player:get_inventory()))
		fs[#fs + 1] = "box[0,3;0.5,0.5;#0000]"
		fs[#fs + 1] = "button[0,3;0.5,0.5;craft_" .. max .. "_" .. recipe_index .. "max;" .. max .. "]"
		fs[#fs + 1] = "tooltip[craft_" .. max .. "_" .. recipe_index .. "max;" .. S("Craft Maximum") .. "]"
	else
		for i = 1, 5 do
			fs[#fs + 1] = "box[0," .. (i-1) * 0.75 .. ";0.5,0.5;#0000]"
			fs[#fs + 1] = "button[0," .. (i-1) * 0.75 .. ";0.5,0.5;dummy_button;x]"
		end
	end
	return table.concat(fs)
end

-- all crafting formspec stuff together
function fast_craft.get_fast_craft_formspec(player, width, scroll_index, recipe_index)
	recipe_index = recipe_index or players[player]
	local n = width - 1.75
	local recipe_width = math.min(4, math.max(1, math.floor(n/2)))
	local list_width = math.max(1, math.floor(n - recipe_width))
	local button_x = math.max(width - 0.5, recipe_width + list_width + 1.25)
	local fs = {
		"box[" .. button_x .. ",4;0.5,0.5;#0000]",
		"image_button[" .. button_x .. ",4;0.5,0.5;fc_reload.png;reload;]",
		"tooltip[reload;" .. S("Refresh Formspec") .. "]",
		fast_craft.get_recipe_list_fs(player, list_width, scroll_index),

		"container[" .. list_width + 1 .. ",0]",
		fast_craft.get_recipe_fs(recipe_width, recipe_index),
		"container_end[]",

		"container[" .. button_x .. ",0]",
		fast_craft.get_craft_buttons_fs(player, recipe_index),
		"container_end[]",
	}
	return table.concat(fs)
end

-- whole, displayable formspec including player inventory and cfs styling
function fast_craft.get_craft_invenory_formspec(player, scroll_index, recipe_index)
	local fs = {
		"formspec_version[6]",
		"size[13.25,12]",

		"container[0.5,0.5]",

		fast_craft.get_fast_craft_formspec(player, 12.25, scroll_index, recipe_index),

		"box[" .. -2*p16 .. "," .. 6.25 - 2*p16 .. ";" .. 12.25 + 4*p16 .. "," .. 4.75 + 4*p16 .. ";#FFF0]",
		"list[current_player;main;0,6.25;10,4;]",

		"container_end[]",
	}
	fs = table.concat(fs)
	if minetest.global_exists("cfs") then
		fs = cfs.style_formspec(fs, player)
	end
	return fs
end


-- callback should show updated formspec
function fast_craft.regsiter_formspec_callback(form_name, callback)
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname ~= form_name then return end
		-- print_table(fields)

		local _, _, scroll_index = (fields.scrlb or ""):find("VAL:(%d*)")

		-- sometimes the formspec needs to be updated manualy
		-- an explicit button helps convey that to the player
		if fields.reload then
			players[player] = nil
			callback(player, scroll_index, nil)
			return true
		end

		for k, v in pairs(fields) do
			-- recipe selected
			local _, _, craft_index = k:find("recipe_(%d*)")
			if craft_index then
				players[player] = tonumber(craft_index)
				craft_index = tonumber(craft_index)

				callback(player, scroll_index, craft_index)
				return true
			end

			-- crafting button pressed
			local _, _, craft_amount, craft_index = k:find("craft_(%d*)_(%d*)")
			if craft_amount then
				craft_amount = tonumber(craft_amount)
				craft_index = tonumber(craft_index)
				fast_craft.craft(player, craft_index, craft_amount)

				callback(player, scroll_index, craft_index)
				return true
			end
		end

		-- if fields.scrlb then return true end
	end)
end
