-- v0.3.58 Kanto mesh-pacing regression.
-- Loads ChunkMesher with dependency stubs; no renderer/GPU/ROM required.
-- The current Kanto body still uses normal urgent build slices. These values
-- are ONLY the prefetch-neighbour slices selected after GoldVoxelBridge has
-- confirmed the current stitched body is already drawable.

package.path = "./?.lua;./?/init.lua;" .. package.path
package.preload["src.render.Assets"] = function()
  return { register = function() end }
end

local mode = "balanced"
local Quality = { buildMode = function() return mode end }
local generic = setmetatable({}, { __index = function() return function() end end })
local V = {
  require = function(name)
    if name == "Quality" then return Quality end
    if name == "Voxel3D" then return { FACE_SHADE = { [1]=1,[2]=1,[5]=1,[6]=1 }, FORMAT = {} } end
    if name == "EngineCompat" then return { osName = function() return "Linux" end } end
    return generic
  end,
}

local M = assert(loadfile("lib/ChunkMesher.lua"))(V)
local function eq(a,b,msg)
  if math.abs((a or 0)-(b or 0)) > 1e-9 then
    error((msg or "not equal")..": "..tostring(a).." ~= "..tostring(b),2)
  end
end
local function check(v,msg) if not v then error(msg or "check failed",2) end end

mode = "smooth"
eq(M._kantoVisibleSlice(true), 0.0018, "smooth urgent neighbour slice")
eq(M._kantoVisibleSlice(false), 0.0008, "smooth idle neighbour slice")
mode = "balanced"
eq(M._kantoVisibleSlice(true), 0.0028, "balanced urgent neighbour slice")
eq(M._kantoVisibleSlice(false), 0.0013, "balanced idle neighbour slice")
mode = "fast"
eq(M._kantoVisibleSlice(true), 0.0040, "fast urgent neighbour slice")
eq(M._kantoVisibleSlice(false), 0.0020, "fast idle neighbour slice")

-- Persistent cache-only cooking is even smaller on a visible gameplay frame.
mode = "smooth"
check(M._cacheWarmSlice(false, true) <= 0.0005, "smooth cache cooker stays sub-ms")
mode = "balanced"
check(M._cacheWarmSlice(false, true) <= 0.0010, "balanced cache cooker stays <=1ms")
mode = "fast"
check(M._cacheWarmSlice(false, true) <= 0.0015, "fast cache cooker stays <=1.5ms")

print("kanto_mesh_pacing_parity: OK")
