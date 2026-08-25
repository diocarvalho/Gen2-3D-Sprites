-- v0.4.00: Pokemon Center healing + foreign-Kanto void-tree fill.

package.preload["src.render.Assets"] = function() return {} end
_G.love={math={random=function(a) return a end}}

local backing={}
local TextBox={new=function(_,text,onDone) if onDone then onDone() end return {text=text} end}
local mod={
  exports={},options={get=function() return nil end},ui={TextBox=TextBox},
  save={get=function(_,k,f) local v=backing[k]; return v==nil and f or v end,
        set=function(_,k,v) backing[k]=v; return true end},
}
local stubs={
  Quality={kantoRadius=function() return 1 end,actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end,refresh=function() return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end,isReady=function() return false end} end},
}
local V={mod=mod,require=function(name) return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function check(v,l) if not v then error(l or "check failed",2) end end
local function eq(a,b,l) if a~=b then error((l or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

-- Nurse recognition must not depend on text-pointer metadata.
do
  local map={def={tileset="POKECENTER"}}
  check(Twin._isYellowCenterNurseForTest("VIRIDIAN_POKECENTER",
    {sprite="SPRITE_NURSE",text="TEXT_VIRIDIANPOKECENTER_NURSE"},map),
    "Viridian nurse recognized")
  check(Twin._isYellowCenterNurseForTest("CERULEAN_POKECENTER",
    {sprite="SPRITE_GIRL",text="TEXT_CERULEANPOKECENTER_NURSE"},map),
    "nurse text fallback recognized")
  check(not Twin._isYellowCenterNurseForTest("VIRIDIAN_MART",
    {sprite="SPRITE_NURSE",text="TEXT_FAKE_NURSE"},{def={tileset="MART"}}),
    "nurse detection center-scoped")
end

-- Gold party healer fallback restores HP/status even without world.healParty.
do
  local world={game={save={party={
    {hp=1,maxHp=35,status="PSN",statusTurns=2},
    {hp=4,maxHP=50,statusId="BRN"},
  }}}}
  check(Twin._healGoldParty(world,"testHeals"),"fallback heal succeeds")
  eq(world.game.save.party[1].hp,35,"mon1 HP")
  eq(world.game.save.party[2].hp,50,"mon2 HP")
  eq(world.game.save.party[1].status,nil,"mon1 status")
  eq(world.game.save.party[2].statusId,nil,"mon2 status")
end

-- Source guard: the geometry module must contain the explicit Kanto tree fill
-- and the geometry cache revision must be bumped when that path changes.
do
  local f=assert(io.open("lib/Structures.lua","rb")); local src=f:read("*a"); f:close()
  check(src:find("foreignKantoTreeFillTile",1,true)~=nil,"Kanto tree fill installed")
  check(src:find('return kantoTree, "kanto_tree"',1,true)~=nil,"off-body tree forced")
  local g=assert(io.open("lib/VoxelDiskCache.lua","rb")); local rev=g:read("*a"); g:close()
  check(rev:find("g2vx-400-r1",1,true)~=nil,"geometry cache bumped")
end

print("kanto_center_heal_void_tree_parity: OK")
