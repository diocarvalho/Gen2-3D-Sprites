-- v0.3.87 regression: Yellow's Bill -> S.S. Ticket -> S.S. Anne rival ->
-- Captain/CUT -> ship-departure chain runs against Gold-owned battle/inventory
-- without borrowing Gold's native S.S. Aqua ticket key.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, id, qty)
      if save.packFull then return false end
      save.inventory = save.inventory or {}
      save.inventory[id] = (save.inventory[id] or 0) + (qty or 1)
      return true
    end,
  }
end

local backing, messages, autoDone = {}, {}, true
_G.love = { math = { random = function(a) return a end } }

local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and opts.choice then
      if autoDone then opts.choice(true) end
    elseif onDone and autoDone then
      onDone()
    end
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
local S = Twin._kantoSSAnneForTest
local Items = Twin._kantoItemsForTest

local function check(v, label) if not v then error(label or "check failed", 2) end end
local function eq(a, b, label)
  if a ~= b then error((label or "value") .. ": expected " .. tostring(b)
    .. ", got " .. tostring(a), 2) end
end
local function contains(s, needle) return tostring(s or ""):find(needle, 1, true) ~= nil end

local billPokemon = { index = 1, x = 6, y = 5, sprite = "SPRITE_MONSTER",
  text = S.BILL.pokemonText }
local billTicket = { index = 2, x = 4, y = 4, sprite = "SPRITE_SUPER_NERD",
  text = S.BILL.ticketText, hidden = true }
local billRare = { index = 3, x = 6, y = 5, sprite = "SPRITE_SUPER_NERD",
  text = S.BILL.rareText, hidden = true }
local rivalObj = { index = 2, x = 36, y = 4, sprite = "SPRITE_BLUE",
  text = S.RIVAL.text, hidden = true }
local captainObj = { index = 1, x = 3, y = 2, sprite = "SPRITE_CAPTAIN",
  text = S.CAPTAIN.text }
local guardObj = { index = 3, x = 19, y = 30, sprite = "SPRITE_SAILOR",
  text = S.GATE.guardText }

local function blocks(width, height, value)
  local out = {}
  for i = 1, width * height do out[i] = value or 0 end
  return out
end

local function makeRegion()
  local dock = { id = S.SHIP.dockMap, width = 12, height = 4,
    blocks = blocks(12, 4, 0x55), objects = {}, warps = {} }
  return {
    version = "yellow", mapsById = {}, npcCache = {}, pokemonCache = {}, validOutdoor = {},
    loaded = {
      field = {}, tilesets = {}, items = { HM_CUT = { teaches = "CUT" } },
      maps = {
        [S.BILL.map] = { id = S.BILL.map, objects = { billPokemon, billTicket, billRare },
          width = 4, height = 4, blocks = blocks(4, 4), warps = {} },
        [S.BILL.routeMap] = { id = S.BILL.routeMap, objects = {}, width = 4, height = 4,
          blocks = blocks(4, 4), warps = {} },
        [S.GATE.map] = { id = S.GATE.map, objects = { guardObj }, width = 20, height = 20,
          blocks = blocks(20, 20), warps = {} },
        [S.RIVAL.map] = { id = S.RIVAL.map, label = "SSAnne2F", objects = { rivalObj },
          width = 20, height = 10, blocks = blocks(20, 10), warps = {} },
        [S.CAPTAIN.map] = { id = S.CAPTAIN.map, objects = { captainObj }, width = 5, height = 5,
          blocks = blocks(5, 5), warps = {} },
        [S.SHIP.dockMap] = dock,
        [S.SHIP.shipMap] = { id = S.SHIP.shipMap, objects = {}, width = 8, height = 8,
          blocks = blocks(8, 8), warps = {} },
      },
      trainers = {
        OPP_RIVAL2 = { index = 9, name = "RIVAL", baseMoney = 35,
          parties = { { { species = "EEVEE", level = 20 }, { species = "SPEAROW", level = 19 } } } },
      },
      text = {
        _SSAnne2FRivalText = "RIVAL intro",
        _SSAnne2FRivalCutMasterText = "RIVAL says the CUT master is seasick.",
        _SSAnneCaptainsRoomCaptainNotSickAnymoreText = "CAPTAIN is not sick anymore.",
      },
      textPointers = {},
    },
  }, dock
