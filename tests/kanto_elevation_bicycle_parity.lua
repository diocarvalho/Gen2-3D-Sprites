-- v0.3.51 regression: Gen-1 tile-pair/elevation collision + manual Bicycle.
-- Self-contained; no ROM cache or renderer/GPU required.

package.preload["src.render.Assets"] = function() return {} end
_G.love = { math = { random = function(a) return a end } }

local backing = {}
local mod = {
  exports = {},
  options = { get = function() return nil end },
  save = {
    get = function(_, key, fallback)
      local value = backing[key]
      return value == nil and fallback or value
    end,
    set = function(_, key, value) backing[key] = value; return true end,
  },
}
local stubs = {
  Quality = { kantoRadius = function() return 1 end,
              actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end,
                  releaseBody = function() end },
  ChunkMesher = {},
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local e = Twin._excursionForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end

-- A tiny two-cell map where both destination tiles are ordinarily passable.
-- Only the extracted pair table can explain a refused step.
local tile = { [0] = 0x31, [1] = 0x44 }
local map = {
  id = "__GEN1__TEST_CAVE",
  sourceId = "TEST_CAVE",
  widthCells = 2, heightCells = 1,
  def = { id = "__GEN1__TEST_CAVE", sourceId = "TEST_CAVE",
          tileset = "CAVERN", width = 1, height = 1, objects = {} },
}
function map:inBounds(x, y) return y == 0 and x >= 0 and x < 2 end
function map:cellTile(x, y) return tile[x] end
function map:isPassableCell(x, y) return self:inBounds(x, y) end
function map:isWalkableCell(x, y) return self:inBounds(x, y) end
function map:warpAtCell() return nil end

local region = {
  loaded = {
    field = {
      tilePairs = {
        land = { { tileset = "CAVERN", a = 0x31, b = 0x44 } },
        water = { { tileset = "CAVERN", a = 0x31, b = 0x52 } },
      },
      bikeRiding = { tilesets = { "OVERWORLD", "CAVERN" },
                     maps = { "ROUTE_23", "INDIGO_PLATEAU" } },
      forcedMovement = { tiles = {}, slopeMaps = {}, clearMaps = {} },
    },
    maps = {
      TEST_CAVE = map.def,
      TEST_ROUTE = { id="TEST_ROUTE", tileset="OVERWORLD" },
      TEST_HOUSE = { id="TEST_HOUSE", tileset="HOUSE" },
      ROUTE_23 = { id="ROUTE_23", tileset="GATE" },
    },
  },
  mapsById = { TEST_CAVE = map },
  npcCache = { TEST_CAVE = {} },
  pokemonCache = { TEST_CAVE = {} },
  validOutdoor = {},
}

-- Collision.lua treats the pair symmetrically and chooses land/water tables
-- from mover.surfing. Match that exact contract in the private Yellow map.
do
  check(Twin._pairBlocked(region, map, 0, 0, 1, 0, false),
        "land elevation pair blocks forward")
  check(Twin._pairBlocked(region, map, 1, 0, 0, 0, false),
        "land elevation pair blocks reverse")
  check(not Twin._pairBlocked(region, map, 0, 0, 1, 0, true),
        "land pair alone does not block a surfer")

  e.surfing = false
  local id = Twin._moveCandidate(region, "TEST_CAVE", 0, 0, "right", {})
  eq(id, nil, "grid mover refuses otherwise-passable elevation edge")

  -- Indexed hot path returns the same verdict without rescanning the rows.
  region.fieldIndex = { tilePairs = { land = { CAVERN = {
    [0x31 * 256 + 0x44] = true,
  } }, water = {} } }
  check(Twin._pairBlocked(region, map, 0, 0, 1, 0, false),
        "pre-indexed pair lookup matches authored list")
end

local world = { game = { save = { inventory = { BICYCLE = 1 } } } }
e.active, e.region, e.sourceMapId = true, region, "TEST_ROUTE"
e.biking, e.forcedBike, e.surfing = false, false, false

-- IsBikeRidingAllowed: ordinary allowed tilesets plus explicit map exceptions.
do
  region.fieldIndex = nil -- exercise extracted-table fallback too
  check(Twin._bikeAllowed(region, "TEST_ROUTE"), "OVERWORLD allows cycling")
  check(Twin._bikeAllowed(region, "TEST_CAVE"), "CAVERN allows cycling")
  check(not Twin._bikeAllowed(region, "TEST_HOUSE"), "HOUSE refuses cycling")
  check(Twin._bikeAllowed(region, "ROUTE_23"), "Route 23 exception allows cycling")
end

-- Manual Kanto Bicycle toggles the same physical state used by Cycling Road.
do
  local ok, why = Twin._toggleBicycle(world)
  check(ok and not why, "Bicycle mounts on allowed Kanto map")
  check(e.biking and not e.forcedBike, "manual mount is not forced")

  e.forcedBike = true
  ok, why = Twin._toggleBicycle(world)
  check(not ok and tostring(why):find("can't get off", 1, true),
        "forced Cycling Road refuses dismount")
  check(e.biking, "forced refusal leaves rider mounted")

  e.forcedBike = false
  ok = Twin._toggleBicycle(world)
  check(ok and not e.biking, "manual Bicycle dismount works after forced lock clears")

  e.sourceMapId = "TEST_HOUSE"
  ok, why = Twin._toggleBicycle(world)
  check(not ok and tostring(why):find("No cycling", 1, true),
        "disallowed tileset refuses mount")
  check(not e.biking, "failed indoor mount does not change state")

  e.sourceMapId = "ROUTE_23"
  ok = Twin._toggleBicycle(world)
  check(ok and e.biking, "map exception mounts despite non-bike tileset")
end

print("kanto_elevation_bicycle_parity: OK")
