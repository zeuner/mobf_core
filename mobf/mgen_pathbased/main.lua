-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file path_based_movement_gen.lua
--! @brief component containing a path based movement generator
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup mgen_path_based MGEN: Path based movement generator
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class p_mov_gen
--! @brief a movement generator evaluating a path to a target and following it
--!@}
p_mov_gen = {}
p_mov_gen.max_waypoint_distance = 0.5



--! @brief movement generator identifier
--! @memberof p_mov_gen
p_mov_gen.name = "mgen_path"

-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief path based movement generator callback
--! @memberof p_mov_gen
--
-- param1: mob to do movement
-- param2: current time
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.callback(entity,now,dstep)

	mobf_assert_backtrace(entity ~= nil)
	mobf_assert_backtrace(entity.dynamic_data ~= nil)
	mobf_assert_backtrace(entity.dynamic_data.p_movement ~= nil)
	mobf_assert_backtrace(dstep ~= nil)

	if entity.dynamic_data.p_movement.eta ~= nil then
		if now < entity.dynamic_data.p_movement.eta then
			return
		end
	end

	if entity.dynamic_data.p_movement.path == nil then
		dbg_mobf.path_mov_lvl1(
				"MOBF: path movement but mo path set!!")
		return
	end

	mobf_assert_backtrace(entity.dynamic_data.p_movement.next_path_index ~= nil)

	if entity.dynamic_data.movement.target == nil then
		mobf_assert_backtrace(entity.dynamic_data.p_movement.path ~= nil)
		
		local target = entity.dynamic_data.p_movement.path[entity.dynamic_data.p_movement.next_path_index]

		dbg_mobf.path_mov_lvl1("MOBF: (2) setting new target to index: " ..
				entity.dynamic_data.p_movement.next_path_index .. " pos: " ..
				printpos(target))
				
		mgen_follow.set_target(entity, target, nil, 
								p_mov_gen.max_waypoint_distance,
								p_mov_gen.on_target, true)
	end

	mgen_follow.callback(entity,now,dstep)
end


