-------------------------------------------------------------------------------
-- quest_engine mod
--
-- License CC BY
--
--! @file dbg.lua
--! @brief debug code file
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

if true then
quest_engine.dbg_lvl1 = function(msg)
	core.log("verbose", msg)
end

quest_engine.dbg_lvl2 = function(msg)
	core.log("action", msg)
end

quest_engine.dbg_lvl3 = function(msg)
	core.log("error", msg)
end

else

quest_engine.dbg_lvl1 = function(msg) end
quest_engine.dbg_lvl2 = function(msg) end
quest_engine.dbg_lvl3 = function(msg) end

end