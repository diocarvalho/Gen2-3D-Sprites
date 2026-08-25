-- v0.3.56 Kanto third-person presentation-state isolation parity.
--
-- Kanto is rendered with a presentation-local player proxy while the real Gold
-- player/world stays resident in Johto.  Character Selector stores both its
-- special-card decision and retained travel-facing state on that real Player.
-- This regression makes sure Kanto owns those presentation values only during
-- its draw, then restores Johto exactly.

local root = (... and ... ~= "") and ... or "."

local stubs = {
  StadiumMon = { FPS = 30 },
  StadiumPack = { KEEP = 4, FPS = 30 },
  Mat4 = {},
  OverworldStadiumConfig = { enabled = false },
  PokemonHeights = {},
  PokemonLocomotion = {},
  FirstPerson = {},
}

local renderer = {
  failed = false,
  drawVoxel = function() return true end,
}

local oldLoaded = package.loaded["src.world.gen2.Player"]
local oldPreload = package.preload["src.world.gen2.Player"]
package.loaded["src.world.gen2.Player"] = nil
package.preload["src.world.gen2.Player"] = function()
  return { red3dPlayerRenderer = renderer }
end

local V = {
  mod = { log = { warn = function() end } },
  require = function(name) return stubs[name] or {} end,
  modelsEnabled = function() return true end,
  playerModelsEnabled = function() return true end,
}

local chunk = assert(loadfile(root .. "/lib/OverworldStadium.lua"))
local Stadium = chunk(V)
assert(type(Stadium._withFreeVisualWalk) == "function")
assert(type(Stadium._kantoProxySpecialCard) == "function")
assert(type(Stadium._red3dRendererForPose) == "function")

local source = {
  moving = false,
  facing = "down",
  px = 8, py = 16,
  cellX = 1, cellY = 2,
  -- Hidden Johto is deliberately in a completely different presentation state.
  surfing = true,
  onBike = true,
  biking = true,
  fishing = true,
  red3dFreeBodyYaw = 2.5,
  red3dLastWorldX = 999,
  red3dLastWorldZ = 888,
  red3dProjectedBodyYaw = -2.0,
}

local proxy = {
  _stadiumSourcePlayer = source,
  _stadiumGen1Excursion = true,
  moving = true,
  facing = "right",
  px = 100, py = 200,
  cellX = 6, cellY = 12,
  surfing = false,
  onBike = false,
  biking = false,
  fishing = false,
  animClock = 7,
}

local pose = {
  entity = proxy,
  isPlayer = true,
  facing = "right",
  px = 100,
  py = 200,
  stadiumVisualMoving = true,
  stadiumMoveWorldX = 1,
  stadiumMoveWorldZ = 0,
}

-- The visible Kanto state wins over hidden Johto's Surf/Bike/Fishing state.
assert(Stadium._kantoProxySpecialCard(proxy) == false)
assert(Stadium._red3dRendererForPose(pose) == renderer,
  "hidden Johto special-card state must not suppress the Kanto 3D player")

proxy.onBike = true
assert(Stadium._kantoProxySpecialCard(proxy) == true)
assert(Stadium._red3dRendererForPose(pose) == nil,
  "Kanto Bicycle must hand presentation back to the authored bike card")
proxy.onBike = false
proxy.biking = true
assert(Stadium._red3dRendererForPose(pose) == nil)
proxy.biking = false
proxy.surfing = true
assert(Stadium._red3dRendererForPose(pose) == nil,
  "Kanto Surf must hand presentation back to the authored special card")
proxy.surfing = false
proxy.fishing = true
assert(Stadium._red3dRendererForPose(pose) == nil)
proxy.fishing = false

-- Ordinary Johto still follows the existing special-card decision.
assert(Stadium._red3dRendererForPose({ entity = source, isPlayer = true }) == nil,
  "Johto fishing must continue to suppress the 3D trainer")

