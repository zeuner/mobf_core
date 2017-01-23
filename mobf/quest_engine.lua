-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file quest_engine.lua
--! @brief a quest engine implementation
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-22
--
--! @defgroup mobf_quest_engine
--! @brief engine for registering and following quests
--! @ingroup framework_int
--! @{
-- Contact: sapier a t gmx net
-------------------------------------------------------------------------------
mobf_assert_backtrace(not core.global_exists("mobf_quest_engine"))

--! @class mobf_quest_engine
--! @brief a quest engine
mobf_quest_engine = {}
--!@}

local quest_data_identifier = "mobf_quest_data"

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] init()
--
--! @brief initialize quest engine
--! @memberof mobf_quest_engine
-------------------------------------------------------------------------------
function mobf_quest_engine.init()

	mobf_quest_engine.definitions = {}

	mobf_quest_engine.quest_data = mobf_read_world_specific_data(quest_data_identifier)
	
	if mobf_quest_engine.quest_data == nil then
		mobf_quest_engine.quest_data = {}
	end

	-- TODO validate and cleanup remanent data once all quests have been loaded
end


-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] register_quest(quest_identifier, definition)
--
--! @brief initialize quest engine
--! @memberof mobf_quest_engine
--
--! @param quest_identifier unique name to use for this quest
--! @param definition definition of quest
--
--! @return true/false if the definition was correct and the identifier unique
-------------------------------------------------------------------------------
function mobf_quest_engine.register_quest(quest_identifier, definition)
	
	if mobf_quest_engine.definitions[quest_identifier] ~= nil then
		return false
	end
	
	-- TODO check quest definition
	
	mobf_quest_engine.definitions[quest_identifier] = definition
end


-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] active_quests(playername)
--
--! @brief initialize quest engine
--! @memberof mobf_quest_engine
--
--! @param playername name of player to get state for
--
--! @return list of quest id's active for player
-------------------------------------------------------------------------------
function mobf_quest_engine.active_quests(playername)
	local retval = {}
	
	print("questdata: " .. dump(mobf_quest_engine.quest_data[playername]))
	
	for key, value in pairs(mobf_quest_engine.quest_data[playername].quests_active) do
		table.insert(retval, key)
	end

	return retval
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] get_quest_state(quest_identifier, playername)
--
--! @brief initialize quest engine
--! @memberof mobf_quest_engine
--
--! @param quest_identifier unique name used for this quest
--! @param playername name of player to get state for
--
--! @return current quest state for player
-------------------------------------------------------------------------------
function mobf_quest_engine.get_quest_state(questlist, playername)

	mobf_quest_engine.init_questdata(playername)
	
	if questlist == nil then
		-- TODO add error trace
		return nil
	end
	
	-- find current active quest within questlist for playername
	local total_possible_quests = {}

	for key, value in pairs(mobf_quest_engine.definitions) do
		
		for i=1, #questlist, 1 do
			if key == questlist[i] then
				table.insert(total_possible_quests, key)
			end
		end
	end
		
	local possible_quests = {}
	local playerdata = mobf_quest_engine.quest_data[playername]
	
	for i=1, #total_possible_quests, 1 do
		local is_possible = true
		local questdef = mobf_quest_engine.definitions[total_possible_quests[i]]
		
		if not questdef.repeatable then
			if mobf_contains(playerdata.quests_completed, total_possible_quests[i]) then
				is_possible = false
			end
		end

		for j=1, #questdef.quests_required , 1 do
			if not mobf_contains(playerdata.quests_completed, questdef.quests_required[j]) then
				is_possible = false
			end
		end
	
		if is_possible then
			table.insert(possible_quests, total_possible_quests[i])
		end
	end
	
	-- more then one quest possible suggest first one for the time beeing
	if #possible_quests > 0 then
		if mobf_quest_engine.quest_data[playername].quests_active[possible_quests[1]] == nil then
			mobf_quest_engine.quest_data[playername].quests_active[possible_quests[1]] = {
				current_state = "init_state"
			}
		end
	
		return {
				questid = possible_quests[1],
				questdef = mobf_quest_engine.definitions[possible_quests[1]],
				playerdata = mobf_quest_engine.quest_data[playername].quests_active[possible_quests[1]]
			}
	end

	return nil
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] quest_action(quest_identifier, playername, action)
--
--! @brief initialize quest engine
--! @memberof mobf_quest_engine
--
--! @param quest_identifier unique name used for this quest
--! @param playername name of player to get state for
--! @param action to perform for player and quest
--
--! @return new quest sate
-------------------------------------------------------------------------------
function mobf_quest_engine.quest_action(quest_identifier, playername, action)

	local questdef = mobf_quest_engine.definitions[quest_identifier]
	local playerdata = mobf_quest_engine.quest_data[playername].quests_active[quest_identifier]
	local queststate = questdef[playerdata.current_state]
	
	
	dbg_mobf.quest_engine_lvl1("MOBF: quest_action " .. action)

	if action == "state_action_1" then
		if queststate.action1 and queststate.action1.next_state then
			playerdata.current_state = queststate.action1.next_state
			playerdata.events = {}
		end
	end
	
	if action == "state_action_2" then
		if queststate.action2 and queststate.action2.next_state then
			playerdata.current_state = queststate.action2.next_state
			playerdata.events = {}
		end
	end
	
	if action == "state_action_3" then
		if queststate.action3 and queststate.action3.next_state then
			playerdata.current_state = queststate.action3.next_state
			playerdata.events = {}
		end
	end
	
	if playerdata.current_state == "quest_completed" then
		table.insert(mobf_quest_engine.quest_data[playername].quests_completed, quest_identifier)
		mobf_quest_engine.quest_data[playername].quests_active[quest_identifier] = nil
	end
	
	mobf_write_world_specific_data(quest_data_identifier,mobf_quest_engine.quest_data)
