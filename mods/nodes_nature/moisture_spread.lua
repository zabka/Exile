-------------------------------------------------------------
--MOISTURE SPREAD
--move wettness through sediment
--other water effects

--20221029: changelog notes:
--fixe freezing of flowing water -> only source now
--add dynamic water source movement downward.
----Require expanding the flowing from 2 to 4 to avoid to many stranded water sources.
----Require increasing chances and frequency of the related abm function. This imply higher rate of moisure related functions.
--reduced probability of evaporation for stable ponds, with 0% if no flowing water right next to the source.

----------------------------------------------------------------
local get_node = minetest.get_node
local set_node = minetest.swap_node

--freeze water
--20221028: remove possibility to freez flowing water which could generate water source later
local function water_freeze(pos, node)
	local n_name = node.name

	if climate.can_freeze(pos) then

		if n_name == "nodes_nature:freshwater_source" then
			minetest.set_node(pos, {name = "nodes_nature:ice"})
		elseif n_name == "nodes_nature:salt_water_source" then
			minetest.set_node(pos, {name = "nodes_nature:sea_ice"})
		end
	end
end

----------------------------------------------------------------
--evaporate water
local function water_evap(pos, node)
	--evaporation
	if climate.can_evaporate(pos) then
		--reduce stable pond evaporation rate by checking if there is no flowing right next to it
		--the higher the number of flowing water next to it, the higher the chance to evaporate, else stable
		local flowing_neighbors = 0
		local check_pos = {x=pos.x+1, y=pos.y, z=pos.z}
		local check_node = get_node(check_pos)
		local check_node_name = check_node.name
		if string.find(check_node_name,"flowing") then
			flowing_neighbors = (flowing_neighbors + 1) * 2
		end
		check_pos = {x=pos.x-1, y=pos.y, z=pos.z}
		check_node = get_node(check_pos)
		check_node_name = check_node.name
		if string.find(check_node_name,"flowing") then
			flowing_neighbors = (flowing_neighbors + 1) * 2
		end
		check_pos = {x=pos.x, y=pos.y, z=pos.z+1}
		check_node = get_node(check_pos)
		check_node_name = check_node.name
		if string.find(check_node_name,"flowing") then
			flowing_neighbors = (flowing_neighbors + 1) * 2
		end
		check_pos = {x=pos.x, y=pos.y, z=pos.z-1}
		check_node = get_node(check_pos)
		check_node_name = check_node.name
		if string.find(check_node_name,"flowing") then
			flowing_neighbors = (flowing_neighbors + 1) * 2
		end
		-- else
		--lose it's own water to the atmosphere
		if flowing_neighbors > math.random(0,100) then
			minetest.remove_node(pos)
			return
		end
	end

end

--------------------------
--move sources down, otherwise erosion leaves them stranded
local function fall_water(pos,node)

	local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(pos_under).name
	
	if under_name == "nodes_nature:freshwater_flowing" or under_name == "nodes_nature:salt_water_flowing" or under_name == "air" then
		minetest.remove_node(pos)
		minetest.set_node(pos_under, {name = node.name})
		return pos
	end
	
	--Fresh water should not float on top of the ocean
	if under_name == "nodes_nature:salt_water_source" and node.name == "nodes_nature:freshwater_source" then
	   minetest.remove_node(pos)
	   return nil
	end

	return pos
end

