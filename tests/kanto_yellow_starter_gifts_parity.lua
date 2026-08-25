-- v0.3.70 regression: Yellow's three Kanto starter sidequests become real
-- Gold-owned Pokemon transactions without enabling Yellow story/cutscene VM.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.inventory.Bag"] = function() return {} end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

local boxFull = false
local box = {}
package.preload["src.core.gen2.Boxes"] = function()
  return {
    isFull = function() return boxFull end,
    box = function() return box end,
    name = function() return "BOX 1" end,
  }
end

local monBuilds, stamps = {}, 0
package.preload["src.battle.gen2.Mon"] = function()
  return {
    new = function(_, species, level, opts)
      local mon = {
        species = species,
        level = level,
        happiness = opts and opts.happiness or 70,
      }
      monBuilds[#monBuilds + 1] = mon
      return mon
    end,
    stampOT = function(save, mon)
      stamps = stamps + 1
      mon.ot = save.player and save.player.name or nil
      mon.otId = save.player and save.player.id or nil
      return mon
    end,
  }
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
local Gifts = Twin._starterGiftsForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end

local bulbaObject = {
  index = 2, name = "CERULEANMELANIESHOUSE_BULBASAUR",
  text = "TEXT_CERULEANMELANIESHOUSE_BULBASAUR", x = 3, y = 4,
}
local melanie = { index = 1, text = "TEXT_CERULEANMELANIESHOUSE_MELANIE" }
local damian = { index = 4, text = "TEXT_ROUTE24_COOLTRAINER_M4" }
local jenny = { index = 7, text = "TEXT_VERMILIONCITY_OFFICER_JENNY" }

local region = {
  loaded = {
    text = {
      MelanieText1 = "MELANIE INTRO",
      MelanieText2 = "MELANIE ASK",
      MelanieText3 = "MELANIE RECEIVED",
      MelanieText4 = "MELANIE AFTER",
      MelanieText5 = "MELANIE DECLINED",
      _Route24DamianText1 = "DAMIAN ASK",
      _Route24DamianText2 = "DAMIAN RECEIVED",
      _Route24DamianText3 = "DAMIAN DECLINED",
      _Route24DamianText4 = "DAMIAN AFTER",
      _OfficerJennyText1 = "JENNY LOCKED",
      _OfficerJennyText2 = "JENNY ASK",
      _OfficerJennyText3 = "JENNY RECEIVED",
      _OfficerJennyText4 = "JENNY DECLINED",
      _OfficerJennyText5 = "JENNY AFTER",
    },
    maps = {
      CERULEAN_MELANIES_HOUSE = { objects = { melanie, bulbaObject } },
      ROUTE_24 = { objects = { damian } },
      VERMILION_CITY = { objects = { jenny } },
    },
    field = {},
  },
  mapsById = {}, npcCache = {}, pokemonCache = {},
}

local world = {
  game = {
    data = { pokemon = { BULBASAUR={}, CHARMANDER={}, SQUIRTLE={} }, moves = {} },
    save = {
      player = { name = "GOLD", id = 1234, kantoBadges = {} },
      party = {}, boxes = {}, currentBox = 1, pokedex = { seen = {}, caught = {} },
    },
    stack = { push = function() return true end },
  },
}

local function fresh()
  backing, messages, choices, box, boxFull, monBuilds, stamps = {}, {}, {}, {}, false, {}, 0
  world.game.save = {
    player = { name = "GOLD", id = 1234, kantoBadges = {} },
    party = {}, boxes = {}, currentBox = 1, pokedex = { seen = {}, caught = {} },
  }
  region.npcCache, region.pokemonCache = {}, {}
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end

-- Exact ownership is map + text scoped, so an unrelated NPC using a familiar
-- text label cannot accidentally mint a Pokemon.
do
  check(Gifts.match("CERULEAN_MELANIES_HOUSE", melanie.text) == Gifts.GIFTS.BULBASAUR,
        "Melanie gift recognized")
  check(Gifts.match("ROUTE_24", damian.text) == Gifts.GIFTS.CHARMANDER,
        "Damian gift recognized")
  check(Gifts.match("VERMILION_CITY", jenny.text) == Gifts.GIFTS.SQUIRTLE,
        "Jenny gift recognized")
  check(Gifts.match("ROUTE_24", melanie.text) == nil, "starter gift is map-scoped")
end

-- Melanie always gives her intro. Below the retail 147 threshold there is no
-- question and no completion. A real Gold party Pikachu supplies friendship.
do
  fresh()
  world.game.save.party = { { species = "PIKACHU", happiness = 146 } }
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CERULEAN_MELANIES_HOUSE", melanie), "low-friendship Melanie handled")
  eq(messages[1], "MELANIE INTRO", "Melanie intro below threshold")
  eq(#messages, 1, "no offer below threshold")
  check(not Twin._kantoEvent(Gifts.GIFTS.BULBASAUR.event), "low friendship sets no event")
  eq(#world.game.save.party, 1, "low friendship gives no Bulbasaur")

  fresh()
  world.game.save.party = { { species = "PIKACHU", happiness = 147 } }
  choices = { false }
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CERULEAN_MELANIES_HOUSE", melanie), "Melanie decline handled")
  eq(messages[1], "MELANIE INTRO", "eligible Melanie intro")
  eq(messages[2], "MELANIE ASK", "eligible Melanie asks")
  eq(messages[3], "MELANIE DECLINED", "Melanie decline text")
  check(not Twin._kantoEvent(Gifts.GIFTS.BULBASAUR.event), "decline remains retryable")
end

-- Compatibility bridge: an explicit Yellow follower value remains accepted and
-- takes precedence, while normal Gold does not substitute a non-Pikachu lead.
do
  fresh()
  world.game.save.pikachuHappiness = 200
  eq(Twin._kantoPikachuHappiness(world), 200, "legacy Pikachu happiness bridge")
  world.game.save.pikachuHappiness = nil
  world.game.save.party = { { species = "EEVEE", happiness = 255 },
                            { species = "PIKACHU", happiness = 151 } }
  eq(Twin._kantoPikachuHappiness(world), 151, "only Pikachu friendship qualifies")
end

-- Successful Bulbasaur gift is a Gen-2 gift mon: level 10, happiness 120,
-- player OT, Pokedex ownership, one local completion event, and hidden pet.
do
  fresh()
  world.game.save.party = { { species = "PIKACHU", happiness = 200 } }
  choices = { true }
  local before = Twin.yellowStarterGifts or 0
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CERULEAN_MELANIES_HOUSE", melanie), "Melanie accept handled")
  eq(#world.game.save.party, 2, "Bulbasaur enters party")
  local mon = world.game.save.party[2]
  eq(mon.species, "BULBASAUR", "Bulbasaur species")
  eq(mon.level, 10, "Bulbasaur level")
  eq(mon.happiness, 120, "gift happiness")
  eq(mon.ot, "GOLD", "gift player OT")
  eq(mon.otId, 1234, "gift player OT id")
  eq(stamps, 1, "OT stamped once")
  check(world.game.save.pokedex.seen.BULBASAUR, "Bulbasaur seen")
  check(world.game.save.pokedex.caught.BULBASAUR, "Bulbasaur caught")
  check(Twin._kantoEvent(Gifts.GIFTS.BULBASAUR.event), "Bulbasaur completion persists")
  check(Twin._kantoObjectHidden("CERULEAN_MELANIES_HOUSE", bulbaObject),
        "Melanie pet object hidden")
  eq(Twin.yellowStarterGifts, before + 1, "starter diagnostic increments")
  eq(messages[#messages], "MELANIE RECEIVED", "Bulbasaur received text")

  local count = #world.game.save.party
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CERULEAN_MELANIES_HOUSE", melanie), "served Melanie handled")
  eq(#world.game.save.party, count, "served Melanie cannot duplicate gift")
  eq(messages[#messages], "MELANIE AFTER", "served Melanie after text")
end

-- Party + current box full is atomic: no mon, no event, and a later retry can
-- still succeed. This is the failure window that must never consume a starter.
do
  fresh()
  for i = 1, 6 do world.game.save.party[i] = { species = i == 1 and "PIKACHU" or "RATTATA", happiness = 200 } end
  boxFull = true
  choices = { true }
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CERULEAN_MELANIES_HOUSE", melanie), "full storage Melanie handled")
  eq(#world.game.save.party, 6, "full party unchanged")
  eq(#monBuilds, 0, "full storage refuses before building gift")
  check(not Twin._kantoEvent(Gifts.GIFTS.BULBASAUR.event), "full storage sets no event")
  check(not Twin._kantoObjectHidden("CERULEAN_MELANIES_HOUSE", bulbaObject),
        "full storage leaves Bulbasaur visible")
end

-- Damian has no prerequisite beyond YES/NO, remains retryable on NO, and gives
-- exactly one level-10 Charmander on success.
do
  fresh(); choices = { false }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "ROUTE_24", damian),
        "Damian decline handled")
  eq(messages[#messages], "DAMIAN DECLINED", "Damian decline text")
  check(not Twin._kantoEvent(Gifts.GIFTS.CHARMANDER.event), "Damian decline retryable")

  choices = { true }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "ROUTE_24", damian),
        "Damian accept handled")
  eq(world.game.save.party[#world.game.save.party].species, "CHARMANDER", "Charmander awarded")
  eq(world.game.save.party[#world.game.save.party].level, 10, "Charmander level")
  check(Twin._kantoEvent(Gifts.GIFTS.CHARMANDER.event), "Charmander completion persists")
  eq(messages[#messages], "DAMIAN RECEIVED", "Charmander received text")
end

-- Jenny is locked until Gold's Kanto Lt. Surge badge is actually owned. The
-- THUNDER badge unlocks the retail YES/NO and successful Squirtle gift.
do
  fresh()
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "VERMILION_CITY", jenny),
        "unbadged Jenny handled")
  eq(messages[#messages], "JENNY LOCKED", "Jenny locked text")
  check(not Twin._kantoEvent(Gifts.GIFTS.SQUIRTLE.event), "no badge gives no Squirtle")

  world.game.save.player.kantoBadges.THUNDER = true
  choices = { false }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "VERMILION_CITY", jenny),
        "badged Jenny decline handled")
  eq(messages[#messages], "JENNY DECLINED", "Jenny decline text")
  check(not Twin._kantoEvent(Gifts.GIFTS.SQUIRTLE.event), "Jenny decline retryable")

  choices = { true }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "VERMILION_CITY", jenny),
        "badged Jenny accept handled")
  eq(world.game.save.party[#world.game.save.party].species, "SQUIRTLE", "Squirtle awarded")
  eq(world.game.save.party[#world.game.save.party].happiness, 120, "Squirtle gift happiness")
  check(Twin._kantoEvent(Gifts.GIFTS.SQUIRTLE.event), "Squirtle completion persists")
  eq(messages[#messages], "JENNY RECEIVED", "Squirtle received text")
end

-- Upgrade/reload migration: if the Bulbasaur event already exists but an old
-- cached map still shows the pet object, map entry repairs only physical state.
do
  fresh()
  backing.yellowPhysicalEventsV1 = {
    [Gifts.GIFTS.BULBASAUR.event] = true,
  }
  Twin._resetKantoStateCacheForTest()
  check(Twin._migrateKantoStarterGiftObjects(region, "CERULEAN_MELANIES_HOUSE"),
        "completed Bulbasaur migrates hidden object")
  check(Twin._kantoObjectHidden("CERULEAN_MELANIES_HOUSE", bulbaObject),
        "migration hides stale Bulbasaur")
end

print("kanto_yellow_starter_gifts_parity: ok")
