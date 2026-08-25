-- v0.3.84 regression: Rocket Hideout, Pokemon Tower, Mr. Fuji, Poke Flute
-- and the two sleeping Snorlax form one persistent Kanto-local quest chain
-- while battles/Pokemon remain genuine Gold runtime state.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.core.Sound"] = function() return { play=function() return true end } end
package.preload["src.battle.gen2.Mon"] = function()
  return {
    new = function(_, species, level)
      return { species=species, level=level, hp=100, maxHp=100 }
    end,
  }
end

_G.love = { math={ random=function(a) return a end } }

local backing, messages, choices, menus = {}, {}, {}, {}
local autoDone = true
local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages+1] = tostring(text)
    if opts and type(opts.choice) == "function" then
      local yes = #choices > 0 and table.remove(choices, 1) or false
      opts.choice(yes == true)
    elseif onDone and autoDone then
      onDone()
    end
    return { text=text, onDone=onDone }
  end,
}
local ListMenu = {
  new = function(_, title, items, opts)
    local menu = { title=title, items=items, opts=opts,
      close=function(self) self.closed=true end }
    menus[#menus+1] = menu
    return menu
  end,
}
local mod = {
  exports={}, options={ get=function() return nil end },
  ui={ TextBox=TextBox, ListMenu=ListMenu },
  save={
    get=function(_, key, fallback)
      local v=backing[key]; return v == nil and fallback or v
    end,
    set=function(_, key, value) backing[key]=value; return true end,
  },
}
local stubs = {
  Quality={ kantoRadius=function() return 1 end,
            actorDistanceCells=function() return math.huge end },
  FirstPerson={ driving=function() return false end, releaseBody=function() end },
  ChunkMesher={ warmPending=function() return 0 end, refresh=function() return true end },
  KantoGen2Style={ PROJECTION_REV="test" },
  runtime_sheets={ new=function() return { load=function() return true end } end },
}
local V={ mod=mod, require=function(name) return stubs[name] or {} end }
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Items=Twin._kantoItemsForTest

local function check(v,label) if not v then error(label or "check failed",2) end end
local function eq(a,b,label) if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local lift={ index=9, x=10,y=2, item="LIFT_KEY", text="TEXT_ROCKETHIDEOUTB4F_LIFT_KEY", hidden=true }
local scope={ index=8, x=25,y=2, item="SILPH_SCOPE", text="TEXT_ROCKETHIDEOUTB4F_SILPH_SCOPE", hidden=true }
local rocket={ index=4, x=11,y=2, trainerClass="OPP_ROCKET", trainerParty=18, text="TEXT_ROCKETHIDEOUTB4F_ROCKET" }
local giovanni={ index=1, x=25,y=3, trainerClass="OPP_GIOVANNI", trainerParty=1, text="TEXT_ROCKETHIDEOUTB4F_GIOVANNI" }
local rhJessie={ index=3, x=24,y=10, text="TEXT_ROCKETHIDEOUTB4F_JESSIE", hidden=true }
local rhJames={ index=2, x=25,y=10, text="TEXT_ROCKETHIDEOUTB4F_JAMES", hidden=true }
local towerJessie={ index=1,x=10,y=8,text="TEXT_POKEMONTOWER7F_JESSIE",hidden=true }
local towerJames={ index=2,x=11,y=8,text="TEXT_POKEMONTOWER7F_JAMES",hidden=true }
local towerFuji={ index=3,x=10,y=3,text="TEXT_POKEMONTOWER7F_MR_FUJI" }
local houseFuji={ index=5,x=3,y=1,text="TEXT_MRFUJISHOUSE_MR_FUJI",hidden=true }
local snorlax12={ index=1,x=10,y=62,text="TEXT_ROUTE12_SNORLAX" }
local snorlax16={ index=7,x=14,y=10,text="TEXT_ROUTE16_SNORLAX" }

local region={
  loaded={
    maps={
      ROCKET_HIDEOUT_B4F={ objects={giovanni,rhJames,rhJessie,rocket,scope,lift} },
      ROCKET_HIDEOUT_ELEVATOR={ objects={} },
      POKEMON_TOWER_6F={ objects={} },
      POKEMON_TOWER_7F={ objects={towerJessie,towerJames,towerFuji} },
      MR_FUJIS_HOUSE={ objects={houseFuji}, warps={{x=2,y=7}} },
      ROUTE_12={ objects={snorlax12} }, ROUTE_16={ objects={snorlax16} },
    },
    trainers={
      OPP_ROCKET={ name="ROCKET", index=1, baseMoney=30,
        parties={ [43]={{species="KOFFING",level=25}}, [44]={{species="ARBOK",level=27}} } },
      OPP_GIOVANNI={ name="GIOVANNI", index=1, baseMoney=99,
        parties={ [1]={{species="PERSIAN",level=25}} } },
    },
    text={}, field={}, items={},
  },
  mapsById={}, npcCache={}, pokemonCache={}, validOutdoor={},
}

local scripted, wildBattles = {}, {}
local world={ game={
  data={
    pokemon={ MAROWAK={}, SNORLAX={}, KOFFING={}, ARBOK={}, PERSIAN={} }, moves={}, items={},
    trainers={ classes={
      CHANNELER={ index=60,name="CHANNELER",attributes={},items={} },
      YOUNGSTER={ index=22,name="YOUNGSTER",attributes={},items={} },
    } },
  },
  save={ player={name="GOLD",id=123}, inventory={}, party={}, pokedex={seen={},caught={}} },
  stack={ push=function(self,x) self.last=x; return true end, top=function(self) return self.last end,
          pop=function(self) local x=self.last; self.last=nil; return x end },
} }
world.startScriptedBattle=function(self, trainer, wild, onDone)
  scripted[#scripted+1]=trainer
  if onDone then onDone("win") end
  return true
end
world.startBattle=function(self, opts, onDone)
  wildBattles[#wildBattles+1]=opts and opts.wild
  if onDone then onDone("win") end
  return true
end

local function fresh()
  backing,messages,choices,menus,scripted,wildBattles={},{},{},{},{},{}
  autoDone=true
  world.game.save={ player={name="GOLD",id=123}, inventory={}, party={}, pokedex={seen={},caught={}} }
  region.npcCache,region.pokemonCache={},{}
  world.game.stack.last=nil
  if Twin._resetKantoStateCacheForTest then Twin._resetKantoStateCacheForTest() end
end

-- New Yellow-only quest keys never alias Gold inventory/story keys.
do
  fresh()
  check(Items.isLocalOnly("LIFT_KEY"), "Lift Key is Kanto-local")
  check(Items.isLocalOnly("SILPH_SCOPE"), "Silph Scope is Kanto-local")
  check(Items.isLocalOnly("POKE_FLUTE"), "Poke Flute is Kanto-local")
  world.game.save.inventory.LIFT_KEY=1
  check(not Twin._kantoItemHeld(world,"LIFT_KEY"), "same-named Gold inventory cannot satisfy Kanto key")
end

-- B4F trainer wins reveal the physically hidden Lift Key and Silph Scope.
do
  fresh()
  Twin._kantoAfterQuestTrainerWin(region,"ROCKET_HIDEOUT_B4F",rocket)
  check(Twin._kantoEvent(Items.ROCKET_HIDEOUT.droppedLiftKeyEvent), "Rocket drop event set")
  check(Twin._kantoObjectShown("ROCKET_HIDEOUT_B4F",lift), "hidden Lift Key forced visible")
  Twin._kantoAfterQuestTrainerWin(region,"ROCKET_HIDEOUT_B4F",giovanni)
  check(Twin._kantoEvent(Items.ROCKET_HIDEOUT.giovanniEvent), "Giovanni event set")
  check(Twin._kantoObjectShown("ROCKET_HIDEOUT_B4F",scope), "hidden Silph Scope forced visible")
  check(Twin._kantoObjectHidden("ROCKET_HIDEOUT_B4F",giovanni), "Giovanni leaves after defeat")
end

-- Elevator is locked before the local Lift Key and exposes exactly B1F/B2F/B4F after it.
do
  fresh()
  check(Twin._kantoRocketElevator(world,region), "locked elevator interaction handled")
  eq(#menus,0,"no floor menu without key")
  Twin._giveKantoLocalItem("LIFT_KEY")
  check(Twin._kantoRocketElevator(world,region), "unlocked elevator opens")
  eq(#menus,1,"one elevator menu")
  eq(menus[1].items[1].label,"B1F","first floor")
  eq(menus[1].items[2].label,"B2F","second floor")
  eq(menus[1].items[3].label,"B4F","third floor")
end

-- Tower gate refuses Marowak without Scope, then runs a non-catchable scripted
-- level-30 MAROWAK battle and persists the restless-soul event with Scope.
do
  fresh()
  local gate=Twin._kantoItemGateForStep(region,"POKEMON_TOWER_6F",10,16,"left")
  check(gate and gate.item=="SILPH_SCOPE","Marowak cell requires Scope")
  Twin._kantoTowerMarowakStep(world,region,"POKEMON_TOWER_6F",10,16)
  eq(#scripted,0,"no identified Marowak battle without Scope")
  Twin._giveKantoLocalItem("SILPH_SCOPE")
  Twin._kantoTowerMarowakStep(world,region,"POKEMON_TOWER_6F",10,16)
  eq(#scripted,1,"Marowak scripted battle starts")
  eq(scripted[1].roster[1].species,"MAROWAK","restless soul species")
  eq(scripted[1].roster[1].level,30,"restless soul level")
  check(Twin._kantoEvent(Items.POKEMON_TOWER.marowakEvent),"Marowak event persists")
end

-- Tower Jessie/James becomes a real Yellow trainer party inside Gold, then both
-- actors disappear and Fuji can be rescued into his house.
do
  fresh()
  Twin._setKantoEvent(Items.POKEMON_TOWER.marowakEvent,true)
  Twin._kantoTowerRocketStep(world,region,"POKEMON_TOWER_7F",10,12)
  eq(#scripted,1,"Tower Rocket battle starts")
  eq(scripted[1].roster[1].species,"ARBOK","Yellow Tower Rocket party 44 used")
  check(Twin._kantoEvent(Items.POKEMON_TOWER.rocketEvent),"Tower Rocket event persists")
  check(Twin._kantoObjectHidden("POKEMON_TOWER_7F",towerJessie),"Jessie hidden after win")
  check(Twin._kantoObjectHidden("POKEMON_TOWER_7F",towerJames),"James hidden after win")

  autoDone=false -- verify rescue state without requiring a real map adapter warp in this unit test
  check(Twin._kantoRescueMrFuji(world,region,"POKEMON_TOWER_7F",towerFuji),"Fuji rescue handled")
  check(Twin._kantoEvent(Items.POKEMON_TOWER.rescueEvent),"Fuji rescue event")
  check(Twin._kantoObjectHidden("POKEMON_TOWER_7F",towerFuji),"Tower Fuji removed")
  check(Twin._kantoObjectShown("MR_FUJIS_HOUSE",houseFuji),"house Fuji revealed")
end

-- Rescued Fuji gives one Kanto-local Poke Flute. It does not enter Gold's Pack.
do
  fresh()
  Twin._setKantoEvent(Items.POKEMON_TOWER.rescueEvent,true)
  check(Twin._kantoMrFujiFlute(world,region,"MR_FUJIS_HOUSE",houseFuji),"Fuji flute handled")
  check(Twin._kantoItemHeld(world,"POKE_FLUTE"),"Poke Flute owned locally")
  eq(world.game.save.inventory.POKE_FLUTE,nil,"Poke Flute does not pollute Gold inventory")
  check(Twin._kantoEvent(Items.POKEMON_TOWER.fluteEvent),"flute event persists")
end

-- Both sleeping Snorlax are inert without the Flute. With it they enter Gold's
-- normal wild-battle path at level 30 and disappear permanently after battle.
do
  fresh()
  check(Twin._kantoSnorlaxInteraction(world,region,"ROUTE_12",snorlax12),"sleeping Snorlax handled")
  eq(#wildBattles,0,"no Snorlax battle without Flute")
  Twin._giveKantoLocalItem("POKE_FLUTE")
  choices={true}
  check(Twin._kantoSnorlaxInteraction(world,region,"ROUTE_12",snorlax12),"Route12 flute use")
  eq(#wildBattles,1,"Route12 Snorlax Gold wild battle")
  eq(wildBattles[1].species,"SNORLAX","Route12 species")
  eq(wildBattles[1].level,30,"Route12 level")
  check(Twin._kantoEvent(Items.SNORLAX.ROUTE_12.event),"Route12 Snorlax cleared")
  check(Twin._kantoObjectHidden("ROUTE_12",snorlax12),"Route12 body removed")

  choices={true}
  check(Twin._kantoSnorlaxInteraction(world,region,"ROUTE_16",snorlax16),"Route16 flute use")
  eq(#wildBattles,2,"Route16 Snorlax Gold wild battle")
  eq(wildBattles[2].level,30,"Route16 level")
  check(Twin._kantoEvent(Items.SNORLAX.ROUTE_16.event),"Route16 Snorlax cleared")
end

print("kanto_rocket_tower_flute_parity: ok")
