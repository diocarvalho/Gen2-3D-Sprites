-- v0.3.51 regression: Kanto Cycling Road parity remains intact after manual Bicycle support.
-- Self-contained; no ROM cache and no renderer/GPU required.

package.preload["src.render.Assets"] = function() return {} end

local backing, gets, sets = {}, 0, 0
local refreshes = 0
local messages = {}
_G.love = { math = { random = function(a) return a end } }

local mod = {
  exports = {},
  options = { get = function() return nil end },
  save = {
    get = function(_, key, fallback)
      gets = gets + 1
      local v = backing[key]
      return v == nil and fallback or v
    end,
    set = function(_, key, value)
      sets = sets + 1
      backing[key] = value
      return true
    end,
  },
  ui = {
    TextBox = {
      new = function(_, text, onDone)
        messages[#messages + 1] = text
        if onDone then onDone() end
        return { text = text }
      end,
    },
  },
}

local inputState = {}
local input = {
  isDown = function(_, key) return inputState[key] == true end,
}
local stubs = {
  Quality = { kantoRadius = function() return 1 end,
              actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end,
                  releaseBody = function() end },
  ChunkMesher = {
    warmPending = function() return 0 end,
    refresh = function() refreshes = refreshes + 1; return true end,
  },
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
local function reset()
  backing, gets, sets, refreshes, messages, inputState = {}, 0, 0, 0, {}, {}
  Twin._resetKantoStateCacheForTest()
  e.active, e.sourceMapId = true, "ROUTE_16"
  e.cellX, e.cellY, e.facing = 1, 2, "right"
  e.biking, e.forcedBike, e.surfing = false, false, false
  e.cyclingBrakeHeld, e.cyclingRollActive = false, false
  e.forcedMoves, e.forcedMoveIndex = nil, 0
  e.seafoamCurrentLock = false
end

-- Persistent table reads are cached during one Kanto visit. A frequently-read
-- event table should cross mod.save once, then stay in memory until invalidated.
do
  reset()
  backing.yellowPhysicalEventsV1 = { EVENT_A = true }
  check(Twin._kantoEvent("EVENT_A"), "first event lookup succeeds")
  check(Twin._kantoEvent("EVENT_A"), "second event lookup succeeds")
  eq(gets, 1, "event table loaded once")
  Twin._setKantoEvent("EVENT_B", true)
  eq(gets, 1, "event mutation reuses cached table")
  eq(sets, 1, "event mutation writes once")
  check(backing.yellowPhysicalEventsV1.EVENT_B, "write-through cache persists mutation")
  Twin._resetKantoStateCacheForTest()
  check(Twin._kantoEvent("EVENT_A"), "event survives cache invalidation")
  eq(gets, 2, "cache invalidation causes one fresh load")
end

-- Multi-door restamps must invalidate the voxel sector once, not once per door.
do
  reset()
  local values = {}
  local map = { id = "__GEN1__SILPH_CO_9F" }
  function map:blockAt(bx, by) return values[by * 100 + bx] or 0x0e end
  function map:setBlock(bx, by, block) values[by * 100 + bx] = block; return true end
  local region = {
    loaded = { field = { cardKeyDoors = { closedDoors = {
      SILPH_CO_9F = {
        { block=0x5f, bx=1, by=4, open=0x0e, event="D1" },
        { block=0x54, bx=9, by=2, open=0x0e, event="D2" },
        { block=0x54, bx=9, by=5, open=0x0e, event="D3" },
        { block=0x5f, bx=5, by=6, open=0x0e, event="D4" },
      },
    } } } },
  }
  eq(Twin._restampClosedDoors(region, "SILPH_CO_9F", map), 4,
    "four authored doors change")
  eq(refreshes, 1, "four door writes produce one chunk refresh")
  eq(Twin._restampClosedDoors(region, "SILPH_CO_9F", map), 0,
    "second restamp is a no-op")
  eq(refreshes, 1, "no-op restamp does not refresh again")
end

local fm = {
  tiles = { ROUTE_16 = { { x=1, y=2, mode="bike" } } },
  slopeMaps = { "ROUTE_17" },
  clearMaps = { "ROUTE_18_GATE_1F" },
}
local region = { loaded = { field = { forcedMovement = fm } } }
local world = {
  game = {
    input = input,
    save = { inventory = { BICYCLE = 1 } },
    stack = { push = function() end },
  },
}

-- CheckForceBikeOrSurf: the authored forced-bike tile mounts silently when the
-- Gold save owns a BICYCLE and marks the stretch as always-on-bike.
do
  reset()
  e.region = region
  check(not Twin._syncForcedBike(world, region, "ROUTE_16", 1, 2),
        "valid bicycle mount does not consume frame with a message")
  check(e.biking and e.forcedBike, "forced bike state armed")
  eq(Twin._bikeStepDuration(region, "ROUTE_17", "down"), e.moveDuration * 0.5,
    "downhill keeps 2x bike speed")
  eq(Twin._bikeStepDuration(region, "ROUTE_17", "up"), e.moveDuration,
    "uphill steering uses normal speed")
end

-- Current Gen1Recomp #255: idle = simulated PAD_DOWN; held A/B brakes; a real
-- held direction wins even while A is held.
do
  e.biking = true
  inputState = {}
  local dir, wx, wz, braked = Twin._cyclingRoadIntent(region, "ROUTE_17", input, nil, 0, 0)
  eq(dir, "down", "idle Cycling Road forces down")
  eq(wx, 0, "forced downhill x")
  eq(wz, 1, "forced downhill z")
  check(not braked, "idle roll is not braking")

  inputState = { a = true }
  dir, wx, wz, braked = Twin._cyclingRoadIntent(region, "ROUTE_17", input, nil, 0, 0)
  eq(dir, nil, "held A suppresses forced direction")
  eq(wz, 0, "held A stops downhill movement")
  check(braked, "held A reports braking")

  dir, wx, wz, braked = Twin._cyclingRoadIntent(region, "ROUTE_17", input, "up", 0, -1)
  eq(dir, "up", "real direction wins over A brake")
  eq(wz, -1, "real uphill vector preserved")
  check(not braked, "directional input is not treated as brake")
end

-- No BICYCLE: refuse entry and queue a one-cell walk back opposite the facing.
do
  reset()
  e.region = region
  world.game.save.inventory = {}
  check(Twin._syncForcedBike(world, region, "ROUTE_16", 1, 2),
        "missing bicycle owns the frame with refusal")
  check(not e.biking and not e.forcedBike, "bike state stays off")
  eq(e.forcedMoves and e.forcedMoves[1], "left", "right-facing player is bounced left")
  check((messages[#messages] or ""):find("BICYCLE", 1, true) ~= nil,
        "refusal names the bicycle")
end

-- Route 16/18 gate scripts clear only BIT_ALWAYS_ON_BIKE.  With v0.3.51's
-- manual Bicycle action the rider stays mounted, matching the native state;
-- only the forced lock is released.
do
  e.biking, e.forcedBike = true, true
  world.game.save.inventory.BICYCLE = 1
  check(not Twin._syncForcedBike(world, region, "ROUTE_18_GATE_1F", 4, 4),
        "gate clear is silent")
  check(e.biking and not e.forcedBike, "gate clears only forced-bike lock")
end

print("kanto_cycling_optimization_parity: OK")