end

local capturedTrainer
local function makeWorld()
  local save = { inventory = {}, party = {}, player = { name = "GOLD" } }
  local world = {
    game = {
      save = save,
      data = {
        items = { HM_CUT = { name = "HM01", teaches = "CUT" } },
        trainers = { classes = {
          RIVAL2 = { index = 7, name = "RIVAL", baseMoney = 35, attributes = {}, items = {} },
          YOUNGSTER = { index = 1, name = "YOUNGSTER", baseMoney = 10, attributes = {}, items = {} },
        } },
      },
      stack = { push = function() return true end },
    },
  }
  world.startScriptedBattle = function(_, trainer, wild, onDone)
    capturedTrainer = trainer
    check(wild == nil, "rival uses trainer battle")
    onDone("win")
    return true
  end
  return world, save
end

local function fresh()
  backing, messages, capturedTrainer, autoDone = {}, {}, nil, true
  Twin._resetKantoStateCacheForTest()
  local ex = Twin._excursionForTest
  ex.battleBusy, ex.prevA, ex.facing = false, false, "up"
  ex.lastOutside = nil
end

-- The two tickets have the same semantic name but MUST NOT share Gold state.
do
  fresh()
  check(Items.isLocalOnly("S_S_TICKET"), "Yellow S.S. Ticket is Kanto-local")
  local world, save = makeWorld()
  Twin._giveKantoLocalItem("S_S_TICKET")
  check(Twin._kantoItemHeld(world, "S_S_TICKET"), "local ticket ownership")
  eq(save.inventory.S_S_TICKET, nil, "Gold S.S. Aqua ticket remains untouched")
end

-- Bill's Pokemon-form interaction arms the separator. Leaving before using the
-- PC resets that attempt, matching Route25ToggleBillsScript.
do
  fresh()
  local region = makeRegion()
  local world = makeWorld()
  check(Twin._kantoBillObjectInteraction(world, region, S.BILL.map, billPokemon),
    "Pokemon-form Bill handled")
  check(Twin._kantoEvent(S.BILL.saidEvent), "Bill requested separator")
  Twin._onKantoMapEntered(region, S.BILL.routeMap)
  check(not Twin._kantoEvent(S.BILL.saidEvent), "abandoned Bill attempt resets on Route 25")
end

-- Completing the separator gives a Kanto-local S.S. Ticket automatically and
-- swaps Bill into his human state without touching Gold's same-named ticket.
do
  fresh()
  local region = makeRegion()
  local world, save = makeWorld()
  check(Twin._kantoBillObjectInteraction(world, region, S.BILL.map, billPokemon), "Bill starts quest")
  Twin._excursionForTest.facing = "up"
  check(Twin._kantoBillPcInteraction(world, region, S.BILL.map, 1, 4), "Bill PC completes separator")
  check(Twin._kantoEvent(S.BILL.usedEvent), "separator event")
  check(Twin._kantoEvent(S.BILL.met2Event), "Bill transformed")
  check(Twin._kantoEvent(S.BILL.ticketEvent), "ticket event")
  check(Twin._kantoItemHeld(world, S.BILL.ticketItem), "Kanto S.S. Ticket held")
  eq(save.inventory.S_S_TICKET, nil, "native Gold S.S. Ticket still absent")
  Twin._onKantoMapEntered(region, S.BILL.routeMap)
  check(Twin._kantoEvent(S.BILL.leftEvent), "leaving Bill's house finalizes his state")
end

