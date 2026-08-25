-- Persistent weather-dependent Delta Pokémon.
-- Species are cloned from the merged Pokémon registry and registered under
-- unique string IDs. Wild substitution happens only after a normal encounter
-- succeeds, so this system never changes encounter rates or tables.

local V = ...
local mod = V.mod
local Config = V.require("Config")
local Settings = V.require("Settings")
local Scene = V.require("Scene")
local State = V.require("WeatherState")
local BaseData = V.require("WeatherVariantsData")
local Dex = V.require("WeatherVariantDex")

local function kantoReforgedInstalled()
  if not mod or type(mod.find) ~= "function" then return false end
  local ok, handle = pcall(function() return mod.find("Kanto-Reforged") end)
  return ok and handle ~= nil and handle ~= false
end

local Data = {}
for _, row in ipairs(BaseData) do Data[#Data + 1] = row end
local kantoPack
if kantoReforgedInstalled() then
  local extra = V.require("KantoWeatherVariantsData")
  for _, row in ipairs(extra) do Data[#Data + 1] = row end
  local ok, pack = pcall(require, "mods.Kanto-Reforged.pokemon_data")
  if ok and type(pack) == "table" then kantoPack = pack end
end

local Variants = {
  data = Data, registered = {}, skipped = {}, forced = nil,
  kantoReforged = kantoReforgedInstalled(),
}

-- Requested labels mapped to real IDs defined by lib/Types.lua. A label may
-- intentionally name a family (for example Rain or Seasonal).
local WEATHER_IDS = {
  ["Rain"] = { RAIN_LIGHT=true, VERDANT_RAIN=true },
  ["Heavy Rain"] = { RAIN_HEAVY=true, HEAVY_RAIN=true },
  ["Storm"] = { STORM=true, RAIN_HEAVY=true },
  ["Thunderstorm"] = { STORM=true, THUNDERSNOW=true },
  ["Snow"] = { SNOW_LIGHT=true }, ["Hail"] = { HAIL=true },
  ["Blizzard"] = { BLIZZARD=true }, ["Wind"] = { GALE=true, STRONG_WINDS=true },
  ["Sandstorm"] = { SANDSTORM=true }, ["Dust Storm"] = { DUSTSTORM=true },
  ["Ashfall"] = { ASHFALL=true }, ["Heatwave"] = { HEATWAVE=true, HARSH_SUN=true },
  ["Sunny"] = { SUNNY=true }, ["Fog"] = { FOG=true, MIST=true },
  ["Moonlit Fog"] = { HAUNTED_MIST=true }, ["Smog"] = { SMOG=true },
  ["Acid Rain"] = { SMOG=true, HEAVY_RAIN=true },
  ["Static Storm"] = { STORM=true, THUNDERSNOW=true },
  ["Flood"] = { HEAVY_RAIN=true }, ["Typhoon"] = { GALE=true, STORM=true },
  ["Aurora"] = { SNOW_LIGHT=true, THUNDERSNOW=true },
  ["Eclipse"] = { HAUNTED_MIST=true, PSYSTORM=true },
  ["Heat Haze"] = { HEATWAVE=true, SUNNY=true },
  ["Spring Rain"] = { VERDANT_RAIN=true, RAIN_LIGHT=true },
  ["Autumn Rain"] = { VERDANT_RAIN=true, RAIN_LIGHT=true },
  ["Moonlit Rain"] = { HAUNTED_MIST=true },
  ["Seasonal"] = { SUNNY=true, VERDANT_RAIN=true, SNOW_LIGHT=true },
  ["Any seasonal weather"] = { SUNNY=true, VERDANT_RAIN=true, SNOW_LIGHT=true, BLIZZARD=true },
  ["Any rare weather"] = { ASHFALL=true, BLIZZARD=true, THUNDERSNOW=true,
    HAUNTED_MIST=true, DRAGONSTORM=true, PSYSTORM=true, SMOG=true, HEAVY_RAIN=true },
}
Variants.weatherIds = WEATHER_IDS

local AFFINITIES = {
  RAIN_LIGHT={ WATER=true, GRASS=true }, RAIN_HEAVY={ WATER=true, GRASS=true },
  HEAVY_RAIN={ WATER=true, GROUND=true }, FOG={ GHOST=true, PSYCHIC_TYPE=true, POISON=true },
  HAUNTED_MIST={ GHOST=true, FAIRY=true, DARK=true }, SMOG={ POISON=true, FIRE=true },
  SNOW_LIGHT={ ICE=true }, HAIL={ ICE=true }, BLIZZARD={ ICE=true },
  STORM={ ELECTRIC=true, FLYING=true }, THUNDERSNOW={ ELECTRIC=true, ICE=true },
  SANDSTORM={ GROUND=true, ROCK=true }, DUSTSTORM={ GROUND=true, ROCK=true },
  ASHFALL={ FIRE=true, GHOST=true }, HEATWAVE={ FIRE=true, GROUND=true },
}
Variants.affinities = AFFINITIES

-- These are names already used by Weather FX config/game data. Variants also
-- remain eligible wherever their base species was just rolled, which is the
-- strongest habitat signal and avoids inventing encounter-table map IDs.
local HABITAT = {
  ASHFALL={ "CINNABAR", "POKEMON_MANSION", "POWER_PLANT" },
  SMOG={ "CELADON", "SAFFRON", "POKEMON_MANSION", "POWER_PLANT" },
  FOG={ "POKEMON_TOWER", "ROCK_TUNNEL", "MT_MOON", "SEAFOAM" },
  HAUNTED_MIST={ "POKEMON_TOWER", "LAVENDER", "ROCK_TUNNEL" },
  SANDSTORM={ "ROUTE_3", "ROUTE_4", "MT_MOON", "ROCK_TUNNEL", "VICTORY_ROAD", "DIGLETTS_CAVE" },
  DUSTSTORM={ "ROUTE_3", "ROUTE_4", "MT_MOON", "ROCK_TUNNEL", "VICTORY_ROAD" },
  SNOW_LIGHT={ "ROUTE_23", "INDIGO_PLATEAU", "SEAFOAM", "VICTORY_ROAD" },
  BLIZZARD={ "ROUTE_23", "INDIGO_PLATEAU", "SEAFOAM", "VICTORY_ROAD" },
  HAIL={ "ROUTE_23", "INDIGO_PLATEAU", "SEAFOAM" },
  STORM={ "ROUTE_", "POWER_PLANT", "CINNABAR", "SEA_ROUTE" },
  RAIN_LIGHT={ "ROUTE_", "FOREST", "CINNABAR", "SEAFOAM" },
  RAIN_HEAVY={ "ROUTE_", "FOREST", "CINNABAR", "SEAFOAM" },
  HEAVY_RAIN={ "ROUTE_", "CINNABAR", "SEAFOAM" },
}
Variants.habitats = HABITAT

local function deepCopy(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}; seen[value] = out
  for k, v in pairs(value) do out[deepCopy(k, seen)] = deepCopy(v, seen) end
  return out
end

local byCohortBase = {}
local byId = {}
for _, row in ipairs(Data) do
  byCohortBase[row.cohort] = byCohortBase[row.cohort] or {}
  byCohortBase[row.cohort][row.base] = row.id
  byId[row.id] = row
end

local function rewriteEvolution(value, cohort, inEvolution, seen)
  if type(value) == "string" then
    if inEvolution then return byCohortBase[cohort][value] or value end
    return value
  end
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}; seen[value] = out
  for k, v in pairs(value) do
    local key = tostring(k):lower()
    local evo = inEvolution or key:find("evol", 1, true) ~= nil
    out[k] = rewriteEvolution(v, cohort, evo, seen)
  end
  return out
end

local function typeAvailable(typeId)
  local chart = mod.content and mod.content.type_chart
  return not chart or type(chart.get) ~= "function" or chart:get(typeId) ~= nil
end

function Variants.install()
  local registry = mod.content and mod.content.pokemon
  if not registry or type(registry.get) ~= "function" or type(registry.register) ~= "function" then
    mod.log:warn("weather variants disabled: pokemon registry cannot register species")
    return false
  end
  local registered, skipped = 0, 0
  for _, row in ipairs(Data) do
    local base = registry:get(row.base)
    if type(base) ~= "table" and row.kantoReforged and kantoPack and kantoPack.species then
      base = kantoPack.species[row.base]
    end
    local typesOk = true
    for _, typeId in ipairs(row.types) do
      if not typeAvailable(typeId) then typesOk = false break end
    end
    if type(base) ~= "table" or not typesOk then
      Variants.skipped[row.id] = type(base) ~= "table" and "base missing" or "type missing"
      skipped = skipped + 1
    else
      local clone = rewriteEvolution(deepCopy(base), row.cohort, false)
      -- `index` is the imported ROM species number, not reusable identity.
      -- Duplicating it across hundreds of registered records makes engine
      -- paths that index auxiliary species tables resolve the vanilla base
      -- unpredictably. Registered species use their string id; dex may remain
      -- shared so the legal base Pokédex entry is retained.
      clone.index = nil
      clone.id = row.id
      clone.name = row.variant .. " " .. row.baseName:upper()
      clone.types = deepCopy(row.types)
      Dex.attach(row, clone)
      clone.level1Moves = clone.level1Moves or {}
      clone.learnset = clone.learnset or {}
      clone.evolutions = clone.evolutions or {}
      -- Intentional fallback: inherited sprites/cry/stats/moves/dex are legal
      -- references to the already-loaded base data, not redistributed assets.
      local ok, err = pcall(function() registry:register(row.id, clone) end)
      if ok then Variants.registered[row.id] = row; registered = registered + 1
      else Variants.skipped[row.id] = tostring(err); skipped = skipped + 1 end
    end
  end
  mod.log:info("weather variants: %d registered, %d skipped", registered, skipped)
  return registered > 0
end

function Variants.bindPokedex()
  return Dex.bindLive(Data, Variants.registered)
end

local poolByWeatherBase = {}
for _, row in ipairs(Data) do
  local ids = WEATHER_IDS[row.weather] or {}
  for weatherId in pairs(ids) do
    local byBase = poolByWeatherBase[weatherId]
    if not byBase then byBase = {}; poolByWeatherBase[weatherId] = byBase end
    local pool = byBase[row.base]
    if not pool then pool = {}; byBase[row.base] = pool end
    pool[#pool + 1] = row
  end
end

local LEGENDARY = { ARTICUNO=true, ZAPDOS=true, MOLTRES=true, MEWTWO=true, MEW=true }
local VERY_RARE = { DITTO=true, EEVEE=true, SNORLAX=true, DRAGONITE=true }
local function rarityOf(row)
  if LEGENDARY[row.base] then return "legendary" end
  if VERY_RARE[row.base] then return "veryRare" end
  return row.rarity or "rare"
end

local function random(rng)
  if type(rng) == "function" then return tonumber(rng()) or 1 end
  if love and love.math then return love.math.random() end
  return math.random()
end

local function configuredChance(row)
  local cfg = Config.get().weatherVariants or {}
  local rarity = rarityOf(row)
  local chance = tonumber(row.chance) or tonumber(cfg[rarity .. "Chance"])
    or tonumber(cfg.encounterChance) or 0.03
  return math.max(0, math.min(1, chance))
end

local function mapSuitable(weatherId, mapId)
  if not mapId then return false end
  local patterns = HABITAT[weatherId]
  if not patterns then return true end
  local id = tostring(mapId):upper()
  for _, pattern in ipairs(patterns) do
    if id:find(pattern, 1, true) then return true end
  end
  -- The normal roll itself proves this base species inhabits this map. Keep
  -- that authoritative instead of rejecting real tables with guessed IDs.
  return true
end
Variants.mapSuitable = mapSuitable

function Variants.forceNext(query)
  query = tostring(query or ""):upper()
  for _, row in ipairs(Data) do
    if row.id == query or row.variant == query or row.base == query
        or (row.variant .. " " .. row.baseName:upper()) == query then
      Variants.forced = row.id
      return row
    end
  end
  return nil
end

function Variants.tryEncounter(first, ctx, weatherDef)
  local cfg = Config.get().weatherVariants or {}
  if cfg.enabled == false or not Settings.weatherVariantsOn() then
    -- Do not leave a developer-forced variant queued to surprise the player
    -- after they turn the feature back on.
    Variants.forced = nil
    return first
  end
  if not (first and first.species) then return first end

  if Variants.forced then
    local row = byId[Variants.forced]
    Variants.forced = nil
    if row and Variants.registered[row.id] then
      local out = {}; for k, v in pairs(first) do out[k] = v end
      out.species, out.weatherVariant, out.rare = row.id, true, true
      return out
    end
  end

  if not weatherDef or not weatherDef.id then return first end
  local byBase = poolByWeatherBase[weatherDef.id]
  local pool = byBase and byBase[first.species]
  if not pool or #pool == 0 or not mapSuitable(weatherDef.id, Scene.now.mapId) then return first end
  local rng = ctx and ctx.rng
  local candidates = {}
  for _, row in ipairs(pool) do
    if Variants.registered[row.id] then candidates[#candidates + 1] = row end
  end
  if #candidates == 0 then return first end
  local row = candidates[math.min(#candidates, math.floor(random(rng) * #candidates) + 1)]
  if random(rng) >= configuredChance(row) then return first end
  local out = {}; for k, v in pairs(first) do out[k] = v end
  out.species, out.weatherVariant, out.rare = row.id, true, true
  return out
end

function Variants.describe()
  local n = 0; for _ in pairs(Variants.registered) do n = n + 1 end
  return ("%d/%d registered"):format(n, #Data)
end

return Variants
