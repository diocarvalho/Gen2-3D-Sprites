-- v0.4.20: single-page 4x4 NEW-UI grid + enlarged borderless PNG icon parity.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end

local savedManager=package.loaded["src.mods.ManagerState"]
local savedFont=package.loaded["src.render.Font"]
local savedTheme=package.loaded["src.ui.Theme"]
local savedLove=love

local custom=true
local mod={id="STADIUM2_OVERWORLD_MODELS",options={get=function(self,key)
  if key=="customUI" then return custom end
end}}
local packagedIcons={
  ["assets/menu/mod_settings_icons/ui.png"]="PNG_UI",
  ["assets/menu/mod_settings_icons/performance.png"]="PNG_PERF",
  ["assets/menu/mod_settings_icons/world.png"]="PNG_WORLD",
  ["assets/menu/mod_settings_icons/weather.png"]="PNG_WEATHER",
  ["assets/menu/mod_settings_icons/camera.png"]="PNG_CAMERA",
  ["assets/menu/mod_settings_icons/battle.png"]="PNG_BATTLE",
  ["assets/menu/mod_settings_icons/models.png"]="PNG_MODELS",
  ["assets/menu/mod_settings_icons/mounts.png"]="PNG_MOUNTS",
  ["assets/menu/mod_settings_icons/wilds.png"]="PNG_WILDS",
  ["assets/menu/mod_settings_icons/followers.png"]="PNG_FOLLOWERS",
  ["assets/menu/mod_settings_icons/developer.png"]="PNG_DEVELOPER",
  ["assets/menu/mod_settings_icons/other.png"]="PNG_OTHER",
}
function mod:read(path) return packagedIcons[path] end
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

local drawCalls={box=0,text={},rect=0,line=0,circle=0,poly=0,newFont=0,newImage=0,imageDraw=0,prints={},printfs={}}
local Font={}
function Font.draw(text,x,y) drawCalls.text[#drawCalls.text+1]=tostring(text) end
function Font.drawBox(x,y,w,h) drawCalls.box=drawCalls.box+1 end
package.loaded["src.render.Font"]=Font
package.loaded["src.ui.Theme"]={cursor=1}
local currentFont
local function fakeFont(size)
  return {size=size,getWidth=function(self,text) return #tostring(text)*(self.size or 10)*0.55 end}
end
local function fakeImage()
  return {getDimensions=function() return 256,256 end,setFilter=function() end}
end
love={
 data={newByteData=function(bytes) return {bytes=bytes} end},
 image={newImageData=function(byteData) return {source=byteData} end},
 graphics={
 setColor=function() end,
 rectangle=function() drawCalls.rect=drawCalls.rect+1 end,
 line=function() drawCalls.line=drawCalls.line+1 end,
 circle=function() drawCalls.circle=drawCalls.circle+1 end,
 polygon=function() drawCalls.poly=drawCalls.poly+1 end,
 push=function() end,pop=function() end,origin=function() end,translate=function() end,scale=function() end,
 setBlendMode=function() end,setLineWidth=function() end,
 getDimensions=function() return 1280,720 end,
 getCanvas=function() return nil end,
 newFont=function(size) drawCalls.newFont=drawCalls.newFont+1; return fakeFont(size) end,
 setFont=function(f) currentFont=f end,
 getFont=function() currentFont=currentFont or fakeFont(14); return currentFont end,
 print=function(text,x,y) drawCalls.prints[#drawCalls.prints+1]=tostring(text) end,
 printf=function(text,x,y,w,align) drawCalls.printfs[#drawCalls.printfs+1]=tostring(text) end,
 newImage=function(source) drawCalls.newImage=drawCalls.newImage+1; return fakeImage() end,
 draw=function(image,x,y,r,sx,sy) drawCalls.imageDraw=drawCalls.imageDraw+1 end,
}}
package.loaded["src.mods.ManagerState"]=Manager

local M=assert(loadfile("lib/CategorizedModSettings.lua"))({mod=mod})
assert(M.install())
local state=setmetatable({}, {__index=Manager})
Manager.openOptions(state,mod)
check(M.gridRootActive(state),"custom settings opens the icon-grid root")
eq(#state.optionRows,13,"eleven known categories + OTHER + reset")
eq(state.optionRows[1]._stadium2Grid.icon,"ui","UI tile has UI icon")
eq(state.optionRows[4]._stadium2Grid.icon,"weather","weather tile has weather icon")
eq(state.optionRows[12]._stadium2Grid.icon,"other","future settings land in OTHER tile")
eq(state.optionRows[13]._stadium2Grid.icon,"reset","reset tile has reset icon")

local input={pressed={}}
function input:wasPressed(k) return self.pressed[k] == true end
input.pressed={right=true}; Manager.updateOptions(state,input); eq(state.cursor,2,"RIGHT moves one compact-grid column")
input.pressed={left=true}; Manager.updateOptions(state,input); eq(state.cursor,1,"LEFT returns one compact-grid column")
input.pressed={down=true}; Manager.updateOptions(state,input); eq(state.cursor,5,"DOWN moves one compact-grid row")
input.pressed={a=true}; Manager.updateOptions(state,input)
eq(state._stadium2OptionCategory,"camera","A opens focused category")
check(state.confirmed==1,"category open keeps ManagerState confirm sound")
input.pressed={b=true}; Manager.updateOptions(state,input)
check(M.gridRootActive(state),"B from category returns to grid")
eq(state.cursor,5,"return restores exact grid tile")


-- All thirteen root tiles now share one page.  The twelve bundled custom
-- icons must be read from the packaged mod namespace and drawn as raster images,
-- while the reset category continues to use the vector fallback renderer.
state.cursor=1
Manager.draw(state)
eq(drawCalls.newImage,12,"twelve packaged custom icons decode from mod:read")
eq(drawCalls.imageDraw,12,"twelve supplied custom icons draw on the single page")

state.cursor=7
Manager.draw(state)
check((state.nativeDraws or 0)==0,"grid root bypasses native long-list renderer")
eq(drawCalls.box,0,"NEW UI grid no longer uses retro Font.drawBox tiles")
check(drawCalls.newFont>0,"NEW UI grid uses modern scalable fonts")
check(drawCalls.rect>=2,"glass panel and focused-card geometry are still drawn without per-icon wells")
check(drawCalls.line + drawCalls.circle + drawCalls.poly > 0,"category icons are drawn with real vector geometry")
local sawTitle=false
for _,t in ipairs(drawCalls.prints) do if t=="MOD SETTINGS" then sawTitle=true end end
check(sawTitle,"modern glass grid draws MOD SETTINGS header")
local sawCategoryCount=false
for _,t in ipairs(drawCalls.printfs) do if t=="13 APPS" then sawCategoryCount=true end end
check(sawCategoryCount,"single-page homescreen grid shows app count instead of page indicator")
for _,t in ipairs(drawCalls.printfs) do
  check(not t:match("^%d+%s*/%s*%d+$"),"single-page grid has no page indicator")
end

state.cursor=1
input.pressed={up=true}; Manager.updateOptions(state,input)
eq(state.cursor,13,"UP from first tile wraps to same-column tail/reset tile")
input.pressed={b=true}; Manager.updateOptions(state,input)
check(state.wentBack==true,"B from grid returns to mod detail")

package.loaded["src.mods.ManagerState"]=savedManager
package.loaded["src.render.Font"]=savedFont
package.loaded["src.ui.Theme"]=savedTheme
love=savedLove
print("custom_ui_icon_grid_parity: OK")
