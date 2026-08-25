-- v0.3.89 regression: Yellow's Elite Four room locks, forward-only run,
-- Champion Rival, and Gold-native Hall of Fame bridge remain Kanto-local.

package.preload["src.render.Assets"] = function() return {} end
local hofInductions = 0
package.preload["src.core.gen2.HallOfFame"] = function()
  return {
    induct = function(save, party)
      hofInductions = hofInductions + 1
      save.hallOfFame = save.hallOfFame or { count = 0, teams = {} }
      save.hallOfFame.count = (save.hallOfFame.count or 0) + 1
      local entry = { winCount = save.hallOfFame.count, mons = {} }
      for _, mon in ipairs(party or {}) do entry.mons[#entry.mons + 1] = { species = mon.species } end
      table.insert(save.hallOfFame.teams, 1, entry)
      save.spawnAfterChampion = "SPAWN_LANCE"
      return entry, false
    end,
  }
end
package.preload["src.ui.gen2.HallOfFame"] = function()
  return { new = function(_, opts) return { kind = "hof", onDone = opts.onDone, entry = opts.entry } end }
end

local backing, messages, pushed, captured = {}, {}, {}, nil
_G.love = { math = { random = function(a) return a end } }
local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and opts.choice then opts.choice(true) elseif onDone then onDone() end
    return { kind = "text", text = text }
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
local L = Twin._kantoLeagueForTest

local function check(v, label) if not v then error(label or "check failed", 2) end end
local function eq(a,b,label) if a ~= b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local function blockDef(id, w, h, objects)
  local b = {}; for i=1,w*h do b[i]=0 end
  return { id=id, width=w, height=h, blocks=b, objects=objects or {}, warps={}, tileset="DUMMY" }
end
local function fakeMap(def)
  local m = { id="__GEN1__"..def.id, sourceId=def.id, def=def, _stadiumForeignGen1Map=true }
  function m:blockAt(bx,by) return self.def.blocks[by*self.def.width+bx+1] end
  function m:setBlock(bx,by,v) self.def.blocks[by*self.def.width+bx+1]=v return true end
  function m:isPassableCell() return true end
  function m:inBounds() return true end
  function m:isWaterCell() return false end
  return m
end

local lorelei={index=1,x=5,y=2,text=L.ROOMS.LORELEIS_ROOM.text,trainerClass="OPP_LORELEI",trainerParty=1}
local bruno={index=1,x=5,y=2,text=L.ROOMS.BRUNOS_ROOM.text,trainerClass="OPP_BRUNO",trainerParty=1}
local agatha={index=1,x=5,y=2,text=L.ROOMS.AGATHAS_ROOM.text,trainerClass="OPP_AGATHA",trainerParty=1}
local lance={index=1,x=6,y=1,text=L.ROOMS.LANCES_ROOM.text,trainerClass="OPP_LANCE",trainerParty=1}
local rival={index=1,x=4,y=2,text=L.CHAMPION.text,sprite="SPRITE_BLUE"}

local function makeRegion()
  local maps = {
    LORELEIS_ROOM=blockDef("LORELEIS_ROOM",8,12,{lorelei}),
    BRUNOS_ROOM=blockDef("BRUNOS_ROOM",8,12,{bruno}),
    AGATHAS_ROOM=blockDef("AGATHAS_ROOM",8,12,{agatha}),
    LANCES_ROOM=blockDef("LANCES_ROOM",8,12,{lance}),
    CHAMPIONS_ROOM=blockDef("CHAMPIONS_ROOM",8,10,{rival}),
    HALL_OF_FAME=blockDef("HALL_OF_FAME",8,10,{}),
    PALLET_TOWN=blockDef("PALLET_TOWN",10,10,{}),
  }
  local r = {
    version="yellow", mapsById={}, npcCache={}, pokemonCache={}, validOutdoor={}, records={},
    loaded={ field={}, tilesets={}, maps=maps, textPointers={}, trainerHeaders={},
      trainers={
        OPP_LORELEI={index=44,name="LORELEI",parties={{ {species="DEWGONG",level=54} }}},
        OPP_BRUNO={index=33,name="BRUNO",parties={{ {species="ONIX",level=53} }}},
        OPP_AGATHA={index=46,name="AGATHA",parties={{ {species="GENGAR",level=56} }}},
        OPP_LANCE={index=47,name="LANCE",parties={{ {species="GYARADOS",level=58} }}},
        OPP_RIVAL3={index=43,name="RIVAL",parties={
          {{species="SANDSLASH",level=61},{species="JOLTEON",level=65}},
          {{species="SANDSLASH",level=61},{species="FLAREON",level=65}},
          {{species="SANDSLASH",level=61},{species="VAPOREON",level=65}},
        }},
      },
      text={
        _ChampionsRoomRivalIntroText="I am the most powerful trainer in the world!",
        _ChampionsRoomRivalAfterBattleText="I lost...",
        _ChampionsRoomOakCongratulatesPlayerText="Congratulations, Champion!",
        _ChampionsRoomOakComeWithMeText="Come with me.",
        _HallOfFameOakText="Your POKEMON are now Hall of Famers!",
      },
    },
  }
  for id,def in pairs(maps) do r.mapsById[id]=fakeMap(def) end
  return r
end

local function makeWorld()
  local save={ party={{species="PIKACHU",level=60}}, player={name="GOLD",kantoBadges={}}, spawnAfterChampion="KEEP_ME" }
  local world={ game={ save=save, data={ trainers={ classes={
    WILL={index=1,name="WILL",attributes={},items={}}, BRUNO={index=2,name="BRUNO",attributes={},items={}},
    KAREN={index=3,name="KAREN",attributes={},items={}}, CHAMPION={index=4,name="CHAMPION",attributes={},items={}},
    RIVAL3={index=5,name="RIVAL",attributes={},items={}}, YOUNGSTER={index=6,name="YOUNGSTER",attributes={},items={}},
  }}}, stack={ push=function(_,screen) pushed[#pushed+1]=screen return true end } } }
  world.startScriptedBattle=function(_,trainer,wild,onDone) captured=trainer; check(wild==nil,"trainer battle"); onDone("win"); return true end
  return world,save
end

local function fresh()
  backing,messages,pushed,captured,hofInductions = {},{},{},nil,0
  Twin._resetKantoStateCacheForTest()
  local e=Twin._excursionForTest
  e.active=true; e.battleBusy=false; e.prevA=false; e.facing="up"; e.lastOutside=nil
end

-- The exact Yellow room block pairs are carried as immutable facts.
do
  fresh(); local r=makeRegion()
  local d=r.loaded.maps.LORELEIS_ROOM
  Twin._applyPhysicalBlocks(r,"LORELEIS_ROOM",d)
  eq(d.blocks[1*0 + 2 + 1],0x24,"Lorelei exit starts closed") -- by=0
  Twin._setKantoEvent(L.ROOMS.LORELEIS_ROOM.event,true)
  Twin._applyPhysicalBlocks(r,"LORELEIS_ROOM",d)
  eq(d.blocks[3],0x05,"Lorelei exit opens after win")

  local a=r.loaded.maps.AGATHAS_ROOM
  Twin._applyPhysicalBlocks(r,"AGATHAS_ROOM",a); eq(a.blocks[3],0x3b,"Agatha exit closed")
  Twin._setKantoEvent(L.ROOMS.AGATHAS_ROOM.event,true)
  Twin._applyPhysicalBlocks(r,"AGATHAS_ROOM",a); eq(a.blocks[3],0x0e,"Agatha exit open")

  local la=r.loaded.maps.LANCES_ROOM
  Twin._applyPhysicalBlocks(r,"LANCES_ROOM",la)
  eq(la.blocks[6*la.width+2+1],0x31,"Lance entrance left open")
  eq(la.blocks[6*la.width+3+1],0x32,"Lance entrance right open")
  Twin._setKantoEvent(L.ROOMS.LANCES_ROOM.lockEvent,true)
  Twin._applyPhysicalBlocks(r,"LANCES_ROOM",la)
  eq(la.blocks[6*la.width+2+1],0x72,"Lance entrance left closed")
  eq(la.blocks[6*la.width+3+1],0x73,"Lance entrance right closed")
end

-- Gold presentation classes are Elite/Champion classes, while roster/name stay Yellow.
do
  fresh(); local r,w=makeRegion(),makeWorld()
  eq(Twin._yellowTrainer(r,w,lorelei,"LORELEIS_ROOM").classId,"WILL","Lorelei Gold presentation")
  eq(Twin._yellowTrainer(r,w,bruno,"BRUNOS_ROOM").classId,"BRUNO","Bruno Gold presentation")
  eq(Twin._yellowTrainer(r,w,agatha,"AGATHAS_ROOM").classId,"KAREN","Agatha Gold presentation")
  eq(Twin._yellowTrainer(r,w,lance,"LANCES_ROOM").classId,"CHAMPION","Lance Gold presentation")
end

-- Entering Lorelei starts a forward-only run; a blackout/reset clears defeated
-- boss persistence so the Elite Four must be fought again.
do
  fresh(); local r=makeRegion()
  Twin._kantoLeagueWarpTransition(r,"INDIGO_PLATEAU_LOBBY","LORELEIS_ROOM")
  check(Twin._kantoEvent(L.START_EVENT),"League run starts")
  check(Twin._kantoLeagueWarpBlocked(r,"LORELEIS_ROOM","INDIGO_PLATEAU_LOBBY"),"Lorelei retreat blocked")
  check(Twin._kantoLeagueWarpBlocked(r,"BRUNOS_ROOM","LORELEIS_ROOM"),"Bruno retreat blocked")
  local id=Twin._trainerWinId("LORELEIS_ROOM",lorelei)
  backing.yellowTrainerWinsV1={[id]=true}
  Twin._setKantoEvent(L.ROOMS.LORELEIS_ROOM.event,true)
  Twin._resetKantoStateCacheForTest() -- re-read seeded wins/events below
  -- reseed event because reset cache does not alter persisted table.
  Twin._setKantoEvent(L.START_EVENT,true); Twin._setKantoEvent(L.ROOMS.LORELEIS_ROOM.event,true)
  Twin._resetKantoLeagueRun(r)
  check(not Twin._kantoEvent(L.START_EVENT),"run flag resets")
  check(not Twin._kantoEvent(L.ROOMS.LORELEIS_ROOM.event),"Lorelei event resets")
  check(backing.yellowTrainerWinsV1[id] == nil,"Lorelei persistent trainer win resets")
end

-- The Champion is Yellow RIVAL3 (party selected by wRivalStarter semantics),
-- then Gold records/animates the Hall of Fame. Gold's pending spawn byte is
-- restored so this parallel Kanto League cannot hijack a native Gold continue.
do
  fresh(); local r=makeRegion(); local w,save=makeWorld()
  local e=Twin._excursionForTest; e.region=r; e.sourceMapId="CHAMPIONS_ROOM"; e.cellX=4; e.cellY=6
  Twin._setKantoEvent(L.START_EVENT,true)
  Twin._setKantoEvent(L.ROOMS.LANCES_ROOM.beatEvent,true)
  check(Twin._kantoChampionInteraction(w,r,"CHAMPIONS_ROOM",rival),"Champion interaction handled")
  check(captured ~= nil,"Champion battle starts")
  eq(captured.classId,"RIVAL3","Champion uses Gold rival class")
  eq(captured.roster[#captured.roster].species,"JOLTEON","default Yellow champion route is Jolteon")
  check(Twin._kantoEvent(L.HOF_EVENT),"Kanto Hall of Fame completion persists")
  eq(hofInductions,1,"Gold Hall of Fame core used")
  eq(save.hallOfFame.count,1,"Gold Hall of Fame counter increments")
  eq(save.spawnAfterChampion,"KEEP_ME","Gold pending spawn preserved")
  local hofScreen
  for _,screen in ipairs(pushed) do if screen.kind=="hof" then hofScreen=screen end end
  check(hofScreen and hofScreen.onDone,"Gold Hall of Fame UI pushed")
  Twin._palletStart=function() return 5,5 end
  hofScreen.onDone()
  eq(Twin._excursionForTest.sourceMapId,"PALLET_TOWN","Hall of Fame returns to Kanto Pallet")
  check(not Twin._kantoEvent(L.START_EVENT),"League run reset for rematch after Hall of Fame")
  check(Twin._kantoEvent(L.HOF_EVENT),"Hall of Fame achievement survives run reset")
end

print("kanto_league_hall_of_fame_parity: OK")
