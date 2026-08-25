-- v0.4.32: OPEN WORLD + WORLD OCEAN are real Kanto excursion controls.
package.preload["src.render.Assets"] = function() return {} end

local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function has(s,n,msg) assert(s:find(n,1,true),msg or ("missing: "..n)) end
local function lacks(s,n,msg) assert(not s:find(n,1,true),msg or ("unexpected: "..n)) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end

local twinSrc=read("lib/TwinRegionWorld.lua")
local bridge=read("lib/GoldVoxelBridge.lua")
local optionsSrc=read("options.lua")

has(twinSrc,'function Twin.openWorldEnabled()',"Kanto exposes OPEN WORLD option helper")
has(twinSrc,'function Twin._openWorldRecords(region, sourceId)',"Kanto has whole-region connected record builder")
has(twinSrc,'sector, openPrepared, openTotal = Twin._openWorldRecords(region, mapId)',"Kanto excursion selects whole graph when OPEN WORLD is enabled")
has(twinSrc,'renderState._stadiumOpenWorldNeighbors = kantoOpenWorld',"Kanto render state follows the public OPEN WORLD toggle")
has(twinSrc,'local oceanScope = kantoOpenWorld',"Kanto ocean cache distinguishes streamed vs open-world bounds")
has(twinSrc,'ocean = Twin.oceanDescriptor(frameCache.worldStub, neighbors)',"Kanto WORLD OCEAN is built from the active Kanto neighbour graph")
has(bridge,'return optionOpenWorld()\nend',"Kanto excursion no longer silently forces OPEN WORLD residency")
lacks(bridge,'return optionOpenWorld() or kantoExcursionActive()',"entering Kanto no longer makes OPEN WORLD permanently true")
has(optionsSrc,'It now works during KANTO FREE ROAM too',"WORLD OCEAN setting documents Kanto behavior")
has(optionsSrc,'KANTO FREE ROAM progressively prepares the complete Yellow outdoor graph',"OPEN WORLD setting documents Kanto whole-region behavior")

-- Exercise the topology builder without a ROM/cache. Pre-attached fake maps
-- avoid the atlas loader and prove the root-relative whole-graph placement and
-- graph depths that the Kanto renderer consumes.
local optionValues={openWorld=true,worldOcean=true}
local mod={
  exports={},
  options={get=function(_,key) return optionValues[key] end},
  save={get=function(_,_,fallback) return fallback end,set=function() return true end},
  ui={},
}
local stubs={
  Quality={kantoSurveyBatch=function() return 1 end,kantoRadius=function() return 2 end,actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end} end},
}
local V={mod=mod,require=function(name) return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
assert(Twin.openWorldEnabled(),"OPEN WORLD helper reads option in Kanto")
assert(Twin.oceanEnabled(),"WORLD OCEAN helper reads option in Kanto")

local fakeA={id="A",sourceId="A",def={width=4,height=4}}
local fakeB={id="B",sourceId="B",def={width=4,height=4}}
local fakeC={id="C",sourceId="C",def={width=4,height=4}}
local records={
  {sourceId="A",id="__Y__A",map=fakeA,ox=100,oy=50,depth=0},
  {sourceId="B",id="__Y__B",map=fakeB,ox=228,oy=50,depth=1},
  {sourceId="C",id="__Y__C",map=fakeC,ox=356,oy=50,depth=2},
}
local region={
  records=records,
  recordBySource={A=records[1],B=records[2],C=records[3]},
  loaded={maps={
    A={connections={east={map="B"}}},
    B={connections={west={map="A"},east={map="C"}}},
    C={connections={west={map="B"}}},
  }},
}
local out,prepared,total=Twin._openWorldRecords(region,"A")
eq(total,2,"whole Kanto graph contains both connected neighbours")
eq(prepared,2,"already materialized Kanto maps are immediately available")
eq(#out,2,"whole Kanto active list contains both maps")
eq(out[1].depth,1,"direct neighbour keeps depth one")
eq(out[2].depth,2,"far neighbour keeps BFS depth")
eq(out[1].ox,128,"whole-world placement is relative to current Kanto root")
eq(out[2].ox,256,"second map placement is relative to current Kanto root")

print("kanto_open_world_ocean_parity: OK")
