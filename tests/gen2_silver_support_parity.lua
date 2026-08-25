-- v0.4.04: Silver is a first-class Gen-2 host, not a Gold alias.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end

local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end

local manifest=read("manifest.json")
check(manifest:find('"games"',1,true) and manifest:find('"gen2"',1,true),"manifest remains generation scoped")
check(manifest:find('"gen2compat": true',1,true),"manifest advertises Gen-2 compatibility")
local main=read("main.lua")
check(main:find("GameVersion.generation",1,true),"runtime guard uses generation, not Gold edition")
check(not main:find("GameVersion.isGold()",1,true),"main has no Gold-only runtime gate")

-- Exercise the mobile picker bridge with Silver as the active edition.
local oldLove=love
local oldPlatform=package.loaded["src.core.Platform"]
local oldVersion=package.loaded["src.core.GameVersion"]
local oldImporter=package.loaded["src.import.RomImporter"]
local chosen, readySilver
love={system={getOS=function() return "iOS" end}}
package.loaded["src.core.Platform"]={detect=function() return {os="iOS"} end}
package.loaded["src.core.GameVersion"]={get=function() return "silver" end}
package.loaded["src.import.RomImporter"]={
  choose=function(fake,version)
    chosen=version
    readySilver=fake.ready and fake.ready.silver
    fake.pickPending=true
  end,
}
local Compat=assert(loadfile("lib/EngineCompat.lua"))({})
local ok,err=Compat.openMobileRomPicker()
check(ok,err or "Silver mobile picker failed")
eq(chosen,"silver","mobile picker routes active Silver edition")
check(readySilver==true,"Silver is marked ready in throwaway picker state")

package.loaded["src.core.Platform"]=oldPlatform
package.loaded["src.core.GameVersion"]=oldVersion
package.loaded["src.import.RomImporter"]=oldImporter
love=oldLove
print("gen2_silver_support_parity: OK")
