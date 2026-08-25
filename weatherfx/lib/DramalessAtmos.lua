-- DramalessAtmos
--
-- Full Kanto-style atmosphere (clouds, light shafts, rain, fog, motes,
-- puddles, distant horizon) running inside Weather FX only.
-- Multi-host 3D atmosphere bridge. First-class hosts (all must keep working):
--   DRAMALESS_SHAPE, potato_voxel / POTATO_VOXEL, STADIUM2_OVERWORLD_MODELS
-- (Gen2-3D-Sprites). Other mods are never edited on disk;
-- we only read their exports.lib and wrap Voxel3D.endScene in memory.
--
-- Missing Dramatic Shape modules are supplied as stubs under
-- lib/voxel_atmos/stubs/. Features that need host data (e.g. sprite
-- reflections in puddles) degrade gracefully.

local V = ...
local mod = V.mod

local Atmos = {
  _ready = false,
  _active = false,
  _drawing = false,
  _reason = "not-initialised",
  _hostId = nil,
  _Voxel3D = nil,
  _origEndScene = nil,
  _cin = nil,
  _distant = nil,
  _horizon = nil,
  _forest = nil,
  _lastMap = nil,
  _lastOutdoor = true,
  _lastNeighbors = nil,
  _lastPosed = nil,
}

local HOSTS = {
  "DRAMALESS_SHAPE",
  "potato_voxel", "POTATO_VOXEL", "PotatoVoxel",
  -- Gold/Silver Stadium 2 overworld (Gen2-3D-Sprites). Same exports.lib
  -- convention as Dramaless; host-specific only via mod.find id.
  "STADIUM2_OVERWORLD_MODELS",
}

local WX_TO_KANTO = {
  -- Clear / sun family
  CLEAR = "clear", SUNNY = "clear", HEATWAVE = "clear", HARSH_SUN = "clear",
  -- Rain / storm → closed deck + 3D rain (2D rain suppressed when 3D draws it)
  RAIN_LIGHT = "rain", RAIN_HEAVY = "rain", HEAVY_RAIN = "rain",
  VERDANT_RAIN = "rain", SLEET = "rain",
  STORM = "thunderstorm", THUNDERSNOW = "thunderstorm", DRAGONSTORM = "thunderstorm",
  -- Cold precip: dense overcast 3D clouds/fog; 2D keeps snow/hail particles
  SNOW_LIGHT = "overcast", BLIZZARD = "overcast", HAIL = "overcast",
  -- Dust / ash / wind: broken cloud + fog volumes; 2D keeps sand/ash grains
  SANDSTORM = "cloudy", DUSTSTORM = "cloudy", ASHFALL = "cloudy",
  STRONG_WINDS = "mostly", GALE = "mostly", BRAWL_WIND = "mostly",
  FLOCKSTORM = "mostly",
  -- Fog / mist: high fog volumes in 3D; 2D fog layers still allowed
  FOG = "overcast", MIST = "cloudy", HAUNTED_MIST = "cloudy", SMOG = "cloudy",
  -- Typed fronts / oddities
  PLAIN_FRONT = "partly", SWARM = "partly", PSYSTORM = "cloudy",
}

local function findHost()
  if not (mod and mod.find) then return nil, nil end
  for i = 1, #HOSTS do
    local ok, host = pcall(mod.find, mod, HOSTS[i])
    if ok and host then return host, HOSTS[i] end
  end
  return nil, nil
end


local function attachNightSkyHost(NightSky)
  if not (NightSky and Atmos._hostLib) then return end
  -- Once resolved, keep refs (host modules are stable for the session).
  if NightSky._DayNight and NightSky._FirstPerson and NightSky._Voxel then return end
  local hostLib = Atmos._hostLib
  pcall(function()
    if not NightSky._DayNight then
      local ok, DN = pcall(hostLib.require, "DayNight")
      if ok then NightSky._DayNight = DN end
    end
    if not NightSky._FirstPerson then
      local ok2, FP = pcall(hostLib.require, "FirstPerson")
      if ok2 then NightSky._FirstPerson = FP end
    end
    if not NightSky._Voxel then
      local ok3, Voxel = pcall(hostLib.require, "Voxel")
      if not ok3 or not Voxel then
        ok3, Voxel = pcall(hostLib.require, "VoxelState")
      end
      if ok3 and Voxel then NightSky._Voxel = Voxel end
    end
  end)
end

