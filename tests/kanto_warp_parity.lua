-- v0.3.45 regression: Yellow/Kanto map adapter + completed-step warp parity.
-- Self-contained: does not need a ROM cache and stubs renderer-only modules.

package.preload["src.render.Assets"] = function() return {} end

local mod = {
  exports = {},
  options = { get = function() return nil end },
  save = {
    get = function(_, _, fallback) return fallback end,
    set = function() return true end,
  },
  ui = {},
}

local FirstPerson = {
  driving = function() return false end,
  releaseBody = function() end,
}
local Quality = {
  kantoRadius = function() return 1 end,
  actorDistanceCells = function() return math.huge end,
}
local ChunkMesher = { warmPending = function() return 0 end }
local KantoGen2Style = { PROJECTION_REV = "test" }
local RuntimeSheets = {
  new = function()
    return { load = function() return true end }
  end,
}
local stubs = {
  Quality = Quality,
  FirstPerson = FirstPerson,
  ChunkMesher = ChunkMesher,
  KantoGen2Style = KantoGen2Style,
  runtime_sheets = RuntimeSheets,
}
local V = {
  mod = mod,
  require = function(name) return stubs[name] or {} end,
}

local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Map = assert(Twin._ForeignGen1Map)

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end

local function blockWithCells(c00, c10, c01, c11)
  local b = {}
  for i = 1, 16 do b[i] = 0 end
  -- collision tile is bottom-left tile of each 16x16 cell.
  b[5], b[7], b[13], b[15] = c00 or 0, c10 or 0, c01 or 0, c11 or 0
  return b
end

local function mapDef(id, tileset, warps, signs)
  return {
    id = id, width = 1, height = 1, borderBlock = 0, blocks = { 0 },
    tileset = tileset, warps = warps or {}, signs = signs or {},
  }
end

local function tileset(block, extra)
  extra = extra or {}
  return {
    id = extra.id or "TEST",
    blocks = { block },
    walkable = extra.walkable or { 0, 0x20, 0x11, 0x22, 0x33, 0x55 },
    doorTiles = extra.doorTiles or {},
    warpTiles = extra.warpTiles or {},
    counterTiles = extra.counterTiles or {},
    warpPadTiles = extra.warpPadTiles,
  }
end

-- Current Gen1Recomp Map.lua stale-cache warp-pad/hole classification.
do
  local def = mapDef("PAD_TEST", "FACILITY", {}, { { x = 1, y = 1, text = "SIGN" } })
  local map = Map.new(def, tileset(blockWithCells(0x20, 0x11, 0, 0)))
  eq(map:warpPadOrHoleAt(0, 0), "pad", "FACILITY $20 pad")
  eq(map:warpPadOrHoleAt(1, 0), "hole", "FACILITY $11 hole")
  eq(map:signAtCell(1, 1).text, "SIGN", "sign lookup")
end

-- Warp/sign indexing uses the map width exactly like current Map.lua, not the
-- old private adapter's arbitrary 1024-cell stride. A y>0 warp catches that.
do
  local def = mapDef("INDEX_TEST", "INTERIOR", {
    { x = 1, y = 1, destMap = "INDEX_TEST", destWarp = 1 },
  })
  local map = Map.new(def, tileset(blockWithCells(0, 0, 0, 0)))
  eq(map:warpAtCell(1, 1).index, 1, "width-based warp lookup")
end

do
  local def = mapDef("HOLE_TEST", "CAVERN")
  local map = Map.new(def, tileset(blockWithCells(0x22, 0, 0, 0)))
  eq(map:warpPadOrHoleAt(0, 0), "hole", "CAVERN $22 hole")
end

do
  local def = mapDef("PAD_TEST_2", "INTERIOR")
  local map = Map.new(def, tileset(blockWithCells(0x55, 0, 0, 0)))
  eq(map:warpPadOrHoleAt(0, 0), "pad", "INTERIOR $55 pad")
end

-- Ordinary door/warp-tile arrival remains the first arm. Holding the same
-- direction must not route a successful normal arrival through ExtraWarpCheck.
do
  local srcDef = mapDef("DOOR_SRC", "INTERIOR", {
    { x = 0, y = 0, destMap = "DOOR_DST", destWarp = 1 },
  })
  local dstDef = mapDef("DOOR_DST", "INTERIOR", {
    { x = 1, y = 1, destMap = "DOOR_SRC", destWarp = 1 },
  })
  local src = Map.new(srcDef, tileset(blockWithCells(0x44, 0, 0, 0),
    { warpTiles = { 0x44 } }))
  local dst = Map.new(dstDef, tileset(blockWithCells(0, 0, 0, 0)))
  local region = {
    mapsById = { DOOR_SRC = src, DOOR_DST = dst },
    recordBySource = {}, records = {},
    loaded = { maps = { DOOR_SRC = srcDef, DOOR_DST = dstDef }, field = {} },
  }
  Twin._setRegionCacheForTest(region)
  local e = Twin._excursionForTest
  e.active, e.region, e.sourceMapId = true, region, "DOOR_SRC"
  e.cellX, e.cellY, e.drawPx, e.drawPy, e.facing = 0, 0, 0, 0, "down"
  e.ignoreWarpKey, e.standingOnWarp = nil, false
  e.safari, e.surfing, e.forcedMoves, e.seafoamCurrentLock = nil, false, nil, false
  local world = { game = { input = { isDown = function(_, key) return key == "down" end } } }
  e.world = world
  eq(Twin._afterExcursionCellLanding(world), true, "ordinary warp-tile arrival consumed")
  eq(e.sourceMapId, "DOOR_DST", "ordinary arrival destination")
  eq(Twin.yellowExtraWarpArrivals, 0, "ordinary arrival not counted as extra warp")
