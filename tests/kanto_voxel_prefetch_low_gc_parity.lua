-- v0.3.59 Kanto VoxelScene prefetch/culling low-GC regression.
-- Self-contained: no engine, ROM cache, GPU, or LOVE renderer required.

package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.render.PaletteFX"] = function()
  return { effectiveColors = function(c) return c end, usesGbcPack = function() return false end }
end
package.preload["src.world.gen2.Map"] = function()
  return { isOutdoor = function() return true end }
end

local padCalls = { world = 0, detail = 0, actor = 0 }
local Quality = {
  worldCullPadding = function() padCalls.world = padCalls.world + 1; return 100 end,
  detailCullPadding = function() padCalls.detail = padCalls.detail + 1; return 60 end,
  actorCullPadding = function() padCalls.actor = padCalls.actor + 1; return 80 end,
}

local liveCalls, atlasLiveCalls = 0, 0
local ChunkMesher = {
  diskCacheEnabled = function() return false end,
  request = function() end,
  pair = function(map) return "mesh:" .. tostring(map.id), nil end,
  setLive = function() liveCalls = liveCalls + 1 end,
  flowers = function() return nil end,
  figures = function() return nil end,
}
local TerrainAtlas = { setLive = function() atlasLiveCalls = atlasLiveCalls + 1 end }
local VoxelState = {}
local Mat4 = { translate = function(x,y,z) return {x,y,z} end }
local generic = setmetatable({}, { __index = function() return function() end end })
local V = {
  require = function(name)
    if name == "Quality" then return Quality end
    if name == "ChunkMesher" then return ChunkMesher end
    if name == "TerrainAtlas" then return TerrainAtlas end
    if name == "VoxelState" then return VoxelState end
    if name == "Mat4" then return Mat4 end
    return generic
  end,
}

local Scene = assert(loadfile("lib/VoxelScene.lua"))(V)
local function check(v,msg) if not v then error(msg or "check failed",2) end end
local function eq(a,b,msg) if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end end

-- One frame computes the three quality paddings exactly once; repeated culling
-- tests reuse the expanded bounds and do not call back into Quality.
local view = Scene._prepareCullView({}, 100, 80, 160, 144)
eq(padCalls.world, 1, "world padding computed once")
eq(padCalls.detail, 1, "detail padding computed once")
eq(padCalls.actor, 1, "actor padding computed once")
local mapB = { id="B", def={ width=10, height=8, connections={} } }
local nb = { map=mapB, ox=200, oy=0, depth=1 }
local stateCull = { _stadiumCullView=view }
Scene.neighborVisible(stateCull, nb)
Scene.neighborVisible(stateCull, nb)
Scene.neighborDetailVisible(stateCull, nb)
Scene.neighborDetailVisible(stateCull, nb)
eq(padCalls.world, 1, "neighbor culling reuses world padding")
eq(padCalls.detail, 1, "neighbor detail culling reuses detail padding")
eq(padCalls.actor, 1, "neighbor checks do not recalc actor padding")

-- Sparse scratch arrays clear stale high indexes even if an earlier slot is nil.
local scratch = {}
local sparse1 = Scene._scratchIndexed(scratch, "nbMesh", 4)
sparse1[1], sparse1[4] = "near", "far"
local sparse2 = Scene._scratchIndexed(scratch, "nbMesh", 2)
eq(sparse1, sparse2, "prefetch array identity reused")
check(sparse2[1] == nil and sparse2[4] == nil, "high-water clear removes stale sparse meshes")

-- Kanto shared-body mode must never enter openWorldFullMasks. Poisoning the
-- connections iterator makes accidental seam-mask construction fail loudly.
local poisonConnections = setmetatable({}, {
  __pairs = function() error("shared-body Kanto must not build FULL seam masks") end
})
local mapA = { id="A", def={ width=10, height=8, connections=poisonConnections } }
mapB.def.connections = poisonConnections
local frameScratch = { cullView = {} }
local state = {
  map = mapA,
  neighbors = { nb },
  _stadiumCullView = Scene._prepareCullView(frameScratch.cullView, 100, 80, 160, 144),
  _stadiumFrameScratch = frameScratch,
  _stadiumResidencyRegion = "kanto",
  _stadiumOpenWorldNeighbors = true,
  _stadiumSharedWorldBodies = true,
  _stadiumYellowKanto = true,
}

local _, ready1 = Scene.prefetch(state)
local liveTable = frameScratch.live
local readyTable = ready1
local _, ready2 = Scene.prefetch(state)
eq(frameScratch.live, liveTable, "live-set dictionary reused")
eq(ready2, readyTable, "neighbor-ready array reused")
eq(liveCalls, 1, "unchanged Kanto residency does not call setLive every frame")
eq(atlasLiveCalls, 1, "unchanged Kanto residency does not rescan atlas residency every frame")
check(VoxelState.ready == true, "terrain remains ready")

print("kanto_voxel_prefetch_low_gc_parity: OK")
