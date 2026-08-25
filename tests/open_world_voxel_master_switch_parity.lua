-- v0.4.16: OPEN WORLD and Kanto are consumers of the voxel renderer; neither
-- may force 3D VOXEL WORLD back on after the player chooses native 2D.
local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function has(s,n,msg) assert(s:find(n,1,true),msg or ("missing: "..n)) end
local function lacks(s,n,msg) assert(not s:find(n,1,true),msg or ("unexpected: "..n)) end

local bridge=read("lib/GoldVoxelBridge.lua")
has(bridge,"V.world3DEnabled = optionEnabled",
  "renderer namespace exposes the strict voxel3d master switch")
has(bridge,"return optionEnabled()\nend\n\nBridge.voxelModeEnabled",
  "renderer master switch is voxel3d only")
lacks(bridge,"return optionEnabled() or kantoExcursionActive()",
  "detached Kanto no longer resurrects the voxel provider")
lacks(bridge,"return optionEnabled() or effectiveOpenWorld()",
  "OPEN WORLD no longer resurrects the voxel provider")
has(bridge,"OPEN WORLD is residency only",
  "install path documents renderer/residency separation")

local options=read("options.lua")
has(options,"OPEN WORLD does NOT force 3D VOXEL WORLD on",
  "settings UI explains independent master switch")

local pipeline=read("lib/GoldPipelineBridge.lua")
has(pipeline,"VoxelBridge.voxelModeEnabled",
  "official Gen2 pipeline follows the same master-switch verdict")

print("open_world_voxel_master_switch_parity: OK")
