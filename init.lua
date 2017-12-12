wcila = {}
wcila.huds = {}
local show_image = true

--Check WCILA Visibility
local function wcila_visible(node, nodepos, player)
   if vector.distance(player:getpos(), nodepos) > 5 then
      return false
   end

   if node == "air" then return false end
   local def = minetest.registered_items[node]

   --To prevent a crash from unknown nodes
   if def == nil then return false end

   --Check if the Player is holding down the sneak key, if they are then show all nodes
   if player:get_player_control().sneak == false then
      if def.drawtype == "airlike" or def.drawtype == "liquid" or def.drawtype == "flowingliquid" then return false end
      if def.groups.not_wcila_visible and defs.groups.not_wcila_visible ~= 0 then return false end
      return true
   else
      return true
   end
end

--Create WCILA Hud
local function create_wcila_hud(player)
   local elems = {}
   elems.bg = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0},
      scale = {x = 0, y = 0},
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
      name = "WAILA Display Name",
      text = "",
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
      text = "",
   })
   elems.img = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0},
      scale = {x = 0, y = 0},
      name = "WAILA Block Image",
      text = "",
      alignment = 0,
      offset = {x = -(100 / 2 * 3), y = 32.5},
      direction = 0
   })

   wcila.huds[player:get_player_name()] = elems
end

--Detect and show block
function wcila.update(player)
   local name
   local dir = player:get_look_dir()
   local pos = vector.add(player:getpos(),{x=0,y=1.625,z=0})

   --TODO check if raycast is implemented yet
   local has_sight, node_pos = minetest.line_of_sight(pos, vector.add(pos,vector.multiply(dir,40)),0.3)

   if node_pos == nil then 
      name = "";
   else
      name = minetest.get_node(node_pos).name
   end

   if not wcila_visible(name, node_pos, player) then name = "" end
   local display_name = ""
   if name ~= "" and minetest.registered_items[name].description ~= "" then display_name = minetest.registered_items[name].description end
   local s = 0
   local techoff = 42
   local iscale = 1
   if name ~= "" then s = 1 end
   if display_name == "" then techoff = 32 end
   local image = ""
   if minetest.registered_items[name] and minetest.registered_items[name].tiles then
      if minetest.registered_items[name].tiles[1] then
         local dt = minetest.registered_items[name].drawtype
         if dt == "normal" or dt == "allfaces" or dt == "allfaces_optional"
         or dt == "glasslike" or dt =="glasslike_framed" or dt == "glasslike_framed_optional"
         or dt == "liquid" or dt == "flowingliquid" then
            local tiles = minetest.registered_items[name].tiles

            local top = tiles[1]
            if (type(top) == "table") then top = top.name end
            local left = tiles[3]
            if (type(left) == "table") then left = left.name
            else left = top end
            local right = tiles[5]
            if (type(right) == "table") then right = right.name
            else right = left end

            image = minetest.inventorycube(top, left, right)
            iscale = 0.3
         else
            image = minetest.registered_items[name].tiles[1]
         end
      end
   end

   if not wcila.huds[player:get_player_name()] then
      create_wcila_hud(player)
   else
      local elems = wcila.huds[player:get_player_name()]
      player:hud_change(elems.bg, "scale", {x = s * 3, y = s * 3})
      player:hud_change(elems.tooltip, "text", display_name)
      player:hud_change(elems.technical, "text", name)
      player:hud_change(elems.technical, "offset", {x = 20, y = techoff})
      player:hud_change(elems.img, "text", tostring(image))
      player:hud_change(elems.img, "scale", {x = s * 2.5 * iscale, y = s * 2.5 * iscale})
   end
end

-- Register Update
local time = 0
local incr = 0.1
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