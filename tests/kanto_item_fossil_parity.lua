-- v0.3.83 regression: Yellow item ids are translated safely into Gold,
-- conflicting story keys stay Kanto-local, and Mt. Moon fossils revive through
-- the Cinnabar Lab without enabling Yellow story ASM.

package.preload["src.render.Assets"] = function() return {} end

local bagFull, bagAdds = false, {}
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, id, count)
      if bagFull then return false end
      save.inventory = save.inventory or {}
      save.inventory[id] = (tonumber(save.inventory[id]) or 0) + (count or 1)
      bagAdds[#bagAdds + 1] = id
      return true
    end,
    remove = function(save, id, count)
      save.inventory = save.inventory or {}
      local left = (tonumber(save.inventory[id]) or 0) - (count or 1)
      save.inventory[id] = left > 0 and left or nil
      return true
    end,
  }
end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

local boxFull, box = false, {}
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
      local mon = { species=species, level=level,
        happiness=opts and opts.happiness or 70 }
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

local backing, messages, choices, menus = {}, {}, {}, {}
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
    return { text=text }
  end,
}
local ListMenu = {
  new = function(_, title, items, opts)
    local menu = { title=title, items=items, opts=opts,
      close=function(self) self.closed=true end }
    menus[#menus + 1] = menu
    return menu
  end,
}

local mod = {
  exports = {},
  options = { get = function() return nil end },
  ui = { TextBox=TextBox, ListMenu=ListMenu },
  save = {
    get = function(_, key, fallback)
      local value = backing[key]
      return value == nil and fallback or value
    end,
    set = function(_, key, value) backing[key]=value; return true end,
  },
}

local stubs = {
  Quality = { kantoRadius=function() return 1 end,
              actorDistanceCells=function() return math.huge end },
  FirstPerson = { driving=function() return false end,
                  releaseBody=function() end },
  ChunkMesher = { warmPending=function() return 0 end,
                  refresh=function() return true end },
  KantoGen2Style = { PROJECTION_REV="test" },
  runtime_sheets = { new=function() return { load=function() return true end } end },
}
local V = { mod=mod, require=function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Items = Twin._kantoItemsForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end

local dome = { index=7, name="MTMOONB2F_DOME_FOSSIL", x=12, y=6,
  text="TEXT_MTMOONB2F_DOME_FOSSIL" }
local helix = { index=8, name="MTMOONB2F_HELIX_FOSSIL", x=13, y=6,
  text="TEXT_MTMOONB2F_HELIX_FOSSIL" }
local secretKey = { index=12, name="POKEMON_MANSION_SECRET_KEY", item="SECRET_KEY" }
local cardKey = { index=4, name="SILPH_CARD_KEY", item="CARD_KEY" }
local thunderTm = { index=5, name="POWER_PLANT_TM_THUNDER", item="TM_THUNDER" }
local megaPunchTm = { index=6, name="MT_MOON_TM_MEGA_PUNCH", item="TM_MEGA_PUNCH" }

local region = {
  loaded = {
    items = {
      POTION={ id="POTION", name="POTION" },
      TM_THUNDER={ id="TM_THUNDER", name="TM25", machine={kind="TM",number=25,move="THUNDER"} },
      TM_MEGA_PUNCH={ id="TM_MEGA_PUNCH", name="TM01", machine={kind="TM",number=1,move="MEGA_PUNCH"} },
    },
    text = { _CinnabarIslandDoorIsLockedText="The door is locked..." },
    maps = {
      MT_MOON_B2F={ objects={ dome, helix } },
      POKEMON_MANSION_B1F={ objects={ secretKey } },
      SILPH_CO_5F={ objects={ cardKey } },
      POWER_PLANT={ objects={ thunderTm } },
      CINNABAR_LAB_FOSSIL_ROOM={ objects={} },
      CINNABAR_ISLAND={ objects={} },
    },
    field = {},
  },
  mapsById={}, npcCache={}, pokemonCache={},
}

local world = {
  game = {
    data = {
      pokemon={ KABUTO={}, OMANYTE={}, AERODACTYL={} }, moves={},
      items={
        POTION={ name="POTION", pocket="ITEM" },
        TM25={ name="TM25", teaches="THUNDER", pocket="TM_HM" },
        CARD_KEY={ name="CARD KEY", pocket="KEY_ITEM" }, -- Johto story key: must not be reused
      },
    },
    stack={
      push=function(self, x) self.last=x; return true end,
      top=function(self) return self.last end,
      pop=function(self) local x=self.last; self.last=nil; return x end,
    },
  },
}

local function fresh()
  backing, messages, choices, menus, bagAdds = {}, {}, {}, {}, {}
  box, boxFull, bagFull, monBuilds, stamps = {}, false, false, {}, 0
  world.game.save = {
    player={ name="GOLD", id=4242 }, inventory={}, party={}, currentBox=1,
    pokedex={ seen={}, caught={}, owned={} },
  }
  region.npcCache, region.pokemonCache = {}, {}
  world.game.stack.last = nil
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end

-- Item translation: ordinary ids pass through, machines follow the move, and
-- colliding Yellow story keys are intentionally local-only.
do
  local gid, mode, move = Items.resolveGoldItem(world.game.data.items, region.loaded.items, "POTION")
  eq(gid, "POTION", "ordinary direct item"); eq(mode, "direct", "direct mode")
  gid, mode, move = Items.resolveGoldItem(world.game.data.items, region.loaded.items, "TM_THUNDER")
  eq(gid, "TM25", "Thunder semantic TM"); eq(mode, "machine", "machine mode")
  eq(move, "THUNDER", "machine move")
  gid, mode, move = Items.resolveGoldItem(world.game.data.items, region.loaded.items, "TM_MEGA_PUNCH")
  eq(gid, nil, "no Mega Punch Gold TM"); eq(mode, "no-machine", "no-machine mode")
  eq(move, "MEGA_PUNCH", "no-machine move preserved")
  gid, mode = Items.resolveGoldItem(world.game.data.items, region.loaded.items, "CARD_KEY")
  eq(gid, nil, "Yellow Card Key never aliases Gold Card Key")
  eq(mode, "local", "Card Key local mode")
end

-- A Gold Radio Tower Card Key does NOT unlock Silph. Picking up Yellow's Card
-- Key creates a Kanto-local bit and leaves Gold's inventory count untouched.
do
  fresh()
  world.game.save.inventory.CARD_KEY = 1
  check(not Twin._kantoItemHeld(world, "CARD_KEY"), "Gold Card Key is not Kanto Card Key")
  check(Twin._pickupYellowItem(world, region, "SILPH_CO_5F", cardKey), "Kanto Card Key pickup handled")
  check(Twin._kantoItemHeld(world, "CARD_KEY"), "Kanto Card Key stored locally")
  eq(world.game.save.inventory.CARD_KEY, 1, "Gold Card Key inventory unchanged")
end

-- Yellow machine pickup resolves to Gold's same-move TM. A move with no Gold
-- machine remains physically unconsumed instead of giving the wrong numbered TM.
do
  fresh()
  check(Twin._pickupYellowItem(world, region, "POWER_PLANT", thunderTm), "Thunder TM pickup handled")
  eq(world.game.save.inventory.TM25, 1, "Gold Thunder TM received")
  eq(bagAdds[1], "TM25", "semantic TM added to bag")

  local before = #bagAdds
  check(Twin._pickupYellowItem(world, region, "MT_MOON_B2F", megaPunchTm), "unsupported TM interaction handled")
  eq(#bagAdds, before, "unsupported TM not added")
  check(messages[#messages]:find("no equivalent TM/HM", 1, true) ~= nil,
    "unsupported machine explains why it remains")
end

-- Secret Key is Kanto-local and the Cinnabar gate matches Yellow's exact
-- destination cell/direction. Gold has no story-key pollution.
do
  fresh()
  local gate = Twin._kantoItemGateForStep(region, "CINNABAR_ISLAND", 18, 4, "up")
  check(gate and gate.item == "SECRET_KEY", "Cinnabar Secret Key gate")
  check(Twin._kantoItemGateForStep(region, "CINNABAR_ISLAND", 18, 4, "down") == nil,
    "gate direction scoped")
  check(Twin._pickupYellowItem(world, region, "POKEMON_MANSION_B1F", secretKey), "Secret Key pickup handled")
  check(Twin._kantoItemHeld(world, "SECRET_KEY"), "Secret Key stored locally")
  eq(world.game.save.inventory.SECRET_KEY, nil, "Secret Key not injected into Gold bag")
end

-- Mt. Moon: no fossil before the Super Nerd is beaten. Afterwards choosing one
-- gives exactly one local fossil and physically hides BOTH fossil objects.
do
  fresh(); choices={true}
  check(Twin._takeMtMoonFossil(world, region, "MT_MOON_B2F", dome), "pre-Nerd fossil interaction handled")
  check(not Twin._kantoItemHeld(world, "DOME_FOSSIL"), "pre-Nerd fossil unavailable")

  Twin._setKantoEvent(Items.MT_MOON.prerequisite, true)
  choices={true}
  check(Twin._takeMtMoonFossil(world, region, "MT_MOON_B2F", dome), "Dome fossil choice handled")
  check(Twin._kantoItemHeld(world, "DOME_FOSSIL"), "Dome fossil owned")
  check(Twin._kantoEvent("EVENT_GOT_DOME_FOSSIL"), "Dome event set")
  check(Twin._kantoObjectHidden("MT_MOON_B2F", dome), "Dome object hidden")
  check(Twin._kantoObjectHidden("MT_MOON_B2F", helix), "other fossil object hidden")
  choices={true}
  Twin._takeMtMoonFossil(world, region, "MT_MOON_B2F", helix)
  check(not Twin._kantoItemHeld(world, "HELIX_FOSSIL"), "cannot take second fossil")
end

-- Cinnabar Lab: submission consumes the local fossil, remains pending while the
-- player stays indoors, becomes ready only after entering Cinnabar Island, then
-- returns a genuine level-30 Gold gift with happiness 120 and player OT.
do
  fresh()
  Twin._giveKantoLocalItem("DOME_FOSSIL")
  choices={true}
  check(Twin._kantoFossilScientist(world, region), "fossil submission handled")
  check(not Twin._kantoItemHeld(world, "DOME_FOSSIL"), "fossil consumed by scientist")
  local pending = Twin._kantoFossilLabState()
  eq(pending.species, "KABUTO", "Dome revives Kabuto")
  eq(pending.level, 30, "revival level")
  eq(pending.ready, false, "not immediately ready")

  check(Twin._kantoFossilScientist(world, region), "waiting scientist handled")
  eq(#world.game.save.party, 0, "cannot collect before walking outside")
  check(Twin._markKantoFossilReady("CINNABAR_ISLAND"), "Cinnabar outdoor step readies fossil")
  pending = Twin._kantoFossilLabState(); check(pending.ready == true, "pending state ready")

  check(Twin._kantoFossilScientist(world, region), "revived fossil collection handled")
  eq(#world.game.save.party, 1, "revived mon enters Gold party")
  local mon = world.game.save.party[1]
  eq(mon.species, "KABUTO", "revived species")
  eq(mon.level, 30, "revived level 30")
  eq(mon.happiness, 120, "Gen2 gift happiness")
  eq(mon.ot, "GOLD", "player OT")
  eq(mon.otId, 4242, "player OT id")
  check(world.game.save.pokedex.caught.KABUTO, "revived mon owned in Gold dex")
  check(Twin._kantoFossilLabState().species == nil, "pending revival cleared only after storage")
end

-- Full party + current box is atomic at the collection window: pending fossil
-- survives and can be collected after space is made.
do
  fresh()
  Twin._giveKantoLocalItem("HELIX_FOSSIL")
  choices={true}
  Twin._kantoFossilScientist(world, region)
  Twin._markKantoFossilReady("CINNABAR_ISLAND")
  for i=1,6 do world.game.save.party[i]={species="RATTATA"} end
  boxFull=true
  Twin._kantoFossilScientist(world, region)
  eq(#monBuilds, 0, "full storage refuses before mon build")
  eq(Twin._kantoFossilLabState().species, "OMANYTE", "full storage keeps pending fossil")
  boxFull=false
  Twin._kantoFossilScientist(world, region)
  eq(#box, 1, "retry stores revived mon in box")
  eq(box[1].species, "OMANYTE", "Helix revives Omanyte")
  check(Twin._kantoFossilLabState().species == nil, "retry clears pending state")
end

print("kanto_item_fossil_parity: ok")
