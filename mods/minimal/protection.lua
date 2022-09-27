-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

S=minimal.S
local __nail_use_count = 3 
local __ready = {}
local ready = function(name, pos, count, timeout)
	-- { playername = { timeout=time() + __timeout, count = __use_count } }
	local timeout = timeout or 2 -- 2 second window for timeout
	local count = count or 3 -- number of clicks
	local ready = __ready[name]
	if ready and ready.pos == pos then
		ready.count = ready.count + 1
		if os.time() < ready.timeout then
			if ready.count >= count then
				__ready[name]  = nil
				return true
			else
				return false
			end
		end
	end
	__ready[name] = {
		timeout = os.time() + timeout,
		count = 1,
		pos = pos,
	}
	return false
end

function minimal.protection_nail_use( itemstack, user, pointed_thing )
	local owner = user:get_player_name()
	local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
	if ready(owner, pt_pos, __nail_use_count) then 
		local pt_node=minetest.get_node(pt_pos)
		local pt_meta=minetest.get_meta(pt_pos)
		if not pt_meta:contains('owner') then
			pt_meta:set_string("owner", owner)
			pt_meta:set_string('nailed', owner)
			itemstack:take_item()
			minimal.infotext_merge(pt_pos, nil, pt_meta)
		end
	else
		-- play hammering sound
	end

	return itemstack
end


-- Set owner for protected items.
function minimal.protection_after_place_node( pos, placer, itemstack, pointed_thing )
	local pn = placer:get_player_name()
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pn)
	minimal.infotext_merge(pos,nil,meta)
	return (creative and creative.is_enabled_for and creative.is_enabled_for(pn))
end

function minimal.protection_on_dig(pos,oldnode,digger)
	local meta = minetest.get_meta(pos)
	if meta:contains('nailed') then
		local owner = meta:get_string('owner')
		if owner == digger:get_player_name() then
			--give digger back the nails
			inv = digger:get_inventory()
			if inv:room_for_item("main", 'tech:nails') then
				inv:add_item("main",'tech:nails')
			else
				minetest.chat_send_player(digger, "No room in inventory!")
				minetest.add_item(pos, 'tech:nails')
			end
			meta:set_string('nailed', "")
		end
	end
end


