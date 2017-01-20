-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file mgen_raster.lua
--! @brief component containing a probabilistic movement generator (uses mgen follow)
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-16
--
--! @defgroup mgen_probabv2 MGEN: a velocity based random movement generator
--! @brief A movement generator creating a velocity based random movement
--! @ingroup framework_int
--! @{ 
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class mgen_probab_v2
--! @brief a movement generator creating velocity based probabilistic movement
--!@}
mgen_probab_v2 = {}

--! @brief movement generator identifier
--! @memberof mgen_probab_v2
mgen_probab_v2.name = "probab_v2_mov_gen"

--! @brief movement patterns known to probabilistic movement gen
mgen_probab_v2.patterns = {}

--!@}

-------------------------------------------------------------------------------
-- name: register_pattern(pattern)
--
--! @brief initialize movement generator
--! @memberof mgen_probab_v2
--
--! @param pattern pattern to register
--! @return true/false
-------------------------------------------------------------------------------
function mgen_probab_v2.register_pattern(pattern)
		core.log("action","\tregistering pattern "..pattern.name)
		if mgen_probab_v2.patterns[pattern.name] == nil then
			mgen_probab_v2.patterns[pattern.name] = pattern
			return true
		else
			return false
		end
end

-------------------------------------------------------------------------------
-- name: spawnmarker(pattern)
--
--! @brief spawn a debug marker
--! @memberof mgen_probab_v2
--
--! @param pos position to spawn marker
--! @param type what type of marker
--! @param description
--! @param marker livetime
-------------------------------------------------------------------------------
function mgen_probab_v2.spawnmarker(pos, type, desc, lifetime)

	if true then
		return
	end
	
	local marker = spawning.spawn_and_check(type, pos, desc)
	
	if lifetime and marker then
		marker.lifetime = lifetime
	end
end

-------------------------------------------------------------------------------
-- name: register_pattern(get_suitable_target)
--
--! @brief initialize movement generator
--! @memberof mgen_probab_v2
--
--! @param entity mob entity
--! @param movement_state current known movement information
--! @return true/false
-------------------------------------------------------------------------------
function mgen_probab_v2.get_suitable_target(entity, movement_state )

	local suiteable_pos = nil
	local mgen_data = entity.dynamic_data.mgen_probab_v2
	local max_target_distance = mgen_data.movement_pattern.max_target_distance

	local x_offset = (math.random() * (2*max_target_distance)) - max_target_distance
	local z_offset = (math.random() * (2*max_target_distance)) - max_target_distance
	
	local new_pos = {
	                 x= movement_state.basepos.x + x_offset,
	                 z= movement_state.basepos.z + z_offset,
	                 y= movement_state.basepos.y
	                }
	                
	mgen_probab_v2.spawnmarker(new_pos, "mobf:mgen2_dbg_check_marker", "random_check", nil)

	-- check if position is suitable
	local new_pos_quality = environment.pos_quality(new_pos,entity)
	
	local good_quality_check_result = 
		environment.evaluate_state(new_pos_quality, LT_GOOD_POS)
	
	if good_quality_check_result then
		mgen_data.find_pos_tries_without_success = 0
		suiteable_pos = new_pos
		
	elseif mgen_data.find_pos_tries_without_success > 10 then
		local safe_quality_check_result = 
			environment.evaluate_state(new_pos_quality, LT_SAFE_EDGE_POS)
			
		if safe_quality_check_result then
			mgen_data.find_pos_tries_without_success = mgen_data.find_pos_tries_without_success - 5
			suiteable_pos = new_pos
		elseif mgen_data.find_pos_tries_without_success > 20 then
			local possible_quality_check_result = 
				environment.evaluate_state(new_pos_quality, LT_SAFE_POS)
				
			if possible_quality_check_result then
				mgen_data.find_pos_tries_without_success = mgen_data.find_pos_tries_without_success - 10
				suiteable_pos = new_pos
			end
		end
	end
	
	
	if suiteable_pos then
		dbg_mobf.mgen_probv2_lvl1("MOBF:         mgen_probabv2 found suitable position=" .. 
		             printpos(new_pos) .. " x_off=" .. x_offset .. " z_off=" .. z_offset)
		             
		mgen_probab_v2.spawnmarker(new_pos, "mobf:mgen2_dbg_suitable_marker", "random_suitable", 5)
	end
	
	return suiteable_pos
end


