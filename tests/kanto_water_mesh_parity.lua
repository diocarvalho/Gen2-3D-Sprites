-- v0.3.80 regression: private Yellow/Kanto water must stay flat geometry and
-- water-facing off-map edges must not become the shared Gen-1 tree-wall apron.
package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.render.Assets"] = function()
  return { imageData = function() return nil end, register = function() end }
end
package.preload["src.render.TileRenderer"] = function()
  return {
    voidFill = "trees",
    borderBlockFor = function(map) return map.def and map.def.borderBlock end,
    defaultAnimatedTiles = function() return {} end,
  }
end
package.preload["src.world.gen2.Map"] = function()
  return { isOutdoor = function(def) return def and def.outdoor == true end }
end

local profile = {
  heights = {
    ground=0, water=-2, void=0, ledge=6, fence=10, sign=12, wall=16,
    tree=16, cliff=32, shell=32, waterfall=32, terrace=16, roof=28,
    cylinder=16, canopy=32, stump=16, can=9, planter=32,
    billboard=16, signpost=16, post=16, column=32, grass=0, flower=0,
    bed=7, stool=8, counter=8, backrest=12, table=12, desk=24,
    prop=16, cutout=16, bike=16, console=16, relief=3, bookcase=32,
    stair_e=16, stair_w=16, stair_down_e=16, stair_down_w=16,
  },
  tilesets = {
    TEST_KANTO = {
      -- Deliberately author the water graphic as a standing cylinder. The
      -- private Kanto water-cell rule must still flatten it.
      cylinder = { 20 },
    },
  },
  buildings = {},
}

local Vshape = {
  data = function(name)
    assert(name == "voxel_heights")
    return profile
  end,
}
local TileShape = assert(loadfile("lib/TileShape.lua"))(Vshape)

local map = {
  _stadiumForeignGen1Map = true,
  id = "__GEN1__TEST_WATER",
  def = { outdoor = true, tileset = "OVERWORLD" },
  tileset = {
    id = "TEST_KANTO", imageWidth = 128, imageHeight = 48, tilesPerRow = 16,
    waterTiles = { 20 }, walkable = {}, animatedTiles = {},
  },
  isWaterCell = function(_, cx, cy) return cx == 0 and cy == 0 end,
  isWalkableCell = function() return false end,
  cellTile = function() return 20 end,
  tileAt = function() return 20 end,
}
local shapes = TileShape.forMap(map)
assert(shapes[20] and shapes[20].class == "cylinder",
  "probe must start with an authored standing donor/profile shape")
local resolved = TileShape.at(map, shapes, 20, 0, 0)
assert(resolved and resolved.class == "water" and resolved.h == -2 and resolved.flat == true,
  "private Kanto Surf cell must override projected/authored solid geometry")

-- Native/Johto-style maps keep authored priority; the safety rule is Kanto-only.
map._stadiumForeignGen1Map = false
local nativeResolved = TileShape.at(map, shapes, 20, 0, 0)
assert(nativeResolved and nativeResolved.class == "cylinder",
  "native map authored geometry must remain unchanged")

-- Load Structures only to exercise its pure water-edge seam. Heavy builders
-- are stubbed because the helper itself performs no rendering or profile work.
local Vstruct = {
  require = function(name)
    if name == "Buildings" then return { build = function() end } end
    if name == "TileShape" then return TileShape end
    if name == "BuildBudget" then return { tick=function() end, check=function() end } end
    error("unexpected V.require: " .. tostring(name))
  end,
  data = function(name) return profile end,
}
local Structures = assert(loadfile("lib/Structures.lua"))(Vstruct)
local edgeMap = {
  _stadiumForeignGen1Map = true,
  isWaterCell = function(_, cx, cy)
    -- Only the east edge is water.
    return cx == 3 and cy >= 0 and cy <= 3
  end,
}
assert(Structures._foreignEdgeWater(edgeMap, 8, 2, 8, 8) == true,
  "off-body tile beside a Kanto water edge must extend as water")
assert(Structures._foreignEdgeWater(edgeMap, -1, 2, 8, 8) == false,
  "non-water Kanto edge must not be converted to water")
assert(Structures._foreignEdgeWater(edgeMap, 7, 2, 8, 8) == false,
  "in-body tiles are never synthetic edge-water fill")
edgeMap._stadiumForeignGen1Map = false
assert(Structures._foreignEdgeWater(edgeMap, 8, 2, 8, 8) == false,
  "Johto/native maps must not use the Kanto edge-water override")

print("kanto_water_mesh_parity: ok")
