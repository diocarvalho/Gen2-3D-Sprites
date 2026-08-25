-- v0.4.27: the custom Mod Settings root and compact category pages must never
-- disappear into the native flat/Game Boy list. Graphics failures degrade to
-- portable custom renderers, while phone taps use input.pointer.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end

local savedManager=package.loaded["src.mods.ManagerState"]
local savedFont=package.loaded["src.render.Font"]
local savedTheme=package.loaded["src.ui.Theme"]
local savedLove=love

local custom=true
local mobile=false
local pointerHook=nil
local mod={
  id="STADIUM2_OVERWORLD_MODELS",
  options={get=function(self,key) if key=="customUI" then return custom end end},
  exports={mobileUiScale={
    isMobile=function() return mobile end,
    scale=function(ww,wh,min,max) return math.max(min or .18, math.min(max or 1.15, math.min(ww/800,wh/600))) end,
  }},
  hooks={wrap=function(self,name,fn)
    if name=="input.pointer" then pointerHook=fn end
    return function() end
  end},
}
local schema={
 {key="customUI",type="toggle",default=true},
 {key="performancePreset",type="choice",default="high"},
 {key="voxel3d",type="toggle",default=true},
 {key="weatherMode",type="choice",default="auto"},
 {key="cameraMode",type="choice",default="diorama"},
 {key="battle3dWorld",type="toggle",default=true},
 {key="stadium3dSprites",type="toggle",default=true},
 {key="mountFlightMode",type="choice",default="off"},
 {key="enabled",type="toggle",default=true},
 {key="partyFollower",type="toggle",default=true},
 {key="dev_overlay",type="toggle",default=false},
 {key="future_option",type="toggle",default=false},
}

local Manager={}
function Manager.openOptions(self,m)
  self.screen="options"; self.currentMod=m; self.optionRows=self:buildOptionRows(m,schema)
