-- Gold/Silver voxel renderer provider for the official render.compose hook.
--
-- Gold does not run Gen-1 drawWorld pipelines.  This module therefore owns no
-- engine method and registers no pipeline.  It only prepares the embedded
-- Dramatic Shapes renderer and exposes renderFrame(world, ctx); GoldComposeBridge
-- calls that from the engine's supported whole-window compose seam.
local mod = ...

local Bridge = {
  installed = false,
  active = false,
  lastError = nil,
  framesAttempted = 0,
  frames3d = 0,
  framesPending = 0,
  framesFailed = 0,
  mapId = nil,
  extraEntitiesProvider = nil,
  extraEntitiesMerged = 0,
  syncBuildMapId = nil,
  syncBuilds = 0,
  syncBuildFailures = 0,
  meshPendingFrames = 0,
  cameraMode = "diorama",
  cameraLevel = 1,
  cameraHotkeyCycles = 0,
  cameraHotkeyPollCycles = 0,
  f6Down = false,
  cameraSliderInstalled = false,
  cameraSliderTouches = 0,
  cameraSliderChanges = 0,
  cameraInputInstalled = false,
  cameraInputError = nil,
  pinchZoomInstalled = false,
  pinchZoomError = nil,
  cameraMovementInstalled = false,
  cameraMovementError = nil,
  cameraOverride = nil,
  cameraProvider = "stadium",
  externalCameraLevel = nil,
  externalCameraLabel = nil,
  selectorDetected = false,
  game = nil,
  lastTickTime = nil,
}

-- Minimal Dramatic-Shape module namespace.  Deliberately does not execute the
-- Gen-1 pipeline/input installer from the original Dramaless package.
local V = { mod = mod, path = mod.path }
local modules, dataFiles = {}, {}

local function chunkFor(rel)
  local source, readErr = mod:read(rel)
  if type(source) ~= "string" then
    error(("STADIUM2_OVERWORLD_MODELS: missing %s: %s")
      :format(rel, tostring(readErr)), 0)
  end
  if source:sub(1, 3) == "\239\187\191" then source = source:sub(4) end
  local loadcode = loadstring or load
  local chunk, err = loadcode(source, "@" .. mod.path .. "/" .. rel)
  if not chunk then
    error(("STADIUM2_OVERWORLD_MODELS: %s did not compile: %s")
      :format(rel, tostring(err)), 0)
  end
  return chunk
end

function V.require(name)
  local hit = modules[name]
  if hit ~= nil then return hit end
  local value = chunkFor("lib/" .. name .. ".lua")(V)
  modules[name] = value
  return value
end

function V.data(name)
  local hit = dataFiles[name]
  if hit ~= nil then return hit end
  local value = chunkFor("data/" .. name .. ".lua")(V)
  dataFiles[name] = value
  return value
end

Bridge.lib = V

local Voxel, Voxel3D, VoxelScene, ChunkMesher, FirstPerson, CamControl, GoldCameraControls
local OverworldBattle, OverworldCapture, GoldColorAtlas
local GoldMap = nil
local neighborMapCache = {}
local logOnce

local function optionEnabled()
  local ok, value = pcall(mod.options.get, mod.options, "voxel3d")
  if not ok or value == nil then return true end
  return not (value == false or value == 0 or value == "0"
    or value == "false" or value == "off")
end

local CAMERA_ORDER = { "diorama", "third", "first" }
local CAMERA_NEXT = { diorama = "third", third = "first", first = "diorama" }

local function platformName()
  if love and love.system and type(love.system.getOS) == "function" then
    local ok, osName = pcall(love.system.getOS)
    if ok and type(osName) == "string" then return osName end
  end
  return "Unknown"
end

local function isAndroid()
  return platformName():lower() == "android"
end

Bridge.isAndroid = isAndroid

local function normalizeCameraMode(value)
  value = type(value) == "string" and value:lower() or value
  if value == "third" or value == "third_person" or value == "3rd" then
    return "third"
  elseif value == "first" or value == "first_person" or value == "1st" then
    return "first"
  end
  return "diorama"
end

local function optionCameraControl()
  local ok, value = pcall(mod.options.get, mod.options, "cameraControl")
  value = ok and type(value) == "string" and value:lower() or "auto"
  if value == "stadium" or value == "selector" then return value end
  return "auto"
end

local function selectorDetected()
  if not (mod and type(mod.find) == "function") then return false end
  local ok, selector = pcall(mod.find, "red_3d_player")
  return ok and selector ~= nil
end

local function externalCameraEnabled()
  local control = optionCameraControl()
  if control == "stadium" then return false end
  local detected = selectorDetected()
  Bridge.selectorDetected = detected
  if control == "selector" then return detected end
  return detected
end

-- 3D Character Selector v3.x changes the engine's public `voxel` pipeline
-- level to select its ZOOM / 1ST / 3RD modes.  This standalone Gold renderer
-- has its own private VoxelState, so without this bridge it would overwrite
-- that choice every frame.  Read the public pipeline label instead of hard-
-- coding rung numbers: upstream voxel mods are free to move the 1ST/3RD rungs.
local function selectorCameraMode()
  if not externalCameraEnabled() then return nil end
  local ok, Pipelines = pcall(require, "src.render.Pipelines")
  if not ok or type(Pipelines) ~= "table" then return nil end
  if type(Pipelines.get) == "function" and not Pipelines.get("voxel") then
    return nil
  end
  if type(Pipelines.level) ~= "function" then return nil end
  local level = Pipelines.level("voxel")
  local label = type(Pipelines.levelLabel) == "function"
    and Pipelines.levelLabel("voxel", level) or tostring(level)
  local upper = tostring(label or ""):upper()
  local mode
  if upper:find("3RD", 1, true) or upper:find("THIRD", 1, true) then
    mode = "third"
  elseif upper:find("1ST", 1, true) or upper:find("FIRST", 1, true) then
    mode = "first"
  else
    -- Character Selector's ordinary ZOOM/orbit state maps to this mod's
    -- diorama camera.  The voxel world remains enabled even if the external
    -- pipeline reports OFF for a transient frame during a mode change.
    mode = "diorama"
  end
  Bridge.externalCameraLevel = level
  Bridge.externalCameraLabel = label
  Bridge.cameraProvider = "red_3d_player"
  return mode
end

-- Shared with FirstPerson/GoldCameraControls.  They still mirror camera input
-- for this renderer, but must pass it through and must not rewrite movement
-- while the Character Selector owns the public camera state.
V.externalCameraOwner = externalCameraEnabled
V.externalCameraPassthrough = externalCameraEnabled

local function optionCameraMode()
  local control = optionCameraControl()
  -- An explicit in-world slider/F6 choice must not be undone one frame later
  -- by AUTO observing red_3d_player's previous public pipeline rung.  Keep the
  -- user's live choice authoritative in AUTO/STADIUM mode.  Choosing CAMERA
  -- CONTROL = CHARACTER SELECTOR explicitly hands ownership back and ignores
  -- this latch, so the compatibility path remains available on demand.
  if control ~= "selector" and Bridge.cameraOverride then
    Bridge.cameraProvider = "stadium-user"
    return normalizeCameraMode(Bridge.cameraOverride)
  end
  local external = selectorCameraMode()
  if external then return external end
  Bridge.cameraProvider = "stadium"
  Bridge.externalCameraLevel = nil
  Bridge.externalCameraLabel = nil
  local ok, value = pcall(mod.options.get, mod.options, "cameraMode")
  if not ok then return "diorama" end
  return normalizeCameraMode(value)
end

local function cameraLevelForMode(mode)
  mode = normalizeCameraMode(mode)
  if mode == "third" then return (Voxel and Voxel.TP_LEVEL) or 7 end
  if mode == "first" then return (Voxel and Voxel.FP_LEVEL) or 6 end
  return (Voxel and Voxel.FULL_LEVEL) or 1