-------------------------------------------------------------------------------
-- name: cbf_moving(entity,now, basepos, current_state)
--
--! @brief callback doing things while mob is moving
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param pos base position of mob
--! @param current_state current short environment state
-------------------------------------------------------------------------------
function mgen_probab_v2.cbf_moving(entity, now, movement_state)

	-- check if target has been reached
	if entity.dynamic_data.mgen_probab_v2.eta > 0 and
		now >= entity.dynamic_data.mgen_probab_v2.eta then
		
		entity.object:setvelocity({x=0,y=0,z=0})
		entity.dynamic_data.mgen_probab_v2.eta =  -1
		entity.dynamic_data.mgen_probab_v2.moving = false
	
		if  math.random() < entity.dynamic_data.mgen_probab_v2.
		                      movement_pattern.stop_movement_chance then
			return
		end
		
		mgen_probab_v2.route_to_random_target(entity, now, movement_state)
		return
	end
	
	-- make the mob jump randomly
	if math.random() < entity.dynamic_data.mgen_probab_v2.
	                       movement_pattern.random_jump_chance then
		-- TODO make it jump
		return
	end

	-- we're moving shall we try to change our movement?
	if math.random() >= entity.dynamic_data.mgen_probab_v2.
	                       movement_pattern.change_started_movement_chance then
		return
	end
	
	-- we should try to change the movement
	mgen_probab_v2.route_to_random_target(entity, now, movement_state)
end

-------------------------------------------------------------------------------
-- name: get_jumpable_positions(entity, movement_state)
--
--! @brief get a list of positions the mob may jump to from current position
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param movement_state information already known about movement
-------------------------------------------------------------------------------
function mgen_probab_v2.get_jumpable_positions(entity, movement_state)
	local jumpable_positions = {}
	
	for xd=-1,1,1 do
	for zd=-1,1,1 do
		local upper_pos =
			{	
				x=movement_state.basepos.x + xd,
				z=movement_state.basepos.z + zd,
				y=movement_state.basepos.y+1
			}
		local lower_pos =
			{	
				x=movement_state.basepos.x + xd,
				z=movement_state.basepos.z + zd,
				y=movement_state.basepos.y+1
			}

		local upper_pos_quality = environment.pos_quality(upper_pos,entity)
		local lower_pos_quality = environment.pos_quality(lower_pos,entity)
		
		if environment.evaluate_state(upper_pos_quality, LT_GOOD_POS) then
			table.insert(jumpable_positions, upper_pos)
			mgen_probab_v2.spawnmarker(upper_pos, "mobf:mgen2_dbg_jumpable_marker", "jumpable_marker", nil)
		end
	
		if environment.evaluate_state(lower_pos_quality, LT_GOOD_POS) then
			table.insert(jumpable_positions, lower_pos)
			mgen_probab_v2.spawnmarker(lower_pos, "mobf:mgen2_dbg_jumpable_marker", "jumpable_marker", nil)
		end
	end
	end
	
	return jumpable_positions
end

-------------------------------------------------------------------------------
-- name: test_walkable(entity, movement_state, velocity, time)
--
--! @brief check if a mob can walk at given velocity for given time without 
--         getting into trouble
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param movement_state information already known about movement
--! @param velocity velocity to assume
--! @param time time to check
-------------------------------------------------------------------------------
function mgen_probab_v2.test_walkable(entity, movement_state, velocity, traveltime)

	--dbg_mobf.mgen_probv2_lvl1("MOBF:     mgen_probabv2 check path: " .. movement_state.basepos_quality:shortstring())
	local prediction_time = 0
	local last_good_predicted_pos = nil
	local last_good_predicted_time = 0
	
	local stepsize = 0.3
	
	while (mobf_calc_scalar_speed(velocity.x, velocity.z) * stepsize) > 0.1 do
		stepsize = stepsize/2
	end
	
	while prediction_time < traveltime do
		local predicted_pos = movement_generic.calc_new_pos(
		                          movement_state.basepos,
		                          {x=0,y=0,z=0 },
		                          prediction_time,
		                          velocity)
		
		local predicted_pos_quality = environment.pos_quality(predicted_pos,entity)
		
		local good_quality_check_result = 
				environment.evaluate_state(predicted_pos_quality, LT_GOOD_POS)
				
		if good_quality_check_result then
			last_good_predicted_pos = predicted_pos
			last_good_predicted_time = prediction_time
		end
	
		local quality_check_result = 
			environment.evaluate_state(predicted_pos_quality, LT_EDGE_POS_GOOD_CENTER)
	
		local compared_to_current = environment.compare_state(predicted_pos_quality, movement_state.basepos_quality)
		
		--dbg_mobf.mgen_probv2_lvl1("MOBF:     mgen_probabv2 check predicted: " ..
		--                          predicted_pos_quality:shortstring() .. 
		--                          " is_good: " .. dump(good_quality_check_result) ..
		--                          " is_ok: " .. dump(quality_check_result) ..
		--                          " time: " .. prediction_time ..
		--                          " compared_to_current: " .. compared_to_current)
	
		if not quality_check_result and
			( compared_to_current > 0) then
			dbg_mobf.mgen_probv2_lvl1("MOBF:     mgen_probabv2 predicted_pos= " .. printpos(predicted_pos) .. 
			" at time " .. prediction_time .. " not good enough: " .. predicted_pos_quality:shortstring())
			return false, last_good_predicted_time, last_good_predicted_pos
		end
		
		prediction_time = prediction_time + stepsize
	end
	return true, traveltime
