-- v0.4.04: controller stick-click zoom reaches DIORAMA and player cards animate.
local function check(v,msg) assert(v,msg) end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end

local steps={}
local modules={
 VoxelState={level=9,active=function() return true end,isThirdPerson=function() return false end,isFirstPerson=function() return false end,isFull=function() return true end},
 Voxel3D={available=function() return true end},
 FirstPerson={onTop=function() return true end,stickX=function() return 0 end,stickY=function() return 0 end,dropLook=function() end,reseatLook=function() end},
 ThirdPerson={stepZoom=function() end,scaleZoom=function() end},
 BattleCam={steerable=false,stepZoom=function() end},
 DioramaZoom={STEP=1.14,step=function(n) steps[#steps+1]=n return true end,scaleBy=function() return true end},
 BattleCinematic={manualLook=function() end},
 OverworldBattle={shot=function() return nil end},
}
local oldTouch=package.loaded["src.core.TouchControls"]
package.loaded["src.core.TouchControls"]={hitTest=function() return nil end}
local oldLove=love
love={
 mousemoved=function() end,
 system={getOS=function() return "Linux" end},
 graphics={getWidth=function() return 1280 end,getHeight=function() return 720 end},
}
local V={require=function(name) return assert(modules[name],name) end}
local C=assert(loadfile("lib/CamControl.lua"))(V)
local forwarded=0
local game={
 wheelmoved=function() end,
 gamepadpressed=function() forwarded=forwarded+1 end,
 touchpressed=function() end,touchmoved=function() end,touchreleased=function() end,
 focus=function() end,
}
C.install(game)
game:gamepadpressed(nil,"leftstick")
game:gamepadpressed(nil,"rightstick")
eq(steps[1],1,"left stick click pulls DIORAMA out")
eq(steps[2],-1,"right stick click pushes DIORAMA in")
eq(forwarded,0,"claimed DIORAMA zoom clicks are not double-forwarded")

local scene=assert(io.open("lib/VoxelScenePatch.lua","rb")):read("*a")
check(scene:find("stadiumVisualAnimDist",1,true),"free-roam player phase consumes visual distance")
check(scene:find("type(e.walkPhase) == \"function\"",1,true),"DIORAMA player phase refreshes from Gen-2 walkPhase")
local bridge=assert(io.open("lib/GoldVoxelBridge.lua","rb")):read("*a")
check(bridge:find("Player._stadium2VoxelPosePatched",1,true),"Gen-2 player pose receives animation bridge")
check(bridge:find("def.walker = true",1,true),"player sprite definition is forced onto walker frames")

package.loaded["src.core.TouchControls"]=oldTouch
love=oldLove
print("diorama_controller_player_walk_parity: OK")