end

Bridge.cameraLevelForMode = cameraLevelForMode
Bridge.normalizeCameraMode = normalizeCameraMode

local function selectorLevelForMode(mode)
  local ok, Pipelines = pcall(require, "src.render.Pipelines")
  if not ok or type(Pipelines) ~= "table"
     or type(Pipelines.levelLabels) ~= "function" then return nil end
  local labels = Pipelines.levelLabels("voxel")
  if type(labels) ~= "table" then return nil end
  mode = normalizeCameraMode(mode)
  local fallback = nil
  for i, label in ipairs(labels) do
    local upper = tostring(label or ""):upper()
    local level = i - 1
    local first = upper:find("1ST", 1, true) or upper:find("FIRST", 1, true)
    local third = upper:find("3RD", 1, true) or upper:find("THIRD", 1, true)
    if mode == "first" and first then return level end
    if mode == "third" and third then return level end
    if mode == "diorama" and level > 0 and not first and not third then
      if upper:find("ZOOM", 1, true) or upper:find("ORBIT", 1, true)
         or upper:find("FULL", 1, true) then
        return level
      end
      fallback = fallback or level
    end
  end
  return fallback
end

local function setSelectorCameraMode(mode)
  local ok, Pipelines = pcall(require, "src.render.Pipelines")
  if not ok or type(Pipelines) ~= "table"
     or type(Pipelines.setLevel) ~= "function" then return false end
  local level = selectorLevelForMode(mode)
  if level == nil then return false end
  local okSet = pcall(Pipelines.setLevel, "voxel", level)
  if not okSet then return false end
  local game = Bridge.game
  if game and game.options and type(Pipelines.syncOptions) == "function" then
    pcall(Pipelines.syncOptions, game.options)
  end
  Bridge.externalCameraLevel = level
  Bridge.cameraProvider = "red_3d_player"
  return true
end

local function setCameraMode(mode, persist)
  mode = normalizeCameraMode(mode)
  Bridge.cameraOverride = mode
  if persist and mod.options and type(mod.options.set) == "function" then
    local ok, result = pcall(mod.options.set, mod.options, "cameraMode", mode)
    if ok and result ~= false then
      -- The public option bucket now owns the value; clear the temporary
      -- override so later Mod Manager changes can be observed normally.
      Bridge.cameraOverride = nil
    end
  end
  Bridge.cameraMode = mode
  Bridge.cameraLevel = cameraLevelForMode(mode)
  return mode
end

function Bridge.selectCameraMode(mode, persist, explicitControl)
  mode = normalizeCameraMode(mode)
  local control = optionCameraControl()

  -- CAMERA CONTROL = CHARACTER SELECTOR is the one mode where the external
  -- public voxel rung is deliberately authoritative.  Everywhere else an
  -- explicit slider/F6 action is a direct command to this renderer.  We still
  -- mirror the requested rung to red_3d_player when possible, but keep a local
  -- latch so AUTO cannot bounce DIORAMA straight back to the old 1ST/3RD rung.
  if control == "selector" and externalCameraEnabled() then
    if setSelectorCameraMode(mode) then
      Bridge.cameraOverride = nil
      Bridge.cameraMode = mode
      Bridge.cameraLevel = cameraLevelForMode(mode)
      return mode
    end
  end

  local result = setCameraMode(mode, persist ~= false)
  if explicitControl then
    Bridge.cameraOverride = mode
    if selectorDetected() then pcall(setSelectorCameraMode, mode) end
    Bridge.cameraProvider = "stadium-user"
  end
  return result
end

function Bridge.cycleCameraMode(persist)
  local current = optionCameraMode()
  return Bridge.selectCameraMode(CAMERA_NEXT[current] or CAMERA_ORDER[1],
    persist ~= false, true)
end

local function frameDt()
  local fallback = 1 / 60
  if not (love and love.timer and type(love.timer.getTime) == "function") then
    return fallback
  end
  local ok, now = pcall(love.timer.getTime)
  now = ok and tonumber(now) or nil
  if not now then return fallback end
  local prev = Bridge.lastTickTime
  Bridge.lastTickTime = now
  if not prev then return fallback end
  return math.max(1 / 240, math.min(1 / 15, now - prev))
end

local function stackTop(game)
  local stack = game and game.stack
  if not (stack and type(stack.top) == "function") then return nil end
  local ok, top = pcall(stack.top, stack)
  if ok then return top end
  return nil
end

local function goldFreeRoam(game)
  local world = game and game.world
  if not (type(world) == "table" and world.map ~= nil) then return false end
  local top = stackTop(game)
  return top == nil or (type(top) == "table" and top._stadiumCaptureOverlay == true)
end

local function fireCameraHotkey(game, fromPoll)
  -- Keep the capture rig stable for the duration of a throw. F6 resumes as
  -- soon as the transparent capture state leaves the stack.
  local top = stackTop(game)
  if top and top._stadiumCaptureOverlay == true then return false end
  if isAndroid() or not optionEnabled() or not goldFreeRoam(game) then
    return false
  end
  local mode = Bridge.cycleCameraMode(true)
  Bridge.cameraHotkeyCycles = Bridge.cameraHotkeyCycles + 1
  if fromPoll then
    Bridge.cameraHotkeyPollCycles = Bridge.cameraHotkeyPollCycles + 1
  end
  local log = mod.log
  if log and type(log.info) == "function" then
    pcall(log.info, log, "Gold voxel camera: %s", tostring(mode))
  end
  return true
end

-- F6 has two independent paths on desktop.  The normal Game2 key callback is
-- lowest latency, while the frame poll below survives another mod replacing or
-- swallowing that callback later in the load order.  Both share one latch so a
-- single physical press can never advance two camera modes.
local function pollCameraHotkey(game)
  if isAndroid() or not (love and love.keyboard
      and type(love.keyboard.isDown) == "function") then
    Bridge.f6Down = false
    return false
  end
  local ok, down = pcall(love.keyboard.isDown, "f6")
  down = ok and down and true or false
  local was = Bridge.f6Down
  Bridge.f6Down = down
  if down and not was then
    return fireCameraHotkey(game, true)
  end
  return false
end

local function installCameraHotkey(game)
  if type(game) ~= "table" then return false end
  if Bridge._hotkeyGame == game then return true end
  if Bridge._hotkeyGame ~= nil then return false end

  local inner = game.keypressed
  game.keypressed = function(self, key, ...)
    if key == "f6" then
      -- Mark the poll latch even if the key was pressed over a menu/battle.
      -- Re-entering free roam while the key is still held must not create a
      -- delayed camera switch.
      Bridge.f6Down = true
      if fireCameraHotkey(self, false) then return end
    end
    if inner then return inner(self, key, ...) end
  end
  Bridge._hotkeyGame = game
  return true
end

Bridge.pollCameraHotkey = pollCameraHotkey

local function cameraSliderRect()
  local G = love and love.graphics
  if not (G and type(G.getDimensions) == "function") then return nil end
  local ww, wh = G.getDimensions()
  if not (ww and wh and ww > 0 and wh > 0) then return nil end
  local w = math.max(250, math.min(380, ww * 0.42))
  local h = 70
  return (ww - w) * 0.5, 12, w, h
end

local function cameraSliderVisible(game)
  return isAndroid() and optionEnabled() and goldFreeRoam(game or Bridge.game)
end

local function sliderModeAt(x)
  local sx, sy, sw = cameraSliderRect()
  if not sx then return nil end
  local pad = 28
  local left, right = sx + pad, sx + sw - pad
  local t = math.max(0, math.min(1, (x - left) / math.max(1, right - left)))
  local index = math.floor(t * 2 + 0.5) + 1
  return CAMERA_ORDER[math.max(1, math.min(3, index))]
