-- v0.3.88 regression: Yellow's Silph Co 11F Jessie/James -> Giovanni ->
-- Saffron liberation -> President MASTER BALL chain runs through Gold-owned
-- battles/items, and non-Gym Giovanni encounters can never award EARTHBADGE.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, id, qty)
      if save.packFull then return false end
      save.inventory = save.inventory or {}
      save.inventory[id] = (tonumber(save.inventory[id]) or 0) + (qty or 1)
      return true
    end,
  }
end

local backing, messages, capturedTrainer = {}, {}, nil
_G.love = { math = { random = function(a) return a end } }

local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and opts.choice then opts.choice(true)
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
local S = Twin._kantoSilphForTest

local function check(v, label) if not v then error(label or "check failed", 2) end end
local function eq(a, b, label)
  if a ~= b then error((label or "value") .. ": expected " .. tostring(b)
    .. ", got " .. tostring(a), 2) end
end
local function contains(s, needle) return tostring(s or ""):find(needle, 1, true) ~= nil end

local james = { index = 4, x = 2, y = 8, sprite = "SPRITE_JAMES", text = S.FINAL.jamesText, hidden = true }
local jessie = { index = 6, x = 3, y = 8, sprite = "SPRITE_JESSIE", text = S.FINAL.jessieText, hidden = true }
local giovanni = { index = 3, x = 6, y = 9, sprite = "SPRITE_GIOVANNI",
  text = S.FINAL.giovanniText, trainerClass = "OPP_GIOVANNI", trainerParty = 2 }
local floorRocket = { index = 5, x = 15, y = 9, sprite = "SPRITE_ROCKET",
  text = "TEXT_SILPHCO11F_ROCKET", trainerClass = "OPP_ROCKET", trainerParty = 40 }
local president = { index = 1, x = 7, y = 5, sprite = "SPRITE_SILPH_PRESIDENT",
  text = S.FINAL.presidentText }
local lowerRocket = { index = 2, x = 4, y = 4, sprite = "SPRITE_ROCKET",
  text = "TEXT_SILPHCO5F_ROCKET", trainerClass = "OPP_ROCKET", trainerParty = 12 }

local saffronRocket = { index = 1, sprite = "SPRITE_ROCKET", text = "TEXT_SAFFRONCITY_ROCKET1" }
local saffronRocket8 = { index = 14, sprite = "SPRITE_ROCKET", text = "TEXT_SAFFRONCITY_ROCKET8" }
local saffronScientist = { index = 8, sprite = "SPRITE_SCIENTIST",
  text = "TEXT_SAFFRONCITY_SCIENTIST", hidden = true }
local saffronWorker = { index = 9, sprite = "SPRITE_SILPH_WORKER_M",
  text = "TEXT_SAFFRONCITY_SILPH_WORKER_M", hidden = true }

local function blocks(w, h)
  local out = {}
  for i = 1, w * h do out[i] = 0 end
  return out
end

local function makeRegion()
  return {
    version = "yellow", mapsById = {}, npcCache = {}, pokemonCache = {}, validOutdoor = {},
    loaded = {
      field = {}, tilesets = {}, items = { MASTER_BALL = { name = "MASTER BALL" } },
      maps = {
        SILPH_CO_11F = { id = "SILPH_CO_11F", label = "SilphCo11F", width = 20, height = 20,
          blocks = blocks(20, 20), warps = {},
          objects = { president, { index=2, text="TEXT_SILPHCO11F_BEAUTY" }, giovanni,
            james, floorRocket, jessie } },
        SILPH_CO_5F = { id = "SILPH_CO_5F", width = 12, height = 12,
          blocks = blocks(12, 12), warps = {}, objects = { lowerRocket } },
        SAFFRON_CITY = { id = "SAFFRON_CITY", width = 20, height = 20,
          blocks = blocks(20, 20), warps = {},
          objects = { saffronRocket, saffronScientist, saffronWorker, saffronRocket8 } },
      },
      trainers = {
        OPP_ROCKET = { index = 10, name = "ROCKET", baseMoney = 30,
          parties = { [45] = { { species = "WEEZING", level = 31 },
                               { species = "ARBOK", level = 31 } } } },
        OPP_GIOVANNI = { index = 9, name = "GIOVANNI", baseMoney = 99,
          parties = { [2] = { { species = "NIDORINO", level = 37 },
                              { species = "PERSIAN", level = 35 } } } },
      },
      text = {
        _SilphCoJessieJamesText1 = "Prepare for trouble!",
        _SilphCoJessieJamesText4 = "TEAM ROCKET blasted off!",
        _SilphCo11FGiovanniText = "GIOVANNI challenges you!",
        _SilphCo11FGiovanniYouRuinedOurPlansText = "You ruined our plans!",
        _SilphCo11FSilphPresidentText = "Thank you for saving SILPH!",
        _SilphCo11FSilphPresidentReceivedMasterBallText = "Received MASTER BALL!",
        _SilphCo11FSilphPresidentMasterBallDescriptionText = "MASTER BALL catches without fail.",
        _SilphCo11FSilphPresidentNoRoomText = "No room!",
      },
      textPointers = {}, trainerHeaders = {},
    },
  }
