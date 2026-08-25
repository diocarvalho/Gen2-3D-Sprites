-- BATTLE WEATHER.
--
-- =====================================================================
-- THE ONE DESIGN DECISION EVERYTHING ELSE FOLLOWS FROM
-- =====================================================================
--
-- `battle.field.weather` IS THE ONLY SOURCE OF TRUTH, AND IT IS NOT OURS.
--
-- Kanto-Reforged already implements battle weather.  Its Sunny Day / Rain
-- Dance / Sandstorm / Hail moves, its Drought / Drizzle / Sand Stream /
-- Air Lock abilities, its Weather Ball, its Forecast Castform, its Sand
-- Veil and its Chlorophyll and Swift Swim speed multipliers ALL read
-- `battle.field.weather` and expect the strings SUNNY, RAINY, SANDSTORM,
-- HAIL and SNOWY.
--
-- So this mod writes that field, in that vocabulary, and reads it back.
-- It does not keep a weather of its own for battles.  The alternative --
-- a parallel field -- would mean a Rain Dance that made it rain for
-- Reforged's Swift Swim but not for our Water boost, which is exactly the
-- class of bug that makes two mods "incompatible".  One field, two
-- writers, and every reader agrees.
--
-- CAPABILITY DETECTION, NOT VERSION CHECKING.  On load this file asks what
-- is already implemented and switches off its own copy of it.  With
-- Kanto-Reforged installed, Weather Ball / Forecast / Sand Veil /
-- Chlorophyll come from there and this mod adds the parts that are
-- missing; without it, this mod adds what it can, which is less, because
-- Gen 1 has no abilities, no held items and no Weather Ball to begin with.
-- Nothing is applied twice in either case.
--
-- =====================================================================
-- WHAT GATES THIS
-- =====================================================================
--
--   * `config.battle.enabled` -- the master switch.
--   * Effects apply to whatever weather is ALREADY in the field.  With no
--     mod setting weather and no seeding, the field is always nil, every
--     hook is a pass-through, and the battle is byte-for-byte vanilla.
--   * SEEDING -- carrying the overworld's weather into a battle -- is the
--     only thing here that changes a battle that would otherwise have no
--     weather at all, so it is the thing behind the opt-in ruleset.
--     `config.battle.requireRuleset = false` releases it for players who
--     want it on an existing save.
--
-- The ruleset itself follows the engine's own `mods/examples/example_weather`
-- pattern deliberately: derive from gen1_faithful, mark it with a field of
-- your own, gate on the marker.
--
-- =====================================================================
-- GEN 1 LIMITATIONS, STATED PLAINLY
-- =====================================================================
--
-- Some of the reference behaviour has nowhere to attach in a Gen 1 engine:
--
--   * NO ABILITIES.  Chlorophyll, Ice Body, Sand Veil and the rest need a
--     mod that adds abilities.  Everything here that touches one is inert
--     without Kanto-Reforged, by construction rather than by a version
--     check: `abilityOf` simply never returns anything.
--   * NO HELD ITEMS.  Same: `mon.heldItem` is nil in vanilla, so the
--     weather rocks and Utility Umbrella cost one nil check.
--   * NO WEATHER BALL, NO CASTFORM, NO SYNTHESIS/MOONLIGHT.  These moves
--     and species do not exist in Gen 1.  With Reforged they do, and it
--     implements them.
--   * SOLAR BEAM'S CHARGE TURN cannot be skipped from a hook: charging is
--     inside the move's own effect, and the engine exposes damage,
--     accuracy and crit, not move flow.  Its POWER change (halved outside
--     sun) is implemented; the charge skip is not.  A future version could
--     do it by patching the move_effects record, which is what Reforged
--     does for its own charging moves.
--   * SPECIAL IS ONE STAT in Gen 1, so "Special Defence up in a
--     sandstorm" raises the same number "Special Attack up" would.  It is
--     applied as a damage reduction on incoming special moves only, which
--     is the half of it that behaves like the modern stat.

local V = ...
local mod = V.mod
local Types = V.require("Types")
local Config = V.require("Config")
local Settings = V.require("Settings")
local State = V.require("WeatherState")

local Battle = {}

Battle.RULESET = "weather_fx_battles"

-- THE LIVE BATTLE.
--
-- Most hooks are handed it on the ctx, but `battle.turn_order` is not:
-- the engine builds that ctx as `{ rng = self.rng }` and nothing else
-- (BattleState:2309).  Reading `ctx.battle` there returned nil, which
-- meant the weather speed abilities silently never fired -- dead code that
-- every test passed because the tests handed in a ctx that HAD a battle.
-- Tracked from the events instead, which is the only source that works
-- for every hook.
local current = nil

function Battle.current()
  return current
end

-- ------- what somebody else already does

Battle.caps = {
  reforged = false,
  weatherBall = false,   -- Weather Ball's type/power
  forms = false,         -- Forecast / Castform
  evasion = false,       -- Sand Veil
  speed = false,         -- Chlorophyll / Swift Swim
}

local function detectCapabilities()
  -- Reset first: install() is re-run on a hot reload, and a capability
  -- that latched true would stay true after the mod providing it was
  -- removed -- which would silently disable our own copy of it forever.
  Battle.caps.reforged = false
  Battle.caps.weatherBall = false
  Battle.caps.forms = false
  Battle.caps.evasion = false
  Battle.caps.speed = false
  local ok, handle = pcall(function() return mod.find("Kanto-Reforged") end)
  if ok and handle then
    Battle.caps.reforged = true
    -- Everything in this list is implemented there and must NOT be
    -- implemented here as well, or the multiplier lands twice.
    Battle.caps.weatherBall = true
    Battle.caps.forms = true
    Battle.caps.evasion = true
    Battle.caps.speed = true
    mod.log:info("Kanto-Reforged detected: deferring Weather Ball, Forecast, "
      .. "Sand Veil and weather speed to it")
  end
end

-- ------- reading the battle
--
-- Every accessor here is total and cheap.  They are called from inside
-- damage and accuracy hooks, which run several times a turn, so none of
-- them allocates and none of them can throw.

