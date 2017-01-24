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

	local maxtries = 21
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
	
--	dbg_mobf.pmovement_lvl3("MOBF: current quality: " ..
--								old_quality:tostring())
	
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
		
--		dbg_mobf.pmovement_lvl3("MOBF: predicted pos " .. printpos(pos_predicted)
--			.. " isn't perfect " .. (maxtries - i) .. " tries left, state: "
--			.. new_quality.tostring(new_quality))
		
		
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
		
		
		local minrotation = math.floor(i/5) * math.pi/4
		
		-- get new random accel
		new_accel =
			direction_control.get_random_acceleration(
				entity.data.movement.min_accel,
				entity.data.movement.max_accel,graphics.getyaw(entity),minrotation)
				
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
				"MOBF:\t" .. T_RED .. "Didn't find a suitable acceleration stopping movement: "
				.. entity.data.name .. printpos(pos) .. C_RESET)
				
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

	dbg_mobf.pmovement_lvl3("MOBF: get_random_acceleration new direction: " .. new_direction ..
							" old direction: " .. current_yaw ..
							" new accel: " .. printpos(new_accel) ..
							" orientation_delta: " .. orientation_delta)

	return new_accel
end


function direction_control.get_acceleration_to(entity, movement_state, targetpos, pos_requirement)

	local factor = 1.5
	local accel_found = false
	
	local tested_accel = 
			movement_generic.get_accel_to(targetpos, entity, nil,
					entity.data.movement.max_accel*factor)
					
	local next_pos =
				movement_generic.predict_next_block(
						movement_state.basepos,
						movement_state.current_velocity,
						tested_accel)
						
	local next_quality = environment.pos_quality(
								next_pos,
								entity
								)
	
	-- reduce factor for as long as possible
	while environment.evaluate_state(next_quality, pos_requirement) and
		factor > 0 do
		
		movement_state.accel_to_set = tested_accel
		movement_state.changed = true
		accel_found = true
		
		factor = factor -0.2
		
		tested_accel = 
			movement_generic.get_accel_to(targetpos, entity, nil,
					entity.data.movement.max_accel*factor)
	
		next_pos =
				movement_generic.predict_next_block(
						movement_state.basepos,
						movement_state.current_velocity,
						tested_accel)
						
		next_quality = environment.pos_quality(
								next_pos,
								entity
								)
	end

	return accel_found, tested_accel, next_quality
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
-- name: redirect_safe_pos_callback(entity, movement_state, predicted_pos, slow_down)
--
--! @brief handle pending redirection
--! @memberof direction_control
--! @private
--
--! @param entity mob to check
--! @param movement_state current movement state
--! @param predicted_pos position the mob will be soon
--! @param slow_dow slow down mob in case of error
--! @return handling complete, position redirecting atm
-------------------------------------------------------------------------------
function direction_control.redirect_safe_pos_callback(entity, movement_state, predicted_pos, slow_down)

	if entity.dynamic_data.movement.redirect_safe_pos == nil then
		dbg_mobf.pmovement_lvl2(
			"MOBF:\t<<not redirecting")
		return false, nil
	end
	
	local safe_pos = entity.dynamic_data.movement.redirect_safe_pos
	local last_distance = entity.dynamic_data.movement.redirect_safe_pos_distance

	if safe_pos ~= nil then
		dbg_mobf.pmovement_lvl2(
			"MOBF:\talready redirecting " .. printpos(entity:getbasepos()) .. "-->" .. printpos(safe_pos))
		local new_distance = vector.distance(entity:getbasepos(), safe_pos)
		local predicted_distance = vector.distance(predicted_pos, safe_pos)
		
		if new_distance > last_distance then
			safe_pos = nil
		else
			entity.dynamic_data.movement.redirect_safe_pos_distance = new_distance
		end
		
		if predicted_distance < new_distance then
			-- still on our way to safe position don't do anything
			dbg_mobf.pmovement_lvl2(
				"MOBF:\t" .. T_GREEN .. "still valid not doing special handling".. C_RESET)
			return true
		end
		
		dbg_mobf.pmovement_lvl2(
				"MOBF:\t" .. T_YELLOW .. "moved towards right direction but current velocity/acceleration is wrong".. C_RESET)
		
		if slow_down then
			movement_generic.slow_down_xz(entity, 0.5)
		end
		
		-- we're to far away from our target find a new one
		if new_distance > 1 then
			return false
		else 
			return false, safe_pos
		end
	end
	
	entity.dynamic_data.movement.redirect_safe_pos = nil
	entity.dynamic_data.movement.redirect_safe_pos_distance = 9999
	return false, nil

