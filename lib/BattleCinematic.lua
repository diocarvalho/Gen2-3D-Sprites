-- Stadium-style cinematic orbit camera for Gold live-overworld battles.
-- It frames both combatants in the actual encounter world, eases between
-- menu/attack framing, and yields temporarily to manual look input.
local V = ...
local FirstPerson = V.require("FirstPerson")

local BattleCinematic = {}

BattleCinematic.enabled = true
BattleCinematic.angle = nil
BattleCinematic.radius = 96
BattleCinematic.height = 48
BattleCinematic.manualHold = 0
BattleCinematic.manualPitch = 0
BattleCinematic.lastActive = false
BattleCinematic.t = 0
BattleCinematic.focusX = nil
BattleCinematic.focusZ = nil
BattleCinematic.activeSide = nil

local TAU = math.pi * 2
local function wrap(a)
  a = (a or 0) % TAU
  if a < 0 then a = a + TAU end
  return a
end
local function approach(a, b, k)
  return a + (b - a) * math.max(0, math.min(1, k))
end

local function approachAngle(a, b, k)
  local d = ((b - a + math.pi) % TAU) - math.pi
  return wrap(a + d * math.max(0, math.min(1, k)))
end

local function eventActiveSide(screen)
  if type(screen) ~= "table" then return nil end
  -- During a real move animation Gold exposes the attacker through hudSide.
  -- Treat `anim` as opaque unless it is a table: older/newer engine builds can
  -- legitimately use a falsey/sentinel value while changing animation phases.
  local anim = type(screen.anim) == "table" and screen.anim or nil
  if anim and anim.clearsHud
      and (anim.hudSide == "player" or anim.hudSide == "enemy") then
    return anim.hudSide
  end
  -- OverworldBattle's tiny advanceQueue observer keeps the acting side alive
  -- through the rest of the same resolving turn (damage text / HP drain).
  if screen.phase == "resolving"
      and (screen._stadiumActiveSide == "player" or screen._stadiumActiveSide == "enemy") then
    return screen._stadiumActiveSide
  end
  return nil
end

local function settingOn()
  local mod = V.mod
  if mod and mod.options and type(mod.options.get) == "function" then
    local ok, v = pcall(mod.options.get, mod.options, "battleSmartCamera")
    if ok and v ~= nil then
      return not (v == false or v == 0 or v == "0" or v == "false" or v == "off")
    end
  end
  return true
end

function BattleCinematic.reset()
  BattleCinematic.angle = nil
  BattleCinematic.radius = 96
  BattleCinematic.height = 48
  BattleCinematic.manualHold = 0
  BattleCinematic.manualPitch = 0
  BattleCinematic.t = 0
BattleCinematic.focusX = nil
BattleCinematic.focusZ = nil
BattleCinematic.activeSide = nil
  BattleCinematic.lastActive = false
end

function BattleCinematic.manualLook(dyaw, dpitch)
  BattleCinematic.angle = wrap((BattleCinematic.angle or FirstPerson.yaw or 0) - (tonumber(dyaw) or 0))
  BattleCinematic.manualPitch = math.max(-0.55, math.min(0.55,
    BattleCinematic.manualPitch + (tonumber(dpitch) or 0)))
  BattleCinematic.manualHold = 2.5
  return true
end

function BattleCinematic.manualActive()
  return BattleCinematic.manualHold > 0
end