-- The weather in force for THIS battler, which is not always the weather
-- in the field: a suppressing ability or a Utility Umbrella removes it for
-- everyone / for its holder.
-- THE TWO GATES, resolved from the config file AND the mod-manager row.
--
-- Either switch may RELAX the other; neither can silently tighten it.
-- That keeps both honest: a player who set `requireRuleset = false` in the
-- file does not have it quietly re-imposed by an untouched menu row, and a
-- player with no editable file can still turn the rules on from the menu.
-- The value used when the row cannot be read at all. It MUST equal the
-- row's own `default` in Settings.SCHEMA, or the mod behaves one way with a
-- readable settings store and another way without -- a difference that
-- would only ever show up on the machines least able to report it. Exposed
-- rather than inlined so the suite can assert the two stay in step; an
-- earlier version carried a comment claiming that test existed when it did
-- not, and a mutation that pulled the two apart passed clean.
Battle.ROW_FALLBACK = "always"

local function rulesRow()
  local ok, value = pcall(Settings.get, "battlerules")
  if ok and value then return value end
  return Battle.ROW_FALLBACK
end

-- ------- is this a Gen 2 boot?
--
-- Asked for exactly one reason: the `rulesets` registry has NO Gen 2 home
-- (src/mods/Schemas.lua -- "no Gen 2 ruleset dispatch exists"). On Gold the
-- registration is taken, dropped and REPORTED, which puts this mod on the
-- manager's boot-error list looking broken; and worse, `requireRuleset`
-- could never be satisfied there, so a player on RULESET would get no battle
-- weather at all with nothing saying why.
--
-- HOW, and why not the obvious ways. GameVersion.get() answers the CART, not
-- the boot: a Gen 2 loader with Gen 1 data loaded still reports a Gen 1
-- version, so it gets this wrong in exactly the headless case that tests it.
-- The loader's own `generation` is a file-local and not reachable from here.
--
-- What is both reachable and documented is the adapter's own behaviour. On a
-- Gen 2 boot a mod's require for `src.core.Game` is answered by a proxy, and
-- docs/preparing-your-mod-for-gen2.md states that `pairs`, `next` and
-- `rawget` see an EMPTY table on it "because the proxy holds nothing of its
-- own". The real Gen 1 module is a populated table. So: an empty Game is the
-- proxy, and the proxy only exists on Gold.
--
-- Anything unexpected reads as Gen 1, which is the behaviour this mod
-- already had, and the answer is cached because the boot cannot change under
-- us.
-- On the table, not a local, so the suite can force a Gen 2 boot: the
-- alternative is a test that sets battle.field.weather by hand, which
-- bypasses seeding -- and seeding is the only thing needsRuleset gates. A
-- test that cannot reach seeding cannot catch this gate breaking, which is
-- exactly what happened before this seam existed.
Battle.gen2Boot = nil

function Battle.isGen2()
  local gen2Boot = Battle.gen2Boot
  if gen2Boot ~= nil then return gen2Boot end
  local ok, empty = pcall(function()
    local G = require("src.core.Game")
    if type(G) ~= "table" then return false end
    return next(G) == nil
  end)
  Battle.gen2Boot = (ok and empty) or false
  return Battle.gen2Boot
end

function Battle.effectsEnabled()
  if rulesRow() == "off" then return false end
  return Config.get().battle.enabled and true or false
end

function Battle.needsRuleset()
  if rulesRow() == "always" then return false end
  -- Gold has no ruleset dispatch, so there is no WEATHER ruleset for a save
  -- to be on. Keeping the requirement there would gate every battle effect
  -- behind a condition that can never become true -- the mod would look
  -- installed and do nothing. The gate is Gen 1's to enforce.
  if Battle.isGen2() then return false end
  return Config.get().battle.requireRuleset and true or false
end

local function fieldWeather(battle)
  local field = battle and battle.field
  local w = field and field.weather
  if type(w) ~= "string" or w == "" then return nil end
  return w
end

-- Reforged's convention, followed rather than reinvented: the species
-- record's ability, unless the battler has traced one or had it
-- suppressed.  Returns nil in vanilla, where no record has an ability.
local function abilityOf(battle, battler)
  if not (battler and battler.mon) then return nil end
  if battler.expAbilitySuppressed then return nil end
  if battler.expTracedAbility then return battler.expTracedAbility end
  local data = battle and battle.data and battle.data.pokemon
  local def = data and data[battler.mon.species]
  return def and def.ability or nil
end
Battle.abilityOf = abilityOf

local function heldItem(battler)
  return battler and battler.mon and battler.mon.heldItem or nil
end

-- Cloud Nine and friends.  Air Lock is not listed: Kanto-Reforged already
-- clears the field outright when an Air Lock holder enters, which is the
-- same outcome by a different route, and listing it here would suppress a
-- weather that mod had already removed.
local function weatherSuppressed(battle)
  local set = Config.get().battle.suppressSet
  if not next(set) then return false end
  for _, b in ipairs({ battle and battle.player, battle and battle.enemy }) do
    if b and set[abilityOf(battle, b) or ""] then return true end
  end
  return false
end

-- The weather a given battler experiences.  nil for "none".
function Battle.weatherFor(battle, battler)
  if not Battle.effectsEnabled() then return nil end
  local w = fieldWeather(battle)
  if not w then return nil end
  if weatherSuppressed(battle) then return nil end
  if Config.battleEffect("heldItems") then
    local umbrella = Config.get().battle.items.umbrella
    if umbrella and heldItem(battler) == umbrella then return nil end
  end
  return w
end

-- The weather in force generally (no particular battler), for effects that
-- are about the field rather than about one side.
function Battle.weather(battle)
  if not Battle.effectsEnabled() then return nil end
  local w = fieldWeather(battle)
  if not w or weatherSuppressed(battle) then return nil end
  return w
end

