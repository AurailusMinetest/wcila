wcila = {}
wcila.huds = {}
local show_image = true

--Check WCILA Visibility
local function wcila_visible(node)
   if node == "air" then return false end
   local def = minetest.registered_items[node]
   if def.drawtype == "airlike" or def.drawtype == "liquid" or def.drawtype == "flowingliquid" then return false end
   if def.groups.not_wcila_visible and defs.groups.not_wcila_visible ~= 0 then return false end
   return true
end

local function getFirstTex(tex) 
   -- string.sub(tex, 1, 
   tex = string.sub(tex, 1, (string.find(tex, '^', 1, true) or string.len(tex)+1)-1)
   return tex
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
   elems.img = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0},
      scale = {x = s, y = s},
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
      if wcila_visible(name) then break end
   end

   if not wcila_visible(name) then name = "" end
   local display_name = ""
   if name ~= "" and minetest.registered_items[name].description ~= "" then display_name = minetest.registered_items[name].description end
   local s = 0
   local techoff = 42
   local iscale = 1
   if name ~= "" then s = 1 end
   if display_name == "" then techoff = 32 end
   local image = ""
   if minetest.registered_items[name] and minetest.registered_items[name].tiles then
      if minetest.registered_items[name].tiles[1] and type(minetest.registered_items[name].tiles[1]) ~= "table" then
         local dt = minetest.registered_items[name].drawtype
         if dt == "normal" or dt == "allfaces" or dt == "allfaces_optional" 
         or dt == "glasslike" or dt =="glasslike_framed" or dt == "glasslike_framed_optional" 
         or dt == "liquid" or dt == "flowingliquid" then
            local tiles = minetest.registered_items[name].tiles 
            
            local top = tiles[1]
            if (type(top) == "table") then top = getFirstTex(top.name) else
               if top then
                  top = getFirstTex(top)
               end
            end
            local left = tiles[3]
            if (type(left) == "table") then left = getFirstTex(left.name) else
               if left then
                  left = getFirstTex(left)
               else left = top end
            end
            local right = tiles[5]
            if (type(right) == "table") then right = getFirstTex(right.name) else
               if right then
                  right = getFirstTex(right)
               else right = left end
            end
            
            image = "[inventorycube{" .. top .. "{" .. left .. "{" .. right
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