-- v0.3.78 Kanto steady-frame proxy/neighbor hot-path regression.
-- Proves connected-neighbor urgency/prefetch can stay untouched until the
-- exact completed cell/travel vector changes, connected-view rebuilds re-arm
-- the dynamic cache, and Kanto player-card/custom-skin ownership leaves
-- repeated sprite resolution/protected callback paths on steady frames.

package.preload["src.render.Assets"] = function()
  return { image=function() return nil end }
end

local function check(v,msg) if not v then error(msg or "check failed",2) end end
local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end
end

local Frame = assert(loadfile("lib/KantoFrameCache.lua"))()
Frame.resetCounters()

-- ---- 1. scalar neighbor-dynamic key survives steady frames -----------------
do
  local owner={}
  local cache=Frame.ensure(owner)
  local sectorA={{id="R1"}}
  local hit=Frame.neighborView(cache,"PALLET_TOWN",2,sectorA)
  check(not hit,"first neighbor view misses")
  check(not Frame.neighborDynamics(cache,5,6,1,0),"first dynamic inputs miss")
  check(Frame.neighborDynamics(cache,5,6,1,0),"identical dynamic inputs hit")
  check(not Frame.neighborDynamics(cache,6,6,1,0),"cell change refreshes")
  check(not Frame.neighborDynamics(cache,6,6,0,1),"travel vector change refreshes")
  check(Frame.neighborView(cache,"PALLET_TOWN",2,sectorA),"same connected view hits")
  check(Frame.neighborDynamics(cache,6,6,0,1),"view hit preserves dynamic key")
  check(not Frame.neighborView(cache,"PALLET_TOWN",3,sectorA),"radius rebuild misses")
  check(not Frame.neighborDynamics(cache,6,6,0,1),
    "connected-view rebuild re-arms identical scalar inputs")
  check(Frame.neighborDynamicHits >= 2 and Frame.neighborDynamicMisses >= 4,
    "dynamic-cache diagnostics record hits/misses")
  Frame.release(owner)
  eq(cache.neighborDynamicX,nil,"release clears dynamic X")
  eq(cache.neighborDynamicWorldX,nil,"release clears dynamic travel X")
end

