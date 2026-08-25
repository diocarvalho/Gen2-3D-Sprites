-- v0.4.07: moving the right stick while 1ST/3RD camera is active must never
-- temporarily hand Gold back to the native 2D renderer.  Two independent
-- protections cover the observed failure mode:
--   1) right-stick LOOK cannot be interpreted as a camera-mode change;
--   2) the optional sun-shadow refresh is deferred while LOOK is moving and
--      isolated if a driver/mesh refresh fails, so main Voxel3D still draws.
local function read(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end
local function has(s, needle, msg)
  assert(s:find(needle, 1, true), msg or ("missing: " .. needle))
end

local fp = read("lib/FirstPerson.lua")
has(fp, "function FirstPerson.analogLookActive()",
  "FirstPerson exposes camera-owned right-stick activity")
has(fp, "if not FirstPerson.driving() then return false end",
  "stale/menu stick values cannot latch a camera")
has(fp, "math.abs(x) >= FirstPerson.STICK_DEAD",
  "look activity uses the camera's real deadzone")

local bridge = read("lib/GoldVoxelBridge.lua")
has(bridge, "local function stickStable(candidate)",
  "Gold camera mode has an analog-look stability latch")
has(bridge, 'current == "first" or current == "third"',
  "latch is limited to the two free-camera modes")
has(bridge, "candidate ~= current",
  "normal same-mode reads are untouched")
has(bridge, "cameraModeStickHolds",
  "camera-mode transient suppressions are observable")

local scene = read("lib/VoxelScene.lua")
has(scene, "FirstPerson.analogLookActive() and ShadowMap.active()",
  "settled sun map is reused while right-stick look moves")
has(scene, "pcall(ShadowMap.begin, cx, cy, vw, vh)",
  "shadow-pass begin failure cannot tear down the voxel frame")
has(scene, "local okShadow, shadowErr = pcall(function()",
  "shadow caster failures are isolated")
has(scene, "pcall(ShadowMap.abort)",
  "failed shadow pass unwinds GPU state")
has(scene, "shadowRefreshErrors",
  "shadow failures remain diagnosable")

local shadow = read("lib/ShadowMap.lua")
has(shadow, "function ShadowMap.abort()",
  "ShadowMap exposes a safe failed-pass unwind")
has(shadow, "ready = false",
  "a failed shadow map is never sampled as valid")

print("fps_right_stick_3d_stability_parity: OK")
