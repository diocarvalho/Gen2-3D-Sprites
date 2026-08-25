-- v0.3.59 ChunkMesher live-set ownership regression.
-- setLive must snapshot caller membership because Kanto reuses/wipes its live
-- dictionary on the next frame. The previous generation still has to remain
-- warm for a cheap door/route round trip.

package.path = "./?.lua;./?/init.lua;" .. package.path
package.preload["src.render.Assets"] = function() return { register=function() end } end

local generic = setmetatable({}, { __index = function() return function() end end })
local V = {
  require = function(name)
    if name == "Voxel3D" then return { FACE_SHADE={ [1]=1,[2]=1,[5]=1,[6]=1 }, FORMAT={} } end
    if name == "Quality" then return { buildMode=function() return "balanced" end } end
    if name == "EngineCompat" then return { osName=function() return "Linux" end } end
    if name == "VoxelDiskCache" then
      return { enabled=function() return false end, load=function() return false end,
        probe=function() return false end, store=function() end, clear=function() end,
        status=function() return {} end }
    end
    return generic
  end,
}

local M = assert(loadfile("lib/ChunkMesher.lua"))(V)
local function eq(a,b,msg) if a ~= b then error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2) end end

local A, B = {id="A"}, {id="B"}
M.request(A, true, nil, false)
eq(M.pending(), 1, "A job queued")
local live = { A=true }
M.setLive(live, false)

-- Simulate VoxelScene wiping/reusing the same caller scratch table next frame.
live.A = nil
M.request(B, true, nil, false)
eq(M.pending(), 2, "B job joins A")
M.setLive({ B=true }, false)
-- A is not in the new live set, but it IS the previous generation and must stay.
eq(M.pending(), 2, "previous live generation survives caller-table reuse")

-- One more generation retires A as expected.
M.setLive({ B=true }, false)
eq(M.pending(), 1, "two-generation residency still evicts genuinely old A")

print("kanto_live_residency_snapshot_parity: OK")
