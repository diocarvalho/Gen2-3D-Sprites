-- Continuous camera-distance zoom for the voxel diorama camera.
local V = ...
local DioramaZoom = {}

DioramaZoom.MIN = 0.24
DioramaZoom.MAX = 2.20
DioramaZoom.STEP = 1.14
DioramaZoom.value = 1.0

local function clamp(v)
  return math.max(DioramaZoom.MIN, math.min(DioramaZoom.MAX, tonumber(v) or 1))
end

function DioramaZoom.get()
  return clamp(DioramaZoom.value)
end

function DioramaZoom.set(v)
  DioramaZoom.value = clamp(v)
  return DioramaZoom.value
end

-- Positive notches pull the camera out; negative notches push in.
function DioramaZoom.step(notches)
  notches = tonumber(notches) or 0
  if notches == 0 then return false end
  DioramaZoom.set(DioramaZoom.get() * (DioramaZoom.STEP ^ notches))
  return true
end

-- Multiplicative distance change. Values below 1 zoom in.
function DioramaZoom.scaleBy(factor)
  factor = tonumber(factor)
  if not factor or factor <= 0 then return false end
  DioramaZoom.set(DioramaZoom.get() * factor)
  return true
end

function DioramaZoom.reset()
  DioramaZoom.value = 1.0
end

return DioramaZoom
