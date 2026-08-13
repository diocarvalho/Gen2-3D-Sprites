-- Pokemon Stadium 2 Overworld Models - Gold/Silver (Generation 2)
--
-- Standalone Gen1Recomp Gold/Gen-2 graphics/gameplay mod. It embeds the Gen2 Dramatic Shapes
-- voxel renderer and the Wilds of Kanto roaming-Pokemon runtime, but contains no
-- Pokemon Stadium 2 ROM or ROM-derived model data. Models are built locally
-- from the player's own compatible Stadium 2 ROM.
local mod = ...

-- This package has its own Gen2-only mod id. Keep a runtime generation guard
-- anyway so accidentally enabling it on Red/Blue/Yellow fails closed.
local function gameGeneration()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  if ok and type(GameVersion) == "table" then
    if type(GameVersion.generation) == "function" then
      local okGen, generation = pcall(GameVersion.generation)
      if okGen and tonumber(generation) then return tonumber(generation) end
    end
    if type(GameVersion.isGen2) == "function" then
      local okGen2, yes = pcall(GameVersion.isGen2)
      if okGen2 and yes then return 2 end
    end
  end
  return 1
end

local function isGen2()
  return gameGeneration() == 2
end

local detectedGeneration = gameGeneration()
if detectedGeneration == 2 then
  mod.log:info("Gold/Silver standalone build: Pokemon Generation 2 detected; Stadium 2 importer targets National Dex 1-251")
else
  mod.log:warn("STADIUM2_OVERWORLD_MODELS requires Pokemon Gold or Silver. Active game reports Pokemon Generation %s; this Gen 2 port will stay inactive.", tostring(detectedGeneration))
  mod.exports.version = "0.2.35"
  mod.exports.targetGeneration = 2
  mod.exports.generation = detectedGeneration
  mod.exports.gen2Compatible = true
  mod.exports.stadium2Importer = true
  mod.exports.standaloneRenderer = true
  mod.exports.maxDex = 251
  mod.exports.active = false
  mod.exports.rendererInstalled = false
  mod.exports.rendererError = "Pokemon Gold/Silver (Generation 2) must be the active game"
  return
end

-- Wilds of Kanto's embedded entry returns an installer factory instead of
-- executing directly.  Run it against THIS mod object, capture the child's
-- public surface, then restore this package's Stadium exports.  v0.1.74 keeps
-- this definition in the top-level entry: an earlier direct-world refactor
-- accidentally deleted it while leaving the call site behind, which made the
-- mod abort late in main.lua after its Options UI had already been registered.
local function bootEmbeddedWilds()
  local source, readErr = mod:read("lib/EmbeddedWildsMain.lua")
  if not source then return nil, tostring(readErr or "embedded Wilds runtime is missing") end
  local loadcode = loadstring or load
  local chunk, compileErr = loadcode(source, "@" .. mod.path .. "/lib/EmbeddedWildsMain.lua")
  if not chunk then return nil, tostring(compileErr) end

  local okFactory, factory = pcall(chunk)
  if not okFactory then return nil, tostring(factory) end
  if type(factory) ~= "function" then
    return nil, "embedded Wilds entry did not return its installer function"
  end

  mod.exports = mod.exports or {}
  local before = {}
  for k, v in pairs(mod.exports) do before[k] = v end

  local okRun, runErr = pcall(factory, mod)
  if not okRun then
    for k in pairs(mod.exports) do mod.exports[k] = nil end
    for k, v in pairs(before) do mod.exports[k] = v end
    return nil, tostring(runErr)
  end

  local wilds = {}
  for k, v in pairs(mod.exports) do
    if before[k] ~= v then wilds[k] = v end
  end

  for k in pairs(mod.exports) do mod.exports[k] = nil end
  for k, v in pairs(before) do mod.exports[k] = v end

  if type(wilds.logic) ~= "table" or type(wilds.render) ~= "table" then
    return nil, "embedded Wilds runtime did not expose spawn logic/render services"
  end
  return wilds
end

