-- v0.3.71 regression: classic Kanto scripted rewards that have safe Gold
-- equivalents mutate the active Gen-2 save instead of the detached dialogue VM.

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
      local mon = { species = species, level = level,
        happiness = opts and opts.happiness or 70 }
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
    return { text = text }
  end,
}
local ListMenu = {
  new = function(_, title, items, opts)
    local menu = { title = title, items = items, opts = opts,
      close = function(self) self.closed = true end }
    menus[#menus + 1] = menu
    return menu
  end,
}

local mod = {
  exports = {},
  options = { get = function() return nil end },
  ui = { TextBox = TextBox, ListMenu = ListMenu },
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
local Rewards = Twin._rewardsForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end

local eeveeObj = { index = 1, name = "CELADONMANSION_ROOF_HOUSE_EEVEE_POKEBALL",
  text = "TEXT_CELADONMANSION_ROOF_HOUSE_EEVEE_POKEBALL" }
local leeObj = { index = 2, name = "FIGHTINGDOJO_HITMONLEE_POKE_BALL",
  text = "TEXT_FIGHTINGDOJO_HITMONLEE_POKE_BALL" }
local chanObj = { index = 3, name = "FIGHTINGDOJO_HITMONCHAN_POKE_BALL",
  text = "TEXT_FIGHTINGDOJO_HITMONCHAN_POKE_BALL" }

local region = {
  loaded = {
    text = {
      _BoxIsFullText = "BOX FULL",
      _GotMonText = "GOT {RAM:}",
      _SilphCo7FSilphWorkerM1HaveThisPokemonText = "LAPRAS INTRO",
      _SilphCo7FSilphWorkerM1LaprasDescriptionText = "LAPRAS DESC",
      _SilphCo7FSilphWorkerM1IsOurPresidentOkText = "LAPRAS AFTER",
      _SilphCo7FSilphWorkerM1SavedText = "LAPRAS SAVED",
      _MtMoonPokecenterMagikarpSalesmanIGotADealText = "MAGIKARP ASK",
      _MtMoonPokecenterMagikarpSalesmanNoText = "MAGIKARP NO",
      _MtMoonPokecenterMagikarpSalesmanNoMoneyText = "MAGIKARP BROKE",
      _MtMoonPokecenterMagikarpSalesmanNoRefundsText = "NO REFUNDS",
      _FightingDojoHitmonleePokeBallText = "TAKE HITMONLEE?",
      _FightingDojoHitmonchanPokeBallText = "TAKE HITMONCHAN?",
      _FightingDojoBetterNotGetGreedyText = "GREEDY",
      _OaksAideHiText = "AIDE ASK {NUM:}",
      _OaksAideComeBackText = "AIDE LATER",
      _OaksAideUhOhText = "AIDE ONLY {NUM:}",
      _Route2GateOaksAideFlashExplanationText = "FLASH REPEAT",
      _Route11Gate2FOaksAideItemfinderDescriptionText = "ITEMFINDER REPEAT",
      _Route15Gate2FOaksAideExpAllText = "EXP REPEAT",
      _MrPsychicsHouseMrPsychicText = "PSYCHIC INTRO",
      _MrPsychicsHouseMrPsychicNoMoreText = "PSYCHIC AFTER",
      _Route16FlyHouseBrunetteGirlText = "FLY INTRO",
      _Route16FlyHouseBrunetteGirlHm02ExplanationText = "FLY AFTER",
    },
    maps = {
      CELADON_MANSION_ROOF_HOUSE = { objects = { eeveeObj } },
      FIGHTING_DOJO = { objects = { leeObj, chanObj } },
      SILPH_CO_7F = { objects = {} }, MT_MOON_POKECENTER = { objects = {} },
      ROUTE_2_GATE = { objects = {} }, ROUTE_11_GATE_2F = { objects = {} },
      ROUTE_15_GATE_2F = { objects = {} }, MR_PSYCHICS_HOUSE = { objects = {} },
      ROUTE_16_FLY_HOUSE = { objects = {} }, CELADON_MART_ROOF = { objects = {} },
    },
    field = {},
  },
  mapsById = {}, npcCache = {}, pokemonCache = {},
}

local data = {
  pokemon = { EEVEE={}, LAPRAS={}, MAGIKARP={}, HITMONLEE={}, HITMONCHAN={} }, moves = {},
  items = {
    HM05 = { name="HM05", teaches="FLASH" }, ITEMFINDER={ name="ITEMFINDER" },
    EXP_SHARE={ name="EXP.SHARE" }, TM29={ name="TM29", teaches="PSYCHIC_M" },
    HM02={ name="HM02", teaches="FLY" }, FRESH_WATER={ name="FRESH WATER" },
    SODA_POP={ name="SODA POP" }, LEMONADE={ name="LEMONADE" },
  },
}
local world = { game = { data = data, stack = { push = function() return true end } } }

local function fresh()
  backing, messages, choices, menus, bagAdds = {}, {}, {}, {}, {}
  box, boxFull, bagFull, monBuilds, stamps = {}, false, false, {}, 0
  world.game.save = {
    player = { name="GOLD", id=2222 }, money=2000, inventory={}, party={},
    currentBox=1, pokedex={ seen={}, caught={}, owned={} },
  }
  region.npcCache, region.pokemonCache = {}, {}
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end
local function talk(mapId, text)
  return Twin._tryKantoSpecialObjectInteraction(world, region, mapId, { text=text })
end
local function seedCaught(n)
  world.game.save.pokedex.caught = {}
  for i=1,n do world.game.save.pokedex.caught["MON"..i] = true end
end

-- Tables are map+text scoped; vending is also recognized only on the rooftop.
do
  check(Rewards.match("CELADON_MANSION_ROOF_HOUSE", eeveeObj.text) == Rewards.POKEMON.EEVEE,
    "Eevee reward recognized")
  check(Rewards.match("FIGHTING_DOJO", leeObj.text) == Rewards.POKEMON.HITMONLEE,
    "Dojo reward recognized")
  check(Rewards.match("ROUTE_24", eeveeObj.text) == nil, "reward map scoped")
  eq(Rewards.match("CELADON_MART_ROOF", "TEXT_CELADONMARTROOF_VENDING_MACHINE1").kind,
    "vending", "vending recognized")
end

-- Celadon ball becomes a real level-25 Gold gift and physically disappears.
do
  fresh()
  check(Twin._tryKantoSpecialObjectInteraction(world, region,
    "CELADON_MANSION_ROOF_HOUSE", eeveeObj), "Eevee handled")
  eq(#world.game.save.party, 1, "Eevee stored")
  local mon = world.game.save.party[1]
  eq(mon.species, "EEVEE", "Eevee species"); eq(mon.level, 25, "Eevee level")
  eq(mon.happiness, 120, "Eevee gift happiness"); eq(mon.ot, "GOLD", "Eevee OT")
  check(world.game.save.pokedex.caught.EEVEE, "Eevee owned")
  check(Twin._kantoEvent(Rewards.POKEMON.EEVEE.event), "Eevee event")
  check(Twin._kantoObjectHidden("CELADON_MANSION_ROOF_HOUSE", eeveeObj), "Eevee ball hidden")
  local count=#world.game.save.party
  Twin._tryKantoSpecialObjectInteraction(world, region, "CELADON_MANSION_ROOF_HOUSE", eeveeObj)
  eq(#world.game.save.party, count, "Eevee cannot duplicate")
end

-- Full party+box refuses before building, setting an event or hiding the ball.
do
  fresh(); for i=1,6 do world.game.save.party[i]={species="RATTATA"} end; boxFull=true
  Twin._tryKantoSpecialObjectInteraction(world, region, "CELADON_MANSION_ROOF_HOUSE", eeveeObj)
  eq(#monBuilds, 0, "full Eevee refuses before build")
  check(not Twin._kantoEvent(Rewards.POKEMON.EEVEE.event), "full Eevee retryable")
  check(not Twin._kantoObjectHidden("CELADON_MANSION_ROOF_HOUSE", eeveeObj), "full Eevee visible")
end

-- Lapras is level 15, and the Magikarp salesman is atomic on decline, money and storage.
do
  fresh(); talk("SILPH_CO_7F", Rewards.POKEMON.LAPRAS.text)
  eq(world.game.save.party[1].species, "LAPRAS", "Lapras awarded")
  eq(world.game.save.party[1].level, 15, "Lapras level")
  check(Twin._kantoEvent(Rewards.POKEMON.LAPRAS.event), "Lapras event")
  eq(messages[1], "LAPRAS INTRO", "Lapras intro"); eq(messages[#messages], "LAPRAS DESC", "Lapras desc")

  fresh(); choices={false}; talk("MT_MOON_POKECENTER", Rewards.POKEMON.MAGIKARP.text)
  eq(world.game.save.money, 2000, "Magikarp decline no charge"); eq(#world.game.save.party,0,"decline no mon")
  fresh(); world.game.save.money=499; choices={true}; talk("MT_MOON_POKECENTER", Rewards.POKEMON.MAGIKARP.text)
  eq(world.game.save.money,499,"broke no charge"); eq(#world.game.save.party,0,"broke no mon")
  fresh(); for i=1,6 do world.game.save.party[i]={species="RATTATA"} end; boxFull=true; choices={true}
  talk("MT_MOON_POKECENTER", Rewards.POKEMON.MAGIKARP.text)
  eq(world.game.save.money,2000,"full Magikarp no charge"); check(not Twin._kantoEvent(Rewards.POKEMON.MAGIKARP.event),"full sale retryable")
  fresh(); choices={true}; talk("MT_MOON_POKECENTER", Rewards.POKEMON.MAGIKARP.text)
  eq(world.game.save.money,1500,"Magikarp costs 500"); eq(world.game.save.party[1].species,"MAGIKARP","Magikarp awarded")
  eq(world.game.save.party[1].level,5,"Magikarp level"); check(Twin._kantoEvent(Rewards.POKEMON.MAGIKARP.event),"sale event")
end

-- Dojo preview marks seen, NO stays retryable, YES gives one L30 fighter, hides only chosen ball.
do
  fresh(); choices={true}; talk("FIGHTING_DOJO", Rewards.POKEMON.HITMONLEE.text)
  check(not world.game.save.pokedex.seen.HITMONLEE, "unbeaten master does not preview")
  Twin._setKantoEvent("EVENT_BEAT_KARATE_MASTER", true); choices={false}
  talk("FIGHTING_DOJO", Rewards.POKEMON.HITMONLEE.text)
  check(world.game.save.pokedex.seen.HITMONLEE, "dojo preview marks seen")
  check(not Twin._kantoEvent(Rewards.POKEMON.HITMONLEE.event), "dojo NO retryable")
  choices={true}; talk("FIGHTING_DOJO", Rewards.POKEMON.HITMONLEE.text)
  eq(world.game.save.party[1].species,"HITMONLEE","Hitmonlee awarded")
  eq(world.game.save.party[1].level,30,"Dojo level")
  check(Twin._kantoObjectHidden("FIGHTING_DOJO", leeObj),"chosen ball hidden")
  check(not Twin._kantoObjectHidden("FIGHTING_DOJO", chanObj),"other ball remains")
  local count=#world.game.save.party; talk("FIGHTING_DOJO", Rewards.POKEMON.HITMONCHAN.text)
  eq(#world.game.save.party,count,"cannot claim both dojo prizes"); eq(messages[#messages],"GREEDY","other ball greedy text")
end

-- Oak's aides use Gold-safe equivalents and exact 10/30/50 ownership gates.
do
  fresh(); seedCaught(9); choices={true}; talk("ROUTE_2_GATE", Rewards.AIDES.ROUTE_2_GATE.text)
  check(not world.game.save.inventory.HM05,"9 caught no Flash")
  seedCaught(10); choices={true}; talk("ROUTE_2_GATE", Rewards.AIDES.ROUTE_2_GATE.text)
  eq(world.game.save.inventory.HM05,1,"10 caught gives HM05"); check(Twin._kantoEvent("EVENT_GOT_HM_FLASH"),"Flash event")
  fresh(); seedCaught(30); choices={true}; talk("ROUTE_11_GATE_2F", Rewards.AIDES.ROUTE_11_GATE_2F.text)
  eq(world.game.save.inventory.ITEMFINDER,1,"30 caught gives Itemfinder")
  fresh(); seedCaught(50); choices={true}; talk("ROUTE_15_GATE_2F", Rewards.AIDES.ROUTE_15_GATE_2F.text)
  eq(world.game.save.inventory.EXP_SHARE,1,"50 caught maps EXP.ALL to EXP.SHARE")
  -- Mixed caught+owned tables count a union rather than losing migrated entries.
  world.game.save.pokedex.caught={A=true}; world.game.save.pokedex.owned={B=true,A=true}
  eq(Rewards.countOwned(world.game.save),2,"Pokedex union count")
end

-- Mr Psychic and the Fly girl award the Gold move-equivalent TM/HM exactly once.
do
  fresh(); talk("MR_PSYCHICS_HOUSE", Rewards.ITEM_GIFTS.MR_PSYCHIC.text)
  eq(world.game.save.inventory.TM29,1,"Mr Psychic gives TM29")
  check(Twin._kantoEvent("EVENT_GOT_TM29"),"TM29 event")
  local have=world.game.save.inventory.TM29; talk("MR_PSYCHICS_HOUSE", Rewards.ITEM_GIFTS.MR_PSYCHIC.text)
  eq(world.game.save.inventory.TM29,have,"TM29 cannot duplicate")
  fresh(); talk("ROUTE_16_FLY_HOUSE", Rewards.ITEM_GIFTS.FLY_GIRL.text)
  eq(world.game.save.inventory.HM02,1,"Fly girl gives HM02")
  check(Twin._kantoEvent("EVENT_GOT_HM02"),"HM02 event")
end

-- Rooftop drinks preserve the vending transaction order: no money moves when
-- the PACK is full, and successful purchases use the retail prices.
do
  fresh(); world.game.save.money=500; bagFull=true
  Twin._buyKantoVendingDrink(world, Rewards.VENDING.drinks[1])
  eq(world.game.save.money,500,"full bag vending no charge"); check(not world.game.save.inventory.FRESH_WATER,"full bag no drink")
  bagFull=false; Twin._buyKantoVendingDrink(world, Rewards.VENDING.drinks[1])
  eq(world.game.save.money,300,"Fresh Water costs 200"); eq(world.game.save.inventory.FRESH_WATER,1,"Fresh Water added")
  Twin._tryKantoSpecialObjectInteraction(world, region, "CELADON_MART_ROOF",
    {text="TEXT_CELADONMARTROOF_VENDING_MACHINE1"})
  eq(menus[#menus].title,"VENDING MACHINE","vending opens menu")
  eq(#menus[#menus].items,3,"vending has three drinks")
end

-- Upgrade/reload repairs stale reward objects from persistent completion state.
do
  fresh(); backing.yellowPhysicalEventsV1={ [Rewards.POKEMON.EEVEE.event]=true }
  Twin._resetKantoStateCacheForTest()
  check(Twin._migrateKantoRewardObjects(region,"CELADON_MANSION_ROOF_HOUSE"),"Eevee object migration")
  check(Twin._kantoObjectHidden("CELADON_MANSION_ROOF_HOUSE",eeveeObj),"migration hides Eevee ball")
end

print("kanto_scripted_rewards_parity: ok")
