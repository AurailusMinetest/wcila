wcila = {}
wcila.huds = {}
local show_image = true

function wcila.update(player)
   local loc = player:getpos()
   local hor = math.rad(math.deg(player:get_look_horizontal()) + 90)
   local ver = math.rad(math.deg(player:get_look_vertical()) + 90)

   local name
   local xmod, ymod, zmod = 0, 0, 0
   for i = 0,4,0.5 do
      xmod = i * math.sin(ver) * math.cos(hor)
      zmod = i * math.sin(ver) * math.sin(hor) --y
      ymod = i * math.cos(ver) --z
      name = minetest.get_node({x = loc.x + xmod, y = loc.y + 1.65 + ymod, z = loc.z + zmod}).name
      if name ~= "air" then break end
   end

   if name == "air" then name = "" end
   local display_name = name
   if name ~= "" and minetest.registered_items[name].description ~= "" then display_name = minetest.registered_items[name].description end
   local s = 0
   if name ~= "" then s = 1 end
   local image = ""
   if show_image then
      if minetest.registered_items[name] and minetest.registered_items[name].tiles then
         if minetest.registered_items[name].tiles[1] and type(minetest.registered_items[name].tiles[1]) ~= "table" then
            image = minetest.registered_items[name].tiles[1]
         end
      end
   end

   if not wcila.huds[player:get_player_name()] then
      local elems = {}
      elems.bg = player:hud_add({
         hud_elem_type = "image",
         position = {x = 0.5, y = 0},
         scale = {x = s, y = s},
         name = "WAILA Background",
         text = "wcila_bg.png",
         alignment = 0,
         offset = {x = 0, y = 34},
         direction = 0
      })
      elems.tooltip = player:hud_add({
         hud_elem_type = "text",
         position = {x = 0.5, y = 0},
         scale = {x = 100, y = 100},
         number = 0xFFFFFF,
         alignment = 0,
         offset = {x = 20, y = 22},
         direction = 0,
         name = "WAILA Display Nmae",
         text = display_name,
      })
      elems.technical = player:hud_add({
         hud_elem_type = "text",
         position = {x = 0.5, y = 0},
         scale = {x = 100, y = 100},
         number = 0xCCCCCC,
         alignment = 0,
         offset = {x = 20, y = 42},
         direction = 0,
         name = "WAILA Technical Name",
         text = name,
      })
      if show_image then
         elems.img = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0},
            scale = {x = s, y = s},
            name = "WAILA Block Picture",
            text = "",
            alignment = 0,
            offset = {x = -(100 / 2 * 3), y = 33},
            direction = 0
         })
      end
      wcila.huds[player:get_player_name()] = elems
   else
      local elems = wcila.huds[player:get_player_name()]
      player:hud_change(elems.bg, "scale", {x = s * 3, y = s * 3})
      player:hud_change(elems.tooltip, "text", display_name)
      player:hud_change(elems.technical, "text", name)
      if show_image then 
         player:hud_change(elems.img, "text", tostring(image)) 
         player:hud_change(elems.img, "scale", {x = s * 2.5, y = s * 2.5})
      end
   end
end

-- Register Update
local time = 0
local incr = 0.15
minetest.register_globalstep(function(dtime)
   time = time + dtime
   if time > incr then
      time = time - incr
      for _,player in ipairs(minetest.get_connected_players()) do
         if player and player:is_player() then
            wcila.update(player)
         end
      end
   end
end)

--Register Leave Clearing
minetest.register_on_leaveplayer(function (player)
   wcila.huds[player:get_player_name()] = nil
end)
