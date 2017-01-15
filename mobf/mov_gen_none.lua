-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file mov_gen_none.lua
--! @brief a dummy movement gen
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf_assert_backtrace(not core.global_exists("mgen_none"))
--! @class mgen_none
--! @brief a movement generator doing nothing
mgen_none = {}

--!@}

--! @brief movement generator identifier
--! @memberof mgen_none
mgen_none.name = "none"

-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief main callback to do nothing
--! @memberof mgen_none
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param pos base position of mob
--! @param current_state current short environment state
-------------------------------------------------------------------------------
function mgen_none.callback(entity, now, dtime, pos, current_state)

	mobf_assert_backtrace(entity ~= nil)
	mobf_assert_backtrace(pos ~= nil)
	mobf_assert_backtrace(current_state ~= nil)
	
	local default_y_acceleration = environment.get_default_gravity(pos,
													entity.environment.media,
													entity.data.movement.canfly)
	mobf_physics.setacceleration(entity,{x=0,y=default_y_acceleration,z=0})
	
	
	local oldspeed = entity.object:getvelocity()
	local newspeed = { x=oldspeed.x, y=oldspeed.y, z=oldspeed.z}
	
	-- do not reset xz speed for floating or dropping mobs
	if not mobf_physics.is_floating(entity) or
		current_state == "drop" or 
		current_state == "in_air" or 
		current_state == "above_water" then
		newspeed.x = 0
		newspeed.z = 0
	end
	
	-- reset falling speed if mob doesn't honor gravity
	if default_y_acceleration == 0 then
		newspeed.y = 0
	end
	
	-- only update if necessary
	if oldspeed.x ~= newspeed.x or
		oldspeed.z ~= newspeed.z or
		oldspeed.y ~= newspeed.y then
	
		entity.object:setvelocity(newspeed)
	end
end

-------------------------------------------------------------------------------
-- name: initialize()
--
--! @brief initialize movement generator
--! @memberof mgen_none
--! @public
-------------------------------------------------------------------------------
function mgen_none.initialize(entity,now)
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof mgen_none
--! @public
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mgen_none.init_dynamic_data(entity,now)

    local data = {
            moving = false,
            }
    
    entity.dynamic_data.movement = data
end

-------------------------------------------------------------------------------
-- name: set_target(entity,target)
--
--! @brief set target for movgen
--! @memberof mgen_none
--! @public
--
--! @param entity mob to apply to
--! @param target to set
-------------------------------------------------------------------------------
function mgen_none.set_target(entity,target)
	return false
end

--register this movement generator
registerMovementGen(mgen_none.name,mgen_none)