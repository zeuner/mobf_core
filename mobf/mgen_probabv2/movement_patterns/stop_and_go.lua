-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file stop_and_go.lua
--! @brief movementpattern creating a random stop and go movement e.g. sheep/cow
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-10
--
--! @addtogroup mpatterns
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @struct stop_and_go_prototype
--! @brief movement pattern for mobs wandering around randomly
local stop_and_go_prototype = {
		name                            ="stop_and_go_v2",
		
		-- chance to move to higher level
		climb_node_up_chance            = 0.4,

		-- random jump configuration
		random_jump_chance              = 0,
		random_jump_initial_speed       = 0,
		random_jump_delay               = 0,
		
		-- chances for movement
		start_movement_chance           = 0.45,
		change_started_movement_chance  = 0.05,
		stop_movement_chance            = 0.05,
		max_target_distance             = 4
	}

--!@}

mgen_probab_v2.register_pattern(stop_and_go_prototype)