-- Gold/Silver renderer bootstrap (v0.2.35: custom Stadium PACK/PKMN battle selectors; prior live-scene/controller/camera/Lugia fixes retained)
--
-- Current Gold exposes a supported whole-window `render.compose` hook.  The
-- embedded voxel bridge is now a renderer PROVIDER only; it does not patch any
-- Gen-2 World method and does not register the inert Gen-1 drawWorld pipeline.
-- GoldComposeBridge invokes it from the live Gold frame seam later below.
local function bootGoldVoxelBridge()
  local source, readErr = mod:read("lib/GoldVoxelBridge.lua")
  if not source then return nil, nil, tostring(readErr or "Gold voxel bridge is missing") end
  local chunk, compileErr = load(source, "@" .. mod.path .. "/lib/GoldVoxelBridge.lua")
  if not chunk then return nil, nil, tostring(compileErr) end
  local okLoad, Bridge = pcall(chunk, mod)
  if not okLoad then return nil, nil, tostring(Bridge) end
  if type(Bridge) ~= "table" or type(Bridge.install) ~= "function" then
    return nil, nil, "Gold voxel bridge did not expose install()"
  end
  local okInstall, installed, libOrErr = pcall(Bridge.install)
  if not okInstall then return nil, nil, tostring(installed) end
  if not installed then return nil, nil, tostring(libOrErr or "Gold voxel bridge install failed") end
  local lib = libOrErr or Bridge.lib
  if type(lib) ~= "table" or type(lib.require) ~= "function" then
    return nil, nil, "Gold voxel bridge did not expose its renderer module loader"
  end
  return Bridge, lib
end

local GoldVoxelBridge, BaseV, bridgeErr = bootGoldVoxelBridge()
local ds, dramaticShapeId
if GoldVoxelBridge and BaseV then
  ds = mod
  dramaticShapeId = "STADIUM2_GOLD_COMPOSE"
  mod.log:info("Gold/Silver voxel renderer provider loaded; official render.compose hook will own Gold world frames and redraw overlay UI above voxels")
else
  mod.log:error("Gold/Silver voxel renderer provider failed: %s", tostring(bridgeErr))
  mod.exports.version = "0.2.35"
  mod.exports.rendererInstalled = false
  mod.exports.rendererError = "Gold/Silver voxel renderer provider failed: " .. tostring(bridgeErr)
  mod.exports.hostDetected = false
  mod.exports.generation = gameGeneration()
  mod.exports.gen2Compatible = true
  mod.exports.targetGeneration = 2
  mod.exports.stadium2Importer = true
  mod.exports.standaloneRenderer = true
  mod.exports.maxDex = 251
  return
end

-- v0.1.89 is a Gen-2-only runtime. Legacy Yellow/Followers-EX glue was
-- intentionally removed; Gold's native party follower is installed below.

local function loadLocal(rel, arg)
  local source, readErr = mod:read(rel)
  assert(source, ("STADIUM2_OVERWORLD_MODELS: missing %s: %s")
    :format(rel, tostring(readErr)))
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  assert(chunk, ("STADIUM2_OVERWORLD_MODELS: %s did not compile: %s")
    :format(rel, tostring(err)))
  return chunk(arg)
end

-- Load our configuration first, then make a tiny namespace that delegates all
-- Dramatic Shape modules to Dramatic Shape while intercepting our own config.
local Config = loadLocal("lib/OverworldStadiumConfig.lua", BaseV)
local PokemonHeights = loadLocal("lib/PokemonHeights.lua", BaseV)
local PokemonLocomotion = loadLocal("lib/PokemonLocomotion.lua", BaseV)

-- Gold now exposes an engine-owned party-follower surface whose spawn gate is
-- opt-in for mods. Enable party slot #1 by default and let the native Gen-2
-- follower trail own movement, map seams, and NPC integration. The Stadium
-- renderer resolves the live party lead on that entity, so changing party order
-- changes the follower model without rebuilding the map.
local GoldPartyFollower = loadLocal("lib/GoldPartyFollower.lua", { mod = mod })
local goldPartyFollowerInstalled, goldPartyFollowerErr = GoldPartyFollower.install()
if goldPartyFollowerInstalled then
  mod.log:info("Gold party-slot-1 follower enabled through src.world.gen2.Follower")
else
  mod.log:warn("Gold party follower not installed: %s", tostring(goldPartyFollowerErr))
end