end

local function makeWorld()
  local save = { inventory = {}, party = {}, player = { name = "GOLD", kantoBadges = {} } }
  local world = {
    game = {
      save = save,
      data = {
        items = { MASTER_BALL = { name = "MASTER BALL" } },
        trainers = { classes = {
          ROCKET = { index = 5, name = "ROCKET", baseMoney = 30, attributes = {}, items = {} },
          ROCKET_EXECUTIVE = { index = 6, name = "EXECUTIVE", baseMoney = 99, attributes = {}, items = {} },
          YOUNGSTER = { index = 1, name = "YOUNGSTER", baseMoney = 10, attributes = {}, items = {} },
        } },
      },
      stack = { push = function() return true end },
    },
  }
  world.startScriptedBattle = function(_, trainer, wild, onDone)
    capturedTrainer = trainer
    check(wild == nil, "Silph uses trainer battle")
    onDone("win")
    return true
  end
  return world, save
end

local function fresh()
  backing, messages, capturedTrainer = {}, {}, nil
  Twin._resetKantoStateCacheForTest()
  local e = Twin._excursionForTest
  e.battleBusy, e.prevA, e.facing = false, false, "up"
end

-- Static Yellow trigger facts are exact.
do
  check(S.duoStep("SILPH_CO_11F", 0, 3), "duo trigger x0")
  check(S.duoStep("SILPH_CO_11F", 3, 3), "duo trigger x3")
  check(not S.duoStep("SILPH_CO_11F", 4, 3), "duo x4 outside trigger")
  check(S.giovanniStep("SILPH_CO_11F", 6, 13), "Giovanni trigger lower")
  check(S.giovanniStep("SILPH_CO_11F", 7, 12), "Giovanni trigger upper-right")
end

-- Giovanni's class is reused outside Viridian Gym. Only the actual Gym map is
-- allowed to mark the trainer as a Kanto Gym battle.
do
  fresh()
  local region, world = makeRegion(), makeWorld()
  local rocketBoss = assert(Twin._yellowTrainer(region, world, giovanni, "ROCKET_HIDEOUT_B4F"))
  local silphBoss = assert(Twin._yellowTrainer(region, world, giovanni, "SILPH_CO_11F"))
  local gymBoss = assert(Twin._yellowTrainer(region, world, giovanni, "VIRIDIAN_GYM"))
  check(not rocketBoss._stadiumYellowGym, "Rocket Hideout Giovanni is not Gym battle")
  check(not silphBoss._stadiumYellowGym, "Silph Giovanni is not Gym battle")
  check(gymBoss._stadiumYellowGym, "Viridian Giovanni remains Gym battle")
end

-- Before liberation, Saffron's Rocket occupation is authoritative even if an
-- imported cache exposes the post-event civilians incorrectly.
do
  fresh()
  local region = makeRegion()
  Twin._onKantoMapEntered(region, S.SAFFRON.map)
  check(Twin._kantoObjectShown(S.SAFFRON.map, saffronRocket), "Saffron Rocket forced visible pre-liberation")
  check(Twin._kantoObjectHidden(S.SAFFRON.map, saffronScientist), "Saffron civilian hidden pre-liberation")
end

