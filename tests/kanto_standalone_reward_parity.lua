-- v0.3.97: remaining standalone Kanto reward parity.
-- Covers Celadon Diner Coin Case, Route 12 Gate TM39 Swift, and Silph 2F's
-- Yellow-only TM36 Selfdestruct credit.

package.preload["src.render.Assets"] = function() return {} end

local added, removed = {}, {}
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, id, count)
      save.inventory = save.inventory or {}
      save.inventory[id] = (tonumber(save.inventory[id]) or 0) + (count or 1)
      added[#added + 1] = id
      return true
    end,
    remove = function(save, id, count)
      local have = tonumber(save.inventory and save.inventory[id]) or 0
      count = count or 1
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

local region={mapsById={},npcCache={},pokemonCache={},loaded={
  maps={}, field={}, items={},
  pokemon={
    VOLTORB={tmhm={"SELFDESTRUCT"}},
    MAGIKARP={tmhm={}},
  },
  text={
    _CeladonDinerGymGuideImFlatOutBustedText="BUSTED",
    _CeladonDinerGymGuideReceivedCoinCaseText="GOT COIN CASE",
    _CeladonDinerGymGuideWinItBackText="WIN IT BACK",
    _Route12Gate2FBrunetteGirlYouCanHaveThisText="TAKE SWIFT",
    _Route12Gate2FBrunetteGirlReceivedTM39Text="GOT SWIFT",
    _Route12Gate2FBrunetteGirlTM39ExplanationText="SWIFT EXPLAIN",
    SilphCo2FSilphWorkerFPleaseTakeThisText="TAKE SELFDESTRUCT",
    _SilphCo2FSilphWorkerFReceivedTM36Text="GOT SELFDESTRUCT",
    _SilphCo2FSilphWorkerFTM36ExplanationText="SELFDESTRUCT EXPLAIN",
  },
}}

local stack={push=function(self,x) self.last=x; return true end}
local learned={}
local world={game={
  data={
    items={
      COIN_CASE={name="COIN CASE"},
      TM39={name="TM39", teaches="SWIFT"},
      -- Gold's numeric TM36 is deliberately unrelated and must not be awarded.
      TM36={name="TM36", teaches="SLUDGE_BOMB"},
    },
    moves={SELFDESTRUCT={name="SELFDESTRUCT"},SWIFT={name="SWIFT"},SLUDGE_BOMB={name="SLUDGE BOMB"}},
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
  backing,messages,partyScreens,added,removed,learned={},{},{},{},{},{}
  world.game.save={
    inventory={},
    party={{species="VOLTORB",moves={}}, {species="MAGIKARP",moves={}}},
    player={name="GOLD"},
  }
  Twin._resetKantoStateCacheForTest()
end

local function interact(map,text)
  local spec=Rewards.match(map,text)
  check(spec,"reward spec exists: "..map)
  return Twin._talkKantoScriptedReward(world,region,spec)
end

-- Celadon Diner: real Gold COIN CASE, one time.
do
  fresh()
  interact("CELADON_DINER","TEXT_CELADONDINER_GYM_GUIDE")
  eq(world.game.save.inventory.COIN_CASE,1,"Coin Case awarded")
  check(Twin._kantoEvent("EVENT_GOT_COIN_CASE"),"Coin Case event")
  interact("CELADON_DINER","TEXT_CELADONDINER_GYM_GUIDE")
  eq(world.game.save.inventory.COIN_CASE,1,"Coin Case not duplicated")
  eq(messages[#messages],"WIN IT BACK","Coin Case repeat text")
end

-- Route 12 Gate 2F: semantic resolver finds Gold's SWIFT machine.
do
  fresh()
  interact("ROUTE_12_GATE_2F","TEXT_ROUTE12GATE2F_BRUNETTE_GIRL")
  eq(world.game.save.inventory.TM39,1,"Swift TM awarded")
  check(Twin._kantoEvent("EVENT_GOT_TM39"),"Swift event")
end

-- Silph 2F: Yellow TM36 is SELFDESTRUCT, not Gold's unrelated TM36.
do
  fresh()
  interact("SILPH_CO_2F","TEXT_SILPHCO2F_SILPH_WORKER_F")
  eq(world.game.save.inventory.TM36,nil,"wrong Gold TM36 never awarded")
  check(Twin._kantoEvent("EVENT_GOT_TM36"),"Yellow TM36 received event")
  check(Twin._kantoEvent("EVENT_KANTO_SILPH_TM36_CREDIT"),"Selfdestruct credit")
  check(#partyScreens==1,"Selfdestruct party chooser opened")
  partyScreens[#partyScreens].opts.onChoose(2,world.game.save.party[2])
  eq(#learned,0,"Yellow-incompatible Magikarp refused")
  check(Twin._kantoEvent("EVENT_KANTO_SILPH_TM36_CREDIT"),"failed teach keeps credit")
  partyScreens[#partyScreens].opts.onChoose(1,world.game.save.party[1])
  eq(learned[1],"SELFDESTRUCT","teaches exact Yellow move")
  check(not Twin._kantoEvent("EVENT_KANTO_SILPH_TM36_CREDIT"),"credit consumed")
  check(Twin._kantoEvent("EVENT_GOT_TM36"),"received event persists")
end

print("kanto_standalone_reward_parity: OK")