-- Put Stadium ROM selection inside THIS MOD'S Mod Manager -> Options screen.
-- The manifest also ships options.lua so the recomp mod manager exposes an OPTIONS button
-- for this mod.  StadiumRomMenu converts the STADIUM ROM FILE row into a real
-- Android file-picker action (A/Confirm, Left, or Right all open the system Files picker).
local RomMenuV = { require = BaseV.require }
local StadiumRomMenu = loadLocal("lib/StadiumRomMenu.lua", RomMenuV)
local managerOptionsInstalled = StadiumRomMenu.installModManagerOptions(mod)

-- Compatibility fallback only for much older builds without per-mod options.
-- On current builds this never runs, so the ROM row lives only under this
-- mod's own Options screen rather than the game's general OPTIONS menu.
if not managerOptionsInstalled then
  StadiumRomMenu.installOptionsHook(mod)
end

-- Gold voxel renderer status.  The `voxel3d` option is read inside
-- GoldVoxelBridge.renderFrame() on every compose frame; no engine class is
-- monkey-patched and src.render.Pipelines is untouched.
local voxelPipelineState = GoldVoxelBridge

-- Android may recreate the app while the native document picker is open.
-- Finish a pending Stadium selection as soon as the live Gold service owner is
-- ready.  Rendering itself is installed later through mod.hooks:wrap.
mod.events:on("game.ready", function(game)
  pcall(StadiumRomMenu.poll, game)
end)

mod.events:on("map.entered", function()
  if GoldVoxelBridge then GoldVoxelBridge.mapId = nil end
end)

-- Legacy Pokemon Yellow follower and Dramatic Sky Ride compatibility code
-- used Gen-1 `src.world.*` controllers and is not loaded in this Gold/Silver
-- package. Keeping it here only increased startup work and made the package
-- look less generation-specific, so v0.1.89 removes it.

local V = {
  mod = mod,
  path = mod.path,
  voxelHostId = dramaticShapeId,
}
setmetatable(V, { __index = BaseV })
function V.require(name)
  if name == "OverworldStadiumConfig" then return Config end
  if name == "PokemonHeights" then return PokemonHeights end
  if name == "PokemonLocomotion" then return PokemonLocomotion end
  if name == "BattleControllerUI" and V.BattleControllerUI then return V.BattleControllerUI end
  return BaseV.require(name)
end

local Stadium = loadLocal("lib/OverworldStadium.lua", V)
V.OverworldStadium = Stadium

-- Stage 1 battle performances: exact Stadium move animations when available,
-- entrance/faint animation, and a short victim recoil without touching damage
-- calculations or the engine's own move-effect graphics.
-- v0.2.29: direct control of the player's active Stadium 2 model during
-- Gold live-world battles. Left stick translates the presentation actor;
-- PlayStation Square / Xbox X plays an imported Stadium 2 attack clip.
local BattlePokemonControl = loadLocal("lib/BattlePokemonControl.lua", V)
-- v0.2.31 full controller-native live battle HUD. Gold still owns logic and
-- submenus, but its old 160x144 battle canvas is no longer composited during
-- the normal live 3D fight; this module draws HP/messages/commands/moves itself.
local BattleControllerUI = loadLocal("lib/BattleControllerUI.lua", V)
V.BattleControllerUI = BattleControllerUI
-- GoldVoxelBridge/VoxelScene were loaded before the Stadium namespace above and
-- retain BaseV as their module environment. Publish the UI on that shared table
-- too so the live renderer can resolve it without depending on the later
-- compositor or on a second module-loader namespace.
BaseV.BattleControllerUI = BattleControllerUI
mod.exports.battleControllerUI = BattleControllerUI
mod.events:on("game.ready", function(game)
  local ok, installed, err = pcall(BattleControllerUI.install, game)
  if not (ok and installed) then
    mod.log:warn("Battle controller UI input shortcuts not installed: %s",
                 tostring(ok and err or installed))
  end
end)

do
  local okS, StadiumControlHost = pcall(V.require, "Stadium")
  if okS and StadiumControlHost and type(StadiumControlHost.updateGen2) == "function"
      and not StadiumControlHost._directPokemonControlInstalled then
    local innerUpdateGen2 = StadiumControlHost.updateGen2
    StadiumControlHost.updateGen2 = function(dt, screen, groundY, ...)
      -- Keep battle input ownership refreshed every frame. This clears any
      -- stale native left-stick direction and provides a polled face-button
      -- fallback before the Stadium actor/camera are updated.
      pcall(BattleControllerUI.update)
      -- Apply stick motion before Stadium builds this frame's model matrix, so
      -- the actor and follow camera agree on the same position with no frame lag.
      pcall(BattlePokemonControl.update, dt, screen)
      return innerUpdateGen2(dt, screen, groundY, ...)
    end
    StadiumControlHost._directPokemonControlInstalled = true
  end
