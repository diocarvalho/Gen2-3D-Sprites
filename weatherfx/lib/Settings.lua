-- The mod's own settings: the rows on this mod's page in the mod manager,
-- and typed readers for them.
--
-- WHY NOT THE OPTIONS MENU.  The engine gives a render pipeline a row on
-- the main OPTIONS menu for free (label + ladder + persistence), and the
-- WEATHER row is exactly that -- so the one setting the player changes
-- often is one button press from where they already are.  Everything here
-- is a set-once preference (quality, accessibility, whether battles get
-- weather), and putting seven more rows on the main menu to sit unused
-- would be worse for the player than a page in the manager they visit
-- once.  Dramatic Shape's ModSetting mirrors its two onto both menus
-- because they are per-scene settings; these are not.
--
-- Every read goes through mod.options:get, which falls back to the row's
-- declared default, so a fresh install with nothing persisted reads the
-- same values as a configured one and no caller ever needs a `or`.

local V = ...
local mod = V.mod
local Types = V.require("Types")

local Settings = {}

-- Row order is page order.  Choice values are the stored ones; the first
-- element of each pair is what the row shows.
Settings.SCHEMA = {
  {
    key = "quality", label = "QUALITY", type = "choice", default = "auto",
    choices = { { "AUTO", "auto" }, { "HIGH", "high" },
                { "MEDIUM", "medium" }, { "LOW", "low" } },
    help = "Particle budget. AUTO picks by platform and steps down if the "
        .. "frame rate sags.",
  },
  {
    -- ALWAYS <WEATHER>: the "always snow", "always rain" switch, on the
    -- page a player can reach without a text editor.  `force` in
    -- config.lua does the same job for a folder install; this is the same
    -- setting for the .modpkg case, which is the one that has caught us
    -- out three times now.
    --
    -- ONE ROW RATHER THAN TWENTY SWITCHES, because these are mutually
    -- exclusive by nature: "always snow" and "always rain" cannot both be
    -- true, and twenty independent toggles would let a player set that and
    -- then wonder which one won.  A single-select row cannot express the
    -- contradiction in the first place.
    --
    -- The choices are built from the catalogue below, so adding a weather
    -- type adds its rung here with no second list to keep in step.
    key = "always", label = "ALWAYS", type = "choice", default = "off",
    choices = nil,          -- filled in below
    help = "Pin one weather everywhere: ALWAYS SNOW, ALWAYS RAIN, and so "
        .. "on. OFF lets the weather system run normally.",
  },
  {
    key = "intensity", label = "INTENSITY", type = "choice", default = "normal",
    choices = { { "SOFT", "soft" }, { "NORMAL", "normal" },
                { "HEAVY", "heavy" }, { "AUTO", "auto" } },
    help = "Scales every effect at once. AUTO makes each of them swell and "
        .. "ease on its own slow rhythm, so a downpour is not the same "
        .. "downpour for six minutes.",
  },
  {
    -- Snow, hail, sleet, sandstorm and ashfall are the weathers Kanto has
    -- no obvious business having, so the built-in region bias suppresses
    -- them hard away from the few maps that argue for them.  That was
    -- tuned for plausibility and it made them effectively invisible: a
    -- player could run AUTO for hours and never see snow.  This row is the
    -- dial between "plausible" and "I would like to see the thing I
    -- installed", and it defaults to the middle rather than to realism.
    key = "exotic", label = "RARE WX", type = "choice", default = "normal",
    choices = { { "OFF", "off" }, { "RARE", "rare" },
                { "NORMAL", "normal" }, { "OFTEN", "often" } },
    help = "How often snow, hail, sleet, sandstorms and ashfall turn up "
        .. "away from the places that suit them. RARE is the realistic "
        .. "setting; OFF removes them from AUTO entirely.",
  },
  {
    key = "speed", label = "AUTO SPEED", type = "choice", default = "normal",
    choices = { { "SLOW", "slow" }, { "NORMAL", "normal" },
                { "FAST", "fast" }, { "TEST", "test" } },
    help = "How long an AUTO spell lasts. TEST changes it every few "
        .. "seconds, for looking at the effects.",
  },
  {
    key = "daytime", label = "TIME OF DAY", type = "choice", default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
    help = "AUTO leans toward fog and storms after dark. Uses Dramatic "
        .. "Shape's clock when that mod is installed.",
  },
  {
    -- Seasons were left out of the first design because Gen 1/2 have none
    -- and the region bias already answers "where does it snow".  Players
    -- still asked for a calendar, so this is the opt-in layer on top: four
    -- seasons, a hemisphere flip, and seasonal weight multipliers on AUTO.
    key = "seasons", label = "SEASONS", type = "choice", default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
    help = "Four seasons that lean AUTO weather (snow in winter, sun in "
        .. "summer). Uses the real calendar on SYSTEM time, or an in-game "
        .. "year on CYCLE.",
  },
  {
    key = "hemisphere", label = "HEMISPHERE", type = "choice",
    default = "northern",
    choices = { { "NORTH", "northern" }, { "SOUTH", "southern" } },
    help = "Which hemisphere the seasons follow. SOUTH reverses them so "
        .. "December is summer. Only matters when SEASONS is ON.",
  },
  {
    key = "seasonNotify", label = "SEASON NOTE", type = "choice",
    default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
    help = "Show a short on-screen banner when the season changes.",
  },
  {
    key = "battles", label = "BATTLES", type = "choice", default = "subtle",
    choices = { { "OFF", "off" }, { "SUBTLE", "subtle" }, { "FULL", "full" } },
    help = "Weather over the battle screen. SUBTLE thins it so the HUD "
        .. "stays readable.",
  },
  {
    -- Species stay registered even when this is OFF. Existing caught
    -- variants and their Pokédex/save records therefore remain valid; only
    -- new wild substitutions stop. Unregistering live species would corrupt
    -- parties and saves made while the option was ON.
    key = "weatherVariants", label = "WX POKEMON", type = "choice",
    default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
    help = "Weather-form Pokémon in wild encounters. OFF keeps all visual "
        .. "weather active but stops new weather variants from appearing. "
        .. "Variants already caught remain usable.",
  },
  {
    -- The gameplay half of battle weather, on the page a player can
    -- actually reach.  It lived only in config.lua until 2.8, which a
    -- .modpkg install has no editable copy of -- the same mistake that
    -- made DEBUG RAIN unreachable in 2.0.1.
    --
    --   OFF      no weather effects in battle at all
    --   RULESET  effects apply, but the overworld's weather only carries
    --            into a battle on the WEATHER ruleset (a new game)
    --   ALWAYS   the sky carries into every outdoor battle, on any save
    --
    -- Weather that a MOVE or ABILITY sets is never gated by this: those
    -- battles already had weather, and RULESET only decides whether the
    -- SKY joins in.
    -- WHY THE DEFAULT IS `always`, changed in 2.11.0.
    --
    -- It was `ruleset`, on the reasoning that a mod should change nothing
    -- until it is opted into. In practice that reasoning failed the most
    -- common install by far: the player adds the mod to a save they are
    -- already playing, pins a sky on the WEATHER row, walks into grass and
    -- gets a dry battle. Nothing is broken, nothing says so, and the
    -- setting that explains it is a different row with a different name.
    --
    -- "Correct but indistinguishable from broken" is the wrong default. The
    -- overworld weather is already visible and already opted into by the
    -- WEATHER row being off OFF; carrying that same sky into a battle is
    -- what the player has already asked for. `RULESET` remains one row away
    -- for anyone who wants battles untouched until a WEATHER-ruleset save.
    --
    -- What this does NOT change: `OFF` still means no battle effects at
    -- all, an indoor battle still inherits no sky, and a weather a MOVE or
    -- ABILITY set was never gated by this row in the first place.
    key = "battlerules", label = "WX RULES", type = "choice",
    default = "always",
    choices = { { "OFF", "off" }, { "RULESET", "ruleset" },
                { "ALWAYS", "always" } },
    help = "Weather effects in battle: chip damage, accuracy, type "
        .. "boosts. ALWAYS (the default) carries the overworld sky into "
        .. "every outdoor battle on any save. RULESET restricts that to a "
        .. "game STARTED on the WEATHER ruleset. OFF disables battle "
        .. "weather entirely.",
  },
  {
    -- The one house rule with a menu row. `terrain` deliberately has none:
    -- it only fires on named maps and contradicts nothing, so it is a config
    -- decision rather than a thing to flip mid-run. Amplified changes how
    -- every primal sky and every sandstorm hits, which is exactly the kind
    -- of thing a player wants to try, dislike, and turn off without editing
    -- a file.
    --
    -- AUTO defers to config.lua (off unless the file says otherwise), so the
    -- row adds a way to answer without taking the file's answer away.
    key = "amplified", label = "AMPLIFIED", type = "choice", default = "auto",
    choices = { { "AUTO", "auto" }, { "OFF", "off" }, { "ON", "on" } },
    help = "House rule, not reference behaviour: harsh sun and heavy rain "
        .. "hit much harder, sandstorms power up ROCK and GROUND, and hail "
        .. "powers up ICE. Ordinary sun and rain are untouched. AUTO follows "
        .. "config.lua, which has it off.",
  },
  {
    key = "lightning", label = "LIGHTNING", type = "choice", default = "full",
    choices = { { "OFF", "off" }, { "SOFT", "soft" }, { "FULL", "full" } },
    help = "SOFT removes the sharp flash and keeps a slow glow -- the "
        .. "setting to use if flashing images are a problem.",
  },
  {
    -- AROUND is the safe default: it uses the documented render.letterbox
    -- hook and cannot contend with anything.  BEHIND additionally patches
    -- BattleState.draw to replace the battle's white field, which is the
    -- only engine internal this mod touches -- opt-in, and it stands down
    -- when another mod is staging battles or SGB colour mode is on.
    key = "backdrops", label = "BATTLE ART", type = "choice", default = "around",
    choices = { { "OFF", "off" }, { "AROUND", "around" }, { "BEHIND", "behind" } },
    help = "Painted scenery, picked by the weather and the map. AROUND "
        .. "fills the bars beside the battle; BEHIND also replaces the "
        .. "battle's white field. Art: CDRX73, DerxwnaKapsyla, "
        .. "http404error, Game Freak.",
  },
  {
    key = "sfx", label = "WEATHER SFX", type = "choice", default = "medium",
    choices = { { "OFF", "off" }, { "LOW", "low" },
                { "MEDIUM", "medium" }, { "HIGH", "high" } },
    help = "Rain and storm loops, and thunder on the strike. Only the rain "
        .. "weathers have sound; the rest are silent on purpose.",
  },
  {
    key = "splash", label = "SPLASHES", type = "choice", default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
    help = "Drops burst where they land.",
  },
  {
    key = "indoors", label = "INDOORS", type = "choice", default = "tint",
    choices = { { "OFF", "off" }, { "TINT", "tint" } },
    help = "TINT keeps a storm's gloom (and its lightning through the "
        .. "windows) while you are inside. Rain never falls indoors.",
  },
  {
    -- OFF by default, and the row itself says why.  This is the only
    -- setting in the mod that MOVES THE PLAYER, and a warp does not know
    -- what the story expects: even restricted to places already visited,
    -- being carried mid-errand can strand you without the HM you set out
    -- with, or drop you the wrong side of a gate you have not opened from
    -- that direction.  None of that is fixable here, because "where the
    -- player is supposed to be right now" is a fact only the story knows.
    key = "tornado", label = "TORNADOES", type = "choice", default = "off",
    choices = { { "OFF", "off" }, { "ON", "on" } },
    help = "POST-GAME ONLY. In a gale, a tornado can carry you to a town "
        .. "you have already visited. It can strand you mid-quest and is "
        .. "not recommended during the story. Type `weather return` in the "
        .. "console to go back.",
  },
  {
    -- 2D = original Weather FX overlays (fog, rain particles, etc.).
    -- 3D = Dramaless/Potato voxel-pass weather when that host is running.
    -- AUTO = 3D when the host is available, otherwise 2D.
    key = "present", label = "WX PRESENT", type = "choice", default = "auto",
    choices = { { "AUTO", "auto" }, { "2D", "2d" }, { "3D", "3d" } },
    help = "How overworld weather is drawn. 2D is the original Weather FX "
        .. "rain and fog overlays. 3D draws inside Dramaless/Potato voxel "
        .. "mode when available. AUTO picks 3D when it can, else 2D. "
        .. "Change anytime; battles always use Weather FX.",
  },
  {
    -- The same switch as config.lua's `debugRain`, on the page a player
    -- can actually reach.  It is HERE and not only in the file because a
    -- .modpkg install has no editable config.lua at all -- so a debug
    -- switch that lived only in the file was unreachable for exactly the
    -- people most likely to need it.
    key = "debugRain", label = "DEBUG RAIN", type = "choice", default = "off",
    choices = { { "OFF", "off" }, { "ON", "on" } },
    help = "Force heavy rain everywhere, indoors and out, and switch the "
        .. "weather system on even if the OPTIONS row is OFF. For testing "
        .. "that the mod is working; turn it off afterwards.",
  },
  {
    key = "debug", label = "DEBUG HUD", type = "choice", default = "off",
    choices = {
      { "OFF", "off" },
      { "SIMPLE", "simple" },
      { "FULL", "full" },
      { "3D", "3d" },
      { "ON", "on" },  -- alias of FULL (older saves / habit)
    },
    help = "On-screen diagnostics. SIMPLE: weather + present + 3D status. "
        .. "FULL: detailed particle/battle/map readout. 3D: voxel bridge only. "
        .. "ON matches FULL.",
  },
}

