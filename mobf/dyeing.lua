-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file dyeing.lua
--! @brief component for dyeing mobs
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-14
--
--! @defgroup dyeing helper functions for dyeing mobs
--! @brief Component handling mob dyeing
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf_assert_backtrace(not core.global_exists("mobf_dyeing"))
--! @class mobf_dyeing
--! @brief mobf_dyeing features
mobf_dyeing = {}
mobf_dyeing.mode = "multiply"

--!@}

------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] config_check(entity)
--
--! @brief check if mob supports dyeing
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to color
-------------------------------------------------------------------------------
function mobf_dyeing.config_check(entity)

	if entity.data.harvest and
		entity.data.harvest.dyeable then
		return true
	end
	
	return false
end


------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] config_check(entity)
--
--! @brief check if mob supports dyeing
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to color
-------------------------------------------------------------------------------
function mobf_dyeing.get_harvest_result(entity)

	local result = nil
	
	if entity.dynamic_data.dyeing == nil then
		entity.dynamic_data.dyeing = {}
	end

	if entity.data.harvest.dye_result_base then
		local color = entity.dynamic_data.dyeing.color
		
		if entity.data.harvest.dye_removed and not
			entity.data.harvest.transforms_to then
			entity.dynamic_data.dyeing.color = nil
			entity.object:settexturemod("");
		end
		
		if color then
			result = entity.data.harvest.dye_result_base .. color .. " 1"
		end
	end
	
	if result == nil and type(entity.data.harvest.result) == "function" then
		result = entity.data.harvest.result()
	end
	
	if result == nil then
		result = entity.data.harvest.result .. " 1"
	end
	
	return result
end

------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] on_activate(entity)
--
--! @brief initialize dyeing config
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to be colored
--! @param remanent remanent data read on activate
-------------------------------------------------------------------------------
function mobf_dyeing.on_activate(entity, remanent)

	if entity.data.harvest and 
		entity.data.harvest.dyeable then
		
		if remanent.dyeing then
			entity.dynamic_data.dyeing = remanent.dyeing
		else
			entity.dynamic_data.dyeing = {}
		end
	
	
		if entity.dynamic_data.dyeing and
			entity.dynamic_data.dyeing.color then
	
		local modifier = "^[" .. mobf_dyeing.mode .. ":" .. 
			entity.dynamic_data.dyeing.color .. ":200"
	
		modifier = string.gsub(modifier, "_", "")
	
		-- apply texture modifier
		entity.object:settexturemod(modifier)
		end
	end
end

------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] on_rightclick(entity)
--
--! @brief do the mob coloring
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to color
--! @param clicker the one trying to color it
--! @param tool the tool used on click
-------------------------------------------------------------------------------
function mobf_dyeing.dye_caption(entity, clicker, tool)

	--todo get name from tool
	local dyename = tool:get_name()
	
	if string.sub(tool:get_name(),1,3) == "dye" then
	
		return "Apply " .. minetest.registered_items[dyename].description
	else
		return "Not holding dye"
	end
end

------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] on_rightclick(entity)
--
--! @brief do the mob coloring
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to color
--! @param clicker the one trying to color it
--! @param tool the tool used on click
-------------------------------------------------------------------------------
function mobf_dyeing.on_rightclick(entity, clicker, tool)

	-- hitting with dye colores sheep
	if string.sub(tool:get_name(),1,3) == "dye" then
	
		local dyename = string.sub(tool:get_name(),5)
		
		if not entity.dynamic_data.dyeing then
			entity.dynamic_data.dyeing = {}
		end
		
		local modifier = "^[" .. mobf_dyeing.mode .. ":" .. dyename .. ":200"
		modifier = string.gsub(modifier, "_", "")
		
		entity.dynamic_data.dyeing.color = dyename
		entity.object:settexturemod(modifier);
		
		
		if not mobf_rtd.creative_mode then
			clicker:get_inventory():remove_item("main",tool:get_name().." 1")
		end
		return true
	end
	
	return false
end

------------------------------------------------------------------------------
-- @function [parent=#mobf_dyeing] fix_texturemodifier(entity)
--
--! @brief fix texture modify which may be lost e.g. due to punching
--! @class mobf_dyeing
--! @public
--
--! @param entity entity to color
-------------------------------------------------------------------------------
function mobf_dyeing.fix_texturemodifier(entity)
	if entity.data.harvest and 
		entity.data.harvest.dyeable and
		entity.dynamic_data.dyeing.color then
		
		local modifier = "^[colorize:" .. 
			entity.dynamic_data.dyeing.color .. ":200"
		modifier = string.gsub(modifier, "_", "")
		
		entity.object:settexturemod("")
		entity.object:settexturemod(modifier)
	end
end