-- The authored 11F Jessie/James trigger uses Yellow's OPP_ROCKET party $2d,
-- then removes the duo persistently.
do
  fresh()
  local region, world = makeRegion(), makeWorld()
  check(Twin._kantoSilphDuoStep(world, region, S.FINAL.map, 2, 3), "Silph duo trigger handled")
  check(capturedTrainer ~= nil, "duo starts Gold trainer battle")
  eq(capturedTrainer.classId, "ROCKET", "duo maps to Gold ROCKET class")
  eq(capturedTrainer.roster[1].species, "WEEZING", "Yellow party $2d selected")
  check(Twin._kantoEvent(S.FINAL.duoEvent), "duo win event persists")
  check(Twin._kantoObjectHidden(S.FINAL.map, james), "James hidden after win")
  check(Twin._kantoObjectHidden(S.FINAL.map, jessie), "Jessie hidden after win")
end

-- Giovanni is the non-Gym OPP_GIOVANNI party 2 battle. Winning liberates the
-- tower/city but never grants EARTHBADGE.
do
  fresh()
  local region, world, save = makeRegion(), nil, nil
  world, save = makeWorld()
  Twin._setKantoEvent(S.FINAL.duoEvent, true)
  check(Twin._kantoSilphGiovanniStep(world, region, S.FINAL.map, 6, 13), "Giovanni trigger handled")
  check(capturedTrainer ~= nil, "Giovanni starts Gold battle")
  eq(capturedTrainer.classId, "ROCKET_EXECUTIVE", "Giovanni uses Gold-compatible boss class")
  check(not capturedTrainer._stadiumYellowGym, "Silph Giovanni not flagged as Gym")
  check(Twin._kantoEvent(S.FINAL.giovanniEvent), "Giovanni completion persists")
  check(not (save.player.kantoBadges and save.player.kantoBadges.EARTH), "Silph cannot award EARTHBADGE")
  check(Twin._kantoObjectHidden(S.FINAL.map, giovanni), "Giovanni removed after liberation")
  check(Twin._kantoObjectHidden(S.FINAL.map, floorRocket), "11F Rocket removed after liberation")
  check(Twin._kantoObjectHidden("SILPH_CO_5F", lowerRocket), "lower-floor Rocket removed globally")
  check(Twin._kantoObjectHidden(S.SAFFRON.map, saffronRocket), "Saffron Rocket removed")
  check(Twin._kantoObjectHidden(S.SAFFRON.map, saffronRocket8), "Saffron door Rocket removed")
  check(Twin._kantoObjectShown(S.SAFFRON.map, saffronScientist), "Saffron scientist restored")
  check(Twin._kantoObjectShown(S.SAFFRON.map, saffronWorker), "Saffron worker restored")
end

-- The President gives a real Gold MASTER BALL only after liberation. Bag-full
-- refusal leaves the Yellow event unset so the gift can be retried.
do
  fresh()
  local region = makeRegion()
  local world, save = makeWorld()
  check(Twin._kantoSilphPresidentInteraction(world, region, S.FINAL.map, president),
    "pre-liberation president interaction handled")
  eq(save.inventory.MASTER_BALL, nil, "no Master Ball before liberation")

  Twin._setKantoEvent(S.FINAL.giovanniEvent, true)
  save.packFull = true
  check(Twin._kantoSilphPresidentInteraction(world, region, S.FINAL.map, president),
    "bag-full president retry handled")
  check(not Twin._kantoEvent(S.FINAL.masterBallEvent), "bag full sets no reward event")
  check(contains(messages[#messages], "No room"), "bag-full authored text")

  save.packFull = false
  check(Twin._kantoSilphPresidentInteraction(world, region, S.FINAL.map, president),
    "Master Ball reward succeeds")
  eq(save.inventory.MASTER_BALL, 1, "real Gold Master Ball added")
  check(Twin._kantoEvent(S.FINAL.masterBallEvent), "Master Ball event persists")
  check(Twin._kantoSilphPresidentInteraction(world, region, S.FINAL.map, president),
    "repeat president talk handled")
  eq(save.inventory.MASTER_BALL, 1, "repeat talk does not duplicate reward")
end

print("kanto_silph_liberation_parity: OK")