end

local BattleStadiumAnimations = loadLocal("lib/BattleStadiumAnimations.lua", V)
local battleAnimationsInstalled, battleAnimationsErr = BattleStadiumAnimations.install()
if battleAnimationsInstalled then
  mod.log:info("Pokemon Stadium Stage 1 battle performances enabled")
else
  mod.log:warn("Pokemon Stadium Stage 1 battle performances not installed: %s",
               tostring(battleAnimationsErr))
end

-- Phase 2 + Phase 3 + Phase 4 battle effects: common elemental families, dedicated
-- signature-move renderers, and safe visual hit-stop/shake/impact polish
-- drawn on the recomp engine's own move-animation layer. Dramatic Shape already maps
-- that layer onto the 3D arena, so this does not touch battle model lifecycle.
local BattleStadiumEffects = loadLocal("lib/BattleStadiumEffects.lua", V)
local battleEffectsInstalled, battleEffectsErr = BattleStadiumEffects.install()
if battleEffectsInstalled then
  mod.log:info("Pokemon Stadium Phase 2 + Phase 3 + Phase 4 battle presentation enabled")
else
  mod.log:warn("Pokemon Stadium Phase 2 + Phase 3 + Phase 4 battle presentation not installed: %s",
               tostring(battleEffectsErr))
end

-- Phase 5: real world-space procedural effects. This wraps Dramatic Shape's
-- exported Stadium begin/update/draw functions, so the particles are drawn
-- inside the active Voxel3D scene and follow camera orbit/depth naturally.
local BattleStadium3DFx = loadLocal("lib/BattleStadium3DFx.lua", V)
local battle3DInstalled, battle3DErr = BattleStadium3DFx.install()
if battle3DInstalled then
  mod.log:info("Pokemon Stadium Phase 5 world-space battle effects enabled")
else
  mod.log:warn("Pokemon Stadium Phase 5 world-space effects not installed: %s", tostring(battle3DErr))
end

-- Patch only structural seams in the exact VoxelScene source from the installed
-- Dramatic Shape build. Stadium operations are isolated per Pokemon, so one
-- bad model falls back to its own sprite without disabling the full overlay.
local VoxelScenePatch = loadLocal("lib/VoxelScenePatch.lua", V)
local rendererInstalled, rendererErr = VoxelScenePatch.install(ds, BaseV, V, Stadium)
if rendererInstalled then
  mod.log:info("Pokemon Stadium overworld renderer installed on current Dramatic Shape VoxelScene")
else
  mod.log:warn("Stadium overworld renderer not installed; Dramatic Shape voxel renderer preserved: %s",
               tostring(rendererErr))
end

-- Standalone roaming Pokemon.  Always boot the embedded, Gen-2-patched Wilds
-- runtime.  Do not let a separately installed Gen-1 Wilds build hijack this
-- package: independence means Gold uses the copy that was actually ported for
-- morning/day/night encounters and the Gen-2 world facade.
local wildsExports, wildsSource, wildsErr
wildsExports, wildsErr = bootEmbeddedWilds()
if wildsExports then
  wildsSource = "embedded"
  mod.log:info("Embedded Wilds of Kanto 1.12.2 Gen-2 roaming spawn runtime enabled")
else
  wildsSource = "failed"
  mod.log:warn("Embedded Wilds roaming spawn runtime failed; Stadium renderer remains available: %s",
               tostring(wildsErr))
end

