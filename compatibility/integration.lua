-- play nice with other mods
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = fast_craft.translator
local p16 = 1/16
local gameid = Settings(minetest.get_worldpath()..DIR_DELIM..'world.mt'):get('gameid')

print("[fast_craft] gameid: " .. gameid)


-- Default integration, always accessible

-- show crafting formspec independently of players 'inventory_formspec'
function fast_craft.show_crafting_inventory(player, scroll_index, craft_index)
	local fs = fast_craft.get_craft_invenory_formspec(player, scroll_index, craft_index)
	minetest.show_formspec(player:get_player_name(), "fast_craft:crafting", fs)
end
fast_craft.regsiter_formspec_callback("fast_craft:crafting", fast_craft.show_crafting_inventory)

minetest.register_chatcommand("fast_craft", {
	params = "",
	description = "Show independent fast_craft crafting formspec.",
	privs = {},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		fast_craft.show_crafting_inventory(player, nil, nil)
	end,
})


-- Game specific integration
if gameid == "cicrev" then
	fast_craft.craft_sizes = {1, 5, 25, 100}
	fast_craft.grid_color = "#959595"
	fast_craft.highlight_color = "#84a19e"

	local function get_cicrev_sfinv_page(player, scroll_index, craft_index)
		local fs = {
			"formspec_version[6]",
			"size[13.25,12]",
			"container[0.5,0.5]",

			fast_craft.get_fast_craft_formspec(player, 12.25, scroll_index, craft_index),
			"box[" .. -2*p16 .. "," .. 6.25 - 2*p16 .. ";" .. 12.25 + 4*p16 .. "," .. 4.75 + 4*p16 .. ";#FFF0]",
			"list[current_player;main;0,6.25;10,4;]",

			"container_end[]",
		}

		local context = sfinv.get_or_create_context(player)
		context.page = "fast_craft:crafting"
		context.nav_idx = table.indexof(context.nav, context.page)

		fs = table.concat(fs) .. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
		if minetest.global_exists("cfs") then
			fs = cfs.style_formspec(fs, player)
		end
		return fs
	end

	sfinv.register_page("fast_craft:crafting", {
	    title = S("Fast Craft"),
	    get = function(self, player, context)
            return get_cicrev_sfinv_page(player) --.. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
	    end
	})

	fast_craft.regsiter_formspec_callback("", function(player, scroll_index, craft_index)
		player:set_inventory_formspec(
			get_cicrev_sfinv_page(player, scroll_index, craft_index)
		)
	end)
elseif gameid == "mineclone2" or minetest.get_modpath("mcl_formspec") then
	fast_craft.craft_sizes = {1, 4, 16, 64}
	fast_craft.grid_color = "#b9b9b9"
	fast_craft.highlight_color = "#84a19e"

	dofile(modpath .. "/compatibility/mcl_recipe_import.lua")


	local function get_mineclone_itemslots()
		local out = ""
		for x = 0, 8 do
			for y = 0, 3 do
				out = out .."image[" .. x * 1.25 .. "," .. y * 1.25 + 5.25 .. ";1,1;mcl_formspec_itemslot.png]"
			end
		end
		return out
	end

	local function show_mcl_craft_page(player, scroll_index, craft_index)
		local fs = {
			"formspec_version[6]",
			"size[12,11]",
			"container[0.5,0.5]",
			"background[-0.5,-0.5;12,5.5;fc_background_mineclone.png]",
			get_mineclone_itemslots(),
			fast_craft.get_fast_craft_formspec(player, 11, scroll_index, craft_index),
			"box[" .. -2*p16 .. "," .. 6.25 - 2*p16 .. ";" .. 12.25 + 4*p16 .. "," .. 4.75 + 4*p16 .. ";#FFF0]",
			"list[current_player;main;0,5.25;9,3;9]",
			"list[current_player;main;0,9;9,1;]",

			"container_end[]",
		}
		fs = table.concat(fs)
		minetest.show_formspec(player:get_player_name(), "fast_craft:mcl_crafting", fs)
	end
	fast_craft.regsiter_formspec_callback("fast_craft:mcl_crafting", show_mcl_craft_page)

	-- wired hack, because mineclone has no oficial hooks to add formspec elements to the main inventory tab
	local old_get_itemslot_bg = mcl_formspec.get_itemslot_bg_v4
	mcl_formspec.get_itemslot_bg_v4 = function(x, y, w, h)
		local out = old_get_itemslot_bg(x, y, w, h)
		if x == 5.375 and y == 4.125 and w == 1 and h == 1 then
			out = out .. "image_button[10.325,2.825;1.1,1.1;fc_mineclone_fc_button.png;show_mcl_fc;;false;false]"
		end
		return out
	end
	local old_get_itemslot_bg = mcl_formspec.get_itemslot_bg
	mcl_formspec.get_itemslot_bg = function(x, y, w, h)
		local out = old_get_itemslot_bg(x, y, w, h)
		if x == 7 and y == 1.5 and w == 1 and h == 1 then
			out = out .. "image_button[6,3;1,1;fc_mineclone_fc_button.png;show_mcl_fc;;false;false]"
		end
		return out
	end
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname ~= "" then return end
		if fields.show_mcl_fc then
			show_mcl_craft_page(player, nil, nil)
			return true
		end
	end)
