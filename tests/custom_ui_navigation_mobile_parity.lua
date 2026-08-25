-- v0.4.04: phone scale floor + vertical custom Pokedex entry navigation.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
local oldPlatform=package.loaded["src.core.Platform"]

-- Mobile menu geometry must no longer shrink 844x390 to the desktop 0.65x.
package.loaded["src.core.Platform"]={detect=function() return {os="iOS"} end}
local Scale=assert(loadfile("lib/MobileUIScale.lua"))({mod={}})
local phone=Scale.scale(844,390,0.18,1.15)
check(phone > 0.85 and phone <= 1.15,"phone UI gets a readable scale floor")
package.loaded["src.core.Platform"]={detect=function() return {os="Linux"} end}
local ScaleDesktop=assert(loadfile("lib/MobileUIScale.lua"))({mod={}})
local desktop=ScaleDesktop.scale(844,390,0.18,1.15)
check(desktop < phone,"desktop small-window behavior remains more compact")

-- Stub the Gen-2 menu classes just enough to install the presentation patch.
local paths={
 "src.ui.gen2.PartyMenu","src.ui.gen2.SummaryMenu","src.ui.gen2.PackMenu",
 "src.ui.gen2.OptionsMenu","src.ui.gen2.SaveMenu","src.ui.gen2.TrainerCard",
 "src.ui.gen2.Pokegear","src.ui.gen2.PokedexMenu",
}
local saved={}
for _,path in ipairs(paths) do
  saved[path]=package.loaded[path]
  local C={}
  C.__index=C
  function C.new(game,opts) return setmetatable({game=game,view="list"},C) end
  function C.draw() end
  package.loaded[path]=C
end
local oldStart=package.loaded["src.ui.gen2.StartMenu"]
local Start={}; Start.__index=Start
package.loaded["src.ui.gen2.StartMenu"]=Start
local P=package.loaded["src.ui.gen2.PokedexMenu"]
function P.order() return {} end
function P.update(self) self.nativeUpdates=(self.nativeUpdates or 0)+1 end

local custom=true
local mod={exports={mobileUiScale=Scale},options={get=function(self,key)
  if key=="customUI" then return custom end
  return nil
end}}
local M=assert(loadfile("lib/GoldSubmenuBattleStyle.lua"))({mod=mod,require=function() return nil end})
assert(M.install())
local start=setmetatable({},Start)
local input={pressed={}}
function input:wasPressed(k) return self.pressed[k] == true end
local game={input=input,stack={top=function() return start end}}
local dex=P.new(game,{})
dex.view="entry"; dex.entryAction=1; dex.newEntry=false
input.pressed={down=true}; dex:update(); eq(dex.entryAction,2,"DOWN advances vertical action list")
input.pressed={up=true}; dex:update(); eq(dex.entryAction,1,"UP reverses vertical action list")
custom=false
input.pressed={down=true}; dex:update(); eq(dex.entryAction,1,"native UI does not receive custom vertical remap")
check((dex.nativeUpdates or 0)==3,"native Pokedex update still runs every frame")

for _,path in ipairs(paths) do package.loaded[path]=saved[path] end
package.loaded["src.ui.gen2.StartMenu"]=oldStart
package.loaded["src.core.Platform"]=oldPlatform
print("custom_ui_navigation_mobile_parity: OK")
