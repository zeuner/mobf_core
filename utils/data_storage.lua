-------------------------------------------------------------------------------
-- Utils package
--
-- License CC BY
--
--! @file data_storage.lua
--! @brief file containing helper functions for remanent data storage
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- name: read_world_data(identifier)
--
--! @brief read world specific data and provide as lua table
--
--! @param identifier some string to uniquely identify this dataset
--
--! @return table containing data
-------------------------------------------------------------------------------
utils.read_world_data = function(identifier)

	local retval = nil
	
	--read from file
	local world_path = core.get_worldpath()

	local file,error = io.open(world_path .. "/" .. identifier,"r")

	if file ~= nil then
		local data_raw = file:read("*a")
		file:close()

		if data_raw ~= nil then
			retval = core.deserialize(data_raw)
		end
	end
	
	return retval
end

-------------------------------------------------------------------------------
-- name: write_world_data(identifier, data)
--
--! @brief read world specific data and provide as lua table
--
--! @param identifier some string to uniquely identify this dataset
--! @param data the data to be saved
--
--! @return true/false successfull/error
-------------------------------------------------------------------------------
utils.write_world_data = function(identifier, data)

	local world_path = core.get_worldpath()
	local file,error = io.open(world_path .. "/" .. identifier,"w")

	if error ~= nil then
		core.log(LOGLEVEL_ERROR,"UTILS: failed to open world specific data file for " .. identifier)
	end
	mobf_assert_backtrace(file ~= nil)

	local serialized_raw_data = core.serialize(data)
	
	local serialized_data = ""
	local pos = 1
	local depth = 0
	local chars_since_open = 0
	local non_whitespace_since_open = false
	
	for i = 1, serialized_raw_data:len(), 1 do
		local last_char = serialized_raw_data:sub(i-1,i-1)
		local char = serialized_raw_data:sub(i,i)
		local next_char = serialized_raw_data:sub(i+1,i+1)

		if char == "{" then

			if next_char ~= "}" and last_char ~= "{" then
				serialized_data = serialized_data .. "\n"

				for j = 1, depth , 1 do
					serialized_data = serialized_data .. "  "
				end
			
			end
				
			serialized_data = serialized_data .. char
			depth = depth + 1
			
			if depth < 0 then
				depth = 0
			end
			
			if next_char ~= "}" then
				serialized_data = serialized_data .. "\n"
				for j = 1, depth , 1 do
					serialized_data = serialized_data .. "  "
				end
			end
			
			chars_since_open = 0
			non_whitespace_since_open = false
		elseif char == "}" then
			depth = depth - 1
			
			if chars_since_open ~= 0 then
			
				if chars_since_open > 0 then
					serialized_data = serialized_data .. "\n"
				end

				for j = 1, depth , 1 do
					serialized_data = serialized_data .. "  "
				end
			end
			serialized_data = serialized_data .. char
			
			if next_char ~= "," then
				serialized_data = serialized_data .. "\n"
			end
			chars_since_open = -1
		elseif char == "," and last_char == "}" then
			serialized_data = serialized_data .. char
			serialized_data = serialized_data .. "\n"
			for j = 1, depth , 1 do
				serialized_data = serialized_data .. "  "
			end
		elseif  char ~= nil then
		
			if char ~= " " or non_whitespace_since_open then
				serialized_data = serialized_data .. char
				chars_since_open = chars_since_open + 1
				non_whitespace_since_open = true
			end
		end
	end

	file:write(serialized_data)
	file:close()
end