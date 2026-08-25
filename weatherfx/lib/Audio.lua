-- WEATHER AUDIO.
--
-- A looping bed per weather family, cross-faded when the weather turns,
-- with the volume following the eased channel so a storm swells as it
-- arrives rather than snapping on -- and a thunder one-shot fired from the
-- strike scheduler so the crack lands with the flash.
--
-- =====================================================================
-- WHAT IS AND IS NOT COVERED, STATED UP FRONT
-- =====================================================================
--
-- Four beds arrived for nineteen weathers.  Rain, heavy rain, primal rain,
-- thunderstorms and gales map onto them cleanly.  Snow, blizzards, hail,
-- sleet, sandstorm, ashfall, strong winds and fog have NO audio and are
-- deliberately SILENT rather than borrowed: rain played under a blizzard
-- is worse than quiet, because it tells the player something false about
-- what is on screen.  Adding one later is a row in `Audio.BEDS` and a file.
--
-- =====================================================================
-- WHY love.audio DIRECTLY
-- =====================================================================
--
-- The engine's audio registry is built around the game's own music and
-- cries -- tracks it owns, selected through `music.select` and mixed at
-- the engine's volume.  A weather bed is neither: it plays UNDER whatever
-- music is running, follows a channel value rather than a track change,
-- and has to duck and swell continuously.  Driving `love.audio` directly
-- keeps that entirely inside this mod, where it can be switched off
-- without touching anything the engine mixes.
--
-- The cost is that the engine's own volume slider does not reach it, so
-- this carries its own -- `WEATHER SFX` in the mod manager, OFF included.
--
-- =====================================================================
-- CROSS-FADE, NOT SWAP
-- =====================================================================
--
-- Two slots, never one.  A weather change fades the outgoing bed down
-- while the incoming one comes up, over the same seconds the visual
-- transition takes, so the ear and the eye agree about when the storm
-- arrived.  Swapping the source instead would produce a click and a
-- discontinuity exactly at the moment the player is looking up.

local V = ...
local mod = V.mod
local Types = V.require("Types")
local Config = V.require("Config")
local Settings = V.require("Settings")
local Scene = V.require("Scene")
local State = V.require("WeatherState")
local Lightning = V.require("Lightning")
local Legendary = V.require("Legendary")

local Audio = {}

Audio.DIR = "assets/sounds/"

-- Which bed a weather uses, and how loud at full channel.  `nil` means
-- silent, which is most of the catalogue and is a decision rather than a
-- gap -- see the header.
--
-- Chosen by the weather's own id so the mapping is readable, with a
-- channel-driven fallback for anything unlisted (a new rain type gets rain
-- without being named here).
Audio.BEDS = {
  RAIN_LIGHT  = { file = "rain",        gain = 0.55 },
  RAIN_HEAVY  = { file = "rain_heavy",  gain = 0.75 },
  HEAVY_RAIN  = { file = "heavy_storm", gain = 0.95 },
  STORM       = { file = "storm",       gain = 0.85 },
  GALE        = { file = "storm",       gain = 0.7 },
  SLEET       = { file = "rain",        gain = 0.4 },
}

Audio.THUNDER = { "thunder_clap", "thunder_roll" }

-- WIND IS ITS OWN LAYER, not another bed.
--
-- A bed is chosen -- a weather has one or it has none -- and the two slots
-- cross-fade between them.  Wind is not like that: a gale and a downpour
-- happen at once, and a blizzard is nothing BUT wind.  So it plays
-- alongside whatever bed is running, at a volume taken straight from the
-- `gust` channel, which means it swells and drops with the same oscillator
-- that leans the rain and drifts the snow.
--
-- This also gives most of the previously-silent weathers a voice without
-- misrepresenting them: a blizzard, a sandstorm, an ashfall and the strong
-- winds all carry gust, and wind is what they actually sound like.  Fog
-- has none and stays silent, which is correct -- fog is quiet.
Audio.WIND = { file = "wind", gain = 0.6 }

-- Which wind.  Grit blowing across a desert does not sound like wind
-- through trees, and a sandstorm that borrowed the ordinary loop would be
-- the same lie as a blizzard borrowing the rain.
--
-- Matched by capability tag rather than by id, so a new sandy weather --
-- ashfall already, and whatever comes next -- gets the right wind without
-- being named here.
function Audio.windFileFor(def)
  if def and def.sandy then return "wind_desert" end
  return Audio.WIND.file
end

-- A weather with no entry still gets rain if it is genuinely raining:
-- the id table is for tuning, not for gatekeeping.
local function bedFor(def)
  if not def then return nil end
  local named = Audio.BEDS[def.id]
  if named then return named end
  if Types.channel(def, "rain") >= 0.5 then
    return { file = "rain_heavy", gain = 0.6 }
  end
  if Types.channel(def, "rain") > 0 then
    return { file = "rain", gain = 0.45 }
  end
  return nil
