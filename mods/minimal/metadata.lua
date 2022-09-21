minimal=minimal

minimal.metadata={}



function minimal.metadata.after_place_node(imeta,meta)
	-- copy meta from item to node
	for _, key in ipairs({'creator','label'}) do
		if key ~= '' and imeta:contains(key) then
			meta:set_string(key, imeta:get_string(key))
		end
	end
end

function minimal.metadata.preserve_metadata(imeta,oldmeta)
		for _, key in ipairs({'creator','label'}) do
			if key ~= '' then
				imeta:set_string(key, oldmeta[key])
			end
		end
end


