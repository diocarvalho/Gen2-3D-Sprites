-- v0.4.31 regression: nearby native-Johto sectors are prewarmed into the
-- persistent BODY cache while Kanto keeps its dedicated region cooker.
local function check(v,msg) if not v then error(msg or "check failed",2) end end
local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end

local scene=read("lib/VoxelScene.lua")
check(scene:find("function VoxelScene._scheduleNeighborDiskWarm",1,true),
  "VoxelScene exposes nearby-sector persistent preloader")
check(scene:find('state._stadiumYellowKanto == true then return 0',1,true),
  "generic preloader leaves Kanto to its dedicated cooker")
check(scene:find('ChunkMesher.warmDisk(map, true, nil, regionTag)',1,true),
  "nearby sectors warm BODY geometry without GPU residency")
check(scene:find('local regionTag = "johto"',1,true),
  "Johto warmers are independently trackable/cancellable")
check(scene:find('pcall(ChunkMesher.cancelWarmRegion, "johto")',1,true),
  "entering Kanto cancels Johto preload jobs and map references")
check(scene:find('targetPending = mode == "fast" and 2 or 1',1,true),
  "mobile preload queue stays bounded")
check(scene:find('targetPending = mode == "fast" and 6 or (mode == "smooth" and 2 or 4)',1,true),
  "desktop uses a wider but bounded preload queue")
check(scene:find("for depth = 1, 3 do",1,true),
  "direct/near sectors are prioritized before deeper prepared maps")

local bridge=read("lib/GoldVoxelBridge.lua")
check(bridge:find("local meshPumpHint = state and true or false",1,true),
  "visible Johto frames throttle cache-only warmers like Kanto")

local mesher=read("lib/ChunkMesher.lua")
check(mesher:find('out.johtoWarmPending = ChunkMesher.warmPending("johto")',1,true),
  "cache status reports Johto preload queue")

print("sector_disk_preload_parity: OK")