end

local function touchInsideSlider(x, y)
  local sx, sy, sw, sh = cameraSliderRect()
  if not sx then return false end
  return x >= sx - 10 and x <= sx + sw + 10
     and y >= sy - 10 and y <= sy + sh + 12
end

local function installCameraSlider(game)
  if not isAndroid() then return true end
  if type(game) ~= "table" then return false end
  if Bridge._sliderGame == game then return true end
  if Bridge._sliderGame ~= nil then return false end

  local held = {}
  local function apply(x)
    local mode = sliderModeAt(x)
    if not mode then return end
    if optionCameraMode() ~= mode then
      Bridge.selectCameraMode(mode, true, true)
      Bridge.cameraSliderChanges = Bridge.cameraSliderChanges + 1
    end
  end

  do
    local inner = game.touchpressed
    game.touchpressed = function(self, id, x, y, ...)
      if cameraSliderVisible(self) and touchInsideSlider(x, y) then
        held[id] = true
        Bridge.cameraSliderTouches = Bridge.cameraSliderTouches + 1
        apply(x)
        return
      end
      if inner then return inner(self, id, x, y, ...) end
    end
  end

  do
    local inner = game.touchmoved
    game.touchmoved = function(self, id, x, y, ...)
      if held[id] then
        apply(x)
        return
      end
      if inner then return inner(self, id, x, y, ...) end
    end
  end

  do
    local inner = game.touchreleased
    game.touchreleased = function(self, id, x, y, ...)
      if held[id] then
        held[id] = nil
        apply(x)
        return
      end
      if inner then return inner(self, id, x, y, ...) end
    end
  end

  local innerFocus = game.focus
  game.focus = function(self, focused, ...)
    if not focused then held = {} end
    if innerFocus then return innerFocus(self, focused, ...) end
  end

  Bridge._sliderGame = game
  Bridge.cameraSliderInstalled = true
  return true
end


-- Android fallback: poll the live LOVE touch table every render frame.
-- Some Android builds route touches through the engine's overlay/pointer chain
-- in a way that can bypass a late instance-method wrapper. Polling is the
-- authoritative fallback because it observes the physical contacts directly.
local function updateCameraSliderTouches(game)
  if not cameraSliderVisible(game) then
    Bridge._sliderPollId = nil
    return false
  end
  local T = love and love.touch
  if not (T and type(T.getTouches) == "function" and type(T.getPosition) == "function") then
    return false
  end

  local okIds, ids = pcall(T.getTouches)
  if not okIds or type(ids) ~= "table" then return false end

  local active = Bridge._sliderPollId
  if active ~= nil then
    local found = false
    for _, id in ipairs(ids) do
      if id == active then
        found = true
        local okPos, x, y = pcall(T.getPosition, id)
        if okPos and type(x) == "number" and type(y) == "number" then
          local mode = sliderModeAt(x)
          if mode and optionCameraMode() ~= mode then
            Bridge.selectCameraMode(mode, true, true)
            Bridge.cameraSliderChanges = Bridge.cameraSliderChanges + 1
          end
        end
        break
      end
    end
    if not found then Bridge._sliderPollId = nil end
    return found
  end

  -- Capture only a touch that is currently inside the visible slider.  The
  -- virtual GB controls live at the bottom of the screen, so this never steals
  -- their contacts; touches elsewhere remain normal game/look/pinch input.
  for _, id in ipairs(ids) do
    local okPos, x, y = pcall(T.getPosition, id)
    if okPos and type(x) == "number" and type(y) == "number"
       and touchInsideSlider(x, y) then
      Bridge._sliderPollId = id
      Bridge.cameraSliderTouches = Bridge.cameraSliderTouches + 1
      local mode = sliderModeAt(x)
      if mode and optionCameraMode() ~= mode then
        Bridge.selectCameraMode(mode, true, true)
        Bridge.cameraSliderChanges = Bridge.cameraSliderChanges + 1
      end
      return true
    end
  end
  return false
end

Bridge.updateCameraSliderTouches = updateCameraSliderTouches

