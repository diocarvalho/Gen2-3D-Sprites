-- v0.4.04: CUSTOM UI OFF -> ON rebuilds categories in the same ManagerState.
local function check(v,msg) assert(v,msg) end
local oldManager=package.loaded["src.mods.ManagerState"]
local custom=true
local mod={id="STADIUM2_OVERWORLD_MODELS",options={get=function(self,key)
  if key=="customUI" then return custom end
end}}
local schema={
 {key="customUI",type="toggle",default=true},
 {key="voxel3d",type="toggle",default=true},
 {key="cameraMode",type="choice",default="diorama"},
 {key="battle3dWorld",type="toggle",default=true},
 {key="enabled",type="toggle",default=true},
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
package.loaded["src.mods.ManagerState"]=Manager
local M=assert(loadfile("lib/CategorizedModSettings.lua"))({mod=mod})
assert(M.install())
local state=setmetatable({}, {__index=Manager})
Manager.openOptions(state,mod)
check(state._stadium2CategorizedOptions==true,"custom UI opens category root")
local rootCount=#state.optionRows
check(rootCount < #schema+4,"category root is not the flat schema")
custom=false
Manager.updateOptions(state,{wasPressed=function() return false end})
check(not state._stadium2CategorizedOptions,"OFF switches live to native flat state")
check(#state.optionRows==#schema,"OFF rebuilds full native option list")
custom=true
Manager.updateOptions(state,{wasPressed=function() return false end})
check(state._stadium2CategorizedOptions==true,"ON rebuilds category root without reopening pause")
check(#state.optionRows==rootCount,"ON restores categorized row count immediately")
package.loaded["src.mods.ManagerState"]=oldManager
print("custom_ui_live_toggle_parity: OK")
