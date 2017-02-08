-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file inventory.lua
--! @brief component containing mob inventory related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-02
--
--! @defgroup Inventory Inventory subcomponent
--! @brief Component handling mob inventory
--! @ingroup framework_int
--! @{
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
mobf_assert_backtrace(not core.global_exists("mobf_quest_inventory"))
--! @class mobf_quest_inventory
--! @brief inventory handling for trader like mobs
mobf_quest_inventory = {}
--! @}

-- Boilerplate to support localized strings if intllib mod is installed.
local S
if core.global_exists("intllib") then
	S = intllib.Getter()
else
	S = function(s) return s end
end
-------------------------------------------------------------------------------
mobf_quest_inventory.formspecs = {}


-- @function [parent=#mobf_quest_inventory] config_check(entity)
--
--! @brief check if mob contains quest handling information
--! @memberof mobf_quest_inventory
--! @public
--
--! @param entity mob being checked
--! @return true/false if quest relevant or not
-------------------------------------------------------------------------------
function mobf_quest_inventory.config_check(entity)
	if entity.data.quest ~= nil then
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_inventory] register_formspec(name,formspec)
--
--! @brief register a formspec to quest inventory handling
--! @memberof mob_inventory
--! @public
--
--! @param name name of formspec to register
--! @param formspec formspec definition
--
--! @return true/false if succesfull or not
-------------------------------------------------------------------------------
function mobf_quest_inventory.register_formspec(name,formspec)

	if mobf_quest_inventory.formspecs[name] == nil then
		mobf_quest_inventory.formspecs[name] = formspec
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_inventory] quest_inventory_callback(entity,player)
--
--! @brief callback handler for inventory by rightclick
--! @memberof mob_inventory
--! @public
--
--! @param entity mob quest inventory is opened
--! @param player player doiing rightclick
--
--! @return true/false if handled
-------------------------------------------------------------------------------
function mobf_quest_inventory.quest_inventory_callback(entity, player)

	if entity.data.quest == nil then
		dbg_mobf.quest_inv_lvl3("MOBF: quest_inv missing quest information")
		return
	end
	
	local playername = player:get_player_name()
	
	if playername == nil then
		dbg_mobf.quest_inv_lvl3("MOBF: quest_inv no playername available")
		return
	end
	
	local questdata = quest_engine.get_quest_state(entity.data.quest.questlist, playername)

	if questdata == nil then
		-- TODO provide some meaningless gossip if there ain't any quest
		dbg_mobf.quest_inv_lvl1("MOBF: gossip not implemented")
		return
	end
	
	
	dbg_mobf.quest_inv_lvl1("MOBF: quest_inv state=" .. questdata.playerdata.current_state)
	
	if entity.data.sound ~= nil and
		entity.data.sound.quest_inventory_open ~= nil then
		sound.play(playername, entity.data.sound.quest_inventory_open)
	end
	
	local formspec_to_show = mobf_quest_inventory.create_formspec(player, entity, playername, questdata)

	if formspec_to_show ~= nil then
	
		local pos = entity.object:getpos()
		
		if pos == nil then
			dbg_mobf.quest_inv_lvl2("MOBF: unable to get npc pos")
			minetest.show_formspec(playername,"")
			return
		end
		
		graphics.look_to_object(entity, player)

		attention.increase_attention_level(entity,player,10)

		if minetest.show_formspec(playername,
					"formspec_questinventory",
					formspec_to_show)
					== false then
			dbg_mobf.quest_inv_lvl3("MOBF: unable to show formspec")
		end
	else
		dbg_mobf.quest_inv_lvl3("MOBF: no formspec available")
	end
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_inventory] quest_inventory_response(entity,player)
--
--! @brief callback handler for player response
--! @memberof mob_inventory
--! @public
--
--! @param player player who did answer
--! @param formname form triggering the response
--! @param fields fields from formspec
--
--! @return true/false if handled
-------------------------------------------------------------------------------
function mobf_quest_inventory.quest_inventory_response(player,formname,fields)

	if formname == "formspec_questinventory" then

		if fields["btn_action1"] ~= nil then
			quest_engine.quest_action(fields["questid"], player:get_player_name(), "state_action_1")
		end

		if fields["btn_action2"] ~= nil then
			quest_engine.quest_action(fields["questid"], player:get_player_name(), "state_action_2")
		end
		
		if fields["btn_action3"] ~= nil then
			quest_engine.quest_action(fields["questid"], player:get_player_name(), "state_action_3")
		end
	
		return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_inventory] init()
