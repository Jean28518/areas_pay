local UPDATE_TIME = 60
local BLOCKS_TO_REMOVE = {"default:chest", "default:chest_locked", "doors:door_steel_a", "doors:door_steel_b", "doors:trapdoor_steel", "doors:trapdoor_steel_open" }
local MAX_RENT_PERIODS = 2 -- This is how long a customer can book the area in the future
--------------------------------------------------------------------------------
-- MEMORY ----------------------------------------------------------------------
--------------------------------------------------------------------------------

local storage = minetest.get_mod_storage()
local rents = minetest.deserialize(storage:get_string("rents"))
if rents == nil then
  rents = {}
end
storage:set_string("rents", minetest.serialize(rents))

-- rents[AREA_ID] = {owner="OWNERNAME", customer="CUSTOMERNAME", rented_to=MINETEST_TIME, rentID=AREA_ID}

local timer = 0
minetest.register_globalstep(function(dtime)
timer = timer + dtime
if (timer > UPDATE_TIME) then
  timer = 0
  -- Remove rented areas, theren time is up
  local rents = minetest.deserialize(storage:get_string("rents"))
  if not rents then
    return
  end
  local now = minetest.get_gametime()
  for id, table in pairs(rents) do
    if (rents[id].rented_to < now) then
      areas_pay_remove_recursive_areas(rents[id].owner, rents[id].rentID)
      rents[id] = nil
      -- Remove ALL Chests, LockedChests, LockedDoors, .... from the area
      for k, v in pairs(BLOCKS_TO_REMOVE) do
        worldedit.replace(areas.areas[id].pos1, areas.areas[id].pos2, v, "air")
      end
    else
      areas_pay_remove_recursive_areas(rents[id].owner, rents[id].rentID)
      rents[id].rentID = areas_pay_add_owner(rents[id].owner, id.." "..rents[id].customer.." Rented Area")
    end
  end
  storage:set_string("rents", minetest.serialize(rents))
end




end)

----------------------------------------------------------------------------
-- Area Sell/Rent Block
----------------------------------------------------------------------------
default.areas_pay_pos = {}

minetest.register_craft({
  output = "areas_pay:shop_block",
	recipe = {
		{"", "", ""},
		{"dye:red", "default:wood", "dye:red"},
		{"", "", ""}
	}
})

minetest.register_node("areas_pay:shop_block", {

    description = "Area Shop Block",
		tiles = {"default_wood.png",
				"default_wood.png",
				"area_pay_front.png",
				"area_pay_front.png",
				"area_pay_front.png",
				"area_pay_front.png",},
    is_ground_content = true,
		-- light_source = 10,
    groups = {dig_immediate=2},
    sounds = default.node_sound_wood_defaults(),
-- Registriere den Owner beim Platzieren:
    after_place_node = function(pos, placer, itemstack)
      local meta = minetest.get_meta(pos)
			meta:set_string("areas_pay:rs", "Sell")
			meta:set_int("areas_pay:price", 0)
      meta:set_int("areas_pay:area_id", 0)
      meta:set_int("areas_pay:period", 7)
      meta:set_string("areas_pay:status", "still to have")
      meta:set_string("owner", placer:get_player_name())
      meta:set_string("areas_pay:customer", "")
    end,
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
      default.areas_pay_pos[player:get_player_name()] = pos
      areas_pay_update_information(player)
      local meta = minetest.get_meta(pos)
      -- Remove obsolete Blocks (If the owner of the block doesnt own the area anymore)
      if meta:get_string("owner") ~= player:get_player_name() and not areas:isAreaOwner(meta:get_int("areas_pay:area_id"), meta:get_string("owner")) and meta:get_int("areas_pay:area_id") ~= 0  then
        minetest.remove_node(pos);
        return
      end
      areas_pay_show_spec(player)
    end,
    can_dig = function(pos, player)
      local meta = minetest.get_meta(pos)
      if player:get_player_name() == meta:get_string("owner") then
        return true
      else
        return false
    end
  end


})

areas_pay_update_information = function (customer)
  local pos = default.areas_pay_pos[customer:get_player_name()]
  local meta = minetest.get_meta(pos)
  local rents = minetest.deserialize(storage:get_string("rents"))
  local id = meta:get_int("areas_pay:area_id")
  if rents ~= nil and rents[id] ~= nil then

    meta:set_string("areas_pay:customer", rents[id].customer)
    meta:set_string("areas_pay:status", "Rented for "..math.floor((rents[meta:get_int("areas_pay:area_id")].rented_to - minetest.get_gametime()) / (24*3600)) .." days by "..rents[id].customer.."." )
  else
    meta:set_string("areas_pay:customer", "")
    meta:set_string("areas_pay:status", "still to have" )
  end
end

