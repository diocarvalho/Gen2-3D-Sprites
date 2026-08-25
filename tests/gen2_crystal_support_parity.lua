-- v0.4.33: Crystal is a first-class Gen-2 host.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
local function read(path)
  local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end

local manifest=read("manifest.json")
check(manifest:find('"games"',1,true) and manifest:find('"gen2"',1,true),"manifest stays generation scoped so current ModTargets includes Crystal")
check(manifest:find('Gold/Silver/Crystal',1,true),"manifest names Crystal as a supported host")

local main=read("main.lua")
check(main:find("GameVersion.engine",1,true),"runtime records the Gen-2 engine lineage")
check(main:find("hostVersion",1,true) and main:find("hostEngine",1,true),"runtime exports host version/engine diagnostics")
check(not main:find("requires Pokemon Gold or Silver.",1,true),"runtime gate is no longer Gold/Silver-only")

-- Exercise the sandbox-safe mobile picker with Crystal active.
local oldLove=love
local oldPlatform=package.loaded["src.core.Platform"]
local oldVersion=package.loaded["src.core.GameVersion"]
local oldImporter=package.loaded["src.import.RomImporter"]
local chosen, readyCrystal
love={system={getOS=function() return "Android" end}}
package.loaded["src.core.Platform"]={detect=function() return {os="Android"} end}
package.loaded["src.core.GameVersion"]={get=function() return "crystal" end}
package.loaded["src.import.RomImporter"]={
  choose=function(fake,version)
    chosen=version
    readyCrystal=fake.ready and fake.ready.crystal
    fake.pickPending=true
  end,
}
local Compat=assert(loadfile("lib/EngineCompat.lua"))({})
local ok,err=Compat.openMobileRomPicker()
check(ok,err or "Crystal mobile picker failed")
eq(chosen,"crystal","mobile picker routes active Crystal edition")
check(readyCrystal==true,"Crystal is marked ready in throwaway picker state")
package.loaded["src.core.Platform"]=oldPlatform
package.loaded["src.core.GameVersion"]=oldVersion
package.loaded["src.import.RomImporter"]=oldImporter
love=oldLove

-- Persistent voxel cache must be edition-separated. Test the exposed namespace
-- without requiring graphics or filesystem services.
local savedGV=package.loaded["src.core.GameVersion"]
local current="crystal"
package.loaded["src.core.GameVersion"]={get=function() return current end}
local V={
  mod={options={get=function() return true end}},
  require=function(name)
    if name=="Voxel3D" then return {} end
    if name=="BuildBudget" then return {tick=function() end,check=function() end} end
    if name=="EngineCompat" then return {fs=function() return nil end} end
    error("unexpected require "..tostring(name))
  end,
}
local Cache=assert(loadfile("lib/VoxelDiskCache.lua"))(V)
eq(Cache.activeGameId(),"crystal","voxel cache sees Crystal host id")
check(Cache.cacheDir():find("/crystal",1,true)~=nil,"Crystal sector cache has its own directory")
current="gold"
check(Cache.cacheDir():find("/gold",1,true)~=nil,"Gold sector cache has a different directory")
current="silver"
check(Cache.cacheDir():find("/silver",1,true)~=nil,"Silver sector cache has a different directory")
package.loaded["src.core.GameVersion"]=savedGV

local battleFx=read("lib/StadiumBattleFXPort.lua")
check(battleFx:find("MYSTICALMAN=true",1,true),"Crystal Eusine class is accepted by boss announcer scope")

print("gen2_crystal_support_parity: OK")