elseif gameid == "survivetest" then
	fast_craft.craft_sizes = {1, 5, 25, 99}
	fast_craft.grid_color = "#292929"
	fast_craft.highlight_color = "#54716e"

	local function get_svt_sfinv_page(player, scroll_index, craft_index)
		local fs = {
			"formspec_version[6]",
			"size[10.5,11.34375]",
			-- "size[8,9.1]",
			"background[0.125,0.125;10.25,5.25;fc_background_mtg.png]",
			"container[0.375,0.375]",

			fast_craft.get_fast_craft_formspec(player, 9.75, scroll_index, craft_index),
			"image[0,5.84375;1,1;gui_hb_bg.png]",
			"image[1.25,5.84375;1,1;gui_hb_bg.png]",
			"image[2.5,5.84375;1,1;gui_hb_bg.png]",
			"image[3.75,5.84375;1,1;gui_hb_bg.png]",
			"image[5,5.84375;1,1;gui_hb_bg.png]",
			"image[6.25,5.84375;1,1;gui_hb_bg.png]",
			"image[7.5,5.84375;1,1;gui_hb_bg.png]",
			"image[8.75,5.84375;1,1;gui_hb_bg.png]",
			"list[current_player;main;0,5.84375;8,4;]",

			"container_end[]",
		}

		local context = sfinv.get_or_create_context(player)
		context.page = "fast_craft:crafting"
		context.nav_idx = table.indexof(context.nav, context.page)

		fs = table.concat(fs) .. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
		if minetest.global_exists("cfs") then
			fs = cfs.style_formspec(fs, player)
		end
		return fs
	end

	sfinv.register_page("fast_craft:crafting", {
	    title = S("Fast Craft"),
	    get = function(self, player, context)
            return get_svt_sfinv_page(player) --.. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
	    end
	})

	fast_craft.regsiter_formspec_callback("", function(player, scroll_index, craft_index)
		player:set_inventory_formspec(
			get_svt_sfinv_page(player, scroll_index, craft_index)
		)
	end)
elseif gameid == "minetest" or minetest.get_modpath("sfinv") then
	fast_craft.craft_sizes = {1, 5, 25, 99}
	fast_craft.grid_color = "#292929"
	fast_craft.highlight_color = "#54716e"

	local function get_mtg_sfinv_page(player, scroll_index, craft_index)
		local fs = {
			"formspec_version[6]",
			"size[10.75,11]",
			"background[0.25,0.25;10.25,5.25;fc_background_mtg.png]",
			"container[0.5,0.5]",

			fast_craft.get_fast_craft_formspec(player, 9.75, scroll_index, craft_index),
			"list[current_player;main;0,5.25;8,4;]",

			"container_end[]",
		}

		local context = sfinv.get_or_create_context(player)
		context.page = "fast_craft:crafting"
		context.nav_idx = table.indexof(context.nav, context.page)

		fs = table.concat(fs) .. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
		if minetest.global_exists("cfs") then
			fs = cfs.style_formspec(fs, player)
		end
		return fs
	end

	sfinv.register_page("fast_craft:crafting", {
	    title = S("Fast Craft"),
	    get = function(self, player, context)
            return get_mtg_sfinv_page(player) --.. sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)
	    end
	})

	fast_craft.regsiter_formspec_callback("", function(player, scroll_index, craft_index)
		player:set_inventory_formspec(
			get_mtg_sfinv_page(player, scroll_index, craft_index)
		)
	end)
