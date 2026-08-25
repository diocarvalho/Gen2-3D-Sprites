-- v0.4.01: Yellow Summer Beach House / Surfing Pikachu parity.

package.preload["src.render.Assets"] = function() return {} end
local musicRestores=0
package.preload["src.core.Music"] = function()
  return {playMap=function() musicRestores=musicRestores+1; return true end}
end
local minigameStarts=0
package.preload["src.ui.SurfingMinigame"] = function()
  return {new=function(game,onDone)
    minigameStarts=minigameStarts+1
    if game.save.surfingHighScore~=1234 then
      error("Kanto-local high score was not bridged into minigame")
    end
    game.save.surfingHighScore=4321
    return {__surfing=true,onDone=onDone}
  end}
end
_G.love={math={random=function(a) return a end},graphics={}}

local backing={yellowSurfingHighScoreV1=1234}
local TextBox={new=function(_,text,onDone,opts)
  return {__textbox=true,text=text,onDone=onDone,opts=opts}
end}
local mod={
  exports={},options={get=function() return nil end},ui={TextBox=TextBox},
  save={get=function(_,k,f) local v=backing[k]; return v==nil and f or v end,
        set=function(_,k,v) backing[k]=v; return true end},
}
local stubs={
  Quality={kantoRadius=function() return 1 end,actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end,releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end,refresh=function() return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end,isReady=function() return false end} end},
}
local V
V={mod=mod,require=function(name) return stubs[name] or {} end}
stubs.KantoSummerBeach=assert(loadfile("lib/KantoSummerBeach.lua"))(V)
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function check(v,l) if not v then error(l or "check failed",2) end end
local function eq(a,b,l) if a~=b then error((l or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local stack={items={}}
function stack:push(state)
  self.items[#self.items+1]=state
  if state.__textbox and state.opts and state.opts.choice then
    state.opts.choice(true)
  elseif state.__textbox and state.onDone then
    state.onDone()
  elseif state.__surfing and state.onDone then
    state.onDone()
  end
  return state
end
function stack:top() return self.items[#self.items] end
function stack:pop() return table.remove(self.items) end

local save={
  player={name="GOLD"},
  surfingHighScore=77,
  party={{species="PIKACHU",moves={{id="THUNDERBOLT"},{id="SURF"}}}},
}
local world={game={save=save,data={},stack=stack},map={id="NEW_BARK_TOWN"}}
local region={loaded={text={}}}

-- Eligibility uses Gold's real party/moves, not Yellow's detached save.
check(Twin._surfingPikachuForTest(world.game)==save.party[1],"Surf Pikachu detected")
save.party[1].moves={{id="THUNDERBOLT"}}
eq(Twin._surfingPikachuForTest(world.game),nil,"Pikachu without Surf rejected")
save.party[1].moves={{id="SURF"}}

-- Talking to the Surfin' Dude launches the engine-owned minigame. The
-- Yellow-only high score is bridged temporarily and Gold's prior field is
-- restored byte-for-byte after the run completes.
check(Twin._tryKantoSpecialObjectInteraction(world,region,"SUMMER_BEACH_HOUSE",
  {text="TEXT_SUMMERBEACHHOUSE_SURFINDUDE"}),"Surfin Dude handled")
eq(minigameStarts,1,"minigame start count")
eq(backing.yellowSurfingHighScoreV1,4321,"Kanto local high score persisted")
eq(save.surfingHighScore,77,"Gold high score field restored")
check(Twin._excursionForTest.surfedThisVisit==true,"visit surf latch set")
eq(Twin.yellowSurfingPikachuRuns,1,"run diagnostic")
eq(Twin.yellowSurfingPikachuFinishes,1,"finish diagnostic")
eq(musicRestores,1,"host map music restored")

-- The asked/surfed bits are map-load-local. Leaving the Beach House clears
-- both without erasing the persistent high score.
Twin._excursionForTest.surfinDudeAsked=true
Twin._excursionForTest.surfedThisVisit=true
check(Twin._resetSummerBeachVisitForTest(Twin._excursionForTest,"ROUTE_19"),"leaving shack resets visit")
eq(Twin._excursionForTest.surfinDudeAsked,false,"asked latch reset")
eq(Twin._excursionForTest.surfedThisVisit,false,"surf latch reset")
eq(backing.yellowSurfingHighScoreV1,4321,"high score survives visit reset")

-- Source guard: dedicated interaction must run before the dialogue sandbox,
-- otherwise full-screen SurfingMinigame states are intentionally suppressed.
do
  local f=assert(io.open("lib/KantoSummerBeach.lua","rb")); local src=f:read("*a"); f:close()
  check(src:find("function M.interact",1,true)~=nil,"Beach House direct handler installed")
  check(src:find('require, "src.ui.SurfingMinigame"',1,true)~=nil,"native minigame required")
  check(src:find("yellowSurfingHighScoreV1",1,true)~=nil,"local high-score bridge installed")
end

print("kanto_surfing_pikachu_parity: OK")
