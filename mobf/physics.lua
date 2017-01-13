-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file harvesting.lua
--! @brief component for all harvesting related mob features
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-13
--
--! @defgroup physics physics subcomponent
--! @brief Component handling mob physics
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf_assert_backtrace(not core.global_exists("mobf_physics"))
--! @class mobf_physics
--! @brief mobf_physics features
mobf_physics = {}

--!@}


-------------------------------------------------------------------------------
-- @function [parent=#harvesting] init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by harvesting
--! @memberof harvesting
--
--! @param entity mob to initialize harvest dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mobf_physics.init_dynamic_data(entity,now)
	local data =  {
		last_acceleration	= { x=0, z=0 },
	}
	entity.dynamic_data.physics = data
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] getacceleration(entity)
--
--! @brief set acceleration for a specific entity object
--! @memberof mobf_physics
--
--! @param entity to set acceleration
--! @param acceleration
-------------------------------------------------------------------------------
function mobf_physics.getacceleration(entity)
	
	local acceleration = entity.object:getacceleration()

	--TODO remove liquid part

	return acceleration
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] setacceleration(entity,accel)
--
--! @brief set acceleration for a specific entity object
--! @memberof mobf_physics
--
--! @param entity to set acceleration
--! @param acceleration
-------------------------------------------------------------------------------
function mobf_physics.setacceleration(entity, accel)
	
	entity.object:setacceleration(accel)

end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] update(self,dtime)
--
--! @brief do physics update on step
--! @memberof mobf_physics
--
--! @param entity to update physics
--! @param time since last call
-------------------------------------------------------------------------------
function mobf_physics.update(self, dtime)

	

	local pos = self.object:getpos()
	
	-- TODO calc liquid acceleration
	local nodename = minetest.get_node(pos).name
	
	
	if core.registered_nodes[nodename].liquidtype == "flowing" then
		local liquid_acceleration = mobf_physics.get_flow_accel(pos, nodename)
	
		if self.dynamic_data.physics.last_acceleration == nil or
			self.dynamic_data.physics.last_acceleration.x ~=
				liquid_acceleration.x or
			self.dynamic_data.physics.last_acceleration.z ~=
				liquid_acceleration.z then
				
				
				
			local updated_accel = self.object:getacceleration()
			
			if self.dynamic_data.physics.last_acceleration then
				updated_accel.x = updated_accel.x - self.dynamic_data.physics.last_acceleration.x
				updated_accel.z = updated_accel.z - self.dynamic_data.physics.last_acceleration.z
			end
			
			updated_accel.x = updated_accel.x + liquid_acceleration.x
			updated_accel.z = updated_accel.z + liquid_acceleration.z
			
			self.object:setacceleration(updated_accel)
			self.dynamic_data.physics.last_acceleration = liquid_acceleration
		end
	elseif mobf_physics.is_floating(self) then
		local updated_accel = self.object:getacceleration()
			
		updated_accel.x = updated_accel.x - self.dynamic_data.physics.last_acceleration.x
		updated_accel.z = updated_accel.z - self.dynamic_data.physics.last_acceleration.z
		
		self.object:setacceleration(updated_accel)
		self.dynamic_data.physics.last_acceleration = nil
	end
	
	-- TODO calc resistance

end

-------------------------------------------------------------------------------
-- name: get_flow_accel(entity)
--
--! @brief update flow acceleration within a given movement state
--! @memberof movement_gen
--
-------------------------------------------------------------------------------
function mobf_physics.is_floating(entity)

	if entity.dynamic_data.physics.last_acceleration ~= nil then
		return true
	else
		return false
	end
end


-------------------------------------------------------------------------------
-- name: get_flow_accel(entity)
--
--! @brief update flow acceleration within a given movement state
--! @memberof movement_gen
--
-------------------------------------------------------------------------------
function mobf_physics.get_flow_accel(pos, nodename)

	local param2 = core.get_node(pos).param2
	local postotest = pos
	
	for i,d in ipairs({-1, 1, -1, 1}) do
		if i < 3 then
			postotest = { x= pos.x+d, y=pos.y, z=pos.z }
		else
			postotest = { x= pos.x, y=pos.y, z=pos.z+d}
		end
		
		local node = core.get_node(postotest);
		
		if node.name == nodename then
			if node.param2 < param2 then
				break
			end
		end
		
		if node.name == core.registered_nodes[nodename].liquid_alternative_source then
			break
		end
		
		postotest = pos
	end
	
	local flowdir = { 
								x = postotest.x - pos.x, 
								z = postotest.z - pos.z
							}

	-- TODO use current velocity to calc resistance
	-- simple way don't apply accel above certain speed
	
	local liquid_accel_value = 2
	
	return 
			{
				x = liquid_accel_value * flowdir.x,
				z = liquid_accel_value * flowdir.z
			}
end
