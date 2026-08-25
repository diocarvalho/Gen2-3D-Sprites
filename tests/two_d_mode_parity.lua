-- v0.4.16 native-2D compatibility regression.
-- 3D VOXEL WORLD is the sole overworld renderer master switch; dormant 3D
-- subsystems must not keep camera/weather/zoom ownership while it is OFF.
local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function has(s,n,msg) assert(s:find(n,1,true),msg or ("missing: "..n)) end
local function lacks(s,n,msg) assert(not s:find(n,1,true),msg or ("unexpected: "..n)) end

local voxel=read("lib/GoldVoxelBridge.lua")
has(voxel,"V.world3DEnabled = optionEnabled","renderer namespace exports the 2D/3D master answer")
has(voxel,"return optionEnabled()\nend\n\nBridge.voxelModeEnabled", "voxel provider follows only voxel3d")
lacks(voxel,"return optionEnabled() or kantoExcursionActive()","Kanto cannot silently force 3D back on")
has(voxel,"release3DPresentation","switching to 2D tears down 3D runtime ownership")
has(voxel,"TwinRegionWorld.returnToJohto","disabling 3D during Kanto returns to hidden Johto anchor")

local fp=read("lib/FirstPerson.lua")
has(fp,"return world3DEnabled() and Voxel.isFreeCam", "free camera cannot drive native 2D")
has(fp,"function FirstPerson.forceRelease", "2D switch can release relative mouse immediately")
has(fp,"love.mouse.setRelativeMode, false", "relative mouse is explicitly released")

local controls=read("lib/GoldCameraControls.lua")
has(controls,"return world3DEnabled() and FirstPerson.driving()", "continuous camera-relative movement requires 3D")
has(controls,"function Controls.release(world)", "native 2D can clear stale free-move state")

local compose=read("lib/GoldComposeBridge.lua")
has(compose,"native 2D is a first-class presentation mode", "compose bridge has explicit 2D path")
has(compose,"if not world3DEnabled() then", "compose skips VoxelScene when 2D is selected")
has(compose,"drawGoldNative2DFrame", "native Gold world, Wilds and custom overlays share the 2D frame")
has(compose,"withNativeWorldPipelinesSuspended", "2D redraw bypasses companion world pipelines without changing their saved options")
has(compose,"Always own the live world frame in 2D", "2D does not trust a scene canvas that may already contain companion voxels")
has(compose,"consumeRenderedFrame", "2D discards any same-frame stale Stadium pipeline output before composing")

local weather=read("weatherfx/lib/DramalessAtmos.lua")
has(weather,"Atmos._hostLib.world3DEnabled", "Weather FX asks whether Stadium2 is actually active, not merely installed")
has(weather,"if okHost and enabled ~= true then return false end", "2D keeps Weather FX screen-space presentation")

local zoom=read("lib/OpenWorldZoom.lua")
has(zoom,'if option("voxel3d", true) == false then return false end', "OPEN WORLD zoom extension is inert in 2D")

local twin=read("lib/TwinRegionWorld.lua")
has(twin,"KANTO FREE ROAM needs 3D VOXEL WORLD. Native 2D remains active.", "Kanto entry refuses instead of forcing voxels")

local main=read("main.lua")
has(main,"mod.exports.world3DEnabled", "companion mods get a public 2D/3D mode query")

local capture=read("lib/OverworldCapture.lua")
has(capture,"2D mode uses normal visible-wild battles/catching", "3D shoulder capture stands down cleanly in 2D")

print("two_d_mode_parity: OK")
