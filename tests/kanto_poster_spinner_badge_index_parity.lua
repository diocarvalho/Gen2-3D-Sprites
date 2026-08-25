-- v0.3.52 regression: Game Corner Rocket poster physical geometry plus
-- pre-indexed spinner / badge-gate lookups. Self-contained, no ROM/GPU needed.

package.preload["src.render.Assets"] = function() return {} end
local played = {}
package.preload["src.core.Sound"] = function()
  return { play = function(_, id) played[#played + 1] = id end }
end
_G.love = { math = { random = function(a) return a end } }

local backing = {}
local refreshes = 0
local TextBox = {
  new = function(_, text, onDone)
    if onDone then onDone() end
    return { text = text }
  end,
}
local mod = {
  exports = {},
  options = { get = function() return nil end },
  ui = { TextBox = TextBox },
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
  ChunkMesher = { refresh = function() refreshes = refreshes + 1 end },
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

local poster = {
  map = "GAME_CORNER", x = 8, y = 2,
  closedBlock = 0x2A, openBlock = 0x43,
  event = "EVENT_FOUND_ROCKET_HIDEOUT",
  posterText = "TEXT_GAMECORNER_POSTER",
}
local field = {
  gameCornerPoster = poster,
  spinners = {
    VIRIDIAN_GYM = {
      { x = 4, y = 5, moves = { { dir = "right", count = 2 } } },
    },
  },
  badgeGates = {
    ROUTE_23 = {
      failText = "_Route23GuardText",
      guards = { { y = 10, maxX = 5, badge = "EARTHBADGE" } },
    },
    ROUTE_22_GATE = {
      failText = "_Route22GuardText", badge = "BOULDERBADGE",
      coords = { { x = 4, y = 3 } },
    },
  },
  forcedMovement = { tiles = {}, slopeMaps = {}, clearMaps = {} },
}

-- The imported map body ships closed. applyPhysicalBlocks must also repair a
-- stale/open private map back to $2a before the switch and to $43 afterwards.
do
  local def = { width = 10, height = 4, blocks = {} }
  for i = 1, def.width * def.height do def.blocks[i] = 0 end
  local region = { loaded = { field = field, maps = { GAME_CORNER = def } } }
  Twin._setKantoEvent(poster.event, false)
  Twin._applyPhysicalBlocks(region, "GAME_CORNER", def)
  eq(def.blocks[poster.y * def.width + poster.x + 1], 0x2A,
     "poster entrance starts closed")
  Twin._setKantoEvent(poster.event, true)
  Twin._applyPhysicalBlocks(region, "GAME_CORNER", def)
  eq(def.blocks[poster.y * def.width + poster.x + 1], 0x43,
     "poster event restores open stairs geometry")
end

-- Pressing the poster is story-free but keeps the cartridge's two sounds,
-- persistent event, and live block refresh.
do
  Twin._setKantoEvent(poster.event, false)
  played, refreshes = {}, 0
  local blocks = { [poster.y * 10 + poster.x + 1] = 0x2A }
  local map = {
    id = "__GEN1__GAME_CORNER", sourceId = "GAME_CORNER",
    def = { width = 10, height = 4 },
  }
  function map:blockAt(x, y) return blocks[y * 10 + x + 1] end
  function map:setBlock(x, y, block) blocks[y * 10 + x + 1] = block; return true end
  local region = {
    loaded = { field = field, maps = { GAME_CORNER = map.def } },
    mapsById = { GAME_CORNER = map },
  }
  local stack = { push = function() end }
  local world = { game = { data = {}, stack = stack, save = {} } }
  local before = Twin.yellowGameCornerPosterOpens or 0
  check(Twin._openGameCornerPoster(world, region, map), "poster interaction consumed")
  check(Twin._kantoEvent(poster.event), "poster sets physical event")
  eq(map:blockAt(8, 2), 0x43, "poster opens live block")
  eq(refreshes, 1, "poster causes one voxel chunk refresh")
  eq(played[1], "Switch", "poster plays switch SFX")
  eq(played[2], "Go_Inside", "stairs opening plays Go_Inside")
  eq(Twin.yellowGameCornerPosterOpens, before + 1, "poster open diagnostic increments")

  played, refreshes = {}, 0
  check(Twin._openGameCornerPoster(world, region, map), "re-reading opened poster consumed")
  eq(refreshes, 0, "already-open poster does not rebuild terrain")
  eq(#played, 0, "already-open poster does not replay opening sounds")
end


-- Existing saves that already beat the poster Rocket must not remain blocked
-- forever just because v0.3.52 introduced the object-hide state later.
do
  local rocket = { index = 7, text = "TEXT_GAMECORNER_ROCKET",
                   trainerClass = "OPP_ROCKET", trainerParty = 1 }
  backing.yellowTrainerWinsV1 = {
    ["GAME_CORNER:7:OPP_ROCKET:1"] = true,
  }
  backing.yellowHiddenObjectsV1 = nil
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
  local region = {
    loaded = { field = field, maps = { GAME_CORNER = { objects = { rocket } } } },
    mapsById = {}, npcCache = { GAME_CORNER = { "stale" } },
    pokemonCache = { GAME_CORNER = { "stale" } },
  }
  local before = Twin.yellowGameCornerRocketMigrations or 0
  Twin._kantoOnMapEntered(region, "GAME_CORNER")
  check(Twin._kantoObjectHidden("GAME_CORNER", rocket),
        "beaten poster Rocket migrates to hidden physical state")
  eq(region.npcCache.GAME_CORNER, nil, "migration invalidates stale NPC cache")
  eq(region.pokemonCache.GAME_CORNER, nil, "migration invalidates stale actor cache")
  eq(Twin.yellowGameCornerRocketMigrations, before + 1,
     "Rocket migration diagnostic increments")
end

-- Build the immutable hot-field index once, then exercise exact O(1) spinner
-- cells and badge rows without rescanning the source arrays.
do
  local idx = Twin._buildKantoFieldIndex(field)
  check(idx.spinners.VIRIDIAN_GYM[5 * 1024 + 4] ~= nil,
        "spinner coordinate is indexed")
  eq(idx.badgeGates.ROUTE_23.upRows[10].badge, "EARTHBADGE",
     "Route 23 guard row indexed")
  eq(idx.badgeGates.ROUTE_22_GATE.coords[3 * 1024 + 4].badge, "BOULDERBADGE",
     "Route 22 exact checkpoint indexed")

  local region = { loaded = { field = field }, fieldIndex = idx }
  local world = { game = { data = {}, stack = { push = function() end } } }
  e.world = world
  e.forcedMoves, e.forcedMoveIndex, e.seafoamCurrentLock = nil, 0, false
  local spinBefore = Twin.yellowSpinnerIndexHits or 0
  check(Twin._trySpinner(region, "VIRIDIAN_GYM", 4, 5),
        "indexed spinner starts forced movement")
  eq(e.forcedMoves[1], "right", "spinner move 1")
  eq(e.forcedMoves[2], "right", "spinner move 2")
  eq(Twin.yellowSpinnerIndexHits, spinBefore + 1, "spinner index hit counted")

  local gateBefore = Twin.yellowBadgeGateIndexHits or 0
  local g = Twin._badgeGateForStep(region, "ROUTE_23", 5, 10, "up")
  eq(g and g.badge, "EARTHBADGE", "northbound Route 23 row resolves")
  eq(Twin._badgeGateForStep(region, "ROUTE_23", 6, 10, "up"), nil,
     "Route 23 max-X span is preserved")
  g = Twin._badgeGateForStep(region, "ROUTE_22_GATE", 4, 3, "up")
  eq(g and g.badge, "BOULDERBADGE", "Route 22 exact cell resolves")
  eq(Twin.yellowBadgeGateIndexHits, gateBefore + 2, "badge index hits counted")
end

print("kanto_poster_spinner_badge_index_parity: OK")