-- ------- one type has two names
--
-- The engine's type IDs and their DISPLAY names agree for fourteen of the
-- fifteen Gen 1 types. The exception is Psychic: the id is `PSYCHIC_TYPE`
-- and the name is `PSYCHIC` (src/battle/TypeChart.lua). A battler's
-- `curTypes` carries the ID, so a table written with the readable name --
-- which is what every chipType in the catalogue uses -- silently never
-- matches it.
--
-- That is not hypothetical: a PSYSTORM was chipping Alakazam, the one
-- species it exists to spare. Nothing errored; the comparison simply never
-- came out true.
--
-- Normalised in the ONE place battler types are compared, rather than
-- renaming fifteen chipTypes to a form nobody writing this catalogue would
-- think of. Keyed both ways so an id or a name may be passed.
local TYPE_ALIAS = {
  PSYCHIC = "PSYCHIC_TYPE",
  PSYCHIC_TYPE = "PSYCHIC_TYPE",
}

local function hasType(battler, typeName)
  local list = battler and battler.curTypes
  if type(list) ~= "table" then return false end
  local want = TYPE_ALIAS[typeName] or typeName
  for i = 1, #list do
    local have = TYPE_ALIAS[list[i]] or list[i]
    if have == want then return true end
  end
  return false
end
Battle.hasType = hasType

local function categoryOf(move)
  if not move then return "physical" end
  if move.category then return move.category end
  local ok, TypeChart = pcall(require, "src.battle.TypeChart")
  if ok and TypeChart and TypeChart.category then
    local ok2, cat = pcall(TypeChart.category, move.type)
    if ok2 and cat then return cat end
  end
  return "physical"
end

local function rollPercent(battle, pct)
  local rng = battle and battle.rng
  local n
  if rng then n = rng(0, 99)
  elseif love and love.math then n = love.math.random(0, 99)
  else n = math.random(0, 99) end
  return n < pct
end

-- ------- 1. TYPE POWER
--
-- The headline effect and the one everybody knows.  Multipliers are the
-- reference ones; the primal weathers are handled in ACCURACY instead,
-- because "the move does not work" is a miss, not zero damage -- returning
-- 0 from a damage hook produces a hit that did nothing, which reads as a
-- bug rather than as a nullified attack.

local POWER = {
  SUNNY      = { FIRE = 1.5, WATER = 0.5 },
  HARSH_SUN  = { FIRE = 1.5 },              -- WATER fails; see accuracy
  RAINY      = { WATER = 1.5, FIRE = 0.5 },
  HEAVY_RAIN = { WATER = 1.5 },             -- FIRE fails; see accuracy
}

-- ------- 1b. AMPLIFIED WEATHER -- NOT REFERENCE BEHAVIOUR
--
-- In the reference games the primal weathers' distinguishing feature IS
-- the nullification: HARSH_SUN boosts FIRE by exactly the same 1.5 that
-- ordinary sun does, and a sandstorm has never boosted any move's power
-- in any generation.  These rows change that -- the matching type hits
-- harder in a primal sky, and a sandstorm powers ROCK and GROUND the way
-- rain powers WATER.
--
-- It is house-rule territory, so it is a switch of its own
-- (`battle.amplified`) rather than folded into `typePower`, and it
-- REPLACES the reference row for that weather rather than stacking with
-- it: two multipliers for one effect is the double-apply bug this mod
-- takes care to avoid everywhere else.
local POWER_AMPLIFIED = {
  HARSH_SUN  = { FIRE = 2.0 },
  HEAVY_RAIN = { WATER = 2.0 },
  SANDSTORM  = { ROCK = 1.5, GROUND = 1.5 },
  -- Ice in a blizzard, by the same logic as sand in a sandstorm: the
  -- weather that hurts everyone else should favour the type that lives
  -- in it.  HAIL and SNOWY both, since the vocabulary carries both.
  HAIL       = { ICE = 1.5 },
  SNOWY      = { ICE = 1.5 },
}

-- ------- 1c. TERRAIN -- ALSO NOT REFERENCE BEHAVIOUR
--
-- A per-map type bonus, read from `config.battle.terrain`.  Inspired by
-- the Gen 6+ Terrain moves, but Gen 1 has no terrain-setting move to
-- attach to, so it is a property of WHERE the battle is fought instead:
-- Bug and Grass under a forest canopy, Electric in the Power Plant,
-- Ghost in the tower.
--
-- Independent of weather by design -- a battle in Viridian Forest gets
-- the canopy bonus whether or not it is raining, which is why the damage
-- hook below can no longer bail out early just because the sky is clear.
local function terrainScale(ctx)
  -- `effectsEnabled` first, and NOT just `battleEffect("terrain")`: the
  -- latter answers "is this individual effect switched on" and misses the
  -- mod-manager rules row, which `effectsEnabled` folds in.  Every weather
  -- effect reaches that gate through `weatherFor`; terrain has no weather
  -- to look up, so it has to ask directly or the manager's off switch
  -- would silently leave terrain running.
  if not Battle.effectsEnabled() then return 1 end
  if not Config.battleEffect("terrain") then return 1 end
  -- Battle.mapId is nil unless the ruleset gate passed at battle.started
  -- (see install), which is what keeps an unselected ruleset vanilla.
  local mapId = Battle.mapId
  if not mapId then return 1 end
  local table_ = Config.get().battle.terrain
  local row = table_ and table_[mapId]
  if not row then return 1 end
  local moveType = ctx.move and ctx.move.type
  if not moveType then return 1 end
  local mult = row[moveType]
  if type(mult) ~= "number" then return 1 end
  return mult
end

-- Solar Beam is halved in anything that is not sun.  Named by move id so a
-- mod that renames it stops matching rather than mis-matching.
local SOLAR_MOVES = { SOLARBEAM = true, SOLAR_BEAM = true, SOLAR_BLADE = true }
local DIMMED_FOR_SOLAR = { RAINY = true, HEAVY_RAIN = true, ELECTRIC_STORM = true,
                           VERDANT_RAIN = true, BRAWL_WIND = true, SMOG = true,
                           DUSTSTORM = true, FLOCKSTORM = true, SWARM = true,
                           HAUNTED_MIST = true, DRAGONSTORM = true,
                           SANDSTORM = true,
                           HAIL = true, SNOWY = true, FOG = true }

