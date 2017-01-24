-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file legacy.lua
--! @brief check for functions which may be missing in older minetest versions
--         and provide own implementations
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

if vector.distance == nil then
	vector.distance = function(pos1,pos2)
		assert(pos1 ~= nil)
		assert(pos2 ~= nil)

		return math.sqrt( math.pow(pos1.x-pos2.x,2) +
				math.pow(pos1.y-pos2.y,2) +
				math.pow(pos1.z-pos2.z,2))
		end
end