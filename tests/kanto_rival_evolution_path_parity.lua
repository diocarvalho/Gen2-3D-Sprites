-- v0.3.98 regression: Yellow rival Eevee evolution route.
-- Oak Lab win => Flareon branch; loss => Vaporeon branch.
-- Winning the optional first Route 22 battle promotes only Flareon -> Jolteon.

package.preload["src.render.Assets"] = function() return {} end

local backing, captured = {}, nil
_G.love = { math = { random = function(a) return a end } }
local TextBox = {
  new = function(_, text, onDone)
    if onDone then onDone() end
    return { text=text }
  end,
}
local mod = {
  exports={}, options={get=function() return nil end}, ui={TextBox=TextBox},
  save={
    get=function(_,k,f) local v=backing[k]; return v==nil and f or v end,
    set=function(_,k,v) backing[k]=v; return true end,
  },
}
local stubs = {
  Quality={kantoRadius=function() return 1 end,actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end,refresh=function() return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end,isReady=function() return false end} end},
}
local V={mod=mod,require=function(name) return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Rival=Twin._kantoRivalForTest

local function check(v,label) if not v then error(label or "check failed",2) end end
local function eq(a,b,label)
  if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end
end

local routeRival1={index=1,x=25,y=5,text="TEXT_ROUTE22_RIVAL1",sprite="SPRITE_BLUE",hidden=true}
local routeRival2={index=2,x=25,y=5,text="TEXT_ROUTE22_RIVAL2",sprite="SPRITE_BLUE",hidden=true}
local function parties(prefix,n)
  local out={}
  for i=1,n do out[i]={{species=prefix..tostring(i),level=5+i}} end
  return out
end
local function region()
  return {
    version="yellow",mapsById={},npcCache={},pokemonCache={},validOutdoor={},records={},
    loaded={field={},tilesets={},trainerHeaders={},
      maps={ROUTE_22={id="ROUTE_22",width=40,height=20,blocks={},objects={routeRival1,routeRival2},warps={}}},
      trainers={
        OPP_RIVAL1={index=25,name="RIVAL",parties=parties("R1P",3)},
        OPP_RIVAL2={index=42,name="RIVAL",parties=parties("R2P",10)},
      },
      text={
        _Route22RivalBeforeBattleText1="EARLY INTRO",
        _Route22RivalAfterBattleText1="EARLY AFTER",
        _Route22RivalBeforeBattleText2="LATE INTRO",
        _Route22RivalAfterBattleText2="LATE AFTER",
      },
    },
  }
end
local function world(outcome)
  local save={party={{species="PIKACHU"}},player={name="GOLD",kantoBadges={}}}
  local w={game={save=save,data={trainers={classes={
    RIVAL1={index=1,name="RIVAL",attributes={},items={}},
    RIVAL2={index=2,name="RIVAL",attributes={},items={}},
  }}},stack={push=function() return true end}}}
  w.startScriptedBattle=function(_,trainer,wild,onDone)
    captured=trainer
    onDone(outcome or "win")
    return true
  end
  return w,save
end
local function fresh()
  backing,captured={},nil
  Twin._resetKantoStateCacheForTest()
  local e=Twin._excursionForTest
  e.active=true;e.battleBusy=false;e.prevA=false;e.facing="up";e.lastOutside=nil
end

-- Immutable source formulas.
do
  eq(Rival.ENCOUNTERS.ROUTE22_FIRST.party,2,"early Route22 is Rival1 party 2")
  eq(Rival.starterFromLabResult(true),Rival.STARTER.FLAREON,"lab win starts Flareon route")
  eq(Rival.starterFromLabResult(false),Rival.STARTER.VAPOREON,"lab loss starts Vaporeon route")
  eq(Rival.starterAfterFirstRoute22Win(Rival.STARTER.FLAREON),Rival.STARTER.JOLTEON,
     "Route22 win promotes Flareon route to Jolteon")
  eq(Rival.starterAfterFirstRoute22Win(Rival.STARTER.VAPOREON),Rival.STARTER.VAPOREON,
     "Vaporeon route stays Vaporeon")
end

-- Before Oak's Lab rival is resolved, the optional Route22 battle cannot fire.
do
  fresh(); local r=region(); local w=world("win")
  check(not Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,4),"early rival waits for lab battle")
  check(captured==nil,"no premature battle")
end

-- Win in Oak's Lab => Flareon branch. Win early Route22 => Jolteon.
do
  fresh(); local r=region(); local w=world("win")
  check(Twin._recordOakLabRivalOutcomeForTest("win"),"record lab win")
  eq(Twin._kantoRivalStarter(),Rival.STARTER.FLAREON,"lab win persisted Flareon")
  check(Twin._kantoEvent(Rival.LAB_EVENT),"lab event persisted")
  check(Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,4),"early Route22 battle fires")
  eq(captured.roster[1].species,"R1P2","uses Yellow Rival1 party 2")
  check(Twin._kantoEvent("EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE"),"early Route22 event")
  eq(Twin._kantoRivalStarter(),Rival.STARTER.JOLTEON,"Route22 win becomes Jolteon branch")
end

-- Lose Oak's Lab => Vaporeon branch; even a later Route22 win does not alter it.
do
  fresh(); local r=region(); local w=world("win")
  Twin._recordOakLabRivalOutcomeForTest("lose")
  eq(Twin._kantoRivalStarter(),Rival.STARTER.VAPOREON,"lab loss persisted Vaporeon")
  check(Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,5),"early Route22 battle after lab loss")
  eq(Twin._kantoRivalStarter(),Rival.STARTER.VAPOREON,"Vaporeon route preserved")
end

-- Brock/Boulder permanently skips the optional first battle. The Flareon route
-- therefore remains Flareon, exactly as Yellow's script intends.
do
  fresh(); local r=region(); local w,save=world("win")
  Twin._recordOakLabRivalOutcomeForTest("win")
  save.player.kantoBadges.BOULDER=true
  save.player.kantoBadges[1]=true
  check(not Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,4),"Boulder skips early rival")
  eq(Twin._kantoRivalStarter(),Rival.STARTER.FLAREON,"skipped battle keeps Flareon route")
end

-- Later Tower party now reads the persisted evolution branch instead of the
-- historical default fallback.
do
  fresh()
  Twin._recordOakLabRivalOutcomeForTest("lose")
  eq(Rival.party(Rival.ENCOUNTERS.TOWER,Twin._kantoRivalStarter()),4,
     "Tower uses Vaporeon-relative party after lab loss")
  Twin._setKantoRivalStarterForTest(Rival.STARTER.JOLTEON)
  eq(Rival.party(Rival.ENCOUNTERS.TOWER,Twin._kantoRivalStarter()),2,
     "Tower uses Jolteon-relative party after early Route22 win")
end

print("kanto_rival_evolution_path_parity: OK")
