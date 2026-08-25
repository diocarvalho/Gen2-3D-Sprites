-- WEATHER IN THE GRASS AND ON THE WATER.
--
-- Three effects, all through documented hooks, all generation-agnostic --
-- the Gen 2 migration guide names `encounter.species` as the route to take
-- INSTEAD of engine surgery, so this is the one part of the mod that is
-- more portable than the code around it, not less.
--
--   encounter.roll      weather leans which species you meet in the grass
--   encounter.fishing   rain brings the fish up
--
-- =====================================================================
-- HOW THE BIAS WORKS
-- =====================================================================
--
-- Every weather with a `chipType` (or a fog/sun/ice tag) favours that type
-- in the grass.  On a weather-influenced step the encounter is rolled
-- again through the vanilla chain, and a matching second roll is kept.
-- Several attempts are made for strongly typed storms (Dragonstorm,
-- Psystorm, Swarm, ...) so the bias is felt without editing tables.
--
-- Only species the map ALREADY contains can appear from a reroll, so a
-- route with no Ghost is unaffected by fog and no encounter table is
-- bypassed.  When the map has no matching species, an optional inject
-- step can pull a species of the favoured type from the merged Pokédex
-- (vanilla + any expanded-dex mod registered through mod.content.pokemon)
-- at the rolled level -- rain can surface Water-types, Dragonstorm can
-- surface Dragons, and so on for every typed weather.
--
-- The encounter RATE is deliberately untouched: a reroll only happens
-- when the first draw already produced an encounter.

local V = ...
local mod = V.mod
local Types = V.require("Types")
local Config = V.require("Config")
local Scene = V.require("Scene")
local State = V.require("WeatherState")
local Legendary = V.require("Legendary")
local WeatherVariants = V.require("WeatherVariants")

local Enc = {}

-- ------- type affinity
--
-- Primary source is `chipType` on the weather def -- every typed front
-- already declares the damage type it chips, which is exactly the type
-- that should be drawn out in the grass.  Fog/sun/ice tags cover the
-- classic weathers that predate chipType or share one.

-- Chance of taking a second (or further) roll, by favoured type.
local STRENGTH = {
  GHOST = 0.60, FIRE = 0.45, ICE = 0.45, WATER = 0.40,
  ELECTRIC = 0.50, GRASS = 0.45, ROCK = 0.45, GROUND = 0.45,
  POISON = 0.50, BUG = 0.50, FLYING = 0.45, FIGHTING = 0.50,
  DRAGON = 0.65, PSYCHIC = 0.55, NORMAL = 0.35,
  -- Gen 2 types
  DARK = 0.55, STEEL = 0.45,
}

-- Extra reroll attempts for exotic fronts so the bias is felt.
local ATTEMPTS = {
  DRAGON = 4, PSYCHIC = 3, GHOST = 3, FIGHTING = 3,
  POISON = 3, BUG = 3, ELECTRIC = 3,
  DARK = 3, STEEL = 2,
}

local function favouredType(def)
  if not def then return nil end
  if def.chipType then return def.chipType end
  if Types.channel(def, "fog") > 0 then return "GHOST" end
  if def.sunny then return "FIRE" end
  if def.frozen then return "ICE" end
  if def.wet then return "WATER" end
  if def.sandy then return "ROCK" end
  return nil
end
Enc.favouredType = favouredType

-- Hard type bans by weather tag.  Unlike STRENGTH (soft bias), a banned
-- type is never kept when the weather is active outdoors — the roll is
-- replaced until a non-banned species appears (or the encounter is dropped).
-- Keys match weather flags on Types defs (wet/sunny/frozen/sandy) plus fog.
-- Includes Gen 2 types (DARK, STEEL). Steel is *not* banned in sand
-- (matches battle sand immunity). Edit via config.encounters.bans.
local DEFAULT_BANS = {
  wet     = { "FIRE", "STEEL" },           -- rain/storm/sleet: no Fire/Steel
  sunny   = { "WATER", "ICE" },            -- harsh sun: Water/Ice struggle
  frozen  = { "BUG", "GRASS", "FLYING" },-- snow/hail: Bug/Grass/Flying
  sandy   = { "WATER", "BUG" },            -- sand: Water/Bug (not STEEL)
  foggy   = { "FIRE" },                    -- fog: Fire stays away
  ash     = { "BUG", "GRASS", "ICE" },     -- ashfall
  psychic = { "DARK" },                    -- psystorm front: Dark suppressed
}