end


-------------------------------------------------------------------------------
-- name: jump_to(entity, now, movement_state, target)
--
--! @brief make mob jump to the specified target
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param movement_state information already known about movement
--! @param target position to walk to
-------------------------------------------------------------------------------
function mgen_probab_v2.jump_to(entity, now, movement_state, target)

	-- find first suitable position at same level as target
	local start_pos_new_level = {
			x = movement_state.basepos.x,
			y = target.y,
			z = movement_state.basepos.z
			}

	local distance = mobf_calc_distance_2d(movement_state.basepos, target)
	local dir_radians = mobf_calc_yaw(target.x-movement_state.basepos.x,target.z-movement_state.basepos.z)
	local vector_velocity = mobf_calc_vector_components(dir_radians, entity.data.movement.max_speed)
	vector_velocity.y = 0
	
	local traveltime = mobf_calc_travel_time(distance, entity.data.movement.max_speed, 0)

	local jump_to_pos = nil
	local prediction_time = 0
	while prediction_time < traveltime do
		local predicted_pos = movement_generic.calc_new_pos(
		                          start_pos_new_level,
		                          {x=0,y=0,z=0 },
		                          prediction_time,
		                          vector_velocity)
		local predicted_pos_quality = environment.pos_quality(predicted_pos,entity)
	
		local quality_check_result = 
			environment.evaluate_state(predicted_pos_quality, LT_EDGE_POS)
			
		if quality_check_result then
			jump_to_pos = predicted_pos
			break
		end
		
		prediction_time = prediction_time + 0.05
	end
	
	if jump_to_pos then
		
		local distance = mobf_calc_distance_2d(jump_to_pos, target)
		local traveltime = mobf_calc_travel_time(distance, entity.data.movement.max_speed, 0)
		entity.object:move_to(jump_to_pos, true)
		entity.object:setvelocity(vector_velocity)
		entity.dynamic_data.mgen_probab_v2.eta = now + traveltime
		entity.dynamic_data.mgen_probab_v2.moving = true
	end
end