-- Build the ALWAYS row's choices from the weather catalogue.  Done here
-- rather than typed out so a new weather type appears on the row without
-- anyone remembering to add it -- the same reason the OPTIONS ladder is
-- built from Types.PINNED.
do
  for _, row in ipairs(Settings.SCHEMA) do
    if row.key == "always" then
      local choices = { { "OFF", "off" } }
      for _, id in ipairs(Types.PINNED) do
        local def = Types.get(id)
        if def and def.label then
          choices[#choices + 1] = { def.label, id }
        end
      end
      row.choices = choices
    end
  end
end

function Settings.define()
  return mod.options:define(Settings.SCHEMA)
end

-- Read a row.  Falling back through the schema means a value written by an
-- older version that no longer exists as a choice still resolves to the
-- default instead of to nil.
local defaults = {}
local valid = {}
for _, row in ipairs(Settings.SCHEMA) do
  defaults[row.key] = row.default
  local set = {}
  for _, choice in ipairs(row.choices or {}) do set[choice[2]] = true end
  valid[row.key] = set
end

function Settings.get(key)
  local ok, value = pcall(function() return mod.options:get(key) end)
  if not ok or value == nil or not valid[key][value] then
    return defaults[key]
  end
  return value
end


-- Overworld presentation: "2d" | "3d" | "auto"
function Settings.presentMode()
  return Settings.get("present") or "auto"
end

-- True when the player wants the original Weather FX 2D overlays forced.
function Settings.force2dPresent()
  return Settings.presentMode() == "2d"
end

-- DEBUG HUD tier.  "on" is kept as an alias of "full" so older saves and
-- muscle memory still work.
function Settings.debugHudMode()
  local v = Settings.get("debug")
  if v == "on" then return "full" end
  if v == "simple" or v == "full" or v == "3d" then return v end
  return "off"
end

function Settings.debugHudOn()
  return Settings.debugHudMode() ~= "off"
end



-- True when the player allows 3D (auto or explicit 3d).
function Settings.allow3dPresent()
  local m = Settings.presentMode()
  return m == "3d" or m == "auto"
end

-- The weather the ALWAYS row is pinning, or nil.  Validated against the
-- catalogue, so a value stored by a build with more weathers than this one
-- reads as "off" rather than pinning something that cannot be drawn.
function Settings.alwaysWeather()
  local v = Settings.get("always")
  if not v or v == "off" then return nil end
  if not Types.byId[v] then return nil end
  return v
end

function Settings.is(key, value)
  return Settings.get(key) == value
end

function Settings.weatherVariantsOn()
  return Settings.get("weatherVariants") == "on"
end

-- The debug-rain switch, from EITHER source.  Two places to set one thing
-- is normally a smell, but these two reach different people: the file is
-- for a folder install and a considered playthrough, the row is for a
-- packed .modpkg on a handheld with no text editor.
function Settings.debugRain(config)
  if config and config.get().debugRain then return true end
  return Settings.is("debugRain", "on")
end

-- ------- derived numbers the draw path wants

local INTENSITY = { soft = 0.6, normal = 1.0, heavy = 1.35 }
function Settings.intensity()
  local v = INTENSITY[Settings.get("intensity")]
  if v then return v end
  return 1                      -- "auto" scales per family instead; see below
end

-- ------- AUTO intensity
--
-- Real weather is not a constant.  A downpour has heavier and lighter
-- minutes inside it, and a storm's strikes cluster and then go quiet.  On
-- the fixed settings this mod picks one number and holds it for the whole
-- spell, which is the single thing that most gives away that the sky is a
-- particle system.
--
-- AUTO fixes that WITHOUT touching the weather itself: the type still says
-- "heavy rain", the state machine still eases toward the same targets, and
-- only the final multiplier breathes.  So nothing downstream -- the battle
-- layer, the AUTO scheduler, the save -- can tell the difference.
--
-- EACH FAMILY GETS ITS OWN RHYTHM, which is the part that matters.  If one
-- oscillator drove everything, the rain, the fog and the lightning would
-- swell and fade in lockstep and read as the brightness being turned up
-- and down.  Five families on unrelated periods, with different phases,
-- never line up for long:
--
--   wet     rain and its splashes
--   frozen  snow
--   grain   hail, sand, blown debris
--   haze    fog banks and the flat veil
--   light   lightning strike rate
--
-- Two sines per family at incommensurable periods -- so the pattern does
-- not repeat on any timescale a player would notice -- mapped into the
-- configured min..max range.

local AUTO_FAMILIES = {
  wet    = { p1 = 37.0, p2 = 13.7, phase = 0.0 },
  frozen = { p1 = 43.0, p2 = 17.3, phase = 1.3 },
  grain  = { p1 = 29.0, p2 = 11.1, phase = 2.6 },
  haze   = { p1 = 61.0, p2 = 23.9, phase = 3.9 },
  light  = { p1 = 23.0, p2 =  8.3, phase = 5.2 },
}

Settings.AUTO_FAMILIES = AUTO_FAMILIES

-- Which family a channel belongs to.  Channels absent from this map do not
-- breathe at all -- deliberately: the grade channels (dim, cool, warm,
-- glare) drive a full-screen multiply, and a full-screen multiply that
-- pulses does not read as weather, it reads as a fault.
Settings.CHANNEL_FAMILY = {
  rain = "wet", splash = "wet",
  snow = "frozen",
  hail = "grain", sand = "grain", debris = "grain",
  fog = "haze", veil = "haze",
  strike = "light",
}

-- `t` is the weather clock in seconds.  Returns the multiplier for one
-- family, or 1 when AUTO is not selected -- so the caller needs no branch.
function Settings.autoScale(family, t, config)
  if Settings.get("intensity") ~= "auto" then return 1 end
  local f = AUTO_FAMILIES[family or ""]
  if not f then return 1 end
  local cfg = config and config.get().autoIntensity
  local lo = (cfg and cfg.min) or 0.5
  local hi = (cfg and cfg.max) or 1.4
  local rate = (cfg and cfg.seconds) or 1
  if rate <= 0 then rate = 1 end
  t = (tonumber(t) or 0) / rate
  -- 0.7/0.3 weighting: a long swell with a shorter ripple on top, rather
  -- than two equal waves, which would read as a beat frequency
  local a = math.sin((t / f.p1) * 2 * math.pi + f.phase) * 0.7
  local b = math.sin((t / f.p2) * 2 * math.pi + f.phase * 1.7) * 0.3
  local unit = (a + b + 1) * 0.5          -- -1..1 -> 0..1
  if unit < 0 then unit = 0 elseif unit > 1 then unit = 1 end
  return lo + (hi - lo) * unit
end

-- Minutes an AUTO spell lasts, as a multiplier on the type's own range.
local SPEED = { slow = 2.2, normal = 1.0, fast = 0.45, test = 0.02 }
function Settings.speedScale()
  return SPEED[Settings.get("speed")] or 1
end

-- How much the region bias is allowed to suppress an out-of-place
-- weather.  1 means "no suppression at all"; the built-in bias multiplies
-- by 0.2, so this is blended against that rather than replacing it, which
-- keeps the geography meaningful at every setting except OFTEN.
local EXOTIC = { off = 0, rare = 1.0, normal = 3.0, often = 7.0 }
function Settings.exoticScale()
  local v = EXOTIC[Settings.get("exotic")]
  if v == nil then return 3.0 end
  return v
end

-- 0 = no weather in battle, 1 = the same as the overworld.
local BATTLE = { off = 0, subtle = 0.5, full = 1 }
function Settings.battleScale()
  return BATTLE[Settings.get("battles")] or 0.5
end

return Settings