-- v0.2.12: hold-to-aim overworld Poké Ball throw. Normal roaming-Pokemon
-- contact keeps Wilds' ordinary Gold battle path. While free-roaming the
-- capture module polls Gold's fixed-step input seam, so L2 / right mouse can
-- target a visible Pokemon in the camera cone and immediately throw before
-- contact. Any supported Gold Ball can be used; if prerequisites are missing,
-- the original Gold battle path remains unchanged.
local OverworldCapture, overworldCaptureInstalled, overworldCaptureErr
do
  local okCapture, captureOrErr = pcall(BaseV.require, "OverworldCapture")
  if okCapture and type(captureOrErr) == "table" then
    OverworldCapture = captureOrErr
    if wildsExports and type(wildsExports.logic) == "table"
       and type(OverworldCapture.install) == "function" then
      local okInstall, installed, err = pcall(OverworldCapture.install, wildsExports.logic)
      overworldCaptureInstalled = okInstall and installed ~= false
      if not overworldCaptureInstalled then
        overworldCaptureErr = tostring(okInstall and err or installed)
      end
    else
      overworldCaptureInstalled = false
      overworldCaptureErr = "visible Wilds runtime unavailable"
    end
  else
    overworldCaptureInstalled = false
    overworldCaptureErr = tostring(captureOrErr)
  end
end
if overworldCaptureInstalled then
  do
  local st = OverworldCapture and OverworldCapture.status and OverworldCapture.status() or {}
  mod.log:info("Overworld capture enabled (direct=%s manual=%s)",
               tostring(st.directHookInstalled), tostring(st.manualHookInstalled))
end
else
  mod.log:warn("Overworld capture minigame unavailable; normal battles preserved: %s",
               tostring(overworldCaptureErr))
end

-- Visible roaming Pokemon provider/fallback drawer.  This no longer patches
-- World:drawPeople; it stays independent from voxel and is consumed by the
-- supported Gold render.compose bridge below.
local GoldWildsBridge, goldWildsBridgeErr
if wildsExports then
  local source, readErr = mod:read("lib/GoldWildsBridge.lua")
  if source then
    local loadcode = loadstring or load
    local chunk, compileErr = loadcode(source,
      "@" .. mod.path .. "/lib/GoldWildsBridge.lua")
    if chunk then
      local okLoad, bridgeOrErr = pcall(chunk, mod, wildsExports)
      if okLoad and type(bridgeOrErr) == "table" then
        GoldWildsBridge = bridgeOrErr
        local okInstall, installErr = GoldWildsBridge.install()
        if not okInstall then
          goldWildsBridgeErr = tostring(installErr)
          GoldWildsBridge = nil
        end
      else
        goldWildsBridgeErr = tostring(bridgeOrErr)
      end
    else
      goldWildsBridgeErr = tostring(compileErr)
    end
  else
    goldWildsBridgeErr = tostring(readErr)
  end
  if GoldWildsBridge then
    mod.log:info("Gold visible-Wilds provider/fallback renderer ready")
  else
    mod.log:warn("Gold visible-Wilds provider failed: %s",
                 tostring(goldWildsBridgeErr))
  end
end

-- Feed the same visible roaming-Pokemon set into the voxel scene.  The Stadium
-- VoxelScene overlay can then replace those entities with their imported
-- Stadium 2 models; if voxel fails, GoldComposeBridge still draws their sprites.
if GoldVoxelBridge and GoldWildsBridge
   and type(GoldVoxelBridge.setExtraEntitiesProvider) == "function"
   and type(GoldWildsBridge.visibleEntities) == "function" then
  local okProvider, providerErr = GoldVoxelBridge.setExtraEntitiesProvider(function(world)
    return GoldWildsBridge.visibleEntities(world)
  end)
  if okProvider then
    mod.log:info("Gold visible-Wilds entities bridged into voxel/Stadium scene")
  else
    mod.log:warn("Gold Wilds voxel entity bridge failed: %s", tostring(providerErr))
  end
end

-- Official Gold frame hook.  This is the first v0.1.74 path that does NOT rely
-- on a Gen-1 pipeline or a Gen-2 class mutation.  Voxel gets first chance on a
-- free-roam frame.  When it is unavailable/pending/broken, the already-drawn
-- Gold scene is preserved and visible Wilds sprites are overlaid independently.
local GoldComposeBridge, goldComposeBridgeErr
do
  local source, readErr = mod:read("lib/GoldComposeBridge.lua")
  if source then
    local loadcode = loadstring or load
    local chunk, compileErr = loadcode(source,
      "@" .. mod.path .. "/lib/GoldComposeBridge.lua")
    if chunk then
      local okLoad, bridgeOrErr = pcall(chunk, mod, GoldVoxelBridge, GoldWildsBridge)
      if okLoad and type(bridgeOrErr) == "table" then
        GoldComposeBridge = bridgeOrErr
        local okInstall, installErr = GoldComposeBridge.install()
        if not okInstall then
          goldComposeBridgeErr = tostring(installErr)
          GoldComposeBridge = nil
        end
      else
        goldComposeBridgeErr = tostring(bridgeOrErr)
      end
    else
      goldComposeBridgeErr = tostring(compileErr)
    end
  else
    goldComposeBridgeErr = tostring(readErr)
  end