local function want3d()
  local ok, Settings = pcall(V.require, "Settings")
  if ok and Settings then
    if Settings.force2dPresent and Settings.force2dPresent() then return false end
    if Settings.allow3dPresent and not Settings.allow3dPresent() then return false end
  end
  -- v0.4.16: finding the Stadium2 host only proves the renderer EXISTS. It
  -- does not mean the player currently selected the voxel overworld. When the
  -- host master switch is OFF, Weather FX must keep its normal 2D rain/fog/
  -- particles instead of suppressing them because a dormant Voxel3D module is
  -- still installed in memory.
  if Atmos._hostId == "STADIUM2_OVERWORLD_MODELS" and Atmos._hostLib
      and type(Atmos._hostLib.world3DEnabled) == "function" then
    local okHost, enabled = pcall(Atmos._hostLib.world3DEnabled)
    if okHost and enabled ~= true then return false end
  end
  return true
end

local function chunkFor(rel)
  local source = mod:read(rel)
  if not source then error("missing " .. rel, 0) end
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  if not chunk then error(rel .. " compile: " .. tostring(err), 0) end
  return chunk
end

-- Build a require namespace: host modules first, then Weather FX voxel_atmos
-- and stubs. Never writes into the host mod.
local function buildNamespace(hostLib)
  local own = {}
  local W = { path = mod.path, mod = mod }

  local STUBS = {
    ForestAtmos = "lib/voxel_atmos/stubs/ForestAtmos.lua",
    Mat4 = "lib/voxel_atmos/stubs/Mat4.lua",
    TileShape = "lib/voxel_atmos/stubs/TileShape.lua",
    SpriteBillboards = "lib/voxel_atmos/stubs/SpriteBillboards.lua",
    TerrainAtlas = "lib/voxel_atmos/stubs/TerrainAtlas.lua",
  }

  local OWN = {
    CinematicAtmos = "lib/voxel_atmos/CinematicAtmos.lua",
    DistantWorld = "lib/voxel_atmos/DistantWorld.lua",
    HorizonApron = "lib/voxel_atmos/HorizonApron.lua",
    WeatherSetting = "lib/voxel_atmos/WeatherSetting.lua",
  }

  function W.require(name)
    if own[name] ~= nil then
      if own[name] == false then error("circular require " .. name, 0) end
      return own[name]
    end
    own[name] = false

    if OWN[name] then
      local value = chunkFor(OWN[name])(W)
      if value == nil then error(name .. " returned nil", 0) end
      own[name] = value
      return value
    end

    -- Prefer host module when present
    if hostLib and hostLib.require then
      local ok, value = pcall(hostLib.require, name)
      if ok and value ~= nil then
        own[name] = value
        return value
      end
    end

    if STUBS[name] then
      local value = chunkFor(STUBS[name])(W)
      if value == nil then error(name .. " stub returned nil", 0) end
      own[name] = value
      return value
    end

    error("DramalessAtmos: cannot resolve " .. tostring(name), 0)
  end

  W.data = hostLib and hostLib.data
  return W
end

