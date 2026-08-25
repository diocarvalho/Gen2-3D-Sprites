-- v0.3.60 Kanto render-frame cache regression.
-- Self-contained: no ROM cache, renderer, GPU, or engine state required.
-- Proves the presentation scratch path reuses table identities while clearing
-- stale fields/references, preserves the exact actor-culling predicates, caches
-- ocean descriptors by root/radius/option, and releases every reference at the
-- artificial Kanto -> Johto residency boundary.

package.path = "./?.lua;./?/init.lua;" .. package.path

local Frame = dofile("lib/KantoFrameCache.lua")
Frame.resetCounters()

local function check(v, msg)
  if not v then error(msg or "check failed", 2) end
end
local function eq(a, b, msg)
  if a ~= b then error((msg or "not equal") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end

local owner = {}
local c1 = Frame.ensure(owner)
check(c1 and owner.renderFrameCache == c1, "first frame cache attaches to excursion owner")
local n1 = Frame.array(c1, "neighbors")
local d1 = Frame.array(c1, "directNeighbors")
local e1 = Frame.array(c1, "entities")
local g1 = Frame.array(c1, "ghosts")
n1[1], d1[1], e1[1], g1[1] = "neighbor", "direct", "entity", "ghost"

local state1 = Frame.state(c1)
state1.map, state1._stadiumLiveBattle = "PALLET", true
local nr1 = Frame.record(c1, "neighborPool", 1, "neighbor")
nr1.id, nr1.stale = "ROUTE_1", true
local gr1 = Frame.record(c1, "ghostPool", 1, "ghost")
gr1.npc, gr1.stale = "NPC", true

-- A later Kanto frame keeps the containers/record identities but starts clean.
local c2 = Frame.ensure(owner)
eq(c2, c1, "frame cache identity is stable")
local n2 = Frame.array(c2, "neighbors")
local d2 = Frame.array(c2, "directNeighbors")
local e2 = Frame.array(c2, "entities")
local g2 = Frame.array(c2, "ghosts")
eq(n2, n1, "neighbor array reused")
eq(d2, d1, "direct-neighbor array reused")
eq(e2, e1, "entity array reused")
eq(g2, g1, "ghost array reused")
eq(#n2, 0, "neighbor array cleared in place")
eq(#d2, 0, "direct-neighbor array cleared in place")
eq(#e2, 0, "entity array cleared in place")
eq(#g2, 0, "ghost array cleared in place")

local state2 = Frame.state(c2)
eq(state2, state1, "render-state table reused")
check(state2.map == nil and state2._stadiumLiveBattle == nil,
  "state reuse clears foreign/battle fields before the next frame")
local nr2 = Frame.record(c2, "neighborPool", 1, "neighbor")
local gr2 = Frame.record(c2, "ghostPool", 1, "ghost")
eq(nr2, nr1, "neighbor descriptor pooled")
eq(gr2, gr1, "ghost descriptor pooled")
check(nr2.id == nil and nr2.stale == nil, "neighbor descriptor scrubbed")
check(gr2.npc == nil and gr2.stale == nil, "ghost descriptor scrubbed")


-- Actor candidates are stable between cell crossings. A generation/cell/radius
-- change invalidates them, but an ordinary render frame reuses both arrays.
local hitA, avEntities, avGhosts = Frame.actorView(c2,"PALLET_TOWN",5,6,8,2,10)
check(not hitA,"first actor view misses")
avEntities[1], avEntities[2] = "PLAYER", "NPC"
avGhosts[1] = "GHOST"
Frame.setActorViewCounts(c2,1,0)
local hitB, avEntities2, avGhosts2, dn, dm = Frame.actorView(c2,"PALLET_TOWN",5,6,8,2,10)
check(hitB,"same cell/generation actor view hits")
eq(avEntities2,avEntities,"actor candidate array reused without wipe")
eq(avGhosts2,avGhosts,"ghost candidate array reused without wipe")
eq(avEntities2[2],"NPC","actor candidate survives cache hit")
eq(dn,1,"cached drawn NPC count retained")
eq(dm,0,"cached drawn Pokemon count retained")
local hitC, avEntities3 = Frame.actorView(c2,"PALLET_TOWN",6,6,8,2,10)
check(not hitC,"player cell crossing invalidates actor view")
eq(avEntities3,avEntities,"actor array identity still reused after miss")
eq(#avEntities3,0,"actor array scrubbed on actor-view miss")

-- Pool tails keep their tiny table allocation but must release old map/actor
-- references as soon as a later route needs fewer records.
local nr3=Frame.record(c2,"neighborPool",2,"neighbor")
nr3.map="OLD_ROUTE"
Frame.trimPool(c2,"neighborPool",2)
Frame.trimPool(c2,"neighborPool",1)
check(nr3.map==nil,"unused neighbor pool tail releases old route reference")
local trims=Frame.poolTrims
Frame.trimPool(c2,"neighborPool",1)
eq(Frame.poolTrims,trims,"stable pool high-water does not rescrub tail every frame")

-- Same quality/culling semantics as the previous inline Kanto code.
local actor = { cellX = 10, cellY = 8, px = 160, py = 128 }
check(Frame.localActorVisible(actor, 12, 10, 2), "local actor at inclusive edge remains visible")
check(not Frame.localActorVisible(actor, 13, 10, 2), "local actor beyond quality radius is culled")
check(Frame.localActorVisible(actor, 999, 999, math.huge), "unlimited actor distance still means unlimited")
check(Frame.neighborActorVisible(actor, 32, -16, 192, 112, 2),
  "neighbor actor offset/culling uses rendered world pixels")
check(not Frame.neighborActorVisible(actor, 32, -16, 400, 112, 2),
  "distant neighbor actor is still culled")

-- Ocean descriptor caching does not allocate a string key each frame and
-- distinguishes root map, sector radius, and option state.
local hit = Frame.ocean(c2, "__GEN1__PALLET_TOWN", 2, true)
check(not hit, "first ocean lookup misses")
local ocean = { rects = { 1, 2, 3, 4 } }
Frame.setOcean(c2, "__GEN1__PALLET_TOWN", 2, true, ocean)
local hit2, got = Frame.ocean(c2, "__GEN1__PALLET_TOWN", 2, true)
check(hit2 and got == ocean, "same root/radius/option reuses ocean descriptor")
local hit3 = Frame.ocean(c2, "__GEN1__PALLET_TOWN", 1, true)
check(not hit3, "quality radius change invalidates ocean descriptor")
Frame.invalidateOcean(owner)
local hit4 = Frame.ocean(c2, "__GEN1__PALLET_TOWN", 2, true)
check(not hit4, "explicit ocean invalidation drops released mesh descriptor")

-- RETURN TO JOHTO must not let reusable scratch pin Kanto maps/actors/meshes.
n2[1], d2[1], e2[1], g2[1] = { map = "KANTO" }, { map = "DIRECT" }, { npc = "KANTO" }, { ghost = "KANTO" }
nr2.map, gr2.map = "KANTO_MAP", "KANTO_GHOST_MAP"
c2.worldStub.map = "KANTO_MAP"
c2.voxelScratch.nbMesh[1] = { mesh = "KANTO_MESH" }
c2.voxelScratch.nbWater[1] = { mesh = "KANTO_WATER" }
c2.voxelScratch.detailReady[1] = { mesh = "KANTO_DETAIL" }
c2.voxelScratch.live["__GEN1__PALLET_TOWN"] = true
c2.voxelScratch.liveApplied["__GEN1__ROUTE_1"] = true
Frame.release(owner)
check(owner.renderFrameCache == nil, "release detaches cache from excursion")
eq(#n2, 0, "released neighbor array cleared")
eq(#d2, 0, "released direct-neighbor array cleared")
eq(#e2, 0, "released entity array cleared")
eq(#g2, 0, "released ghost array cleared")
check(nr2.map == nil and gr2.map == nil, "pooled records no longer pin maps")
check(c2.worldStub.map == nil, "ocean world stub no longer pins current map")
check(next(c2.voxelScratch.nbMesh) == nil and next(c2.voxelScratch.nbWater) == nil,
  "released prefetch scratch no longer pins terrain/water meshes")
check(next(c2.voxelScratch.detailReady) == nil,
  "released detail-ready scratch no longer pins far-map meshes")
check(next(c2.voxelScratch.live) == nil and next(c2.voxelScratch.liveApplied) == nil,
  "released residency scratch no longer pins Kanto map ids")
check(Frame.releases >= 1, "release diagnostic counted")
check(Frame.stateReuses >= 1 and Frame.arrayReuses >= 4,
  "steady-state reuse diagnostics counted")
check(Frame.actorViewHits >= 1 and Frame.actorViewMisses >= 2,
  "actor-view reuse diagnostics counted")

print("kanto_render_frame_cache_parity: OK")
