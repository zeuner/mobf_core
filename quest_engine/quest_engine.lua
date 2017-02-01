-------------------------------------------------------------------------------
-- Utils package
--
-- License CC BY
--
--! @file quest_engine.lua
--! @brief main part of quest engine
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-24
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
local quest_data_identifier = "quest_data"

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] init()
--
--! @brief initialize quest engine
--! @memberof quest_engine
-------------------------------------------------------------------------------
function quest_engine.init()

	if quest_engine ~= nil and quest_engine.init_done then
		return
	end

	quest_engine.definitions = {}
	quest_engine.event_definitions = {}

	quest_engine.quest_data = utils.read_world_data(quest_data_identifier)
	
	if quest_engine.quest_data == nil then
		quest_engine.quest_data = {}
	end
	
	quest_engine.register_event("event_craft", 
		{
			cbf = function(eventdef, parameter)
				if eventdef.item == parameter.item and
					parameter.count > 0 then
					return true
				end
			
			return false
		end
		})
	
	local craft_event_handler = function(itemstack, player, old_craft_grid, craft_inv)
		quest_engine.event(nil, player, "event_craft",
			{ item = itemstack:get_name(), count=itemstack:get_count() } )
	end
	
	minetest.register_on_craft(craft_event_handler)
	
	quest_engine.register_event("event_eat", 
		{
			cbf = function(eventdef, parameter)
				if eventdef.item == parameter.item and
					parameter.count > 0 and 
					eventdef.heal ~= nil and eventdef.heal <= parameter.heal then
					return true
				end
			
			return false
		end
		})
	
	local eat_event_handler = function(hp_change, replace_with_item, itemstack, user, pointed_thing)
		quest_engine.event(nil, user, "event_eat",
			{ item = itemstack:get_name(), count=itemstack:get_count(), heal=hp_change } )
	end
	
	minetest.register_on_item_eat(eat_event_handler)
	
	
	quest_engine.init_done = true

	-- TODO validate and cleanup remanent data once all quests have been loaded
end


-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] register_quest(quest_identifier, definition)
--
--! @brief register a quest to quest engine
--! @memberof quest_engine
--
--! @param quest_identifier unique name to use for this quest
--! @param definition definition of quest
--
--! @return true/false if the definition was correct and the identifier unique
-------------------------------------------------------------------------------
function quest_engine.register_quest(quest_identifier, definition)
	
	if quest_engine.definitions[quest_identifier] ~= nil then
		return false
	end
	
	-- TODO check quest definition
	
	quest_engine.definitions[quest_identifier] = definition
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] register_event(event_identifier, definition)
--
--! @brief initialize quest engine
--! @memberof quest_engine
--
--! @param event_identifier unique name to use for this event
--! @param definition definition of event
--
--! @return true/false if the definition was correct and the identifier unique
-------------------------------------------------------------------------------
function quest_engine.register_event(event_identifier, definition)
	
	if quest_engine.event_definitions[event_identifier] ~= nil then
		return false
	end
	
	-- TODO check event definition
	
	quest_engine.event_definitions[event_identifier] = definition
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] active_quests(playername)
--
--! @brief initialize quest engine
--! @memberof quest_engine
--
--! @param playername name of player to get state for
--
--! @return list of quest id's active for player
-------------------------------------------------------------------------------
function quest_engine.active_quests(playername)
	local retval = {}
	
	print("questdata: " .. dump(quest_engine.quest_data[playername]))
	
	for key, value in pairs(quest_engine.quest_data[playername].quests_active) do
		table.insert(retval, key)
	end

	return retval
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] get_quest_state(quest_identifier, playername)
--
--! @brief initialize quest engine
--! @memberof quest_engine
--
--! @param quest_identifier unique name used for this quest
--! @param playername name of player to get state for
--
--! @return current quest state for player
-------------------------------------------------------------------------------
function quest_engine.get_quest_state(questlist, playername)

	quest_engine.init_questdata(playername)
	
	if questlist == nil then
		-- TODO add error trace
		return nil
	end
	
	-- find current active quest within questlist for playername
	local total_possible_quests = {}

	for key, value in pairs(quest_engine.definitions) do
		
		for i=1, #questlist, 1 do
			if key == questlist[i] then
				table.insert(total_possible_quests, key)
			end
		end
	end
		
	local possible_quests = {}
	local playerdata = quest_engine.quest_data[playername]
	
	for i=1, #total_possible_quests, 1 do
		local is_possible = true
		local questdef = quest_engine.definitions[total_possible_quests[i]]
		
		if not questdef.repeatable then
			if utils.contains(playerdata.quests_completed, total_possible_quests[i]) then
				is_possible = false
			end
		end

		for j=1, #questdef.quests_required , 1 do
			if not utils.contains(playerdata.quests_completed, questdef.quests_required[j]) then
				is_possible = false
			end
		end
	
		if is_possible then
			table.insert(possible_quests, total_possible_quests[i])
		end
	end
	
	-- more then one quest possible suggest first one for the time beeing
	if #possible_quests > 0 then
		if quest_engine.quest_data[playername].quests_active[possible_quests[1]] == nil then
			quest_engine.quest_data[playername].quests_active[possible_quests[1]] = {
				current_state = "init_state"
			}
		end
	
		return {
				questid = possible_quests[1],
				questdef = quest_engine.definitions[possible_quests[1]],
				playerdata = quest_engine.quest_data[playername].quests_active[possible_quests[1]]
			}
	end

	return nil
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] quest_action(quest_identifier, playername, action)
--
--! @brief initialize quest engine
--! @memberof quest_engine
--
--! @param quest_identifier unique name used for this quest
--! @param playername name of player to get state for
--! @param action to perform for player and quest
--
--! @return new quest sate
-------------------------------------------------------------------------------
function quest_engine.quest_action(quest_identifier, playername, action)

	local questdef = quest_engine.definitions[quest_identifier]
	local playerdata = quest_engine.quest_data[playername].quests_active[quest_identifier]
	local queststate = questdef[playerdata.current_state]
	
	
	quest_engine.dbg_lvl1("quest_enine: quest_action " .. action)

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
		table.insert(quest_engine.quest_data[playername].quests_completed, quest_identifier)
		quest_engine.quest_data[playername].quests_active[quest_identifier] = nil
	end
	
	utils.write_world_data(quest_data_identifier,quest_engine.quest_data)
