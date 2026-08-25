-- v0.3.85 regression: Yellow Kanto's physical dungeon mechanics remain real
-- inside Gold even though the excursion does not execute Yellow map ASM.
-- Covers Pokemon Mansion statue switches/falls, Victory Road boulder switches,
-- the 3F boulder drop, and one-off static Pokemon run persistence.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.battle.gen2.Mon"] = function()
  return { new = function(_, species, level) return { species=species, level=level } end }
end

local backing, messages, choices = {}, {}, {}
_G.love = { math = { random = function(a) return a end } }

local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = text
    if opts and opts.choice then
      opts.choice(#choices > 0 and table.remove(choices, 1) or false)
    elseif onDone then
      onDone()
    end
    return { text=text, onDone=onDone }
  end,
}

local mod = {
  exports={}, options={ get=function() return nil end }, ui={ TextBox=TextBox },
  save={
    get=function(_, key, fallback)
      local v=backing[key]; return v == nil and fallback or v
    end,
    set=function(_, key, value) backing[key]=value; return true end,
  },
}

local refreshes = 0
local stubs = {
  Quality={ kantoRadius=function() return 1 end,
            actorDistanceCells=function() return math.huge end },
  FirstPerson={ driving=function() return false end, releaseBody=function() end },
  ChunkMesher={ warmPending=function() return 0 end,
                refresh=function() refreshes=refreshes+1; return true end },
  KantoGen2Style={ PROJECTION_REV="test" },
  runtime_sheets={ new=function() return { load=function() return true end } end },
}
local V={ mod=mod, require=function(name) return stubs[name] or {} end }
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local P=Twin._kantoDungeonPuzzlesForTest

local function check(v,label) if not v then error(label or "check failed",2) end end
local function eq(a,b,label)
  if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end
end
local function fresh()
  backing,messages,choices={}, {}, {}
  refreshes=0
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
  local ex=Twin._excursionForTest
  ex.facing="down"; ex.battleBusy=false; ex.safari=false; ex.prevA=false
end
local function def(id,w,h,fill)
  local blocks={}
  for i=1,w*h do blocks[i]=fill or 0x66 end
  return { id=id,width=w,height=h,blocks=blocks,objects={} }
end
local function block(d,bx,by) return d.blocks[by*d.width+bx+1] end
local function regionWith(mapdefs)
  return { version="yellow", mapsById={}, npcCache={}, pokemonCache={},
    loaded={ maps=mapdefs or {}, field={}, text={}, trainers={} } }
end
local function liveMap(d)
  local m={ id="__GEN1__"..d.id, sourceId=d.id, def=d }
  function m:blockAt(bx,by) return block(d,bx,by) end
  function m:setBlock(bx,by,b) d.blocks[by*d.width+bx+1]=b; return true end
  return m
end

-- Exact hidden switch coordinates and facing gate.
do
  fresh()
  check(P.mansionSwitchAt("POKEMON_MANSION_1F",2,5,"up"),"1F switch coordinate")
  check(P.mansionSwitchAt("POKEMON_MANSION_2F",2,11,"up"),"2F switch coordinate")
  check(P.mansionSwitchAt("POKEMON_MANSION_3F",10,5,"up"),"3F switch coordinate")
  check(P.mansionSwitchAt("POKEMON_MANSION_B1F",20,3,"up"),"B1F left switch")
  check(P.mansionSwitchAt("POKEMON_MANSION_B1F",18,25,"up"),"B1F right switch")
  check(not P.mansionSwitchAt("POKEMON_MANSION_1F",2,5,"left"),"Mansion switch requires facing up")
end

-- Mansion block sets reconstruct exact OFF and ON states instead of toggling
-- blindly from whatever a previous visit left in the shared map definition.
do
  fresh()
  local d=def("POKEMON_MANSION_1F",20,20,0x77)
  local r=regionWith({POKEMON_MANSION_1F=d})
  Twin._applyPhysicalBlocks(r,"POKEMON_MANSION_1F",d)
  eq(block(d,12,6),0x0e,"Mansion 1F off floor")
  eq(block(d,8,3),0x2d,"Mansion 1F off gate")
  Twin._setKantoEvent(P.MANSION_EVENT,true)
  Twin._applyPhysicalBlocks(r,"POKEMON_MANSION_1F",d)
  eq(block(d,12,6),0x2d,"Mansion 1F on gate")
  eq(block(d,8,3),0x0e,"Mansion 1F alternating gate opens")
  eq(block(d,10,8),0x0e,"Mansion 1F second alternating gate opens")
  eq(block(d,13,13),0x0e,"Mansion 1F third alternating gate opens")
end

