-- v0.3.94 regression: Cerulean robbery aftermath physical actor state.
package.preload["src.render.Assets"] = function() return {} end
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, item, count)
      save.inventory = save.inventory or {}
      save.inventory[item] = (save.inventory[item] or 0) + (count or 1)
      return true
    end,
  }
end
package.preload["src.core.Sound"] = function() return { play=function() return true end } end
_G.love = { math = { random = function(a) return a end } }

local backing, messages = {}, {}
local TextBox = { new=function(_, text, onDone)
  messages[#messages+1] = tostring(text)
  if onDone then onDone() end
  return {}
end }
local mod = {
  exports={}, options={get=function() return nil end}, ui={TextBox=TextBox},
  save={
    get=function(_,k,f) local v=backing[k]; if v==nil then return f end return v end,
    set=function(_,k,v) backing[k]=v; return true end,
  },
}
local stubs = {
  Quality={kantoRadius=function() return 1 end, actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end,refresh=function() return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end} end},
}
local V={mod=mod,require=function(n) return stubs[n] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function check(v,m) if not v then error(m or "check failed",2) end end
local function hidden(map,obj) return Twin._kantoObjectHidden(map,obj) end
local rocket={index=2,name="CERULEANCITY_ROCKET",text="TEXT_CERULEANCITY_ROCKET"}
local g1={index=6,name="CERULEANCITY_GUARD1",text="TEXT_CERULEANCITY_GUARD1"}
local g2={index=11,name="CERULEANCITY_GUARD2",text="TEXT_CERULEANCITY_GUARD2"}
local region={loaded={maps={CERULEAN_CITY={objects={rocket,g1,g2}}}},npcCache={},pokemonCache={}}

Twin._migrateKantoCeruleanRobberyObjects(region,"CERULEAN_CITY")
check(not hidden("CERULEAN_CITY",rocket),"pre-return Rocket visible")
check(hidden("CERULEAN_CITY",g1),"pre-return guard1 hidden")
check(not hidden("CERULEAN_CITY",g2),"pre-return guard2 visible")

Twin._setKantoEvent("EVENT_KANTO_RETURNED_STOLEN_TM28",true)
Twin._migrateKantoCeruleanRobberyObjects(region,"CERULEAN_CITY")
check(hidden("CERULEAN_CITY",rocket),"post-return Rocket hidden")
check(not hidden("CERULEAN_CITY",g1),"post-return guard1 visible")
check(hidden("CERULEAN_CITY",g2),"post-return guard2 hidden")
print("kanto_cerulean_robbery_aftermath_parity: ok")
