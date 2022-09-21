minimal=minimal

minimal.metadata={}
<<<<<<< HEAD
local copy_list={'creator','label'}


-- copy itemes metadata to nodes metadata.
function minimal.metadata.after_place_node(imeta,meta)
	-- copy meta from item to node
	for _, key in ipairs({copy_list}) do
=======



function minimal.metadata.after_place_node(imeta,meta)
	-- copy meta from item to node
	for _, key in ipairs({'creator','label'}) do
>>>>>>> 3795a88f6b11bf3bfec0b9f442fea23c170ac3b1
		if key ~= '' and imeta:contains(key) then
			meta:set_string(key, imeta:get_string(key))
		end
	end
end

<<<<<<< HEAD

-- Copies node metadata to items metadata.  
function minimal.metadata.preserve_metadata(imeta,oldmeta)
		for _, key in ipairs(copy_list) do
=======
function minimal.metadata.preserve_metadata(imeta,oldmeta)
		for _, key in ipairs({'creator','label'}) do
>>>>>>> 3795a88f6b11bf3bfec0b9f442fea23c170ac3b1
			if key ~= '' then
				imeta:set_string(key, oldmeta[key])
			end
		end
end