-- Is the amplified house rule on?
--
-- Two answers can disagree: the OPTIONS row and `battle.effects.amplified`
-- in config.lua. The row wins when it says anything definite, and its AUTO
-- default defers to the file -- so adding the row gave players a way to
-- answer without taking the file's answer away from anyone who had already
-- set it.
--
-- Read through Settings rather than Config because this is a menu question;
-- an unreadable row falls through to the file, which is the behaviour every
-- version before the row had.
local function amplifiedOn()
  local ok, row = pcall(Settings.get, "amplified")
  if ok and row == "on" then return true end
  if ok and row == "off" then return false end
  return Config.battleEffect("amplified")
end

local function damageScale(battle, ctx, weather)
  local scale = 1
  local moveType = ctx.move and ctx.move.type
  local moveId = ctx.move and ctx.move.id

  if Config.battleEffect("typePower") then
    -- The amplified row REPLACES the reference one for that weather when
    -- it exists; it never multiplies on top of it.
    local row = (amplifiedOn() and POWER_AMPLIFIED[weather])
      or POWER[weather]
    if row and moveType and row[moveType] then scale = scale * row[moveType] end
  end

  if Config.battleEffect("solarBeam") and moveId and SOLAR_MOVES[moveId] then
    if DIMMED_FOR_SOLAR[weather] then scale = scale * 0.5 end
  end

  return scale
end

-- ------- 2. ACCURACY

-- Perfect accuracy under the right sky, and a penalty under the wrong one.
local ACCURACY = {
  THUNDER   = { RAINY = "always", HEAVY_RAIN = "always", ELECTRIC_STORM = "always", SUNNY = 50, HARSH_SUN = 50 },
  HURRICANE = { RAINY = "always", HEAVY_RAIN = "always", SUNNY = 50, HARSH_SUN = 50 },
  BLIZZARD  = { HAIL = "always", SNOWY = "always" },
  -- the reference's three "-storm" moves, present only with a mod that
  -- adds them; harmless entries otherwise
  BLEAKWIND_STORM = { RAINY = "always", HEAVY_RAIN = "always" },
  WILDBOLT_STORM  = { RAINY = "always", HEAVY_RAIN = "always" },
  SANDSEAR_STORM  = { RAINY = "always", HEAVY_RAIN = "always" },
}

-- Fog reduces everyone's accuracy, which is the one thing Gen 4 fog did.
local FOG_ACCURACY = 0.85

-- The primal weathers nullify the opposing type outright.
local NULLIFIED = {
  HARSH_SUN = "WATER",
  HEAVY_RAIN = "FIRE",
}

-- ------- 0. SAYING WHAT THE WEATHER IS DOING
--
-- THE COMPLAINT THIS FIXES: the weather changed the fight and never said so.
-- Chip damage announces itself every turn, and a nullified move explains
-- itself when it fails -- but the boosts and dampenings, which are the
-- effects that decide most turns, were invisible. A player could fight a
-- whole battle in heavy rain without being told why their Fire moves were
-- doing half damage.
--
-- Written as GAME MESSAGES, not an overlay. The battle already has a text
-- queue with the right font, timing and pacing; a drawn panel would have to
-- reinvent all three and would still look like something bolted on. Two
-- lines at most, in the voice the residual messages already use.
--
-- DERIVED, never a second table. Every line below is generated from POWER,
-- POWER_AMPLIFIED and NULLIFIED -- the same tables the damage hook reads. A
-- hand-written list would be a second source of truth that drifts the moment
-- a weather is retuned, and the failure mode is the worst kind: the game
-- confidently telling the player something that is no longer true.
--
-- WHAT IS DELIBERATELY NOT SAID:
--   * Effects that apply to BOTH sides identically. Rain boosts Water for
--     everyone, so "PLAYER: Water up / ENEMY: Water up" is noise -- it reads
--     as asymmetry where there is none. Sides are named only where they
--     actually differ, which in practice is nothing here: Gen 1 weather is
--     symmetric. If an asymmetric effect is ever added, this is where it
--     goes.
--   * Chip damage. It already announces itself every turn and repeating it
--     up front doubles the message for no information.
--   * Terrain and accuracy. Accuracy is a per-move surprise that reads
--     better when the move fails; terrain is a property of the place, not
--     the sky.

local TYPE_WORD = {
  FIRE = "FIRE", WATER = "WATER", GRASS = "GRASS", ELECTRIC = "ELECTRIC",
  ICE = "ICE", ROCK = "ROCK", GROUND = "GROUND", FLYING = "FLYING",
  BUG = "BUG", POISON = "POISON", FIGHTING = "FIGHTING", GHOST = "GHOST",
  DRAGON = "DRAGON", NORMAL = "NORMAL", PSYCHIC = "PSYCHIC",
  PSYCHIC_TYPE = "PSYCHIC",
}

-- The one-line description of the sky itself, taken from the catalogue so a
-- new weather needs no entry here.
local function skyLine(weather)
  local def = Types.forBattleWeather(weather)
  local label = (def and def.battleText) or nil
  if label then return label end
  local WORDS = {
    RAINY = "It is raining!",
    HEAVY_RAIN = "A heavy rain\nis falling!",
    SUNNY = "The sunlight is\nstrong!",
    HARSH_SUN = "The sunlight is\nharsh!",
    SANDSTORM = "A sandstorm is\nraging!",
    HAIL = "Hail is falling!",
    SNOWY = "It is snowing!",
    FOG = "A deep fog\nrolled in!",
    STRONG_WINDS = "Mysterious winds\nare blowing!",
  }
  if WORDS[weather] then return WORDS[weather] end
  -- `label` is the OPTIONS-row abbreviation -- "PSY", "BRAWL", "VRAIN" --
  -- sized for a menu column, not a sentence. Reading it out gives "The PSY
  -- is swirling!". The typed storms all carry a chipType, which is the full
  -- type word, so that is the better source; label is the last resort.
  local word = (def and def.chipType and (TYPE_WORD[def.chipType] or def.chipType))
  if word then
    return ("A %s storm\nis swirling!"):format(word)
  end
  local name = (def and def.label) or weather
  return ("The %s is\nswirling!"):format(tostring(name))
end