-------------------------------------------------------------------------------
-- name: distance_to_next_point(entity)
--
--! @brief get distance to next target point (2d only)
--! @memberof p_mov_gen
--! @private
--
--! @param entity mob to check
--! @param current_pos position mob is atm
--
--! @retval distance
-------------------------------------------------------------------------------
function p_mov_gen.distance_to_next_point(entity,current_pos)
	local index = entity.dynamic_data.p_movement.next_path_index
	mobf_assert_backtrace(entity.dynamic_data.p_movement.path ~= nil)
	mobf_assert_backtrace(index <= #entity.dynamic_data.p_movement.path)
	return mobf_calc_distance_2d(current_pos,
		entity.dynamic_data.p_movement.path[index])
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof p_mov_gen
--
--! @param entity to initialize
--! @param now current time
--! @param restored_data data restored on activate
-------------------------------------------------------------------------------
function p_mov_gen.init_dynamic_data(entity,now,restored_data)

	local pos = entity.object:getpos()

	local data = {
			path                = nil,
			eta                 = nil,
			last_move_stop      = now,
			next_path_index     = 1,
			force_target        = nil,
			pathowner           = nil,
			pathname            = nil,
			}

	if restored_data ~= nil and
		type(restored_data) == "table" then
		dbg_mobf.path_mov_lvl3(
			"MOBF: path movement reading stored data: " .. dump(restored_data))
		if restored_data.pathowner ~= nil and
			restored_data.pathname ~= nil then
			data.pathowner = restored_data.pathowner
			data.pathname = restored_data.pathname

			data.path = mobf_path.getpoints(data.pathowner,data.pathname)
			dbg_mobf.path_mov_lvl3(
				"MOBF: path movement restored points: " .. dump(data.path))
		end

		if restored_data.pathindex ~= nil and
			type(restored_data.pathindex) == "number" and
			restored_data.pathindex > 0 and
			data.path ~= nil and
			restored_data.pathindex < #data.path then
			data.next_path_index = restored_data.pathindex
		end
	end

	entity.dynamic_data.p_movement = data

	mgen_follow.init_dynamic_data(entity,now)
	
	entity.dynamic_data.movement.follow_speedup = false
end

-------------------------------------------------------------------------------
-- name: set_path(entity,path)
--
--! @brief set target for movgen
--! @memberof p_mov_gen
--! @public
--
--! @param entity mob to apply to
--! @param path to set
--! @param enable_speedup shall follow speedup be applied to path movement?
-------------------------------------------------------------------------------
function p_mov_gen.set_path(entity,path, enable_speedup)
	mobf_assert_backtrace(entity.dynamic_data.p_movement ~= nil)
	if path ~= nil then
		entity.dynamic_data.p_movement.next_path_index = 1
		entity.dynamic_data.p_movement.path = path
		
		if enable_speedup then
			entity.dynamic_data.movement.follow_speedup = follow_speedup
		end
		
		mgen_follow.set_target(entity,entity.dynamic_data.p_movement.path[1], nil, 
								p_mov_gen.max_waypoint_distance,
								p_mov_gen.on_target, true)
		return true
	else
		entity.dynamic_data.p_movement.next_path_index = nil
		entity.dynamic_data.movement.max_distance = nil
		entity.dynamic_data.p_movement.path = nil
		entity.dynamic_data.movement.target = nil
		entity.dynamic_data.movement.follow_speedup = nil
		return false
	end
end

-------------------------------------------------------------------------------
-- name: set_cycle_path(entity,value)
--
--! @brief set state of path cycle mechanism
--! @memberof p_mov_gen
--! @public
--
--! @param entity mob to apply to
--! @param value to set true/false/nil(mob global default)
-------------------------------------------------------------------------------
function p_mov_gen.set_cycle_path(entity,value)
	mobf_assert_backtrace(entity.dynamic_data.p_movement ~= nil)
	entity.dynamic_data.p_movement.cycle_path = value
end

-------------------------------------------------------------------------------
-- name: set_end_of_path_handler(entity,handler)
--
--! @brief set handler to call for non cyclic paths if final target is reached
--! @memberof p_mov_gen
--! @public
--
--! @param entity mob to apply to
--! @param handler to call at final target
-------------------------------------------------------------------------------
function p_mov_gen.set_end_of_path_handler(entity,handler)
	entity.dynamic_data.p_movement.HANDLER_end_of_path = handler
end

-------------------------------------------------------------------------------
-- name: on_target(entity)
--
--! @brief called once follow movegen tells it's on target
--! @memberof p_mov_gen
--! @public
--
--! @param entity mob reaching target
--! @param really_on_target tells if follow movegen did reach it or notice a fatal issue
-------------------------------------------------------------------------------
function p_mov_gen.on_target(entity, really_on_target)

	if really_on_target then
		dbg_mobf.path_mov_lvl2("MOBF: pathmov target "..
			 printpos(entity.dynamic_data.p_movement.path[1]) .. " reached")

		local cycle_path = entity.dynamic_data.p_movement.cycle_path or
				(entity.dynamic_data.p_movement.cycle_path == nil and
				entity.data.patrol ~= nil and
				entity.data.patrol.cycle_path)

		dbg_mobf.path_mov_lvl3("MOBF: pathmov cycle:  " .. dump(cycle_path))
		--remove first point from path
		if not cycle_path then
			local new_path = {}
			
			for i = 2, #entity.dynamic_data.p_movement.path, 1 do
				new_path[#new_path +1] = entity.dynamic_data.p_movement.path[i]
			end
			entity.dynamic_data.p_movement.path = new_path
		end
		
		
		if not cycle_path or 
				(entity.dynamic_data.p_movement.next_path_index
				== #entity.dynamic_data.p_movement.path) then
				entity.dynamic_data.p_movement.next_path_index = 0
		end

		--get next point to move to or exit if already at end
		if #entity.dynamic_data.p_movement.path == 0 then
			if entity.dynamic_data.p_movement.HANDLER_end_of_path ~= nil
					and type(entity.dynamic_data.p_movement.HANDLER_end_of_path) == "function" then
				entity.dynamic_data.p_movement.HANDLER_end_of_path(entity, true)
				entity.dynamic_data.p_movement.HANDLER_end_of_path = nil
			end
			entity.dynamic_data.p_movement.path = nil
			dbg_mobf.path_mov_lvl1("MOBF: end of path reached")
			return true
		end

		mobf_assert_backtrace(entity.dynamic_data.p_movement.path ~= nil)
		
		entity.dynamic_data.p_movement.next_path_index =
			entity.dynamic_data.p_movement.next_path_index + 1
			
		local targetpos = entity.dynamic_data.p_movement.path
				[entity.dynamic_data.p_movement.next_path_index]

		mgen_follow.set_target(entity,targetpos, nil, 
								p_mov_gen.max_waypoint_distance,
								p_mov_gen.on_target, true)
	

		dbg_mobf.path_mov_lvl1("MOBF: (1) setting new target to index: " ..
			entity.dynamic_data.p_movement.next_path_index .. " pos: " ..
			printpos(targetpos))
	else
		dbg_mobf.path_mov_lvl1("MOBF: failed to reach target we need to find another way there")
		
		entity.dynamic_data.p_movement.path = nil

		if entity.dynamic_data.p_movement.HANDLER_end_of_path ~= nil
			and type(entity.dynamic_data.p_movement.HANDLER_end_of_path) == "function" then
				
			entity.dynamic_data.p_movement.HANDLER_end_of_path(entity, false)
			entity.dynamic_data.p_movement.HANDLER_end_of_path = nil
		end
	end
end

-------------------------------------------------------------------------------
-- name: set_target(entity, target, follow_speedup, max_distance)
--
--! @brief set target for movgen
--! @memberof p_mov_gen
--! @public
--
--! @param entity mob to apply to
--! @param target to set
--! @param follow_speedup use follow speedup to reach target
--! @param max_distance --unused here
-------------------------------------------------------------------------------
function p_mov_gen.set_target(entity, target, follow_speedup, max_distance)
	mobf_assert_backtrace(target ~= nil)

	local current_pos = entity.getbasepos(entity)
	local targetpos = nil

	if not mobf_is_pos(target) then
		if target:is_player() then
			targetpos = target:getpos()
			targetpos.y = targetpos.y +0.5
		else
			if type(target.getbasepos) == "function" then
				targetpos = target.getbasepos(target)
			else
				targetpos = target:getpos()
			end
		end
	else
		targetpos = target
	end

	if targetpos == nil then
		return false
	end

	if entity.dynamic_data.p_movement.lasttargetpos ~= nil then
		if vector.equals(entity.dynamic_data.p_movement.lasttargetpos,
			targetpos) then
			return true
		end
	end

	entity.dynamic_data.p_movement.lasttargetpos = targetpos

	entity.dynamic_data.p_movement.path = nil
	entity.dynamic_data.p_movement.next_path_index = 1

	--try to find path on our own
	if not mobf_get_world_setting("mobf_disable_pathfinding") then
		entity.dynamic_data.p_movement.path =
		  mobf_path.find_path(current_pos,targetpos,5,1,1,nil)
	else
		entity.dynamic_data.p_movement.path = nil
	end
	
	-- build a path from target point only
	if entity.dynamic_data.p_movement.path == nil then
		minetest.log(LOGLEVEL_INFO,
			"MOBF: no pathfinding support/ no path found directly setting targetpos as path")

		local path = {}
		path[#path+1] = targetpos
		entity.dynamic_data.p_movement.path = path
	end

	-- set the path
	if entity.dynamic_data.p_movement.path ~= nil then
		entity.dynamic_data.movement.follow_speedup = follow_speedup
		
		mgen_follow.set_target(entity,entity.dynamic_data.p_movement.path[1], nil, 
								p_mov_gen.max_waypoint_distance,
								p_mov_gen.on_target, true)
		return true
	end

	return false
end

--register this movement generator
registerMovementGen(p_mov_gen.name,p_mov_gen)
