-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file init.lua
--! @brief barn implementation
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-27
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

-- Boilerplate to support localized strings if intllib mod is installed.
local S
if (minetest.get_modpath("intllib")) then
  dofile(minetest.get_modpath("intllib").."/intllib.lua")
  S = intllib.Getter(minetest.get_current_modname())
else
  S = function ( s ) return s end
end

minetest.log("action","MOD: barn mod loading ...")

-- barn class
local barn = {}
local version = "0.1.0"
local modpath = minetest.get_modpath("barn")

barn.breedpairs = {
	{ "animal_sheep:sheep","animal_sheep:sheep","animal_sheep:lamb","animal_sheep:lamb"},
	{ "animal_cow:cow","animal_cow:steer","animal_cow:baby_calf_m","animal_cow:baby_calf_f"},
	}

barn.breedpairs_small = {
	{ "animal_chicken:chicken","animal_chicken:rooster","animal_chicken:chick_m","animal_chicken:chick_f"},
}

--include barn models
dofile (modpath .. "/model.lua")


-- register craftrecieps for barns
minetest.register_craftitem("barn:barn_empty", {
			description = S("Barn to breed animals"),
			image = minetest.inventorycube("barn_3d_empty_top.png","barn_3d_empty_side.png","barn_3d_empty_side.png"),
			on_place = function(item, placer, pointed_thing)
				if pointed_thing.type == "node" then
					local pos = pointed_thing.above

					local newobject = minetest.add_entity(pos,"barn:barn_empty_ent")

					item:take_item()

					return item
				end
			end
		})

minetest.register_craftitem("barn:barn_small_empty", {
			description = S("Barn to breed small animals"),
			image = "barn_small.png",
			on_place = function(item, placer, pointed_thing)
				if pointed_thing.type == "node" then
					local pos = pointed_thing.above

					local newobject = minetest.add_entity(pos,"barn:barn_small_empty_ent")

					item:take_item()

					return item
				end
			end
		})

minetest.register_craft({
	output = "barn:barn_empty 1",
	recipe = {
		{'default:stick', 'default:stick','default:stick'},
		{'default:wood','default:wood','default:wood'},
	}
})

minetest.register_craft({
	output = "barn:barn_small_empty 1",
	recipe = {
		{'default:stick', 'default:stick'},
		{'default:wood','default:wood'},
	}
})


