-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file direction_control.lua
--! @brief functions for direction control in probabilistic movement gen
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @ingroup mgen_probab
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class direction_control
--! @brief functions for direction control in probabilistic movement gen
direction_control = {}
--!@}

-------------------------------------------------------------------------------
-- name: changeaccel(pos,entity,velocity)
--
--! @brief find a suitable new acceleration for mob
--! @memberof direction_control
--! @private
--
--! @param pos current position
--! @param entity mob to get acceleration for
--! @param current_velocity current velocity
--! @return {{ x/y/z accel} + jump flag really?
-------------------------------------------------------------------------------
function direction_control.changeaccel(pos,entity,current_velocity)

	local maxtries = 5
	local old_quality = environment.pos_quality(pos,entity)

	local new_accel =
		direction_control.get_random_acceleration(
			entity.data.movement.min_accel,
			entity.data.movement.max_accel,graphics.getyaw(entity),0)
	local pos_predicted =
		movement_generic.predict_next_block(pos,current_velocity,new_accel)
	local new_quality = environment.pos_quality(pos_predicted,entity)
	
	local accel_best_found_quality = new_accel
	local quality_best_found = new_quality
	local best_is_possible = false
	
	local accel_accepted = false
	
	dbg_mobf.pmovement_lvl1("MOBF: current quality: " ..
								old_quality:tostring())
	
	local best_quality =
		environment.evaluate_state( new_quality,
									env_lim(
									nil,
									MQ_IN_MEDIA,
									GQ_FULL,
									GQ_FULL,
									SQ_OK,
									SQ_OK))

	-- try to find a acceleration to best possible state
	for i = 1, maxtries, 1 do

		-- found best
		if best_quality then
			accel_accepted = true
			break
		end
		
		dbg_mobf.pmovement_lvl1("MOBF: predicted pos " .. printpos(pos_predicted)
			.. " isn't perfect " .. (maxtries - i) .. " tries left, state: "
			.. new_quality.tostring(new_quality))
		
		
		--accept little less perfect quality in rare cases too
		local probab = math.random()
		
		local fair_state = environment.evaluate_state(
									new_quality,
									env_lim(
										nil,
										MQ_IN_MEDIA,
										GQ_PARTIAL,
										GQ_FULL,
										SQ_POSSIBLE,
										SQ_OK))
										
		if probab < 0.3 and fair_state then
			accel_accepted = true
			break
		end
		
		local acceptable_state = environment.evaluate_state(
									new_quality,
									env_lim(
										nil,
										MQ_IN_MEDIA,
										GQ_PARTIAL,
										nil,
										nil,
										SQ_POSSIBLE))
										
		if probab < 0.1 and acceptable_state then
			accel_accepted = true
			break
		end
		
		
		-- if this is best state we found sofar then save it
		if environment.compare_state(quality_best_found,new_quality) > 0 then
			quality_best_found = new_quality
			accel_best_found_quality = new_accel
			best_is_possible = fair_state or acceptable_state
		end
		
		-- get new random accel
		new_accel =
			direction_control.get_random_acceleration(
				entity.data.movement.min_accel,
				entity.data.movement.max_accel,graphics.getyaw(entity),0)
				
		pos_predicted =
			movement_generic.predict_next_block(pos,current_velocity,new_accel)
		new_quality = environment.pos_quality(pos_predicted,entity)
	end
	
	
	if not accel_accepted then
		if best_is_possible then
			dbg_mobf.pmovement_lvl1("MOBF: didn't find a really good acceleration but at least an acceptable one")
			new_accel = accel_best_found_quality
		elseif environment.compare_state(quality_best_found,old_quality) <= 0 then
			dbg_mobf.pmovement_lvl1("MOBF: didn't find a really good acceleration but best found one ain't worse then current one")
			new_accel = accel_best_found_quality
		else
			dbg_mobf.pmovement_lvl1(
				"MOBF: Didn't find a suitable acceleration stopping movement: "
				.. entity.data.name .. printpos(pos))
				
			entity.object:setvelocity({x=0,y=0,z=0})
			entity.dynamic_data.movement.started = false
			
			--don't accelerate mob at all
			new_accel = {  x=0, y=0, z=0 }
		end
	end

	return new_accel

end

-------------------------------------------------------------------------------
-- name: get_random_acceleration(minaccel,maxaccel,current_yaw, minrotation)
--
--! @brief get a random x/z acceleration within a specified acceleration range
--! @memberof direction_control
--! @private
--
--! @param minaccel minimum acceleration to use
--! @param maxaccel maximum acceleration
--! @param current_yaw current orientation of mob
--! @param minrotation minimum rotation to perform
--! @return x/y/z acceleration
-------------------------------------------------------------------------------
function direction_control.get_random_acceleration(
	minaccel,maxaccel,current_yaw, minrotation)

	local direction = 1
	if math.random() < 0.5 then
		direction = -1
	end

	--calc random absolute value
	local rand_accel = (math.random() * (maxaccel - minaccel)) + minaccel

	local orientation_delta = mobf_gauss(math.pi/6,1/2)

	--calculate new acceleration
	local new_direction =
		current_yaw + ((minrotation + orientation_delta) * direction)

	local new_accel = mobf_calc_vector_components(new_direction,rand_accel)

	dbg_mobf.pmovement_lvl3(" new direction: " .. new_direction ..
							" old direction: " .. current_yaw ..
							" new accel: " .. printpos(new_accel) ..
							" orientation_delta: " .. orientation_delta)

	return new_accel
end


function direction_control.get_acceleration_to(entity, movement_state, targetpos, pos_requirement)

	local factor = 0.1
	local accel_found = false
	
	repeat
		movement_state.accel_to_set =
			movement_generic.get_accel_to(targetpos, entity, nil,
					entity.data.movement.max_accel*factor)
					
		local next_pos =
				movement_generic.predict_next_block(
						movement_state.basepos,
						movement_state.current_velocity,
						movement_state.accel_to_set)
						
		local next_quality = environment.pos_quality(
									next_pos,
									entity
									)
		
		if environment.evaluate_state(next_quality,
								pos_requirement) then
			accel_found = true
		end
					
		factor = factor +0.1
	until ( factor > 1 or accel_found)
	
	if accel_found then
		movement_state.changed = true
	end

	return accel_found
end

-------------------------------------------------------------------------------
-- name: get_pos_around(entity, movement_state)
--
--! @brief get a good position around
--! @memberof direction_control
--! @private
--
--! @param entity
--! @param movement_state
--! @return position or nil
-------------------------------------------------------------------------------
function direction_control.get_pos_around(entity, movement_state)

	local new_pos =
		environment.get_pos_same_level(movement_state.basepos,1,entity,
				function(quality)
					return environment.evaluate_state(quality,
													LT_SAFE_EDGE_POS)
				end
				)

	if new_pos == nil then
		dbg_mobf.pmovement_lvl2("MOBF: mob " .. entity.data.name ..
			" trying edge pos")
			
		new_pos = environment.get_pos_same_level(movement_state.basepos,1,entity,
				function(quality)
					return environment.evaluate_state(quality,
													LT_EDGE_POS)
				end
				)
	end

	if new_pos == nil then
		dbg_mobf.pmovement_lvl2("MOBF: mob " .. entity.data.name ..
			" trying relaxed surface")
			
		new_pos = environment.get_pos_same_level(movement_state.basepos,1,entity,
				function(quality)
					return environment.evaluate_state(quality,
													LT_EDGE_POS_GOOD_CENTER)
				end
				)
	end

	if new_pos == nil then
		dbg_mobf.pmovement_lvl2("MOBF: mob " .. entity.data.name ..
			" trying even more relaxed surface")
			
		new_pos = environment.get_pos_same_level(movement_state.basepos,1,entity,
				function(quality)
					return environment.evaluate_state(quality,
													LT_EDGE_POS_POSSIBLE_CENTER)
				end
				)
	end

	return new_pos
end


-------------------------------------------------------------------------------
-- name: get_random_acceleration(entity, predicted_pos, 
--	predicted_quality, movement_state)
--
--! @brief handle drop state
--! @memberof direction_control
--! @private
--
--! @param entity
--! @param predicted_pos
--! @param predicted_quality
--! @param movement_state
--! @return true/false
-------------------------------------------------------------------------------
function direction_control.handle_drop_pending(entity, predicted_pos, 
	predicted_quality, movement_state, mob_is_safe)

	local drop_pending =
			(predicted_quality.geometry_quality <= GQ_PARTIAL and
			 predicted_quality.center_geometry_quality <= GQ_NONE) or
			 predicted_quality.surface_quality_min <= SQ_WATER
			 
	
	if drop_pending then
		dbg_mobf.pmovement_lvl2(
				"MOBF: mob " .. entity.data.name
				.. " is going to walk on water or drop")
		entity.dynamic_data.movement.drop_was_pending = true
		
		-- try to find a position around where mob would be safe
		
		local new_pos = entity.dynamic_data.movement.last_drop_was_pending_safe_pos
		local last_distance = entity.dynamic_data.movement.last_drop_was_pending_safe_pos_distance
		
		if new_pos ~= nil then
			local new_distance = mobf_calc_distance(predicted_pos, new_pos)
			
			if new_distance < last_distance then
				-- still on our way to safe position don't do anything
				entity.dynamic_data.movement.last_drop_was_pending_safe_pos_distance = new_distance
				return
			end
			
			-- we're to far away from our target find a new one
			if new_distance > 1 then
				new_pos = nil
			end
		end
				
		entity.dynamic_data.movement.last_drop_was_pending_safe_pos = nil
		entity.dynamic_data.movement.last_drop_was_pending_safe_pos_distance = 9999
		
		new_pos = direction_control.get_pos_around(entity, movement_state)
		
		
		-- we found a position now try to get an acceleration to it
		if new_pos ~= nil then
		
			dbg_mobf.pmovement_lvl2(
					"MOBF: trying to redirect to safe position .. " .. printpos(new_pos))
					
			
			if not direction_control.get_acceleration_to(entity, movement_state,
				new_pos, LT_EDGE_POS_POSSIBLE_CENTER) then
			
				-- try to find an accel which will result in some quality as good as current
				if not direction_control.get_acceleration_to(entity, movement_state,
					new_pos, { old_state=movement_state.current_quality }) then
					movement_state.force_change = true
					return false
				end
			end
			
			-- we did update movement_state using a valid new acceleration
			entity.dynamic_data.movement.last_drop_was_pending_safe_pos = new_pos
			entity.dynamic_data.movement.last_drop_was_pending_safe_pos_distance = 
				mobf_calc_distance(predicted_pos, new_pos)
			return true
		end
		
		--no suitable pos found, if mob is safe atm just stop it
		if mob_is_safe then
			if movement_state.current_quality == GQ_FULL then
				local targetpos = {x= movement_state.basepos.x,
						y=movement_state.basepos.y,
						z=movement_state.basepos.z}
						
				targetpos.x = targetpos.x - movement_state.current_velocity.x
				targetpos.z = targetpos.z - movement_state.current_velocity.z
				
				movement_state.accel_to_set =
					movement_generic.get_accel_to(targetpos, entity, nil,
							entity.data.movement.min_accel)
				dbg_mobf.pmovement_lvl2("MOBF: good pos, slowing down")
				movement_state.changed = true
				return true
			else --stop immediatlely
				entity.object:setvelocity({x=0,y=0,z=0})
				movement_state.accel_to_set = {x=0,y=nil,z=0}
				dbg_mobf.pmovement_lvl2("MOBF: stopping at safe pos")
				movement_state.changed = true
				return true
			end
		end

		-- bad case we don't know how to save this mob, let's try our chances
		dbg_mobf.pmovement_lvl2("MOBF: mob " .. entity.data.name ..
			" didn't find a way to fix drop trying random")
			
		--make mgen change direction randomly
		movement_state.force_change = true
		return true
	else
		entity.dynamic_data.movement.drop_was_pending = false
		entity.dynamic_data.movement.last_drop_was_pending_safe_pos = nil
		return true
	end
end


-------------------------------------------------------------------------------
-- name: precheck_movement(entity,movement_state,pos_predicted,pos_predicted_quality)
--
--! @brief check if x/z movement results in invalid position and change
--         movement if required
--! @memberof direction_control
--
--! @param entity mob to generate movement
--! @param movement_state current state of movement
--! @param pos_predicted position mob will be next
--! @param pos_predicted_quality quality of predicted position
--! @return movement_state is changed!
-------------------------------------------------------------------------------
function direction_control.precheck_movement(
	entity,movement_state,pos_predicted,pos_predicted_quality)

	if movement_state.changed then
		--someone already changed something
		return
	end

	local prefered_quality =
		environment.evaluate_state(pos_predicted_quality, LT_GOOD_POS)

	-- ok predicted pos isn't as good as we'd wanted it to be let's find out why
	if not prefered_quality then

		local mob_is_safe =
			environment.evaluate_state(pos_predicted_quality, LT_SAFE_POS)

		if movement_state.current_quality == nil then
			movement_state.current_quality = environment.pos_quality(
												movement_state.basepos,
												entity
												)
		end

		if environment.compare_state(
			movement_state.current_quality,
			pos_predicted_quality) > 0
			and
			pos_predicted_quality.media_quality == MQ_IN_MEDIA then
			--movement state is better than old one so we're fine
			return
		end

		local walking_at_edge =
			environment.evaluate_state(pos_predicted_quality, LT_SAFE_EDGE_POS)

		if walking_at_edge then
			--mob center still on ground but at worst walking at edge, do nothing
			return
		end
		
		if (pos_predicted_quality.geometry_quality == GQ_NONE) then
			dbg_mobf.pmovement_lvl2("MOBF: mob " .. entity.data.name .. " is dropping")
			return
		end
		
		
		if not direction_control.handle_drop_pending(entity, pos_predicted, 
			pos_predicted_quality, movement_state, mob_is_safe) then
			return
		end

		--check if mob is going to be somewhere where it can't be
		if pos_predicted_quality.media_quality ~= MQ_IN_MEDIA then
			dbg_mobf.pmovement_lvl2("MOBF: collision pending "
				.. printpos(movement_state.basepos) .. "-->"
				.. printpos(pos_predicted))

			--try to find a better position at same level
			local new_pos =
				environment.get_suitable_pos_same_level(movement_state.basepos,1,entity)

			if new_pos == nil then
				new_pos =
					environment.get_suitable_pos_same_level(
						movement_state.basepos,1,entity,true)
			end

			--there is at least one direction to go
			if new_pos ~= nil then
				dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name
					.. " redirecting to:" .. printpos(new_pos))
				local new_predicted_state = nil
				local new_predicted_pos = nil
				for i=1,5,1 do
					movement_state.accel_to_set =
						movement_generic.get_accel_to(new_pos,entity)
					--TODO check if acceleration is enough
					new_predicted_pos =
						movement_generic.predict_enter_next_block( entity,
												movement_state.basepos,
												movement_state.current_velocity,
												movement_state.accel_to_set)
					new_predicted_state = environment.pos_quality(
												new_predicted_pos,
												entity
												)
					if new_predicted_state.media_quality == MQ_IN_MEDIA then
						break
					end
				end
				if new_predicted_state.media_quality ~= MQ_IN_MEDIA then
					movement_state.accel_to_set = movement_state.current_acceleration

					dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name
						.. " acceleration not enough to avoid collision try to jump")
					if math.random() <
						( entity.dynamic_data.movement.mpattern.jump_up *
							PER_SECOND_CORRECTION_FACTOR) then
						local upper_pos = {
										x= pos_predicted.x,
										y= pos_predicted.y +1,
										z= pos_predicted.z
										}

						local upper_quality = environment.pos_quality(
													upper_pos,
													entity
													)

						if environment.evaluate_state(	upper_quality,LT_EDGE_POS) then

							entity.object:setvelocity(
									{x=movement_state.current_velocity.x,
									y=5,
									z=movement_state.current_velocity.z})
						end
					end
				end
				movement_state.changed = true
				return
			end

			--try to find a better position above
			new_pos = environment.get_suitable_pos_same_level({ x=movement_state.basepos.x,
														 y=movement_state.basepos.y+1,
														 z=movement_state.basepos.z},
														1,entity)

			if new_pos == nil then
				new_pos = environment.get_suitable_pos_same_level({ x=movement_state.basepos.x,
											 y=movement_state.basepos.y+1,
											 z=movement_state.basepos.z},
											1,entity)
			end

			if new_pos ~= nil then
				dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name
					.. " seems to be locked in, jumping to:" .. printpos(new_pos))

				entity.object:setvelocity({x=0,
											y=5.5,
											z=0})
				movement_state.accel_to_set = movement_generic.get_accel_to(new_pos,entity)
				movement_state.changed = true
				return
			end

			dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name
					.. " unable to fix collision try random")
			--a collision is going to happen force change of direction
			movement_state.force_change = true
			return
		end
		
		-- don't do follow up checks if there alreas is a fix pending
		if movement_state.changed then
			return
		end

		local suboptimal_surface =
			environment.evaluate_state(	pos_predicted_quality,
					{	old_state=nil,
						min_media=MQ_IN_MEDIA,
						min_geom=GQ_PARTIAL,
						min_geom_center=nil,
						min_min_surface=SQ_WRONG,
						min_max_surface=SQ_POSSIBLE,
						min_center_surface=nil	})

		if suboptimal_surface then
			dbg_mobf.pmovement_lvl2(
				"MOBF: suboptimal positiond detected trying to find better pos")
			--try to find a better position at same level
			local new_pos =
				environment.get_suitable_pos_same_level(
					movement_state.basepos,1,entity)

			if new_pos ~= nil then
				dbg_mobf.pmovement_lvl2(
					"MOBF: redirecting to better position .. " .. printpos(new_pos))
				movement_state.accel_to_set = movement_generic.get_accel_to(new_pos,entity)
				movement_state.changed = true
				return
			else
				-- pos isn't critical don't do anything
				return
			end
		end

		local geom_ok =
			environment.evaluate_state(	pos_predicted_quality,
					{	old_state=nil,
						min_media=MQ_IN_MEDIA,
						min_geom=GQ_PARTIAL,
						min_geom_center=nil,
						min_min_surface=nil,
						min_max_surface=nil,
						min_center_surface=nil	})
		if geom_ok and
			pos_predicted_quality.surface_quality_max == SQ_WRONG then
			dbg_mobf.pmovement_lvl2(
				"MOBF: wrong surface detected trying to find better pos")
			local new_pos =
				environment.get_suitable_pos_same_level(
					movement_state.basepos,1,entity)

			if new_pos == nil then
				new_pos =
					environment.get_suitable_pos_same_level(
						movement_state.basepos,2,entity)
			end

			if new_pos ~= nil then
				dbg_mobf.pmovement_lvl2(
					"MOBF: redirecting to better position .. " .. printpos(new_pos))
				movement_state.accel_to_set =
					movement_generic.get_accel_to(new_pos,entity)
				movement_state.changed = true
				return
			else
				--try generic
				movement_state.force_change = true
				return
			end
		end

		dbg_mobf.pmovement_lvl2("MOBF: Unhandled suboptimal state:"
			.. pos_predicted_quality.tostring(pos_predicted_quality))
		movement_state.force_change = true
	end
