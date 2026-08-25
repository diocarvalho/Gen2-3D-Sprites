-- v0.3.60 Kanto direct-neighbor handoff regression.
-- TwinRegionWorld supplies a reusable depth<=1 array. GoldVoxelBridge must use
-- that exact table rather than allocate/filter a second array every Kanto frame.

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end
end
local function check(v,msg) if not v then error(msg or "check failed",2) end end

love = love or { graphics = {} }
local modStub = {
  path = "tests",
  options = { get = function() return nil end },
  read = function() return nil, "unused in direct-neighbor helper regression" end,
}
local Bridge = assert(loadfile("lib/GoldVoxelBridge.lua"))(modStub)
check(type(Bridge._directKantoNeighbors) == "function", "bridge exposes direct-neighbor helper")

local n1, n2, n3 = {depth=1}, {depth=2}, {depth=1}
local reusable = { n1, n3 }
local state = { neighbors = {n1,n2,n3}, _stadiumDirectNeighbors = reusable }
local got, reused = Bridge._directKantoNeighbors(state)
eq(got, reusable, "bundled Kanto path reuses TwinRegionWorld array identity")
check(reused, "bundled Kanto path reports zero-allocation reuse")

local fallback, fallbackReused = Bridge._directKantoNeighbors({ neighbors = {n1,n2,n3} })
check(not fallbackReused, "older/injected Twin path uses compatibility fallback")
eq(#fallback, 2, "fallback keeps only direct neighbors")
eq(fallback[1], n1, "fallback preserves direct-neighbor order 1")
eq(fallback[2], n3, "fallback preserves direct-neighbor order 2")

print("kanto_direct_neighbor_handoff_parity: OK")
