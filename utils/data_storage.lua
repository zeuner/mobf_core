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

	local serialized_data = core.serialize(data)

	file:write(serialized_data)
	file:close()
end