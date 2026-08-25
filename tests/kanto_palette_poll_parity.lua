-- v0.3.59 cheap Gold palette invalidation probe regression.
-- Polling Kanto's material family must not walk the Johto PalMap unless an
-- actual daytime/color/palette input changed and a full profile is requested.

package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.render.GbcPalette"] = function()
  return { mode="gbc", resolve=function(colors) return colors end }
end
local paletteSet = {}
for slot=1,8 do
  paletteSet[slot] = { {255,255,255},{170,170,170},{85,85,85},{0,0,0} }
end
package.preload["src.world.gen2.Palettes"] = function()
  return {
    daytimeFor=function() return "DAY" end,
    bgSet=function() return paletteSet end,
  }
end

local Atlas = dofile("lib/GoldColorAtlas.lua")
local poisonPalMap = setmetatable({}, {
  __pairs=function() error("cheap palette poll walked the PalMap") end
})
local map = { def={ id="NEW_BARK_TOWN" }, tileset={ tilePalettes=poisonPalMap } }
local world = { map=map, game={ data={ gen2Palettes={} } } }

local day, mode, setRef, palMapRef, err = Atlas.worldPaletteInputs(world, map)
if err then error(err) end
if day ~= "DAY" or mode ~= "gbc" then error("cheap inputs lost daytime/mode") end
if setRef ~= paletteSet then error("cheap inputs lost palette-set identity") end
if palMapRef ~= poisonPalMap then error("cheap inputs lost PalMap identity") end

-- The full profile DOES inspect tilePalettes; this confirms the poison is a
-- meaningful guard and the cheap path above genuinely avoided that work.
local ok = pcall(Atlas.worldPaletteProfile, world, map)
if ok then error("full profile unexpectedly skipped PalMap analysis") end

print("kanto_palette_poll_parity: OK")
