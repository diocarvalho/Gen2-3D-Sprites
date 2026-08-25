-- v0.3.55 Kanto third-person player-model animation parity.
--
-- Character Selector v3.x caches its skinned voxel pose in beginVoxelFrame().
-- Kanto renders a presentation-local proxy while the real Gold player remains
-- in Johto.  The bridge must refresh the selector from that proxy before
-- drawVoxel()/drawVoxelShadow(), while restoring every gameplay-facing field.

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

local V = {
  mod = { log = { warn = function() end } },
  require = function(name) return stubs[name] or {} end,
  modelsEnabled = function() return true end,
  playerModelsEnabled = function() return true end,
}

local chunk = assert(loadfile(root .. "/lib/OverworldStadium.lua"))
local Stadium = chunk(V)
assert(type(Stadium) == "table")
assert(type(Stadium._refreshKantoPlayerSkinAnimation) == "function")

local source = {
  moving = false,
  facing = "down",
  stepFlip = false,
  animClock = 2,
  progress = 3,
  targetX = nil,
  targetY = nil,
  stepFrames = 8,
  jumping = false,
  hopFrames = nil,
  red3dMoveStickX = 0.1,
  red3dMoveStickY = 0.2,
  red3dAnalogMoveActive = false,
  px = 8,
  py = 16,
  cellX = 1,
  cellY = 2,
}

local proxy = {
  _stadiumSourcePlayer = source,
  _stadiumGen1Excursion = true,
  moving = true,
  facing = "right",
  stepFlip = true,
  animClock = 9,
  jumping = true,
  hopping = true,
  hopFrames = 17,
  px = 104,
  py = 200,
  cellX = 6,
  cellY = 12,
}

local pose = {
  entity = proxy,
  isPlayer = true,
  facing = "right",
  px = 104,
  py = 200,
  phase = nil,
  flip = false,
  stadiumVisualMoving = true,
  stadiumVisualAnimDist = 7.5,
  stadiumMoveWorldX = 0.6,
  stadiumMoveWorldZ = 0.8,
}

local seen = {}
local calls = 0
local renderer = {
  voxelFrameKey = "hidden-johto-idle",
  voxelUploadedKey = "hidden-johto-idle",
  beginVoxelFrame = function(self, player, p)
    calls = calls + 1
    assert(player == source, "selector must keep the original Gold player identity")
    assert(p == pose, "selector must receive the visible Kanto pose")
    seen[calls] = {
      moving = player.moving,
      facing = player.facing,
      progress = player.progress,
      stepFrames = player.stepFrames,
      targetX = player.targetX,
      targetY = player.targetY,
      jumping = player.jumping,
      hopFrames = player.hopFrames,
      stickX = player.red3dMoveStickX,
      stickY = player.red3dMoveStickY,
      analog = player.red3dAnalogMoveActive,
      px = player.px,
      py = player.py,
      cellX = player.cellX,
      cellY = player.cellY,
    }
    self.voxelFrameKey = "kanto-walk-" .. tostring(calls)
  end,
}

assert(Stadium._refreshKantoPlayerSkinAnimation(pose, renderer) == true)
assert(calls == 1, "first Kanto draw must refresh the selector frame")
local first = seen[1]
assert(first.moving == true)
assert(first.facing == "right")
assert(first.progress == 9, "Kanto animClock must become native 16-frame progress")
assert(first.stepFrames == 16)
assert(first.targetX == 6 and first.targetY == 13,
  "Kanto travel vector must supply a native-looking target cell")
assert(first.jumping == true and first.hopFrames == 17,
  "Kanto ledge jump state must reach the model renderer")
assert(math.abs(first.stickX - 0.6) < 1e-9 and math.abs(first.stickY - 0.8) < 1e-9)
assert(first.analog == true, "Kanto movement magnitude must drive selector walk/run blend")
assert(first.px == 104 and first.py == 200 and first.cellX == 6 and first.cellY == 12)

-- Every field exposed to the renderer is render-only.  Gold remains untouched.
assert(source.moving == false)
assert(source.facing == "down")
assert(source.animClock == 2)
assert(source.progress == 3)
assert(source.stepFrames == 8)
assert(source.targetX == nil and source.targetY == nil)
assert(source.jumping == false and source.hopFrames == nil)
assert(source.red3dMoveStickX == 0.1 and source.red3dMoveStickY == 0.2)
assert(source.red3dAnalogMoveActive == false)
assert(source.px == 8 and source.py == 16 and source.cellX == 1 and source.cellY == 2)

-- Shadow/reflection/main draws in one scene frame reuse the same prepared frame.
assert(Stadium._refreshKantoPlayerSkinAnimation(pose, renderer) == true)
assert(calls == 1, "same scene frame must not advance the skeleton twice")

-- If Character Selector's own Johto pipeline overwrites its cached key between
-- passes, Kanto must detect that stale frame and immediately reclaim animation.
renderer.voxelFrameKey = "hidden-johto-idle-again"
assert(Stadium._refreshKantoPlayerSkinAnimation(pose, renderer) == true)
assert(calls == 2, "foreign cached-frame overwrite must trigger a Kanto refresh")

-- A new VoxelScene frame always gets a fresh Kanto skeletal frame.
assert(Stadium.prepare({}) == true)
assert(Stadium._refreshKantoPlayerSkinAnimation(pose, renderer) == true)
assert(calls == 3)
assert(Stadium.kantoPlayerAnimRefreshes == 3)

-- Older Character Selector builds have no beginVoxelFrame.  In that case the
-- bridge must invalidate the stale voxel frame so drawVoxel falls back to its
-- position-aware animationState() path instead of reusing hidden Johto idle.
local legacy = { voxelFrameKey = "stale", voxelUploadedKey = "stale" }
assert(Stadium._refreshKantoPlayerSkinAnimation(pose, legacy) == true)
assert(legacy.voxelFrameKey == nil and legacy.voxelUploadedKey == nil)
assert(Stadium.kantoPlayerAnimFallbacks >= 1)

-- Ordinary Johto poses remain selector-owned and are not refreshed here.
local johtoCalls = 0
local johto = { entity = source, isPlayer = true }
local johtoRenderer = {
  voxelFrameKey = "johto",
  beginVoxelFrame = function() johtoCalls = johtoCalls + 1 end,
}
assert(Stadium._refreshKantoPlayerSkinAnimation(johto, johtoRenderer) == true)
assert(johtoCalls == 0)

print("kanto_third_person_player_animation_parity: OK")
