-------------------------------------------------------------------------------
-- Utils package
--
-- License CC BY
--
--! @file init.lua
--! @brief main file for initializing the utils package
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

if core.global_exists("utils") then
	print(debug.traceback("Current Callstack:\n"))
	assert("utils is already registred to namespace!" == nil)
end
--! @class utils
--! @brief utility functions helfull for creating minetest mods

utils = {}
--!@}

local modpath = core.get_modpath("utils")

dofile (modpath .. "/data_storage.lua")


-------------------------------------------------------------------------------
-- name: utils.contains(cur_table,element)
--
--! @brief check if element is in table
--
--! @param cur_table table to look in
--! @param element element to look for
--! @return true/false
-------------------------------------------------------------------------------
utils.contains = function (cur_table, element)

    if type(cur_table) ~= "table" then
        return false
    end

    if cur_table == nil then
        return false
    end

    for i,v in ipairs(cur_table) do
        if v == element then
            return true
        end
    end

    return false
end