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


if vector.round == nil then
	vector.round = function(pos)
		if pos == nil then
			return pos
		end
	
		return { x=math.floor(pos.x + 0.5),
				y=math.floor(pos.y + 0.5),
				z=math.floor(pos.z + 0.5)
			}
	end
end

if vector.equals == nil then
	vector.equals = function(pos1,pos2)
		if pos1 == nil or
			pos2 == nil then
			return false
		end

		if pos1.x ~= pos2.x or
			pos1.y ~= pos2.y or
			pos1.z ~= pos2.z or
			pos1.x == nil or
			pos1.y == nil or
			pos1.z == nil or
			pos2.x == nil or
			pos2.y == nil or
			pos2.z == nil then
			return false
		end
	
		return true
	end
end
