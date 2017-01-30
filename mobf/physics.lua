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


local param2_to_liquid_level = function(param2)
	while param2 > 8 do
		param2 = param2 - 8
	end
	
	return param2
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] init_dynamic_data(entity,now)
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
-- @function [parent=#mobf_physics] getvelocity(entity)
--
--! @brief set acceleration for a specific entity object
--! @memberof mobf_physics
--
--! @param entity to set acceleration
--! @param acceleration
-------------------------------------------------------------------------------
function mobf_physics.getvelocity(entity)
	
	local velocity = entity.object:getvelocity()

	return velocity
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] setvelocity(entity,accel)
--
--! @brief set acceleration for a specific entity object
--! @memberof mobf_physics
--
--! @param entity to set acceleration
--! @param acceleration
-------------------------------------------------------------------------------
function mobf_physics.setvelocity(entity, velocity)

	entity.object:setvelocity(velocity)
	entity.dynamic_data.physics.last_velocity = velocity
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

	local pos = self.getbasepos(self)
	
	-- calc liquid acceleration
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


	-- apply gravity
	local gravity = environment.get_default_gravity(pos,
	                    self.environment.media,
	                    self.data.movement.canfly)
	local mob_acceleration = self.object:getacceleration()
	
	if mob_acceleration.y ~= gravity then
		mob_acceleration.y = gravity
		self.object:setacceleration(mob_acceleration)
	end
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] is_floating(entity)
--! @memberof mobf_physics
--
--! @brief provide information about mob floating
--! @memberof mobf_physics
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
-- @function [parent=#mobf_physics] get_flow_accel(entity)
--! @memberof mobf_physics
--
--! @brief update flow acceleration within a given movement state
--! @memberof mobf_physics
--
-------------------------------------------------------------------------------
function mobf_physics.get_flow_accel(pos, nodename)

	local liquid_level = param2_to_liquid_level(core.get_node(pos).param2)
	local postotest = pos
	
	local possible_directions = {}
	local equivalent_directions = {}
	local float_target = nil
	
	dbg_mobf.physics_lvl1("get_flow_accel: Current liquid_level=" .. liquid_level)
	for i,d in ipairs({-1, 1, -1, 1}) do
		if i < 3 then
			postotest = { x= pos.x+d, y=pos.y, z=pos.z }
		else
			postotest = { x= pos.x, y=pos.y, z=pos.z+d}
		end
		
		local node = core.get_node(postotest);
		
		dbg_mobf.physics_lvl1("get_flow_accel: Testing: " .. printpos(postotest) .. 
			" name=" .. node.name .. " param2=" .. node.param2 .. 
			" liquid_level=" .. param2_to_liquid_level(node.param2))
		
		if node.name == nodename then
		
			local actual_level = param2_to_liquid_level(node.param2)
		
			if actual_level < liquid_level then
				table.insert(possible_directions, postotest)
			elseif actual_level == liquid_level then
				table.insert(equivalent_directions, postotest)
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
			
			local flowdelta = param2_to_liquid_level(node_opposite.param2)
								- param2_to_liquid_level(node_target.param2)
			
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
	
	-- there's no real level difference make it flow towards one of the other 
	-- nodes with same level and hope this one does have a node with lower level
	-- next to it
	if float_target == nil then
	
		if #equivalent_directions > 1 then
			local maxdelta = -1
		
			for i=1,#equivalent_directions,1 do
				local opposite_pos = {y=pos.y}
				opposite_pos.x = pos.x + (equivalent_directions[i].x -pos.x) * -1
				opposite_pos.z = pos.z + (equivalent_directions[i].z -pos.z) * -1
		
				local node_target   = core.get_node(equivalent_directions[i]);
				local node_opposite = core.get_node(opposite_pos);
			
				local flowdelta = param2_to_liquid_level(node_opposite.param2)
									- param2_to_liquid_level(node_target.param2)
			
				if node_opposite.name == nodename then
					if flowdelta > maxdelta then
						maxdelta = flowdelta
						float_target = equivalent_directions[i]
					end
				elseif node_opposite.name == core.get_node(pos).liquid_alternative_source then
					float_target = equivalent_directions[i]
					maxdelta = 20
				else
					--corner case
					float_target = equivalent_directions[i]
				end
			end
		else
			float_target = equivalent_directions[1]
		end
	end
	
	local flowdir = { x=0, z=0 }
	
	dbg_mobf.physics_lvl1("get_flow_accel: Possible directions: " .. #possible_directions .. 
		" Equivalent direction: " .. #equivalent_directions)
	
	if float_target then
		flowdir.x = float_target.x - pos.x
		flowdir.z = float_target.z - pos.z
	else
		dbg_mobf.physics_lvl2("get_flow_accel: in flowing water but no possible direction found")
	end

	-- TODO use current velocity to calc resistance
	-- simple way don't apply accel above certain speed
	local liquid_accel_value = 0.75 + 0.2 * liquid_level
	
	return 
			{
				x = liquid_accel_value * flowdir.x,
				z = liquid_accel_value * flowdir.z
			}
end


-------------------------------------------------------------------------------
-- @function [parent=#mobf_physics] damage_handler(entity, now, basepos, state)
--
--! @brief do damage based uppon physics
--! @memberof mobf_physics
--
--! @param entity to update physics
--! @param now current timestamp
--! @param basepos base position of mob
--! @param state current position state
-------------------------------------------------------------------------------
function mobf_physics.damage_handler(entity, now, basepos, state)

	local drown_time = 5
	local collision_damage_threshold = 5

	--handle drowning
	if not entity.data.generic.no_drowning then
		if state == "in_water" then
			if entity.dynamic_data.physics.ts_last_drown_damage == nil then
				entity.dynamic_data.physics.ts_last_drown_damage = now
			end
		
			if entity.dynamic_data.physics.ts_last_drown_damage + drown_time < now then
		
				entity.object:set_hp(entity.object:get_hp() - 1)
				mobf_lifebar.set(entity.lifebar,entity.object:get_hp()/entity.hp_max)

				if entity.data.sound ~= nil then
					sound.play(basepos,entity.data.sound.drown);
				end
			
				entity.dynamic_data.movement.ts_last_drown_damage = now

				if entity.object:get_hp() <= 0 then
					mobf_lifebar.del(entity.lifebar)
					entity:do_drop(nil)
					spawning.remove(entity,"drowned")
					return false
				end
			end
		else
			entity.dynamic_data.physics.ts_last_drown_damage = now
		end
	end
	
	local current_velocity = entity.object:getvelocity()
	local speeddelta = 0
	
	-- handle damage resulting from high speed collisions
	if entity.data.generic.collision_damage then
	
		if not entity.dynamic_data.physics.last_velocity then
			entity.dynamic_data.physics.last_velocity = current_velocity
		end
	
		speeddelta = vector.distance(entity.dynamic_data.physics.last_velocity,current_velocity)
		entity.dynamic_data.physics.last_velocity = current_velocity
		
		dbg_mobf.physics_lvl1("speeddelta: " .. speeddelta .. 
			" state: " .. state .. " pos: " .. printpos(basepos))
	else
		if not entity.dynamic_data.physics.last_velocity then
			entity.dynamic_data.physics.last_velocity = current_velocity
		end
	
		speeddelta = math.abs(entity.dynamic_data.physics.last_velocity.y -current_velocity.y)
		entity.dynamic_data.physics.last_velocity = current_velocity
		
		dbg_mobf.physics_lvl1("speeddelta: " .. speeddelta .. 
			" state: " .. state .. " pos: " .. printpos(basepos))
	end
	
	if speeddelta > collision_damage_threshold then
		
		local damage = 0
		local current_health = entity.object:get_hp()
		if state ~= "in_water" then
			damage = speeddelta
		end
	
		if damage > current_health then
			entity.object:set_hp(0)
		else
			entity.object:set_hp(current_health - damage)
		end
	
	
		mobf_lifebar.set(entity.lifebar,entity.object:get_hp()/entity.hp_max)

		if entity.data.sound ~= nil then
			sound.play(basepos,entity.data.sound.hit);
		end

		if entity.object:get_hp() <= 0 then
			mobf_lifebar.del(entity.lifebar)
			entity:do_drop(nil)
			spawning.remove(entity,"hit the ground or wall")
			return false
		end
	end
	
	
	
	return true
end