-- Returns placed camera, centre x/z when a Gold live-world battle is active.
local function frameImpl(dt)
  if not settingOn() then
    BattleCinematic.lastActive = false
    return nil
  end
  local ok, OverworldBattle = pcall(V.require, "OverworldBattle")
  if not ok or not OverworldBattle or type(OverworldBattle.cameraContext) ~= "function" then
    return nil
  end
  local ctx = OverworldBattle.cameraContext()
  if not ctx or not ctx.arena then
    if BattleCinematic.lastActive then BattleCinematic.reset() end
    return nil
  end

  local arena = ctx.arena
  local p, e = arena.player, arena.enemy
  if not (type(p) == "table" and type(e) == "table") then return nil end
  local px, pz = tonumber(p[1]), tonumber(p[2])
  local ex, ez = tonumber(e[1]), tonumber(e[2])
  if not (px and pz and ex and ez) then return nil end
  -- Work only with validated numeric coordinates from this point onward.
  p, e = { px, pz }, { ex, ez }
  local cx = arena.mid and tonumber(arena.mid[1]) or ((px + ex) * 0.5)
  local cz = arena.mid and tonumber(arena.mid[2]) or ((pz + ez) * 0.5)
  if not (cx and cz) then
    cx, cz = (px + ex) * 0.5, (pz + ez) * 0.5
  end
  local gy = tonumber(ctx.groundY) or 0
  local screen = ctx.screen
  local attack = screen and screen.anim ~= nil
  local resolving = screen and screen.phase == "resolving"
  local activeSide = eventActiveSide(screen)

  dt = math.max(0, math.min(0.1, tonumber(dt) or 1/60))
  BattleCinematic.t = BattleCinematic.t + dt
  if not BattleCinematic.angle then
    -- Start behind the player's side, offset enough to read both models.
    local dx, dz = e[1] - p[1], e[2] - p[2]
    BattleCinematic.angle = wrap(math.atan2(-dx, -dz) + 0.65)
  end

  if BattleCinematic.manualHold > 0 then
    BattleCinematic.manualHold = math.max(0, BattleCinematic.manualHold - dt)
  else
    if activeSide then
      -- Stadium-style shoulder shot: stay mostly behind and to the side of the
      -- Pokemon whose turn is currently playing, rather than orbiting both
      -- combatants evenly. A very small drift keeps the frame alive.
      local actor = activeSide == "player" and p or e
      local other = activeSide == "player" and e or p
      local dx, dz = other[1] - actor[1], other[2] - actor[2]
      local len = math.sqrt(dx * dx + dz * dz)
      if len < 0.001 then len = 1 end
      local ux, uz = dx / len, dz / len
      local px2, pz2 = -uz, ux
      local sideSign = activeSide == "player" and 1 or -1
      local bx = -ux + px2 * 0.48 * sideSign
      local bz = -uz + pz2 * 0.48 * sideSign
      local targetAngle = wrap(math.atan2(bx, bz) + math.sin(BattleCinematic.t * 0.72) * 0.10)
      BattleCinematic.angle = approachAngle(BattleCinematic.angle, targetAngle, dt * 2.0)
    else
      -- Between turns/menu selection, widen back out and resume the slow orbit.
      local speed = resolving and 0.12 or 0.085
      BattleCinematic.angle = wrap(BattleCinematic.angle + speed * dt)
    end
    BattleCinematic.manualPitch = approach(BattleCinematic.manualPitch, 0, dt * 0.9)
  end

  -- Active-turn shots push closer; menu/inter-turn shots leave more breathing room.
  local wantRadius = activeSide and (attack and 69 or 76) or (resolving and 88 or 100)
  local wantHeight = activeSide and (attack and 35 or 40) or 48
  BattleCinematic.radius = approach(BattleCinematic.radius, wantRadius, dt * 2.8)
  BattleCinematic.height = approach(BattleCinematic.height, wantHeight, dt * 2.8)

  -- Focus strongly favors the active Pokemon while retaining enough of the
  -- opponent's side to read the exchange. Between turns it eases to midpoint.
  local wantFx, wantFz = cx, cz
  if activeSide then
    local actor = activeSide == "player" and p or e
    local other = activeSide == "player" and e or p
    local actorWeight = attack and 0.82 or 0.74
    wantFx = actor[1] * actorWeight + other[1] * (1 - actorWeight)
    wantFz = actor[2] * actorWeight + other[2] * (1 - actorWeight)
  end
  BattleCinematic.focusX = approach(BattleCinematic.focusX or cx, wantFx, dt * 3.2)
  BattleCinematic.focusZ = approach(BattleCinematic.focusZ or cz, wantFz, dt * 3.2)
  BattleCinematic.activeSide = activeSide

  local a = BattleCinematic.angle
  local r = BattleCinematic.radius
  local fx, fz = BattleCinematic.focusX, BattleCinematic.focusZ
  local eyeY = gy + BattleCinematic.height + BattleCinematic.manualPitch * 42
  local eye = { fx + math.sin(a) * r, eyeY, fz + math.cos(a) * r }
  local focus = { fx, gy + 12, fz }
  local cam = {
    eye = eye,
    focus = focus,
    up = { 0, 1, 0 },
    fov = math.rad(55),
    curve = 0,
    _stadiumBattleCinematic = true,
  }
  BattleCinematic.lastActive = true
  return cam, cx, cz
end

-- A presentation camera must never be able to take the game down. Gen1Recomp
-- battle internals are intentionally allowed to evolve, so keep the entire
-- optional cinematic behind one pcall. If a future/older BattleState exposes
-- a shape we did not expect, the live-world battle simply uses the ordinary
-- overworld camera for that frame and gameplay continues.
function BattleCinematic.frame(dt)
  local ok, cam, cx, cz = pcall(frameImpl, dt)
  if ok then return cam, cx, cz end

  if not BattleCinematic._errorLogged then
    BattleCinematic._errorLogged = true
    pcall(function()
      if V.mod and V.mod.log and type(V.mod.log.warn) == "function" then
        V.mod.log:warn("Stadium battle camera disabled after recoverable error: %s",
                       tostring(cam))
      end
    end)
  end
  BattleCinematic.reset()
  return nil
end

return BattleCinematic
