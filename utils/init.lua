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