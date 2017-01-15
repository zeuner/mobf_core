-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file phyics.lua
--! @brief component for all physics related mob features
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

	if mobf_physics.is_floating(entity) then
	
		acceleration.x = acceleration.x - entity.dynamic_data.physics.last_acceleration.x
		acceleration.z = acceleration.z - entity.dynamic_data.physics.last_acceleration.z
	
	end
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

	if mobf_physics.is_floating(entity) then
		accel.x = accel.x + entity.dynamic_data.physics.last_acceleration.x
		accel.z = accel.z + entity.dynamic_data.physics.last_acceleration.z
	end

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

	--print("Liquid update called")

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
	
	local possible_directions = {}
	local float_target = nil
	
	for i,d in ipairs({-1, 1, -1, 1}) do
		if i < 3 then
			postotest = { x= pos.x+d, y=pos.y, z=pos.z }
		else
			postotest = { x= pos.x, y=pos.y, z=pos.z+d}
		end
		
		local node = core.get_node(postotest);
		
		if node.name == nodename then
			if node.param2 < param2 then
				table.insert(possible_directions, postotest)
			end
		end
		
		postotest = pos
	end
	
	if #possible_directions > 1 then
		local maxdelta = -1
		
		for i=1,#possible_directions,1 do
			local opposite_pos = {y=pos.y}
			opposite_pos.x = pos.x + (possible_directions[i].x -pos.x) * -1
			opposite_pos.z = pos.z + (possible_directions[i].z -pos.z) * -1
		
			local node_target   = core.get_node(possible_directions[i]);
			local node_opposite = core.get_node(opposite_pos);
			local flowdelta = node_opposite.param2 - node_target.param2
			
			if node_opposite.name == nodename then
				if flowdelta > maxdelta then
				maxdelta = flowdelta
				float_target = possible_directions[i]
				end
			elseif node_opposite.name == core.get_node(pos).liquid_alternative_source then
				float_target = possible_directions[i]
				maxdelta = 20
			else
				--corner case
				float_target = possible_directions[i]
			end
		end
	
	else
		float_target = possible_directions[1]
	end
	
	
	
	local flowdir = { x=0, z=0 }
	
	
	if #possible_directions > 0 then
		flowdir.x = float_target.x - pos.x
		flowdir.z = float_target.z - pos.z
	end
	
	print("param2=" .. param2)

	-- TODO use current velocity to calc resistance
	-- simple way don't apply accel above certain speed
	
	local liquid_accel_value = 0.75 + 0.2 * param2
	
	return 
			{
				x = liquid_accel_value * flowdir.x,
				z = liquid_accel_value * flowdir.z
			}
end
