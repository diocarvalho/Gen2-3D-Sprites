-- v0.3.90 regression: Yellow's scripted rival encounters and Hall-of-Fame
-- Cerulean Cave unlock are reconstructed without leaking into Gold story state.

package.preload["src.render.Assets"] = function() return {} end

local backing, messages, captured = {}, {}, nil
_G.love = { math = { random = function(a) return a end } }
local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and opts.choice then opts.choice(true) elseif onDone then onDone() end
    return { kind = "text" }
  end,
}
local mod = {
  exports = {}, options = { get = function() return nil end }, ui = { TextBox = TextBox },
  save = {
    get = function(_, key, fallback) local v = backing[key]; return v == nil and fallback or v end,
    set = function(_, key, value) backing[key] = value; return true end,
  },
}
local stubs = {
  Quality = { kantoRadius = function() return 1 end, actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end, releaseBody = function() end },
  ChunkMesher = { warmPending = function() return 0 end, refresh = function() return true end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load=function() return true end, isReady=function() return false end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Rival = Twin._kantoRivalForTest
local Post = Twin._kantoPostgameForTest

local function check(v, label) if not v then error(label or "check failed", 2) end end
local function eq(a,b,label) if a ~= b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local cerRival = { index=1, x=20, y=2, text="TEXT_CERULEANCITY_RIVAL", sprite="SPRITE_BLUE", hidden=true }
local caveGuard = { index=10, x=4, y=12, text="TEXT_CERULEANCITY_SUPER_NERD3", sprite="SPRITE_SUPER_NERD" }
local towerRival = { index=1, x=15, y=5, text="TEXT_POKEMONTOWER2F_RIVAL", sprite="SPRITE_BLUE", hidden=true }
local routeRival1 = { index=1, x=25, y=5, text="TEXT_ROUTE22_RIVAL1", sprite="SPRITE_BLUE", hidden=true }
local routeRival2 = { index=2, x=25, y=5, text="TEXT_ROUTE22_RIVAL2", sprite="SPRITE_BLUE", hidden=true }

local function parties(prefix, n)
  local out = {}
  for i=1,n do out[i]={{species=prefix..tostring(i),level=10+i}} end
  return out
end

local function makeRegion()
  return {
    version="yellow", mapsById={}, npcCache={}, pokemonCache={}, validOutdoor={}, records={},
    loaded={ field={}, tilesets={}, trainerHeaders={},
      maps={
        CERULEAN_CITY={id="CERULEAN_CITY",width=40,height=36,blocks={},objects={cerRival,caveGuard},warps={}},
        POKEMON_TOWER_2F={id="POKEMON_TOWER_2F",width=20,height=20,blocks={},objects={towerRival},warps={}},
        ROUTE_22={id="ROUTE_22",width=40,height=20,blocks={},objects={routeRival1,routeRival2},warps={}},
      },
      trainers={
        OPP_RIVAL1={index=25,name="RIVAL",parties=parties("R1P",3)},
        OPP_RIVAL2={index=42,name="RIVAL",parties=parties("R2P",10)},
      },
      text={
        _CeruleanCityRivalPreBattleText="CERULEAN INTRO",
        _CeruleanCityRivalIWentToBillsText="CERULEAN AFTER",
        _PokemonTower2FRivalWhatBringsYouHereText="TOWER INTRO",
        _PokemonTower2FRivalHowsYourDexText="TOWER AFTER",
        _Route22RivalBeforeBattleText2="ROUTE22 INTRO",
        _Route22RivalAfterBattleText2="ROUTE22 AFTER",
      },
    },
  }
end

local function makeWorld()
  local save={ party={{species="PIKACHU"}}, player={name="GOLD",kantoBadges={}} }
  local world={ game={ save=save, data={ trainers={ classes={
    RIVAL1={index=1,name="RIVAL",attributes={},items={}},
    RIVAL2={index=2,name="RIVAL",attributes={},items={}},
    YOUNGSTER={index=3,name="YOUNGSTER",attributes={},items={}},
  }}}, stack={ push=function() return true end } } }
  world.startScriptedBattle=function(_,trainer,wild,onDone)
    captured=trainer; check(wild==nil,"rival is trainer battle"); onDone("win"); return true
  end
  return world,save
end

local function fresh()
  backing,messages,captured = {},{},nil
  Twin._resetKantoStateCacheForTest()
  local e=Twin._excursionForTest
  e.active=true; e.battleBusy=false; e.prevA=false; e.facing="up"; e.lastOutside=nil
end

-- Immutable Yellow encounter coordinates/party formulas.
do
  eq(Rival.step("CERULEAN_CITY",20,6).id,"CERULEAN","Cerulean trigger")
  eq(Rival.step("POKEMON_TOWER_2F",14,6).id,"TOWER","Tower trigger")
  eq(Rival.step("ROUTE_22",29,5).id,"ROUTE22_FIRST","Route22 shared trigger begins with early rival")
  eq(Rival.party(Rival.ENCOUNTERS.TOWER,1),2,"Tower Jolteon-route party")
  eq(Rival.party(Rival.ENCOUNTERS.ROUTE22,3),10,"Route22 Vaporeon-route party")
end

-- Cerulean bridge rival: script-hidden actor is revealed on the authored cell,
-- uses Yellow RIVAL1 party 3 through Gold, then leaves persistently.
do
  fresh(); local r=makeRegion(); local w=makeWorld()
  Twin._migrateKantoRivalObjects(r,"CERULEAN_CITY")
  check(Twin._kantoObjectHidden("CERULEAN_CITY",cerRival),"Cerulean rival hidden before trigger")
  check(Twin._handleKantoRivalStep(w,r,"CERULEAN_CITY",20,6),"Cerulean rival handled")
  eq(captured.classId,"RIVAL1","Cerulean Gold presentation class")
  eq(captured.roster[1].species,"R1P3","Cerulean Yellow party 3")
  check(Twin._kantoEvent(Rival.ENCOUNTERS.CERULEAN.event),"Cerulean rival event persists")
  check(Twin._kantoObjectHidden("CERULEAN_CITY",cerRival),"Cerulean rival leaves after win")
end

-- Pokemon Tower chooses RIVAL2 party wRivalStarter+1. v0.3.89's default
-- Jolteon route is preserved, so an unmigrated save selects party 2.
do
  fresh(); local r=makeRegion(); local w=makeWorld()
  check(Twin._handleKantoRivalStep(w,r,"POKEMON_TOWER_2F",15,5),"Tower rival handled")
  eq(captured.classId,"RIVAL2","Tower Gold presentation class")
  eq(captured.roster[1].species,"R2P2","Tower starter-relative party")
  check(Twin._kantoEvent(Rival.ENCOUNTERS.TOWER.event),"Tower rival event persists")
end

-- Route 22's final warm-up does not fire early. With all eight Kanto badges it
-- uses RIVAL2 party wRivalStarter+7 (party 8 on the default Jolteon route).
do
  fresh(); local r=makeRegion(); local w,save=makeWorld()
  check(not Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,4),"Route22 waits for all badges")
  check(captured==nil,"no early Route22 battle")
  local names={"BOULDER","CASCADE","THUNDER","RAINBOW","SOUL","MARSH","VOLCANO","EARTH"}
  for i,name in ipairs(names) do save.player.kantoBadges[name]=true; save.player.kantoBadges[i]=true end
  check(Twin._handleKantoRivalStep(w,r,"ROUTE_22",29,4),"Route22 rival handled")
  eq(captured.roster[1].species,"R2P8","Route22 starter-relative party")
  check(Twin._kantoEvent(Rival.ENCOUNTERS.ROUTE22.event),"Route22 rival event persists")
end

-- Hall of Fame controls Cerulean Cave exactly as Yellow's HOF tail does: the
-- guard is present before induction and removed afterward. The warp predicate
-- is an independent safety net against collision/free-move bypasses.
do
  fresh(); local r=makeRegion()
  Twin._migrateKantoPostgameObjects(r,"CERULEAN_CITY")
  check(Twin._kantoObjectShown("CERULEAN_CITY",caveGuard),"cave guard forced visible before HOF")
  check(not Twin._kantoObjectHidden("CERULEAN_CITY",caveGuard),"cave guard not hidden before HOF")
  check(Post.blocksWarp("CERULEAN_CITY","CERULEAN_CAVE_1F",false),"cave warp blocked before HOF")
  Twin._setKantoEvent(Post.HOF_EVENT,true)
  Twin._migrateKantoPostgameObjects(r,"CERULEAN_CITY")
  check(Twin._kantoObjectHidden("CERULEAN_CITY",caveGuard),"cave guard hidden after HOF")
  check(not Twin._kantoObjectShown("CERULEAN_CITY",caveGuard),"force-show cleared after HOF")
  check(not Post.blocksWarp("CERULEAN_CITY","CERULEAN_CAVE_1F",true),"cave warp opens after HOF")
end

print("kanto_rival_postgame_parity: OK")