areas_pay_show_spec = function (player)
    local pos = default.areas_pay_pos[player:get_player_name()]
    local meta = minetest.get_meta(pos)
    local player_name = player:get_player_name()
    local listname = "nodemeta:"..pos.x..','..pos.y..','..pos.z
    local rents = minetest.deserialize(storage:get_string("rents"))
		if atm.balance[player:get_player_name()] == nil then
			atm.balance[player:get_player_name()] = 0
		end
		if player:get_player_name() == meta:get_string("owner") then
		minetest.show_formspec(player:get_player_name(), "areas_pay_owner", "size[6.5,5]"..
     "label[0,0;Welcome, ".. player:get_player_name().."]" ..
     "label[3.3,0;Status: ".. meta:get_string("areas_pay:status").."]" ..
     "field[0.3,1.3;6.5,1;area_id_field;Areas ID:;"..meta:get_string("areas_pay:area_id").."]" ..
		 "field[0.3,2.3;3,1;price_field;Price:;"..meta:get_string("areas_pay:price").."]" ..
     "field[3.55,2.3;3.2,1;period_field;Period in Days (Just for Rent):;"..meta:get_string("areas_pay:period").."]" ..
		 "button[0,3.3;6.5,1;save_fields_button;Save Fields]" ..
     "button[0,4.3;6.5,1;set_rent_sell_button;"..meta:get_string("areas_pay:rs").."]"
   )
 elseif meta:get_string("areas_pay:rs") == "Sell" then -- For Buying
      minetest.show_formspec(player:get_player_name(), "areas_pay_customer", "size[8,1.7]"..
      "label[0,0;Welcome, "..player:get_player_name()..", the Area with the ID "..meta:get_string("areas_pay:area_id").." is for Sell.]" ..
      "label[0,0.5;Price: "..meta:get_string("areas_pay:price").."]" ..
      "button[5,1;3,1;buy_button;Buy Now]"
    )
  elseif meta:get_string("areas_pay:customer") == player_name then -- For the current customer in renting
    minetest.show_formspec(player:get_player_name(), "areas_pay_customer_rent", "size[8,1.7]"..
    "label[0,0;Welcome back, "..player:get_player_name()..", you are renting the area "..meta:get_string("areas_pay:area_id").." the next ".. math.floor((rents[meta:get_int("areas_pay:area_id")].rented_to - minetest.get_gametime()) / (24*3600)) .." Days.]" ..
    "label[0,0.5;Price: "..meta:get_string("areas_pay:price").."]" ..
    "label[1.5,0.5;Period: "..meta:get_string("areas_pay:period").." Days]" ..
    "button[5,1;3,1;rent_button;Rent Now]")
  elseif meta:get_string("areas_pay:status") == "still to have" then -- For other custumers
    minetest.show_formspec(player:get_player_name(), "areas_pay_customer_rent", "size[8,1.7]"..
    "label[0,0;Welcome, "..player:get_player_name()..", the area with the ID "..meta:get_string("areas_pay:area_id").." is open for rent.]" ..
    "label[0,0.5;Price: "..meta:get_string("areas_pay:price").."]" ..
    "label[1.5,0.5;Period: "..meta:get_string("areas_pay:period").." Days]" ..
    "button[5,1;3,1;rent_button;Rent Now]")
  else -- When the area is rented
    minetest.show_formspec(player:get_player_name(), "areas_pay_customer_rented", "size[8,0.7]"..
    "label[0,0;Welcome, "..player:get_player_name()..".  Unfortunately the area with the ID "..meta:get_string("areas_pay:area_id").." is rented.]" ..
    "label[0,0.5;Price: "..meta:get_string("areas_pay:price").."]")
  end
