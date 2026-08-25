-- v0.3.99 regression: final uncovered Yellow TM gifts.
-- Celadon Mart 3F TM18 COUNTER and Cinnabar Lab TM35 METRONOME must not
-- inject Gold's unrelated numeric TM18/TM35 items.

package.preload["src.render.Assets"] = function() return {} end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

local partyScreens = {}
package.preload["src.ui.gen2.PartyMenu"] = function()
  return {
    new = function(_, opts)
      local s={opts=opts}
      partyScreens[#partyScreens+1]=s
      return s
    end,
  }
end

_G.love={math={random=function(a) return a end}}

local backing,messages={},{}
local TextBox={
  new=function(_,text,onDone)
    messages[#messages+1]=tostring(text)
    if onDone then onDone() end
    return {text=text}
  end,
}
local mod={
  exports={},options={get=function() return nil end},
  ui={TextBox=TextBox,ListMenu={new=function() return {} end}},
  save={
    get=function(_,k,f) local v=backing[k]; return v==nil and f or v end,
    set=function(_,k,v) backing[k]=v; return true end,
  },
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
local Rewards=Twin._rewardsForTest

local function check(v,l) if not v then error(l or "check failed",2) end end
local function eq(a,b,l)
  if a~=b then error((l or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end
end

local learned={}
local world={game={
  save=nil,
  data={
    items={
      TM18={name="TM18",teaches="RAIN_DANCE"},
      TM35={name="TM35",teaches="SLEEP_TALK"},
    },
    moves={
      COUNTER={name="COUNTER"},METRONOME={name="METRONOME"},
      RAIN_DANCE={name="RAIN DANCE"},SLEEP_TALK={name="SLEEP TALK"},
    },
    pokemon={},
  },
  stack={push=function() return true end},
}}
world.game.learnMoveOn=function(self,mon,move,cb)
  learned[#learned+1]=move
  mon.moves=mon.moves or {}
  mon.moves[#mon.moves+1]={id=move}
  cb(true)
end

local region={mapsById={},npcCache={},pokemonCache={},loaded={
  field={},items={},maps={},
  pokemon={
    MACHOP={tmhm={"COUNTER"}},
    CLEFAIRY={tmhm={"METRONOME"}},
    MAGIKARP={tmhm={}},
  },
  text={
    _CeladonMart3FClerkTM18PreReceiveText="TAKE COUNTER",
    _CeladonMart3FClerkReceivedTM18Text="GOT COUNTER",
    _CeladonMart3FClerkTM18ExplanationText="COUNTER EXPLAIN",
    _CinnabarLabMetronomeRoomScientist1Text="TAKE METRONOME",
    _CinnabarLabMetronomeRoomScientist1ReceivedTM35Text="GOT METRONOME",
    _CinnabarLabMetronomeRoomScientist1TM35ExplanationText="METRONOME EXPLAIN",
  },
}}

local function fresh()
  backing,messages,partyScreens,learned={},{},{},{}
  world.game.save={
    inventory={},
    party={{species="MACHOP",moves={}}, {species="CLEFAIRY",moves={}}, {species="MAGIKARP",moves={}}},
    player={name="GOLD"},
  }
  Twin._resetKantoStateCacheForTest()
end

local function reward(map,text)
  local spec=Rewards.match(map,text)
  check(spec,"matched "..map)
  eq(spec.kind,"yellow_tm","yellow TM type")
  Twin._talkKantoScriptedReward(world,region,spec)
  return spec
end

-- Celadon Counter: never award Gold's TM18 Rain Dance.
do
  fresh()
  local spec=reward("CELADON_MART_3F","TEXT_CELADONMART3F_CLERK")
  eq(spec.move,"COUNTER","Counter move identity")
  eq(world.game.save.inventory.TM18,nil,"Gold TM18 not injected")
  check(Twin._kantoEvent("EVENT_GOT_TM18"),"Yellow TM18 event")
  check(Twin._kantoEvent("EVENT_KANTO_CELADON_TM18_CREDIT"),"Counter credit")
  partyScreens[#partyScreens].opts.onChoose(3,world.game.save.party[3])
  eq(#learned,0,"Magikarp incompatible with Counter")
  check(Twin._kantoEvent("EVENT_KANTO_CELADON_TM18_CREDIT"),"failed Counter teach keeps credit")
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  eq(learned[1],"COUNTER","teaches Counter")
  check(not Twin._kantoEvent("EVENT_KANTO_CELADON_TM18_CREDIT"),"Counter credit consumed")
end

-- Cinnabar Metronome: never award Gold's TM35 Sleep Talk.
do
  fresh()
  local spec=reward("CINNABAR_LAB_METRONOME_ROOM","TEXT_CINNABARLABMETRONOMEROOM_SCIENTIST1")
  eq(spec.move,"METRONOME","Metronome move identity")
  eq(world.game.save.inventory.TM35,nil,"Gold TM35 not injected")
  check(Twin._kantoEvent("EVENT_GOT_TM35"),"Yellow TM35 event")
  check(Twin._kantoEvent("EVENT_KANTO_CINNABAR_TM35_CREDIT"),"Metronome credit")
  partyScreens[#partyScreens].opts.onChoose(2,world.game.save.party[2])
  eq(learned[1],"METRONOME","teaches Metronome")
  check(not Twin._kantoEvent("EVENT_KANTO_CINNABAR_TM35_CREDIT"),"Metronome credit consumed")
end

-- Each reward stays one-time after its local credit is spent.
do
  fresh()
  reward("CELADON_MART_3F","TEXT_CELADONMART3F_CLERK")
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  local before=#partyScreens
  reward("CELADON_MART_3F","TEXT_CELADONMART3F_CLERK")
  eq(#partyScreens,before,"spent Counter reward does not create a second machine")
  eq(messages[#messages],"COUNTER EXPLAIN","post-Counter explanation")
end

print("kanto_final_yellow_tm_gifts_parity: OK")
