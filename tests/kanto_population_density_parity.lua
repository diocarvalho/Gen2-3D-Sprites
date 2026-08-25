-- v0.4.22 regression: Yellow/Kanto free-roam uses a denser visible wild
-- population than the old two-mon baseline while respecting tiny patches.
package.preload["src.render.Assets"] = function() return {} end
_G.love = { math = { random = function(a) return a end } }
local mod={exports={},options={get=function() return nil end},save={get=function(_,_,d)return d end,set=function()return true end}}
local stubs={
  Quality={kantoRadius=function()return 1 end,actorDistanceCells=function()return math.huge end},
  FirstPerson={driving=function()return false end,releaseBody=function()end},
  ChunkMesher={warmPending=function()return 0 end,refresh=function()return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function()return{load=function()return true end}end},
}
local V={mod=mod,require=function(name)return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local f=assert(Twin._kantoVisibleEncounterCount)
local grass=f(25,"grass",100,10)
local water=f(25,"water",100,5)
assert(grass>=5,"normal Kanto grass should target at least five visible wild Pokemon")
assert(water>=3,"normal Kanto water should target at least three visible wild Pokemon")
assert(f(25,"grass",6,10)<=1,"tiny encounter patch remains capacity bounded")
assert(f(140,"grass",300,10)<=10,"grass hard cap is preserved")
assert(f(140,"water",300,5)<=5,"water hard cap is preserved")
print("kanto_population_density_parity: OK")