end

-------------------------------------------------------------------------------
-- name: redirect_safe_pos(entity, pos)
--
--! @brief (re-)set the redirection position
--! @memberof direction_control
--! @private
--
--! @param entity mob to check
--! @param pos position to save, nil to reset pos
-------------------------------------------------------------------------------
function direction_control.redirect_safe_pos(entity, pos)

	if pos ~= nil then
		dbg_mobf.pmovement_lvl2(
				"MOBF:\tstoring redirection pos " .. printpos(pos))
		entity.dynamic_data.movement.redirect_safe_pos = pos
		entity.dynamic_data.movement.redirect_safe_pos_distance = 
				vector.distance(entity:getbasepos(), pos)
	else
		dbg_mobf.pmovement_lvl2(
				"MOBF:\tresetting redirection pos")
		entity.dynamic_data.movement.redirect_safe_pos = nil
		entity.dynamic_data.movement.redirect_safe_pos_distance = 9999
	end
end

function direction_control.best_chance_redirect(entity, movement_state, new_pos, limit)

	if new_pos == nil then
		new_pos = direction_control.get_pos_around(entity, movement_state)
	end
	
	
	-- we found a position now try to get an acceleration to it
	if new_pos ~= nil then
	
		dbg_mobf.pmovement_lvl2(
				"MOBF:\t-->trying to redirect to safe position .. " .. printpos(new_pos))
				
		
		local found_good, best_tried_accel, best_quality =
			direction_control.get_acceleration_to(entity, movement_state,
				new_pos, limit)
		
		if not found_good then
		
			-- check if best try was at least as good as now
			if environment.evaluate_state(best_quality,
				{ old_state=movement_state.current_quality }) then
				dbg_mobf.pmovement_lvl2(
					"MOBF:\t" .. T_YELLOW .. "redirecting to acceptable pos" .. C_RESET)
				movement_state.accel_to_set = best_tried_accel
				movement_state.changed = true
			else
				dbg_mobf.pmovement_lvl2(
					"MOBF:\t" .. T_RED .. "didn't find a way to redirect trying random" .. C_RESET)
				movement_state.force_change = true
				return false
			end
		else
			dbg_mobf.pmovement_lvl2(
					"MOBF:\t" .. T_GREEN .. "redirecting to good pos" .. C_RESET)
		end
		
		-- we did update movement_state using a valid new acceleration
		direction_control.redirect_safe_pos(entity, new_pos)
		return false
	end

	return true
end

-------------------------------------------------------------------------------
-- name: get_random_acceleration(entity, predicted_pos, 
--	predicted_quality, movement_state)
--
--! @brief handle drop state
--! @memberof direction_control
--! @private
--
--! @param entity mob to check
--! @param predicted_pos position the mob will be
--! @param predicted_quality quality of predicted position
--! @param movement_state current movement state
--! @param mob_is_safe mob is at save pos atm
--! @return true = nothing done in here, false = all done stop other checks
-------------------------------------------------------------------------------
function direction_control.handle_drop_pending(entity, predicted_pos, 
	predicted_quality, movement_state, mob_is_safe)

	local drop_pending =
			(predicted_quality.geometry_quality <= GQ_PARTIAL and
			 predicted_quality.center_geometry_quality <= GQ_NONE) or
			 predicted_quality.surface_quality_min <= SQ_WATER_3P
			 
	
	if drop_pending then
		dbg_mobf.pmovement_lvl2(
				"MOBF: mob " .. entity.data.name
				.. " is going to " .. T_YELLOW .. " walk on water or drop" .. C_RESET)
		dbg_mobf.pmovement_lvl2(
				"MOBF: state:\n" .. predicted_quality:tostring())
		entity.dynamic_data.movement.drop_was_pending = true
		
		-- try to find a position around where mob would be safe
		
		local already_done, new_pos =
			direction_control.redirect_safe_pos_callback(entity, movement_state,
															predicted_pos, true)
			
		if already_done then
			return false
		end
		
		
		if not direction_control.best_chance_redirect(entity, movement_state,
			new_pos, LT_EDGE_POS_POSSIBLE_CENTER) then
			return false
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
				return false
			end
		end

		-- bad case we don't know how to save this mob, let's try our chances
		dbg_mobf.pmovement_lvl2("MOBF:" .. T_RED .. " mob " .. entity.data.name ..
			" didn't find a way to fix drop trying random" .. C_RESET)
			
		--make mgen change direction randomly
		movement_state.force_change = true
		return true
	else
		return true
	end
