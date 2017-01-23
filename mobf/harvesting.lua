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
--! @date 2012-08-09
--
--! @defgroup harvesting Harvesting subcomponent
--! @brief Component handling harvesting
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf_assert_backtrace(not core.global_exists("harvesting"))
--! @class harvesting
--! @brief harvesting features
harvesting = {}

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
function harvesting.init_dynamic_data(entity,now)
	dbg_mobf.harvesting_lvl1("MOBF: " .. entity.data.name
		.. " initializing harvesting dynamic data")
	local data =  {
		ts_last 				= now,
	}
	entity.dynamic_data.harvesting = data
end


function harvesting.catch(entity, player, now)

	if entity.data.catching ~= nil and
		entity.data.catching.tool ~= "" then

		--bugfix check
		if (entity.dynamic_data.spawning.player_spawned and
				entity.dynamic_data.spawning.spawner == nil) then
			dbg_mobf.harvesting_lvl1("MOBF: mob flagged as player spanwned but no spawner set!")
			entity.dynamic_data.spawning.player_spawned = false
		end

		--grief protection
		if minetest.world_setting_get("mobf_grief_protection") and
			entity.dynamic_data.spawning.player_spawned and
			entity.dynamic_data.spawning.spawner ~= player:get_player_name() then
			dbg_mobf.harvesting_lvl1("MOBF: anti gief triggered catching aborted")
			return true
		end

		-- what's wielded by player
		local tool = player:get_wielded_item()
		local catchtools = entity.data.catching.tool
		
		if type(entity.data.catching.tool) == "string" then
			catchtools = {}
			catchtools[#catchtools +1 ] = {
				name = entity.data.catching.tool,
				chance = 1
			}
		end
		
		dbg_mobf.harvesting_lvl3("MOBF: catch_tool: " .. dump(tool:get_name()) .. " catchtools: " .. dump(catchtools) .. " count: " .. #catchtools)
		
		for i = 1, #catchtools, 1 do
			dbg_mobf.harvesting_lvl3("MOBF: catch_tool: " .. dump(tool:get_name()) .. " <-> " .. catchtools[i].name )
			if tool:get_name() == catchtools[i].name then
				dbg_mobf.harvesting_lvl1("MOBF: player wearing ".. 
					entity.data.catching.tool)
		
				-- check if mob is in some state in which it can't be cought, abort in this case
				if type(entity.data.catching.can_be_cought) == "function" then
					if (not entity.data.catching.can_be_cought(entity)) then
						dbg_mobf.harvesting_lvl1("MOBF: entity denied catching")
						return true
					end
				end

				-- take from inventory
				if entity.data.catching.consumed == true and
					not mobf_rtd.creative_mode then
					if player:get_inventory():contains_item("main",catchtools[i].name.." 1") then
						dbg_mobf.harvesting_lvl2("MOBF: removing: "
							.. catchtools[i].name.." 1")
						player:get_inventory():remove_item("main",
							catchtools[i].name.." 1")
					else
						mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!! player is"
						.. " wearing a item he doesn't have in inventory!!!")
						return true
					end
				end
				
				-- check chances
				if math.random() > catchtools[i].chance then
					minetest.chat_send_player(player:get_player_name(),
						"You failed to catch " .. entity.description .. "!")
					return true
				end
				
				-- determin what to add in case of successfull catching
				local catch_result = nil
				local catch_type = "undefined"

				if entity.data.generic.addoncatch ~= nil then
					catch_result = entity.data.generic.addoncatch.." 1"
					catch_type = "specified"
				else
					catch_result = entity.data.modname ..":"..entity.data.name.." 1"
					catch_type = "automatic"
				end
				
				dbg_mobf.harvesting_lvl2("MOBF: adding " .. catch_type .. 
					" oncatch item: " .. catch_result)
				
				local add_retval = 
					player:get_inventory():add_item("main",catch_result)
				
				-- try to add to player inventory
				if not add_retval:is_empty() then
					minetest.chat_send_player(player:get_player_name(),
						"You don't have any room left in inventory!")
					return true
				end
				
				--play catch sound
				if entity.data.sound ~= nil then
					sound.play(entity.object:getpos(),entity.data.sound.catch);
				end
				
				mobf_quest_engine.event(entity, player, "event_cought", { mob=entity.name, tool=catchtools[i].name, result=catch_result })
				
				spawning.remove(entity, "cought")
				return true
			end
		end
	end

	return false
end

