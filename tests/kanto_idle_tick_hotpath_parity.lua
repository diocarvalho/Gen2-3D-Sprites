-- v0.3.64 Kanto render-rate idle/encounter hot-path regression.
-- Idle frames must not resolve map/entity tables before the NPC wander clock
-- is due, active movers must interpolate from the cached role record alone,
-- and stable overlay/RNG callbacks must leave the protected-call path after
-- one defensive validation.

package.preload["src.render.Assets"] = function() return {} end

local Spatial = assert(loadfile("lib/KantoSpatial.lua"))()
Spatial.resetCounters()

local mod = {
  exports = {},
  options = { get=function(_,_,default) return default end },
  save = {
    get=function(_,_,fallback) return fallback end,
    set=function() return true end,
  },
  ui = {},
}
local stubs = {
  Quality = { kantoRadius=function() return 1 end, actorDistanceCells=function() return math.huge end },
  FirstPerson = { driving=function() return false end, releaseBody=function() end },
  ChunkMesher = { warmPending=function() return 0 end },
  KantoGen2Style = { PROJECTION_REV="test" },
  KantoSpatial = Spatial,
  runtime_sheets = { new=function() return { load=function() return true end } end },
}
local V = { mod=mod, require=function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local e = Twin._excursionForTest

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end

-- ---- 1. role cache can be peeked without allocating/building on a miss ----
do
  local region = {}
  eq(Spatial.peekRoles(region,"MAP"), nil, "peek miss returns nil")
  eq(region.npcRoleCache, nil, "peek miss does not allocate role-cache table")
  local list = {}
  local roles = Spatial.roles(region,"MAP",list)
  eq(Spatial.peekRoles(region,"MAP"), roles, "peek returns existing role identity")
end

-- ---- 2. idle AI frame touches no map/entity tables before timer is due ----
do
  local region = {} -- deliberately no loaded/maps fields: old path resolved them every frame
  e.region=region; e.sourceMapId="IDLE_MAP"; e.npcAiClock=0; e.npcAiCursor=0
  e.battleBusy=false; e.trainerEngaging=false
  local builds = Spatial.roleBuilds
  local before = Twin.kantoNpcIdleFastFrames or 0
  Twin._tickKantoNpcAI({}, 0.10, false)
  eq(Spatial.roleBuilds, builds, "idle sub-0.70s frame builds no actor roles")
  eq(region.npcRoleCache, nil, "idle sub-0.70s frame allocates no actor cache")
  eq(Twin.kantoNpcIdleFastFrames, before+1, "idle fast-frame diagnostic increments")
end

-- ---- 3. active mover interpolates from cached roles without map lookup ----
do
  local walker = {
    name="walker", def={}, wander=true, moving=true, _moveT=0.95,
    cellX=2, cellY=3, px=16, py=32, _fromPx=16, _fromPy=32, _toPx=32, _toPy=48,
  }
  local npcs={walker}
  local region={}
  local roles=Spatial.roles(region,"MOVE_MAP",npcs)
  Spatial.setMoving(region,"MOVE_MAP",npcs,walker,true)
  eq(#roles.moving,1,"mover seeded in cached role record")
  e.region=region; e.sourceMapId="MOVE_MAP"; e.npcAiClock=0
  e.battleBusy=false; e.trainerEngaging=false
  local before=Twin.kantoNpcMoverFastFrames or 0
  Twin._tickKantoNpcAI({}, 0.02, false)
  check(walker.moving == false, "cached mover completes interpolation without map resolution")
  eq(#roles.moving,0,"completed mover removed from tiny active list")
  eq(Twin.kantoNpcMoverFastFrames,before+1,"mover fast-frame diagnostic increments")
end

-- ---- 4. overlay stack callback becomes direct after one validation --------
do
  local state=nil
  local stack={ top=function() return state end }
  local world={game={stack=stack}}
  local realPcall=pcall
  eq(Twin._overlayOpen(world),false,"overlay first probe sees empty stack")
  local probes=Twin.kantoOverlayProbeReads or 0
  state={name="menu"}
  _G.pcall=function() error("unexpected repeated overlay protected call") end
  local ok, open=realPcall(Twin._overlayOpen,world)
  _G.pcall=realPcall
  check(ok and open==true,"trusted overlay path calls stack top directly")
  eq(Twin.kantoOverlayProbeReads,probes,"stable stack does not re-probe")
  check((Twin.kantoOverlayFastCalls or 0)>=1,"overlay fast-call diagnostic increments")

  -- Replacing the method identity must defensively re-arm the probe.
  stack.top=function() return nil end
  eq(Twin._overlayOpen(world),false,"changed stack method is revalidated")
  eq(Twin.kantoOverlayProbeReads,probes+1,"changed stack method adds one probe")
end

-- ---- 5. trainer IDs/headers are cached and only aligned trainers touch them --
do
  local objA={trainerClass="OPP_BUG_CATCHER",trainerParty=1,index=1}
  local objB={trainerClass="OPP_LASS",trainerParty=1,index=2}
  local a={def=objA,cellX=2,cellY=2,facing="right",moving=false}
  local b={def=objB,cellX=5,cellY=5,facing="down",moving=false}
  local npcs={a,b}
  local fakeMap={}
  local region={
    mapsById={MAP=fakeMap}, npcCache={MAP=npcs}, pokemonCache={MAP={}},
    npcRoleCache={}, npcSpatialCache={}, pokemonSpatialCache={},
    loaded={
      maps={MAP={id="MAP",label="MAP_LABEL"}},
      trainerHeaders={MAP_LABEL={ [1]={range=4}, [2]={range=1} }},
      field={}, encounters={}, text={},
    },
  }
  Spatial.roles(region,"MAP",npcs)
  e.region=region; e.sourceMapId="MAP"; e.cellX=9; e.cellY=9
  e.battleBusy=false; e.trainerEngaging=false
  Twin.kantoTrainerIdCacheBuilds=0; Twin.kantoTrainerHeaderCacheBuilds=0
  Twin.kantoTrainerIdCacheHits=0; Twin.kantoTrainerHeaderCacheHits=0
  check(not Twin._checkYellowTrainerSight({}),"unaligned trainers do not engage")
  eq(Twin.kantoTrainerIdCacheBuilds,0,"unaligned trainers build no persistent id strings")
  eq(Twin.kantoTrainerHeaderCacheBuilds,0,"unaligned trainers resolve no headers")

  -- Player is now in B's facing line, but beyond its authored range: this
  -- touches exactly that trainer's immutable id/header without starting battle.
  e.cellX=5; e.cellY=7
  check(not Twin._checkYellowTrainerSight({}),"aligned out-of-range trainer does not engage")
  eq(Twin.kantoTrainerIdCacheBuilds,1,"only aligned trainer builds one id")
  eq(Twin.kantoTrainerHeaderCacheBuilds,1,"only aligned trainer resolves one header")
  check(not Twin._checkYellowTrainerSight({}),"repeat aligned out-of-range check stays non-engaging")
  eq(Twin.kantoTrainerIdCacheBuilds,1,"trainer id reused on repeat landing")
  eq(Twin.kantoTrainerHeaderCacheBuilds,1,"trainer header reused on repeat landing")
  check((Twin.kantoTrainerIdCacheHits or 0)>=1 and (Twin.kantoTrainerHeaderCacheHits or 0)>=1,
    "trainer id/header cache-hit diagnostics increment")
end

-- ---- 6. Love RNG callback becomes direct after one validation -------------
do
  local oldLove=_G.love
  local calls=0
  local api={ random=function(lo,hi) calls=calls+1; return lo end }
  _G.love={math=api}
  local realPcall=pcall
  eq(Twin._randomInt(3,9),3,"RNG first defensive probe succeeds")
  local probes=Twin.kantoRngProbeReads or 0
  _G.pcall=function() error("unexpected repeated RNG protected call") end
  local ok,value=realPcall(Twin._randomInt,4,10)
  _G.pcall=realPcall
  _G.love=oldLove
  check(ok and value==4,"trusted RNG path is direct after first probe")
  eq(Twin.kantoRngProbeReads,probes,"stable RNG does not re-probe")
  check((Twin.kantoRngFastCalls or 0)>=1 and calls>=2,"RNG fast-call diagnostic increments")
end

print("kanto_idle_tick_hotpath_parity: OK")
