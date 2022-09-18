-- set info text using following format:
-- Node_definintion_description
-- Owner: Owner_Name
-- Line 3 Text
-- Line 4 Text
-- Line 5 Text
--
-- lines containing : use text left of : as the key
-- to make it easy to replace lines by key
--

minimal=minimal
local S=minimal.S
local debug = 0

function print_debug(msg,old_lines,new_lines,unkeyed,output_lines)
	if debug == 1 then
		print (msg)
		print ("old_lines"..dump(old_lines))
		print ("new_lines"..dump(new_lines))
		print ("unkeyed: "..dump(unkeyed))
		print ("output_lines: "..dump(output_lines))
	end
end

local fixed_order = {
--	"", 			-- node description - unkeyed but fixed as first line
	"Owner",		-- Node Owner
	"Label",		-- Custom Label
	"Creator",		-- Node Creator
	"Location", 		-- Transporter Location
	"Destination",  	-- Transporter Destination
	"Description",  	-- Trigger Description
	"Contents",		-- Cooking Pot Contents
	"Status",		-- Cooking Pot status
	"Note",			-- Note field (added for cooking pot)
	"Dye Test Bundle",	-- Dye Bundles
	"Bed",			-- Beds
}
-- Split infotext line into keyed or unkeyed list. 
function infotext_parse_key(line,keyed_list,unkeyed_list)
	local ikey = line:find(':',1,true)
	local key
	if ikey then
		--remove ':' from key
		key = line:sub(1, ikey - 1)
	end
	if #line == ikey then -- Nothing after ':' - delete this key
		line = ""
	end
	if key then
--print("<<<"..(key or "")..">>>")
		keyed_list[key] = line
	else
		table.insert(unkeyed_list,line)

	end
end

-- Get infotext from meta data and split it into lines.
-- sort it into keyed and unkeyed lists and return the lists
function infotext_parse_infotext(meta)
	local keyed = {} 
	local unkeyed = {} -- lines without keys
	local infotext_string = meta:get_string("infotext")
	if infotext_string ~= '' then
--print("---------\nINFOTEXT:  "..infotext_string)
		for line in infotext_string:gmatch("[^\r\n]+") do
--print ("gmatch: "..line)
			infotext_parse_key(line,keyed,unkeyed)
		end
		table.remove(unkeyed,1) -- remove the description from the old infotext
	end
--print ("old_lines: "..dump(keyed))
--print ("unkeyed_lines:"..dump(unkeyed))
	return keyed,unkeyed
end

-- Accept a string with a single infotext line or a table of multiple strings
-- split the lines into keyed and unkeyed lists provided.
function infotext_parse_new(lines,unkeyed)
	local keyed = {}
	-- passed a string, convert it to the expected table
	if lines and type(lines) == 'string' then
		local line=lines
		lines={}
		if line ~= "" then
			table.insert(lines,line)
		end
	end
--print ("infotext_parse_new\n----\n"..dump(lines))
	if lines and type(lines) == 'table' then
		for _,line in ipairs(lines) do
--print("parse_new - line: "..line)
			infotext_parse_key(line,keyed,unkeyed)
		end
	end
	return keyed
end

function table.removekey(table, key)
	if table and type(table) == 'table' then
		local value = table[key]
		table[key] = nil
		return value
	end
	return nil
end
-- Append keys to the output removing them from the append_list, and optionally a second list
-- Intended for 2 passes, one with the new infotext lines and the old lines from meta data as
-- the remove list. The second pass is with only the old lines and no additional remove lines.
function infotext_append_keys(output_list, append_list, remove_list)
	if append_list then
		for key,line in pairs(append_list) do
			local new_line = table.removekey(append_list,key)
			if remove_list then
				table.removekey(remove_list,key)
			end
			if new_line ~= "" then -- Empty lines don't get added to output
				table.insert(output_list,new_line)
			end
		end
	end
end

function infotext_append_unkeyed(output_lines,unkeyed)
	-- append unkeyed lines
	if #unkeyed > 0 then
		for _, line in ipairs(unkeyed) do
			-- Exclude the node description from unkeyed lines
			if line and line ~= output_lines[1] then
				table.insert(output_lines, line)
			end
		end
	end
end

-- Generate infotext from a list of lines and save to meta
function minimal.infotext_output_meta(meta,output_lines)
	-- combine lines into string and set infotext
	local text="";
	for _,line in ipairs(output_lines) do
		text = text .. line .. "\n"
	end
	text = text:sub(1, -2) -- remove last \n
	meta:set_string("infotext",text)
--print (text)
	return text
end

function infotext_output_desc_owner(pos,meta)
	local output_lines={}
	-- Line 1 is always the item description
	local desc = minetest.registered_nodes[minetest.get_node(pos).name].description
	output_lines[1] = desc
	-- Line 2 is always Owner if set
	local owner = meta:get_string('owner')
	if owner and owner ~= "" then
		output_lines[2] = "Owner: " .. owner
	end
	return output_lines
end


-- Main funtion called from other modules.
-- Takes the pos of the node being modifide, in string or pos object form and
-- a single line of text or a list of text lines to add/replace.
-- Lines should ideally be keyed as follows:

-- key: Infotext line to add/replace

-- New keys replace old keys.
-- If called with no lines, and no existing info text, The description of the node and 
-- name of the owner will be added.  Any infotext added will also include these lines
-- using data from the node's description and meta data.
-- remove_desc is an optional flag to remove the description from old infotext if it exists.
-- 		fixes a problem for nodes that change with state changes.

function minimal.set_infotext(pos, add_lines, meta)
	if type(pos) == "string" then
		pos = minetest.string_to_pos(pos)
	end

--print ("***************************\n"..dump(pos))
	if not meta then
		meta = minetest.get_meta(pos)
	end

	local output_lines=infotext_output_desc_owner(pos,meta)
	local old_lines,unkeyed = infotext_parse_infotext(meta)
	local new_lines = infotext_parse_new(add_lines, nil, unkeyed)
--print_debug("Before Ordered Lines",old_lines,new_lines,unkeyed,output_lines)
	-- Use fixed_order list to find output_lines
	for i, ordered_key in ipairs(fixed_order) do 
		local old_line=table.removekey(old_lines, ordered_key)
		local new_line=table.removekey(new_lines, ordered_key)
		if i > 1 then -- skip writing out Owner; already added above
			if new_line then
--print ("NEW_LINE==="..new_line)
				table.insert(output_lines,new_line)
			elseif old_line then
--print ("OLD_LINE==="..old_line)
				table.insert(output_lines,old_line)
			end
		end
	end
--print("*&*&*&*&*&*&*& "..dump(new_lines))
--print_debug("After Ordered Lines",old_lines,new_lines,unkeyed,output_lines)
	infotext_append_keys(output_lines,new_lines,old_lines)
--print_debug("After Appending new Keys",old_lines,new_lines,unkeyed,output_lines)
	infotext_append_keys(output_lines,old_lines)
--print_debug("After Appending old Keys",old_lines,new_lines,unkeyed,output_lines)
	infotext_append_unkeyed(output_lines,unkeyed)

--print_debug("After Appending UNKEYED",old_lines,new_lines,unkeyed,output_lines)
	return minimal.infotext_output_meta(meta,output_lines)
end


function minimal.infotext_delete_key(meta,key)
	local infotext_string = meta:get_string("infotext")
print(infotext_string)
	if infotext_string ~= '' then
print(key..':')
		--XXX Not capturing the \n at the end of the line
		infotext_string = infotext_string:gsub(key..':[^\n]+[\n]*','')
	end
	meta:set_string("infotext",infotext_string)
print(infotext_string)
end
 