--20221028: Adding water source migration
--Code inspired from dynamic_liquids by FaceDeer 
local all_direction_permutations = {
	{{x=0,z=1},{x=0,z=-1},{x=1,z=0},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=1},{x=0,z=-1},{x=-1,z=0},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=1},{x=1,z=0},{x=-1,z=0},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=1},{x=-1,z=0},{x=0,z=-1},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=1},{x=-1,z=0},{x=1,z=0},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=0,z=1},{x=-1,z=0},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=0,z=1},{x=1,z=0},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=1,z=0},{x=-1,z=0},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=1,z=0},{x=0,z=1},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=-1,z=0},{x=1,z=0},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=0,z=-1},{x=-1,z=0},{x=0,z=1},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=0,z=1},{x=0,z=-1},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=0,z=1},{x=-1,z=0},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=0,z=-1},{x=0,z=1},{x=-1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=0,z=-1},{x=-1,z=0},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=1},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=-1},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=0,z=1},{x=0,z=-1},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=0,z=-1},{x=1,z=0},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=0,z=-1},{x=0,z=1},{x=1,z=0},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=-1},{x=0,z=1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=1},{x=0,z=-1},{x=1,z=1},{x=1,z=-1},{x=-1,z=1},{x=-1,z=-1}},
}
-- POC behaviour, search for moving opportunity start from the center x with 1 checked nodes & 0 non checked nodes. The search on the inner circle start is random based on the all_direction_permutations matrix.
--[[
1	0	0	0	1	0	0	0	1
0	1	0	0	1	0	0	1	0
0	0	1	0	1	0	1	0	0
0	0	0	1	1	1	0	0	0
1	1	1	1	x	1	1	1	1
0	0	0	1	1	1	0	0	0
0	0	1	0	1	0	1	0	0
0	1	0	0	1	0	0	1	0
1	0	0	0	1	0	0	0	1
--]]
local function dynamic_water(pos,node)
	local check_pos = {x=pos.x, y=pos.y-1, z=pos.z}
	local check_node = get_node(check_pos)
	local check_node_name = check_node.name

	local perm = all_direction_permutations[math.random(24)]
	local dirs
	--the first loop is for the range of the search, based on the water flow range
	for j=1,4 do
		--the second loop is the search for the random swap possibilities
		for i=1,8 do
			dirs = perm[i]
			check_pos.x = pos.x + dirs.x * j
			check_pos.z = pos.z + dirs.z * j
			check_node = get_node(check_pos)
			check_node_name = check_node.name
			if check_node_name == "nodes_nature:freshwater_flowing" or check_node_name == "nodes_nature:salt_water_flowing" then
				set_node(pos, check_node)
				set_node(check_pos, node)
				return true
			end
		end
	end
	return false
end

local function water_handler(pos, node)
   pos = fall_water(pos, node)
   if pos == nil then
      return -- the water is not there anymore
   end
   if dynamic_water(pos,node) then
      return -- the water is not there anymore
   end 
   if climate.active_temp < 2 then
      water_freeze(pos, node)
   else
      water_evap(pos, node)
   end
end

--
minetest.register_abm({
	label = "Water Source Handling",
	nodenames = {"nodes_nature:freshwater_source", "nodes_nature:salt_water_source"},
	interval = 1,
	chance = 1,
	action = function(...)
		water_handler(...)
	end
})


----------------------------------------------------------------
--Thaw snow and ice

local function thaw_frozen(pos, node)
   --position gets overwritten by climate function otherwise,
   --not clear why
   local p = pos
   if climate.can_thaw(p) then

      local name = node.name
      if name == "nodes_nature:snow_block" then
	 minetest.set_node(p, {name = "nodes_nature:freshwater_source"})
      elseif name == "nodes_nature:snow" then
	 minetest.remove_node(p)
      elseif name == "nodes_nature:ice" then
	 local under = minetest.get_node({x = p.x, y = p.y-1, z =p.z})
	 if under.name == "nodes_nature:salt_water_source" then
	    minetest.remove_node(p)
	 else
	    minetest.set_node(p, {name = "nodes_nature:freshwater_source"})
	 end
      elseif name == "nodes_nature:sea_ice" then
	 minetest.set_node(p, {name = "nodes_nature:salt_water_source"})
	 return
      end
      minetest.check_for_falling(p)
      return
   end
end


minetest.register_abm({
	label = "Thaw Ice and snow",
	nodenames = {"nodes_nature:ice", "nodes_nature:snow_block", "nodes_nature:snow", "nodes_nature:sea_ice"},
	interval = 103,
	chance = 5,
	action = function(...)
		thaw_frozen(...)
	end
})



------------------------------------------------------------------
--
local function snow_accumulate(pos, node)
	if pos.y < -15 then
		return
	end

	--
	local posu = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(posu).name

	if under_name == "air" then
		return
	end

	--is snowing
	if not climate.get_snow(pos) then
		return
	end

	local nodedef = minetest.registered_nodes[under_name]
	if not nodedef then
		return
	end

	--walkable under i.e. not on water etc
	local walk = nodedef.walkable
	if not walk then
		return
	end

	--pile up snow
	if under_name == "nodes_nature:snow" then
		minetest.swap_node(posu, {name = "nodes_nature:snow_block"})
		return
	end

	--not on stairs, meshes etc
	local draw = nodedef.drawtype
	if draw ~= 'normal' then
		return
	end

	--thin snow
	minetest.set_node(pos, {name = "nodes_nature:snow"})

end


--
minetest.register_abm({
	label = "snow accumulate",
	nodenames = {"air", "nodes_nature:snow"},
	neighbors = {"group:crumbly","group:cracky", "group:snappy"},
	interval = 72,
	chance = 770,
	min_y = -15,
	action = function(...)
		snow_accumulate(...)
	end
})