local function drawInScene()
  if not Atmos._drawing or not want3d() then return end
  local cin = Atmos._cin
  local Voxel3D = Atmos._Voxel3D
  if not (cin and Voxel3D and Voxel3D.vp) then return end

  -- Animation clock is advanced in Atmos.update(dt). Do not call
  -- ForestAtmos.update(0) here — that was a no-op that invited TOD snaps.

  -- Align light-shaft shear with the host sun/moon *this frame*.
  -- Cache DayNight/ShadowMap on Atmos so we never hostLib.require per frame.
  pcall(function()
    if not Atmos._DayNight or not Atmos._ShadowMap then
      local hostLib = Atmos._hostLib
      if not hostLib then return end
      if not Atmos._DayNight then
        local ok, DN = pcall(hostLib.require, "DayNight")
        if ok then Atmos._DayNight = DN end
      end
      if not Atmos._ShadowMap then
        local ok, SM = pcall(hostLib.require, "ShadowMap")
        if ok then Atmos._ShadowMap = SM end
      end
    end
    local DayNight, ShadowMap = Atmos._DayNight, Atmos._ShadowMap
    if not (DayNight and DayNight.shearAt and ShadowMap) then return end
    local tt = DayNight.time and DayNight.time() or 0
    local kx, kz = DayNight.shearAt(tt)
    if type(kx) == "number" and type(kz) == "number" then
      ShadowMap.KX, ShadowMap.KZ = kx, kz
    end
  end)

  local map = Atmos._lastMap
  local outdoor = Atmos._lastOutdoor
  if outdoor == nil then outdoor = true end

  local prevBlend, prevAlpha
  pcall(function()
    prevBlend, prevAlpha = love.graphics.getBlendMode()
  end)
  local pr, pg, pb, pa
  pcall(function() pr, pg, pb, pa = love.graphics.getColor() end)

  -- Stars first: celestial sphere through Voxel3D.vp; math fallback if needed.
  pcall(function()
    if not Atmos._NightSky then
      Atmos._NightSky = V.require("NightSky")
    end
    local NightSky = Atmos._NightSky
    if not NightSky then return end
    attachNightSkyHost(NightSky)
    local tt = (Atmos._forest and Atmos._forest.time) or 0
    local ok = false
    if NightSky.drawWorld then
      ok = NightSky.drawWorld(Voxel3D, tt) and true or false
    end
    if not ok and NightSky.draw then
      pcall(function()
        local w, h = love.graphics.getDimensions()
        if Voxel3D and Voxel3D.canvas then
          local o, cw, ch = pcall(function()
            return Voxel3D.canvas:getWidth(), Voxel3D.canvas:getHeight()
          end)
          if o and cw then w, h = cw, ch end
        end
        pcall(love.graphics.push)
        pcall(love.graphics.origin)
        pcall(love.graphics.setDepthMode, "always", false)
        NightSky.draw(w, h, h * 0.7, nil, tt)
        pcall(love.graphics.setDepthMode, "lequal", true)
        pcall(love.graphics.pop)
      end)
    end
  end)

  local ok, err = pcall(function()
    if cin.draw then
      cin.draw(map, outdoor, Atmos._lastNeighbors, Atmos._lastPosed)
    end
  end)
  if not ok then
    Atmos._lastDrawError = tostring(err)
  else
    Atmos._lastDrawError = nil
  end

  pcall(love.graphics.setShader)
  if prevBlend then pcall(love.graphics.setBlendMode, prevBlend, prevAlpha) end
  if pr then pcall(love.graphics.setColor, pr, pg, pb, pa) end
  pcall(love.graphics.setDepthMode, "lequal", true)
end

