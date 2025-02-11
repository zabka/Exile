-- bones/init.lua

-- Minetest 0.4 mod: bones
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("bones")

creative = creative

bones = {}

local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end

local bones_formspec =
	"size[8,9]" ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]"
	--default.get_hotbar_bg(0,4.85)

local share_bones_time = tonumber(minetest.settings:get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(minetest.settings:get("share_bones_time_early")) or share_bones_time / 4

minetest.register_node("bones:bones", {
	description = S("Bones"),
	inventory_image = "bones_inv.png",
	wield_image = "bones_inv.png",
	tiles = {"bones_bone.png"},
	stack_max = minimal.stack_max_bulky,
	drawtype = "nodebox",
	node_box = {
			type = "fixed",
			fixed = {
				{-0.1250, -0.5000, -0.5000,  0.0625, -0.3750,  0.0625}, -- NodeBox1
				{-0.1875, -0.5000,  0.0625,  0.1250, -0.3125,  0.2500}, -- NodeBox2
				{ 0.0625, -0.5000, -0.5000,  0.3125, -0.4375, -0.3750}, -- NodeBox3
				{-0.3750, -0.5000, -0.5000, -0.1250, -0.4375, -0.3750}, -- NodeBox4
				{ 0.0625, -0.5000, -0.3125,  0.3125, -0.4375, -0.2500}, -- NodeBox5
				{-0.3750, -0.5000, -0.3125, -0.1250, -0.4375, -0.2500}, -- NodeBox6
				{-0.3750, -0.4375, -0.3125, -0.3125, -0.3125, -0.2500}, -- NodeBox7
				{ 0.2500, -0.4375, -0.3125,  0.3125, -0.3125, -0.2500}, -- NodeBox8
				{ 0.0000, -0.3125, -0.3125,  0.3125, -0.2500, -0.2500}, -- NodeBox9
				{-0.3750, -0.3125, -0.3125, -0.0625, -0.2500, -0.2500}, -- NodeBox10
				{-0.0625, -0.3125, -0.3125,  0.0000, -0.2500, -0.0625}, -- NodeBox11
				{-0.3750, -0.5000, -0.1875, -0.1250, -0.4375, -0.1250}, -- NodeBox12
				{-0.3750, -0.3125, -0.1875, -0.0625, -0.2500, -0.1250}, -- NodeBox13
				{-0.3750, -0.4375, -0.1875, -0.3125, -0.3125, -0.1250}, -- NodeBox14
				{ 0.0625, -0.5000, -0.1875,  0.3125, -0.4375, -0.1250}, -- NodeBox15
				{ 0.2500, -0.4375, -0.1875,  0.3125, -0.3125, -0.1250}, -- NodeBox16
				{ 0.3750, -0.5000, -0.4375,  0.4375, -0.4375, -0.1250}, -- NodeBox17
				{-0.4375, -0.5000, -0.2500, -0.3750, -0.4375,  0.0625}, -- NodeBox18
				{-0.3125, -0.5000,  0.1250, -0.1875, -0.4375,  0.4375}, -- NodeBox19
				{ 0.1875, -0.5000,  0.0000,  0.2500, -0.3750,  0.4375}, -- NodeBox20
				{ 0.3125, -0.5000, -0.0625,  0.5000, -0.4375,  0.1250}, -- NodeBox21
				{ 0.2500, -0.3750, -0.1250,  0.4375, -0.1875,  0.1875}, -- NodeBox23
				{ 0.3125, -0.4375, -0.0625,  0.4375, -0.3750,  0.1250}, -- NodeBox28
				{ 0.3125, -0.5000,  0.4375,  0.5000, -0.4375,  0.5000}, -- NodeBox29
				{-0.4375, -0.5000,  0.1875, -0.3750, -0.4375,  0.3750}, -- NodeBox30
				{ 0.4375, -0.2500, -0.1250,  0.5000, -0.1875,  0.1875}, -- NodeBox31
				{ 0.4375, -0.3750, -0.1250,  0.5000, -0.3125,  0.1875}, -- NodeBox32
				{ 0.4375, -0.3125, -0.1250,  0.5000, -0.2500, -0.0625}, -- NodeBox33
				{ 0.4375, -0.3125,  0.1250,  0.5000, -0.2500,  0.1875}, -- NodeBox34
				{ 0.4375, -0.3125,  0.0000,  0.5000, -0.2500,  0.0625}, -- NodeBox35
			}
		},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	groups = {dig_immediate = 2, attached_node = 1, temp_pass = 1, falling_node = 1},
	sounds = nodes_nature.node_sound_gravel_defaults(),

	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local name = ""
		if player then
			name = player:get_player_name()
		end
		return is_owner(pos, name) and inv:is_empty("main")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if is_owner(pos, player:get_player_name()) then
			return count
		end
		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if is_owner(pos, player:get_player_name()) then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if meta:get_inventory():is_empty("main") then
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = "bones:bones"}) then
				inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos, "bones:bones")
			end
			minetest.remove_node(pos)
		end
	end,

	on_punch = function(pos, node, player)
		if not is_owner(pos, player:get_player_name()) then
			return
		end

		if minimal.infotext_is_empty(pos) then
			return
		end

		local inv = minetest.get_meta(pos):get_inventory()
		local player_inv = player:get_inventory()
		local has_space = true

		for i = 1, inv:get_size("main") do
			local stk = inv:get_stack("main", i)
			if player_inv:room_for_item("main", stk) then
				inv:set_stack("main", i, nil)
				player_inv:add_item("main", stk)
			else
				has_space = false
				break
			end
		end

		-- remove bones if player emptied them
		if has_space then
			if player_inv:room_for_item("main", {name = "bones:bones"}) then
				player_inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos,"bones:bones")
			end
			minetest.remove_node(pos)
		end
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local time = meta:get_int("time") + elapsed
		if time >= share_bones_time then
			minimal.infotext_merge(pos,'Status: '.. S("@1's old bones", meta:get_string("owner")),meta)
			meta:set_string("owner", "")
		else
			meta:set_int("time", time)
			return true
		end
	end,
	on_blast = function(pos)
	end,
})