local function weatherForBans()
  -- Bans follow the sky you see, including ALWAYS / pinned rain.
  if not Config.get().encounters.enabled then return nil end
  if (State.level or 0) <= 0 then return nil end
  if Scene.now.indoors and not Config.locationFor(Scene.now.mapId, true) then
    return nil
  end
  return State.current()
end

local function bannedSet(def, cfg)
  local set = {}
  if not def then return set end
  local bans = (cfg and cfg.bans) or DEFAULT_BANS
  local function addList(list)
    if type(list) ~= "table" then return end
    for i = 1, #list do
      local ty = list[i]
      if type(ty) == "string" then set[ty:upper()] = true end
    end
  end
  if def.wet then addList(bans.wet) end
  if def.sunny then addList(bans.sunny) end
  if def.frozen then addList(bans.frozen) end
  if def.sandy then addList(bans.sandy) end
  if def.psychic then addList(bans.psychic) end
  if Types.channel(def, "fog") > 0.15 then addList(bans.foggy) end
  if Types.channel(def, "ash") > 0.15 or (def.id and tostring(def.id):find("ASH", 1, true)) then
    addList(bans.ash)
  end
  -- Per-weather-id overrides: cfg.bansById.RAIN_HEAVY = { "FIRE", "GRASS" }
  if cfg and type(cfg.bansById) == "table" and def.id then
    addList(cfg.bansById[def.id] or cfg.bansById[tostring(def.id):upper()])
  end
  return set
end

local function isBanned(species, set)
  if not species or not set then return false end
  local list = (Enc.typesOf or typesOf)(species)
  if type(list) ~= "table" then return false end
  for i = 1, #list do
    if set[list[i]] then return true end
  end
  return false
end


local function typesOf(species)
  local ok, list = pcall(function()
    local Game = require("src.core.Game")
    local data = Game and Game.data and Game.data.pokemon
    local def = data and data[species]
    return def and def.types or nil
  end)
  if ok then return list end
  return nil
end
Enc.typesOf = typesOf

local function isType(species, wanted)
  local list = (Enc.typesOf or typesOf)(species)
  if type(list) ~= "table" then return false end
  for i = 1, #list do
    if list[i] == wanted then return true end
  end
  return false
end
Enc.isType = isType

-- Cache of species ids per type.  Built from the MERGED pokemon registry
-- (mod.content.pokemon) so an expanded-dex mod's species are included;
-- falls back to Game.data.pokemon when the registry is not yet available.
local poolByType = nil
local poolBroken = false
local poolSource = "none"

local function addToPools(pools, id, def)
  if type(id) ~= "string" or type(def) ~= "table" then return end
  if type(def.types) ~= "table" then return end
  -- Skip entries explicitly marked non-wild / non-encounter.
  if def.encounter == false or def.wild == false then return end
  if def.inject == false then return end
  for i = 1, #def.types do
    local t = def.types[i]
    if type(t) == "string" then
      local bucket = pools[t]
      if not bucket then bucket = {}; pools[t] = bucket end
      bucket[#bucket + 1] = id
    end
  end
end

local function buildPools()
  local pools = {}
  local source = "none"

  -- 1) Merged content registry -- includes every mod that registered or
  --    patched pokemon (expanded dex, fakemon packs, type edits, …).
  local okReg, regCount = pcall(function()
    local reg = mod.content and mod.content.pokemon
    if not reg or type(reg.each) ~= "function" then return 0 end
    local n = 0
    for id, def in reg:each() do
      addToPools(pools, id, def)
      n = n + 1
    end
    return n
  end)
  if okReg and (regCount or 0) > 0 then
    source = "registry"
  end

  -- 2) Fallback: live Game.data.pokemon (ROM import + whatever merged into
  --    Data.pokemon).  Used when the registry iterator is empty or missing.
  if source == "none" then
    local okData, dataCount = pcall(function()
      local Game = require("src.core.Game")
      local data = Game and Game.data and Game.data.pokemon
      if type(data) ~= "table" then return 0 end
      local n = 0
      for id, def in pairs(data) do
        addToPools(pools, id, def)
        n = n + 1
      end
      return n
    end)
    if okData and (dataCount or 0) > 0 then
      source = "gamedata"
    end
  end

  if source == "none" then return nil, "none" end
  return pools, source
