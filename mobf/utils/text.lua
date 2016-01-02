-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file text.lua
--! @brief generic functions used in many different places
--! @copyright Sapier
--! @author Sapier
--! @date 2013-02-04
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @defgroup gen_func Generic functions
--! @brief functions for various tasks
--! @ingroup framework_int
--! @{

T_BLACK = "\027[0;30m"
T_RED    ="\027[0;31m"
T_GREEN  ="\027[0;32m"
T_YELLOW ="\027[0;33m"
T_BLUE   ="\027[0;34m"
T_PURPLE ="\027[0;35m"
T_CYAN   ="\027[0;36m"
T_WHITE  ="\027[0;37m"
B_BLACK  ="\027[1;30m"
B_RED    ="\027[1;31m"
B_GREEN  ="\027[1;32m"
B_YELLOW ="\027[1;33m"
B_BLUE   ="\027[1;34m"
B_PURPLE ="\027[1;35m"
B_CYAN   ="\027[1;36m"
B_WHITE  ="\027[1;37m"
U_BLACK  ="\027[4;30m"
U_RED    ="\027[4;31m"
U_GREEN  ="\027[4;32m"
U_YELLOW ="\027[4;33m"
U_BLUE   ="\027[4;34m"
U_PURPLE ="\027[4;35m"
U_CYAN   ="\027[4;36m"
U_WHITE  ="\027[4;37m"
BK_BLACK ="\027[40m"
BK_RED   ="\027[41m"
BK_GREEN ="\027[42m"
BK_YELLOW="\027[43m"
BK_BLUE  ="\027[44m"
BK_PURPLE="\027[45m"
BK_CYAN  ="\027[46m"
BK_WHITE ="\027[47m"
C_RESET  ="\027[0m"

-------------------------------------------------------------------------------
-- name: printpos(pos)
--
--! @brief convert pos to string of type "(X,Y,Z)"
--
--! @param pos position to convert
--! @return string with coordinates of pos
-------------------------------------------------------------------------------
function printpos(pos)
	if pos ~= nil then
		if pos.y ~= nil then
			mobf_assert_backtrace(type(pos.x) == "number")
			mobf_assert_backtrace(type(pos.z) == "number")
			mobf_assert_backtrace(type(pos.y) == "number")
			return "("..string.format("%3f",pos.x)..","
						..string.format("%3f",pos.y)..","
						..string.format("%3f",pos.z)..")"
		else
			mobf_assert_backtrace(type(pos.x) == "number")
			mobf_assert_backtrace(type(pos.z) == "number")
			return "("..string.format("%3f",pos.x)..", ? ,"
						..string.format("%3f",pos.z)..")"
		end
	end
	return ""
end

-------------------------------------------------------------------------------
-- name: mobf_print(text)
--
--! @brief print adding timestamp in front of text
--
--! @param text to show
-------------------------------------------------------------------------------
function mobf_print(text)
	print("[" .. string.format("%10f",os.clock()) .. "]" .. text)
end

-------------------------------------------------------------------------------
-- name: mobf_fixed_size_string(text,length)
--
--! @brief make a text fixed length
--
--! @param text text to enforce lenght
--! @param length lenght to enforce
--!
--! @return text with exactly lenght characters
-------------------------------------------------------------------------------
function mobf_fixed_size_string(text,length)
	mobf_assert_backtrace(length ~= nil)
	
	if text == nil then
		text="nil"
	end
	
	local current_length = string.len(text)
	
	if current_length == nil then 
		current_length = 0
		text = ""
	end
	
	if current_length < length then
		
		while current_length < length do
			text = text .. " "
			current_length = current_length +1
		end
		
		return text
	else
		return string.sub(text,1,length)
	end
end
--!@}