local function may_replace(pos, player)
	local node_name = minetest.get_node(pos).name
	local node_definition = minetest.registered_nodes[node_name]

	-- if the node is unknown, we return false
	if not node_definition then
		return false
	end

	-- allow replacing air and liquids
	if node_name == "air" or node_definition.liquidtype ~= "none" then
		return true
	end

	-- don't replace filled chests and other nodes that don't allow it
	local can_dig_func = node_definition.can_dig
	if can_dig_func and not can_dig_func(pos, player) then
		return false
	end

	-- default to each nodes buildable_to; if a placed block would replace it, why shouldn't bones?
	-- flowers being squished by bones are more realistical than a squished stone, too
	-- exception are of course any protected buildable_to
	return node_definition.buildable_to and not minetest.is_protected(pos, player:get_player_name())
end

local drop = function(pos, itemstack)
	local obj = minetest.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:set_velocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end

local player_inventory_lists = { "main", "craft" }
bones.player_inventory_lists = player_inventory_lists

local function is_all_empty(player_inv)
	for _, list_name in ipairs(player_inventory_lists) do
		if not player_inv:is_empty(list_name) then
			return false
		end
	end
	return true
end

minetest.register_on_dieplayer(function(player)

	local bones_mode = minetest.settings:get("bones_mode") or "bones"
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end

	local bones_position_message = minetest.settings:get_bool("bones_position_message") == true
	local player_name = player:get_player_name()
	local pos = vector.round(player:get_pos())
	local pos_string = minetest.pos_to_string(pos)

	-- return if keep inventory set or in creative mode
	if bones_mode == "keep" or (creative and creative.is_enabled_for
			and creative.is_enabled_for(player:get_player_name())) then
		minetest.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	local player_inv = player:get_inventory()
	if is_all_empty(player_inv) then
		minetest.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	-- check if it's possible to place bones, if not find space near player
	if bones_mode == "bones" and not may_replace(pos, player) then
		local air = minetest.find_node_near(pos, 1, {"air"})
		if air and not minetest.is_protected(air, player_name) then
			pos = air
		else
			bones_mode = "drop"
		end
	end

	if bones_mode == "drop" then
		for _, list_name in ipairs(player_inventory_lists) do
		   for i = 1, player_inv:get_size(list_name) do
		      local stack = player_inv:get_stack(list_name, i)
		      if minetest.get_item_group(stack:get_name(),
						 "nobones") < 1 then
			 drop(pos, stack)
		      end
		   end
		   player_inv:set_list(list_name, {})
		end
		drop(pos, ItemStack("bones:bones"))
		minetest.log("action", player_name .. " dies at " .. pos_string ..
			". Inventory dropped")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2, and dropped their inventory.", player_name, pos_string))
		end
		return
	end

	local param2 = minetest.dir_to_facedir(player:get_look_dir())
	repeat
	   local pos2 = vector.add(pos, {x=0,y=-1,z=0})
	   if minetest.get_node(pos2).name == "air" then
	      pos = pos2
	   else
	      pos2 = nil
	   end
	until pos2 == nil
	player:set_pos(pos)
	minetest.set_node(pos, {name = "bones:bones", param2 = param2})
	minetest.log("action", player_name .. " dies at " .. pos_string ..
		". Bones placed")
	if bones_position_message then
		minetest.chat_send_player(player_name, S("@1 died at @2, and bones were placed.", player_name, pos_string))
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 4)

	for _, list_name in ipairs(player_inventory_lists) do
		for i = 1, player_inv:get_size(list_name) do
		   local stack = player_inv:get_stack(list_name, i)
		   if minetest.get_item_group(stack:get_name(),
					      "nobones") == 0 then
		      if inv:room_for_item("main", stack) then
			 inv:add_item("main", stack)
		      else -- no space left
			 drop(pos, stack)
		      end
		   end
		end
		player_inv:set_list(list_name, {})
	end

	meta:set_string("formspec", bones_formspec)
	meta:set_string("owner", player_name)

	if share_bones_time ~= 0 then
		minimal.infotext_merge(pos,'Status: '..S("@1's fresh bones", player_name),meta)
		if share_bones_time_early == 0 or not minetest.is_protected(pos, player_name) then
			meta:set_int("time", 0)
		else
			meta:set_int("time", (share_bones_time - share_bones_time_early))
		end

		minetest.get_node_timer(pos):start(10)
	else

		minimal.infotext_merge(pos,'Status: '..S("@1's bones", player_name),meta)
	end
end)