-- A Kanto draw receives Kanto mount flags and a Kanto-local yaw baseline. The
-- huge Johto coordinates must never look like one giant Kanto movement sample.
local first
local ok, result = Stadium._withFreeVisualWalk(pose, function()
  first = {
    surfing = source.surfing,
    onBike = source.onBike,
    biking = source.biking,
    fishing = source.fishing,
    yaw = source.red3dFreeBodyYaw,
    lastX = source.red3dLastWorldX,
    lastZ = source.red3dLastWorldZ,
  }
  -- Emulate Character Selector voxelModelMatrix consuming real Kanto travel.
  source.red3dFreeBodyYaw = 1.234
  source.red3dLastWorldX = pose.px
  source.red3dLastWorldZ = pose.py
  source.red3dProjectedBodyYaw = 1.234
  return "drawn"
end)
assert(ok and result == "drawn")
assert(first.surfing == false and first.onBike == false
  and first.biking == false and first.fishing == false,
  "render call must see visible Kanto special-card state")
assert(first.lastX == 100 and first.lastZ == 200,
  "first Kanto frame must rebase travel sampling at the Kanto position")
assert(math.abs(first.yaw - math.pi / 2) < 1e-6,
  "first Kanto yaw should seed from the visible rightward travel vector")

-- Kanto-facing continuity is retained on the proxy, not on Gold.
assert(math.abs(proxy._stadiumRed3dFreeBodyYaw - 1.234) < 1e-9)
assert(proxy._stadiumRed3dLastWorldX == 100)
assert(proxy._stadiumRed3dLastWorldZ == 200)

-- Every Johto field is restored byte-for-byte after the render-only bridge.
assert(source.surfing == true and source.onBike == true
  and source.biking == true and source.fishing == true)
assert(source.red3dFreeBodyYaw == 2.5)
assert(source.red3dLastWorldX == 999 and source.red3dLastWorldZ == 888)
assert(source.red3dProjectedBodyYaw == -2.0)

-- Even if the hidden Johto renderer changes its own retained yaw between Kanto
-- passes, the next Kanto draw resumes from Kanto's last sample/yaw.
source.red3dFreeBodyYaw = -2.75
source.red3dLastWorldX = -500
source.red3dLastWorldZ = -600
source.red3dProjectedBodyYaw = -1.5
pose.px = 104
pose.py = 200
proxy.px = 104
proxy.py = 200
local second
assert(Stadium._withFreeVisualWalk(pose, function()
  second = {
    yaw = source.red3dFreeBodyYaw,
    lastX = source.red3dLastWorldX,
    lastZ = source.red3dLastWorldZ,
  }
  return true
end))
assert(math.abs(second.yaw - 1.234) < 1e-9)
assert(second.lastX == 100 and second.lastZ == 200,
  "Kanto must retain its own previous world sample across hidden Johto draws")
assert(source.red3dFreeBodyYaw == -2.75)
assert(source.red3dLastWorldX == -500 and source.red3dLastWorldZ == -600)
assert(source.red3dProjectedBodyYaw == -1.5)

-- An explicit idle Kanto facing change (interaction/warp) is a real
-- turn-in-place, unlike merely orbiting the third-person camera.
pose.stadiumVisualMoving = false
pose.stadiumMoveWorldX, pose.stadiumMoveWorldZ = 0, 0
proxy.moving = false
proxy.facing = "up"
pose.facing = "up"
local turned
assert(Stadium._withFreeVisualWalk(pose, function()
  turned = { yaw = source.red3dFreeBodyYaw, x = source.red3dLastWorldX, z = source.red3dLastWorldZ }
  return true
end))
assert(math.abs(turned.yaw - math.pi) < 1e-6,
  "idle Kanto facing change must rotate the retained 3D body yaw")
assert(turned.x == 104 and turned.z == 200,
  "turn-in-place must rebase the Kanto travel sample at the standing position")
assert(source.red3dFreeBodyYaw == -2.75 and source.red3dLastWorldX == -500,
  "turn-in-place must still restore hidden Johto presentation state")

package.loaded["src.world.gen2.Player"] = oldLoaded
package.preload["src.world.gen2.Player"] = oldPreload

print("kanto_third_person_transition_parity: OK")