end

-- Non-door warp on a carpet: stepping onto the warp cell with DOWN still
-- held must run ExtraWarpCheck and transition, matching CheckWarpsNoCollision.
do
  local srcDef = mapDef("SRC", "FACILITY", {
    { x = 0, y = 0, destMap = "DST", destWarp = 1 },
  })
  local dstDef = mapDef("DST", "INTERIOR", {
    { x = 1, y = 1, destMap = "SRC", destWarp = 1 },
  })
  local src = Map.new(srcDef, tileset(blockWithCells(0, 0, 0x33, 0)))
  local dst = Map.new(dstDef, tileset(blockWithCells(0, 0, 0, 0)))
  local region = {
    mapsById = { SRC = src, DST = dst },
    recordBySource = {}, records = {},
    loaded = {
      maps = { SRC = srcDef, DST = dstDef },
      field = {
        warpCarpets = {
          edgeMaps = {}, function2Maps = { "SRC" }, function2Tilesets = {},
          ssAnneBow = { map = "SS_ANNE_BOW", tile = 0x3B },
          tiles = { up = {}, down = { 0x33 }, left = {}, right = {} },
        },
      },
    },
  }
  Twin._setRegionCacheForTest(region)
  local e = Twin._excursionForTest
  e.active, e.region, e.sourceMapId = true, region, "SRC"
  e.cellX, e.cellY, e.drawPx, e.drawPy, e.facing = 0, 0, 0, 0, "down"
  e.ignoreWarpKey, e.standingOnWarp = nil, false
  e.safari, e.surfing, e.forcedMoves, e.seafoamCurrentLock = nil, false, nil, false
  local world = { game = { input = { isDown = function(_, key) return key == "down" end } } }
  e.world = world
  eq(Twin._afterExcursionCellLanding(world), true, "held-direction extra warp consumed")
  eq(e.sourceMapId, "DST", "extra warp destination map")
  eq(e.cellX, 1, "extra warp destination x")
  eq(e.cellY, 1, "extra warp destination y")
  eq(Twin.yellowExtraWarpArrivals, 1, "extra warp counter")
end

-- Story-free free roam still needs Victory Road's physical walkable hole.
do
  local fake3 = {
    def = { id = "VICTORY_ROAD_3F", tileset = "CAVERN", warps = {} },
    sourceId = "VICTORY_ROAD_3F",
    inBounds = function() return true end,
    isWalkableCell = function() return true end,
  }
  local fake2 = {
    def = { id = "VICTORY_ROAD_2F", tileset = "CAVERN", warps = {} },
    sourceId = "VICTORY_ROAD_2F",
    inBounds = function(_, x, y) return x >= 0 and y >= 0 and x < 40 and y < 40 end,
    isWalkableCell = function() return true end,
  }
  local region = {
    mapsById = { VICTORY_ROAD_3F = fake3, VICTORY_ROAD_2F = fake2 },
    recordBySource = {}, records = {},
    loaded = {
      maps = {
        VICTORY_ROAD_3F = fake3.def,
        VICTORY_ROAD_2F = fake2.def,
      },
      field = {},
    },
  }
  Twin._setRegionCacheForTest(region)
  local e = Twin._excursionForTest
  e.active, e.region, e.sourceMapId = true, region, "VICTORY_ROAD_3F"
  e.cellX, e.cellY, e.drawPx, e.drawPy, e.facing = 23, 15, 23 * 16, 15 * 16, "right"
  e.surfing, e.forcedMoves, e.seafoamCurrentLock = false, nil, false
  e.ignoreWarpKey, e.standingOnWarp = nil, false
  eq(Twin._applyDungeonHole(region, "VICTORY_ROAD_3F", 23, 15), true,
    "Victory Road physical hole")
  eq(e.sourceMapId, "VICTORY_ROAD_2F", "Victory Road hole destination map")
  eq(e.cellX, 22, "Victory Road hole destination x")
  eq(e.cellY, 16, "Victory Road hole destination y")
  eq(Twin.yellowDungeonFalls, 1, "dungeon fall counter")
end

print("kanto_warp_parity: OK")
