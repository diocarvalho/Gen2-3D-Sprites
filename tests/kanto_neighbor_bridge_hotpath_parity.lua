-- v0.3.65 Kanto neighbor-descriptor + Gold bridge hot-path regression.
-- Self-contained: proves the connected-route descriptor arrays survive steady
-- presentation frames without repopulation, remain independent of actor-view
-- invalidation, invalidate on root/radius/sector identity changes, and that the
-- Gold bridge leaves pcall after one successful excursionState validation.

package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(v,msg) if not v then error(msg or "check failed",2) end end
local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end
end

local Frame = dofile("lib/KantoFrameCache.lua")
Frame.resetCounters()
local owner = {}
local cache = Frame.ensure(owner)
local sectorA = { { id="R1" }, { id="R2" } }

local hit, neighbors, direct = Frame.neighborView(cache, "PALLET_TOWN", 2, sectorA)
check(not hit, "first connected-neighborhood lookup misses")
local n1 = Frame.record(cache, "neighborPool", 1, "neighbor")
local n2 = Frame.record(cache, "neighborPool", 2, "neighbor")
n1.id, n1.map, n1.depth = "R1", { id="MAP_R1" }, 1
n2.id, n2.map, n2.depth = "R2", { id="MAP_R2" }, 2
neighbors[1], neighbors[2], direct[1] = n1, n2, n1
Frame.trimPool(cache, "neighborPool", 2)

local hit2, neighbors2, direct2 = Frame.neighborView(cache, "PALLET_TOWN", 2, sectorA)
check(hit2, "same root/radius/sector identity hits")
eq(neighbors2, neighbors, "neighbor array identity is retained")
eq(direct2, direct, "direct-neighbor array identity is retained")
eq(neighbors2[1], n1, "pooled descriptor survives steady frame")
eq(neighbors2[1].map.id, "MAP_R1", "steady hit does not scrub map reference")

-- Actor motion changes actor candidates, not the immutable connected graph.
Frame.invalidateActorView(owner)
local hit3, neighbors3 = Frame.neighborView(cache, "PALLET_TOWN", 2, sectorA)
check(hit3, "actor-view invalidation does not rebuild neighbor descriptors")
eq(neighbors3[2], n2, "actor invalidation preserves second-ring descriptor")

-- Any topology/quality identity change must rebuild and clear arrays first.
local hit4, neighbors4, direct4 = Frame.neighborView(cache, "PALLET_TOWN", 3, sectorA)
check(not hit4, "Kanto radius change invalidates neighbor view")
eq(neighbors4, neighbors, "radius miss still reuses array object")
eq(#neighbors4, 0, "radius miss clears stale neighbor membership")
eq(#direct4, 0, "radius miss clears stale direct membership")
neighbors4[1] = n1; direct4[1] = n1
local sectorB = { { id="R1" } }
local hit5 = Frame.neighborView(cache, "PALLET_TOWN", 3, sectorB)
check(not hit5, "rebuilt sector-record table invalidates same root/radius")
local hit6 = Frame.neighborView(cache, "ROUTE_1", 3, sectorB)
check(not hit6, "root-map transition invalidates neighborhood view")
check(Frame.neighborViewHits >= 2 and Frame.neighborViewMisses >= 4,
  "neighbor-view diagnostics record hits and misses")

Frame.release(owner)
check(owner.renderFrameCache == nil, "RETURN TO JOHTO-style release detaches frame cache")
check(cache.neighborViewSource == nil, "release drops cached sector table reference")

-- Gold bridge: validate the trusted bundled helper once, then leave pcall on
-- subsequent frames. Replacing the helper function re-arms the protected probe.
love = love or { graphics = {} }
local modStub = {
  path = "tests",
  options = { get = function() return nil end },
  read = function() return nil, "unused in bridge helper regression" end,
}
local Bridge = assert(loadfile("lib/GoldVoxelBridge.lua"))(modStub)
check(type(Bridge._callKantoExcursionState) == "function",
  "Gold bridge exposes Kanto excursion-state fast-call helper")
local calls = 0
local twin = { excursionState = function(world)
  calls = calls + 1
  return { world = world, call = calls }
end }
local world = { tag="GOLD" }
local ok1, s1 = Bridge._callKantoExcursionState(world, twin)
check(ok1 and s1.world == world and s1.call == 1, "first protected excursion call succeeds")
eq(Bridge.kantoExcursionStateProtectedCalls, 1, "first call uses one protected validation")
eq(Bridge.kantoExcursionStateDirectCalls or 0, 0, "first call is not counted direct")
local ok2, s2 = Bridge._callKantoExcursionState(world, twin)
check(ok2 and s2.call == 2, "second excursion call succeeds")
eq(Bridge.kantoExcursionStateProtectedCalls, 1, "steady frame does not re-enter pcall")
eq(Bridge.kantoExcursionStateDirectCalls, 1, "steady frame uses trusted direct call")
local replacementCalls = 0
twin.excursionState = function(w)
  replacementCalls = replacementCalls + 1
  return { world=w, replacement=true }
end
local ok3, s3 = Bridge._callKantoExcursionState(world, twin)
check(ok3 and s3.replacement, "replacement helper succeeds")
eq(Bridge.kantoExcursionStateProtectedCalls, 2,
  "helper identity change re-arms one protected validation")
eq(replacementCalls, 1, "replacement helper called once")

print("kanto_neighbor_bridge_hotpath_parity: OK")