-- Vermilion's sailor accepts only the Kanto-local ticket. The authored gate
-- coordinate flashes it once, then normal movement can continue to the dock.
do
  fresh()
  local region = makeRegion()
  local world, save = makeWorld()
  save.inventory.S_S_TICKET = 1 -- Gold native ticket alone is deliberately insufficient.
  check(Twin._kantoSSAnneGuardTalk(world, region, S.GATE.map, guardObj), "guard talks")
  check(contains(messages[#messages], "need a ticket"), "Gold ticket does not satisfy Yellow gate")
  Twin._giveKantoLocalItem(S.BILL.ticketItem)
  Twin._excursionForTest.facing = "down"
  check(Twin._kantoSSAnneGateStep(world, region, S.GATE.map, 18, 30), "ticket checkpoint handled")
  check(Twin._kantoEvent(S.GATE.flashedEvent), "ticket flashed checkpoint persists")
end

-- The 2F corridor starts Yellow's Rival2 party 1 in Gold's real trainer battle
-- path, then permanently clears the encounter after a win.
do
  fresh()
  local region = makeRegion()
  local world = makeWorld()
  check(Twin._kantoSSAnneRivalStep(world, region, S.RIVAL.map, 36, 8), "rival trigger handled")
  check(capturedTrainer ~= nil, "Gold trainer battle started")
  eq(capturedTrainer.classId, "RIVAL2", "Rival2 Gold trainer class preserved")
  eq(capturedTrainer.roster[1].species, "EEVEE", "Yellow Rival2 party 1 used")
  check(Twin._kantoEvent(S.RIVAL.event), "rival completion persists")
  check(not Twin._kantoSSAnneRivalStep(world, region, S.RIVAL.map, 37, 8),
    "completed rival does not retrigger")
end

-- The Captain's reward is Gold's real CUT HM, while the story completion flag
-- remains Kanto-local. Repeated talks do not duplicate the HM.
do
  fresh()
  local region = makeRegion()
  local world, save = makeWorld()
  check(Twin._kantoSSAnneCaptainInteraction(world, region, S.CAPTAIN.map, captainObj),
    "Captain interaction handled")
  check(Twin._kantoEvent(S.CAPTAIN.rubbedEvent), "Captain back-rub event")
  check(Twin._kantoEvent(S.CAPTAIN.gotEvent), "HM01 story event")
  eq(save.inventory.HM_CUT, 1, "Gold CUT HM awarded")
  check(Twin._kantoSSAnneCaptainInteraction(world, region, S.CAPTAIN.map, captainObj),
    "Captain repeat handled")
  eq(save.inventory.HM_CUT, 1, "CUT HM not duplicated")
end

-- Departure sets the permanent ship-left bit and stamps the same four lower
-- Vermilion Dock blocks Yellow converts to water. Keep the UI callback parked
-- so this unit test does not need a rendered city map for the scripted exit.
do
  fresh()
  local region, dockDef = makeRegion()
  local world = makeWorld()
  Twin._excursionForTest.world = world
  Twin._setKantoEvent(S.CAPTAIN.gotEvent, true)
  local fakeDock = {
    id = "__GEN1__" .. S.SHIP.dockMap, def = dockDef,
    blockAt = function(self, bx, by) return self.def.blocks[by * self.def.width + bx + 1] end,
    setBlock = function(self, bx, by, block)
      self.def.blocks[by * self.def.width + bx + 1] = block
      return true
    end,
  }
  region.mapsById[S.SHIP.dockMap] = fakeDock
  autoDone = false
  check(Twin._kantoSSAnneWarpTransition(region, S.SHIP.shipMap, S.SHIP.dockMap),
    "ship departure transition handled")
  check(Twin._kantoEvent(S.SHIP.leftEvent), "ship-left event persists")
  for _, row in ipairs(S.SHIP.departureBlocks) do
    eq(dockDef.blocks[row.by * dockDef.width + row.bx + 1], 0x0d,
      "departed dock block becomes water")
  end
end

print("kanto_bill_ssanne_parity: OK")