end
if GoldComposeBridge then
  mod.log:info("Gold render.compose integration enabled")
else
  mod.log:error("Gold render.compose integration failed: %s",
                tostring(goldComposeBridgeErr))
end

-- `game.ready` happens before a new Gold World necessarily exists, while
-- `map.entered` happens after the live map/people are built.  The embedded
-- Wilds event listener normally initializes there, but this idempotent repair
-- makes a current map visible even if event ordering differs across builds or
-- after a save reload.
local function ensureWildsCurrentMap(ev)
  if not (wildsExports and type(wildsExports.logic) == "table") then return end
  local worldApi = mod.world
  local ow = worldApi and worldApi.overworld and worldApi:overworld()
  local map = ow and ow.map
  local mapId = (ev and ev.mapId) or (map and map.id)
  if not mapId then return end

  local logic = wildsExports.logic
  local initialized = logic.state and logic.state.initialized == true
  if logic.activeMapId == mapId and initialized then return end
  if type(logic.onMapEntered) ~= "function" then return end

  local ok, err = pcall(logic.onMapEntered, logic, {
    mapId = mapId, map = map, via = "stadium2_gen2_bootstrap",
  })
  if not ok then
    mod.log:warn("Gold visible-Wilds map bootstrap failed: %s", tostring(err))
  end
end

mod.events:on("map.entered", ensureWildsCurrentMap)
mod.events:on("save.loaded", ensureWildsCurrentMap)
mod.events:on("game.ready", ensureWildsCurrentMap)
pcall(ensureWildsCurrentMap)

-- Gold/Silver can change land encounter slots with time of day. Rebuild the
-- embedded Wilds population when the engine announces a TOD transition so the
-- visible roster stays in lockstep with vanilla encounters.
if wildsExports and type(wildsExports.logic) == "table" then
  mod.events:on("world.tod_changed", function(ev)
    local logic = wildsExports.logic
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    local mapId = (ev and ev.mapId) or (ow and ow.map and ow.map.id)
    if mapId and logic.activeMapId == mapId
       and type(logic.onMapReloaded) == "function" then
      local okReload, reloadErr = pcall(logic.onMapReloaded, logic, { mapId = mapId })
      if not okReload then
        mod.log:warn("Wilds time-of-day refresh failed: %s", tostring(reloadErr))
      end
    end
  end)
end

-- Companion mods can tag a Pokemon entity explicitly through this mod.
mod.exports.version = "0.2.35"
mod.exports.overworld = Stadium
mod.exports.red3dPlayerCompat = true
mod.exports.red3dPlayerCompatStatus = function()
  local selector = mod.find and mod.find("red_3d_player") or nil
  local okPlayer, Player = pcall(require, "src.world.gen2.Player")
  local renderer = okPlayer and type(Player) == "table" and Player.red3dPlayerRenderer or nil
  local camera = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  return {
    selectorDetected = selector ~= nil,
    rendererReady = type(renderer) == "table" and type(renderer.drawVoxel) == "function",
    activeId = type(renderer) == "table" and renderer.activeId or nil,
    cameraProvider = camera and camera.cameraProvider or nil,
    externalCameraLabel = camera and camera.externalCameraLabel or nil,
    externalCameraLevel = camera and camera.externalCameraLevel or nil,
  }
end
mod.exports.romMenu = StadiumRomMenu
mod.exports.chooseStadiumRom = function(game)
  if game then return StadiumRomMenu.choose(game) end
  local okGame2, Game2 = pcall(require, "src.core.Game2")
  return StadiumRomMenu.choose(okGame2 and Game2 or nil)
end
mod.exports.tag = function(entity, speciesOrDex)
  return Stadium.tag(entity, speciesOrDex)
end
mod.exports.untag = function(entity)
  return Stadium.untag(entity)
end