elseif gameid == "pmb_core" then
	dofile(modpath .. "/compatibility/pmb_recipe_import.lua")
	fast_craft.craft_sizes = {1, 5, 25, 100}

	local function show_pmb_craft_page(player, scroll_index, craft_index)
		local fs = {
			"formspec_version[6]",
			"size[13.25,12]",
			"container[0.5,0.5]",

			"box[" .. -8*p16 .. "," .. 0 - 8*p16 .. ";" .. 12.25 + 16*p16 .. "," .. 4.75 + 16*p16 .. ";#F110]",
			fast_craft.get_fast_craft_formspec(player, 12.25, scroll_index, craft_index),
			"box[" .. -8*p16 .. "," .. 6.25 - 8*p16 .. ";" .. 12.25 + 16*p16 .. "," .. 4.75 + 16*p16 .. ";#F110]",
			"list[current_player;main;0,6.25;10,3;10]",
			"list[current_player;main;0,10;10,1;]",

			"container_end[]",
		}
		fs = table.concat(fs)
		if minetest.global_exists("cfs") then
			fs = cfs.style_formspec(fs, player)
		end
		minetest.show_formspec(player:get_player_name(), "fast_craft:pmb_crafting", fs)
	end
	fast_craft.regsiter_formspec_callback("fast_craft:pmb_crafting", show_pmb_craft_page)


	-- local old_accessory_slots = pmb_inventory.player.get_accessories
	-- pmb_inventory.player.get_accessories = function(o)
	-- 	-- print("AAAAAAAAAAAAAAAA: " .. o.x .. " - " .. o.y)
	-- 	-- 16.3 7
	-- 	local fs = old_accessory_slots(o)
	-- 	local fc_button = {
	-- 		"style[show_pmb_fc;font=mono;border=false;bgimg_middle=12;padding=-12]",
	-- 		"style[show_pmb_fc;bgimg=pmb_button.png]",
	-- 		"style[show_pmb_fc:hovered;bgimg=pmb_button_hovered.png]",
	-- 		"image_button[" .. o.x .. "," .. o.y + 1 .. ";1,1;fc_mineclone_fc_button.png;show_pmb_fc;;false;false]",
	-- 	}
	-- 	fc_button = table.concat(fc_button)
	-- 	return fs .. fc_button
	-- end

	pmb_inventory.register_formspec_process("inventory", "fast_craft:show_pmb_fc", function()
		local fc_button = {
			"style[show_pmb_fc;font=mono;border=false;bgimg_middle=12;padding=-12]",
			"style[show_pmb_fc;bgimg=pmb_button.png]",
			"style[show_pmb_fc:hovered;bgimg=pmb_button_hovered.png]",
			"image_button[16.3,8;1,1;fc_mineclone_fc_button.png;show_pmb_fc;;false;false]",
		}
		fc_button = table.concat(fc_button)
		return fc_button
	end)

	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname ~= "" then return end
		if fields.show_pmb_fc then
			show_pmb_craft_page(player, nil, nil)
			return true
		end
	end)
else
	minetest.log("warning", "[fast_craft] No integration method found for game: '" .. gameid .. "'. Use the chat command '/fast_craft' to access functionality")
end

if minetest.get_modpath("awards") then
	fast_craft.register_on_craft(function(player, itemstack, recipe)
		if awards and awards.notify_craft then
			awards.notify_craft(player, itemstack:get_name(), itemstack:get_count())
		end
	end)
end
