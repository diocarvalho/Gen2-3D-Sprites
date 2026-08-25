-- v0.4.17 performance regression: AUTO renderer governor + cheaper background work.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(v,msg) if not v then error(msg or "check failed",2) end end
local function near(a,b,e,msg) if math.abs(a-b) > (e or 1e-9) then error((msg or "not near")..": "..tostring(a).." ~= "..tostring(b),2) end end
local function read(path) local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s end

local values = {
  performancePreset="auto", graphicsResolution="55", graphicsShadows="blob",
  graphicsReflections="sky", graphicsDrawDistance="balanced",
  graphicsKantoRadius="1", graphicsBuildRate="smooth",
}
local mod = { id="STADIUM2_OVERWORLD_MODELS", options={ get=function(_,k) return values[k] end } }
local V = {
  mod=mod,
  require=function(name)
    if name=="ModSetting" then
      return { new=function() return { get=function() return "low" end } end }
    end
    if name=="config" then return {} end
    error("unexpected require "..tostring(name))
  end,
}
local Quality = assert(loadfile("lib/Quality.lua"))(V)
check(Quality.requestedPreset()=="auto", "AUTO is the requested default policy")
check(Quality.preset()=="medium", "AUTO starts at medium instead of expensive high")
near(Quality.renderFactor(),0.55,1e-9,"AUTO medium render factor")
local u,i,c = Quality.buildSlices()
check(u <= 0.0031 and i <= 0.0011 and c <= 0.0081, "medium AUTO uses smooth cooperative mesh slices")
check(Quality.kantoRadius()==1, "medium AUTO limits Kanto prefetch to one ring")
check(Quality.actorDistanceCells()==16, "balanced actor prefilter is tighter")

-- Plenty of headroom for >8 seconds promotes to HIGH, but HIGH retains the
-- cheap sky reflection path instead of turning SSR on behind the user's back.
for _=1,1800 do Quality.noteFrameCost(0.005,60) end
check(Quality.autoTier()=="high", "AUTO can climb to high after long stable headroom")
check(Quality.reflections()=="sky", "AUTO high keeps fast water reflections")
-- Sustained expensive draws demote quickly.
for _=1,100 do Quality.noteFrameCost(0.020,60) end
check(Quality.autoTier()~="high", "AUTO demotes quickly when voxel draw cost is late")

local options = read("options.lua")
check(options:find('{ "AUTO / RECOMMENDED", "auto" }',1,true), "AUTO preset is exposed in settings")
local wilds = read("lib/behavior_tick.lua")
check(wilds:find('if tier == "medium" then return 1 / 30 end',1,true), "visible Wilds AI is 30 Hz on medium")
local flyers = read("lib/AmbientFlyers.lua")
check(flyers:find('if not voxelEnabled() then',1,true), "ambient voxel-only flyers stop updating in native 2D")
check(flyers:find('if tier == "medium" then return 1 / 30 end',1,true), "ambient flyers are 30 Hz on medium")
local wx = read("weatherfx/lib/Quality.lua")
check(wx:find('return "medium"',1,true), "Weather AUTO starts medium to avoid first-run particle spike")

print("performance_optimization_parity: OK")
