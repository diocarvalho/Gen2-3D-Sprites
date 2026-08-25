-- v0.3.68 regression: story-free Kanto civic access/service parity.
-- Covers Saffron guard drinks + gate pushback, Pewter Museum admission, and
-- Old Amber ownership/hiding using Gold inventory/money without Yellow story VM.

package.preload["src.render.Assets"] = function() return {} end
local bagAccept = true
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, item, count)
      if not bagAccept then return false end
      save.inventory = save.inventory or {}
      save.inventory[item] = (tonumber(save.inventory[item]) or 0) + (count or 1)
      return true
    end,
    slots = function() return bagAccept and 0 or 1 end,
    capacity = function() return 1 end,
  }
end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

_G.love = { math = { random = function(a) return a end } }

local backing, messages, choices = {}, {}, {}
local function popChoice()
  if #choices == 0 then return false end
  return table.remove(choices, 1)
end

local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and type(opts.choice) == "function" then
      opts.choice(popChoice())
    elseif onDone then
      onDone()
    end
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
  ChunkMesher = { warmPending = function() return 0 end,
                  refresh = function() return true end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Civic = Twin._civicForTest
local e = Twin._excursionForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end
local function contains(haystack, needle)
  return tostring(haystack or ""):find(needle, 1, true) ~= nil
end
local function fresh()
  backing, messages, choices = {}, {}, {}
  bagAccept = true
  e.forcedMoves, e.forcedMoveIndex, e.seafoamCurrentLock = nil, 0, false
  e.facing = "down"
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end

local region = {
  loaded = {
    text = {
      _SaffronGateGuardThanksForTheDrinkText = "THANKS",
      _SaffronGateGuardImParchedText = "PARCHED",
      _SaffronGateGuardYouCanGoOnThroughText = "THROUGH",
      _SaffronGateGuardGeeImThirstyText = "CLOSED",
      _Museum1FScientist1TakePlentyOfTimeText = "TAKE TIME",
      _Museum1FScientist1WouldYouLikeToComeInText = "TICKET?",
      _Museum1FScientist1ThankYouText = "THANK YOU",
      _Museum1FScientist1DontHaveEnoughMoneyText = "NO MONEY",
      _Museum1FScientist1ComeAgainText = "COME AGAIN",
      _Museum1FScientist2TakeThisToAPokemonLabText = "TAKE AMBER",
      _Museum1FScientist2YouDontHaveSpaceText = "NO SPACE",
      _Museum1FScientist2ReceivedOldAmberText = "GOT AMBER",
      _Museum1FScientist2GetTheOldAmberCheckText = "CHECK AMBER",
    },
    maps = {},
    field = {},
  },
  mapsById = {}, npcCache = {}, pokemonCache = {},
}
local world = {
  game = {
    data = { items = { OLD_AMBER = { name = "OLD AMBER" } } },
    save = { money = 0, inventory = {} },
    stack = { push = function() return true end },
  },
}

-- Static Yellow gate coordinates/directions are exact and shared across the
-- service layer, so the physical trigger cannot drift from the authored maps.
do
  check(Civic.gateTrigger("ROUTE_5_GATE", 3, 3), "Route 5 left trigger")
  check(Civic.gateTrigger("ROUTE_5_GATE", 4, 3), "Route 5 right trigger")
  check(Civic.gateTrigger("ROUTE_7_GATE", 3, 4), "Route 7 lower trigger")
  check(not Civic.gateTrigger("ROUTE_7_GATE", 4, 4), "Route 7 non-trigger")
  eq(Civic.gateBounce("ROUTE_5_GATE", "up"), "down", "vertical gate pushback")
  eq(Civic.gateBounce("ROUTE_7_GATE", "left"), "right", "horizontal gate pushback")
end

-- No drink: guard blocks the trigger and queues exactly one step back.
do
  fresh()
  world.game.save.money, world.game.save.inventory = 0, {}
  e.facing = "up"
  local before = Twin.yellowSaffronGateBlocks or 0
  check(Twin._handleKantoSaffronGateStep(world, region, "ROUTE_5_GATE", 3, 3),
        "closed Saffron gate consumes landing")
  check(not Twin._kantoEvent(Civic.SAFFRON_EVENT), "no drink leaves Saffron closed")
  eq(e.forcedMoves and e.forcedMoves[1], "down", "Route 5 pushes player back south")
  eq(Twin.yellowSaffronGateBlocks, before + 1, "Saffron block diagnostic")
  eq(messages[#messages], "CLOSED", "closed-road text")
end

-- The first drink in Yellow's fixed order is consumed once and opens all four
-- guards. A later gate no longer consumes anything or pushes the player back.
do
  fresh()
  world.game.save.inventory = { FRESH_WATER = 2, SODA_POP = 1, LEMONADE = 1 }
  e.facing = "up"
  local before = Twin.yellowSaffronDrinks or 0
  check(Twin._handleKantoSaffronGateStep(world, region, "ROUTE_5_GATE", 4, 3),
        "drink opens Saffron gate")
  eq(world.game.save.inventory.FRESH_WATER, 1, "first drink order consumes fresh water")
  eq(world.game.save.inventory.SODA_POP, 1, "later drinks untouched")
  check(Twin._kantoEvent(Civic.SAFFRON_EVENT), "shared Saffron event opens")
  eq(e.forcedMoves, nil, "successful drink does not push back")
  eq(messages[#messages - 1], "PARCHED", "parched text first")
  eq(messages[#messages], "THROUGH", "through text second")
  eq(Twin.yellowSaffronDrinks, before + 1, "drink diagnostic increments")
  check(not Twin._handleKantoSaffronGateStep(world, region, "ROUTE_8_GATE", 2, 4),
        "opened shared event bypasses another gate")
  eq(world.game.save.inventory.SODA_POP, 1, "opened gate consumes no second drink")
end

-- Direct guard talk shares the same Gold inventory authority.
do
  fresh()
  world.game.save.inventory = { LEMONADE = 1 }
  local guard = { text = "TEXT_ROUTE7GATE_GUARD" }
  check(Twin._talkKantoSaffronGuard(world, region, "ROUTE_7_GATE", guard),
        "guard talk is handled")
  eq(world.game.save.inventory.LEMONADE, nil, "guard talk hands over lemonade")
  check(Twin._kantoEvent(Civic.SAFFRON_EVENT), "guard talk opens shared event")
end

-- Museum rope: declining or lacking money walks the player one tile south;
-- paying exactly ¥50 persists the ticket and stops future rope interception.
do
  fresh()
  world.game.save.money, world.game.save.inventory = 100, {}
  choices = { false }
  check(Twin._handleKantoMuseumGateStep(world, region, "MUSEUM_1F", 9, 4),
        "museum decline consumes rope landing")
  eq(world.game.save.money, 100, "decline spends no money")
  check(not Twin._kantoEvent(Civic.MUSEUM_TICKET_EVENT), "decline buys no ticket")
  eq(e.forcedMoves and e.forcedMoves[1], "down", "decline pushes south")

  fresh()
  world.game.save.money, world.game.save.inventory = 40, {}
  choices = { true }
  check(Twin._handleKantoMuseumGateStep(world, region, "MUSEUM_1F", 10, 4),
        "museum insufficient funds consumes rope landing")
  eq(world.game.save.money, 40, "insufficient funds spend nothing")
  check(not Twin._kantoEvent(Civic.MUSEUM_TICKET_EVENT), "no ticket without ¥50")
  eq(e.forcedMoves and e.forcedMoves[1], "down", "insufficient funds push south")
  eq(messages[#messages], "NO MONEY", "insufficient-funds text")

  fresh()
  world.game.save.money, world.game.save.inventory = 100, {}
  choices = { true }
  local before = Twin.yellowMuseumTickets or 0
  check(Twin._handleKantoMuseumGateStep(world, region, "MUSEUM_1F", 9, 4),
        "museum ticket purchase consumes rope landing")
  eq(world.game.save.money, 50, "museum charges exactly ¥50")
  check(Twin._kantoEvent(Civic.MUSEUM_TICKET_EVENT), "museum ticket persists")
  eq(e.forcedMoves, nil, "paid visitor is not pushed back")
  eq(Twin.yellowMuseumTickets, before + 1, "ticket diagnostic increments")
  check(not Twin._handleKantoMuseumGateStep(world, region, "MUSEUM_1F", 10, 4),
        "ticket bypasses other rope cell")
end

-- Old Amber is Kanto-local because Gold has no compatible item id. The service
-- still honors Gold key-item pocket capacity; success persists local ownership.
do
  fresh()
  local amber = { index = 4, name = "MUSEUM1F_OLD_AMBER", text = "TEXT_MUSEUM1F_OLD_AMBER", x = 12, y = 3 }
  local scientist = { index = 3, name = "MUSEUM1F_SCIENTIST2", text = "TEXT_MUSEUM1F_SCIENTIST2", x = 11, y = 3 }
  region.loaded.maps.MUSEUM_1F = { objects = { scientist, amber } }
  region.npcCache.MUSEUM_1F, region.pokemonCache.MUSEUM_1F = { "stale" }, { "stale" }
  world.game.save.inventory = {}
  bagAccept = false
  check(Twin._giveKantoMuseumAmber(world, region, "MUSEUM_1F"),
        "Old Amber scientist handles bag-full talk")
  check(not Twin._kantoEvent(Civic.OLD_AMBER_EVENT), "bag full sets no amber event")
  check(not Twin._kantoObjectHidden("MUSEUM_1F", amber), "bag full leaves display visible")
  eq(messages[#messages], "NO SPACE", "bag-full refusal text")

  bagAccept = true
  local before = Twin.yellowOldAmberGifts or 0
  check(Twin._giveKantoMuseumAmber(world, region, "MUSEUM_1F"),
        "Old Amber gift succeeds")
  check(Twin._kantoItemHeld(world, "OLD_AMBER"), "Kanto-local OLD AMBER ownership")
  eq(world.game.save.inventory.OLD_AMBER, nil, "Gold bag is not polluted with OLD_AMBER")
  check(Twin._kantoEvent(Civic.OLD_AMBER_EVENT), "Old Amber event persists")
  check(Twin._kantoObjectHidden("MUSEUM_1F", amber), "display hides after gift")
  eq(region.npcCache.MUSEUM_1F, nil, "gift invalidates NPC cache")
  eq(region.pokemonCache.MUSEUM_1F, nil, "gift invalidates actor cache")
  eq(Twin.yellowOldAmberGifts, before + 1, "amber diagnostic increments")
  check(Twin._giveKantoMuseumAmber(world, region, "MUSEUM_1F"),
        "repeat scientist talk remains handled")
  check(Twin._kantoItemHeld(world, "OLD_AMBER"), "repeat talk keeps one local amber state")
  eq(messages[#messages], "CHECK AMBER", "repeat completion text")
end

-- Upgrade/migration safety: an existing completion event hides a stale display
-- on map entry without running Yellow ASM.
do
  fresh()
  local amber = { index = 4, name = "MUSEUM1F_OLD_AMBER", text = "TEXT_MUSEUM1F_OLD_AMBER" }
  region.loaded.maps.MUSEUM_1F = { objects = { amber } }
  region.npcCache.MUSEUM_1F, region.pokemonCache.MUSEUM_1F = { "stale" }, { "stale" }
  backing.yellowPhysicalEventsV1 = { [Civic.OLD_AMBER_EVENT] = true }
  Twin._resetKantoStateCacheForTest()
  local before = Twin.yellowMuseumObjectMigrations or 0
  Twin._kantoOnMapEntered(region, "MUSEUM_1F")
  check(Twin._kantoObjectHidden("MUSEUM_1F", amber), "completed amber migrates display hidden")
  eq(region.npcCache.MUSEUM_1F, nil, "migration clears NPC cache")
  eq(region.pokemonCache.MUSEUM_1F, nil, "migration clears actor cache")
  eq(Twin.yellowMuseumObjectMigrations, before + 1, "migration diagnostic increments")
end

print("kanto_civic_access_parity: OK")
