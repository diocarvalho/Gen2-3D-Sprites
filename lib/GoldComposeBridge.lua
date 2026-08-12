-- Gold/Silver official render.compose bridge.
--
-- v0.1.74 fixes Gold's START/menu overlay path correctly.  Gen 2 Game2.lua
-- composites the overworld and stack UI into ONE scene canvas; unlike Gen 1,
-- it does not expose a separable worldOverride pass.  A voxel frame therefore
-- has to own the Gold compose window, then re-draw only the live Gold stack on
-- top using the exact transform Game2:drawScene() uses for overworld overlays.
--
-- This keeps the voxel overworld visible while START/dialog/menu overlays are
-- open without painting Gold's already-composited vanilla 2D world back over it.
local mod, VoxelBridge, WildsBridge = ...

local Bridge = {
  installed = false,
  frames = 0,
  worldFrames = 0,
  voxelFrames = 0,
  voxelOverlayFrames = 0,
  goldOverlayRedrawFrames = 0,
  goldOverlayStatesDrawn = 0,
  worldOverrideFrames = 0,
  legacyDirectFrames = 0,
  spriteFallbackFrames = 0,
  wildSpritesDrawn = 0,
  passthroughFrames = 0,
  battleFrames = 0,
  battleFallbackFrames = 0,
  lastVoxelError = nil,
  lastOverlayError = nil,
  lastWildError = nil,
}

local function resolveGame(host, ctx)
  -- Current Gold passes Game2 itself as the render.compose hook owner.  Prefer
  -- that object whenever generation==2 so its real stack/world are used.
  if type(host) == "table" and host.stack then
    if ctx and tonumber(ctx.generation) == 2 and host.world then return host end
    if host.world or host.overworld then return host end
  end

  -- Compatibility only: older experimental hosts may not pass Game2 directly.
  local ok2, Game2 = pcall(require, "src.core.Game2")
  if ok2 and type(Game2) == "table" and Game2.stack and Game2.world then
    return Game2
  end
  local ok1, Game = pcall(require, "src.core.Game")
  if ok1 and type(Game) == "table" then return Game end
  return nil
end

local function resolveWorld(game, host)
  local world = game and game.world
  if type(world) == "table" and world.map then return world end

  world = game and game.overworld
  if type(world) == "table" and world.map then return world end

  world = host and host.world
  if type(world) == "table" and world.map then return world end

  world = host and host.overworld
  if type(world) == "table" and world.map then return world end

  local api = mod.world
  if api and type(api.overworld) == "function" then
    local ok, publicWorld = pcall(api.overworld, api)
    if ok and type(publicWorld) == "table" and publicWorld.map then return publicWorld end
  end
  return nil
end

local function stackTop(game)
  local stack = game and game.stack
  if not stack or type(stack.top) ~= "function" then return nil end
  local ok, top = pcall(stack.top, stack)
  if ok then return top end
  return nil
end

local function drawCanvasFull(canvas, ctx)
  if not canvas then return false end
  local G = love.graphics
  local ww, wh = tonumber(ctx and ctx.ww), tonumber(ctx and ctx.wh)
  if not (ww and wh and ww > 0 and wh > 0) then ww, wh = G.getDimensions() end
  local cw, ch = canvas:getDimensions()
  if not (cw and ch and cw > 0 and ch > 0) then return false end
  G.setColor(1, 1, 1, 1)
  G.draw(canvas, 0, 0, 0, ww / cw, wh / ch)
  return true
end

local function installWorldOverride(host, ctx, canvas)
  -- Gen 1 / experimental compatibility only.  Current Gold Game2 deliberately
  -- has no setWorldOverride because worldCanvas and uiCanvas are the same scene.
  local renderer = (ctx and ctx.renderer)
    or (type(host) == "table" and host.setWorldOverride and host)
  if not (renderer and type(renderer.setWorldOverride) == "function") then
    return false
  end
  local ok = pcall(renderer.setWorldOverride, renderer, canvas)
  return ok and renderer.worldOverride ~= nil
end