-- Live statue interaction toggles the shared event and immediately changes
-- collision/mesh blocks on the active floor.
do
  fresh()
  local d=def("POKEMON_MANSION_2F",16,16,0x77)
  local m=liveMap(d)
  local r=regionWith({POKEMON_MANSION_2F=d}); r.mapsById.POKEMON_MANSION_2F=m
  Twin._excursionForTest.facing="up"
  choices={true}
  local world={game={stack={push=function() return true end}}}
  check(Twin._tryMansionSwitch(world,r,"POKEMON_MANSION_2F",m,2,11),"Mansion live switch handled")
  check(Twin._kantoEvent(P.MANSION_EVENT),"Mansion shared event on")
  eq(block(d,4,2),0x5f,"Mansion 2F on closed set")
  eq(block(d,9,4),0x0e,"Mansion 2F on open set")
  check(refreshes>0,"live switch refreshes voxel geometry")
  eq(messages[#messages],"Who wouldn't?","Mansion pressed text")
end

-- Loading Cinnabar Island resets the retail global mansion switch.
do
  fresh()
  Twin._setKantoEvent(P.MANSION_EVENT,true)
  Twin._kantoOnMapEntered(regionWith({}),"CINNABAR_ISLAND")
  check(not Twin._kantoEvent(P.MANSION_EVENT),"Cinnabar entry resets Mansion switch")
end

-- Victory Road 1F preserves the authored closed block so the temporary event
-- can open it and the 2F-load reset can restore the original value.
do
  fresh()
  local d=def("VICTORY_ROAD_1F",10,10,0x66)
  d.blocks[6*d.width+4+1]=0x4a
  local r=regionWith({VICTORY_ROAD_1F=d})
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_1F",d)
  eq(block(d,4,6),0x4a,"Victory 1F authored closed block remembered")
  Twin._setKantoEvent("EVENT_VICTORY_ROAD_1_BOULDER_ON_SWITCH",true)
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_1F",d)
  eq(block(d,4,6),0x1d,"Victory 1F switch opens gate")
  Twin._kantoOnMapEntered(r,"VICTORY_ROAD_2F")
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_1F",d)
  eq(block(d,4,6),0x4a,"Victory 2F entry resets/restores 1F gate")
end

-- Victory Road 2F has two independent switch/gate pairs; 3F has one.
do
  fresh()
  local d2=def("VICTORY_ROAD_2F",16,20,0x44)
  local d3=def("VICTORY_ROAD_3F",10,10,0x55)
  local r=regionWith({VICTORY_ROAD_2F=d2,VICTORY_ROAD_3F=d3})
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_2F",d2)
  Twin._setKantoEvent("EVENT_VICTORY_ROAD_2_BOULDER_ON_SWITCH1",true)
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_2F",d2)
  eq(block(d2,3,4),0x15,"Victory 2F switch 1 opens gate")
  eq(block(d2,11,7),0x44,"Victory 2F switch 2 still closed")
  Twin._setKantoEvent("EVENT_VICTORY_ROAD_2_BOULDER_ON_SWITCH2",true)
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_2F",d2)
  eq(block(d2,11,7),0x1d,"Victory 2F switch 2 opens gate")
  Twin._setKantoEvent("EVENT_VICTORY_ROAD_3_BOULDER_ON_SWITCH1",true)
  Twin._applyPhysicalBlocks(r,"VICTORY_ROAD_3F",d3)
  eq(block(d3,3,5),0x1d,"Victory 3F switch opens gate")
end

-- The 3F hole transfers the authored boulder into Victory Road 2F and makes it
-- visible at 23,16 for the lower-floor puzzle.
do
  fresh()
  local src={ index=10,sprite="SPRITE_BOULDER",x=22,y=15 }
  local dst={ index=13,sprite="SPRITE_BOULDER",x=23,y=16,hidden=true }
  local r=regionWith({
    VICTORY_ROAD_3F={objects={src}},
    VICTORY_ROAD_2F={objects={dst}},
  })
  local entity={ def=src,isBoulder=true,cellX=22,cellY=15 }
  local hole=P.victoryBoulderHole("VICTORY_ROAD_3F",23,15)
  check(Twin._dropVictoryRoadBoulder(r,"VICTORY_ROAD_3F",entity,hole),"Victory Road boulder falls")
  check(Twin._kantoEvent("EVENT_VICTORY_ROAD_3_BOULDER_ON_SWITCH2"),"Victory boulder-hole event persists")
  check(not Twin._kantoBoulderVisible("VICTORY_ROAD_3F",src),"3F boulder hidden")
  check(Twin._kantoBoulderVisible("VICTORY_ROAD_2F",dst),"2F destination boulder revealed")
  local x,y=Twin._kantoBoulderPosition("VICTORY_ROAD_2F",dst)
  eq(x,23,"destination boulder x"); eq(y,16,"destination boulder y")
end

-- Pokemon Mansion 3F broken floors use Yellow's dungeon-warp landing table.
do
  fresh()
  local map,x,y=Twin._resolveDungeonHole(nil,"POKEMON_MANSION_3F",16,14)
  eq(map,"POKEMON_MANSION_1F","Mansion left hole destination")
  eq(x,16,"Mansion left hole x"); eq(y,14,"Mansion left hole y")
  map,x,y=Twin._resolveDungeonHole(nil,"POKEMON_MANSION_3F",17,14)
  eq(map,"POKEMON_MANSION_1F","Mansion middle hole destination")
  map,x,y=Twin._resolveDungeonHole(nil,"POKEMON_MANSION_3F",19,14)
  eq(map,"POKEMON_MANSION_2F","Mansion right hole destination")
  eq(x,18,"Mansion right hole x"); eq(y,14,"Mansion right hole y")
end

-- Yellow's one-off wild TrainerHeader objects are removed by EndTrainerBattle
-- after RUN as well as win/catch. Match that for the legendary/static bridge.
do
  fresh()
  local obj={ index=6,pokemon="MOLTRES",level=50,x=11,y=5 }
  local entity={ staticYellowPokemon=true,sourceObject=obj,cellX=11,cellY=5 }
  local r=regionWith({VICTORY_ROAD_2F={objects={obj}}})
  r.pokemonCache.VICTORY_ROAD_2F={entity}
  local world={ game={ data={pokemon={MOLTRES={}},moves={}},
                       save={pokedex={seen={},caught={}},party={}} } }
  world.startBattle=function(_,opts,onDone)
    check(opts and opts.wild and opts.wild.species=="MOLTRES","Gold static wild battle built")
    onDone("run")
    return true
  end
  check(Twin._startYellowWildBattle(world,r,"VICTORY_ROAD_2F","MOLTRES",50,entity),"static battle starts")
  check(Twin._staticPokemonCleared("VICTORY_ROAD_2F",obj),"running clears one-off static Pokemon")
end

print("kanto_dungeon_puzzle_parity: OK")