end
Audio.bedFor = bedFor

-- ------- loading
--
-- Once per file, and never retried after a failure: a missing sound costs
-- one log line and silence, not a stutter every frame.

local cache, failed = {}, {}

-- ------- love.filesystem is sandboxed away from mods now
--
-- The updated engine hands mods a `love` facade that ERRORS on
-- `filesystem`, `thread`, `system` and `event` (src/mods/Sandbox.lua). It
-- errors on the INDEX, so the usual `love and love.filesystem` guard does not
-- protect anything -- reading the field is itself the throw. That is what
-- broke rendering: the first pipeline update raised, and a pipeline that
-- raises draws nothing.
--
-- `love.data.newByteData` is not blocked and produces something
-- `newSource`/`newImageData` accept just as happily as a FileData, so the
-- bytes still come from `mod:read` and only the wrapper changes.
local function byteData(bytes, name)
  if not (love and love.data and love.data.newByteData) then return nil end
  local ok, d = pcall(love.data.newByteData, bytes)
  if not ok or not d then return nil end
  -- The real newByteData takes bytes ONLY -- there is no name argument, where
  -- newFileData had one. Carried alongside because callers (and the suite's
  -- audio stub) identify a sound by it.
  pcall(function() d.name = name end)
  return d
end

local function sourceFor(name, kind)
  local key = name .. "/" .. kind
  if cache[key] then return cache[key] end
  if failed[key] then return nil end
  if not (love and love.audio) then return nil end
  local ok, src = pcall(function()
    -- Both extensions are tried rather than inferred from the name.  The
    -- rule used to be "thunder is mp3, everything else is ogg", which was
    -- true of the four files that existed when it was written and wrong
    -- the moment a fifth arrived in a different format.  A miss costs one
    -- extra read, once, since the result is cached either way.
    local data, ext
    for _, try in ipairs({ ".ogg", ".mp3" }) do
      data = mod:read(Audio.DIR .. name .. try)
      if data then ext = try break end
    end
    if not data then return nil end
    local fileData = byteData(data, name .. ext)
    if not fileData then return nil end
    return love.audio.newSource(fileData, kind)
  end)
  if not ok or not src then
    failed[key] = true
    mod.log:warn("weather sound %s could not be loaded", name)
    return nil
  end
  cache[key] = src
  return src
end

function Audio.invalidate()
  for _, src in pairs(cache) do pcall(function() src:stop() end) end
  cache, failed = {}, {}
  Audio.slots = { {}, {} }
  Audio.wind = { level = 0, file = nil }
end

-- ------- the two bed slots

Audio.slots = { {}, {} }     -- { file, src, level, target }
Audio.wind = { level = 0, file = nil }   -- plays over any bed
Audio.lastStrike = -1

local function slotFor(file)
  for i = 1, 2 do
    if Audio.slots[i].file == file then return Audio.slots[i] end
  end
  return nil
end

local function freeSlot()
  local quietest, best = nil, 2
  for i = 1, 2 do
    local s = Audio.slots[i]
    if not s.file then return s end
    if (s.level or 0) < best then quietest, best = s, s.level or 0 end
  end
  return quietest
end

-- ------- volume
--
-- Two multipliers on top of the bed's own gain, both continuous so
-- nothing steps: how much of the weather is actually falling, and where
-- the player is.

local function contextGain()
  if Scene.now.visible == "hidden" then return 0 end
  local cfg = Config.get().audio
  if Scene.now.visible == "battle" then
    return tonumber(cfg.battle) or 0.35
  end
  if Scene.now.indoors then
    -- muffled through a wall, not silent: hearing the storm you walked in
    -- out of is most of the point
    return tonumber(cfg.indoors) or 0.3
  end
  return 1
end

function Audio.masterGain()
  if Settings.is("sfx", "off") then return 0 end
  local cfg = Config.get().audio
  if not cfg.enabled then return 0 end
  local named = { low = 0.4, medium = 0.7, high = 1.0 }
  local row = named[Settings.get("sfx")] or 1.0
  return row * (tonumber(cfg.volume) or 1) * contextGain()
end

-- ------- the tick