--puddle detect
--check for sides that can hold water
--intended to be call for an air node with solid below
--i.e. somewhere to put a puddle
local function puddle_detect(pos)
	local sides = {
		{x = pos.x + 1, y = pos.y, z = pos.z},
		{x = pos.x - 1, y = pos.y, z = pos.z},
		{x = pos.x, y = pos.y, z = pos.z + 1},
		{x = pos.x, y = pos.y, z = pos.z - 1}
	}
	local puddle = true
	for i, v in ipairs(sides) do
		local s_name = minetest.get_node(v).name
		if minetest.get_item_group(s_name, "wet_sediment") == 0
		and minetest.get_item_group(s_name, "soft_stone") == 0
		and minetest.get_item_group(s_name, "masonry") == 0
		and minetest.get_item_group(s_name, "stone") == 0  then
			puddle = false
			break
		end
	end
	if puddle then
		return true
	else
		return false
	end
end

----------------------------------------------------------------
-- Wet nodes: move water down into dry sediment
--drain if exposed side or under
--evaporate at surface in hot sun

local function moisture_spread(pos, node)


	local nodename = node.name

	--dry version
	local nodedef = minetest.registered_nodes[nodename]
	local dry_name = nodedef._dry_name
	if not nodedef or not dry_name then
		return
	end

	--evaporation
	if climate.can_evaporate(pos) then
		--lose it's own water to the atmosphere
		minetest.swap_node(pos, {name = dry_name})
		return
	end

	--1= fresh or 2 = salty
	local water_type = minetest.get_item_group(nodename, "wet_sediment")


	--move through the soil, with a bias downwards
	local pos_sed = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y, z = pos.z + 1},
		{"group:sediment"})

	if #pos_sed > 0 then
		--select a random one
		local pos2 = pos_sed[math.random(#pos_sed)]
		--is it dry?
		local name2 = minetest.get_node(pos2).name
		if minetest.get_item_group(name2, "wet_sediment") == 0 then
			--lose it's own water, and move it
			minetest.swap_node(pos, {name = dry_name})
			--set wet version of what draining into
			local nodedef2 = minetest.registered_nodes[name2]
			if not nodedef2 then
				return
			end
			if water_type == 1 then
				minetest.swap_node(pos2, {name = nodedef2._wet_name})
			else
				--can it absorb salt or is it "destroyed" e.g. surface, ag
				local salt = nodedef2._wet_salty_name
				if not salt then
					--set it to it's salted parent material
					minetest.swap_node(pos2, {name = nodedef2.drop})
				else
					minetest.swap_node(pos2, {name = nodedef2._wet_salty_name})
				end
			end
			return
		end
	end

	--leach out
	--move out of the soil, only downwards
	local pos_air = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
		{"air"})

	if #pos_air > 0 then
		--select a random one
		local pos2 = pos_air[math.random(#pos_air)]
		--lose it's own water, and move it
		minetest.swap_node(pos, {name = dry_name})
		--source or flowing?
		if puddle_detect(pos2) then
			if water_type == 1 then
				minetest.set_node(pos2, {name = "nodes_nature:freshwater_source"})
			else
				minetest.set_node(pos2, {name = "nodes_nature:salt_water_source"})
			end
		else
			if water_type == 1 then
				minetest.set_node(pos2, {name = "nodes_nature:freshwater_flowing"})
			else
				minetest.set_node(pos2, {name = "nodes_nature:salt_water_flowing"})
			end
		end
		return
	end




end

--
--
minetest.register_abm({
	label = "Moisture Spread",
	nodenames = {"group:wet_sediment"},
	--neighbors = {"group:sediment"},
	interval = 121,
	chance = 15,
	action = function(...)
		moisture_spread(...)
	end
})


----------------------------------------------------------------
-- Water soaks into sediment
local function water_soak(pos, node)

	local nodename = node.name

	--move into the soil, with a bais downwards
	local pos_sed = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y, z = pos.z + 1},
		{"group:sediment"})

	if #pos_sed > 0 then
		--select a random one
		local pos2 = pos_sed[math.random(#pos_sed)]
		--is it dry?
		local name2 = minetest.get_node(pos2).name
		if minetest.get_item_group(name2, "wet_sediment") == 0 then
			--
			if nodename == "nodes_nature:freshwater_source" then
				--non-renew
				minetest.swap_node(pos, {name = "air"})
				--set wet version of what draining into
				local nodedef2 = minetest.registered_nodes[name2]
				if not nodedef2 then
					return
				end
				minetest.swap_node(pos2, {name = nodedef2._wet_name})
				return
			else
				--set salty wet version of what draining into
				local nodedef2 = minetest.registered_nodes[name2]
				if not nodedef2 then
					return
				end
				minetest.swap_node(pos2, {name = nodedef2._wet_salty_name})
				return
			end
		end
	end

end

--
--
minetest.register_abm({
	label = "Water Soak",
	nodenames = {"nodes_nature:freshwater_source", "nodes_nature:salt_water_source"},
	neighbors = {"group:sediment"},
	interval = 147,
	chance = 100,
	action = function(...)
		water_soak(...)
	end
})



----------------------------------------------------------------
-- flowing Water erode
--will rearrange sediments until out of the path of flow..
--and cannot shift them anywhere else
--eventually getting a stable "river" bed shape if it can
local function water_erode(pos, node)
	--take the sediment under it and move it to the side
	local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(pos_under).name
	if minetest.get_item_group(under_name, "sediment") > 0 then

		--move it to another part of water, so long as it is grounded
		local pos_flow = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
			{"nodes_nature:freshwater_flowing", "nodes_nature:salt_water_flowing" })

		if #pos_flow > 0 then
			--select a random one
			local pos2 = pos_flow[math.random(#pos_flow)]
			--check under
			local pos_uf = {x = pos2.x, y = pos2.y - 1, z = pos2.z}
			local uf_name = minetest.get_node(pos_uf).name

			local nodedefu = minetest.registered_nodes[uf_name]
			if not nodedefu then
				return
			end

			if nodedefu.walkable then

				--shift the sediment and put the water in its place
				minetest.remove_node(pos)
				minetest.set_node(pos_under, {name = node.name})
				--set dropped
				local nodedef = minetest.registered_nodes[under_name]
				if not nodedef then
					return
				end
				minetest.set_node(pos2, {name = nodedef.drop})
			end
		end

	elseif minetest.get_item_group(under_name, "water") > 0 or under_name == "air" then
		--it is a water fall
		--take sediment from beside and move under to fill gap
		--move it to another part of water, so long as it is grounded
		local pos_flow = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y, z = pos.z + 1},
			{"group:sediment"})

		if #pos_flow > 0 then
			--select a random one
			local pos2 = pos_flow[math.random(#pos_flow)]

			--check under is solid
			local pos_uf = {x = pos_under.x, y = pos_under.y - 1, z = pos_under.z}
			local uf_name = minetest.get_node(pos_uf).name

			local nodedefu = minetest.registered_nodes[uf_name]
			if not nodedefu then
				return
			end

			if nodedefu.walkable then
				--take it and drop it underneath
				--set dropped
				local side_name = minetest.get_node(pos2).name
				local nodedef = minetest.registered_nodes[side_name]
				if not nodedef then
					return
				end
				minetest.remove_node(pos2)
				minetest.set_node(pos_under, {name = nodedef.drop})
			end
		end

	end
end


--
--
minetest.register_abm({
	label = "Water Erode",
	nodenames = {"nodes_nature:freshwater_flowing", "nodes_nature:salt_water_flowing"},
	neighbors = {"group:sediment"},
	interval = 120,
	chance = 30,
	action = function(...)
		water_erode(...)
	end
})


------------------------------------------------------------------
--soak water into soil, catch water in puddles
local function rain_soak(pos, node)
	if pos.y < -15 then
		return
	end
	local name = node.name


	if climate.get_rain(pos) then
		--dry sediment absorbs water, wet and solids can trap puddles
		if minetest.get_item_group(name, "sediment") >0
		and minetest.get_item_group(name, "wet_sediment") == 0
		then
			--set wet version of what draining into
			local nodedef = minetest.registered_nodes[name]
			if not nodedef then
				return
			end
			minetest.swap_node(pos, {name = nodedef._wet_name})
			return
		elseif math.random()<0.3 then
			local posa = {x = pos.x, y = pos.y + 1, z = pos.z}
			if puddle_detect(posa) then
				minetest.set_node(posa, {name = "nodes_nature:freshwater_source"})
			end
		end

	end
end


--
minetest.register_abm({
	label = "Rain Soak",
	--calling for stone is for puddles only, but means calling all stone
	--nodenames = {"group:sediment", "group:stone", "group:soft_stone"},
	nodenames = {"group:sediment"},
	interval = 92,
	chance = 180,
	min_y = -15,
	action = function(...)
		rain_soak(...)
	end
})