end


-------------------------------------------------------------------------------
-- name: get_random_acceleration(entity, predicted_pos, 
--	predicted_quality, movement_state)
--
--! @brief handle drop state
--! @memberof direction_control
--! @private
--
--! @param entity mob to check
--! @param predicted_pos position the mob will be
--! @param predicted_quality quality of predicted position
--! @param movement_state current movement state
--! @param mob_is_safe mob is at save pos atm
--! @return true/false
-------------------------------------------------------------------------------
function direction_control.handle_collision_pending(entity, predicted_pos, 
	predicted_quality, movement_state, mob_is_safe)
	
	if predicted_quality.media_quality == MQ_IN_MEDIA and
		movement_state.current_quality.media_quality == MQ_IN_MEDIA then
		return true
	end
	
	dbg_mobf.pmovement_lvl2("MOBF: " ..entity.data.name .. " colliding or collision pending "
			.. printpos(movement_state.basepos) .. "-->"
			.. printpos(predicted_pos))
			
	-- we're ok now try to avoid collision
	if movement_state.current_quality.media_quality == MQ_IN_MEDIA then
	
		-- try jumping up
		if math.random() < entity.dynamic_data.movement.mpattern.jump_up then
			local pos_above = {x=predicted_pos.x, y = predicted_pos.y+1, z=predicted_pos.z}
			
			local quality_above = environment.pos_quality(pos_above, entity)
			
			if environment.evaluate_state(quality_above, LT_EDGE_POS) then
				dbg_mobf.pmovement_lvl2("MOBF:\t" .. T_PURPLE .. "jumping (TODO)" .. C_RESET)
				
				local current_speed_vec = entity.object:getvelocity()
				entity.object:setvelocity({x=current_speed_vec.x,y=6,z=current_speed_vec.z})
				movement_state.changed = true
				return false
			else
				dbg_mobf.pmovement_lvl2("MOBF:\t" .. T_PURPLE .. "tried to jump but quality is:" .. C_RESET .. quality_above:tostring())
			end
		end

		dbg_mobf.pmovement_lvl2("MOBF:\tforce random acceleration change to avoid collision")
		movement_state.force_change = true
		movement_generic.slow_down_xz(entity, 0.5)
		
	-- current pos is already colliding try redirecting to somewhere more good
	else
		dbg_mobf.pmovement_lvl2("MOBF:\t" .. T_YELLOW .. "mob already colliding, try to find better pos" .. C_RESET)
		
		-- check if we're already redirecting
		local already_done, new_pos =
			direction_control.redirect_safe_pos_callback(entity, movement_state,
															predicted_pos, false)
															
		if already_done then
			movement_state.changed = true
			return false
		end
	
		--try to redirect to some acceptable position
		if not direction_control.best_chance_redirect(entity, movement_state,
			new_pos, LT_EDGE_POS) then
			return false
		end
		
		--bad no good pos around 
		dbg_mobf.pmovement_lvl2("MOBF: " .. T_RED .. "mob " ..entity.data.name
				.. " colliding atm but didn't find a way to solve it" .. printpos(new_pos) .. C_RESET)
		movement_state.force_change = true
	end

	return true
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
	if prefered_quality then
		direction_control.redirect_safe_pos(entity, nil)
		return
	end

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

	if not direction_control.handle_collision_pending(entity, pos_predicted,
		pos_predicted_quality, movement_state) then
		return
	end

	dbg_mobf.pmovement_lvl2("MOBF: Unhandled suboptimal state:"
		.. pos_predicted_quality.tostring(pos_predicted_quality))
	movement_state.force_change = true
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
		if movement_state.changed then
			dbg_mobf.pmovement_lvl3("MOBF:<<< " .. entity.data.name ..
				" not random changing speed already changed: " .. dump(movement_state.changed))
		else
			dbg_mobf.pmovement_lvl3("MOBF:<<< " .. entity.data.name ..
				" not random changing speed: " .. rand_value .." >= " .. max_value)
		end
	end
end