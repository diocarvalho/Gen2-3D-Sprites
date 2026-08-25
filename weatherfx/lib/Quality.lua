-- HOW MUCH WEATHER THE MACHINE CAN AFFORD.
--
-- Two numbers decide everything expensive in this mod: how many particles
-- exist, and whether the costlier passes (the fog banks, the bolt
-- geometry) run at all.  Both come from here, so there is one place to
-- look when a phone drops frames and one place to change when it should
-- not have.
--
-- THE BUDGETS ARE CAPS, NOT COUNTS.  A tier says "at most this many
-- raindrops"; the weather says what fraction of the cap is falling right
-- now.  A light drizzle on a desktop and a downpour on a phone can be the
-- same 200 particles, and neither has to know about the other.
--
-- AUTO IS ADAPTIVE, AND ONLY AUTO IS.  A player who picked HIGH gets HIGH
-- even if it costs them frames -- that is what picking it means.  On AUTO
-- the governor watches a slow average of frame time and steps the tier
-- down when the frame is consistently late, back up when it is
-- consistently early, with a wide gap between the two thresholds and a
-- multi-second dwell so it settles instead of oscillating.  It measures
-- the WHOLE frame, not this mod's share of it, which is the right signal:
-- the question is not "is the weather expensive" but "can this frame
-- afford weather".
--
-- Android and iOS start at MEDIUM rather than HIGH.  A mobile GPU can
-- usually manage the high tier; a mobile GPU that also has Dramatic
-- Shape's diorama on it usually cannot, and starting low and climbing is
-- a better first impression than starting high and stuttering.

local V = ...
local Settings = V.require("Settings")
local Config = V.require("Config")

local Quality = {}

-- Caps per tier.  `rain` and `snow` are particle counts at full density;
-- `splash` is the transient pool; `fogLayers` is how many noise banks
-- scroll; `bolt` turns the drawn lightning channel (as opposed to the
-- screen flash) on and off.
Quality.TIERS = {
  high   = { rain = 900, snow = 700, grain = 700, splash = 140, fogLayers = 3, bolt = true },
  medium = { rain = 460, snow = 360, grain = 340, splash = 70,  fogLayers = 2, bolt = true },
  low    = { rain = 200, snow = 160, grain = 150, splash = 0,   fogLayers = 1, bolt = false },
}

Quality.ORDER = { "low", "medium", "high" }
local RANK = { low = 1, medium = 2, high = 3 }

-- ------- mobile-safe AUTO starting tier
--
-- The sandbox does not expose a trustworthy OS name.  Starting AUTO at HIGH
-- caused the first few seconds on phones/integrated GPUs to allocate and draw
-- the expensive particle tier before the governor could react.  Start MEDIUM
-- everywhere; fast hardware still climbs to HIGH after the normal dwell.
local function platformDefault()
  return "medium"
end

-- Live state of the governor.  `auto` is the tier AUTO has settled on;
-- `ema` is the smoothed frame time it settled on it from.
local auto = { tier = nil, ema = 1 / 60, hold = 0 }

local SLOW = 1 / 42      -- frames later than this are "the machine is struggling"
local FAST = 1 / 56      -- frames earlier than this are "there is headroom"
local DWELL = 3.0        -- seconds a verdict must hold before the tier moves

function Quality.update(dt)
  if not auto.tier then auto.tier = platformDefault() end
  dt = tonumber(dt) or 0
  -- A single huge dt is a load hitch, a window drag or a breakpoint, not a
  -- performance signal; clamp it out rather than let it demote the tier.
  if dt <= 0 or dt > 0.25 then return end
  -- ~1.5s time constant: slow enough to ignore a single late frame,
  -- quick enough to react before the player gives up on the mod.
  auto.ema = auto.ema + (dt - auto.ema) * math.min(1, dt / 1.5)

  local want = 0
  if auto.ema > SLOW then want = -1 elseif auto.ema < FAST then want = 1 end
  if want == 0 then
    auto.hold = 0
    return
  end
  auto.hold = auto.hold + dt
  if auto.hold < DWELL then return end
  auto.hold = 0
  local rank = RANK[auto.tier] or 3
  local next_ = math.max(1, math.min(#Quality.ORDER, rank + want))
  auto.tier = Quality.ORDER[next_]
end

-- The tier in force right now.
-- The tier in force.  config.lua wins over the mod-manager row when it
-- names one, because the file is the deliberate, per-playthrough setting
-- and the row is the convenient one; "auto" in the file means "let the
-- row decide", which is what makes the default config invisible.
function Quality.tier()
  local picked = Config.get().quality
  if picked == "auto" or picked == nil then picked = Settings.get("quality") end
  if picked ~= "auto" then return picked end
  if not auto.tier then auto.tier = platformDefault() end
  return auto.tier
end

-- The tier's caps, scaled by the config's per-weather `density` and
-- clamped by `maxParticles`.  Returned as a fresh table because the caller
-- may hold it for a frame and the tier table itself must stay pristine.
--
-- `density` scales the CAP rather than the drawn count, so turning it up
-- genuinely puts more drops in the sky rather than making the same drops
-- denser -- and turning it down frees the memory rather than hiding it.
local scaled = { rain = 0, snow = 0, grain = 0, splash = 0, fogLayers = 1, bolt = false }

function Quality.budget(density)
  local tier = Quality.TIERS[Quality.tier()] or Quality.TIERS.medium
  density = tonumber(density) or 1
  if density < 0 then density = 0 elseif density > 3 then density = 3 end
  local cap = Config.get().maxParticles
  local function one(v)
    v = math.floor(v * density + 0.5)
    if cap and v > cap then v = math.floor(cap) end
    return math.max(0, v)
  end
  scaled.rain, scaled.snow = one(tier.rain), one(tier.snow)
  scaled.grain, scaled.splash = one(tier.grain), one(tier.splash)
  scaled.fogLayers, scaled.bolt = tier.fogLayers, tier.bolt
  return scaled
end

-- Reset the governor -- on hot reload, and whenever the mod switches off,
-- so a session spent at OFF does not leave a stale verdict behind.
function Quality.reset()
  auto.tier = nil
  auto.ema = 1 / 60
  auto.hold = 0
end

-- For the debug readout.
function Quality.describe()
  local tier = Quality.tier()
  if Settings.get("quality") == "auto" then
    return ("AUTO/%s %.1ffps"):format(tier:upper(), 1 / math.max(auto.ema, 1e-6))
  end
  return tier:upper()
end

return Quality
