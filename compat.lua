-- game specific stuff

local function get_mineclone_itemslots()
	local out = ""
	for x = 0.5, 10.25, 1.25 do
		for y = 5.75, 10.5, 1.25 do
			out = out .."image["..x..","..y..";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end

local function get_hotbar_background(x, y)
	local f = ""
	for i = 0, 7 do
		f = f .."image[" .. x + i*1.25 .. "," .. y .. ";1,1;gui_hb_bg.png]"
	end
	return f
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
		.. "background[0,0;10.75,11;fc_background.png]"

		.. "style_type[button;border=false;bgimg_middle=4;padding=-4]"
		.. "style_type[button;bgimg=fc_button.png]"
		.. "style_type[button:hovered;bgimg=fc_button_hovered.png]"
		.. "style_type[button:pressed;bgimg=fc_button_pressed.png]"

		.. "style_type[image_button;border=false;bgimg_middle=4;padding=-4]"
		.. "style_type[image_button;bgimg=fc_button.png]"
		.. "style_type[image_button:hovered;bgimg=fc_button_hovered.png]"
		.. "style_type[image_button:pressed;bgimg=fc_button_pressed.png]"
	},
	mtg = {
		group_icons = {
			wood = "default:wood",
			tree = "default:tree",
			stick = "default:stick",
			stone = "default:cobble",
		},
		style = ""
		.. "background[0.25,0.25;10.25,5.25;fc_background_mtg.png]"
		.. get_hotbar_background(0.5, 5.75)
	},
	mineclone = {
		-- group_icons = {},
		style = ""
		.. "background[0.25,0.25;10.25,5.25;fc_background_mineclone.png]"
		.. get_mineclone_itemslots()
	},
}

return games