--
--! @brief initialize quest inventory system
--! @memberof mobf_quest_inventory
--! @public
--
--! @param player player formspec to be shown to
--! @param playername name of player
--! @param questdata state of current quest
--
--! @return formspec definition
-------------------------------------------------------------------------------
function mobf_quest_inventory.init()

	minetest.register_on_player_receive_fields(mobf_quest_inventory.quest_inventory_response)
end

-------------------------------------------------------------------------------
-- @function [parent=#mobf_quest_inventory] create_formspec(player, playername, questdata)
--
--! @brief callback handler for inventory by rightclick
--! @memberof mobf_quest_inventory
--! @public
--
--! @param player player formspec to be shown to
--! @param playername name of player
--! @param questdata state of current quest
--
--! @return formspec definition
-------------------------------------------------------------------------------
function mobf_quest_inventory.create_formspec(player, entity, playername, questdata)

	local retval = "size[8,6;]" ..
			"label[0.25,0;"..S("Hello %s"):format(playername).."]"
			

	local queststate = questdata.questdef[questdata.playerdata.current_state]
	
	if queststate == nil then
		return retval
	end
	
	if questdata.questid then
		retval = retval .. "field[-999,-999;1,1;questid;;" .. questdata.questid .. "]"
	end

	if queststate.text ~= nil then
		retval = retval .. "textarea[0.5,0.5;5,4;x;;".. S(queststate.text) .. "]"
	end
	
	if queststate.action1 ~= nil and 
		quest_engine.action_available(entity, player, queststate.action1, questdata.playerdata) then
		retval = retval .. "button_exit[0.2,4.5;7.75,0;btn_action1;" .. S(queststate.action1.msg) .. "]"
	end
	
	if queststate.action2 ~= nil and 
		quest_engine.action_available(entity, player, queststate.action2, questdata.playerdata) then
		retval = retval .. "button_exit[0.2,5.25;7.75,0;btn_action2;" .. S(queststate.action2.msg) .. "]"
	end
	
	if queststate.action3 ~= nil and 
		quest_engine.action_available(entity, player, queststate.action3, questdata.playerdata) then
		retval = retval .. "button_exit[0.2,6;7.75,0;btn_action3;" .. S(queststate.action3.msg) .. "]"
	end
	
	if queststate.recipe ~= nil then
		if queststate.recipe[1] and queststate.recipe[1][1] and queststate.recipe[1][1] ~= "" then
			retval = retval .. "item_image[5.25,0.75;0.75,0.75;" .. queststate.recipe[1][1] .. "]"
		end
		if queststate.recipe[1] and queststate.recipe[1][2] and queststate.recipe[1][2] ~= "" then
			retval = retval .. "item_image[6,0.75;0.75,0.75;" .. queststate.recipe[1][2] .. "]"
		end
		if queststate.recipe[1] and queststate.recipe[1][3] and queststate.recipe[1][3] ~= "" then
			retval = retval .. "item_image[6.75,0.75;0.75,0.75;" .. queststate.recipe[1][3] .. "]"
		end
		if queststate.recipe[2] and queststate.recipe[2][1] and queststate.recipe[2][1] ~= "" then
			retval = retval .. "item_image[5.25,1.5;0.75,0.75;" .. queststate.recipe[2][1] .. "]"
		end
		if queststate.recipe[2] and queststate.recipe[2][2] and queststate.recipe[2][2] ~= "" then
			retval = retval .. "item_image[6,1.5;0.75,0.75;" .. queststate.recipe[2][2] .. "]"
		end
		if queststate.recipe[2] and queststate.recipe[2][3] and queststate.recipe[2][3] ~= "" then
			retval = retval .. "item_image[6.75,1.5;0.75,0.75;" .. queststate.recipe[2][3] .. "]"
		end
		if queststate.recipe[3] and queststate.recipe[3][1] and queststate.recipe[3][1] ~= "" then
			retval = retval .. "item_image[5.25,2.25;0.75,0.75;" .. queststate.recipe[3][1] .. "]"
		end
		if queststate.recipe[3] and queststate.recipe[3][2] and queststate.recipe[3][2] ~= "" then
			retval = retval .. "item_image[6,2.25;0.75,0.75;" .. queststate.recipe[3][2] .. "]"
		end
		if queststate.recipe[3] and queststate.recipe[3][3] and queststate.recipe[3][3] ~= "" then
			retval = retval .. "item_image[6.75,2.25;0.75,0.75;" .. queststate.recipe[3][3] .. "]"
		end
	end
	
	return retval
end