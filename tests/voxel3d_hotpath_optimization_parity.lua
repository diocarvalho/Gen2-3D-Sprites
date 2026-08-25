-- v0.4.18 regression: voxel hot-path optimizations remain allocation-light
-- without silently lowering the renderer's geometry/visual settings.
local function check(v, msg) if not v then error(msg or "check failed", 2) end end
local function read(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

local mesher = read("lib/ChunkMesher.lua")
check(mesher:find("pushRaw = pushRaw", 1, true), "mesh sinks expose packed raw quad writes")
check(mesher:find("local heightCache = {}", 1, true), "terrain height samples are cached per build")
check(mesher:find("local fullU0, fullU1, fullV0, fullV1 = {}, {}, {}, {}", 1, true), "full atlas UV rectangles are cached")
check(mesher:find("local sink = newSink()", 1, true), "auxiliary voxel meshes use the optimized sink")
check(mesher:find('local RING = 8', 1, true), "terrain ring/detail radius stays unchanged")
check(mesher:find('local AO_STRENGTH = 2.4', 1, true), "AO strength stays unchanged")
check(mesher:find('(s.class == "water") and waterPush ~= nil', 1, true), "split-water routing stays enabled")

local voxel = read("lib/Voxel3D.lua")
check(voxel:find("local weatherCached = nil", 1, true), "Weather module lookup is lazy-cached")
check(voxel:find("local preserveCallerCanvasCached = nil", 1, true), "platform/canvas capability probe is cached")
check(voxel:find("held.depthTarget", 1, true), "depth target tables are reused")
check(voxel:find("local drawPull = nil", 1, true), "draw uniform cache tracks pull")
check(voxel:find("if drawPull ~= resolvedPull then", 1, true), "unchanged pull uniform sends are skipped")
check(voxel:find("resetDrawUniformCache()", 1, true), "uniform cache has explicit invalidation")
check(voxel:find("local sunTexelScratch = { 0, 0 }", 1, true), "shader vector scratch is reused")

print("voxel3d_hotpath_optimization_parity: OK")
