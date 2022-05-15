-- game specific stuff

local function get_mineclone_itemslots()
	local out = ""
	for x = 0.25, 10, 1.25 do
		for y = 5.25, 10, 1.25 do
			out = out .."image["..x..","..y..";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end

local games = {
	cicrev = {
		group_icons = {
			planks = "cicrev:planks_oak",
			log = "cicrev:log_oak",
		},
		style = ""
		.. "bgcolor[;neither;]"
		.. "listcolors[#777777;#929292;#00000000]"
		.. "background[0,0;10.25,10.25;fc_background.png]"
		.. "style_type[button;bgimg=fc_button_8x8.png]"
		.. "style_type[image_button;bgimg=fc_button_8x8.png]"
		.. "style_type[item_image_button;bgimg=fc_button_16x16.png]"
	},
	mtg = {
		group_icons = {
			wood = "default:wood",
			tree = "default:tree",
			stick = "default:stick",
			stone = "default:cobble",
		},
		style = ""
		.. "background[0,0;10.25,10.25;fc_background_mtg.png]"
	},
	mineclone = {
		-- group_icons = {},
		style = ""
		.. get_mineclone_itemslots()
		.. "background[0,0;10.25,10.25;fc_background_mineclone.png]"
	},
}

return games
