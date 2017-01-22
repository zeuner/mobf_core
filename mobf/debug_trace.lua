-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file debug_trace.lua
--! @brief contains switchable debug trace functions
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @defgroup debug_trace Debug trace functions
--! @brief central configuration of trace functions
--! @ingroup framework_int

--lvl1 excessive output
--lvl2 medium output
--lvl3 less output

-- usable levels
--LOGLEVEL_INFO
--LOGLEVEL_NOTICE
--LOGLEVEL_WARNING
--LOGLEVEL_ERROR
--LOGLEVEL_CRITICAL


local trace_levels = {
	{ "generic",                  nil,           nil,                nil },
	{ "graphics",                 nil,           nil,                nil },
	{ "spawning",                 nil,           nil,                nil },
	{ "permanent_store",          nil,           nil,                nil },
	{ "movement",                 nil,           nil,                nil },
	{ "pmovement",                nil,           nil,                nil },
	{ "mgen_probv2",              nil,           nil,                nil },
	{ "fmovement",                nil,           nil,                nil },
	{ "flmovement",               nil,           nil,                nil },
	{ "path_mov",                 nil,           nil,                nil },
	{ "fighting",                 nil,           nil,                nil },
	{ "environment",              nil,           nil,                nil },
	{ "harvesting",               nil,           nil,                nil },
	{ "sound",                    nil,           nil,                nil },
	{ "random_drop",              nil,           nil,                nil },
	{ "mob_state",                nil,           nil,                nil },
	{ "mobf_core",                nil,           nil,                nil },
	{ "mobf_core_helper",         nil,           nil,                nil },
	{ "trader_inv",               nil,           nil,                nil },
	{ "ride",                     nil,           nil,                nil },
	{ "path",                     nil,           nil,                nil },
	{ "lifebar",                  nil,           nil,                nil },
	{ "attention",                nil,           nil,                nil },
	{ "physics",                  nil,           nil,                nil },
	{ "quest_inv",                nil,           nil,                nil },
	{ "quest_engine",             nil,           nil,                nil },
	
}


--! @brief configuration of trace level to use for various components
--! @ingroup debug_trace
dbg_mobf = {}


--! initialize trace functions
for i, v in ipairs(trace_levels) do
	
	if v[2] ~= nil then
		dbg_mobf[v[1] .. "_lvl1"] = function(msg) core.log(v[2], msg) end
	else
		dbg_mobf[v[1] .. "_lvl1"] = function(msg) end
	end
	
	if v[3] ~= nil then
		dbg_mobf[v[1] .. "_lvl2"] = function(msg) core.log(v[3], msg) end
	else
		dbg_mobf[v[1] .. "_lvl2"] = function(msg) end
	end
	
	if v[4] ~= nil then
		dbg_mobf[v[1] .. "_lvl3"] = function(msg) core.log(v[4], msg) end
	else
		dbg_mobf[v[1] .. "_lvl3"] = function(msg) end
	end
end