-- v0.3.69 regression: story-free Vermilion Fan Club -> Cerulean Bike Shop
-- chain. Gold owns BICYCLE; BIKE VOUCHER is Kanto-local on normal Gen-2 hosts
-- but can migrate/use a physical item if an injected host actually defines it.

package.preload["src.render.Assets"] = function() return {} end
local bagAccept = { BIKE_VOUCHER = true, BICYCLE = true }
local keySlots, keyCap = 0, 25
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, item, count)
      if bagAccept[item] == false then return false end
      save.inventory = save.inventory or {}
      save.inventory[item] = (tonumber(save.inventory[item]) or 0) + (count or 1)
      return true
    end,
    remove = function(save, item, count)
      save.inventory = save.inventory or {}
      local left = (tonumber(save.inventory[item]) or 0) - (count or 1)
      save.inventory[item] = left > 0 and left or nil
    end,
    slots = function(_, _, pocket) return pocket == "KEY_ITEM" and keySlots or 0 end,
    capacity = function(_, pocket) return pocket == "KEY_ITEM" and keyCap or 20 end,
  }
end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

_G.love = { math = { random = function(a) return a end } }

local backing, messages, choices, menuChoice = {}, {}, {}, nil
local lastMenu = nil
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
    local menu = { closed = false, close = function(self) self.closed = true end }
    lastMenu = { title = title, items = items, menu = menu }
    local picked
    if menuChoice == true then picked = items[1]
    elseif menuChoice == false then picked = items[2] end
    if picked and opts and type(opts.onChoose) == "function" then opts.onChoose(picked, menu) end
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
local Civic = Twin._civicForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end
local function seen(text)
  for _, value in ipairs(messages) do if value == text then return true end end
  return false
end
local function fresh()
  backing, messages, choices, menuChoice, lastMenu = {}, {}, {}, nil, nil
  bagAccept = { BIKE_VOUCHER = true, BICYCLE = true }
  keySlots, keyCap = 0, 25
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end

local region = {
  loaded = {
    text = {
      _PokemonFanClubChairmanIntroText = "CHAIR INTRO",
      _PokemonFanClubChairmanStoryText = "CHAIR STORY",
      _PokemonFanClubReceivedBikeVoucherText = "GOT VOUCHER",
      _PokemonFanClubExplainBikeVoucherText = "EXPLAIN VOUCHER",
      _PokemonFanClubNoStoryText = "NO STORY",
      _PokemonFanClubChairFinalText = "CHAIR FINAL",
      _BagFullText = "BAG FULL",
      _BikeShopClerkHowDoYouLikeYourBicycleText = "HOW IS BIKE",
      _BikeShopClerkOhThatsAVoucherText = "OH VOUCHER",
      _BikeShopBagFullText = "BIKE BAG FULL",
      _BikeShopExchangedVoucherText = "EXCHANGED",
      _BikeShopClerkWelcomeText = "WELCOME",
      _BikeShopClerkDoYouLikeItText = "BIKE PITCH",
      _BikeShopCantAffordText = "CANT AFFORD",
      _BikeShopComeAgainText = "COME AGAIN",
    },
    maps = {}, field = {},
  },
  mapsById = {}, npcCache = {}, pokemonCache = {},
}
local world = {
  game = {
    -- Normal Gold host: BICYCLE exists, BIKE_VOUCHER does not.
    data = { items = { BICYCLE = { name = "BICYCLE", pocket = "KEY_ITEM" } } },
    save = { money = 999999, inventory = {} },
    stack = { push = function() return true end },
  },
}

-- Exact interaction ownership: only the authored maps/text rows are promoted
-- out of the dialogue sandbox into real service actions.
do
  check(Civic.isFanClubChairman("POKEMON_FAN_CLUB", "TEXT_POKEMONFANCLUB_CHAIRMAN"),
        "Fan Club chairman row recognized")
  check(not Civic.isFanClubChairman("VERMILION_CITY", "TEXT_POKEMONFANCLUB_CHAIRMAN"),
        "chairman row is map-scoped")
  check(Civic.isBikeShopClerk("BIKE_SHOP", "TEXT_BIKESHOP_CLERK"),
        "Bike Shop clerk row recognized")
end

-- Chairman NO path: no story, no gift, no event, so a later visit can retry.
do
  fresh(); world.game.save.inventory = {}; choices = { false }
  check(Twin._talkKantoFanClubChairman(world, region), "chairman decline handled")
  eq(messages[1], "CHAIR INTRO", "chairman asks first")
  eq(messages[2], "NO STORY", "decline skips story")
  check(not Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "decline leaves event clear")