end
--
-- -- Wenn der Spieler auf Exchange gedrückt hat:
-- minetest.register_on_player_receive_fields(function(customer, formname, fields)
-- 	if formname == "areas_pay:areas_pay_license_atm" and fields.buy_sell ~= nil and fields.buy_sell ~= "" then
--     local pos = default.areas_pay_pos[customer:get_player_name()]
--     local meta = minetest.get_meta(pos)
--     local minv = meta:get_inventory()
--     local pinv = customer:get_inventory()
--     local items = minv:get_list("einnahme")
--     if items == nil then return end -- do not crash the server
--
-- 	-- Check if We Can Exchange:
-- 	local enough_space = true
-- 	local enough_items = true
-- 		-- BUY:
-- 		if meta:get_string("areas_pay:rs") == "Buy" then
-- 			for i, item in pairs(items) do
-- 				if not pinv:room_for_item("main", item)  then
-- 					enough_space = false
-- 				end
-- 			end
--
--
--
-- 		-- SELL:
-- 		else
-- 			for i, item in pairs(items) do
-- 				if not pinv:contains_item("main",item) then
-- 					enough_items = false
-- 				end
-- 			end
-- 		end
--
--
-- 	-- Check Licence:
-- 		local allowed = false
-- 		local empty = true
-- 		local ltable = minetest.deserialize(meta:get_string("areas_pay:ltable"))
-- 		if ltable == nil then
-- 			ltable = {}
-- 		end
-- 		for k, v in pairs(ltable) do
-- 			empty = false
-- 			if v == "defined" then
-- 				if licenses_check_player_by_licese(customer:get_player_name(), k) then
-- 					allowed = true
-- 				end
-- 			end
-- 		end
-- 		if empty then
-- 			allowed = true
-- 		end
-- 	-- Enough Money???
-- 		if meta:get_string("areas_pay:rs") == "Buy" and atm.balance[customer:get_player_name()] < meta:get_int("areas_pay:price") then
-- 			minetest.chat_send_player(customer:get_player_name(),"You dont have enough money on your account!" )
-- 			return
-- 		end
--

-- Set Rent / Sell
minetest.register_on_player_receive_fields(function(customer, formname, fields)
	if formname == "areas_pay_owner" and fields.set_rent_sell_button ~= nil and fields.set_rent_sell_button ~= "" then
		local pos = default.areas_pay_pos[customer:get_player_name()]
		local meta = minetest.get_meta(pos)
		if meta:get_string("areas_pay:rs") == "Rent" then
			meta:set_string("areas_pay:rs", "Sell")
		else
			meta:set_string("areas_pay:rs", "Rent")
		end
		areas_pay_show_spec(customer)
	end
end)

-- Save Fields
minetest.register_on_player_receive_fields(function(customer, formname, fields)
	if formname == "areas_pay_owner" and fields.save_fields_button ~= nil and fields.save_fields_button ~= "" then
		local pos = default.areas_pay_pos[customer:get_player_name()]
		local meta = minetest.get_meta(pos)
    if not areas:isAreaOwner(tonumber(fields.area_id_field), customer:get_player_name()) then
      minetest.chat_send_player(customer:get_player_name(), "You don't own that area!")
      areas_pay_show_spec(customer)
      return
    end
		if tonumber(fields.price_field) ~= nil then
			meta:set_int("areas_pay:price", fields.price_field)
		end
    if tonumber(fields.price_field) ~= nil then
      meta:set_int("areas_pay:area_id", fields.area_id_field)
    end
    if tonumber(fields.price_field) ~= nil then
      meta:set_int("areas_pay:period", fields.period_field)
    end
    minetest.close_formspec(customer:get_player_name(), "areas_pay_owner")
	end
end)

-- Buying
minetest.register_on_player_receive_fields(function(customer, formname, fields)
	if formname == "areas_pay_customer" and fields.buy_button ~= nil and fields.buy_button ~= "" then
		local pos = default.areas_pay_pos[customer:get_player_name()]
		local meta = minetest.get_meta(pos)
    if meta:get_int("areas_pay:area_id") == 0 then
      minetest.chat_send_player(customer:get_player_name(), "Shop unconfigured")
      minetest.close_formspec(customer:get_player_name(), "areas_pay_customer")
      return
    end
    -- Check if the customer has enough money, give him the area, and remove the block.
	  if jeans_economy_book(customer:get_player_name(), meta:get_string("owner"), meta:get_int("areas_pay:price"), customer:get_player_name().." buys the Area with the ID " .. meta:get_string("areas_pay:area_id").." from " .. meta:get_string("owner")) then
      minetest.chat_send_player(customer:get_player_name(), "Buyed successfully Area")
      areas_pay_change_owner(meta:get_string("owner"), meta:get_string("areas_pay:area_id").." "..customer:get_player_name() )
      minetest.remove_node(pos);
    else
      minetest.chat_send_player(customer:get_player_name(), "You dont have enough money, to buy this!")
    end
	end
  minetest.close_formspec(customer:get_player_name(), "areas_pay_customer")
end)

-- Rent
minetest.register_on_player_receive_fields(function(customer, formname, fields)
	if formname == "areas_pay_customer_rent" and fields.rent_button ~= nil and fields.rent_button ~= "" then
		local pos = default.areas_pay_pos[customer:get_player_name()]
		local meta = minetest.get_meta(pos)
    -- Check, if the area can be rented
    local rents = minetest.deserialize(storage:get_string("rents")) or {}
    local id = meta:get_int("areas_pay:area_id")
    if id == 0 then
      minetest.chat_send_player(customer:get_player_name(), "Shop unconfigured")
      minetest.close_formspec(customer:get_player_name(), "areas_pay_customer_rent")
      return
    end
    --       If the area is rented, and the time after renting is lower then two full periods
    if rents == nil or rents[id] == nil or (rents[id] ~= nil and (rents[id].rented_to + meta:get_int("areas_pay:period") - minetest.get_gametime()) < (meta:get_int("areas_pay:period") * MAX_RENT_PERIODS)) then
      -- Check if the customer has enough money, give him the area, and remove the block.
      local owner = meta:get_string("owner")
	    if jeans_economy_book(customer:get_player_name(), meta:get_string("owner"), meta:get_int("areas_pay:price"), customer:get_player_name().." buys the Area with the ID " .. meta:get_string("areas_pay:area_id").." from " .. meta:get_string("owner")) then
         -- Select, and create a new area
        if rents ~= nil and rents[id] ~= nil and rents[id].rentID ~= nil then
          areas_pay_remove_recursive_areas(owner, rents[id].rentID)
        end
        minetest.chat_send_player(customer:get_player_name(), "Rented area successfully")
        areas_pay_select_area(owner, meta:get_string("areas_pay:area_id"))
        local newID = areas_pay_add_owner(owner, meta:get_string("areas_pay:area_id").." "..customer:get_player_name().." Rented Area")
        -- Figure out rented_to time
        local rented_to = 0
        if rents == nil or rents[id] == nil or rents[id].rented_to < minetest.get_gametime() then
          rented_to = minetest.get_gametime() + meta:get_int("areas_pay:period") * 24 * 3600
        else
          rented_to = rents[id].rented_to + meta:get_int("areas_pay:period") * 24 * 3600
        end
        rents[id] = {owner = owner, customer = customer:get_player_name(), rented_to=rented_to, rentID=newID }
        storage:set_string("rents", minetest.serialize(rents))
        meta:set_string("areas_pay:customer", customer:get_player_name())
      else
        minetest.chat_send_player(customer:get_player_name(), "You dont have enough money, to buy this!")
      end
    else
      minetest.chat_send_player(customer:get_player_name(), "You can only rent the area !")

    end
	end
  minetest.close_formspec(customer:get_player_name(), "areas_pay_customer_rent")
end)



--------------------------------------------------------------------------------
-- Area Functions:
-- These are Functions from https://github.com/minetest-mods/areas
-- released under GNU LESSER GENERAL PUBLIC LICENSE   Version 2.1
--------------------------------------------------------------------------------
areas_pay_change_owner = function(name, param)
  local id, newOwner = param:match("^(%d+)%s(%S+)$")
  if not id then
    return false, "Invalid usage, see"
        .." /help change_owner."
  end

  if not areas:player_exists(newOwner) then
    return false, "The player \""..newOwner
        .."\" does not exist."
  end

  id = tonumber(id)
  if not areas:isAreaOwner(id, name) then
    return false, "Area "..id.." does not exist"
        .." or is not owned by you."
  end
  areas.areas[id].owner = newOwner
  areas:save()
  minetest.chat_send_player(newOwner,
    ("%s has given you control over the area %q (ID %d).")
      :format(name, areas.areas[id].name, id))
  return true, "Owner changed."
end

areas_pay_remove_recursive_areas = function (name, param)
	local id = tonumber(param)
	if not id then
		return false, "Invalid usage, see"
				.." /help recursive_remove_areas"
	end

	if not areas:isAreaOwner(id, name) then
		return false, "Area "..id.." does not exist or is"
				.." not owned by you."
	end
	areas:remove(id, true)
	areas:save()
	return true, "Removed area "..id.." and it's sub areas."
end

areas_pay_add_owner = function(name, param)
	local pid, ownerName, areaName
			= param:match('^(%d+) ([^ ]+) (.+)$')

	if not pid then
		minetest.chat_send_player(name, "Incorrect usage, see /help add_owner")
		return -1
	end

	local pos1, pos2 = areas:getPos(name)
	if not (pos1 and pos2) then
		return false, "You need to select an area first."
	end

	if not areas:player_exists(ownerName) then
		return -1, "The player \""..ownerName.."\" does not exist."
	end

	minetest.log("action", name.." runs /add_owner. Owner = "..ownerName..
			" AreaName = "..areaName.." ParentID = "..pid..
			" StartPos = "..pos1.x..","..pos1.y..","..pos1.z..
			" EndPos = "  ..pos2.x..","..pos2.y..","..pos2.z)

	-- Check if this new area is inside an area owned by the player
	pid = tonumber(pid)
	if (not areas:isAreaOwner(pid, name)) or
	   (not areas:isSubarea(pos1, pos2, pid)) then
		return -1
	end

	local id = areas:add(ownerName, areaName, pos1, pos2, pid)
	areas:save()

	return id
end

areas_pay_select_area = function(name, param)
	local id = tonumber(param)
	if not id then
		return false, "Invalid usage, see /help select_area."
	end
	if not areas.areas[id] then
		return false, "The area "..id.." does not exist."
	end

	areas:setPos1(name, areas.areas[id].pos1)
	areas:setPos2(name, areas.areas[id].pos2)
	return true, "Area "..id.." selected."
end
