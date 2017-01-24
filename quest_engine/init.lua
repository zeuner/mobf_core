-------------------------------------------------------------------------------
-- quest_engine mod
--
-- License CC BY
--
--! @file init.lua
--! @brief main file for initializing the quest engine
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
core.log("action","MOD: quest_engine loading ...")

if core.global_exists("quest_engine") then
	print(debug.traceback("Current Callstack:\n"))
	assert("quest_engine is already registred to namespace!" == nil)
end

quest_engine = {}

local version = "0.0.0"
local modpath = core.get_modpath("quest_engine")

dofile (modpath .. "/dbg.lua")
dofile (modpath .. "/quest_engine.lua")

quest_engine.init()

core.log("action","MOD: quest_enine                version " .. version .. " loaded")