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
function mobf_quest_engine.active_quests( playername)

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
		if mobf_quest_engine.quest_data[playername][possible_quests[1]] == nil then
			mobf_quest_engine.quest_data[playername][possible_quests[1]] = {
				current_state = "init_state"
			}
		end
	
		return {
				questid = possible_quests[1],
				questdef = mobf_quest_engine.definitions[possible_quests[1]],
				playerdata = mobf_quest_engine.quest_data[playername][possible_quests[1]]
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
	local playerdata = mobf_quest_engine.quest_data[playername][quest_identifier]
	local queststate = questdef[playerdata.current_state]
	
	
	dbg_mobf.quest_engine_lvl1("MOBF: quest_action " .. action)

	if action == "state_action_1" then
		if queststate.action1 and queststate.action1.next_state then
			playerdata.current_state = queststate.action1.next_state
		end
	end
	
	if action == "state_action_2" then
		if queststate.action2 and queststate.action2.next_state then
			playerdata.current_state = queststate.action2.next_state
		end
	end
	
	if action == "state_action_3" then
		if queststate.action3 and queststate.action3.next_state then
			playerdata.current_state = queststate.action3.next_state
		end
	end
	
	if playerdata.current_state == "quest_completed" then
		table.insert(mobf_quest_engine.quest_data[playername].quests_completed, quest_identifier)
		mobf_quest_engine.quest_data[playername][quest_identifier] = nil
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