function Audio.update(dt)
  if not (love and love.audio) then return end
  dt = tonumber(dt) or 0
  if dt <= 0 or dt > 0.25 then dt = 1 / 60 end

  local master = Audio.masterGain()
  local off = (State.level or 0) <= 0

  -- what should be playing
  local wantFile, wantGain = nil, 0
  if not off and master > 0 then
    local bed = bedFor(State.current())
    if bed then
      -- the eased channel, so the bed swells with the visible weather
      local amount = math.min(1, State.channel("rain"))
      if amount <= 0.02 then amount = 0 end
      wantFile = amount > 0 and bed.file or nil
      wantGain = bed.gain * amount
    end
  end

  if wantFile and not slotFor(wantFile) then
    local slot = freeSlot()
    if slot then
      slot.file, slot.level = wantFile, slot.level or 0
      slot.src = sourceFor(wantFile, "stream")
      if slot.src then
        pcall(function()
          slot.src:setLooping(true)
          slot.src:setVolume(0)
          slot.src:play()
        end)
      else
        slot.file = nil
      end
    end
  end

  -- cross-fade both slots toward their targets
  local seconds = math.max(0.2, tonumber(Config.get().audio.fadeSeconds) or 2.5)
  for i = 1, 2 do
    local slot = Audio.slots[i]
    if slot.file then
      local target = (slot.file == wantFile) and wantGain or 0
      local step = dt / seconds
      if slot.level < target then
        slot.level = math.min(target, slot.level + step)
      elseif slot.level > target then
        slot.level = math.max(target, slot.level - step)
      end
      if slot.src then
        pcall(function() slot.src:setVolume(slot.level * master) end)
      end
      if slot.level <= 0 and target <= 0 then
        if slot.src then pcall(function() slot.src:stop() end) end
        slot.file, slot.src = nil, nil
      end
    end
  end

  -- ------- wind, over whatever bed is playing
  do
    local want, wantFile = 0, nil
    if not off and master > 0 and Config.get().audio.wind ~= false then
      -- straight from the eased channel, so it breathes with the same
      -- oscillator that leans the rain
      want = math.min(1, State.channel("gust")) * Audio.WIND.gain
      wantFile = Audio.windFileFor(State.current())
    end
    local w = Audio.wind

    -- A CHANGE OF WIND fades out before it fades in, rather than swapping
    -- the source underneath.  Swapping would click; cross-fading would
    -- need a second wind slot for a transition that already takes three
    -- seconds of visible weather anyway.  The dip is the storm turning
    -- over, which is what is happening.
    if w.src and w.file and wantFile and w.file ~= wantFile then
      want = 0
      if w.level <= 0 then
        pcall(function() w.src:stop() end)
        w.src, w.file = nil, nil
      end
    end

    if want > 0 and not w.src and wantFile then
      w.file = wantFile
      w.src = sourceFor(wantFile, "stream")
      if w.src then
        pcall(function()
          w.src:setLooping(true)
          w.src:setVolume(0)
          w.src:play()
        end)
      end
    end
    local step = dt / seconds
    if w.level < want then w.level = math.min(want, w.level + step)
    elseif w.level > want then w.level = math.max(want, w.level - step) end
    if w.src then
      pcall(function() w.src:setVolume(w.level * master) end)
      if w.level <= 0 and want <= 0 then
        pcall(function() w.src:stop() end)
        w.src, w.file = nil, nil
      end
    end
  end

  -- ------- thunder, fired from the strike the player is watching
  --
  -- Lightning.age resets to 0 on each strike, so a fall in age IS a new
  -- strike.  Reading the same value the flash is drawn from is what keeps
  -- the crack and the flash together; a separate timer would drift.
  local age = Lightning.age or -1
  if not off and master > 0 and Config.get().audio.thunder then
    if age >= 0 and (Audio.lastStrike < 0 or age < Audio.lastStrike) then
      -- A roused bird brings its own crack; everything else takes one of
      -- the ordinary pair at random.
      local pick = Legendary.thunderSound()
      if not pick then
        local names = Audio.THUNDER
        pick = names[(love.math and love.math.random or math.random)(#names)]
      end
      local src = sourceFor(pick, "static")
      if src then
        pcall(function()
          src:stop()
          src:setVolume(math.min(1, master * (tonumber(Config.get().audio.thunderGain) or 0.8)))
          src:play()
        end)
      end
    end
  end
  Audio.lastStrike = age
end

function Audio.describe()
  local playing = {}
  for i = 1, 2 do
    local s = Audio.slots[i]
    if s.file and (s.level or 0) > 0.01 then
      playing[#playing + 1] = ("%s%.0f%%"):format(s.file, s.level * 100)
    end
  end
  if (Audio.wind.level or 0) > 0.01 then
    playing[#playing + 1] = ("%s%.0f%%"):format(
      Audio.wind.file or "wind", Audio.wind.level * 100)
  end
  if #playing == 0 then return "-" end
  return table.concat(playing, "+")
end

return Audio
