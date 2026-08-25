-- v0.3.63 Kanto position-persistence hot-path regression.
-- Ordinary cell crossings reuse one snapshot and coalesce mod.save traffic;
-- explicit/menu checkpoints remain exact.

package.preload["src.render.Assets"] = function() return {} end

local writes, lastWrite = 0, nil
local mod = {
  exports = {}, options = { get=function(_,_,default) return default end }, ui = {},
  save = {
    get = function(_, _, fallback) return fallback end,
    set = function(_, key, value)
      if key == "yellowFreeRoamPositionV1" then writes=writes+1; lastWrite=value end
      return true
    end,
  },
}
local stubs = {
  Quality = { kantoRadius=function() return 1 end, actorDistanceCells=function() return math.huge end },
  FirstPerson = { driving=function() return false end, releaseBody=function() end },
  ChunkMesher = { warmPending=function() return 0 end },
  KantoGen2Style = { PROJECTION_REV="test" },
  runtime_sheets = { new=function() return { load=function() return true end } end },
}
local V = { mod=mod, require=function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local e = Twin._excursionForTest

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end

local region = { loaded={maps={},field={},encounters={},text={}}, mapsById={}, validOutdoor={} }
e.active=true; e.region=region; e.world={}; e.sourceMapId="PALLET_TOWN"
e.cellX=5; e.cellY=6; e.facing="down"; e.surfing=false; e.biking=false; e.forcedBike=false
e.lastOutside={id="PALLET_TOWN",x=5,y=6}
e.positionSnapshot=nil; e.positionDirty=nil; e.positionDirtySteps=nil

-- Entry/explicit checkpoint writes once and creates the reusable snapshot.
check(Twin._persistExcursionPosition(true), "forced entry checkpoint succeeds")
eq(writes, 1, "entry crosses save bridge once")
local snapshot = e.positionSnapshot
local outside = snapshot.lastOutside
check(type(snapshot)=="table" and type(outside)=="table", "position snapshot allocated")
eq(lastWrite, snapshot, "save receives reusable snapshot")

-- Seven ordinary cells remain in memory only.
for i=1,7 do
  e.cellX = 5 + i
  check(Twin._persistExcursionPosition(false), "deferred cell checkpoint succeeds")
end
eq(writes, 1, "first seven cell crossings do not cross save bridge")
eq(e.positionSnapshot, snapshot, "cell crossings reuse position table")
eq(e.positionSnapshot.lastOutside, outside, "cell crossings reuse LAST_MAP table")
eq(snapshot.x, 12, "in-memory snapshot tracks latest cell")
check(e.positionDirty == true, "deferred travel marks position dirty")

-- Eighth changed landing emits the batched checkpoint.
e.cellX = 13
check(Twin._persistExcursionPosition(false), "eighth cell checkpoint succeeds")
eq(writes, 2, "eighth cell emits one batched save write")
check(e.positionDirty ~= true, "batch write clears dirty flag")
eq(e.positionDirtySteps, 0, "batch write resets dirty counter")

-- A forced checkpoint with no state change is a no-op.
check(Twin._persistExcursionPosition(true), "unchanged forced checkpoint succeeds")
eq(writes, 2, "unchanged forced checkpoint does not rewrite save")

-- Menu/explicit flush makes a partially filled batch exact immediately.
e.cellY = 7
Twin._persistExcursionPosition(false)
e.cellY = 8
Twin._persistExcursionPosition(false)
eq(writes, 2, "partial batch remains coalesced")
check(Twin._flushExcursionPosition(), "explicit/menu flush succeeds")
eq(writes, 3, "flush writes latest position once")
eq(lastWrite.y, 8, "flush persists latest cell")
check(e.positionDirty ~= true, "flush clears dirty flag")

-- LAST_MAP changes mutate the existing nested snapshot instead of allocating.
e.lastOutside = {id="ROUTE_1",x=10,y=20}
e.cellY = 9
Twin._persistExcursionPosition(false)
eq(e.positionSnapshot.lastOutside, outside, "LAST_MAP update reuses nested table")
eq(outside.id, "ROUTE_1", "reused LAST_MAP snapshot updates id")
check(Twin._flushExcursionPosition(), "LAST_MAP flush succeeds")
eq(writes, 4, "LAST_MAP change gets one durable checkpoint")

print("kanto_position_checkpoint_parity: OK")