function Atmos.install()
  if Atmos._ready and Atmos._active then return true end
  Atmos._ready = true
  Atmos._active = false
  Atmos._drawing = false

  local host, hostId = findHost()
  if not host then
    Atmos._reason = "no-3d-voxel-host"
    return false
  end
  Atmos._hostId = hostId
  if not (host.exports and host.exports.lib) then
    Atmos._reason = "host-missing-exports-lib"
    return false
  end

  local hostLib = host.exports.lib
  Atmos._hostLib = hostLib
  local W = buildNamespace(hostLib)

  local okV, Voxel3D = pcall(function() return W.require("Voxel3D") end)
  if not okV or not Voxel3D or not Voxel3D.endScene then
    Atmos._reason = "Voxel3D-unavailable"
    return false
  end
  Atmos._Voxel3D = Voxel3D

  -- CinematicAtmos draws through beginEffect/endEffect (Dramatic Shape API).
  -- Dramaless does not define them; install safe in-memory polyfills so
  -- clouds/rays/rain can bind shaders without editing the host mod on disk.
  if type(Voxel3D.beginEffect) ~= "function" then
    function Voxel3D.beginEffect(shader)
      if not Voxel3D.vp then return false end
      if shader then
        local ok = pcall(love.graphics.setShader, shader)
        if not ok then return false end
      end
      -- Keep depth test; do not write depth for translucent volumes.
      pcall(love.graphics.setDepthMode, "lequal", false)
      return true
    end
  end
  if type(Voxel3D.endEffect) ~= "function" then
    function Voxel3D.endEffect()
      pcall(love.graphics.setShader)
      pcall(love.graphics.setDepthMode, "lequal", true)
    end
  end
  -- Optional fields some Kanto draws read; never crash if absent.
  if Voxel3D.focus == nil then Voxel3D.focus = { 0, 0, 0 } end
  if Voxel3D.eye == nil then Voxel3D.eye = { 0, 40, 0 } end

  local okF, forest = pcall(function() return W.require("ForestAtmos") end)
  if okF then Atmos._forest = forest end

  local okC, cin = pcall(function() return W.require("CinematicAtmos") end)
  if not okC or not cin then
    Atmos._reason = "CinematicAtmos-load-failed: " .. tostring(cin)
    return false
  end
  Atmos._cin = cin

  pcall(function() Atmos._distant = W.require("DistantWorld") end)
  pcall(function() Atmos._horizon = W.require("HorizonApron") end)

  -- Night stars/planets + greyer rain sky via one Sky.paint wrap (host only).
  if not Atmos._skyWrapped then
    local okSky, Sky = pcall(function() return hostLib.require("Sky") end)
    if okSky and Sky and type(Sky.paint) == "function" then
      local NightSky
      pcall(function()
        local src = mod:read("lib/NightSky.lua")
        if not src then return end
        NightSky = assert((loadstring or load)(src, "@NightSky"))(V)
      end)
      local origPaint = Sky.paint
      -- Gen2 Sky.paint may pass extra args (top, axis, ray); always forward them.
      function Sky.paint(w, h, sky, horizonY, cell, body, ...)
        local skyArg = sky
        if NightSky and sky and sky.bands and Atmos._cin and Atmos._cin.skyWeather then
          local ok, info = pcall(Atmos._cin.skyWeather)
          if ok and info then
            local copy = {}
            for k, v in pairs(sky) do copy[k] = v end
            copy.bands = NightSky.applyWeatherBands(sky.bands, info)
            skyArg = copy
          end
        end
        local result = origPaint(w, h, skyArg, horizonY, cell, body, ...)
        attachNightSkyHost(NightSky)
        local showStars = NightSky and NightSky.isNight and NightSky.isNight(body)
        if NightSky and showStars then
          local edge
          pcall(function() edge = Sky.region(h, horizonY) end)
          local t = (Atmos._forest and Atmos._forest.time) or 0
          pcall(NightSky.draw, w, h, edge or (h * 0.42), body, t)
        end
        return result
      end
      Atmos._skyWrapped = true
    end
  end

  -- Capture scene context from VoxelScene.render by wrapping it when available
  local okS, VoxelScene = pcall(function() return hostLib.require("VoxelScene") end)
  if okS and VoxelScene and VoxelScene.render and not Atmos._wrappedScene then
    local orig = VoxelScene.render
    VoxelScene.render = function(state, w, h, vw, vh, paletteFor)
      if state then
        Atmos._lastMap = state.map
        Atmos._lastNeighbors = state.neighbors
        Atmos._lastPosed = state.posed
        -- Prefer Weather FX Scene outdoor flag; fall back to outdoor=true for
        -- voxel overworld (host only renders outdoor maps in practice).
        local outdoor = true
        pcall(function()
          local Scene = V.require("Scene")
          if Scene and Scene.now and Scene.now.outdoor ~= nil then
            outdoor = Scene.now.outdoor and true or false
            -- Canopy maps still get atmosphere (Kanto behaviour).
            if outdoor == false and Scene.now.mapId then
              local DN = hostLib.require("DayNight")
              if DN and DN.isCanopy and state.map and DN.isCanopy(state.map) then
                outdoor = true
              end
            end
          end
        end)
        Atmos._lastOutdoor = outdoor
      end
      return orig(state, w, h, vw, vh, paletteFor)
    end
    Atmos._wrappedScene = true
  end

  if not Atmos._origEndScene then
    Atmos._origEndScene = Voxel3D.endScene
    function Voxel3D.endScene()
      if Atmos._drawing and want3d() then
        pcall(drawInScene)
      end
      return Atmos._origEndScene()
    end
  end

  Atmos._active = true
  Atmos._drawing = true
  Atmos._reason = "full-atmos:" .. tostring(hostId)
  return true
end

function Atmos.active()
  return Atmos._active and Atmos._drawing
end

function Atmos.reason()
  if Atmos._lastDrawError then
    return tostring(Atmos._reason) .. "|err:" .. tostring(Atmos._lastDrawError):sub(1, 40)
  end
  return Atmos._reason
end

function Atmos.handlesPrecipitation()
  if not want3d() or not Atmos.active() then return false end
  -- 3D only draws rain *streaks* for the rain/storm family. Snow, hail, sand
  -- and ash keep Weather FX 2D particles so every weather has both layers:
  -- 3D clouds/fog/rays + 2D precip grains where CinematicAtmos has no streak.
  local id = tostring(Atmos._wxId or ""):upper()
  if id:find("RAIN", 1, true) or id == "STORM" or id == "SLEET"
      or id == "VERDANT_RAIN" or id == "THUNDERSNOW" or id == "DRAGONSTORM" then
    return true
  end
  return false
