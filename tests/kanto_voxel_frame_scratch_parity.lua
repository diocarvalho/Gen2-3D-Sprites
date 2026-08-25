-- v0.3.60 Kanto VoxelScene scratch/pool regression.
-- Loads only the helper surface with dependency stubs; no engine/GPU required.

package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.render.PaletteFX"] = function()
  return { effectiveColors = function(c) return c end, usesGbcPack = function() return false end }
end
package.preload["src.world.gen2.Map"] = function()
  return { isOutdoor = function() return true end }
end

local translateCalls = 0
local Mat4 = {
  translate = function(x, y, z)
    translateCalls = translateCalls + 1
    return { "T", x, y, z }
  end,
}
local generic = setmetatable({}, { __index = function() return function() end end })
local V = {
  require = function(name)
    if name == "Mat4" then return Mat4 end
    return generic
  end,
}

local Scene = assert(loadfile("lib/VoxelScene.lua"))(V)
local function check(v, msg) if not v then error(msg or "check failed", 2) end end
local function eq(a,b,msg) if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end end

local scratch = { waterDraws = {}, waterPool = {} }
local a = Scene._scratchArray(scratch, "waterDraws")
a[1], a[2] = 1, 2
local b = Scene._scratchArray(scratch, "waterDraws")
eq(a, b, "scratch array identity reused")
eq(#b, 0, "scratch array cleared")


local sparse = Scene._scratchIndexed(scratch, "sparse", 4)
sparse[1], sparse[4] = "a", "d"
local sparseAgain = Scene._scratchIndexed(scratch, "sparse", 2)
eq(sparseAgain, sparse, "sparse scratch identity reused")
check(sparseAgain[1] == nil and sparseAgain[4] == nil, "sparse high-water slots cleared")

local set1 = Scene._scratchSet(scratch, "live")
set1.A, set1.B = true, true
local set2 = Scene._scratchSet(scratch, "live")
eq(set2, set1, "set scratch identity reused")
check(next(set2) == nil, "set scratch cleared in place")
Scene._copySet(set2, { A=true, C=true })
check(Scene._sameSet(set2, { A=true, C=true }), "set compare/copy preserves membership")
check(not Scene._sameSet(set2, { A=true }), "set compare detects membership change")

local r1 = Scene._scratchRecord(scratch, "waterPool", 1)
r1[1] = "old"
local r2 = Scene._scratchRecord(scratch, "waterPool", 1)
eq(r1, r2, "scratch record identity reused")
Scene._waterRow(scratch, b, "mesh", "tex", "model")
eq(b[1], r1, "water row uses pooled record")
eq(r1[1], "mesh", "water mesh refreshed")
eq(r1[2], "tex", "water texture refreshed")
eq(r1[3], "model", "water model refreshed")

-- v0.3.60: when a pooled draw list shrinks, unused records keep their table
-- identity for later reuse but must stop retaining actors/maps/meshes from the
-- route we just left. Stable low-water marks do not rescrub the tail.
local stale2 = Scene._scratchRecord(scratch, "waterPool", 2)
stale2.mesh = { route = "OLD_ROUTE" }
local stale3 = Scene._scratchRecord(scratch, "waterPool", 3)
stale3.actor = { mapId = "OLD_ROUTE" }
scratch.waterPoolUsed = 3
Scene._trimScratchPool(scratch, "waterPool", 1)
check(next(stale2) == nil and next(stale3) == nil, "trim clears stale pooled references")
eq(scratch.waterPoolUsed, 1, "trim records new high-water use")
stale2.marker = "must survive stable trim"
Scene._trimScratchPool(scratch, "waterPool", 1)
eq(stale2.marker, "must survive stable trim", "stable trim does not rescrub tail")
Scene._trimScratchPool(scratch, "waterPool", 0)
check(next(r1) == nil, "further shrink clears newly-unused record")

local nb = { ox = 32, oy = -16 }
local m1 = Scene._neighborModel(nb)
local m2 = Scene._neighborModel(nb)
eq(m1, m2, "unchanged neighbor transform reused")
eq(translateCalls, 1, "one matrix allocation for stable neighbor")
nb.ox = 48
local m3 = Scene._neighborModel(nb)
check(m3 ~= m1, "offset change rebuilds neighbor transform")
eq(translateCalls, 2, "changed offset triggers exactly one rebuild")

print("kanto_voxel_frame_scratch_parity: OK")