mod.exports.active = true
mod.exports.hostDetected = true
mod.exports.hostId = dramaticShapeId
mod.exports.generation = gameGeneration()
mod.exports.gen2Compatible = true
mod.exports.targetGeneration = 2
mod.exports.stadium2Importer = true
mod.exports.standaloneRenderer = true
mod.exports.maxDex = 251
mod.exports.rendererInstalled = rendererInstalled
mod.exports.rendererError = rendererErr
mod.exports.voxelHostId = dramaticShapeId
mod.exports.voxelHostGeneration = 2
mod.exports.voxelPipelineState = voxelPipelineState
mod.exports.voxelDirectWorldHook = false
mod.exports.voxelComposeHook = GoldComposeBridge ~= nil
-- Legacy default target remains FULL/diorama level 1. v0.1.89 can select the
-- live first/third-person levels through GoldVoxelBridge without changing this
-- compatibility value expected by older diagnostics.
mod.exports.voxelTargetLevel = 1
mod.exports.voxelStatus = function()
  return GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
end
mod.exports.voxelCameraMode = function()
  local status = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  return status and status.cameraMode or "diorama"
end
mod.exports.voxelCameraLevel = function()
  local status = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  return status and status.cameraLevel or 1
end
mod.exports.cycleVoxelCamera = function()
  if GoldVoxelBridge and type(GoldVoxelBridge.cycleCameraMode) == "function" then
    return GoldVoxelBridge.cycleCameraMode(true)
  end
  return nil
end
mod.exports.partyFollower = GoldPartyFollower
mod.exports.partyFollowerStatus = function()
  return GoldPartyFollower and GoldPartyFollower.status and GoldPartyFollower.status() or {
    installed = false,
    error = goldPartyFollowerErr,
  }
end
mod.exports.inWorld3DBattles = true
mod.exports.inWorld3DBattleStatus = function()
  local voxel = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  local compose = GoldComposeBridge and GoldComposeBridge.status and GoldComposeBridge.status() or nil
  return {
    installed = voxel and voxel.battleInstalled or false,
    active = voxel and voxel.battleActive or false,
    error = (voxel and voxel.battleError) or (compose and compose.lastBattleError) or nil,
    frames = compose and compose.battleFrames or 0,
    fallbacks = compose and compose.battleFallbackFrames or 0,
  }
end
mod.exports.battlePokemonControl = BattlePokemonControl
mod.exports.battlePokemonControlStatus = function()
  return BattlePokemonControl and BattlePokemonControl.status and BattlePokemonControl.status() or nil
end
mod.exports.battleControllerUI = BattleControllerUI
mod.exports.battleControllerUIStatus = function()
  return BattleControllerUI and BattleControllerUI.status and BattleControllerUI.status() or nil
end
mod.exports.battleAnimationsInstalled = battleAnimationsInstalled
mod.exports.battleAnimationsError = battleAnimationsErr
mod.exports.battleEffectsInstalled = battleEffectsInstalled
mod.exports.battleEffectsError = battleEffectsErr

mod.exports.battle3DInstalled = battle3DInstalled
mod.exports.battle3DError = battle3DErr
mod.exports.lib = BaseV
mod.exports.wilds = wildsExports
mod.exports.overworldCaptureInstalled = overworldCaptureInstalled
mod.exports.overworldCaptureError = overworldCaptureErr
mod.exports.overworldCaptureStatus = function()
  return OverworldCapture and OverworldCapture.status and OverworldCapture.status() or {
    installed = false, error = overworldCaptureErr,
  }
end
mod.exports.wildSpawnsInstalled = wildsExports ~= nil
mod.exports.wildSpawnsSource = wildsSource
mod.exports.wildSpawnsError = wildsErr
mod.exports.goldWildsDrawBridgeInstalled = GoldWildsBridge ~= nil
mod.exports.goldWildsDrawBridgeError = goldWildsBridgeErr
mod.exports.goldWildsDrawBridgeStatus = function()
  return GoldWildsBridge and GoldWildsBridge.status and GoldWildsBridge.status() or nil
end
mod.exports.goldComposeBridgeInstalled = GoldComposeBridge ~= nil
mod.exports.goldComposeBridgeError = goldComposeBridgeErr
mod.exports.goldComposeBridgeStatus = function()
  return GoldComposeBridge and GoldComposeBridge.status and GoldComposeBridge.status() or nil
end
mod.exports.visibleWildsForced = true
mod.exports.entryCompleted = true
