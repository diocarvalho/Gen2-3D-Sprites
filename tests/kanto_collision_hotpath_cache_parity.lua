-- v0.3.61 Kanto movement/collision hot-path regression.
-- Verifies the private Gen-1 map's collision-tile cache, direct passability
-- fast path, and immutable ledge/warp-carpet indexes without ROM payloads.

package.preload["src.render.Assets"] = function() return {} end

local mod = {
  exports = {},
  options = { get = function() return nil end },
  save = {
    get = function(_, _, fallback) return fallback end,
    set = function() return true end,
  },
  ui = {},
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
local Map = assert(Twin._ForeignGen1Map)

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end

local function block(tile)
  local t = {}
  for i=1,16 do t[i]=tile end
  return t
end

-- ---- 1. collision-cell tile cache + exact dynamic-block invalidation ------
do
  local def = {
    id="CACHE_MAP", width=1, height=1, borderBlock=0, blocks={0},
    tileset="OVERWORLD", warps={}, signs={}, objects={}, connections={},
  }
  local tileset = {
    blocks={ block(0x11), block(0x22) },
    walkable={0x11}, doorTiles={}, warpTiles={}, counterTiles={}, waterTiles={},
  }
  local map = Map.new(def, tileset)
  Twin.kantoCellTileCacheMisses = 0
  eq(map:cellTile(0,0), 0x11, "first cell read")
  eq(Twin.kantoCellTileCacheMisses, 1, "first read populates cache")
  eq(map:cellTile(0,0), 0x11, "second cell read")
  eq(Twin.kantoCellTileCacheMisses, 1, "second read reuses cache")

  check(map:setBlock(0,0,1), "dynamic block restamp succeeds")
  eq(map:cellTile(0,0), 0x22, "restamp invalidates cached collision tile")
  eq(Twin.kantoCellTileCacheMisses, 2, "restamped cell repopulates once")

  -- Revert to walkable and prove our own map does not route the hot collision
  -- check through global pcall. Use a saved pcall only to protect the test.
  check(map:setBlock(0,0,0), "restore block")
  local realPcall = pcall
  _G.pcall = function() error("unexpected protected call") end
  local ok, value = realPcall(function() return Twin._passable(map,0,0,false) end)
  _G.pcall = realPcall
  check(ok and value == true, "ForeignGen1Map passability takes direct safe path")

  -- Unknown external map implementations retain the defensive protected path.
  local external = { isPassableCell=function() error("external map failure") end }
  eq(Twin._passable(external,0,0,false), false, "external map errors remain contained")
end

-- ---- 2. immutable ledge + ExtraWarpCheck carpet indexes ------------------
do
  local field = {
    ledges = {
      { tileset="OVERWORLD", facing="down", input="down", standingTile=0x39, ledgeTile=0x37 },
    },
    warpCarpets = {
      function2Maps={"CARPET_MAP"},
      edgeMaps={}, function2Tilesets={},
      tiles={ down={0x55}, up={}, left={}, right={} },
    },
  }
  local idx = Twin._buildKantoFieldIndex(field)
  local region = { loaded={field=field}, fieldIndex=idx }
  Twin._excursionForTest.region = region

  local ledgeMap = {
    def={tileset="OVERWORLD"}, widthCells=4, heightCells=4,
    inBounds=function(self,x,y) return x>=0 and y>=0 and x<4 and y<4 end,
    cellTile=function(self,x,y)
      if x==1 and y==1 then return 0x39 end
      if x==1 and y==2 then return 0x37 end
      return 0x01
    end,
  }
  local before = Twin.yellowLedgeIndexHits or 0
  check(Twin._ledgeRuleAt(region, ledgeMap, 1,1,"down") ~= nil,
    "indexed ledge rule resolves")
  eq(Twin.yellowLedgeIndexHits, before+1, "ledge index hit recorded")

  local carpetMap = {
    id="CARPET_MAP", sourceId="CARPET_MAP", def={tileset="INTERIOR"},
    inBounds=function(self,x,y) return x>=0 and y>=0 and x<3 and y<3 end,
    cellTile=function(self,x,y) if x==1 and y==2 then return 0x55 end return 0x01 end,
  }
  local warpBefore = Twin.yellowWarpCarpetIndexHits or 0
  check(Twin._collisionWarpAllowed(carpetMap,1,1,"down"),
    "indexed warp carpet accepts authored front tile")
  eq(Twin.yellowWarpCarpetIndexHits, warpBefore+1, "warp carpet index hit recorded")
end


-- ---- 3. render-rate timer/input probes become direct after one validation --
do
  local realPcall = pcall
  local oldLove = _G.love
  local ticks = 0
  local timer = { getTime=function() ticks=ticks+1; return ticks/60 end }
  _G.love = { timer=timer }
  check(Twin._now() > 0, "timer first probe succeeds")
  _G.pcall = function() error("unexpected repeated protected call") end
  local okNow, t = realPcall(Twin._now)
  _G.pcall = realPcall
  _G.love = oldLove
  check(okNow and t > 0, "trusted timer path is direct after first probe")

  local input = { isDown=function(self,key) return key == "a" end }
  check(Twin._inputDown(input,"a"), "input first probe succeeds")
  _G.pcall = function() error("unexpected repeated protected call") end
  local okInput, down = realPcall(Twin._inputDown, input, "a")
  _G.pcall = realPcall
  check(okInput and down == true, "trusted input path is direct after first probe")
end

print("kanto_collision_hotpath_cache_parity: OK")