end


-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] quest_action(playername)
--
--! @brief initialize player specific quest data
--! @memberof mobf_quest_engine
--
--! @param playername name of player
-------------------------------------------------------------------------------
function mobf_quest_engine.init_questdata(playername)
	if mobf_quest_engine.quest_data[playername] ~= nil then
		return
	end
	
	mobf_quest_engine.quest_data[playername] = {
		quests_completed = {},
		quests_active = {}
	}
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] action_available(entity, player, actiondef, playerdata)
--
--! @brief check if a specific action is available
--! @memberof mobf_quest_engine
--
--! @param entity
--! @param player
--! @param actiondef
--! @param playerdata
--
--! @return true/false
-------------------------------------------------------------------------------
function mobf_quest_engine.action_available(entity, player, actiondef, playerdata)
	if actiondef.action_available_fct ~= nil then
		return actiondef.action_available_fct(entity, player, actiondef, playerdata)
	end
	
	if actiondef.events_required ~= nil then
		
		
		
		for i,eventdef in ipairs(actiondef.events_required) do
			dbg_mobf.quest_engine_lvl2("MOBF: action requires: " .. dump(eventdef))
			
			if not mobf_quest_engine.event_completed(eventdef,playerdata) then
				return false
			end
		end
	end
	
	return true
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] event_completed(eventdef, playerdata)
--
--! @brief check if player did complete a specific event requirement
--! @memberof mobf_quest_engine
--
--! @param eventdef description of event requirement
--! @param playerdata player event data
--
--! @return true/false
-------------------------------------------------------------------------------
function mobf_quest_engine.event_completed(eventdef, playerdata)

	if eventdef.type == "event_harvest" then
		dbg_mobf.quest_engine_lvl2("MOBF: player_events: " .. dump(playerdata.events))
		local count = 0
		for i, event in ipairs(playerdata.events) do
			if event.type == "event_harvest" and event.parameter == eventdef.mobtype then
				count = count + 1
			end
		end
		
		if count >= eventdef.count then
			return true
		end
		
		return false
	end


	dbg_mobf.quest_engine_lvl3("MOBF: event_complete unknown eventtype \"" .. eventdef.type .. "\"")
	return false
end


-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_engine] event(entity, player, eventtype, parameters)
--
--! @brief tell quest engine about a happened event
--! @memberof mobf_quest_engine
--
--! @param entity related to event
--! @param player causing the event
--! @param eventtype type of event
--! @param parameter custom parameter
--
-------------------------------------------------------------------------------
function mobf_quest_engine.event(entity, player, eventtype, parameter)

	if not player:is_player() then
		return
	end

	local playername = player:get_player_name()
	
	dbg_mobf.quest_engine_lvl3("MOBF: event type=" .. eventtype .. " playername=" .. playername)
	
	local questlist = mobf_quest_engine.active_quests(playername)
	
	for i, quest in ipairs(questlist) do
		local questdata = mobf_quest_engine.get_quest_state({ quest }, playername)
		
		if questdata.playerdata.events == nil then
			questdata.playerdata.events = {}
		end
		
		table.insert(questdata.playerdata.events,
			{ type=eventtype, parameter=parameter}
			)
		
	end
	
	mobf_write_world_specific_data(quest_data_identifier,mobf_quest_engine.quest_data)
end