-- v0.3.49 regression: story-free Yellow dynamic interior geometry.
-- Covers Silph CARD KEY doors, Yellow Rocket Hideout lift-gate version rules,
-- trainer-event migration, and Vermilion Gym's trash-can lock/door behavior.

package.preload["src.render.Assets"] = function() return {} end

local backing = {}
local messages = {}
local randomQueue = {}
_G.love = {
  math = {
    random = function(a, b)
      if #randomQueue > 0 then return table.remove(randomQueue, 1) end
      return a
    end,
  },
}

local mod = {
  exports = {},
  options = { get = function() return nil end },
  save = {
    get = function(_, key, fallback)
      local value = backing[key]
      if value == nil then return fallback end
      return value
    end,
    set = function(_, key, value)
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

local stubs = {
  Quality = { kantoRadius = function() return 1 end,
              actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end,
                  releaseBody = function() end },
  ChunkMesher = { warmPending = function() return 0 end, refresh = function() return true end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(value, label)
  if not value then error(label or "check failed", 2) end
end
local function fresh()
  backing = {}
  messages = {}
  randomQueue = {}
  if Twin and Twin._resetKantoStateCacheForTest then
    Twin._resetKantoStateCacheForTest()
  end
end
local function def(id, width, height, fill)
  local blocks = {}
  for i = 1, width * height do blocks[i] = fill or 0x0e end
  return { id = id, width = width, height = height, blocks = blocks,
           tileset = "FACILITY", objects = {} }
end
local function block(d, bx, by)
  return d.blocks[by * d.width + bx + 1]
end
local function regionFor(mapId, d, extra)
  extra = extra or {}
  return {
    version = "yellow",
    mapsById = {},
    loaded = {
      maps = { [mapId] = d },
      field = extra.field or {},
      trainerHeaders = extra.trainerHeaders or {},
      text = extra.text or {
        _VermilionGymTrashText = "TRASH",
        _VermilionGymTrashSuccessText1 = "FIRST",
        _VermilionGymTrashFailText = "RESET",
        _VermilionGymTrashSuccessText3 = "OPEN",
      },
    },
  }
end

-- Silph floors ship open in raw map bytes; story callbacks stamp the locked
-- block until the per-door event is set. The private Kanto map must do that
-- before collision/meshing sees the map.
do
  fresh()
  local d = def("SILPH_CO_2F", 8, 8, 0x0e)
  local region = regionFor("SILPH_CO_2F", d)
  Twin._applyPhysicalBlocks(region, "SILPH_CO_2F", d)
  eq(block(d, 2, 2), 0x54, "Silph 2F door 1 stamped closed")
  eq(block(d, 2, 5), 0x54, "Silph 2F door 2 stamped closed")
  Twin._setKantoEvent("EVENT_SILPH_CO_2_UNLOCKED_DOOR1", true)
  Twin._applyPhysicalBlocks(region, "SILPH_CO_2F", d)
  eq(block(d, 2, 2), 0x0e, "Silph door 1 reopens from event")
  eq(block(d, 2, 5), 0x54, "Silph door 2 stays locked independently")
end

-- Yellow specifically has no Rocket Hideout B4F gate callback, so that
-- doorway must stay open. B1F still has a guard-gated physical door.
do
  fresh()
  local b4 = def("ROCKET_HIDEOUT_B4F", 16, 8, 0x0e)
  local region4 = regionFor("ROCKET_HIDEOUT_B4F", b4)
  Twin._applyPhysicalBlocks(region4, "ROCKET_HIDEOUT_B4F", b4)
  eq(block(b4, 12, 5), 0x0e, "Yellow B4F lift gate remains open")

  local b1 = def("ROCKET_HIDEOUT_B1F", 16, 10, 0x0e)
  local region1 = regionFor("ROCKET_HIDEOUT_B1F", b1)
  Twin._applyPhysicalBlocks(region1, "ROCKET_HIDEOUT_B1F", b1)
  eq(block(b1, 12, 8), 0x54, "Yellow B1F lift gate starts closed")
  Twin._setKantoEvent("EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_4", true)
  Twin._applyPhysicalBlocks(region1, "ROCKET_HIDEOUT_B1F", b1)
  eq(block(b1, 12, 8), 0x0e, "B1F guard event opens lift gate")
end

-- Existing pre-v0.3.49 trainer wins migrate through the extracted trainer
-- header event, so upgrading does not relock a gate the player already earned.
do
  fresh()
  local b1 = def("ROCKET_HIDEOUT_B1F", 16, 10, 0x0e)
  b1.label = "RocketHideoutB1F"
  b1.objects = {
    { index = 5, trainerClass = "OPP_ROCKET", trainerParty = 1, x = 10, y = 10 },
  }
  backing.yellowTrainerWinsV1 = {
    ["ROCKET_HIDEOUT_B1F:5:OPP_ROCKET:1"] = true,
  }
  local region = regionFor("ROCKET_HIDEOUT_B1F", b1, {
    trainerHeaders = {
      RocketHideoutB1F = {
        [5] = { event = "EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_4" },
      },
    },
  })
  Twin._applyPhysicalBlocks(region, "ROCKET_HIDEOUT_B1F", b1)
  check(Twin._kantoEvent("EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_4"),
        "old trainer win migrated to physical event")
  eq(block(b1, 12, 8), 0x0e, "migrated trainer win keeps B1F open")
end

local function fakeDoorMap(blockId, tile)
  local m = { id = "__GEN1__SILPH_CO_2F", sourceId = "SILPH_CO_2F",
              def = { id = "SILPH_CO_2F", width = 8, height = 8, blocks = {} } }
  local current = blockId
  function m:blockAt() return current end
  function m:setBlock(_, _, b) current = b; return true end
  function m:cellTile() return tile end
  function m:value() return current end
  return m
end
local world = {
  game = {
    save = { inventory = {} },
    stack = { push = function() end },
  },
}

-- CARD KEY interaction consumes no story script: it finds the authored block
-- row, persists its Yellow unlock event and swaps only that block.
do
  fresh()
  local d = def("SILPH_CO_2F", 8, 8, 0x0e)
  local region = regionFor("SILPH_CO_2F", d, {
    field = { cardKeyDoors = { doorTiles = { 0x18, 0x24 } } },
  })
  local map = fakeDoorMap(0x54, 0x18)
  world.game.save.inventory = {}
  check(Twin._tryCardKeyDoor(world, region, "SILPH_CO_2F", map, 4, 4),
        "locked Silph door consumes interaction without key")
  eq(map:value(), 0x54, "door remains closed without CARD KEY")
  check(not Twin._kantoEvent("EVENT_SILPH_CO_2_UNLOCKED_DOOR1"),
        "no unlock event without key")

  -- Gold's Radio Tower CARD_KEY is a different story key and must not unlock
  -- the Yellow Silph door merely because the constant name collides.
  world.game.save.inventory.CARD_KEY = 1
  check(Twin._tryCardKeyDoor(world, region, "SILPH_CO_2F", map, 4, 4),
        "Gold CARD KEY collision stays handled")
  eq(map:value(), 0x54, "Gold CARD KEY does not open Silph")
  check(not Twin._kantoEvent("EVENT_SILPH_CO_2_UNLOCKED_DOOR1"),
        "Gold CARD KEY sets no Silph event")

  Twin._giveKantoLocalItem("CARD_KEY")
  check(Twin._tryCardKeyDoor(world, region, "SILPH_CO_2F", map, 4, 4),
        "Kanto CARD KEY opens Silph door")
  eq(map:value(), 0x0e, "Kanto CARD KEY swaps the open block")
  check(Twin._kantoEvent("EVENT_SILPH_CO_2_UNLOCKED_DOOR1"),
        "Kanto CARD KEY persists exact door event")
end

local function fakeGymMap()
  local current = 0x99
  local m = { id = "__GEN1__VERMILION_GYM", sourceId = "VERMILION_GYM",
              def = { id = "VERMILION_GYM", width = 8, height = 8, blocks = {} } }
  function m:blockAt(bx, by)
    if bx == 2 and by == 2 then return current end
    return 0
  end
  function m:setBlock(bx, by, b)
    if bx == 2 and by == 2 then current = b end
    return true
  end
  function m:value() return current end
  return m
end

-- Vermilion first switch + retail mask bug + second switch door opening.
do
  fresh()
  local d = def("VERMILION_GYM", 8, 8, 0)
  local region = regionFor("VERMILION_GYM", d)
  local map = fakeGymMap()
  backing.yellowTrashPuzzleV1 = { first = 0 }
  randomQueue = { 2 } -- #row=2; 2 & 2 -> candidate slot 2 -> can 3
  check(Twin._tryTrashCan(world, region, "VERMILION_GYM", map, 1, 7),
        "first switch interaction")
  check(Twin._kantoEvent("EVENT_1ST_LOCK_OPENED"), "first lock event set")
  eq(backing.yellowTrashPuzzleV1.second, 3, "mask-2 row picks can 3")
  eq(messages[#messages], "FIRST", "first-switch text")

  check(Twin._tryTrashCan(world, region, "VERMILION_GYM", map, 3, 7),
        "second switch interaction")
  check(Twin._kantoEvent("EVENT_2ND_LOCK_OPENED"), "second lock event set")
  eq(map:value(), 5, "Vermilion motorized door block opens")
  eq(messages[#messages], "OPEN", "second-switch success text")
end

-- A zero AND reproduces the cartridge bug: second switch becomes can 0.
do
  fresh()
  local region = regionFor("VERMILION_GYM", def("VERMILION_GYM", 8, 8, 0))
  backing.yellowTrashPuzzleV1 = { first = 0 }
  randomQueue = { 13 } -- 13 & 2 = 0
  Twin._tryTrashCan(world, region, "VERMILION_GYM", fakeGymMap(), 1, 7)
  eq(backing.yellowTrashPuzzleV1.second, 0, "zero mask result falls to can 0")
end

-- Wrong second can resets first-lock event and immediately re-rolls first.
do
  fresh()
  local region = regionFor("VERMILION_GYM", def("VERMILION_GYM", 8, 8, 0))
  backing.yellowPhysicalEventsV1 = { EVENT_1ST_LOCK_OPENED = true }
  backing.yellowTrashPuzzleV1 = { first = 0, second = 3 }
  randomQueue = { 6 } -- firstLockCandidates[6] = 10
  Twin._tryTrashCan(world, region, "VERMILION_GYM", fakeGymMap(), 1, 9) -- can 1
  check(not Twin._kantoEvent("EVENT_1ST_LOCK_OPENED"), "wrong second relocks")
  eq(backing.yellowTrashPuzzleV1.first, 10, "wrong second rerolls first can")
  eq(backing.yellowTrashPuzzleV1.second, nil, "wrong second clears second can")
  eq(messages[#messages], "RESET", "reset text")
end

-- Vermilion City map-load roll changes only the first index mid-puzzle.
do
  fresh()
  local region = regionFor("VERMILION_CITY", def("VERMILION_CITY", 8, 8, 0))
  backing.yellowPhysicalEventsV1 = { EVENT_1ST_LOCK_OPENED = true }
  backing.yellowTrashPuzzleV1 = { first = 0, second = 3 }
  randomQueue = { 8 } -- index 8 -> can 14
  Twin._onKantoMapEntered(region, "VERMILION_CITY")
  eq(backing.yellowTrashPuzzleV1.first, 14, "Vermilion City entry rerolls first can")
  eq(backing.yellowTrashPuzzleV1.second, 3, "map-load roll preserves second can")
  check(Twin._kantoEvent("EVENT_1ST_LOCK_OPENED"), "map-load roll preserves first event")
end

print("kanto_dynamic_interior_parity: OK")
