-- v0.3.86 regression: Yellow one-off Pokemon keep their authored overworld
-- presentation in Gold. Power Plant Voltorb/Electrode remain disguised as
-- Poke Balls until touched, static intro text precedes the Gold battle, and
-- completed-vs-blackout persistence works for either NPC- or Pokemon-cache
-- presentation actors.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.battle.gen2.Mon"] = function()
  return { new = function(_, species, level)
    return { species = species, level = level }
  end }
end

local backing, messages = {}, {}
_G.love = { math = { random = function(a) return a end } }

local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = text
    if opts and opts.choice then opts.choice(false)
    elseif onDone then onDone() end
    return { text = text }
  end,
}

local mod = {
  exports = {}, options = { get = function() return nil end }, ui = { TextBox = TextBox },
  save = {
    get = function(_, key, fallback)
      local v = backing[key]
      return v == nil and fallback or v
    end,
    set = function(_, key, value) backing[key] = value; return true end,
  },
}

local stubs = {
  Quality = { kantoRadius = function() return 1 end,
              actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end, releaseBody = function() end },
  ChunkMesher = { warmPending = function() return 0 end, refresh = function() return true end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function()
    return { load = function() return true end, isReady = function() return false end }
  end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function check(v, label) if not v then error(label or "check failed", 2) end end
local function eq(a, b, label)
  if a ~= b then error((label or "value") .. ": expected " .. tostring(b)
    .. ", got " .. tostring(a), 2) end
end
local function fresh()
  backing, messages = {}, {}
  Twin._resetKantoStateCacheForTest()
  local ex = Twin._excursionForTest
  ex.battleBusy = false; ex.safari = false; ex.prevA = false
end
local function regionFor(mapId, obj, body, label)
  local mapDef = { id = mapId, label = label or mapId, objects = { obj } }
  return {
    version = "yellow", mapsById = {}, npcCache = {}, pokemonCache = {},
    loaded = {
      maps = { [mapId] = mapDef }, field = {}, trainers = {},
      text = body and { STATIC_BATTLE_TEXT = body } or {},
      textPointers = body and {
        [label or mapId] = { [obj.text] = { text = "STATIC_BATTLE_TEXT", asm = true } }
      } or {},
    },
  }, { id = "__GEN1__" .. mapId, sourceId = mapId, def = mapDef }
end
local function battleWorld(species, outcome, onStart)
  local save = { pokedex = { seen = {}, caught = {} }, party = {} }
  local world = {
    game = {
      data = { pokemon = { [species] = {} }, moves = {} },
      save = save,
      stack = { push = function() return true end },
    },
  }
  world.startBattle = function(_, opts, onDone)
    check(opts and opts.wild, "Gold wild battle payload")
    if onStart then onStart(opts.wild, save) end
    onDone(outcome)
    return true
  end
  return world, save
end

-- Power Plant's eight trap Pokemon are map Pokemon with SPRITE_POKE_BALL. That
-- authored sprite, not the species identity, decides their overworld disguise.
do
  fresh()
  check(Twin._isDisguisedStaticPokemon({ pokemon = "VOLTORB", sprite = "SPRITE_POKE_BALL" }),
    "Voltorb trap recognized")
  check(Twin._isDisguisedStaticPokemon({ pokemon = "ELECTRODE", sprite = "sprite_poke_ball" }),
    "Electrode trap is case-insensitive")
  check(not Twin._isDisguisedStaticPokemon({ pokemon = "ZAPDOS", sprite = "SPRITE_BIRD" }),
    "Zapdos remains a visible Pokemon")
  check(not Twin._isDisguisedStaticPokemon({ sprite = "SPRITE_POKE_BALL" }),
    "ordinary item ball is not a Pokemon trap")
end

-- Touching a disguised trap presents Yellow's Bzzzt text, then starts a real
-- level-40 Gold Voltorb battle. RUN consumes the one-off trap, just like the
-- one-off trainer-header tail in Yellow.
do
  fresh()
  local obj = { index = 1, pokemon = "VOLTORB", level = 40, sprite = "SPRITE_POKE_BALL",
    x = 9, y = 20, text = "TEXT_POWERPLANT_VOLTORB1" }
  local region = regionFor("POWER_PLANT", obj, "Bzzzt!", "PowerPlant")
  local entity = { def = obj, staticYellowPokemon = true, sourceObject = obj,
    disguisedStaticPokemon = true, cellX = 9, cellY = 20 }
  region.npcCache.POWER_PLANT = { entity }
  region.pokemonCache.POWER_PLANT = {}
  local world = battleWorld("VOLTORB", "run", function(wild)
    eq(wild.species, "VOLTORB", "trap species")
    eq(wild.level, 40, "trap level")
  end)
  check(Twin._startStaticPokemonInteraction(world, region, "POWER_PLANT", obj, entity),
    "trap interaction handled")
  eq(messages[1], "Bzzzt!", "Yellow reveal text shown before battle")
  eq(#region.npcCache.POWER_PLANT, 0, "trap ball removed while battle resolves")
  check(Twin._staticPokemonCleared("POWER_PLANT", obj), "completed trap encounter persists")
end

-- Blacking out is the retry path. The touched trap is removed while the battle
-- is on-screen, then BOTH presentation caches are invalidated so the authored
-- ball can be rebuilt on the same map.
do
  fresh()
  local obj = { index = 4, pokemon = "ELECTRODE", level = 43, sprite = "SPRITE_POKE_BALL",
    x = 25, y = 18, text = "TEXT_POWERPLANT_ELECTRODE1" }
  local region = regionFor("POWER_PLANT", obj, "Bzzzt!", "PowerPlant")
  local entity = { def = obj, staticYellowPokemon = true, sourceObject = obj,
    disguisedStaticPokemon = true, cellX = 25, cellY = 18 }
  region.npcCache.POWER_PLANT = { entity }
  region.pokemonCache.POWER_PLANT = {}
  local world = battleWorld("ELECTRODE", "lose")
  check(Twin._startStaticPokemonInteraction(world, region, "POWER_PLANT", obj, entity),
    "Electrode trap starts")
  check(region.npcCache.POWER_PLANT == nil, "blackout invalidates trap NPC cache")
  check(region.pokemonCache.POWER_PLANT == nil, "blackout invalidates Pokemon cache too")
  check(not Twin._staticPokemonCleared("POWER_PLANT", obj), "blackout does not consume trap")
end

-- Legendary/static Pokemon use the same reveal helper but stay Pokemon models.
-- A caught Mewtwo is cleared persistently, and the Gold Pokedex owns the catch.
do
  fresh()
  local obj = { index = 1, pokemon = "MEWTWO", level = 70, sprite = "SPRITE_MONSTER",
    x = 27, y = 13, text = "TEXT_CERULEANCAVEB1F_MEWTWO" }
  local region = regionFor("CERULEAN_CAVE_B1F", obj, "Mew!", "CeruleanCaveB1F")
  local entity = { species = "MEWTWO", staticYellowPokemon = true, sourceObject = obj,
    cellX = 27, cellY = 13 }
  region.pokemonCache.CERULEAN_CAVE_B1F = { entity }
  region.npcCache.CERULEAN_CAVE_B1F = {}
  local world, save = battleWorld("MEWTWO", "caught", function(wild, s)
    eq(wild.level, 70, "Mewtwo level")
    s.pokedex.caught.MEWTWO = true
  end)
  check(Twin._startStaticPokemonInteraction(world, region, "CERULEAN_CAVE_B1F", obj, entity),
    "Mewtwo interaction handled")
  eq(messages[1], "Mew!", "Mewtwo Yellow reveal text")
  check(save.pokedex.seen.MEWTWO, "Mewtwo marked seen")
  check(save.pokedex.caught.MEWTWO, "Mewtwo remains caught in Gold Pokedex")
  check(Twin._staticPokemonCleared("CERULEAN_CAVE_B1F", obj), "Mewtwo object cleared")
end

-- Once a static encounter is consumed, objectAt must not fall back to the raw
-- authored map object after its presentation entity has disappeared.
do
  fresh()
  local obj = { index = 9, pokemon = "ZAPDOS", level = 50, sprite = "SPRITE_BIRD",
    x = 4, y = 9, text = "TEXT_POWERPLANT_ZAPDOS" }
  local region, map = regionFor("POWER_PLANT", obj, "Gyaoo!", "PowerPlant")
  region.npcCache.POWER_PLANT = {}; region.pokemonCache.POWER_PLANT = {}
  Twin._markStaticPokemonCleared("POWER_PLANT", obj)
  local hit = Twin._objectAtForTest(region, "POWER_PLANT", map, 4, 9)
  check(hit == nil, "cleared static object cannot leak back through objectAt")
end

print("kanto_static_encounter_parity: OK")
