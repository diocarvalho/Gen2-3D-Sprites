-- v0.4.16: native 2D must win even if a companion drawWorld pipeline was
-- already active before render.compose. The override is draw-local and its
-- live level is restored afterwards without writing options.
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
local savedPipelines=package.loaded["src.render.Pipelines"]
local savedLove=love

local levels={voxel=2}
local Pipelines={}
function Pipelines.list()
  return {{id="voxel",def={drawWorld=function() end}}}
end
function Pipelines.level(id) return levels[id] or 0 end
function Pipelines.setLevel(id,level) levels[id]=level; return level end
package.loaded["src.render.Pipelines"]=Pipelines

love={graphics={
  push=function() end,pop=function() end,origin=function() end,
  setColor=function() end,setLineWidth=function() end,
  getDimensions=function() return 1280,720 end,
}}

local hook
local mod={
  id="STADIUM2_OVERWORLD_MODELS",
  options={get=function(self,key)
    if key=="voxel3d" then return false end
    if key=="customUI" then return true end
  end},
  hooks={wrap=function(self,name,fn,prio) hook=fn end},
  log={info=function() end},
}
local staleConsumes=0
local PipelineBridge={consumeRenderedFrame=function()
  staleConsumes=staleConsumes+1
  return true -- simulate a 3D result produced earlier in the same frame
end}
local VoxelBridge={
  world3DEnabled=function() return false end,
  setGame=function() end,updateBattle=function() end,battleShot=function() return nil end,
  renderFrame=function() error("voxel render must not run in 2D") end,
}
local WildsBridge={
  drawFallback=function() return 0 end,
}
local Bridge=assert(loadfile("lib/GoldComposeBridge.lua"))(mod,VoxelBridge,WildsBridge,PipelineBridge)

local drew=0
local world={map={id="NEW_BARK_TOWN"},camera={},draw=function(self)
  -- The external world pipeline must be OFF only while the native map is drawn.
  eq(levels.voxel,0,"companion drawWorld pipeline suspended during native 2D draw")
  drew=drew+1
end}
local stack={states={}}
function stack:top() return nil end
local game={world=world,stack=stack}
world.game=game
local nextCalls=0
local handled=Bridge._compose(function() nextCalls=nextCalls+1; return false end,
  game,{generation=2,worldActive=true,ww=1280,wh=720})
assert(handled==true,"native 2D compose owns the live world frame")
eq(drew,1,"native Gold world drawn exactly once by 2D compose")
eq(nextCalls,0,"stale precomposited 3D scene is not passed through")
eq(staleConsumes,1,"same-frame stale pipeline marker is consumed/discarded")
eq(levels.voxel,2,"companion pipeline live level restored after native draw")
eq(Bridge.status().native2DPipelineSuppressions,1,"draw-local pipeline suppression diagnosed")

package.loaded["src.render.Pipelines"]=savedPipelines
love=savedLove
print("two_d_compose_runtime_parity: OK")