end
function Manager.schemaFor(self,m) return schema end
function Manager.buildOptionRows(self,m,subset)
  local rows={}
  for _,r in ipairs(subset or {}) do rows[#rows+1]={id=r.key,label=r.key} end
  return rows
end
function Manager.updateOptions(self,input) self.nativeUpdates=(self.nativeUpdates or 0)+1 end
function Manager.draw(self) self.nativeDraws=(self.nativeDraws or 0)+1 end
function Manager.confirmSound(self) self.confirmed=(self.confirmed or 0)+1 end
function Manager.goBack(self) self.wentBack=true end

local Font={draw=function() end,drawBox=function() end}
package.loaded["src.render.Font"]=Font
package.loaded["src.ui.Theme"]={cursor=1}
package.loaded["src.mods.ManagerState"]=Manager

local screenW,screenH=1280,720
local failDraw=false
local font={getWidth=function(self,text) return #tostring(text)*8 end}
love={
 data={newByteData=function(bytes) return {bytes=bytes} end},
 image={newImageData=function(data) return data end},
 graphics={
  setColor=function() end,
  rectangle=function() if failDraw then error("synthetic PC graphics failure") end end,
  line=function() end,circle=function() end,polygon=function() end,
  push=function(arg) if arg~=nil then error("legacy backend rejects push argument") end end,
  pop=function() end,origin=function() end,translate=function() end,scale=function() end,
  setBlendMode=function() end,setLineWidth=function() end,
  getDimensions=function() return screenW,screenH end,
  getCanvas=function() return nil end,
  newFont=function() return font end,setFont=function() end,getFont=function() return font end,
  print=function() end,printf=function() end,
  newImage=function() return {getDimensions=function() return 128,128 end,setFilter=function() end} end,
  draw=function() end,
 }
}
function mod:read(path) return "PNG" end

local M=assert(loadfile("lib/CategorizedModSettings.lua"))({mod=mod})
assert(M.install())
check(pointerHook~=nil,"phone input uses the supported input.pointer hook")

local state=setmetatable({}, {__index=Manager})
Manager.openOptions(state,mod)
check(M.gridRootActive(state),"desktop opens custom grid before failure")
failDraw=true
local ok,err=pcall(Manager.draw,state)
check(ok,"custom desktop draw failure is contained: "..tostring(err))
check(M.gridRootActive(state),"graphics failure keeps the app-grid root active")
check(state._stadium2GridCompatibilityRenderer==true,"graphics failure uses the compatibility icon-grid renderer")
check((state.nativeDraws or 0)==0,"graphics failure never replaces the grid with native ManagerState draw")
eq(#state.optionRows,13,"graphics failure preserves the thirteen app-grid category rows")
Manager.updateOptions(state,{wasPressed=function() return false end})
check((state.nativeUpdates or 0)==0,"grid input remains owned by the app menu after degraded drawing")

-- A fresh open retries the full glass renderer.  In phone landscape the root should use
-- the full surface as a 5x3 grid and an uncaptured pointer tap should activate
-- the exact icon through input.pointer.
failDraw=false
mobile=true
screenW,screenH=844,390
Manager.openOptions(state,mod)
check(M.gridRootActive(state),"fresh phone open retries custom grid")
Manager.draw(state)
local layout=state._stadium2GridTouchLayout
check(layout and layout.mobile,"phone renderer records touch layout")
local geo=M.gridLayoutFor(844,390,.5,13)
eq(geo.columns,5,"phone landscape uses five columns")
eq(geo.rows,3,"phone landscape fits thirteen apps in three rows")
check(geo.panelW>800,"phone menu uses nearly the full landscape width")
local first=assert(layout.hits[1])
local game={stack={top=function() return state end}}
local consumed=pointerHook(function() return false end,game,{
 phase="pressed",x=first.x+first.w/2,y=first.y+first.h/2,
 insideGame=false,
})
check(consumed==true,"direct phone icon tap is consumed")
eq(state._stadium2OptionCategory,"ui","direct phone tap opens the tapped category")
check(M.categoryPageActive(state),"phone category page stays inside the custom UI")
local nativeBefore=state.nativeDraws or 0
Manager.draw(state)
eq(state.nativeDraws or 0,nativeBefore,"phone category page bypasses original ManagerState OptionRows draw")
local catLayout=state._stadium2CategoryTouchLayout
check(catLayout and catLayout.mobile,"phone category draws the modern touch-aware card layout")
check(type(catLayout.hits)=="table" and #catLayout.hits>0,"phone category exposes tappable setting cards")
eq(M.categoryVisibleRows({mobile=true,panelW=844,panelH=390}),8,"phone landscape viewport capacity is eight slim rows")
eq(M.categoryVisibleRows({mobile=true,panelW=390,panelH=844}),11,"phone portrait viewport capacity is eleven slim rows")
eq(M.categoryVisibleRows({mobile=false,panelW=500,panelH=620}),10,"desktop uses ten slim visible setting rows")
state.optionRows={}
for i=1,12 do state.optionRows[i]={id="row"..i,label="row"..i} end
state.cursor,state.scroll=10,0
M.clampCategoryScroll(state)
eq(state.scroll,2,"landscape category scroll uses the eight-row custom viewport, not stock four-row scroll")
local catHit=catLayout.hits[1]
local catConsumed=pointerHook(function() return false end,game,{
 phase="pressed",x=catHit.x+catHit.w/2,y=catHit.y+catHit.h/2,insideGame=false,
})
check(catConsumed==true,"direct phone setting-card tap is consumed by the modern category UI")

check(M.showRoot(state,true),"return to app grid for named category checks")
check(M.showCategory(state,"mounts"),"FLY PKMN opens as a categorized page")
check(M.categoryPageActive(state),"FLY PKMN uses the modern category renderer")
Manager.draw(state)
eq(state.nativeDraws or 0,nativeBefore,"FLY PKMN never drops to the original phone OptionRows UI")
check(M.showRoot(state,true),"return to app grid after FLY PKMN")
check(M.showCategory(state,"wilds"),"WILD PKMN opens as a categorized page")
check(M.categoryPageActive(state),"WILD PKMN uses the modern category renderer")
Manager.draw(state)
eq(state.nativeDraws or 0,nativeBefore,"WILD PKMN never drops to the original phone OptionRows UI")

-- Portrait swaps to a 3x5 grid so touch targets stay wide enough.
screenW,screenH=390,844
local portrait=M.gridLayoutFor(390,844,.5,13)
eq(portrait.columns,3,"phone portrait uses three columns")
eq(portrait.rows,5,"phone portrait uses five rows")

package.loaded["src.mods.ManagerState"]=savedManager
package.loaded["src.render.Font"]=savedFont
package.loaded["src.ui.Theme"]=savedTheme
love=savedLove
print("custom_ui_pc_phone_crash_parity: OK")
