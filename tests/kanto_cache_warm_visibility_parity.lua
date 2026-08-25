-- v0.3.58 visible-Kanto cache-warmer regression.
-- Persistent cooking may use already-prepared current/neighbour maps, but it
-- must not call the expensive ForeignGen1Map/atlas preparation path for random
-- far-away records during a visible gameplay frame.

package.preload["src.render.Assets"] = function() return {} end
_G.love = { math = { random = function(a) return a end } }

local warmed = {}
local stubs = {
  Quality = {
    buildMode = function() return "balanced" end,
    kantoSurveyBatch = function() return 2 end,
    kantoRadius = function() return 1 end,
    actorDistanceCells = function() return math.huge end,
  },
  FirstPerson = { driving = function() return false end, releaseBody = function() end },
  ChunkMesher = {
    diskCacheEnabled = function() return true end,
    warmPending = function() return 0 end,
    warmDisk = function(map)
      warmed[#warmed + 1] = map and map.sourceId or "nil"
      return true, "queued"
    end,
  },
  KantoGen2Style = { PROJECTION_REV = "test" },
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local mod = {
  options = { get = function() return nil end },
  save = { get=function(_,_,fallback) return fallback end, set=function() return true end },
  ui = { TextBox = { new = function() return {} end } },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)

local function eq(a,b,msg)
  if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end
end

local region = {
  records = {
    { sourceId = "FAR_A", map = nil },
    { sourceId = "FAR_B", map = nil },
    { sourceId = "FAR_C", map = nil },
  },
  diskWarmSeen = {},
}
local root = { sourceId = "PALLET_TOWN" }
local neighbors = {
  { map = { sourceId = "ROUTE_1" } },
  { map = { sourceId = "ROUTE_21" } },
}

Twin._scheduleKantoDiskWarm(region, root, neighbors, false)
eq(#warmed, 2, "balanced visible frame respects pending target")
eq(warmed[1], "PALLET_TOWN", "current prepared map warms first")
eq(warmed[2], "ROUTE_1", "prepared neighbor warms second")
eq(region.records[1].map, nil, "unrelated far map remains unprepared")
eq(region.records[2].map, nil, "second far map remains unprepared")

-- Already-seen prepared maps are skipped; the next prepared neighbor can fill
-- the remaining queue slot without touching FAR_A/B/C.
warmed = {}
Twin._scheduleKantoDiskWarm(region, root, neighbors, false)
eq(#warmed, 1, "next prepared unseen neighbor can warm")
eq(warmed[1], "ROUTE_21", "only already-prepared next neighbor is queued")
eq(region.records[3].map, nil, "far record remains lazy after repeated visible frames")

print("kanto_cache_warm_visibility_parity: OK")