-- Load TwinRegionWorld with the same lightweight compatibility stubs used by
-- the other Kanto hot-path regressions.
local Spatial = assert(loadfile("lib/KantoSpatial.lua"))()
local mod={
  exports={},
  options={get=function(_,_,default) return default end},
  save={get=function(_,_,fallback) return fallback end,set=function() return true end},
  ui={},
}
local stubs={
  Quality={kantoRadius=function() return 2 end,actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end},
  KantoGen2Style={PROJECTION_REV="test"},
  KantoSpatial=Spatial,
  KantoFrameCache=Frame,
  runtime_sheets={new=function() return {load=function() return true end} end},
}
local V={mod=mod,require=function(name) return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local e=Twin._excursionForTest

-- ---- 2. neighbor flags refresh only when their exact inputs change ---------
do
  local owner={}
  local cache=Frame.ensure(owner)
  e.cellX,e.cellY=15,10
  e.lastWorldX,e.lastWorldZ=1,0
  local neighbors={
    {depth=1,dir="east"},
    {depth=1,dir="west"},
    {depth=2,dir="connected",_stadiumPrefetchNX=1,_stadiumPrefetchNZ=0},
    {depth=2,dir="connected",_stadiumPrefetchNX=-1,_stadiumPrefetchNZ=0},
    {depth=3,dir="connected"},
  }
  local map={widthCells=20,heightCells=20}
  check(Twin._refreshKantoNeighborDynamics(cache,neighbors,map),"first neighbor refresh runs")
  check(neighbors[1].urgent and neighbors[1].prefetch,"east direct seam is urgent/prefetched")
  check(not neighbors[2].urgent and neighbors[2].prefetch,"west direct seam stays prefetched only")
  check(neighbors[3].prefetch,"east second ring prefetches while travelling east")
  check(not neighbors[4].prefetch,"west second ring does not prefetch while travelling east")
  check(not neighbors[5].prefetch,"third ring is never directional-prefetched")
  eq(cache.neighborPrefetchCount,3,"cached prefetch count includes two direct + east ring")

  local refreshes=Twin.kantoNeighborDynamicRefreshes or 0
  local skips=Twin.kantoNeighborDynamicSkips or 0
  check(not Twin._refreshKantoNeighborDynamics(cache,neighbors,map),
    "identical steady frame skips connected-neighbor loop")
  eq(Twin.kantoNeighborDynamicRefreshes,refreshes,"steady hit performs no refresh")
  eq(Twin.kantoNeighborDynamicSkips,skips+1,"steady hit records one skip")

  e.lastWorldX=-1
  check(Twin._refreshKantoNeighborDynamics(cache,neighbors,map),"direction change refreshes")
  check(not neighbors[3].prefetch and neighbors[4].prefetch,"second-ring direction flips exactly")

  e.cellX=0
  check(Twin._refreshKantoNeighborDynamics(cache,neighbors,map),"cell change refreshes urgency")
  check(not neighbors[1].urgent and neighbors[2].urgent,"west edge urgency follows new cell")
  Frame.release(owner)
end

-- ---- 3. custom-skin active callback leaves pcall after one validation ------
do
  local calls=0
  mod.exports.customPlayerSprite={active=function() calls=calls+1; return true end}
  Twin._customPlayerActiveRef,Twin._customPlayerActiveFn,Twin._customPlayerActiveTrusted=nil,nil,false
  local protected=Twin.kantoCustomPlayerActiveProtectedCalls or 0
  check(Twin._customPlayerSpriteActive(),"first custom-skin probe returns active")
  eq(Twin.kantoCustomPlayerActiveProtectedCalls,protected+1,"first identity is protected once")
  local realPcall=pcall
  _G.pcall=function() error("unexpected repeated custom-skin protected call") end
  local ok,active=realPcall(Twin._customPlayerSpriteActive)
  _G.pcall=realPcall
  check(ok and active==true,"trusted custom-skin callback runs directly")
  check((Twin.kantoCustomPlayerActiveDirectCalls or 0)>=1,"direct custom-skin diagnostic increments")
  eq(calls,2,"active callback executed exactly once per query")

  mod.exports.customPlayerSprite.active=function() calls=calls+1; return false end
  check(not Twin._customPlayerSpriteActive(),"callback identity change is revalidated")
  eq(Twin.kantoCustomPlayerActiveProtectedCalls,protected+2,"replacement adds one protected probe")
end

-- ---- 4. Kanto proxy sprite/card identity is frame-cached ------------------
do
  e.biking=false
  local sourceA={id="JOHTO_PLAYER_A"}
  local sourceB={id="JOHTO_PLAYER_B"}
  local world={player={sprite=sourceA}}
  local region={goldPaletteKey="DAY",loaded={field={playerSprites={}},sprites={}}}
  local proxy={}
  local misses=Twin.kantoProxySpriteCacheMisses or 0
  local hits=Twin.kantoProxySpriteCacheHits or 0
  local sprite,hit=Twin._updateKantoProxySprite(world,region,"PALLET_TOWN",proxy,true)
  eq(sprite,sourceA,"custom Kanto proxy reuses Gold player SpriteRenderer identity")
  check(not hit,"first proxy identity resolves")
  eq(Twin.kantoProxySpriteCacheMisses,misses+1,"first proxy lookup is one miss")
  local sprite2,hit2=Twin._updateKantoProxySprite(world,region,"PALLET_TOWN",proxy,true)
  eq(sprite2,sourceA,"steady proxy keeps same sprite")
  check(hit2,"steady proxy identity hits")
  eq(Twin.kantoProxySpriteCacheHits,hits+1,"steady proxy cache hit recorded")

  e.biking=true
  local _,bikeHit=Twin._updateKantoProxySprite(world,region,"PALLET_TOWN",proxy,true)
  check(not bikeHit,"bike-state identity change invalidates proxy cache")
  region.goldPaletteKey="NITE"
  local _,palHit=Twin._updateKantoProxySprite(world,region,"PALLET_TOWN",proxy,true)
  check(not palHit,"palette identity change invalidates proxy cache")
  world.player.sprite=sourceB
  local spriteB,sourceHit=Twin._updateKantoProxySprite(world,region,"PALLET_TOWN",proxy,true)
  check(not sourceHit and spriteB==sourceB,"source SpriteRenderer replacement invalidates proxy cache")

  -- v0.3.78: default Kanto presentation is ALSO the live Gold player card.
  -- This is a color contract, not merely a missing-sheet fallback: the native
  -- SpriteRenderer already carries PAL_OW_RED / time-of-day object colors and
  -- must never be recolored through Kanto's BG material palette.
  e.biking=false
  region.loaded.field.playerSprites={normal="SPRITE_RED",bike="SPRITE_RED_BIKE"}
  region.loaded.sprites.SPRITE_RED={image="should-not-be-used.png"}
  local fallback,fbHit=Twin._updateKantoProxySprite(world,region,"ROUTE_1",proxy,false)
  check(not fbHit and fallback==sourceB,"default Kanto player must keep native Gold SpriteRenderer identity")
  local fallback2,fbHit2=Twin._updateKantoProxySprite(world,region,"ROUTE_1",proxy,false)
  check(fbHit2 and fallback2==sourceB,"native Gold player identity is frame-cached")
end

print("kanto_steady_proxy_neighbor_hotpath_parity: OK")