-- Everything the damage tables say about this sky, as player-facing lines.
-- Returns at most two: one for what grew stronger, one for what weakened.
function Battle.effectLines(weather)
  if not Config.battleEffect("typePower") then return {} end
  local row = (amplifiedOn() and POWER_AMPLIFIED[weather]) or POWER[weather]
  local up, down = {}, {}
  if row then
    for typeName, mult in pairs(row) do
      local word = TYPE_WORD[typeName] or typeName
      if mult > 1 then up[#up + 1] = word
      elseif mult < 1 then down[#down + 1] = word end
    end
  end
  -- A nullified type is the strongest statement the weather makes, so it is
  -- reported as its own line rather than lumped in with "weakened".
  local dead = NULLIFIED[weather]
  local lines = {}
  table.sort(up); table.sort(down)
  if up[1] then
    lines[#lines + 1] = ("%s moves\ngrew stronger!"):format(table.concat(up, " and "))
  end
  if dead then
    lines[#lines + 1] = ("%s moves\ncannot be used!"):format(TYPE_WORD[dead] or dead)
  elseif down[1] then
    lines[#lines + 1] = ("%s moves\nweakened!"):format(table.concat(down, " and "))
  end
  return lines
end

-- Queue the opening announcement.  Guarded end to end: a battle that cannot
-- take messages simply does not get them.
local function announce(battle, weather)
  if not (battle and battle.sayNext and weather) then return end
  if not Config.battleEffect("announce") then return end
  -- once per battle, whatever else re-enters
  battle.field = battle.field or {}
  if battle.field.wxAnnounced then return end
  battle.field.wxAnnounced = true

  pcall(function()
    battle:sayNext(skyLine(weather))
    for _, line in ipairs(Battle.effectLines(weather)) do
      battle:sayNext(line)
    end
  end)
end
Battle.announce = announce


-- ------- 3. RESIDUAL DAMAGE

-- Every typed weather uses the same 1/16 residual rule.  The weather
-- catalogue supplies `chipType`, so adding a new type of weather does not
-- require another hard-coded branch here.
local RESIDUAL_TEXT = {
  NORMAL = "is buffeted\nby the PLAIN FRONT!",
  FIRE = "is scorched\nby the HEAT!",
  WATER = "is battered\nby the RAIN!",
  ELECTRIC = "is jolted\nby the STORM!",
  GRASS = "is worn down\nby the VERDANT RAIN!",
  ICE = "is pelted\nby the ICE!",
  FIGHTING = "is battered\nby the FIGHTING WINDS!",
  POISON = "is poisoned\nby the SMOG!",
  GROUND = "is battered\nby the DUSTSTORM!",
  FLYING = "is battered\nby the FLOCKSTORM!",
  PSYCHIC = "is battered\nby PSYCHIC ENERGY!",
  BUG = "is swarmed\nby the INSECTS!",
  ROCK = "is buffeted\nby the SANDSTORM!",
  GHOST = "is chilled\nby the HAUNTED MIST!",
  DRAGON = "is battered\nby DRAGONIC ENERGY!",
}

-- Abilities that turn residual weather into healing, or that heal anyway.
-- All of these are inert without an ability mod.
local HEALS = {
  ICE_BODY  = { HAIL = 1 / 16, SNOWY = 1 / 16 },
  RAIN_DISH = { RAINY = 1 / 16, HEAVY_RAIN = 1 / 16 },
  DRY_SKIN  = { RAINY = 1 / 8, HEAVY_RAIN = 1 / 8 },
}
local BURNS = {
  DRY_SKIN    = { SUNNY = 1 / 8, HARSH_SUN = 1 / 8 },
  SOLAR_POWER = { SUNNY = 1 / 8, HARSH_SUN = 1 / 8 },
}
-- Abilities that ignore residual weather damage entirely.
local RESIDUAL_IMMUNE = {
  OVERCOAT = true, MAGIC_GUARD = true, SAND_VEIL = true, SAND_RUSH = true,
  SAND_FORCE = true, ICE_BODY = true, SNOW_CLOAK = true, SLUSH_RUSH = true,
}

local function maxHpOf(battler)
  local mon = battler and battler.mon
  return (mon and mon.stats and mon.stats.hp) or (mon and mon.maxHp) or 0
end

local function displayName(b)
  local mon = b and b.mon
  local name = (mon and (mon.nickname or mon.species)) or "?"
  if b and b.isPlayer == false then return "Enemy " .. name end
  return name
end

-- One battler's end-of-turn weather effect.  Returns a message or nil.
local function residualFor(battle, b, weather)
  if not (b and b.mon and b.mon.hp and b.mon.hp > 0) then return nil end
  local cfg = Config.get().battle
  local ability = abilityOf(battle, b)
  local maxHp = maxHpOf(b)
  if maxHp <= 0 then return nil end

  -- healing first: an Ice Body holder in hail heals instead of chipping
  if Config.battleEffect("healing") and ability then
    local heal = HEALS[ability] and HEALS[ability][weather]
    if heal and b.mon.hp < maxHp then
      b.mon.hp = math.min(maxHp, b.mon.hp + math.max(1, math.floor(maxHp * heal)))
      return displayName(b) .. "'s\n" .. ability:gsub("_", " ") .. " restored HP!"
    end
    local burn = BURNS[ability] and BURNS[ability][weather]
    if burn then
      local hurt = math.max(1, math.floor(maxHp * burn))
      b.mon.hp = math.max(cfg.residualDamage.canFaint and 0 or 1, b.mon.hp - hurt)
      return displayName(b) .. " is hurt\nby the sunlight!"
    end
  end

  if not Config.battleEffect("residual") then return nil end
  -- Resolve the field weather back to the catalogue.  Shared battle
  -- strings such as RAINY/SNOWY are intentionally represented by their
  -- canonical typed weather, while unique fronts retain their own type.
  local def = Types.forBattleWeather(weather)
  if not def or not def.chipType then return nil end
  if ability and RESIDUAL_IMMUNE[ability] then return nil end

  -- A weather hurts every battler except the matching Gen-1 type.  Dual
  -- types are immune if either type matches, just as the existing
  -- sandstorm/hail rules did.
  -- Through hasType, NOT an inline compare: the engine's Psychic id is
  -- `PSYCHIC_TYPE` while its display name is `PSYCHIC`, and every chipType in
  -- the catalogue is written the readable way. Compared directly, a PSYSTORM
  -- chipped Alakazam -- the one species it exists to spare -- and nothing
  -- errored, because a comparison that is never true looks exactly like a
  -- Pokemon that simply is not immune.
  if hasType(b, def.chipType) then return nil end

  local hurt = math.max(1, math.floor(maxHp * (cfg.residualDamage.fraction or 1 / 16)))
  local floor_ = cfg.residualDamage.canFaint and 0 or 1
  b.mon.hp = math.max(floor_, b.mon.hp - hurt)
  local text = RESIDUAL_TEXT[def.chipType]
    or ("is battered\nby the " .. tostring(def.label or weather) .. "!")
  return displayName(b) .. "\n" .. text
end

-- ------- 4. SPECIAL DEFENCE IN A SANDSTORM
--
-- Applied as a damage reduction on incoming special moves rather than as a
-- stat change, because Gen 1 has ONE Special stat and raising it would
-- raise the attacker's side of it too.

local function sandstormDefence(ctx, weather)
  if weather ~= "SANDSTORM" then return 1 end
  if not Config.battleEffect("defenseBoost") then return 1 end
  if categoryOf(ctx.move) ~= "special" then return 1 end
  local battle = ctx.battle
  local target = ctx.target
      or (battle and ctx.attacker == battle.player and battle.enemy)
      or (battle and battle.player)
  if hasType(target, "ROCK") then return 2 / 3 end
  return 1
end

-- ------- 5. STRONG WINDS
--
-- Moves that would be super effective on a Flying type are cut.  The
-- effectiveness is read out of the vanilla result rather than recomputed,
-- so this stays correct under any type-chart mod.

local function strongWinds(weather, info, target)
  if weather ~= "STRONG_WINDS" then return 1 end
  if not hasType(target, "FLYING") then return 1 end
  local mult = info and info.typeMult
  -- the engine carries effectiveness in tenths (10 = neutral)
  if type(mult) == "number" and mult > 10 then return 0.5 end
  return 1
end

-- ------- installation

function Battle.install()
  detectCapabilities()

  -- ------- the ruleset

  -- Skipped entirely on Gold: `rulesets` has no Gen 2 home, so the write
  -- would be taken, dropped and reported -- one boot error on the manager's
  -- list, for a registration nothing there could ever read. Not registering
  -- is the honest version of the same outcome. needsRuleset() already
  -- returns false there, so no effect is lost by it.
  local base = (not Battle.isGen2()) and mod.content.rulesets:get("gen1_faithful") or nil
  if Battle.isGen2() then
    mod.log:info("Gen 2 boot: skipping the %s ruleset (no Gen 2 ruleset "
      .. "dispatch exists); battle weather applies without it", Battle.RULESET)
  elseif not base then
    mod.log:error("gen1_faithful is missing from the rulesets registry; "
      .. "another mod removed it, so %s cannot be derived", Battle.RULESET)
  else
    local derived = {}
    for key, value in pairs(base) do derived[key] = value end
    derived.name = "WEATHER"
    -- The marker the seeding gate reads.  Unknown fields ride through the
    -- schema untouched, which is what makes rulesets extensible.
    derived.weatherFx = true
    mod.content.rulesets:register(Battle.RULESET, derived)
  end

  -- ------- seeding the field from the sky
  --
  -- The only thing here that puts weather into a battle that would
  -- otherwise have none, so the only thing behind the ruleset gate.

  mod.events:on("battle.started", function(ev)
    local battle = ev and ev.battle
    current = battle

    -- Captured HERE, above the seeding early-returns below, because
    -- terrain is not gated on seeding or on being outdoors: a cave or a
    -- tower is exactly where a terrain bonus should still apply.
    --
    -- It IS gated on the ruleset, though, and by the same test seeding
    -- uses.  The promise this mod makes is that installed-but-unselected
    -- is byte-for-byte vanilla, and a forest powering up BUG moves in a
    -- gen1_faithful battle would break it.  Storing nil here switches
    -- terrain off for the whole battle rather than re-testing per hit.
    do
      local ok, Scene = pcall(V.require, "Scene")
      local mapId = (ok and Scene and Scene.now and Scene.now.mapId) or nil
      if Battle.needsRuleset()
        and not (battle and battle.ruleset and battle.ruleset.weatherFx) then
        mapId = nil
      end
      Battle.mapId = mapId
    end

    -- Once, on the first battle: report any configured map id that is not a
    -- real map.
    Battle.checkMapIds()

    if not battle then return end
    local cfg = Config.get().battle
    if not (Battle.effectsEnabled() and cfg.seedFromOverworld) then return end

    local gated = Battle.needsRuleset()
    if gated and not (battle.ruleset and battle.ruleset.weatherFx) then return end

    -- Indoors has no sky, so an indoor battle inherits nothing -- which
    -- is also why a Rock Tunnel fight is never in a blizzard.
    local Scene = V.require("Scene")
    if Scene.now.indoors then return end

    local weather = Types.battleWeather(State.id)
    if not weather then return end

    battle.field = battle.field
      or { weather = nil, tokens = {}, sides = battle.sides }
    battle.field.tokens = battle.field.tokens or {}
    -- Do not stamp on a weather something else set first (an ability's
    -- entry effect fires before this in some orderings).
    if battle.field.weather then return end
    battle.field.weather = weather
    if cfg.seededTurns then battle.field.weatherTurns = cfg.seededTurns end
    mod.save:set("battleWeather", weather)
  end)

  -- ------- the opening announcement
  --
  -- A SECOND handler, deliberately, rather than a call inside the seeding
  -- block above. That block returns early half a dozen times -- no ruleset,
  -- indoors, a sky already set by an ability -- and every one of those
  -- returns is correct for SEEDING and wrong for ANNOUNCING: the player
  -- still needs to know what they are fighting in when some other mod put
  -- the weather there, or when the sky came from a move.
  --
  -- Registered after, so it runs after, so `battle.field.weather` is final
  -- whoever set it.
  mod.events:on("battle.started", function(ev)
    local battle = ev and ev.battle
    if not battle then return end
    if not Battle.effectsEnabled() then return end
    announce(battle, battle.field and battle.field.weather)
  end)

  mod.events:on("battle.ended", function()
    current = nil
    Battle.mapId = nil
    mod.save:set("battleWeather", nil)
  end)

  -- ------- damage

  mod.hooks:wrap("battle.damage", function(next_, ctx)
    if not ctx then return next_(ctx) end
    local battle = ctx.battle
    -- The engine names it `user` (BattleState:2226); `attacker` is
    -- accepted too so a mod that re-dispatches with its own ctx still
    -- works.
    local attacker = ctx.user or ctx.attacker
    local weather = Battle.weatherFor(battle, attacker)

    -- Terrain is a property of the MAP, not the sky, so it is computed
    -- before the weather check and the early-out now asks whether there
    -- is anything at all to apply.  Without this a forest bonus would
    -- only work while it happened to be raining.
    local terrain = terrainScale(ctx)
    if not weather and terrain == 1 then return next_(ctx) end

    local scale = terrain
    if weather then
      scale = scale * damageScale(battle, ctx, weather) * sandstormDefence(ctx, weather)
    end

    local damage, info = next_(ctx)
    if type(damage) ~= "number" then return damage, info end

    -- Damage.compute returns 0 for a status move or a move with no power
    -- (Damage.lua:139).  A WATER-type status move under rain would
    -- otherwise be scaled to 0 and then floored UP to 1 by the clamp
    -- below -- turning Withdraw into a one-point attack.  Zero stays zero.
    if damage <= 0 then return damage, info end

    local target = ctx.target
    scale = scale * strongWinds(weather, info, target)

    if scale == 1 then return damage, info end
    -- Pass `info` through untouched or the crit and type-effectiveness
    -- flags vanish from every caller downstream.
    return math.max(1, math.floor(damage * scale)), info
  end)

  -- ------- accuracy

  mod.hooks:wrap("battle.accuracy", function(next_, ctx)
    if not ctx then return next_(ctx) end
    local battle = ctx.battle
    local weather = Battle.weatherFor(battle, ctx.user)
    if not weather then return next_(ctx) end
    local moveId = ctx.move and ctx.move.id
    local moveType = ctx.move and ctx.move.type

    -- the primal nullifications: the move simply does not work
    local dead = NULLIFIED[weather]
    if dead and moveType == dead and Config.battleEffect("typePower") then
      if battle and battle.sayNext then
        local msg = (weather == "HARSH_SUN")
          and "The Water attack\nevaporated in the\nharsh sunlight!"
          or "The Fire attack\nfizzled out in the\nheavy rain!"
        pcall(function() battle:sayNext(msg) end)
      end
      return false
    end

    if Config.battleEffect("accuracy") and moveId then
      local row = ACCURACY[moveId]
      local verdict = row and row[weather]
      if verdict == "always" then return true end
      if type(verdict) == "number" then
        if not rollPercent(battle, verdict) then return false end
        return next_(ctx)
      end
      if weather == "FOG" then
        -- everything is a little harder to land in fog; applied as an
        -- extra independent roll rather than by editing the move's
        -- accuracy, which this hook is not given
        if not rollPercent(battle, math.floor(FOG_ACCURACY * 100)) then
          return false
        end
      end
    end

    -- Sand Veil / Snow Cloak, only when nobody else provides them.
    if Config.battleEffect("evasion") and not Battle.caps.evasion then
      local target = ctx.target
      local ability = abilityOf(battle, target)
      if (ability == "SAND_VEIL" and weather == "SANDSTORM")
          or (ability == "SNOW_CLOAK" and (weather == "HAIL" or weather == "SNOWY")) then
        if rollPercent(battle, 20) then return false end
      end
    end

    return next_(ctx)
  end)

  -- ------- speed
  --
  -- Only when nobody else provides it.  The hook hands over both battlers
  -- and their moves and expects the one that goes first, so the vanilla
  -- answer is taken and then overruled only when exactly one side is
  -- boosted -- which avoids reimplementing priority, ties and the
  -- tie-break roll.

  -- RETURNS A BOOLEAN, NOT A BATTLER.  TurnOrder.firstMover returns
  -- "does `a` go first" (TurnOrder.lua:50-59), and the engine assigns the
  -- hook's result straight into `pFirst`.  Returning a battler table here
  -- was always truthy, so the player would have moved first every time a
  -- weather speed ability was in play -- a corrupted turn order rather
  -- than a missing effect.  It never fired only because the ctx had no
  -- battle to read; both halves are fixed together.
  mod.hooks:wrap("battle.turn_order", function(next_, a, aMove, b, bMove, ctx)
    local first = next_(a, aMove, b, bMove, ctx)
    if Battle.caps.speed or not Config.battleEffect("speed") then return first end
    local battle = (ctx and ctx.battle) or current
    local weather = Battle.weather(battle)
    if not weather then return first end

    local BOOST = {
      CHLOROPHYLL = { SUNNY = true, HARSH_SUN = true },
      SWIFT_SWIM  = { RAINY = true, HEAVY_RAIN = true },
      SAND_RUSH   = { SANDSTORM = true },
      SLUSH_RUSH  = { HAIL = true, SNOWY = true },
    }
    local function boosted(x)
      local ability = abilityOf(battle, x)
      local row = ability and BOOST[ability]
      return row and row[weather] and true or false
    end
    local aFast, bFast = boosted(a), boosted(b)
    -- Only a same-priority turn is reordered, and only when exactly one
    -- side is boosted -- otherwise the vanilla answer already stands.
    if aFast == bFast then return first end
    local aPri = (aMove and aMove.priority) or 0
    local bPri = (bMove and bMove.priority) or 0
    if aPri ~= bPri then return first end
    return aFast and true or false
  end)

  -- ------- residual, healing, and the held-item extenders

  mod.events:on("battle.turn_ended", function(ev)
    local battle = ev and ev.battle
    if not battle or battle.result then return end
    local cfg = Config.get().battle
    if not Battle.effectsEnabled() then return end

    -- AI Rivals and other documented double-battle decorators expose the
    -- second active battlers as player2/enemy2. Visit all four, once each;
    -- ordinary battles still take the same two-element path.
    local seen = {}
    local battlers = {}
    for _, key in ipairs({ "player", "enemy", "player2", "enemy2" }) do
      if battle[key] then battlers[#battlers + 1] = battle[key] end
    end
    for _, b in ipairs(battlers) do
      if b and not seen[b] then
        seen[b] = true
        local weather = Battle.weatherFor(battle, b)
        if weather then
          local ok, message = pcall(residualFor, battle, b, weather)
          if ok and message and battle.sayNext then
            pcall(function() battle:sayNext(message) end)
            -- The engine's own residual sweep has already run and called
            -- onFaint for anything it killed; ours runs after it, so a
            -- knockout here is ours to report.
            if b.mon.hp <= 0 and battle.onFaint then
              pcall(function() battle:onFaint(b) end)
            end
          end
        end
      end
    end
  end)

  -- Weather rocks: a move that set the weather this turn gets extra turns
  -- if its user is holding the matching rock.
  mod.events:on("battle.move_used", function(ev)
    if not Config.battleEffect("heldItems") then return end
    local battle = ev and ev.battle
    local field = battle and battle.field
    if not (field and field.weather and field.weatherTurns) then return end
    local user = ev.user or ev.battler or ev.attacker
    local item = heldItem(user)
    if not item then return end
    local cfg = Config.get().battle.items
    if cfg.extenders[item] == field.weather then
      field.weatherTurns = field.weatherTurns + (cfg.extendBy or 3)
      -- once per set, not once per turn: the flag rides on the field and
      -- the field is rebuilt whenever the weather changes
      if field.weatherRockApplied ~= field.weather then
        field.weatherRockApplied = field.weather
      end
    end
  end)

  return true
end

-- ------- for the debug row and the tests

-- What the debug row prints for `btl`.  A bare "-" was the single most
-- expensive thing on this readout: "the sky changes but the battle is dry"
-- has at least four different causes and the row named none of them, so the
-- answer was always "read Battle.lua".  Now it says which gate closed, in
-- the same shape `art:behind!not-installed` and `terr:off` already use.
--
-- `!` is a gate that actually stopped this battle; `?` is a gate that is
-- armed but has not been tested yet because no battle is up.  The
-- distinction matters: standing in the overworld with WX RULES on RULESET
-- is not a fault, it is a thing to know before walking into grass.
-- ------- map ids that do not exist
--
-- A terrain bonus or location override keyed to a map that does not exist
-- does nothing at all, silently: no error, no warning, and no way to tell it
-- apart from one that is working but has not come up yet. Not hypothetical --
-- the bundled table shipped `POKEMONTOWER_1F` (the engine calls it
-- `POKEMON_TOWER_1F`) and seven Ghost bonuses were dead for a release with
-- nothing saying so.
--
-- Read LAZILY on the first battle rather than at config-load time: config
-- loads before the dataset is guaranteed merged, and comparing against an
-- empty registry would report every id as unknown.
--
-- On the table rather than a local so the suite can re-arm it; the mod
-- itself only ever sets it true.
Battle.mapIdsChecked = false

function Battle.checkMapIds()
  if Battle.mapIdsChecked then return end
  Battle.mapIdsChecked = true

  local known, count = {}, 0
  local ok = pcall(function()
    for id in mod.content.maps:each() do
      known[id] = true
      count = count + 1
    end
  end)
  if not ok or count == 0 then return end   -- cannot say; stay quiet

  -- Ids the mod SHIPS, which are deliberately cross-generation: the terrain
  -- table carries Kanto rows and Johto rows together because only 76 of Gen
  -- 1's 222 maps exist on Gold. Whichever set is not the running game's will
  -- never match, and that is correct rather than a mistake -- so warning
  -- about them would mean every Kanto boot complains about six Johto ids and
  -- every Gold boot about eight Kanto ones, which is how a useful warning
  -- becomes noise people learn to ignore.
  --
  -- Both sets are verified against the engine's own manifests
  -- (tools/rom_manifest.json and tools/rom_manifest_gold.json), so the check
  -- that matters is the one on ids a PLAYER added.
  local BUNDLED = Config.bundledMapIds and Config.bundledMapIds() or {}

  local function report(label, tbl)
    if type(tbl) ~= "table" then return end
    local bad, good = {}, 0
    for mapId in pairs(tbl) do
      if type(mapId) == "string" then
        if known[mapId] then good = good + 1
        elseif not BUNDLED[mapId] then bad[#bad + 1] = mapId end
      end
    end
    -- If NOT ONE configured id is a known map, the likelier explanation is
    -- that this is not the dataset those ids were written for -- a trimmed
    -- or fixture set, or another region -- than that every single one is a
    -- typo. Warning about all of them there would train people to ignore the
    -- warning. The stated cost: a config with exactly one entry and a typo in
    -- it gets nothing. The case this exists for, one bad id among several
    -- good ones, is still caught.
    if good == 0 then return end
    table.sort(bad)
    for _, mapId in ipairs(bad) do
      mod.log:warn(
        "%s: %q is not a map id in this dataset, so it will never match. "
        .. "Check it against the DEBUG HUD's map: field.", label, mapId)
    end
  end

  local cfg = Config.get()
  report("battle.terrain", cfg.battle and cfg.battle.terrain)
  -- `locations` has the same failure mode and predates the terrain table, so
  -- it is checked here too rather than left as the one silent one.
  report("locations", cfg.locations)
end

function Battle.describe()
  local w = mod.save:get("battleWeather", nil)
  if w then return w end

  if rulesRow() == "off" then return "-!wxrules-off" end
  local cfg = Config.get().battle
  if not cfg.enabled then return "-!battle-off" end
  if not cfg.seedFromOverworld then return "-!seed-off" end

  if Battle.needsRuleset() then
    if current then
      if not (current.ruleset and current.ruleset.weatherFx) then
        -- The common one by a wide margin: WX RULES is on RULESET (the
        -- default) and this save was not started on the WEATHER ruleset,
        -- so the sky never joins the battle.  WX RULES -> ALWAYS fixes it
        -- on an existing save.
        return "-!needs-ruleset"
      end
    else
      return "-?needs-ruleset"
    end
  end

  local ok, Scene = pcall(V.require, "Scene")
  if ok and Scene and Scene.now and Scene.now.indoors then
    return "-!indoors"
  end

  return "-"
end

return Battle