end

-------------------------------------------------------------------------------
-- name: random_movement_handler(entity,movement_state)
--
--! @brief generate a random y-movement
--! @memberof direction_control
--
--! @param entity mob to apply random jump
--! @param movement_state current movement state
--! @return movement_state is modified!
-------------------------------------------------------------------------------
function direction_control.random_movement_handler(entity,movement_state)
	dbg_mobf.pmovement_lvl3("MOBF: >>> random movement handler called")
	
	local rand_value = math.random()
	local max_value =
		entity.dynamic_data.movement.mpattern.random_acceleration_change
			* PER_SECOND_CORRECTION_FACTOR
	if movement_state.changed == false and
		(rand_value < max_value or
		movement_state.force_change) then

		movement_state.accel_to_set = direction_control.changeaccel(movement_state.basepos,
							entity,movement_state.current_velocity)
		if movement_state.accel_to_set ~= nil then
			--retain current y acceleration
			movement_state.accel_to_set.y = movement_state.current_acceleration.y
			movement_state.changed = true
		end
		dbg_mobf.pmovement_lvl1("MOBF:<<< randomly changing speed from "..
			printpos(movement_state.current_acceleration).." to "..
			printpos(movement_state.accel_to_set))
	else
		dbg_mobf.pmovement_lvl3("MOBF:<<<" .. entity.data.name ..
			" not changing speed random: " .. rand_value .." >= " .. max_value ..
			" or already changed: " .. dump(movement_state.changed))
	end
end