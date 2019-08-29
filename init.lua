
----------------------------------------------------------------------------
-- Area Sell/Rent Block
----------------------------------------------------------------------------
default.areas_pay_pos = {}
minetest.register_node("areas_pay:shop_block", {

    description = "Area Shop Block",
		tiles = {"shop_licenses_top.png",
				"shop_licenses_top.png",
				"shop_licenses.png",
				"shop_licenses.png",
				"shop_licenses.png",
				"shop_licenses.png",},
    is_ground_content = true,
		-- light_source = 10,
    groups = {dig_immediate=2},
    sounds = default.node_sound_stone_defaults(),
-- Registriere den Owner beim Platzieren:
    after_place_node = function(pos, placer, itemstack)
      local meta = minetest.get_meta(pos)
			meta:set_string("areas_pay:rs", "Sell")
			meta:set_int("areas_pay:price", 0)
      meta:set_int("areas_pay:area_id", 0)
      meta:set_int("areas_pay:period", 7)
      meta:set_string("areas_pay:status", "still to have")
      meta:set_string("owner", placer:get_player_name())
    end,
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
      default.areas_pay_pos[player:get_player_name()] = pos
      show_spec(player)
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

show_spec = function (player)
    local pos = default.areas_pay_pos[player:get_player_name()]
    local meta = minetest.get_meta(pos)
    local listname = "nodemeta:"..pos.x..','..pos.y..','..pos.z
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
    else
      minetest.show_formspec(player:get_player_name(), "areas_pay:areas_pay_license_atm", "size[8,7.5]"..
      "label[0,0;Welcome, "..player:get_player_name().."]" ..
      "label[0,0.5;Items:]" ..
      "list["..listname..";einnahme;0,1;2,2;]"..
			"label[2.5,0;License required: "..licenses_required.."]" ..
      "label[5.7,1.45;Price: "..meta:get_string("areas_pay:price").."]" ..
			"label[5.7,1.8;Your Balance: "..atm.balance[player:get_player_name()].."]" ..
      "list[current_player;main;0,3.5;8,4;]" ..
      "button[3,1.5;2,1;buy_sell;"..meta:get_string("areas_pay:rs").."]"
    )
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
-- 	-- Do the thing:
-- 		-- BUY:
-- 		if meta:get_string("areas_pay:rs") == "Buy" then
-- 			if enough_space and allowed then
-- 				local item_name = "Nothing"
-- 				local item_count = 1
-- 				for i, item in pairs(items) do
-- 					pinv:add_item("main",item)
-- 					if item_name == "Nothing" or item_name == "" then
-- 						item_name = item:get_name()
-- 						item_count = item:get_count()
-- 					 end
-- 				end
-- 				if jeans_economy then
-- 					jeans_economy_save(customer:get_player_name(), "Server", meta:get_int("areas_pay:price"), customer:get_player_name().." buys "..item_count.." "..item_name.." at the areas_pay")
-- 				end
-- 				atm.balance[customer:get_player_name()] = atm.balance[customer:get_player_name()] - meta:get_int("areas_pay:price")
-- 				show_spec(customer)
-- 				meta:set_int("areas_pay:counter", meta:get_int("areas_pay:counter") + 1)
-- 			elseif not allowed then
-- 				minetest.chat_send_player(customer:get_player_name(),"You are not allowed to buy this!" )
-- 			elseif not enough_space then
-- 				minetest.chat_send_player(customer:get_player_name(),"You don't have enough space in your inventory!")
-- 			end
-- 		-- SELL:
-- 		else
-- 			if allowed and enough_items then
-- 				local item_name = "Nothing"
-- 				local item_count = 1
-- 				for i, item in pairs(items) do
-- 			 	 pinv:remove_item("main",item)
-- 				 if item_name == "Nothing" or item_name == "" then
-- 					 item_name = item:get_name()
-- 					 item_count = item:get_count()
-- 			 		end
-- 			  end
-- 				if jeans_economy then
-- 					jeans_economy_save("Server", customer:get_player_name(), meta:get_int("areas_pay:price"), customer:get_player_name().." sells "..item_count.." "..item_name.." to the areas_pay")
-- 				end
-- 				atm.balance[customer:get_player_name()] = atm.balance[customer:get_player_name()] + meta:get_int("areas_pay:price")
-- 				show_spec(customer)
-- 				meta:set_int("areas_pay:counter", meta:get_int("areas_pay:counter") + 1)
-- 			elseif not allowed then
-- 				minetest.chat_send_player(customer:get_player_name(),"You are not allowed to buy this!" )
-- 			else
-- 				minetest.chat_send_player(customer:get_player_name(),"You don't have the required items in your inventory!" )
-- 			end
--
-- 		end
-- 		atm.saveaccounts()
--   end
-- end)
--
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
		show_spec(customer)
	end
end)

-- Set Price
minetest.register_on_player_receive_fields(function(customer, formname, fields)
	if formname == "areas_pay_owner" and fields.save_fields_button ~= nil and fields.save_fields_button ~= "" then
		local pos = default.areas_pay_pos[customer:get_player_name()]
		local meta = minetest.get_meta(pos)
		if tonumber(fields.price_field) ~= nil then
			meta:set_int("areas_pay:price", fields.price_field)
		end
    if tonumber(fields.price_field) ~= nil then
      meta:set_int("areas_pay:area_id", fields.area_id_field)
    end
    if tonumber(fields.price_field) ~= nil then
      meta:set_int("areas_pay:period", fields.period_field)
    end
		show_spec(customer)
	end
end)