local function goldOverlayStateCount(game)
  local stack = game and game.stack
  local states = stack and stack.states
  if type(states) ~= "table" or #states == 0 then return 0 end

  local base = 1
  if type(stack.visibleBase) == "function" then
    local ok, value = pcall(stack.visibleBase, stack)
    if ok and tonumber(value) then
      base = math.max(1, math.min(#states, math.floor(tonumber(value))))
    end
  end
  return math.max(0, #states - base + 1)
end

local function drawGoldOverlayStack(game, world, ctx)
  local stack = game and game.stack
  if not stackTop(game) then return true, 0 end
  if not (stack and type(stack.draw) == "function") then
    return false, 0, "Gold stack has no draw()"
  end
  if not (world and type(world.fitScale) == "function") then
    return false, 0, "Gold world has no fitScale()"
  end

  local ww, wh = tonumber(ctx and ctx.ww), tonumber(ctx and ctx.wh)
  if not (ww and wh and ww > 0 and wh > 0) then
    ww, wh = love.graphics.getDimensions()
  end

  local okScale, scale = pcall(world.fitScale, world)
  scale = okScale and tonumber(scale) or nil
  if not (scale and scale > 0) then
    return false, 0, "Gold world fitScale() returned an invalid scale"
  end

  -- Mirror Game2:drawScene's live-overworld overlay branch exactly:
  -- center a 160x144 UI at world:fitScale(), then draw the visible stack.
  local G = love.graphics
  local okDraw, drawErr = pcall(function()
    G.push("all")
    G.origin()
    G.translate(math.floor((ww - 160 * scale) / 2),
                math.floor((wh - 144 * scale) / 2))
    G.scale(scale, scale)
    stack:draw()
    G.pop()
  end)
  if not okDraw then
    -- pcall can catch an error after push() but before pop(); restore one level
    -- best-effort so the compose hook never leaves the engine in a poisoned state.
    pcall(G.pop)
    return false, 0, tostring(drawErr)
  end
  return true, goldOverlayStateCount(game)
end

local function drawGoldVoxelFrame(canvas, game, world, ctx)
  local G = love.graphics
  local ok, result, overlayCount, overlayErr = pcall(function()
    G.push("all")
    G.origin()
    if not drawCanvasFull(canvas, ctx) then
      G.pop()
      return false, 0, "voxel renderer returned an unusable canvas"
    end

    local okOverlay, count, err = drawGoldOverlayStack(game, world, ctx)
    G.pop()
    if not okOverlay then return false, 0, err end
    return true, count, nil
  end)

  if not ok then
    pcall(G.pop)
    return false, 0, tostring(result)
  end
  return result, overlayCount or 0, overlayErr
end

local function drawGoldBattleFrame(shot, ctx)
  local canvas = shot and shot.canvas
  local ui = ctx and ctx.sceneCanvas
  if not (canvas and ui) then return false end
  local G = love.graphics
  local ok, err = pcall(function()
    G.push("all")
    G.origin()
    if not drawCanvasFull(canvas, ctx) then error("unusable 3D battle canvas") end
    -- Game2's sceneCanvas is window-sized. Once BattleState has a 3D shot it
    -- clears the old white field to transparent and leaves only Gold's native
    -- battle UI/panels/animations in this texture.
    if not drawCanvasFull(ui, ctx) then error("unusable Gold battle UI canvas") end
    G.pop()
  end)
  if not ok then
    pcall(G.pop)
    Bridge.lastBattleError = tostring(err)
    return false
  end
  Bridge.lastBattleError = nil
  return true
end

local function compose(nextFn, host, ctx)
  Bridge.frames = Bridge.frames + 1

  -- Battle updates must run even though Game2 reports worldActive=false for an
  -- opaque BattleState. Bind the live Game2 owner and render the encounter-site
  -- shot before deciding whether this is a free-roam frame.
  local game = resolveGame(host, ctx)
  if VoxelBridge and type(VoxelBridge.setGame) == "function" then
    pcall(VoxelBridge.setGame, game)
  end
  if VoxelBridge and type(VoxelBridge.updateBattle) == "function" then
    pcall(VoxelBridge.updateBattle, 1 / 60)
  end
  if not (ctx and ctx.worldActive == true) and VoxelBridge
     and type(VoxelBridge.battleShot) == "function" then
    local okShot, shot = pcall(VoxelBridge.battleShot)
    if okShot and shot and shot.canvas then
      if drawGoldBattleFrame(shot, ctx) then
        Bridge.battleFrames = Bridge.battleFrames + 1
        return true
      end
      Bridge.battleFallbackFrames = Bridge.battleFallbackFrames + 1
    end
  end

  -- Game2 marks only its live overworld branch worldActive=true.  Opaque/full-
  -- screen Gold pages are already excluded by Game2 before this hook runs.
  if not (ctx and ctx.worldActive == true) then
    Bridge.passthroughFrames = Bridge.passthroughFrames + 1
    return nextFn(host, ctx)
  end

  local world = resolveWorld(game, host)
  if not (world and world.map) then
    Bridge.passthroughFrames = Bridge.passthroughFrames + 1
    return nextFn(host, ctx)
  end

  Bridge.worldFrames = Bridge.worldFrames + 1
  local isGold = tonumber(ctx.generation) == 2
  local hasOverlay = stackTop(game) ~= nil

  if VoxelBridge and type(VoxelBridge.renderFrame) == "function" then
    -- Hand the renderer the ACTUAL live Game2 owner. Gold's World is not a
    -- Gen-1 singleton, and first/third-person camera gates/input need the same
    -- stack object whose overlays are composited below.
    local okVoxel, canvas, voxelErr = pcall(VoxelBridge.renderFrame, world, ctx)
    if okVoxel and canvas then
      if isGold then
        -- Gold's sceneCanvas/worldCanvas/uiCanvas are the same finished texture.
        -- Own the compose frame, paint voxels first, then re-draw ONLY the stack
        -- UI at the same transform Game2 uses.  This is the v0.1.74 pause fix.
        local okFrame, overlayCount, overlayErr = drawGoldVoxelFrame(
          canvas, game, world, ctx)
        if okFrame then
          Bridge.voxelFrames = Bridge.voxelFrames + 1
          Bridge.legacyDirectFrames = Bridge.legacyDirectFrames + 1
          if hasOverlay then
            Bridge.voxelOverlayFrames = Bridge.voxelOverlayFrames + 1
            Bridge.goldOverlayRedrawFrames = Bridge.goldOverlayRedrawFrames + 1
            Bridge.goldOverlayStatesDrawn = Bridge.goldOverlayStatesDrawn
              + (tonumber(overlayCount) or 0)
          end
          Bridge.lastVoxelError = nil
          Bridge.lastOverlayError = nil
          return true
        end
        voxelErr = overlayErr or "Gold voxel/UI composite failed"
        Bridge.lastOverlayError = voxelErr
      else
        -- Gen 1 / experimental compatibility path where separate world + UI
        -- passes really do exist.
        if installWorldOverride(host, ctx, canvas) then
          Bridge.voxelFrames = Bridge.voxelFrames + 1
          Bridge.worldOverrideFrames = Bridge.worldOverrideFrames + 1
          if hasOverlay then Bridge.voxelOverlayFrames = Bridge.voxelOverlayFrames + 1 end
          Bridge.lastVoxelError = nil
          return nextFn(host, ctx)
        end
        if not hasOverlay and drawCanvasFull(canvas, ctx) then
          Bridge.voxelFrames = Bridge.voxelFrames + 1
          Bridge.legacyDirectFrames = Bridge.legacyDirectFrames + 1
          Bridge.lastVoxelError = nil
          return true
        end
        voxelErr = hasOverlay
          and "legacy compose API cannot preserve UI over direct voxel canvas"
          or "voxel renderer returned an unusable canvas"
      end
    elseif not okVoxel then
      voxelErr = tostring(canvas)
    end
    Bridge.lastVoxelError = voxelErr
  end

  -- If voxel rendering is unavailable, preserve Gold's already-composited scene
  -- and the existing visible-Wilds sprite fallback behavior.
  local visible = WildsBridge and type(WildsBridge.visibleEntities) == "function"
    and WildsBridge.visibleEntities(world) or {}
  if type(visible) == "table" and #visible > 0
     and ctx.sceneCanvas and WildsBridge
     and type(WildsBridge.drawFallback) == "function" then
    drawCanvasFull(ctx.sceneCanvas, ctx)
    local okWild, drawn, wildErr = pcall(WildsBridge.drawFallback, world)
    if okWild then
      Bridge.spriteFallbackFrames = Bridge.spriteFallbackFrames + 1
      Bridge.wildSpritesDrawn = Bridge.wildSpritesDrawn + (tonumber(drawn) or 0)
      Bridge.lastWildError = wildErr
    else
      Bridge.lastWildError = tostring(drawn)
    end
    return true
  end

  Bridge.passthroughFrames = Bridge.passthroughFrames + 1
  return nextFn(host, ctx)
end

function Bridge.install()
  if Bridge.installed then return true end
  if not (mod.hooks and type(mod.hooks.wrap) == "function") then
    return false, "mod.hooks:wrap is unavailable"
  end
  local ok, err = pcall(function()
    mod.hooks:wrap("render.compose", compose, 1000)
  end)
  if not ok then return false, tostring(err) end
  Bridge.installed = true
  if mod.log and type(mod.log.info) == "function" then
    pcall(mod.log.info, mod.log,
      "Gold render.compose bridge installed (voxel + Gold overlay-stack redraw)")
  end
  return true
end

function Bridge.status()
  return {
    installed = Bridge.installed,
    frames = Bridge.frames,
    worldFrames = Bridge.worldFrames,
    voxelFrames = Bridge.voxelFrames,
    voxelOverlayFrames = Bridge.voxelOverlayFrames,
    goldOverlayRedrawFrames = Bridge.goldOverlayRedrawFrames,
    goldOverlayStatesDrawn = Bridge.goldOverlayStatesDrawn,
    worldOverrideFrames = Bridge.worldOverrideFrames,
    legacyDirectFrames = Bridge.legacyDirectFrames,
    spriteFallbackFrames = Bridge.spriteFallbackFrames,
    wildSpritesDrawn = Bridge.wildSpritesDrawn,
    battleFrames = Bridge.battleFrames,
    battleFallbackFrames = Bridge.battleFallbackFrames,
    passthroughFrames = Bridge.passthroughFrames,
    lastVoxelError = Bridge.lastVoxelError,
    lastOverlayError = Bridge.lastOverlayError,
    lastWildError = Bridge.lastWildError,
    lastBattleError = Bridge.lastBattleError,
  }
end

Bridge._compose = compose
return Bridge
