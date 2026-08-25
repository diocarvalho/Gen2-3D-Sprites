-- v0.3.46 regression: Yellow/Kanto ledges + exact connected-route overlap.
-- Self-contained: no ROM cache, no renderer, and no copyrighted map payload.

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
local stubs = {
  Quality = Quality,
  FirstPerson = FirstPerson,
  ChunkMesher = { warmPending = function() return 0 end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Map = assert(Twin._ForeignGen1Map)

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(value, label)
  if not value then error(label or "check failed", 2) end
end

local function fakeMap(id, widthCells, heightCells, tileset, tiles)
  local map = {
    id = id,
    sourceId = id,
    widthCells = widthCells,
    heightCells = heightCells,
    def = {
      id = id, tileset = tileset or "OVERWORLD",
      width = widthCells / 2, height = heightCells / 2,
      connections = {}, warps = {}, signs = {}, objects = {},
    },
  }
  function map:inBounds(x, y)
    return x >= 0 and y >= 0 and x < self.widthCells and y < self.heightCells
  end
  function map:cellTile(x, y)
    local key = tostring(x) .. ":" .. tostring(y)
    return (tiles and tiles[key]) or 0x01
  end
  function map:isPassableCell(x, y, surfing)
    return self:inBounds(x, y) and self:cellTile(x, y) ~= 0x37
      and self:cellTile(x, y) ~= 0x36
  end
  function map:isWalkableCell(x, y) return self:isPassableCell(x, y, false) end
  function map:isWaterCell() return false end
  function map:isGrassCell() return false end
  function map:warpAtCell() return nil end
  function map:isWarpTileCell() return false end
  function map:warpPadOrHoleAt() return nil end
  function map:signAtCell() return nil end
  function map:connection(dir) return self.def.connections and self.def.connections[dir] end
  return map
end

local LEDGES = {
  { tileset = "OVERWORLD", facing = "down", input = "down",
    standingTile = 0x39, ledgeTile = 0x37 },
  { tileset = "OVERWORLD", facing = "down", input = "down",
    standingTile = 0x39, ledgeTile = 0x36 },
}

local function regionFor(maps)
  local defs = {}
  local valid = {}
  for id, map in pairs(maps) do defs[id], valid[id] = map.def, true end
  return {
    mapsById = maps,
    recordBySource = {}, records = {},
    npcCache = {}, pokemonCache = {}, spriteCache = {},
    validOutdoor = valid,
    loaded = { maps = defs, field = { ledges = LEDGES }, encounters = {} },
  }
end

local function stand(region, mapId, x, y, facing)
  Twin._setRegionCacheForTest(region)
  local e = Twin._excursionForTest
  e.active, e.region, e.sourceMapId = true, region, mapId
  e.cellX, e.cellY = x, y
  e.drawPx, e.drawPy = x * 16, y * 16
  e.facing = facing or "down"
  e.surfing, e.moving = false, false
  e.freeActive, e.freeX, e.freeZ, e.freeMapId = false, nil, nil, nil
  e.toMapId, e.toCellX, e.toCellY = nil, nil, nil
  e.moveDurationCurrent = nil
  e.hopActive, e.hopProgress, e.hopLift, e.hopSeam = false, 0, 0, false
  e.ignoreWarpKey, e.standingOnWarp = nil, false
  e.safari, e.forcedMoves, e.seafoamCurrentLock = nil, nil, false
  e.battleBusy, e.trainerEngaging = false, false
  return e
end

local world = { game = { input = { isDown = function() return false end } } }

-- Connection offsets describe an overlap strip; a source coordinate outside
-- that overlap must be rejected, never clamped to the destination corner.
do
  local destDef = { id = "DEST", width = 2, height = 2 }
  local conn = { map = "DEST", offset = 2 }
  local x, y = Map.connectionLanding(destDef, conn, "down", 3, 0)
  eq(x, nil, "non-overlap route edge rejected")
  eq(y, nil, "non-overlap route edge has no y")
  x, y = Map.connectionLanding(destDef, conn, "down", 4, 0)
  eq(x, 0, "first overlapping source cell maps to destination x=0")
  eq(y, 0, "south seam lands on top row")
end

-- Ordinary authored ledge: one DOWN input travels two cells, and the hop state
-- supplies a vertical arc to the 3D player proxy.
do
  local map = fakeMap("LEDGE_MAP", 8, 8, "OVERWORLD", {
    ["2:2"] = 0x39, ["2:3"] = 0x37, ["2:4"] = 0x01,
  })
  local region = regionFor({ LEDGE_MAP = map })
  local e = stand(region, "LEDGE_MAP", 2, 2, "down")
  local before = Twin.yellowLedgeHops or 0
  check(Twin._tryStartLedgeHop(world, "down"), "authored DOWN ledge starts")
  eq(e.toMapId, "LEDGE_MAP", "in-map ledge keeps map")
  eq(e.toCellX, 2, "in-map ledge landing x")
  eq(e.toCellY, 4, "in-map ledge travels two cells")
  check(e.hopActive, "hop state active")
  check((e.moveDurationCurrent or 0) > e.moveDuration, "hop lasts longer than one step")
  eq(Twin.yellowLedgeHops, before + 1, "ledge counter increments")
  -- Reverse/side input is still blocked by the authored one-way row.
  e = stand(region, "LEDGE_MAP", 2, 2, "left")
  check(not Twin._tryStartLedgeHop(world, "left"), "wrong direction does not hop")
end

-- Synthetic equivalent of the real Route 4 south ledge: source (13,16),
-- front ledge at (13,17), two-cell landing crosses the connection whose
-- offset is -25, yielding Route 3 (63,0), exactly like Gen1Recomp's parity test.
do
  local source = fakeMap("ROUTE_4", 80, 18, "OVERWORLD", {
    ["13:16"] = 0x39, ["13:17"] = 0x37,
  })
  local dest = fakeMap("ROUTE_3", 80, 18, "OVERWORLD", {})
  source.def.connections.south = { map = "ROUTE_3", offset = -25 }
  dest.def.connections.north = { map = "ROUTE_4", offset = 25 }
  local region = regionFor({ ROUTE_4 = source, ROUTE_3 = dest })
  local e = stand(region, "ROUTE_4", 13, 16, "down")
  local seamBefore = Twin.yellowLedgeSeamHops or 0
  local mapId, x, y, seam = Twin._ledgeLanding(region, "ROUTE_4", 13, 16, "down")
  eq(mapId, "ROUTE_3", "seam ledge destination map")
  eq(x, 63, "Route 4 ledge destination x")
  eq(y, 0, "Route 4 ledge destination y")
  eq(seam, true, "seam ledge flagged")
  check(Twin._tryStartLedgeHop(world, "down"), "seam ledge starts")
  eq(e.toMapId, "ROUTE_3", "hop queues Route 3")
  eq(e.toCellX, 63, "hop queues exact Route 3 x")
  eq(e.toCellY, 0, "hop queues exact Route 3 y")
  eq(e.toPx, e.fromPx, "south seam hop keeps x interpolation continuous")
  eq(e.toPy, e.fromPy + 32, "south seam hop visually travels two cells")
  eq(Twin.yellowLedgeSeamHops, seamBefore + 1, "seam ledge counter increments")
end

-- A shifted route edge outside its true overlap must fail through the live
-- movement candidate too, not merely through the pure equation helper.
do
  local source = fakeMap("WIDE", 12, 4, "OVERWORLD", {})
  local dest = fakeMap("NARROW", 4, 4, "OVERWORLD", {})
  source.def.connections.south = { map = "NARROW", offset = 2 }
  local region = regionFor({ WIDE = source, NARROW = dest })
  stand(region, "WIDE", 3, 3, "down") -- dest x = -1: outside overlap
  local before = Twin.kantoConnectionEdgeRejects or 0
  local mapId = Twin._moveCandidate(region, "WIDE", 3, 3, "down", world)
  eq(mapId, nil, "live non-overlap handoff rejected")
  eq(Twin.kantoConnectionEdgeRejects, before + 1, "edge-reject diagnostic increments")
end

print("kanto_ledge_route_parity: OK")
