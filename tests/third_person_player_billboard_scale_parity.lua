-- v0.4.06: the 2D trainer card must not balloon when the 3RD-person boom
-- is close, zoomed in, or collision-compressed.  Its presentation scale
-- compensates for the live boom distance while NPC cards remain untouched.
local function check(v,msg) assert(v,msg) end
local function near(a,b,msg)
  assert(math.abs(a-b) < 1e-6,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b))
end

local voxel={level=7,isThirdPerson=function() return true end}
local V={require=function(name)
  if name=="VoxelState" then return voxel end
  error(name)
end}
local TP=assert(loadfile("lib/ThirdPerson.lua"))(V)

TP.out=0
TP.len=48
near(TP.playerCardScale(16),1,"orbit/first-person handoff keeps authored size")

TP.out=1
TP.len=48
near(TP.playerCardScale(16),0.75,"default 48px boom caps native trainer size")
TP.len=24
near(TP.playerCardScale(16),0.375,"close boom shrinks proportionally")
TP.len=96
near(TP.playerCardScale(16),1,"far boom never enlarges above authored size")
TP.len=48
near(TP.playerCardScale(32),0.375,"high-resolution player frame is normalised by frame height")

local scene=assert(io.open("lib/VoxelScene.lua","rb")):read("*a")
check(scene:find("local function playerCardScale(p)",1,true),"VoxelScene has player-only scale helper")
check(scene:find("billboardMatrix(px, py, y, mirror, visualScale)",1,true),"solid player card accepts scale")
check(scene:find("casterMatrixScaled",1,true),"sun shadow uses the same scaled card transform")
check(scene:find("shadowMatrixScaled",1,true),"fallback shadow uses the same scaled card transform")
check(scene:find("p.lift, playerCardScale(p)",1,true),"main cast passes the player scale")

local patch=assert(io.open("lib/VoxelScenePatch.lua","rb")):read("*a")
check(patch:find("supportsPlayerCardScale",1,true),"structural Stadium patch preserves the scale-aware host call")
check(patch:find("playerCardScale(p)",1,true),"patched drawCast forwards player scale")

print("third_person_player_billboard_scale_parity: OK")