end

function Atmos.handlesFog()
  if not want3d() or not Atmos.active() then return false end
  local id = tostring(Atmos._wxId or ""):upper()
  -- Fog family: 3D mist volumes replace 2D fog so it does not double up.
  if id == "FOG" or id == "MIST" or id == "HAUNTED_MIST" or id == "SMOG" then
    return true
  end
  -- Closed-deck rain/storm: 3D fog bed is the primary look.
  if id:find("RAIN", 1, true) or id == "STORM" or id == "SLEET"
      or id == "THUNDERSNOW" or id == "DRAGONSTORM" or id == "VERDANT_RAIN" then
    return true
  end
  -- Snow, sand, ash, wind, clear: keep 2D fog/tint layers alongside 3D clouds.
  return false
end

function Atmos.syncFromWeatherFx(state, settings, level)
  if not Atmos.active() or not Atmos._cin then return end
  local cin = Atmos._cin
  level = tonumber(level) or tonumber(state and state.level) or 0

  -- Weather FX is the authority. When its row is OFF, the embedded 3D host
  -- must also stand down; otherwise the last cloud/rain preset remains visible
  -- even though the 2D channels were correctly zeroed.
  if cin.atmosphereSetting and cin.atmosphereSetting.setValue then
    if level <= 0 then
      pcall(function() cin.atmosphereSetting:setValue("off") end)
    else
      local q = settings and settings.get and settings.get("quality") or "auto"
      local atmos = (q == "low" or q == "medium") and "low" or "full"
      pcall(function() cin.atmosphereSetting:setValue(atmos) end)
    end
  end

  if cin.weatherSpeedSetting and cin.weatherSpeedSetting.setValue then
    local sp = settings and settings.get and settings.get("speed") or "normal"
    local mapped = ({ slow="slow", normal="normal", fast="fast", test="very_fast" })[sp] or "normal"
    pcall(function() cin.weatherSpeedSetting:setValue(mapped) end)
  end

  local intensity = settings and settings.intensity and settings.intensity() or 1
  if settings and settings.get and settings.get("intensity") == "auto" then
    -- AUTO still breathes the 2D/eased channels independently. Keep the 3D
    -- volumes at neutral strength instead of making the whole sky pulse.
    intensity = 1
  end
  cin.wxIntensityScale = math.max(0.35, math.min(1.55, tonumber(intensity) or 1))

  local lm = settings and settings.get and settings.get("lightning") or "full"
  cin.wxLightningScale = (lm == "off" and 0) or (lm == "soft" and 0.32) or 1

  local weatherId = state and state.id
  if type(weatherId) == "table" then
    weatherId = weatherId.id or weatherId.name
  end
  if level <= 0 then weatherId = "CLEAR" end
  weatherId = tostring(weatherId or ""):upper()
  Atmos._wxId = weatherId
  local kanto = WX_TO_KANTO[weatherId] or "partly"
  if cin.weatherSetting and cin.weatherSetting.setValue then
    pcall(function() cin.weatherSetting:setValue(kanto) end)
  end
  if cin.notifyWxWeather then
    pcall(cin.notifyWxWeather, weatherId)
  end
end

function Atmos.update(dt)
  if not Atmos._ready then Atmos.install() end
  if not Atmos.active() then
    if not Atmos._ready then return end
    -- retry install occasionally if host appeared late
    if not Atmos._active then pcall(Atmos.install) end
    return
  end
  -- Keep outdoor flag in sync with Weather FX Scene when available.
  pcall(function()
    local Scene = V.require("Scene")
    if Scene and Scene.now and Scene.now.outdoor ~= nil then
      local outdoor = Scene.now.outdoor and true or false
      if outdoor == false and Atmos._lastMap then
        -- leave previous canopy override if any; Scene is authoritative for indoors
      end
      Atmos._lastOutdoor = outdoor
    end
  end)
  local step = tonumber(dt) or 0
  if step < 0 then step = 0 end
  if step > 0.25 then step = 0.25 end  -- avoid hitch-induced lattice jumps
  if Atmos._forest and Atmos._forest.update then
    pcall(Atmos._forest.update, step)
  end
  if Atmos._cin and Atmos._cin.update then
    pcall(Atmos._cin.update, step)
  end
end

function Atmos.invalidate()
  if Atmos._cin and Atmos._cin.invalidate then
    pcall(Atmos._cin.invalidate)
  end
end

return Atmos
