--[[
Fast Craft by Skamiz Kazzarch

See: https://forum.minetest.net/viewtopic.php?f=9&t=28125 for a more generic version of this mod

WARNING: Is liable to be buggy in case of recipes, which ask for a group ingredient,
 but also a specific item belonging to the group, since I didn't figure out a way
 to correctly count the items in such a case.


WARNING: Fails if recipe defines replacements for specific items which are only
requested by group
	example: recipe asks for group water bucket, and specifies two replacements
	one in case of normal water and one in case of river water,
	both of which replace with empty bucket
	this mod will give two empty buckets when the recipe is crafted



- only once there is an active need
TODO: if an item is required, but imediately returned count it as if infinite
		alternative: remove item from recipe and ad a condition checking whetehr it's in the inventory
TODO: fake scrollbar which can be styled
try: can I just place images over the scrollbar and still have it work?
TODO: button clikcing sounds
TODO: callbacks for crafting stuff
TODO: pressetes for group icons
	or, randomly choose an image from the group each time it's needed
	or or, Is it possible to dynamically make an animated texture switching through the images?
		no, probably not, since I con't directly get the node images
TODO: multigroup icons + support for predefined group icons to use an image in stead of an item
TODO: make fc_slots.png whiten, then colorize it from code as neccessary

TODO: recipe guide page
TODO: recipes can be hidden form guide; hidden = true
TODO: crafting conditions can have descriptions which are displayed in recipe section

TODO: consider turning bulk crafting into repeated single crafting

A way to find changes in the inventory:
	serialize it, cache it, compare with previous state



---------------------------------------------



Wish for minetest: a callback for when inventory is opened/contents are changed
--]]

-- SETUP STUFF

local t0 = minetest.get_us_time()

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

fast_craft = {}
fast_craft.registered_crafts = {}
fast_craft.registered_on_crafts = {}
fast_craft.translator = minetest.get_translator("fast_craft")

dofile(modpath .. "/api.lua")
dofile(modpath .. "/compatibility/engine_recipe_import.lua")

dofile(modpath .. "/gui.lua")
dofile(modpath .. "/compatibility/integration.lua")

if not fast_craft.craft_sizes then
	fast_craft.craft_sizes = {1, 5, 25, 100}
end
if not fast_craft.grid_color then
	fast_craft.grid_color = "#959595"
end
if not fast_craft.highlight_color then
	fast_craft.highlight_color = "#84a19e"
end

-- just a usefull debug function
local function print_table(po)
	for k, v in pairs(po) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end


local function get_alias(item)
	local alias = item
	while minetest.registered_aliases[alias] do
		alias = minetest.registered_aliases[alias]
	end
	if alias ~= item then
		return alias
	end
end


-- finnishing up
minetest.register_on_mods_loaded(function()
	-- resolve aliases
	for _, recipe in pairs(fast_craft.registered_crafts) do
		recipe.output[1] = get_alias(recipe.output[1]) or recipe.output[1]
		for item, amount in pairs(recipe.additional_output) do
			local ali = get_alias(item)
			if ali then
				recipe.additional_output[ali] = recipe.additional_output[item]
				recipe.additional_output[item] = nil
			end
		end
		for item, amount in pairs(recipe.input) do
			local ali = get_alias(item)
			if ali then
				recipe.input[ali] = recipe.input[item]
				recipe.input[item] = nil
			end
		end
	end

	-- TODO:
	-- Warning for recipes that use, or produce nonexiting items
	-- maybe simplify ALL recipes? instead of just imported ones
	table.sort(fast_craft.registered_crafts, function(a, b) return a.output[1] < b.output[1] end)
end)


print("[MOD] 'fast_craft' loaded in " .. (minetest.get_us_time() - t0)/1000000 .. " s")