-------------------------------------------------------------------------------
-- @function [parent=#harvesting] callback(entity,player,now)
--
--! @brief callback handler for harvest by player
--! @memberof harvesting
--
--! @param entity mob being harvested
--! @param player player harvesting
--! @param now the current time
--! @return true/false if handled by harvesting or not
-------------------------------------------------------------------------------
function harvesting.callback(entity,player,now)

	dbg_mobf.harvesting_lvl1("MOBF: harvest function called")

	local now = mobf_get_current_time()

	--handle catching of mob
	if harvesting.catch(entity,player,now) then
		return true
	end

	--handle harvestable mobs, check if player is wearing correct tool
	if entity.data.harvest ~= nil then

		dbg_mobf.harvesting_lvl1("MOBF: trying to harvest harvestable mob")
		if (entity.data.harvest.tool ~= "") then
			local tool = player:get_wielded_item()
			if tool ~= nil then
				dbg_mobf.harvesting_lvl1("MOBF: Player is wearing >"
					.. tool:get_name() .. "< required is >".. entity.data.harvest.tool
					.. "< wear: " .. tool:get_wear())

				if (tool:get_name() ~=  entity.data.harvest.tool) then
					--player is wearing wrong tool do an attack
					return false
				else
					--tool is completely consumed
					if entity.data.harvest.tool_consumed == true then
						if player:get_inventory():contains_item("main",entity.data.harvest.tool.." 1") == false then
							dbg_mobf.harvesting_lvl1("MOBF: Player doesn't have"
								.. " at least 1 of ".. entity.data.harvest.tool)
							--handled but not ok so don't attack
							return true
						end
					else
						--damage tool
						local tool_wear = tool:get_wear()

						dbg_mobf.harvesting_lvl1("MOBF: tool " .. tool:get_name()
							.. " wear: " ..  tool_wear)
						-- damage used tool
						if tool_wear ~= nil and
							entity.data.harvest.max_tool_usage ~= nil then

							local todamage = (65535/entity.data.harvest.max_tool_usage)
							dbg_mobf.harvesting_lvl1("MOBF: tool damage calculated: "
								.. todamage);
							if tool:add_wear(todamage) ~= true then
								dbg_mobf.harvesting_lvl3("MOBF: Tried to damage non tool item "
									.. tool:get_name() .. "!");
							end
							player:set_wielded_item(tool)
						end
					end
				end
			else
				--player isn't wearing a tool so this has to be an attack
				return false
			end
		else
			--no havest tool defined so this has to be an attack
			return false
		end


		--transformation and harvest delay is exclusive

		--harvest delay mode
		if entity.data.harvest.min_delay < 0 or
			entity.dynamic_data.harvesting.ts_last + entity.data.harvest.min_delay < now then
			
			local result = nil 
			
			if mobf_dyeing.config_check(entity) then
				result = mobf_dyeing.get_harvest_result(entity)
			elseif type(entity.data.harvest.result) == "function" then
				result = entity.data.harvest.result(entity)
			else
				result = entity.data.harvest.result.." 1"
			end
			
			if not player:get_inventory():add_item("main", result) then
				-- TODO place as item at entity pos
			end
			
			mobf_quest_engine.event(entity, player, "event_harvest", entity.name)

			--check if tool is consumed by action
			if entity.data.harvest.tool_consumed and
				not mobf_rtd.creative_mode then
				dbg_mobf.harvesting_lvl2("MOBF: removing "
					..entity.data.harvest.tool.." 1")
				player:get_inventory():remove_item("main",entity.data.harvest.tool.." 1")
			end
		else
			dbg_mobf.harvesting_lvl1("MOBF: " .. entity.data.name
				.. " not ready to be harvested")
		end

		-- check if mob is transformed by harvest
		if entity.data.harvest.transforms_to ~= nil and
			entity.data.harvest.transforms_to ~= "" then
			local transformed = spawning.replace_entity(entity,
											entity.data.harvest.transforms_to)
		else
			entity.dynamic_data.harvesting.ts_last = mobf_get_current_time()
		end


		--play harvest sound
		if entity.data.sound ~= nil then
			sound.play(entity.object:getpos(),entity.data.sound.harvest);
		end

		--harvest done
		return true
	end

	return false
end


-------------------------------------------------------------------------------
-- @function transform(entity)
--
--! @brief self transform callback for mob
--! @ingroup harvesting
--
--! @param entity mob calling
--! @param now current time
-------------------------------------------------------------------------------
function transform(entity,now)

	--check if it's a transformable mob
	if entity.data.auto_transform ~= nil then

		if now - entity.dynamic_data.spawning.original_spawntime
			> entity.data.auto_transform.delay then
			spawning.replace_entity(entity,entity.data.auto_transform.result)
			return false
		end

	end

end
