-- v0.3.62 Kanto completed-step hot-path regression.
-- Verifies ordinary landings skip warp resolution/tile work, warp bounce
-- suppression uses scalar fields, encounter-option reads are cached, and Surf
-- passability consumes one cached collision tile.

package.preload["src.render.Assets"] = function() return {} end

local optionValue = false
local optionReads = 0
local mod = {
  exports = {},
  options = { get = function(_, key)
    if key == "random_encounters" then
      optionReads = optionReads + 1
      return optionValue
    end
    return nil
  end },
  save = {
    get = function(_, _, fallback) return fallback end,
    set = function() return true end,
  },
  ui = {},
}
local stubs = {
  Quality = { kantoRadius=function() return 1 end, actorDistanceCells=function() return math.huge end },
  FirstPerson = { driving=function() return false end, releaseBody=function() end },
  ChunkMesher = { warmPending=function() return 0 end },
  KantoGen2Style = { PROJECTION_REV="test" },
  runtime_sheets = { new=function() return { load=function() return true end } end },
}
local V = { mod=mod, require=function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Map = assert(Twin._ForeignGen1Map)
local e = Twin._excursionForTest

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end
local function block(tile)
  local t = {}
  for i=1,16 do t[i]=tile end
  return t
end

-- ---- 1. Surf passability reads one collision tile -----------------------
do
  local def = {
    id="SURF_FAST", width=1, height=1, borderBlock=0, blocks={0},
    tileset="OVERWORLD", warps={}, signs={}, objects={}, connections={},
  }
  local tileset = {
    blocks={block(0x14)}, walkable={}, waterTiles={0x14},
    doorTiles={}, warpTiles={}, counterTiles={},
  }
  local map = Map.new(def, tileset)
  local original = map.cellTile
  local reads = 0
  map.cellTile = function(self,x,y) reads=reads+1; return original(self,x,y) end
  check(map:isPassableCell(0,0,true), "water cell is Surf-passable")
  eq(reads, 1, "Surf passability reads cached collision tile exactly once")
end

-- ---- 2. warp bounce arm is scalar, legacy string still accepted --------
do
  Twin._clearWarpIgnore()
  Twin._setWarpIgnore("TEST_MAP", 7, 9)
  eq(e.ignoreWarpMap, "TEST_MAP", "scalar warp map stored")
  eq(e.ignoreWarpX, 7, "scalar warp x stored")
  eq(e.ignoreWarpY, 9, "scalar warp y stored")
  eq(type(e.ignoreWarpKey), "boolean", "normal runtime does not allocate a string warp key")
  check(Twin._warpIgnoreMatches("TEST_MAP",7,9), "scalar warp ignore matches destination cell")
  check(not Twin._warpIgnoreMatches("TEST_MAP",7,10), "scalar warp ignore rejects another cell")

  Twin._clearWarpIgnore()
  e.ignoreWarpKey = "LEGACY:2:3"
  check(Twin._warpIgnoreMatches("LEGACY",2,3), "legacy string warp key remains compatible")
  Twin._clearWarpIgnore()
end

-- ---- 3. random-encounter option bridge is cached until UI invalidation --
do
  optionReads, optionValue = 0, false
  Twin._invalidateEncounterOptionCache()
  check(not Twin._classicRandomEncountersEnabled(), "first encounter option read is false")
  check(not Twin._classicRandomEncountersEnabled(), "second encounter option read reuses cache")
  eq(optionReads, 1, "options bridge crossed once while unchanged")
  optionValue = true
  check(not Twin._classicRandomEncountersEnabled(), "cached value remains stable during gameplay")
  eq(optionReads, 1, "external value change does not add per-step bridge traffic")
  Twin._invalidateEncounterOptionCache()
  check(Twin._classicRandomEncountersEnabled(), "menu/invalidation refresh sees changed option")
  eq(optionReads, 2, "refresh crosses options bridge once")
end

-- ---- 4. ordinary completed cell probes warp index once and skips tiles --
do
  local def = {
    id="PLAIN_MAP", width=2, height=2, borderBlock=0, blocks={0,0,0,0},
    tileset="OVERWORLD", warps={}, signs={}, objects={}, connections={},
  }
  local tileset = {
    blocks={block(0x01)}, walkable={0x01}, waterTiles={},
    doorTiles={}, warpTiles={}, counterTiles={}, grassTile=0x52,
  }
  local map = Map.new(def, tileset)
  local warpReads, tileReads = 0, 0
  local realWarpAt, realCellTile = map.warpAtCell, map.cellTile
  map.warpAtCell = function(self,x,y) warpReads=warpReads+1; return realWarpAt(self,x,y) end
  map.cellTile = function(self,x,y) tileReads=tileReads+1; return realCellTile(self,x,y) end

  local region = {
    loaded={
      maps={PLAIN_MAP=def}, tilesets={OVERWORLD=tileset},
      encounters={}, field={}, text={},
    },
    mapsById={PLAIN_MAP=map}, validOutdoor={PLAIN_MAP=true},
    fieldIndex=Twin._buildKantoFieldIndex({}),
    npcCache={PLAIN_MAP={}}, pokemonCache={PLAIN_MAP={}},
    spritePixels={}, spriteSheets={},
  }
  e.active=true; e.region=region; e.world={game={save={player={}}}}
  e.sourceMapId="PLAIN_MAP"; e.cellX=1; e.cellY=1; e.facing="down"
  e.surfing=false; e.biking=false; e.forcedBike=false; e.forcedMoves=nil
  e.seafoamCurrentLock=false; e.safari=nil; e.battleBusy=false; e.trainerEngaging=false
  Twin._clearWarpIgnore()
  Twin._invalidateEncounterOptionCache()
  local before = Twin.kantoWarpLandingFastSkips or 0
  check(not Twin._afterExcursionCellLanding(e.world), "plain landing has no battle/warp ownership")
  eq(Twin.kantoWarpLandingFastSkips, before+1, "ordinary landing takes warp fast-skip")
  eq(warpReads, 1, "ordinary landing probes O(1) warp index exactly once")
  eq(tileReads, 0, "ordinary non-warp landing performs no warp collision-tile work")
end

print("kanto_step_landing_hotpath_parity: OK")