end

local function typePool(wanted)
  if poolBroken then return nil end
  if not poolByType then
    local built, source = buildPools()
    if not built then
      poolBroken = true
      poolSource = "none"
      return nil
    end
    poolByType = built
    poolSource = source or "unknown"
    mod.log:info("encounter type pools from %s", poolSource)
  end
  return poolByType[wanted]
end
Enc.typePool = typePool

-- Drop the cache so a late-loading expanded dex is picked up next inject.
function Enc.invalidatePools()
  poolByType = nil
  poolBroken = false
  poolSource = "none"
end

local function pickFromPool(wanted, rng)
  local pool = typePool(wanted)
  if not pool or #pool == 0 then return nil end
  local roll
  if type(rng) == "function" then
    roll = rng()
  elseif love and love.math then
    roll = love.math.random()
  else
    roll = math.random()
  end
  local idx = math.floor((tonumber(roll) or 0) * #pool) + 1
  if idx < 1 then idx = 1 end
  if idx > #pool then idx = #pool end
  return pool[idx]
end

-- Pinned skies (ALWAYS row, config.force, OPTIONS ladder pin, DEBUG RAIN)
-- are cosmetic/testing choices -- they must not rewrite the grass.  Only
-- weather the world produced on its own (AUTO, CYCLE, fronts, locations,
-- legends, psystorms) leans encounters.
local FORCED_PIN = {
  always = true, config = true, menu = true, debug = true,
}

-- The weather actually being experienced out here.  Indoors and covered
-- frames answer nil, so a cave with no sky does not conjure Ghosts.
-- Forced/pinned weather also answers nil so ALWAYS SNOW does not turn
-- every route into an Ice-type safari.
local function activeWeather()
  if not Config.get().encounters.enabled then return nil end
  if (State.level or 0) <= 0 then return nil end
  if Scene.now.indoors and not Config.locationFor(Scene.now.mapId, true) then
    return nil
  end
  if FORCED_PIN[State.pinnedBy or ""] then return nil end
  return State.current()
end
Enc.activeWeather = activeWeather

local function chance(rng, p)
  local roll
  if type(rng) == "function" then roll = rng()
  elseif love and love.math then roll = love.math.random()
  else roll = math.random() end
  return (tonumber(roll) or 1) < p
end

-- Weather multiplies how often grass produces *some* encounter.
-- 1.5 => ~50% more encounters (retry when the first roll is empty).
-- Legendaries use their own smaller boost in Legendary.claimEncounter.
function Enc.rateMultiplier()
  local cfg = Config.get().encounters
  if not cfg or cfg.enabled == false then return 1 end
  if cfg.rateBoost == false then return 1 end
  local mult = tonumber(cfg.rateBoost) or 1.5
  if mult < 1 then mult = 1 end
  -- Only outdoors with live weather (not CLEAR-only cosmetic).
  if Scene.now.indoors then return 1 end
  if (State.level or 0) <= 0 then return 1 end
  local def = State.current and State.current()
  if not def or def.id == "CLEAR" then return 1 end
  return mult
end


function Enc.install()
  -- ------- typed weather leans the grass
  --
  -- WHY `encounter.roll` AND NOT `encounter.species`.
  --
  -- This hung off `encounter.species` and did nothing at all in a real game.
  -- That hook is a TRANSFORM: its vanilla link is the identity function, so
  -- calling it a second time hands back the same encounter.  `encounter.roll`
  -- is the hook that actually draws with fresh RNG every call.

  mod.hooks:wrap("encounter.roll", function(next_, encDef, ctx)
    local first = next_(encDef, ctx)

    -- ------- Rate boost (~50% more encounters under active weather)
    -- When the engine produced no encounter, retry once with probability
    -- that yields about rateBoost× overall rate for typical step rates.
    if not (first and first.species) then
      local mult = Enc.rateMultiplier()
      if mult > 1 then
        -- P(retry | miss) ≈ (mult - 1) / mult  → overall ≈ mult × base
        local retryP = (mult - 1) / mult
        if chance(ctx and ctx.rng, retryP) then
          first = next_(encDef, ctx)
        end
      end
      if not (first and first.species) then return first end
    end

    -- Legendary bird / beast substitution (roused weather only).
    -- Uses its own +5% chance scale, not the wild 50% rate boost.
    local bird, birdLevel = Legendary.claimEncounter()
    if bird then
      local out = {}
      for k, v in pairs(first) do out[k] = v end
      out.species = bird
      out.level = birdLevel or out.level
      return out
    end

    -- A registered Delta may substitute for the normal species only under
    -- its mapped live weather. The normal roll is preserved on every miss.
    local variant = WeatherVariants.tryEncounter(first, ctx, activeWeather())
    if variant ~= first then return variant end

    local cfg = Config.get().encounters

    -- ------- Hard type bans (e.g. no Fire in rain)
    -- Runs even when soft species bias is off, and follows pinned weather.
    if cfg.bans ~= false then
      local banDef = weatherForBans()
      local banned = bannedSet(banDef, cfg)
      if next(banned) ~= nil and isBanned(first.species, banned) then
        local rng = ctx and ctx.rng
        local replacement = nil
        for _ = 1, 10 do
          local second = next_(encDef, ctx)
          if second and second.species and not isBanned(second.species, banned) then
            replacement = second
            break
          end
        end
        if not replacement and cfg.inject ~= false then
          -- Prefer a non-banned type from the soft-bias favourite, else WATER/NORMAL
          local prefer = favouredType(banDef) or "NORMAL"
          if banned[prefer] then prefer = "WATER" end
          if banned[prefer] then prefer = "NORMAL" end
          if banned[prefer] then prefer = "GRASS" end
          if not banned[prefer] then
            local species = pickFromPool(prefer, rng)
            if species and not isBanned(species, banned) then
              replacement = {}
              for k, v in pairs(first) do replacement[k] = v end
              replacement.species = species
            end
          end
        end
        if replacement then
          first = replacement
        else
          -- Could not find a legal species — drop this encounter rather than
          -- force a banned type (100% exclusion).
          return nil
        end
      end
    end

    if not cfg.species then return first end

    local def = activeWeather()
    local wanted = favouredType(def)
    if not wanted then return first end
    if isType(first.species, wanted) then return first end

    local strength = (STRENGTH[wanted] or 0.4) * (tonumber(cfg.strength) or 1)
    if strength <= 0 then return first end

    -- Soft bias must not reintroduce a hard-banned type.
    local bannedSoft = bannedSet(weatherForBans(), cfg)
    if bannedSoft[wanted] then return first end

    local attempts = ATTEMPTS[wanted] or 2
    local rng = ctx and ctx.rng
    for _ = 1, attempts do
      if not chance(rng, strength) then break end
      local second = next_(encDef, ctx)
      if second and second.species and isType(second.species, wanted)
          and not isBanned(second.species, bannedSoft) then
        return second
      end
    end

    -- Inject: any favoured type, when enabled, after the map table failed
    -- to produce a match.  Pool is the merged Pokédex (expanded dex mods
    -- included).  Level comes from the original roll so Route 1 does not
    -- hand out Lv50 legends.
    local allowInject = cfg.inject
    if allowInject == nil then allowInject = true end
    if allowInject then
      local injectChance = (tonumber(cfg.injectChance) or 0.35) * (tonumber(cfg.strength) or 1)
      if injectChance > 0 and chance(rng, injectChance) then
        local species = pickFromPool(wanted, rng)
        if species and not isBanned(species, bannedSoft) then
          local out = {}
          for k, v in pairs(first) do out[k] = v end
          out.species = species
          return out
        end
      end
    end

    return first
  end)

  -- ------- rain brings the fish up

  mod.hooks:wrap("encounter.fishing", function(next_, rod, mapId, candidates)
    local first = next_(rod, mapId, candidates)
    local cfg = Config.get().encounters
    if not cfg.fishing then return first end

    local def = activeWeather()
    if not (def and def.wet) then return first end
    if not chance(nil, (tonumber(cfg.fishingBonus) or 0.5)) then return first end

    local second = next_(rod, mapId, candidates)
    if not first then return second end
    if not second then return first end
    local a = tonumber(first.level) or 0
    local b = tonumber(second.level) or 0
    if b > a then return second end
    return first
  end)

  return true
end

function Enc.describe()
  local wanted = favouredType(activeWeather())
  return wanted or "-"
end

return Enc