-------------------------------------------------------------------------------
-- name: route_to_random_target(entity, now, movement_state)
--
--! @brief find random target around and make mob move there
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param movement_state information already known about movement
-------------------------------------------------------------------------------
function mgen_probab_v2.route_to_random_target(entity, now, movement_state)

	local jumpable_positions = mgen_probab_v2.get_jumpable_positions(entity, movement_state)
	
	-- if there's any node we can jump up or down check probability to do
	if #jumpable_positions > 0 and
		math.random() < entity.dynamic_data.mgen_probab_v2.
		                  movement_pattern.climb_node_up_chance then
		
		mgen_probab_v2.jump_to(entity, now, movement_state, jumpable_positions[math.random(1, #jumpable_positions)])
		return
	end

	-- get a random position around to try to move to
	local new_target = mgen_probab_v2.get_suitable_target(entity, movement_state )
	
	
	if new_target then
		-- TODO check for direct way to target
		local distance = mobf_calc_distance_2d(movement_state.basepos, new_target)
		local direction = mobf_get_direction(movement_state.basepos, new_target)
		local dir_radians = mobf_calc_yaw(new_target.x-movement_state.basepos.x,new_target.z-movement_state.basepos.z)
		
		local scalar_velocity = math.random() 
		                 * (entity.data.movement.max_speed - entity.data.movement.min_speed)
		                 + entity.data.movement.min_speed

		local vector_velocity = mobf_calc_vector_components(dir_radians, scalar_velocity)
		vector_velocity.y = 0
		
		local travel_time = mobf_calc_travel_time(distance, scalar_velocity, 0)
		
		dbg_mobf.mgen_probv2_lvl1("MOBF:     mgen_probabv2 distance    =" .. distance .. " \n" ..
		                          "                        direction   =" .. dir_radians .."\n" ..
		                          "                        travel_time =" .. travel_time .. "s")
		
		
		local canwalkto, eta, last_predicted_pos = mgen_probab_v2.test_walkable(entity, movement_state, vector_velocity, travel_time)
		
		if canwalkto or eta > 2 then

			entity.dynamic_data.mgen_probab_v2.eta = now + eta
			entity.dynamic_data.mgen_probab_v2.moving = true

			entity.object:setvelocity(vector_velocity)

			local marker_entity = nil
			if canwalkto then
				mgen_probab_v2.spawnmarker(new_target, "mobf:mgen2_dbg_target_marker", "random_target", eta +1)
			else
				mgen_probab_v2.spawnmarker(new_target, "mobf:mgen2_dbg_part_target_marker", "random_target", eta +1)
			end
		
			-- TODO update animation
			return
		end
	end
	
	-- increase try counter
	entity.dynamic_data.mgen_probab_v2.find_pos_tries_without_success = 
		entity.dynamic_data.mgen_probab_v2.find_pos_tries_without_success + 1
end

-------------------------------------------------------------------------------
-- name: cbf_standing(entity, now, basepos, current_state)
--
--! @brief callback doing things while mob is moving
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param pos base position of mob
--! @param current_state current short environment state
-------------------------------------------------------------------------------
function mgen_probab_v2.cbf_standing(entity, now, movement_state)

	local random_val =  math.random()
	-- check if we need to start movement
	if random_val > entity.dynamic_data.mgen_probab_v2.
	                       movement_pattern.start_movement_chance then
		return
	end

	mgen_probab_v2.route_to_random_target(entity, now, movement_state)
end


-------------------------------------------------------------------------------
-- name: callback(entity,now, basepos, current_state)
--
--! @brief main callback for probabilistic movement gen v2
--! @memberof mgen_probab_v2
--
--! @param entity mob to generate movement for
--! @param now current time
--! @param pos base position of mob
--! @param current_state current short environment state
-------------------------------------------------------------------------------
function mgen_probab_v2.callback(entity,now, dtime, basepos, current_state)

	local movement_state = {}
	movement_state.short_state = current_state
	movement_state.basepos = basepos
	-- get quality of basepos
	movement_state.basepos_quality = environment.pos_quality(movement_state.basepos, entity)
	
	-- TODO fill movement state
	
	-- TODO check current mob position

	if entity.dynamic_data.mgen_probab_v2.moving then
		--dbg_mobf.mgen_probv2_lvl1("MOBF: mgen_probabv2 " .. entity.data.name .. " moving")
		mgen_probab_v2.cbf_moving(entity,now, movement_state)
	else
		--dbg_mobf.mgen_probv2_lvl1("MOBF: mgen_probabv2 " .. entity.data.name .. " not moving")
		mgen_probab_v2.cbf_standing(entity,now, movement_state)
	end
end


-------------------------------------------------------------------------------
-- name: initialize()
--
--! @brief initialize movement generator
--! @memberof mgen_probab_v2
--! @public
-------------------------------------------------------------------------------
function mgen_probab_v2.initialize(entity,now)

	dbg_mobf.mgen_probv2_lvl3("MOBF: mgen_probab_v2: initializing probabilistic movement generator v2")
	
		minetest.register_entity("mobf:mgen2_dbg_check_marker",
			 {
				physical        = false,
				collisionbox    = {-0.5,-0.5,-0.5,0.5,1.5,0.5 },
				visual          = "mesh",
				visual_size= {x=0.25,y=1.5,z=0.25},
				textures        = { "wool_white.png^[colorize:red:255" },
				mesh            = "mobf_path_marker.b3d",
				initial_sprite_basepos  = {x=0, y=0},
				lifetime        = 2,

				on_step = function(self,dtime)

					if self.creationtime == nil then
						self.creationtime = 0
					end

					self.creationtime = self.creationtime + dtime

					if self.creationtime > self.lifetime then
						self.object:remove()
					end
				end
			})
	
	minetest.register_entity("mobf:mgen2_dbg_suitable_marker",
			 {
				physical        = false,
				collisionbox    = {-0.5,-0.5,-0.5,0.5,1.5,0.5 },
				visual          = "mesh",
				visual_size= {x=0.5,y=1,z=0.5},
				textures        = { "wool_white.png^[colorize:yellow:255" },
				mesh            = "mobf_path_marker.b3d",
				initial_sprite_basepos  = {x=0, y=0},
				lifetime        = 10,

				on_step = function(self,dtime)

					if self.creationtime == nil then
						self.creationtime = 0
					end

					self.creationtime = self.creationtime + dtime

					if self.creationtime > self.lifetime then
						self.object:remove()
					end
				end
			})
			
	minetest.register_entity("mobf:mgen2_dbg_target_marker",
			 {
				physical        = false,
				collisionbox    = {-0.5,-0.5,-0.5,0.5,1.5,0.5 },
				visual          = "mesh",
				visual_size= {x=1,y=0.5,z=1},
				textures        = { "wool_white.png^[colorize:green:255" },
				mesh            = "mobf_path_marker.b3d",
				initial_sprite_basepos  = {x=0, y=0},
				lifetime        = 10,

				on_step = function(self,dtime)

					if self.creationtime == nil then
						self.creationtime = 0
					end

					self.creationtime = self.creationtime + dtime

					if self.creationtime > self.lifetime then
						self.object:remove()
					end
				end
			})
			
	minetest.register_entity("mobf:mgen2_dbg_part_target_marker",
			 {
				physical        = false,
				collisionbox    = {-0.5,-0.5,-0.5,0.5,1.5,0.5 },
				visual          = "mesh",
				visual_size= {x=1,y=0.5,z=1},
				textures        = { "wool_white.png^[colorize:cyan:255" },
				mesh            = "mobf_path_marker.b3d",
				initial_sprite_basepos  = {x=0, y=0},
				lifetime        = 10,

				on_step = function(self,dtime)

					if self.creationtime == nil then
						self.creationtime = 0
					end

					self.creationtime = self.creationtime + dtime

					if self.creationtime > self.lifetime then
						self.object:remove()
					end
				end
			})

	minetest.register_entity("mobf:mgen2_dbg_jumpable_marker",
			 {
				physical        = false,
				collisionbox    = {-0.5,-0.5,-0.5,0.5,1.5,0.5 },
				visual          = "mesh",
				visual_size= {x=0.25,y=0.6,z=0.25},
				textures        = { "wool_white.png^[colorize:black:255" },
				mesh            = "mobf_path_marker.b3d",
				initial_sprite_basepos  = {x=0, y=0},
				lifetime        = 10,

				on_step = function(self,dtime)

					if self.creationtime == nil then
						self.creationtime = 0
					end

					self.creationtime = self.creationtime + dtime

					if self.creationtime > self.lifetime then
						self.object:remove()
					end
				end
			})

end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof mgen_probab_v2
--! @public
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mgen_probab_v2.init_dynamic_data(entity, now)

	if mgen_probab_v2.patterns[entity.data.movement.pattern] == nil then
		dbg_mobf.mgen_probv2_lvl3("MOBF: mgen_probab_v2: movement pattern: " ..
			entity.data.movement.pattern .. " not defined\n" ..
			"Available:\n" .. dump(mgen_probab_v2.patterns))
		mobf_assert_backtrace(false)
	end

	

	local data = {
		movement_pattern = mgen_probab_v2.patterns[entity.data.movement.pattern],
		moving = false,
		eta = -1,
		target = nil,
		find_pos_tries_without_success = 0
	}

	entity.dynamic_data.mgen_probab_v2 = data
	entity.object:setvelocity({x=0,y=0,z=0})
end

-------------------------------------------------------------------------------
-- name: set_target(entity,target)
--
--! @brief set target for movgen
--! @memberof mgen_probab_v2
--! @public
--
--! @param entity mob to apply to
--! @param target to set
-------------------------------------------------------------------------------
function mgen_probab_v2.set_target(entity,target)

	-- TODO check if target can be reached direct else ignore
	
	return false
end

--register this movement generator
registerMovementGen(mgen_probab_v2.name,mgen_probab_v2)


-- register movement patterns
dofile (mobf_modpath .. "/mgen_probabv2/movement_patterns/stop_and_go.lua")