-- v0.2.00 Android right-thumb look fallback. The camera-mode slider proved
-- that some Android builds do not reliably deliver late Game2 touch wrappers,
-- so camera look observes LOVE's physical touch table directly as well. Only a
-- free touch on the right side is claimed; overlay controls and the camera
-- slider are ignored. Two simultaneous FREE right-side touches are left alone
-- for pinch zoom. This feeds FirstPerson.lookBy, the same yaw/pitch used by
-- both the 1ST/3RD free-roam camera and Gold's live-overworld battle shot.
local function updateRightLookTouches(game, battleActive)
  if not isAndroid() or not optionEnabled() then
    Bridge._rightLookPollId = nil
    Bridge._rightLookPollX, Bridge._rightLookPollY = nil, nil
    return false
  end

  local mode = optionCameraMode()
  if mode ~= "first" and mode ~= "third" then
    Bridge._rightLookPollId = nil
    Bridge._rightLookPollX, Bridge._rightLookPollY = nil, nil
    return false
  end

  -- In free roam require the world to be the active view. During a live-world
  -- battle the battle state is intentionally on the stack, so battleActive is
  -- the explicit permission for the same camera to keep steering.
  if not battleActive and not goldFreeRoam(game or Bridge.game) then
    Bridge._rightLookPollId = nil
    Bridge._rightLookPollX, Bridge._rightLookPollY = nil, nil
    return false
  end

  local T = love and love.touch
  local G = love and love.graphics
  if not (T and type(T.getTouches) == "function" and type(T.getPosition) == "function"
       and G and type(G.getDimensions) == "function") then
    return false
  end
  local okIds, ids = pcall(T.getTouches)
  if not okIds or type(ids) ~= "table" then return false end
  local ww, wh = G.getDimensions()

  local TouchControls = nil
  pcall(function() TouchControls = require("src.core.TouchControls") end)
  local function controlAt(x, y)
    if not (TouchControls and type(TouchControls.hitTest) == "function") then return nil end
    local ok, hit = pcall(TouchControls.hitTest, TouchControls, x, y)
    return ok and hit or nil
  end
  local function freeRight(id)
    local ok, x, y = pcall(T.getPosition, id)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil end
    if x < ww * 0.45 then return nil end
    if touchInsideSlider(x, y) then return nil end
    if controlAt(x, y) then return nil end
    return x, y
  end

  local candidates = {}
  for _, id in ipairs(ids) do
    local x, y = freeRight(id)
    if x then candidates[#candidates + 1] = { id = id, x = x, y = y } end
  end

  -- Two free fingers on the look side are a pinch gesture, not a camera turn.
  if #candidates > 1 then
    Bridge._rightLookPollId = nil
    Bridge._rightLookPollX, Bridge._rightLookPollY = nil, nil
    return false
  end
  if #candidates == 0 then
    Bridge._rightLookPollId = nil
    Bridge._rightLookPollX, Bridge._rightLookPollY = nil, nil
    return false
  end

  local c = candidates[1]
  if Bridge._rightLookPollId ~= c.id then
    Bridge._rightLookPollId = c.id
    Bridge._rightLookPollX, Bridge._rightLookPollY = c.x, c.y
    return true
  end

  local px, py = Bridge._rightLookPollX or c.x, Bridge._rightLookPollY or c.y
  local dx, dy = c.x - px, c.y - py
  Bridge._rightLookPollX, Bridge._rightLookPollY = c.x, c.y
  if dx ~= 0 or dy ~= 0 then
    -- Match FirstPerson's mobile-shooter convention: drag right looks right,
    -- drag up looks up. Scale by actual screen dimensions so sensitivity is
    -- stable from phones to tablets.
    local yaw = -(dx / math.max(320, ww)) * (2.2 * math.pi)
    local pitch = (dy / math.max(240, wh)) * (2.2 * math.pi)
    if battleActive then
      local okCam, BattleCinematic = pcall(V.require, "BattleCinematic")
      if okCam and BattleCinematic and type(BattleCinematic.manualLook) == "function" then
        BattleCinematic.manualLook(yaw, pitch)
      else
        FirstPerson.lookBy(yaw, pitch)
      end
    else
      FirstPerson.lookBy(yaw, pitch)
    end
    Bridge.rightLookFrames = (Bridge.rightLookFrames or 0) + 1
  end
  return true
end

Bridge.updateRightLookTouches = updateRightLookTouches

-- Direct Android pinch poll for DIORAMA. The callback-based pinch recognizer
-- is kept for desktop/debug hosts, but real Android builds have already shown
-- that late Game2 touch wrappers are not reliable enough. This watches LOVE's
-- physical contacts directly and changes the continuous diorama camera distance.
local function updateDioramaPinchTouches(game)
  if not isAndroid() or not optionEnabled() or optionCameraMode() ~= "diorama"
     or not goldFreeRoam(game or Bridge.game) then
    Bridge._dioramaPinchA, Bridge._dioramaPinchB = nil, nil
    Bridge._dioramaPinchGap = nil
    return false
  end
  local T, G = love and love.touch, love and love.graphics
  if not (T and type(T.getTouches) == "function" and type(T.getPosition) == "function"
       and G and type(G.getDimensions) == "function") then return false end
  local okIds, ids = pcall(T.getTouches)
  if not okIds or type(ids) ~= "table" then return false end
  local TouchControls = nil
  pcall(function() TouchControls = require("src.core.TouchControls") end)
  local function free(id)
    local ok, x, y = pcall(T.getPosition, id)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil end
    if touchInsideSlider(x, y) then return nil end
    if TouchControls and type(TouchControls.hitTest) == "function" then
      local okHit, hit = pcall(TouchControls.hitTest, TouchControls, x, y)
      if okHit and hit then return nil end
    end
    return { id=id, x=x, y=y }
  end
  local freeTouches = {}
  for _, id in ipairs(ids) do
    local c = free(id)
    if c then freeTouches[#freeTouches+1] = c end
  end
  if #freeTouches < 2 then
    Bridge._dioramaPinchA, Bridge._dioramaPinchB = nil, nil
    Bridge._dioramaPinchGap = nil
    return false
  end
  local a, b = freeTouches[1], freeTouches[2]
  local dx, dy = a.x-b.x, a.y-b.y
  local gap = math.sqrt(dx*dx + dy*dy)
  if gap < 16 then return false end
  if Bridge._dioramaPinchA ~= a.id or Bridge._dioramaPinchB ~= b.id
     or not Bridge._dioramaPinchGap then
    Bridge._dioramaPinchA, Bridge._dioramaPinchB = a.id, b.id
    Bridge._dioramaPinchGap = gap
    return true
  end
  local factor = gap / math.max(1, Bridge._dioramaPinchGap)
  Bridge._dioramaPinchGap = gap
  if math.abs(factor - 1) > 0.008 then
    local okZoom, DioramaZoom = pcall(V.require, "DioramaZoom")
    if okZoom and DioramaZoom and type(DioramaZoom.scaleBy) == "function" then
      DioramaZoom.scaleBy(1 / factor)
      Bridge.dioramaPinchFrames = (Bridge.dioramaPinchFrames or 0) + 1
      return true
    end
  end
  return false
end

Bridge.updateDioramaPinchTouches = updateDioramaPinchTouches

function Bridge.drawCameraSlider(ctx)
  local game = Bridge.game
  if not cameraSliderVisible(game) then return false end
  local G = love and love.graphics
  if not G then return false end
  local sx, sy, sw, sh = cameraSliderRect()
  if not sx then return false end
  local pad = 28
  local left, right = sx + pad, sx + sw - pad
  local trackY = sy + 38
  local mode = optionCameraMode()
  local idx = (mode == "third" and 2) or (mode == "first" and 3) or 1
  local thumbX = left + (idx - 1) * (right - left) / 2
  local labels = { "DIORAMA", "3RD", "1ST" }

  local ok = pcall(function()
    G.push("all")
    G.origin()
    G.setBlendMode("alpha")
    G.setColor(0, 0, 0, 0.58)
    G.rectangle("fill", sx, sy, sw, sh, 12, 12)
    G.setColor(1, 1, 1, 0.20)
    G.rectangle("line", sx, sy, sw, sh, 12, 12)
    G.setColor(1, 1, 1, 0.45)
    G.setLineWidth(4)
    G.line(left, trackY, right, trackY)
    for i = 1, 3 do
      local px = left + (i - 1) * (right - left) / 2
      G.setColor(1, 1, 1, 0.72)
      G.circle("fill", px, trackY, 5)
    end
    G.setColor(1, 1, 1, 1)
    G.circle("fill", thumbX, trackY, 11)
    G.setColor(0, 0, 0, 0.82)
    G.circle("fill", thumbX, trackY, 5)

    local font = type(G.getFont) == "function" and G.getFont() or nil
    for i, label in ipairs(labels) do
      local px = left + (i - 1) * (right - left) / 2
      local tw = font and font:getWidth(label) or (#label * 6)
      G.setColor(1, 1, 1, i == idx and 1 or 0.68)
      G.print(label, math.floor(px - tw / 2), sy + 7)
    end
    G.pop()
  end)
  if not ok then pcall(G.pop) return false end
  return true
end

Bridge.cameraSliderVisible = cameraSliderVisible
Bridge.cameraSliderRect = cameraSliderRect

local function bindGame(game)
  if type(game) ~= "table" then return false end
  Bridge.game = game
  V.game = game
  installCameraHotkey(game)
  if FirstPerson and type(FirstPerson.install) == "function"
     and not Bridge.cameraInputInstalled then
    local ok, result, err = pcall(FirstPerson.install, game)
    if ok and result ~= false then
      Bridge.cameraInputInstalled = true
      Bridge.cameraInputError = nil
    else
      Bridge.cameraInputError = tostring(ok and err or result)
      logOnce("camera-input:" .. Bridge.cameraInputError, "warn",
        "Gold first/third-person camera input hooks unavailable: %s",
        Bridge.cameraInputError)
    end
  end
  -- Install the shared camera input owner AFTER FirstPerson, as CamControl's
  -- wraps are intentionally the outer layer. This activates two-finger pinch
  -- zoom on the voxel world without letting the same gesture also become a
  -- first/third-person look drag. It also keeps wheel/pad zoom routing in one
  -- place instead of adding a Gold-only touch implementation.
  if CamControl and type(CamControl.install) == "function"
     and not Bridge.pinchZoomInstalled then
    local ok, result, err = pcall(CamControl.install, game)
    if ok and result ~= false then
      Bridge.pinchZoomInstalled = true
      Bridge.pinchZoomError = nil
    else
      Bridge.pinchZoomError = tostring(ok and err or result)
      logOnce("pinch-zoom:" .. Bridge.pinchZoomError, "warn",
        "Gold voxel pinch-zoom hooks unavailable: %s",
        Bridge.pinchZoomError)
    end
  end

  if not Bridge.cameraSliderInstalled then
    local okSlider, sliderResult = pcall(installCameraSlider, game)
    if not okSlider or sliderResult == false then
      logOnce("camera-slider-install", "warn",
        "Gold Android camera-mode slider unavailable")
    end
  end

  if GoldCameraControls and type(GoldCameraControls.install) == "function"
     and not Bridge.cameraMovementInstalled then
    local ok, result, err = pcall(GoldCameraControls.install)
    if ok and result ~= false then
      Bridge.cameraMovementInstalled = true
      Bridge.cameraMovementError = nil
    else
      Bridge.cameraMovementError = tostring(ok and err or result)
      logOnce("camera-movement:" .. Bridge.cameraMovementError, "warn",
        "Gold camera-relative movement hook unavailable: %s",
        Bridge.cameraMovementError)
    end
  end
  return true
end

function Bridge.setGame(game)
  return bindGame(game)
end

logOnce = function(key, level, fmt, ...)
  Bridge._logged = Bridge._logged or {}
  if Bridge._logged[key] then return end
  Bridge._logged[key] = true
  local log = mod.log
  local fn = log and log[level]
  if type(fn) == "function" then pcall(fn, log, fmt, ...) end
end

local function ensurePlayerPose()
  -- Requiring the explicit Gen-2 class is intentional here: this is a Gen-2
  -- only package and VoxelScene consumes the entity pose contract directly.
  local okPlayer, Player = pcall(require, "src.world.gen2.Player")
  if not okPlayer or type(Player) ~= "table" then
    return false, tostring(Player or "Gen-2 Player unavailable")
  end
  if type(Player.pose) ~= "function" then
    function Player:pose()
      local y = self.py + (self.spriteYOffset or 0)
      return self.sprite, self.px, y, self.facing,
        (self.walkPhase and self:walkPhase()) or 0,
        self.stepFlip == true, false
    end
  end
  return true
end

-- Gold keys generated tilesets with engine constants such as
-- `TILESET_JOHTO`, while Dramatic Shapes' authored voxel profile predates
-- that cache vocabulary and is keyed as `TilesetJohto`.  The tileset object
-- itself is returned by World:atlasFor and can therefore carry the engine
-- key in `id`; passing that straight through makes every authored Gen-2
-- shape silently miss and fall back to generic solid boxes.
--
-- Translate only the engine's TILESET_* spelling.  Gen-1 ids (OVERWORLD,
-- FOREST, etc.) and already-canonical Gen-2 ids are returned unchanged.
local function profileTilesetId(raw)
  if type(raw) ~= "string" or raw:sub(1, 8) ~= "TILESET_" then
    return raw
  end
  local out = { "Tileset" }
  for word in raw:sub(9):gmatch("[^_]+") do
    local lower = word:lower()
    out[#out + 1] = lower:sub(1, 1):upper() .. lower:sub(2)
  end
  return table.concat(out)
end

-- Exposed for the headless compatibility probe; harmless to runtime callers.
Bridge.profileTilesetId = profileTilesetId

local function attachRenderer(world, map)
  if not (world and map and map.def) then
    return false, "Gold map/definition not ready"
  end
  if type(world.atlasFor) ~= "function" then
    return false, "Gold World:atlasFor is unavailable"
  end

  -- Voxel terrain UVs sample a TILESET ATLAS, not Gold's already-baked whole
  -- map canvas. Reuse World:atlasFor so roofs/asset overrides resolve through
  -- the exact same live Gen-2 path as vanilla Gold.
  local ok, atlas, tileset = pcall(world.atlasFor, world, map.def)
  if not ok then return false, "Gold atlasFor failed: " .. tostring(atlas) end
  if not atlas then return false, "Gold atlasFor returned no tileset atlas" end

  map.tileset = tileset or map.tileset

  -- IMPORTANT: map.def.tileset remains the engine key (for example
  -- TILESET_JOHTO); only the tileset record's presentation id is normalised
  -- for the voxel modules.  Gen1Recomp itself indexes world.tilesets by
  -- map.def.tileset, so changing this field does not disturb the engine's
  -- lookup, while TileShape/Structures/Buildings can finally find their
  -- authored Gen-2 profile rows.
  if map.tileset then
    local engineId = map.def.tileset or map.tileset.id
    local profileId = profileTilesetId(engineId)
    if profileId then
      map.tileset._stadiumEngineTilesetId =
        map.tileset._stadiumEngineTilesetId or map.tileset.id or engineId
      map.tileset.id = profileId
    end
  end

  map.renderer = map.renderer or {}
  map.renderer.data = (world.game and world.game.data) or map.renderer.data

  -- Gold's generated tileset sheet is intentionally four-shade source art.
  -- The native 2D renderer assigns one of eight GBC palettes PER 8x8 tile at
  -- draw/bake time. Voxel geometry samples the atlas directly, so feeding it
  -- World:atlasFor's raw sheet produces a correct-but-monochrome world. Bake
  -- that same Gen-2 PalMap into a private atlas before the voxel mesh sees it.
  if not GoldColorAtlas then
    local okColor, moduleOrErr = pcall(V.require, "GoldColorAtlas")
    if okColor and type(moduleOrErr) == "table" then
      GoldColorAtlas = moduleOrErr
    else
      logOnce("gold-color-module:" .. tostring(moduleOrErr), "warn",
        "Gold voxel GBC-color adapter unavailable; raw atlas fallback: %s",
        tostring(moduleOrErr))
    end
  end

  local image, pixels, colored, colorErr, colorKey = atlas, nil, false, nil, nil
  if GoldColorAtlas and type(GoldColorAtlas.forMap) == "function" then
    local okColor, a, b, c, d, e = pcall(GoldColorAtlas.forMap, world, map, atlas)
    if okColor then
      image, pixels, colored, colorErr, colorKey = a or atlas, b, c == true, d, e
    else
      colorErr = tostring(a)
    end
  end

  map.renderer.image = image or atlas
  map.renderer.gbcAtlas = colored == true
  map.renderer._stadiumAtlasData = colored and pixels or nil
  map.renderer._stadiumColorKey = colored and colorKey or nil
  map.renderer._stadiumGen2Color = colored == true
  if not colored and colorErr then
    logOnce("gold-color-fallback:" .. tostring(colorErr), "warn",
      "Gold voxel color atlas fell back to raw source art: %s", tostring(colorErr))
  end
  return true
end

-- Gold's native 2D renderer keeps connected areas as lightweight image records
-- (`{ id, ox, oy, image }`).  VoxelScene needs actual Map objects so it can
-- mesh the next area before the player crosses the seam.  v0.2.04 adapts the
-- DIRECT connection in each cardinal direction -- one whole map ahead -- and
-- keeps those maps warm as body-only neighbour meshes.  This is intentionally
-- a renderer-side adapter: Gold's own map transition/collision code remains the
-- authority and is never replaced.
local CARDINAL_CONNECTIONS = { "north", "south", "west", "east" }
local EDGE_URGENT_CELLS = 8

local function goldMapModule()
  if GoldMap then return GoldMap end
  local ok, Map = pcall(require, "src.world.gen2.Map")
  if ok and type(Map) == "table" and type(Map.new) == "function" then
    GoldMap = Map
    return GoldMap
  end
  return nil
end

local function directNeighborSpecs(world)
  local root = world and world.map and world.map.def
  local maps = world and world.maps
  if not (root and maps) then return {} end

  -- Prefer offsets Gold already computed for its native connected-map strips.
  -- If a strip image was unavailable and Gold omitted that record, derive the
  -- same connection offset directly so voxel streaming is not held hostage by
  -- the 2D bake path.
  local native = {}
  for _, nb in ipairs(world.neighbors or {}) do
    if nb and nb.id then native[nb.id] = nb end
  end

  local out, seen = {}, {}
  for _, dir in ipairs(CARDINAL_CONNECTIONS) do
    local conn = root.connections and root.connections[dir]
    local id = conn and (conn.mapId or conn.map)
    local def = id and maps[id] or nil
    if def and not seen[id] then
      seen[id] = true
      local n = native[id]
      local ox, oy = n and tonumber(n.ox), n and tonumber(n.oy)
      if not (ox and oy) then
        local offset = tonumber(conn.offset) or 0
        if dir == "north" then
          ox, oy = offset * 32, -def.height * 32
        elseif dir == "south" then
          ox, oy = offset * 32, root.height * 32
        elseif dir == "west" then
          ox, oy = -def.width * 32, offset * 32
        else -- east
          ox, oy = root.width * 32, offset * 32
        end
      end
      out[#out + 1] = { id = id, dir = dir, ox = ox, oy = oy, native = n }
    end
  end
  return out
end

local function neighborUrgent(world, dir)
  local p = world and world.player
  local def = world and world.map and world.map.def
  if not (p and def) then return false end
  local x, y = tonumber(p.cellX), tonumber(p.cellY)
  if not (x and y) then return false end
  local w, h = (tonumber(def.width) or 0) * 2, (tonumber(def.height) or 0) * 2
  if dir == "north" then return y <= EDGE_URGENT_CELLS end
  if dir == "south" then return y >= h - 1 - EDGE_URGENT_CELLS end
  if dir == "west" then return x <= EDGE_URGENT_CELLS end
  if dir == "east" then return x >= w - 1 - EDGE_URGENT_CELLS end
  return false
end

local function adaptedNeighborMap(world, id)
  local maps, tilesets = world and world.maps, world and world.tilesets
  local def = maps and maps[id]
  local sourceTileset = def and tilesets and tilesets[def.tileset]
  local Map = goldMapModule()
  if not (def and sourceTileset and Map) then
    return nil, "missing Gold neighbour map/tileset adapter data"
  end

  local hit = neighborMapCache[id]
  if not hit or hit.def ~= def or hit.sourceTileset ~= sourceTileset
      or hit.blocks ~= def.blocks then
    local ok, map = pcall(Map.new, def, sourceTileset)
    if not ok or type(map) ~= "table" then
      return nil, "Gold neighbour Map.new failed: " .. tostring(map)
    end
    hit = { map = map, def = def, sourceTileset = sourceTileset, blocks = def.blocks }
    neighborMapCache[id] = hit
  end

  local ok, err = attachRenderer(world, hit.map)
  if not ok then return nil, err end
  return hit.map
end

local function adaptedNeighbors(world)
  local out, byId = {}, {}
  for _, spec in ipairs(directNeighborSpecs(world)) do
    local map, err = adaptedNeighborMap(world, spec.id)
    if map then
      local rec = {
        id = spec.id, map = map, ox = spec.ox, oy = spec.oy, dir = spec.dir,
        -- Background builds start immediately at the ordinary neighbour budget;
        -- approaching an edge promotes that destination to the urgent slice so
        -- fast movement is much less likely to outrun its mesh.
        urgent = neighborUrgent(world, spec.dir),
      }
      out[#out + 1] = rec
      byId[spec.id] = rec

      -- Add the actual Map object to Gold's own neighbour record too.  Existing
      -- consumers such as ThirdPerson boom collision and follower seam checks
      -- already look for `nb.map`; until now Gold's records never supplied it.
      -- Unknown fields are ignored by the native 2D renderer.
      if spec.native then spec.native.map = map end
    else
      logOnce("neighbor-adapt:" .. tostring(spec.id) .. ":" .. tostring(err),
        "warn", "Gold connected-map voxel adapter skipped %s: %s",
        tostring(spec.id), tostring(err))
    end
  end
  return out, byId
end

local function adaptedGhosts(world, byId)
  local out = {}
  for _, g in ipairs(world and world.ghosts or {}) do
    local id = (g.map and g.map.id) or (g.npc and g.npc.mapId)
    local nb = id and byId[id]
    if nb and g.npc then
      out[#out + 1] = {
        npc = g.npc, map = nb.map, ox = nb.ox, oy = nb.oy, peers = g.peers,
      }
    end
  end
  return out
end

local function currentMasks(neighbors)
  local masks = {}
  for _, nb in ipairs(neighbors or {}) do
    if nb.map and nb.map.def then
      masks[#masks + 1] = {
        nb.ox, nb.oy,
        nb.ox + nb.map.def.width * 32,
        nb.oy + nb.map.def.height * 32,
      }
    end
  end
  return masks
end

local function mergedEntities(world)
  local out, seen = {}, {}
  local function add(e)
    if type(e) == "table" and not seen[e] then
      seen[e] = true
      out[#out + 1] = e
    end
  end

  -- VoxelScene expects all standing actors in state.entities.  Gold keeps the
  -- player and native NPCs separately, so include them explicitly rather than
  -- relying on the Gen-1 World.entities convention.
  add(world.player)
  if type(world.npcs) == "table" then
    for _, e in ipairs(world.npcs) do add(e) end
  end
  if type(world.entities) == "table" then
    for _, e in ipairs(world.entities) do add(e) end
  end

  Bridge.extraEntitiesMerged = 0
  local provider = Bridge.extraEntitiesProvider
  if type(provider) == "function" then
    local ok, extra = pcall(provider, world)
    if ok and type(extra) == "table" then
      local before = #out
      for _, e in ipairs(extra) do add(e) end
      Bridge.extraEntitiesMerged = #out - before
    elseif not ok then
      local err = "visible Wilds provider failed: " .. tostring(extra)
      Bridge.lastError = err
      logOnce("extra-entities:" .. tostring(extra), "warn",
        "Gold visible-Wilds voxel entity provider failed: %s", tostring(extra))
    end
  end
  return out
end

local function makeState(world)
  if not (world and world.map and world.camera and world.player) then
    return nil, "Gold world/map/player is not ready"
  end
  local attached, attachErr = attachRenderer(world, world.map)
  if not attached then return nil, attachErr end

  local neighbors, byId = adaptedNeighbors(world)
  -- Shared with the camera/follower compatibility paths.  These are the exact
  -- direct maps VoxelScene is drawing this frame, in current-map coordinates.
  V.goldNeighbors = neighbors

  return {
    map = world.map,
    camera = world.camera,
    player = world.player,
    entities = mergedEntities(world),
    neighbors = neighbors,
    ghosts = adaptedGhosts(world, byId),
    flyAnim = world.flyAnim,
    -- Carry the true-directional renderer state with the exact live Gold world
    -- used to build this frame.  Do not make OverworldStadium rediscover the
    -- world through Game.overworld/StateStack: those facades can lag behind the
    -- first map and only become current after a connection transition.
    _stadiumFreeMoveActive = world._stadiumFreeMoveActive == true,
    _stadiumFreeVisualMoving = world._stadiumFreeVisualMoving == true,
    _stadiumFreeAnimDist = tonumber(world._stadiumFreeAnimDist) or 0,
    _stadiumOpenWorldNeighbors = true,
  }
end

-- Sibling Gold-only modules (notably OverworldBattle) can request the same
-- adapted state the free-roam renderer uses, including normalized tileset ids.
V.goldStateForWorld = makeState

local function pixelDimensions(ctx)
  local pw, ph = tonumber(ctx and ctx.pw), tonumber(ctx and ctx.ph)
  if pw and ph and pw > 0 and ph > 0 then return pw, ph end
  local G = love.graphics
  if G.getPixelDimensions then
    local ok, w, h = pcall(G.getPixelDimensions)
    if ok and w and h and w > 0 and h > 0 then return w, h end
  end
  return G.getDimensions()
end

local function viewDimensions(world, ctx)
  local vw, vh = tonumber(world and world.viewW), tonumber(world and world.viewH)
  if vw and vh and vw > 0 and vh > 0 then return vw, vh end

  local ww, wh = tonumber(ctx and ctx.ww), tonumber(ctx and ctx.wh)
  if not (ww and wh and ww > 0 and wh > 0) then
    ww, wh = love.graphics.getDimensions()
  end
  local scale = 1
  if world and type(world.zoomScale) == "function" then
    local ok, s = pcall(world.zoomScale, world)
    if ok and tonumber(s) and tonumber(s) > 0 then scale = tonumber(s) end
  end
  return math.max(1, math.ceil(ww / scale)), math.max(1, math.ceil(wh / scale))
end

function Bridge.install()
  if Bridge.installed then return true, V end

  local poseOK, poseErr = ensurePlayerPose()
  if not poseOK then return false, poseErr end

  local ok, a, b, c, d, e, f, g = pcall(function()
    return V.require("VoxelState"), V.require("Voxel3D"),
      V.require("VoxelScene"), V.require("ChunkMesher"),
      V.require("FirstPerson"), V.require("CamControl"),
      V.require("GoldCameraControls")
  end)
  if not ok then return false, tostring(a) end
  Voxel, Voxel3D, VoxelScene, ChunkMesher, FirstPerson, CamControl, GoldCameraControls =
    a, b, c, d, e, f, g

  if not (type(Voxel) == "table" and type(Voxel.setLevel) == "function") then
    return false, "VoxelState renderer is unavailable"
  end
  if not (type(Voxel3D) == "table" and type(Voxel3D.available) == "function") then
    return false, "Voxel3D renderer is unavailable"
  end
  if not (type(VoxelScene) == "table" and type(VoxelScene.render) == "function") then
    return false, "VoxelScene renderer is unavailable"
  end
  if not (type(ChunkMesher) == "table" and type(ChunkMesher.pump) == "function"
       and type(ChunkMesher.get) == "function") then
    return false, "ChunkMesher renderer is unavailable"
  end

  if not (type(FirstPerson) == "table" and type(FirstPerson.update) == "function"
       and type(FirstPerson.install) == "function") then
    return false, "FirstPerson/ThirdPerson camera rig is unavailable"
  end
  if not (type(CamControl) == "table" and type(CamControl.install) == "function"
       and type(CamControl.pinchBy) == "function") then
    return false, "Voxel pinch-zoom controller is unavailable"
  end
  if not (type(GoldCameraControls) == "table"
       and type(GoldCameraControls.install) == "function") then
    return false, "Gold camera-relative movement adapter is unavailable"
  end

  -- In-world battles are optional to the renderer's survival: install them
  -- through this same Gold module namespace, but never let a battle hook
  -- failure disable the proven free-roam voxel path.
  local okBattle, battleOrErr = pcall(V.require, "OverworldBattle")
  if okBattle and type(battleOrErr) == "table" then
    OverworldBattle = battleOrErr
    local okInstall, installErr = pcall(OverworldBattle.install)
    Bridge.battleInstalled = okInstall and installErr ~= false
    if not Bridge.battleInstalled then
      Bridge.battleError = tostring(installErr or "battle install declined")
    end
  else
    Bridge.battleInstalled = false
    Bridge.battleError = tostring(battleOrErr)
  end

  -- Optional in-world capture minigame.  Keep it isolated from renderer
  -- survival exactly like the battle presentation: a bad capture asset/hook
  -- may fall back to normal battles but must never disable the voxel world.
  local okCapture, captureOrErr = pcall(V.require, "OverworldCapture")
  if okCapture and type(captureOrErr) == "table" then
    OverworldCapture = captureOrErr
    Bridge.captureAvailable = true
    Bridge.captureError = nil
  else
    Bridge.captureAvailable = false
    Bridge.captureError = tostring(captureOrErr)
  end

  Bridge.installed = true
  Bridge.active = optionEnabled()
  logOnce("installed", "info",
    "Gen-2 voxel renderer provider ready for Gold render.compose")
  return true, V
end

function Bridge.ensure()
  if not Bridge.installed then return Bridge.install() end
  return true, V
end

function Bridge.renderFrame(world, ctx)
  Bridge.framesAttempted = Bridge.framesAttempted + 1
  Bridge.active = optionEnabled()
  Bridge.mapId = world and world.map and world.map.id or nil

  if not Bridge.active then return nil, "voxel disabled", "disabled" end
  if not Bridge.installed then
    local ok, err = Bridge.install()
    if not ok then
      Bridge.framesFailed = Bridge.framesFailed + 1
      Bridge.lastError = tostring(err)
      return nil, Bridge.lastError, "failed"
    end
  end

  -- GoldComposeBridge supplies the live Game2 owner explicitly; current World
  -- objects also keep it as world.game. The camera modules use this instead of
  -- the Gen-1 singleton when deciding whether free roam is actually on top.
  bindGame((world and world.game) or Bridge.game)

  local okAvailable, available = pcall(Voxel3D.available)
  if not okAvailable or not available then
    local err = okAvailable and "Voxel3D reports graphics/depth support unavailable"
      or ("Voxel3D availability check failed: " .. tostring(available))
    Bridge.framesFailed = Bridge.framesFailed + 1
    Bridge.lastError = err
    logOnce("available:" .. err, "warn", "%s", err)
    return nil, err, "failed"
  end

  local state, stateErr = makeState(world)
  if not state then
    Bridge.framesFailed = Bridge.framesFailed + 1
    Bridge.lastError = tostring(stateErr)
    return nil, Bridge.lastError, "failed"
  end

  -- Prime the CURRENT Gold map synchronously once on entry.  The original
  -- renderer queues terrain through an async coroutine because Gen 1's normal
  -- pipeline has a dedicated update/pump cadence.  Gold's compose hook does
  -- not have that host contract, and a failed async job was previously cached
  -- as false and mistaken for "still pending" forever.  A one-time direct
  -- build gives Gold a drawable terrain mesh immediately (or a concrete error).
  if Bridge.syncBuildMapId ~= state.map.id then
    Bridge.syncBuildMapId = state.map.id
    Bridge.syncBuilds = Bridge.syncBuilds + 1

    -- A destination that was already visible as a neighbour has a body mesh
    -- waiting in cache.  Reuse it immediately on the seam instead of blocking
    -- the crossing to synchronously rebuild the new current map.  On a cold
    -- boot, prime the full map with neighbour masks already applied so the
    -- 32-tile forest apron cannot grow up through connected route terrain.
    local warm = (type(ChunkMesher.peek) == "function")
      and (ChunkMesher.peek(state.map, false) or ChunkMesher.peek(state.map, true))
    local okPrime, primeMeshOrErr = true, warm
    if not warm then
      okPrime, primeMeshOrErr = pcall(ChunkMesher.get, state.map, false,
                                      currentMasks(state.neighbors))
    end
    if not okPrime then
      Bridge.syncBuildFailures = Bridge.syncBuildFailures + 1
      Bridge.framesFailed = Bridge.framesFailed + 1
      Bridge.lastError = "Gen-2 voxel mesh prime crashed: " .. tostring(primeMeshOrErr)
      logOnce("prime-crash:" .. tostring(state.map.id) .. ":" .. Bridge.lastError,
        "error", "%s", Bridge.lastError)
      return nil, Bridge.lastError, "failed"
    end
    if not primeMeshOrErr then
      local meshErr = type(ChunkMesher.lastError) == "function"
        and ChunkMesher.lastError(state.map.id) or nil
      Bridge.syncBuildFailures = Bridge.syncBuildFailures + 1
      Bridge.framesFailed = Bridge.framesFailed + 1
      Bridge.lastError = meshErr and ("Gen-2 voxel mesh build failed: " .. tostring(meshErr))
        or "Gen-2 voxel mesh build produced no terrain"
      logOnce("prime-empty:" .. tostring(state.map.id) .. ":" .. Bridge.lastError,
        "error", "%s", Bridge.lastError)
      return nil, Bridge.lastError, "failed"
    end
  end

  local ok, canvasOrErr = pcall(function()
    -- Poll Android touch contacts before resolving this frame's camera mode so
    -- a slider drag takes effect on the very same rendered frame.
    local liveGame = (world and world.game) or Bridge.game
    updateCameraSliderTouches(liveGame)
    updateDioramaPinchTouches(liveGame)
    updateRightLookTouches(liveGame, false)
    pollCameraHotkey(liveGame)
    local mode = optionCameraMode()
    -- A capture begun from DIORAMA temporarily dives to the already-proven
    -- 3RD-person rig so the player can physically aim with mouse/right stick.
    -- The saved camera option is never changed; leaving the minigame returns
    -- to DIORAMA automatically on the next frame.
    local captureMode = nil
    if OverworldCapture and type(OverworldCapture.cameraOverride) == "function" then
      local okCaptureMode, value = pcall(OverworldCapture.cameraOverride)
      if okCaptureMode then captureMode = value end
    end
    local renderMode = captureMode or mode
    local level = cameraLevelForMode(renderMode)
    local dt = frameDt()
    Bridge.cameraMode, Bridge.cameraLevel = mode, level
    Bridge.captureCameraOverride = captureMode

    -- DIORAMA keeps the proven v0.1.78 camera. FIRST and THIRD select the
    -- already-authored placed-camera rungs, now driven by Gold's live Game2.
    Voxel.setLevel(level)
    if type(Voxel.update) == "function" then Voxel.update(dt, level) end
    if FirstPerson and type(FirstPerson.update) == "function" then
      FirstPerson.update(dt)
    end
    if OverworldCapture and type(OverworldCapture.afterCameraUpdate) == "function" then
      pcall(OverworldCapture.afterCameraUpdate)
    end
    ChunkMesher.pump(false)
    local pw, ph = pixelDimensions(ctx)
    local vw, vh = viewDimensions(world, ctx)
    local canvas = VoxelScene.render(state, pw, ph, vw, vh, nil)
    ChunkMesher.pump(false)
    return canvas
  end)

  if not ok then
    Bridge.framesFailed = Bridge.framesFailed + 1
    Bridge.lastError = tostring(canvasOrErr)
    logOnce("render:" .. Bridge.lastError, "error",
      "Gold compose voxel frame failed; flat Gold + visible Wilds fallback will be used: %s",
      Bridge.lastError)
    return nil, Bridge.lastError, "failed"
  end

  if not canvasOrErr then
    local meshErr = type(ChunkMesher.lastError) == "function"
      and ChunkMesher.lastError(state.map.id) or nil
    if meshErr then
      Bridge.framesFailed = Bridge.framesFailed + 1
      Bridge.lastError = "Gen-2 voxel mesh failed after prime: " .. tostring(meshErr)
      logOnce("mesh-failed:" .. tostring(state.map.id) .. ":" .. Bridge.lastError,
        "error", "%s", Bridge.lastError)
      return nil, Bridge.lastError, "failed"
    end
    Bridge.framesPending = Bridge.framesPending + 1
    Bridge.meshPendingFrames = Bridge.meshPendingFrames + 1
    return nil, "voxel mesh pending", "pending"
  end

  Bridge.frames3d = Bridge.frames3d + 1
  Bridge.lastError = nil
  return canvasOrErr, nil, "rendered"
end

function Bridge.updateBattle(dt)
  if not (OverworldBattle and type(OverworldBattle.update) == "function") then
    return false
  end
  -- Poll Android right-thumb look even though Gold's BattleState is on top.
  -- The live-world battle uses the same FirstPerson/ThirdPerson yaw/pitch as
  -- free roam, so steering here changes the camera the battle actually draws.
  local battleActive = false
  pcall(function() battleActive = OverworldBattle.shot() ~= nil or OverworldBattle.battle() ~= nil end)
  updateRightLookTouches(Bridge.game, battleActive)
  local ok, err = pcall(OverworldBattle.update, tonumber(dt) or (1 / 60))
  if not ok then
    Bridge.battleError = tostring(err)
    return false
  end
  return true
end

function Bridge.battleShot()
  if not (OverworldBattle and type(OverworldBattle.shot) == "function") then
    return nil
  end
  local ok, shot = pcall(OverworldBattle.shot)
  return ok and shot or nil
end

function Bridge.battleStage()
  if not (OverworldBattle and type(OverworldBattle.stage) == "function") then
    return nil
  end
  local ok, stage = pcall(OverworldBattle.stage)
  return ok and stage or nil
end

function Bridge.setExtraEntitiesProvider(fn)
  if fn ~= nil and type(fn) ~= "function" then
    return false, "extra entity provider must be a function or nil"
  end
  Bridge.extraEntitiesProvider = fn
  return true
end

function Bridge.status()
  return {
    installed = Bridge.installed,
    active = Bridge.active,
    mapId = Bridge.mapId,
    framesAttempted = Bridge.framesAttempted,
    frames3d = Bridge.frames3d,
    framesPending = Bridge.framesPending,
    framesFailed = Bridge.framesFailed,
    extraEntitiesProvider = type(Bridge.extraEntitiesProvider) == "function",
    extraEntitiesMerged = Bridge.extraEntitiesMerged,
    connectedMaps = V.goldNeighbors and #V.goldNeighbors or 0,
    openWorldNeighbors = true,
    syncBuildMapId = Bridge.syncBuildMapId,
    syncBuilds = Bridge.syncBuilds,
    syncBuildFailures = Bridge.syncBuildFailures,
    meshPendingFrames = Bridge.meshPendingFrames,
    cameraMode = Bridge.cameraMode,
    cameraLevel = Bridge.cameraLevel,
    cameraProvider = Bridge.cameraProvider,
    selectorDetected = Bridge.selectorDetected,
    externalCameraLevel = Bridge.externalCameraLevel,
    externalCameraLabel = Bridge.externalCameraLabel,
    cameraInputInstalled = Bridge.cameraInputInstalled,
    cameraInputError = Bridge.cameraInputError,
    pinchZoomInstalled = Bridge.pinchZoomInstalled,
    pinchZoomError = Bridge.pinchZoomError,
    cameraMovementInstalled = Bridge.cameraMovementInstalled,
    cameraMovementError = Bridge.cameraMovementError,
    cameraMovement = (GoldCameraControls and GoldCameraControls.status
      and GoldCameraControls.status()) or nil,
    cameraHotkeyCycles = Bridge.cameraHotkeyCycles,
    cameraHotkeyPollCycles = Bridge.cameraHotkeyPollCycles,
    f6Down = Bridge.f6Down,
    cameraSliderInstalled = Bridge.cameraSliderInstalled,
    cameraSliderTouches = Bridge.cameraSliderTouches,
    cameraSliderChanges = Bridge.cameraSliderChanges,
    platform = platformName(),
    battleInstalled = Bridge.battleInstalled,
    battleError = Bridge.battleError,
    battleActive = Bridge.battleShot() ~= nil,
    captureAvailable = Bridge.captureAvailable,
    captureError = Bridge.captureError,
    captureCameraOverride = Bridge.captureCameraOverride,
    capture = (OverworldCapture and OverworldCapture.status
      and OverworldCapture.status()) or nil,
    meshError = (ChunkMesher and type(ChunkMesher.lastError) == "function"
      and Bridge.mapId and ChunkMesher.lastError(Bridge.mapId)) or nil,
    lastError = Bridge.lastError,
  }
end

-- Test/diagnostic accessors; no engine mutation.
Bridge._mergedEntities = mergedEntities
Bridge._directNeighborSpecs = directNeighborSpecs
Bridge._adaptedNeighbors = adaptedNeighbors
Bridge._currentMasks = currentMasks
Bridge._makeState = makeState
Bridge._selectorCameraMode = selectorCameraMode
Bridge._externalCameraEnabled = externalCameraEnabled
Bridge._optionCameraControl = optionCameraControl

return Bridge
