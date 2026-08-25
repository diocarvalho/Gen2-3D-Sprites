-- v0.3.95 regression: Celadon rooftop drink trades preserve Yellow's
-- three one-time TM rewards without misinterpreting Gen-1 TM numbers in Gold.

package.preload["src.render.Assets"] = function() return {} end

local bagRemoves = {}
package.preload["src.inventory.Bag"] = function()
  return {
    remove = function(save, id, count)
      local have = tonumber(save.inventory and save.inventory[id]) or 0
      if have < (count or 1) then return false end
      local left = have - (count or 1)
      save.inventory[id] = left > 0 and left or nil
      bagRemoves[#bagRemoves + 1] = id
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

local backing, messages, menus = {}, {}, {}
local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and type(opts.choice) == "function" then opts.choice(true)
    elseif onDone then onDone() end
    return { text = text }
  end,
}
local ListMenu = {
  new = function(_, title, items, opts)
    local menu = { title=title, items=items, opts=opts,
      close=function(self) self.closed=true end }
    menus[#menus + 1] = menu
    return menu
  end,
}
local mod = {
  exports={}, options={get=function() return nil end},
  ui={TextBox=TextBox,ListMenu=ListMenu},
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
local function eq(a,b,label) if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local girl={text="TEXT_CELADONMARTROOF_LITTLE_GIRL",x=5,y=5}
local region={mapsById={},npcCache={},pokemonCache={},loaded={
  maps={CELADON_MART_ROOF={objects={girl}}},
  field={},items={},
  pokemon={
    LAPRAS={tmhm={"ICE_BEAM"}},
    GEODUDE={tmhm={"ROCK_SLIDE"}},
    DODRIO={tmhm={"TRI_ATTACK"}},
    MAGIKARP={tmhm={}},
  },
  text={
    _CeladonMartRoofLittleGirlImThirstyText="THIRSTY",
    _CeladonMartRoofLittleGirlImNotThirstyText="NOT THIRSTY",
    _CeladonMartRoofLittleGirlYayFreshWaterText="YAY WATER",
    _CeladonMartRoofLittleGirlYaySodaPopText="YAY SODA",
    _CeladonMartRoofLittleGirlYayLemonadeText="YAY LEMONADE",
    _CeladonMartRoofLittleGirlReceivedTM13Text="GOT {RAM:BUFFER}",
    _CeladonMartRoofLittleGirlReceivedTM48Text="GOT {RAM:BUFFER}",
    _CeladonMartRoofLittleGirlReceivedTM49Text="GOT {RAM:BUFFER}",
    _CeladonMartRoofLittleGirlTM13ExplanationText="ICE BEAM EXPLAIN",
    _CeladonMartRoofLittleGirlTM48ExplanationText="ROCK SLIDE EXPLAIN",
    _CeladonMartRoofLittleGirlTM49ExplanationText="TRI ATTACK EXPLAIN",
  },
}}

local learned={}
local stack={push=function(self,x) self.last=x; return true end}
local world={game={
  data={
    items={
      FRESH_WATER={name="FRESH WATER"},
      SODA_POP={name="SODA POP"},
      LEMONADE={name="LEMONADE"},
      -- Deliberately wrong-number Gen-2 TMs. v0.3.95 must never award these.
      TM13={name="TM13",teaches="SNORE"},
      TM48={name="TM48",teaches="FIRE_PUNCH"},
      TM49={name="TM49",teaches="FURY_CUTTER"},
    },
    moves={
      ICE_BEAM={name="ICE BEAM"}, ROCK_SLIDE={name="ROCK SLIDE"},
      TRI_ATTACK={name="TRI ATTACK"},
    },
    pokemon={},
  },
  stack=stack,
  save=nil,
}}
world.game.learnMoveOn=function(self,mon,moveId,cb)
  learned[#learned+1]={mon=mon,move=moveId}
  mon.moves=mon.moves or {}
  mon.moves[#mon.moves+1]={id=moveId}
  cb(true)
end

local function fresh()
  backing,messages,menus,partyScreens,bagRemoves,learned={},{},{},{},{},{}
  world.game.save={
    inventory={},
    party={{species="LAPRAS",moves={}}, {species="GEODUDE",moves={}},
           {species="DODRIO",moves={}}, {species="MAGIKARP",moves={}}},
    player={name="GOLD"},
  }
  Twin._resetKantoStateCacheForTest()
end

local function talk()
  return Twin._tryKantoSpecialObjectInteraction(world,region,"CELADON_MART_ROOF",girl)
end

local function chooseMenu(index)
  local m=menus[#menus]
  check(m and m.items[index],"menu choice exists")
  m.opts.onChoose(m.items[index],m)
end

local function chooseParty(index)
  local p=partyScreens[#partyScreens]
  check(p and p.opts and p.opts.onChoose,"party picker exists")
  p.opts.onChoose(index,world.game.save.party[index])
end

check(Rewards.isCeladonDrinkGirl("CELADON_MART_ROOF",girl.text),"girl recognized")
check(not Rewards.isCeladonDrinkGirl("CELADON_CITY",girl.text),"girl map scoped")

-- No drinks: normal thirsty state.
do
  fresh(); talk()
  eq(messages[#messages],"THIRSTY","no-drink dialogue")
end

-- Fresh Water is consumed before teaching. The earned Yellow TM13 is a local
-- credit, not Gold's unrelated TM13 SNORE.
do
  fresh(); world.game.save.inventory.FRESH_WATER=1
  talk(); chooseMenu(1)
  eq(world.game.save.inventory.FRESH_WATER,nil,"Fresh Water consumed")
  check(Twin._kantoEvent("EVENT_GOT_TM13"),"Yellow TM13 receive event")
  check(Twin._kantoEvent("EVENT_KANTO_CELADON_TM13_CREDIT"),"TM13 local credit")
  eq(world.game.save.inventory.TM13,nil,"wrong Gold TM13 not awarded")
  check(#partyScreens==1,"teaching chooser opens")
  chooseParty(1)
  eq(learned[1].move,"ICE_BEAM","teaches Yellow Ice Beam")
  check(not Twin._kantoEvent("EVENT_KANTO_CELADON_TM13_CREDIT"),"credit consumed after learn")
  check(Twin._kantoEvent("EVENT_GOT_TM13"),"receive event remains")
end

-- Canceling/deferring leaves the local machine credit. Talking again exposes
-- the pending credit without consuming a second drink.
do
  fresh(); world.game.save.inventory.SODA_POP=2
  talk(); chooseMenu(1)
  eq(world.game.save.inventory.SODA_POP,1,"one Soda Pop consumed")
  check(Twin._kantoEvent("EVENT_KANTO_CELADON_TM48_CREDIT"),"Rock Slide credit pending")
  partyScreens[#partyScreens].opts.onCancel()
  local removes=#bagRemoves
  talk()
  eq(menus[#menus].items[1].value.mode,"credit","pending credit offered first")
  chooseMenu(1)
  eq(#bagRemoves,removes,"retry teaching consumes no second drink")
  chooseParty(2)
  eq(learned[#learned].move,"ROCK_SLIDE","teaches Yellow Rock Slide")
end

-- Compatibility is Yellow's original tmhm table, not Gold's machine table.
do
  fresh(); world.game.save.inventory.LEMONADE=1
  talk(); chooseMenu(1)
  chooseParty(4) -- MAGIKARP cannot learn TRI ATTACK in Yellow
  eq(#learned,0,"incompatible Yellow species refused")
  check(Twin._kantoEvent("EVENT_KANTO_CELADON_TM49_CREDIT"),"failed choice keeps credit")
  chooseParty(3)
  eq(learned[1].move,"TRI_ATTACK","compatible mon learns Tri Attack")
end

-- Each of the three rewards is one-time independently. Once all are received
-- and all credits used, the girl is no longer thirsty.
do
  fresh()
  for _, id in ipairs({"FRESH_WATER","SODA_POP","LEMONADE"}) do
    world.game.save.inventory[id]=1
  end
  -- Always choose first available entry; after each successful teach the next
  -- unclaimed drink becomes first.
  talk(); chooseMenu(1); chooseParty(1)
  talk(); chooseMenu(1); chooseParty(2)
  talk(); chooseMenu(1); chooseParty(3)
  eq(world.game.save.inventory.FRESH_WATER,nil,"water gone")
  eq(world.game.save.inventory.SODA_POP,nil,"soda gone")
  eq(world.game.save.inventory.LEMONADE,nil,"lemonade gone")
  talk()
  eq(messages[#messages],"NOT THIRSTY","all rewards complete")
end

print("kanto_celadon_drink_tm_parity: OK")
