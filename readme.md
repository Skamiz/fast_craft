#about
This mod provides an alternative crafting system, loosely inspired by Terraria.

Instead of aranging ingredients in the crafting grid, you can choose the recipe
from a list of all recipes you have the needed ingredients for and then select
the amount you want to craft. No need for draging around item stacks and
memorizing paterns.

Note that there is no way to detect when the player opens their inventory,
thus the list of aviable recipes is out of date sometimes
and has to be updated by pressing any button.

#warnings
Crafting may behave incorrectly in case of recipes which ask for a group and
simultaneously for a specific item which is part of that group.
I don't recall ever seeing such a recipe, so it shouldn't be a problem,
but be aware just in case.

Can cause noticable slowdown in starting the world, when importing recipes.
This is due to 'minetest.get_craft_result(recipe)' being the only way to detect
if a recipe uses replacements. And this function is relatively slow.

#settings
This mod has two settings which can be configured from in game.

'import_recipes' - allows you to disable the importing of recipes from the
					default crafting system

'simplify_recipes' - when importing recipes, try to simplify them
	example: 3 wood -> 6 wooden slab will be turned into 1 wood -> 2 wooden slab

#functions
fast_craft.register_craft({
	output = { -- main output
		"item_out",
		item_count,
	},
	additional_output = { -- replacements and byproducts
		["ao_1"] = 1
	},
	input = {
		["item_in_a"] = 1,
		["item_in_b"] = 2,
		["item_in_c"] = 1,
	},
	conditions = { -- if any one condition is true, the recipe is available
		["name_of_condition_1"] = true,
		["name_of_condition_2"] = true,
	}
})

fast_craft.register_condition("none", {
	-- returns true when condition is fulfiled, making it possible to craft recipes -- -- with this condition
	func = function(player)
		return true
	end,

	-- not yet used
	description = "Short description of the condition.",
	icon = *.png file or item name representing this condition
})

#translation
There are a few user facing strings to calrify to the player what is going on.
The mod is set up to support translations, which won't be of any use until I
actually have some translations.

A template is provided in the locale folder.

#license
MIT License

Copyright (c) 2023 Skamiz Kazzarch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