------------------------------------------------------------------------------
-- @function [parent=#barn] is_food(name)
--
--! @brief check if something is considered to be food
--! @memberof barn
--! @public
--
--! @param name name of thing to be beckecked
--! @param self the barn
--! @param now current time
-------------------------------------------------------------------------------
barn.is_food = function (name)

	if name == "default:leaves" then
		return true
	end

	if name == "default:junglegrass" then
		return true
	end

	return false
end

------------------------------------------------------------------------------
-- @function [parent=#barn] free_pos_around(pos)
--
--! @brief get a free pos around pos
--! @memberof barn
--! @public
--
--! @param pos position to look for free pos around
--
--! @return position or nil
-------------------------------------------------------------------------------
barn.free_pos_around = function(pos)
	for xdelta = -1, 1, 1 do
	for zdelta = -1, 1, 1 do
		local new_pos = {
				x=pos.x + xdelta,
				y=pos.y,
				z=pos.z + zdelta}
				
		local objectcount = #minetest.get_objects_inside_radius( new_pos ,1)
		print("Objectcount at pos " .. printpos(new_pos) .. " is " .. objectcount)
		if not objectcount or objectcount <= 0 then
			print("position found")

			return new_pos
		end
	end
	end

	return nil
end

------------------------------------------------------------------------------
-- @function [parent=#barn] breed(breedpairs, self, now)
--
--! @brief make mobs breed
--! @memberof barn
--! @public
--
--! @param breedpairs breed definition
--! @param self the barn
--! @param now current time
-------------------------------------------------------------------------------
barn.breed = function(breedpairs,self,now)

	local pos = self.object:getpos()
	local objectlist = minetest.get_objects_inside_radius(pos,4)
	local le_animal1 = nil
	local le_animal2 = nil

	for index,value in pairs(objectlist) do

		local luaentity = value:get_luaentity()

		local mobname = nil

		if luaentity ~= nil and
			luaentity.data ~= nil and
			luaentity.data.name ~= nil and
			luaentity.data.modname ~= nil then
			mobname = luaentity.data.modname .. ":" .. luaentity.data.name
		end

		if mobname ~= nil and
			mobname == breedpairs[1] and
			luaentity ~= le_animal1 and
			le_animal2 == nil then

			le_animal2 = luaentity
		end

		if mobname ~= nil and
			mobname == breedpairs[2] and
			le_animal2 ~= luaentity then

			le_animal1 = luaentity
		end

		if le_animal1 ~= nil and
			le_animal2 ~= nil then
			break
		end
	end

	if math.random() < (0.001 * (now - (self.last_breed_time + 30))) and
		self.last_breed_time > 0 and
		le_animal1 ~= nil and
		le_animal2 ~= nil then
		local pos1 = le_animal1.object:getpos()
		local pos2 = le_animal2.object:getpos()
		local pos = self.object:getpos()
		local pos_to_breed = {
								x = pos1.x + (pos2.x - pos1.x) /2,
								y = pos1.y,
								z = pos1.z + (pos2.z - pos1.z) /2,
							}

		-- check position by now this is done by spawn algorithm only
		
		if #minetest.get_objects_inside_radius(pos_to_breed,1) > 0 then
		
			pos_to_breed = barn.free_pos_around(pos_to_breed)
		end
		
		if pos_to_breed == nil then
			return false
		end

		local result = breedpairs[math.random(3,4)]

		local breeded = minetest.add_entity(pos_to_breed ,result)

		local breeded_lua = breeded:get_luaentity()

		if breeded_lua.dynamic_data.spawning == nil then
			breeded_lua.dynamic_data.spawning = {}
		end
		breeded_lua.dynamic_data.spawning.player_spawned = true
		
		if le_animal1.dynamic_data.spawning.spawner ~= nil then
			breeded_lua.dynamic_data.spawning.spawner = le_animal1.dynamic_data.spawning.spawner
		elseif le_animal2.dynamic_data.spawning.spawner ~= nil then
			breeded_lua.dynamic_data.spawning.spawner = le_animal2.dynamic_data.spawning.spawner
		end
		
		local player = minetest.get_player_by_name(breeded_lua.dynamic_data.spawning.spawner)
		
		if player ~= nil then
			quest_engine.event(nil, player, "event_breed", 
				{ 
					breeded = result,
					mobtype1 = le_animal1.data.modname .. ":" .. le_animal1.data.name,
					mobtype2 = le_animal2.data.modname .. ":" .. le_animal2.data.name,
				})
		end
	
		return true
	end

	return false
end

-- register barn entity for breeding
minetest.register_entity(":barn:barn_ent",
	{
		physical 		= true,
		collisionbox 	= {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
		visual 			= "wielditem",
		textures 		= { "barn:box_filled"},
		visual_size     = { x=0.666,y=0.666,z=0.666},

		on_step = function(self,dtime)

			local now = os.time(os.date('*t'))

			if now ~= self.last_check_time then

				local select = math.random(1,#barn.breedpairs)
				local breedpairs = barn.breedpairs[select]
				--print("Selected " ..  select .. " --> " ..dump(breedpairs))


				if barn.breed(breedpairs,self,now) then
					local pos = self.object:getpos()
					--remove barn and add empty one
					self.object:remove()

					local barn_empty = minetest.add_entity(pos,"barn:barn_empty_ent")
					local barn_empty_lua = barn_empty:get_luaentity()
					barn_empty_lua.last_breed_time = now
				end

				self.last_check_time = now
			end
		end,

		on_activate = function(self,staticdata)
			if staticdata == nil then
				self.last_breed_time = os.time(os.date('*t'))
			else
				self.last_breed_time = tonumber(staticdata)
			end
			self.last_check_time = os.time(os.date('*t'))
		end,

		get_staticdata = function(self)
			return self.last_breed_time
		end,

		on_punch = function(self,player)
			player:get_inventory():add_item("main", "barn:barn_empty 1")
			self.object:remove()
		end,

		last_breed_time = -1,
		last_check_time = -1,
	})

-- register barn entity for placing barn
minetest.register_entity(":barn:barn_empty_ent",
	{
		physical 		= true,
		collisionbox 	= {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
		visual 			= "wielditem",
		textures 		= { "barn:box_empty"},
		visual_size     = { x=0.666,y=0.666,z=0.666},


		on_punch = function(self,player)
		
		  if player == nil then
		      return
		  end
		  
		  if not player:is_player() then
		      return
		  end

			--if player is wearing food replace by full barn
			local tool = player:get_wielded_item()

			if barn.is_food(tool:get_name()) then
				local time_of_last_breed = self.last_breed_time
				local pos = self.object:getpos()

				self.object:remove()

				local barn = minetest.add_entity(pos,"barn:barn_ent")

				local barn_lua = barn:get_luaentity()

				barn_lua.last_breed_time = time_of_last_breed

				player:get_inventory():remove_item("main",tool:get_name().." 1")
			--else add to players inventory
			else
				player:get_inventory():add_item("main", "barn:barn_empty 1")
				self.object:remove()
			end
		end,

		on_activate = function(self, staticdata)
			self.last_breed_time = os.time(os.date('*t'))
			self.last_check_time = self.last_breed_time
		end,

		})


-- register small barn for breeding
minetest.register_entity(":barn:barn_small_ent",
	{
		physical 		= true,
		collisionbox 	= {-0.5,-0.5,-0.5, 0.5,-0.2,0.5},
		visual 			= "wielditem",
		textures 		= { "barn:box_small_filled"},
		visual_size     = { x=0.666,y=0.666,z=0.666},

		on_step = function(self,dtime)

			local now = os.time(os.date('*t'))

			if now ~= self.last_check_time then



				local select = math.random(1,#barn.breedpairs_small)
				local breedpairs = barn.breedpairs_small[select]
				--print("Selected " ..  select .. " --> " ..dump(breedpairs))


				if barn.breed(breedpairs,self,now) then
					local pos = self.object:getpos()
					--remove barn and add empty one
					self.object:remove()

					local barn_empty = minetest.add_entity(pos,"barn:barn_small_empty_ent")
					local barn_empty_lua = barn_empty:get_luaentity()
					barn_empty_lua.last_breed_time = now
				end

				self.last_check_time = now
			end
		end,

		on_activate = function(self,staticdata)
			if staticdata == nil then
				self.last_breed_time = os.time(os.date('*t'))
			else
				self.last_breed_time = tonumber(staticdata)
			end
			self.last_check_time = os.time(os.date('*t'))
		end,

		get_staticdata = function(self)
			return self.last_breed_time
		end,

		on_punch = function(self,player)
			player:get_inventory():add_item("main", "barn:barn_small_empty 1")
			self.object:remove()
		end,

		last_breed_time = -1,
		last_check_time = -1,
	})


--register small barn entity to place a small barn
minetest.register_entity(":barn:barn_small_empty_ent",
	{
		physical 		= true,
		collisionbox 	= {-0.5,-0.5,-0.5, 0.5,-0.2,0.5},
		visual 			= "wielditem",
		textures 		= { "barn:box_small_empty"},
		visual_size     = { x=0.666,y=0.666,z=0.666},


		on_punch = function(self,player)

			--if player is wearing food replace by full barn
			local tool = player:get_wielded_item()

			if barn.is_food(tool:get_name()) then
				local time_of_last_breed = self.last_breed_time
				local pos = self.object:getpos()

				self.object:remove()

				local barn = minetest.add_entity(pos,"barn:barn_small_ent")

				local barn_lua = barn:get_luaentity()

				barn_lua.last_breed_time = time_of_last_breed

				player:get_inventory():remove_item("main",tool:get_name().." 1")
			--else add to players inventory
			else
				player:get_inventory():add_item("main", "barn:barn_small_empty 1")
				self.object:remove()
			end
		end,

		on_activate = function(self, staticdata)
			self.last_breed_time = os.time(os.date('*t'))
			self.last_check_time = self.last_breed_time
		end,

		})

-- initialize quest support for barn
quest_engine.init()

quest_engine.register_event(
	"event_breed",
	{
		cbf = function(eventdef, parameter)
			if (eventdef.mobtype1 == nil or parameter.mobtype1 == eventdef.mobtype1 ) and
				(eventdef.mobtype2 == nil or parameter.mobtype2 == eventdef.mobtype2 )  or 
				(eventdef.mobtype1 == nil or parameter.mobtype2 == eventdef.mobtype1 ) and
				(eventdef.mobtype2 == nil or parameter.mobtype1 == eventdef.mobtype2 ) and
				(eventdef.breeded == nil or parameter.breeded == eventdef.breeded) then
				return true
			end
			
			return false
		end
	}
)

------------------------------------------------------------------------------
-- @function register_breed_definition(name)
--
--! @brief official api for registering breed from mobs
--
--! @param breeddef the definition to use for breeding
-------------------------------------------------------------------------------
function register_breed_definition(breeddef)

	local toadd = {}
	
	if breeddef.mob1 ~= nil then 
		toadd.mobtype1 = breeddef.mob1
	end
		
	if breeddef.mob2 ~= nil then
		toadd.mobtype2 = breeddef.mob2
	end
	
	if breeddef.results ~= nil then
		toadd.results = breeddef.results
	end
	
	
	if toadd.mobtype2 == nil then
		toadd.mobtype2 = toadd.mobtype1
	end
	
	toadd.food = breeddef.food
	
	if toadd.mobtype1 == nil or 
		toadd.mobtype2 == nil or
		toadd.results == nil then
		return false
	end

	if breeddef.barn == "smallbarn" then
		table.insert(barn.breedpairs_small,breeddef)
		return true
		
	elseif breeddef.barn == "barn" then
		table.insert(barn.breedpairs,breeddef)
		return true
		
	else
		return false
	end
	-- TODO
end

minetest.log("action","MOD: barn mod version " .. version .. " loaded")
