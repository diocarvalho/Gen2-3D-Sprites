-- Gold/Game2 camera-relative movement adapter for the voxel first/third-person
-- cameras.
--
-- Gold's native movement remains deliberately grid/cardinal: World:pollInput
-- converts the physical pad into heldDir, and World:step later feeds that
-- direction through the normal Player:tryMove / connection / collision path.
-- This adapter changes only WHICH cardinal direction a free-camera input means.
-- The camera-space stick/key vector is rotated by FirstPerson.yaw, quantised to
-- Gold's nearest legal cardinal, and written back to heldDir after the vanilla
-- poll has preserved bike/downhill behavior and every other input source.
--
-- Result: in FIRST/THIRD PERSON, UP/W means "forward in the camera view",
-- DOWN/S means back, and LEFT/RIGHT strafe relative to the camera. DIORAMA,
-- menus, scripts, battles and every non-free-roam state keep vanilla controls.

local V = ...

local FirstPerson = V.require("FirstPerson")
local Voxel = V.require("VoxelState")

local Controls = {
  installed = false,
  remaps = 0,
  lastDir = nil,
  lastWorldX = 0,
  lastWorldZ = 0,
}

local DIR_SCORE = {
  right = function(x, z) return x end,
  left  = function(x, z) return -x end,
  down  = function(x, z) return z end,
  up    = function(x, z) return -z end,
}
local DIR_ORDER = { "down", "right", "up", "left" }

-- Small hysteresis near 45-degree boundaries. Without it, tiny mouse/stick
-- yaw noise can make a held forward input alternate between two grid axes.
local KEEP_MARGIN = 0.10

function Controls.directionFromWorld(x, z, previous)
  x, z = tonumber(x) or 0, tonumber(z) or 0
  if math.abs(x) < 1e-6 and math.abs(z) < 1e-6 then return nil end

  local best, bestScore = nil, -math.huge
  for _, dir in ipairs(DIR_ORDER) do
    local score = DIR_SCORE[dir](x, z)
    if score > bestScore then
      best, bestScore = dir, score
    end
  end

  if previous and DIR_SCORE[previous] then
    local oldScore = DIR_SCORE[previous](x, z)
    if oldScore > 0 and oldScore >= bestScore - KEEP_MARGIN then
      best = previous
    end
  end
  return best
end

function Controls.directionFromCameraVector(mx, mz, previous)
  local wx, wz = FirstPerson.moveWorld(mx or 0, mz or 0)
  return Controls.directionFromWorld(wx, wz, previous), wx, wz
end

function Controls.directionFromYaw()
  local dir = Controls.directionFromCameraVector(0, 1, nil)
  return dir
end

function Controls.install()
  if Controls.installed then return true end

  local ok, World = pcall(require, "src.world.gen2.World")
  if not ok or type(World) ~= "table" then
    return false, "Gold World class unavailable: " .. tostring(World)
  end
  if type(World.pollInput) ~= "function" then
    return false, "Gold World:pollInput is unavailable"
  end

  if World.stadiumCameraRelativeControlsHook then
    Controls.installed = true
    return true
  end

  local vanillaPollInput = World.pollInput
  function World:pollInput(input)
    local out = vanillaPollInput(self, input)

    if not FirstPerson.driving() then
      Controls.lastDir = nil
      Controls.lastWorldX, Controls.lastWorldZ = 0, 0
      return out
    end

    -- FirstPerson.moveVector reads the unquantised left stick when available,
    -- touch d-pad deflection, or held digital directions. A zero vector means
    -- "the player supplied no direction"; leave vanilla heldDir alone so Gold
    -- can still inject Cycling Road's downhill movement and similar rules.
    local mx, mz = FirstPerson.moveVector()
    if mx == 0 and mz == 0 then
      Controls.lastDir = nil
      Controls.lastWorldX, Controls.lastWorldZ = 0, 0
      return out
    end

    local dir, wx, wz = Controls.directionFromCameraVector(mx, mz,
      Controls.lastDir)
    if dir then
      self.heldDir = dir
      Controls.lastDir = dir
      Controls.lastWorldX, Controls.lastWorldZ = wx, wz
      Controls.remaps = Controls.remaps + 1
    end
    return out
  end

  -- In first person the camera is the player's head. Make an A press use the
  -- nearest cardinal to that look direction, so turning to face a person/sign
  -- and pressing A interacts with what is actually in the centre of the view.
  -- Third person intentionally leaves idle facing alone; its camera can orbit
  -- the character independently, while movement itself still turns the body.
  if type(World.interact) == "function" then
    local vanillaInteract = World.interact
    function World:interact(...)
      if FirstPerson.driving() and Voxel.isFirstPerson(Voxel.level)
         and self.player and not self.player.moving then
        local dir = Controls.directionFromYaw()
        if dir then self.player.facing = dir end
      end
      return vanillaInteract(self, ...)
    end
  end

  World.stadiumCameraRelativeControlsHook = true
  Controls.installed = true
  return true
end

function Controls.status()
  return {
    installed = Controls.installed,
    remaps = Controls.remaps,
    lastDir = Controls.lastDir,
    lastWorldX = Controls.lastWorldX,
    lastWorldZ = Controls.lastWorldZ,
  }
end

return Controls
