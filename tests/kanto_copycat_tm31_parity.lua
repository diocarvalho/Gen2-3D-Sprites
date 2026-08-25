-- v0.3.96 regression: Copycat's POKE DOLL trade awards Yellow TM31
-- MIMIC as a Kanto-local one-use machine credit, never Gold's unrelated TM31.

package.preload["src.render.Assets"] = function() return {} end

local removed = {}
package.preload["src.inventory.Bag"] = function()
  return {
    remove = function(save, id, count)
      local have = tonumber(save.inventory and save.inventory[id]) or 0
      count = tonumber(count) or 1
      if have < count then return false end
      local left = have - count
      save.inventory[id] = left > 0 and left or nil
      removed[#removed + 1] = id
      return true
    end,
  }
end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end

local partyScreens = {}
package.preload["src.ui.gen2.PartyMenu"] = function()
  return {
    new = function(_, opts)
      local screen = { opts = opts }
      partyScreens[#partyScreens + 1] = screen
      return screen
    end,
  }
end

_G.love = { math = { random = function(a) return a end } }

local backing, messages = {}, {}
local TextBox = {
  new = function(_, text, onDone)
    messages[#messages + 1] = tostring(text)
    if onDone then onDone() end
    return { text = text }
  end,
}
local mod = {
  exports={}, options={get=function() return nil end},
  ui={TextBox=TextBox,ListMenu={new=function() return {} end}},
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
local Rewards=Twin._rewardsForTest

local function check(v,label) if not v then error(label or "check failed",2) end end
local function eq(a,b,label)
  if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end
end

local copycat={text="TEXT_COPYCATSHOUSE2F_COPYCAT",x=4,y=3}
local region={mapsById={},npcCache={},pokemonCache={},loaded={
  maps={COPYCATS_HOUSE_2F={objects={copycat}}},
  field={},items={},
  pokemon={
    ABRA={tmhm={"MIMIC"}},
    MAGIKARP={tmhm={}},
  },
  text={
    _CopycatsHouse2FCopycatDoYouLikePokemonText="DO YOU LIKE POKEMON",
    _CopycatsHouse2FCopycatTM31PreReceiveText="POKE DOLL PLEASE",
    _CopycatsHouse2FCopycatReceivedTM31Text="RECEIVED {RAM:BUFFER}",
    _CopycatsHouse2FCopycatTM31Explanation1Text="MIMIC FIRST EXPLAIN",
    _CopycatsHouse2FCopycatTM31Explanation2Text="MIMIC EXPLAIN",
  },
}}
local learned={}
local stack={push=function(self,x) self.last=x; return true end}
local world={game={
  data={
    items={
      POKE_DOLL={name="POKE DOLL"},
      -- This is intentionally the unrelated Gold TM31. The test ensures it is
      -- never inserted into Gold's inventory by the Yellow reward.
      TM31={name="TM31",teaches="MUD_SLAP"},
    },
    moves={MIMIC={name="MIMIC"},MUD_SLAP={name="MUD-SLAP"}},
    pokemon={},
  },
  stack=stack,
  save=nil,
}}
world.game.learnMoveOn=function(self,mon,moveId,cb)
  learned[#learned+1]=moveId
  mon.moves=mon.moves or {}
  mon.moves[#mon.moves+1]={id=moveId}
  cb(true)
end

local function fresh()
  backing,messages,partyScreens,removed,learned={},{},{},{},{}
  world.game.save={
    inventory={},
    party={{species="ABRA",moves={}}, {species="MAGIKARP",moves={}}},
    player={name="GOLD"},
  }
  Twin._resetKantoStateCacheForTest()
end

local function talk()
  return Twin._tryKantoSpecialObjectInteraction(world,region,"COPYCATS_HOUSE_2F",copycat)
end

check(Rewards.isCopycat("COPYCATS_HOUSE_2F",copycat.text),"Copycat recognized")
check(not Rewards.isCopycat("SAFFRON_CITY",copycat.text),"Copycat map scoped")

-- No doll: just normal Copycat dialogue.
do
  fresh(); talk()
  eq(messages[#messages],"DO YOU LIKE POKEMON","no-doll dialogue")
  check(not Twin._kantoEvent("EVENT_GOT_TM31"),"no TM without doll")
end

-- Doll trade creates the Yellow MIMIC credit, consumes exactly one doll, and
-- never puts Gold's unrelated TM31 into the PACK.
do
  fresh()
  world.game.save.inventory.POKE_DOLL=2
  talk()
  eq(world.game.save.inventory.POKE_DOLL,1,"one doll consumed")
  eq(world.game.save.inventory.TM31,nil,"Gold TM31 not awarded")
  check(Twin._kantoEvent("EVENT_GOT_TM31"),"Yellow receive event persisted")
  check(Twin._kantoEvent("EVENT_KANTO_COPYCAT_TM31_CREDIT"),"Mimic credit persisted")
  check(#partyScreens==1,"teach picker opens")
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  eq(learned[1],"MIMIC","teaches Yellow MIMIC")
  check(not Twin._kantoEvent("EVENT_KANTO_COPYCAT_TM31_CREDIT"),"credit consumed on learn")
  check(Twin._kantoEvent("EVENT_GOT_TM31"),"receive event remains after use")
end

-- Incompatible species cannot consume the credit; it stays available.
do
  fresh()
  world.game.save.inventory.POKE_DOLL=1
  talk()
  partyScreens[#partyScreens].opts.onChoose(2,world.game.save.party[2])
  eq(#learned,0,"Magikarp refused MIMIC")
  check(Twin._kantoEvent("EVENT_KANTO_COPYCAT_TM31_CREDIT"),"failed teach keeps credit")
  talk()
  check(#partyScreens>=2,"talking again reopens pending credit")
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  eq(learned[1],"MIMIC","retry teaches MIMIC")
end

-- Once the credit is spent, Copycat never takes another doll and stays on her
-- post-reward explanation.
do
  fresh()
  world.game.save.inventory.POKE_DOLL=2
  talk()
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  local remaining=world.game.save.inventory.POKE_DOLL
  talk()
  eq(world.game.save.inventory.POKE_DOLL,remaining,"no second doll consumed")
  eq(messages[#messages],"MIMIC EXPLAIN","post-reward explanation")
end

print("kanto_copycat_tm31_parity: OK")
