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
  cameraInputInstalled = false,
  cameraInputError = nil,
  cameraMovementInstalled = false,
  cameraMovementError = nil,
  cameraOverride = nil,
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

local Voxel, Voxel3D, VoxelScene, ChunkMesher, FirstPerson, GoldCameraControls
local OverworldBattle
local logOnce

local function optionEnabled()
  local ok, value = pcall(mod.options.get, mod.options, "voxel3d")
  if not ok or value == nil then return true end
  return not (value == false or value == 0 or value == "0"
    or value == "false" or value == "off")
end

local CAMERA_ORDER = { "diorama", "third", "first" }
local CAMERA_NEXT = { diorama = "third", third = "first", first = "diorama" }

local function normalizeCameraMode(value)
  value = type(value) == "string" and value:lower() or value
  if value == "third" or value == "third_person" or value == "3rd" then
    return "third"
  elseif value == "first" or value == "first_person" or value == "1st" then
    return "first"
  end
  return "diorama"
end

local function optionCameraMode()
  if Bridge.cameraOverride then return normalizeCameraMode(Bridge.cameraOverride) end
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

function Bridge.cycleCameraMode(persist)
  local current = optionCameraMode()
  return setCameraMode(CAMERA_NEXT[current] or CAMERA_ORDER[1], persist ~= false)
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
  return type(world) == "table" and world.map ~= nil and stackTop(game) == nil
end

local function installCameraHotkey(game)
  if type(game) ~= "table" then return false end
  if Bridge._hotkeyGame == game then return true end
  if Bridge._hotkeyGame ~= nil then return false end

  local inner = game.keypressed
  game.keypressed = function(self, key, ...)
    if key == "f6" and optionEnabled() and goldFreeRoam(self) then
      local mode = Bridge.cycleCameraMode(true)
      Bridge.cameraHotkeyCycles = Bridge.cameraHotkeyCycles + 1
      local log = mod.log
      if log and type(log.info) == "function" then
        pcall(log.info, log, "Gold voxel camera: %s", tostring(mode))
      end
      return
    end
    if inner then return inner(self, key, ...) end
  end
  Bridge._hotkeyGame = game
  return true
end

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
  map.renderer.image = atlas
  map.renderer.gbcAtlas = false
  map.renderer.data = (world.game and world.game.data) or map.renderer.data
  return true
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
  return {
    map = world.map,
    camera = world.camera,
    player = world.player,
    entities = mergedEntities(world),
    -- Connected-map rows in Gold are baked-image records, not Gen-1 Map
    -- objects.  The current map is enough to prove/render the voxel host; do
    -- not poison the scene with incompatible neighbour records.
    neighbors = {},
    ghosts = {},
    flyAnim = world.flyAnim,
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

  local ok, a, b, c, d, e, f = pcall(function()
    return V.require("VoxelState"), V.require("Voxel3D"),
      V.require("VoxelScene"), V.require("ChunkMesher"),
      V.require("FirstPerson"), V.require("GoldCameraControls")
  end)
  if not ok then return false, tostring(a) end
  Voxel, Voxel3D, VoxelScene, ChunkMesher, FirstPerson, GoldCameraControls =
    a, b, c, d, e, f

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
    local okPrime, primeMeshOrErr = pcall(ChunkMesher.get, state.map, false, {})
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
    local mode = optionCameraMode()
    local level = cameraLevelForMode(mode)
    local dt = frameDt()
    Bridge.cameraMode, Bridge.cameraLevel = mode, level

    -- DIORAMA keeps the proven v0.1.78 camera. FIRST and THIRD select the
    -- already-authored placed-camera rungs, now driven by Gold's live Game2.
    Voxel.setLevel(level)
    if type(Voxel.update) == "function" then Voxel.update(dt, level) end
    if FirstPerson and type(FirstPerson.update) == "function" then
      FirstPerson.update(dt)
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
    syncBuildMapId = Bridge.syncBuildMapId,
    syncBuilds = Bridge.syncBuilds,
    syncBuildFailures = Bridge.syncBuildFailures,
    meshPendingFrames = Bridge.meshPendingFrames,
    cameraMode = Bridge.cameraMode,
    cameraLevel = Bridge.cameraLevel,
    cameraInputInstalled = Bridge.cameraInputInstalled,
    cameraInputError = Bridge.cameraInputError,
    cameraMovementInstalled = Bridge.cameraMovementInstalled,
    cameraMovementError = Bridge.cameraMovementError,
    cameraMovement = (GoldCameraControls and GoldCameraControls.status
      and GoldCameraControls.status()) or nil,
    cameraHotkeyCycles = Bridge.cameraHotkeyCycles,
    battleInstalled = Bridge.battleInstalled,
    battleError = Bridge.battleError,
    battleActive = Bridge.battleShot() ~= nil,
    meshError = (ChunkMesher and type(ChunkMesher.lastError) == "function"
      and Bridge.mapId and ChunkMesher.lastError(Bridge.mapId)) or nil,
    lastError = Bridge.lastError,
  }
end

-- Test/diagnostic accessors; no engine mutation.
Bridge._mergedEntities = mergedEntities
Bridge._makeState = makeState

return Bridge
