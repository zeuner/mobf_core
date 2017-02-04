-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file quest_events.lua
--! @brief class containing event initialization
--! @copyright Sapier
--! @author Sapier
--! @date 2017-01-25
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

quest_engine.init()

quest_engine.register_event(
	"event_harvest",
	{
		cbf = function(eventdef, parameter)
			if eventdef.mobtype == nil or parameter == eventdef.mobtype then
				return true
			end
			
			return false
		end
	}
)

quest_engine.register_event(
	"event_cought",
	{
		cbf = function(eventdef, parameter)
			if (eventdef.mob == nil or eventdef.mob == parameter.mob) and
				(eventdef.tool == nil or eventdef.name == parameter.tool) and 
				(eventdef.result == nil or eventdef.result == parameter.tool) then
				return true
			end
			
			return false
		end
	}
)

quest_engine.register_event(
	"event_killed",
	{
		cbf = function(eventdef, parameter)
			if (eventdef.mob == nil or eventdef.mob == parameter.mob) and
				(eventdef.tool == nil or eventdef.name == parameter.tool) and 
				(eventdef.result == nil or eventdef.result == parameter.tool) then
				return true
			end
			
			-- pattern matching for mobname
			if eventdef.mob == nil and string.find(eventdef.mob,"*") then
				local mobfilter = string.sub(eventdef.mob, -2, 1)
				print("mobfilter=" .. mobfilter)
				if (string.find(parameter.mob, mobfilter) == 1) and
					(eventdef.tool == nil or eventdef.name == parameter.tool) and 
					(eventdef.result == nil or eventdef.result == parameter.tool) then
					return true
				end
			end
			
			return false
		end
	}
)