end

-- Normal Gold has no BIKE_VOUCHER item definition. The service therefore uses
-- Kanto-local possession but still honors the real KEY_ITEM pocket capacity.
do
  fresh(); world.game.save.inventory = {}; choices = { true }; keySlots = keyCap
  check(Twin._talkKantoFanClubChairman(world, region), "chairman full key pocket handled")
  check(seen("CHAIR STORY"), "YES hears chairman story")
  eq(messages[#messages], "BAG FULL", "full Gold key-item pocket refuses voucher")
  check(not Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "full pocket sets no voucher event")

  fresh(); world.game.save.inventory = {}; choices = { true }
  local before, localBefore = Twin.yellowBikeVouchers or 0, Twin.yellowLocalBikeVouchers or 0
  check(Twin._talkKantoFanClubChairman(world, region), "local voucher award handled")
  eq(world.game.save.inventory.BIKE_VOUCHER, nil, "Gen-1-only voucher is not invented in Gold bag")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "Kanto-local voucher possession persists")
  eq(Twin.yellowBikeVouchers, before + 1, "voucher diagnostic increments")
  eq(Twin.yellowLocalBikeVouchers, localBefore + 1, "local-voucher diagnostic increments")
  eq(messages[#messages - 1], "GOT VOUCHER", "received line")
  eq(messages[#messages], "EXPLAIN VOUCHER", "voucher explanation follows")
  check(Twin._talkKantoFanClubChairman(world, region), "served chairman handled")
  eq(messages[#messages], "CHAIR FINAL", "served chairman uses final text")
end

-- Compatibility host: if BIKE_VOUCHER really is defined, use the real Gold Bag
-- item and preserve GiveItem's bag-full semantics instead of forcing local mode.
do
  fresh(); world.game.data.items.BIKE_VOUCHER = { name = "BIKE VOUCHER", pocket = "KEY_ITEM" }
  world.game.save.inventory = {}; choices = { true }; bagAccept.BIKE_VOUCHER = false
  check(Twin._talkKantoFanClubChairman(world, region), "physical voucher full-bag handled")
  eq(messages[#messages], "BAG FULL", "physical voucher add refusal shown")
  check(not Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "physical add failure sets no event")

  fresh(); world.game.save.inventory = {}; choices = { true }
  check(Twin._talkKantoFanClubChairman(world, region), "physical voucher award handled")
  eq(world.game.save.inventory.BIKE_VOUCHER, 1, "defined voucher enters Gold bag")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "physical voucher backfills same event")
  world.game.data.items.BIKE_VOUCHER = nil
end

-- Local voucher + Bike Shop full pocket: Bicycle add fails, so held voucher
-- remains and EVENT_GOT_BICYCLE stays clear.
do
  fresh(); world.game.save.inventory = {}
  backing.yellowPhysicalEventsV1 = { [Civic.BIKE_VOUCHER_EVENT] = true }
  Twin._resetKantoStateCacheForTest(); bagAccept.BICYCLE = false
  check(Twin._talkKantoBikeShopClerk(world, region), "local voucher exchange bag-full handled")
  eq(messages[1], "OH VOUCHER", "clerk recognizes local voucher")
  eq(messages[2], "BIKE BAG FULL", "clerk reports Bicycle pocket refusal")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "failed exchange preserves voucher possession")
  check(not Twin._kantoEvent(Civic.BICYCLE_EVENT), "failed exchange sets no bicycle completion")
  eq(world.game.save.inventory.BICYCLE, nil, "failed exchange gives no bicycle")
end

-- Successful local exchange: add Gold BICYCLE first, then mark the voucher
-- consumed via EVENT_GOT_BICYCLE. Subsequent talks use the owned-bike branch.
do
  fresh(); world.game.save.inventory = {}
  backing.yellowPhysicalEventsV1 = { [Civic.BIKE_VOUCHER_EVENT] = true }
  Twin._resetKantoStateCacheForTest()
  local before = Twin.yellowBicycleExchanges or 0
  check(Twin._talkKantoBikeShopClerk(world, region), "local voucher exchange handled")
  eq(world.game.save.inventory.BICYCLE, 1, "Gold receives the Bicycle")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "received-voucher history persists")
  check(Twin._kantoEvent(Civic.BICYCLE_EVENT), "bicycle completion persists")
  eq(messages[#messages], "EXCHANGED", "exchange line shown")
  eq(Twin.yellowBicycleExchanges, before + 1, "exchange diagnostic increments")
  local held, hasBike, done = Twin._syncKantoBikeServiceEvents(world.game.save)
  check(not held and hasBike and done, "completed local voucher is no longer held")
  check(Twin._talkKantoBikeShopClerk(world, region), "owned-bike clerk handled")
  eq(messages[#messages], "HOW IS BIKE", "owned bike skips sale")
end

-- Physical-voucher compatibility/migration: an injected Gold save holding one
-- is recognized, and successful exchange consumes it only after Bicycle add.
do
  fresh(); world.game.save.inventory = { BIKE_VOUCHER = 1 }
  check(Twin._talkKantoFanClubChairman(world, region), "physical voucher migration handled")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "physical voucher backfills event")
  eq(world.game.save.inventory.BIKE_VOUCHER, 1, "migration creates no duplicate")
  eq(messages[#messages], "CHAIR FINAL", "migrated owner gets final text")

  messages = {}
  check(Twin._talkKantoBikeShopClerk(world, region), "physical voucher exchange handled")
  eq(world.game.save.inventory.BIKE_VOUCHER, nil, "physical voucher spent after successful Bicycle add")
  eq(world.game.save.inventory.BICYCLE, 1, "physical compatibility path gives Bicycle")
end

-- A Gold save already owning BICYCLE is authoritative: both Kanto service bits
-- backfill and no voucher is minted.
do
  fresh(); world.game.save.inventory = { BICYCLE = 1 }
  check(Twin._talkKantoBikeShopClerk(world, region), "existing Gold bike migration handled")
  check(Twin._kantoEvent(Civic.BICYCLE_EVENT), "existing bike backfills bicycle event")
  check(Twin._kantoEvent(Civic.BIKE_VOUCHER_EVENT), "existing bike completes voucher chain")
  eq(world.game.save.inventory.BIKE_VOUCHER, nil, "migration does not invent voucher")
  eq(messages[#messages], "HOW IS BIKE", "existing bike uses owned branch")
end

-- No voucher: retain the impossible ¥1,000,000 retail pitch. Selecting Bicycle
-- always yields can't-afford + come-again and never changes Gold money/items;
-- CANCEL goes directly to come-again.
do
  fresh(); world.game.save.money, world.game.save.inventory = 999999, {}; menuChoice = true
  local before = Twin.yellowBikeShopBrowses or 0
  check(Twin._talkKantoBikeShopClerk(world, region), "bike sale browse handled")
  eq(messages[1], "WELCOME", "shop welcome first")
  check(lastMenu ~= nil, "price menu opens")
  eq(lastMenu.title, "BIKE PITCH", "price menu keeps authored pitch")
  eq(lastMenu.items[1].label, "BICYCLE", "first row Bicycle")
  eq(lastMenu.items[1].right, "¥1000000", "authored impossible price")
  eq(lastMenu.items[2].label, "CANCEL", "second row cancel")
  check(seen("CANT AFFORD"), "buy selection cannot afford")
  eq(messages[#messages], "COME AGAIN", "sale closes with come-again")
  eq(world.game.save.money, 999999, "browsing never changes money")
  eq(world.game.save.inventory.BICYCLE, nil, "retail path sells no bicycle")
  eq(Twin.yellowBikeShopBrowses, before + 1, "browse diagnostic increments")

  fresh(); world.game.save.money, world.game.save.inventory = 999999, {}; menuChoice = false
  check(Twin._talkKantoBikeShopClerk(world, region), "bike sale cancel handled")
  check(not seen("CANT AFFORD"), "cancel skips can't-afford line")
  eq(messages[#messages], "COME AGAIN", "cancel goes directly to come-again")
end

-- Actual object dispatcher owns both interactions ahead of dialogue-only fallback.
do
  fresh(); world.game.save.inventory = {}; choices = { false }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "POKEMON_FAN_CLUB",
      { text = "TEXT_POKEMONFANCLUB_CHAIRMAN" }), "dispatcher owns chairman")
  fresh(); world.game.save.inventory = { BICYCLE = 1 }
  check(Twin._tryKantoSpecialObjectInteraction(world, region, "BIKE_SHOP",
      { text = "TEXT_BIKESHOP_CLERK" }), "dispatcher owns bike clerk")
  eq(messages[#messages], "HOW IS BIKE", "dispatcher reaches bike service")
end

print("kanto_bike_voucher_parity: OK")