end


-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] init_questdata(playername)
--
--! @brief initialize player specific quest data
--! @memberof quest_engine
--
--! @param playername name of player
-------------------------------------------------------------------------------
function quest_engine.init_questdata(playername)
	if quest_engine.quest_data[playername] ~= nil then
		return
	end
	
	quest_engine.quest_data[playername] = {
		quests_completed = {},
		quests_active = {}
	}
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] action_available(entity, player, actiondef, playerdata)
--
--! @brief check if a specific action is available
--! @memberof quest_engine
--
--! @param entity
--! @param player
--! @param actiondef
--! @param playerdata
--
--! @return true/false
-------------------------------------------------------------------------------
function quest_engine.action_available(entity, player, actiondef, playerdata)
	if actiondef.action_available_fct ~= nil then
		return actiondef.action_available_fct(entity, player, actiondef, playerdata)
	end
	
	if actiondef.events_required ~= nil then
		
		
		
		for i,eventdef in ipairs(actiondef.events_required) do
			quest_engine.dbg_lvl2("quest_engine: action requires: " .. dump(eventdef))
			
			if not quest_engine.event_completed(eventdef,playerdata) then
				return false
			end
		end
	end
	
	return true
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] event_completed(eventdef, playerdata)
--
--! @brief check if player did complete a specific event requirement
--! @memberof quest_engine
--
--! @param eventdef description of event requirement
--! @param playerdata player event data
--
--! @return true/false
-------------------------------------------------------------------------------
function quest_engine.event_completed(eventdef, playerdata)

	if quest_engine.event_definitions[eventdef.type] ~= nil then
	
		local count = 0
		for i, event in ipairs(playerdata.events) do
		
			if event.type == eventdef.type and 
				quest_engine.event_definitions[eventdef.type].cbf(eventdef, event.parameter) then
				count = count + 1
			end

		end
		
		if count >= eventdef.count then
			return true
		end
		
		return false
		
	end

	quest_engine.dbg_lvl3("quest_engine: event_complete unknown eventtype \"" .. eventdef.type .. "\"")
	return false
end

-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] event_relevant(eventtype, questaction, playername, printmsg)
--
--! @brief check if event is relevant for state
--! @memberof quest_engine
--
--! @param eventtype type of event to check
--! @param questaction action to check
--! @param playername name of player
--! @param printmsg send chat message
--
--! @return true/false
-------------------------------------------------------------------------------
function quest_engine.event_relevant(eventtype, questaction, playername, printmsg)

	if questaction == nil then
		return false
	end

	if questaction.events_required then
		for i=1, #questaction.events_required, 1 do
			if questaction.events_required[i].type == eventtype then
			
				if printmsg and questaction.events_required[i].msg ~= nil then
					minetest.chat_send_player(playername, questaction.events_required[i].msg)
				end
				return true
			end
		end
		
		return false
	else
		return true
	end
end


-------------------------------------------------------------------------------
-- @function [parent=#quest_engine] event(entity, player, eventtype, parameters)
--
--! @brief tell quest engine about a happened event
--! @memberof quest_engine
--
--! @param entity related to event
--! @param player causing the event
--! @param eventtype type of event
--! @param parameter custom parameter
--
-------------------------------------------------------------------------------
function quest_engine.event(entity, player, eventtype, parameter)

	if not player:is_player() then
		return
	end

	local playername = player:get_player_name()
	
	quest_engine.dbg_lvl3("quest_engine: event type=" .. eventtype .. " playername=" .. playername)
	
	local questlist = quest_engine.active_quests(playername)
	
	for i, quest in ipairs(questlist) do
		local questdata = quest_engine.get_quest_state({ quest }, playername)
		
		-- TODO check if event is relevant for state
		local queststate = questdata.questdef[questdata.playerdata.current_state]
		
		if questdata.playerdata.current_state and
			queststate and 
			(quest_engine.event_relevant(eventtype, queststate.action1, playername, true) or
			not quest_engine.event_relevant(eventtype, queststate.action2, playername, true) or
			not quest_engine.event_relevant(eventtype, queststate.action3, playername, true)) then
		
			if questdata.playerdata.events == nil then
				questdata.playerdata.events = {}
			end
		
			if parameter == nil then
				parameter = {}
			end
		
			table.insert(questdata.playerdata.events,
				{ type=eventtype, parameter=parameter}
				)
		end
		
	end
	
	utils.write_world_data(quest_data_identifier,quest_engine.quest_data)
end