-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

S=minimal.S


function minimal.protection_nail_use( itemstack, user, pointed_thing )
	local pt_pos=minetest.get_pointed_thing_position(pointed_thing,false)
	local pt_node=minetest.get_node(pt_pos)
	local pt_meta=minetest.get_meta(pt_pos)
	local owner = user:get_player_name()
	if not pt_meta:contains('owner') then
		pt_meta:set_string("owner", owner)
		pt_meta:set_string('nailed', owner)
		itemstack:take_item()
		minimal.infotext_merge(pt_pos, nil, pt_meta)
	end
	return itemstack
end


-- Set owner for protected items.
function minimal.protection_after_place_node( pos, placer, itemstack, pointed_thing )
	local iDef=itemstack:get_definition()
	local iName=itemstack:get_name()
	local pn = placer:get_player_name()
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pn)
	meta:set_string('nailed', pn)
	minimal.infotext_merge(pos,nil,meta)
	return (creative and creative.is_enabled_for and creative.is_enabled_for(pn))
end

minetest.register_on_dignode(function(pos,oldnode,digger)
	local meta = minetest.get_meta(pos)

print (dump(oldnode))
	if meta:contains('nailed') then
		--give digger back the nails
		inv = digger:get_meta():get_inventory()
		if inv:room_for_item("main", 'tech::nails') then
			inv:add_item(inv, 'tech::nails')
		else
			minetest.chat_send_player(digger, "No room in inventory!")
			minetest.add_item(pos, 'tech::nails')
		end
	return true
	end

end)

