-- Weather compatibility facade.
-- v0.3.18 replaces the old four-mode hand-drawn rain/fog/cloud code with the
-- embedded Weather FX 4.10 presentation/state/audio stack.
local V = ...
local Core = V.require("WeatherFXCore")

local Weather = {}

function Weather.install()
  return Core.install()
end

function Weather.setContext(outdoor, map)
  return Core.setContext(outdoor, map)
end

function Weather.mode()
  return Core.mode()
end

function Weather.hasRain()
  return Core.hasRain()
end

function Weather.hasFog()
  return Core.hasFog()
end

-- Weather FX's voxel-atmos bridge wraps the host Sky.paint and Voxel3D.endScene
-- in memory, so there is no separate legacy pixel-cloud pass here anymore.
function Weather.paintSky(w, h, horizonY, cell, skyRay)
  return Core.paintSky(w, h, horizonY, cell, skyRay)
end

-- Voxel3D calls this while its scene canvas is still active. Weather FX draws
-- its screen-space layers here; rain/fog automatically suppress themselves
-- when the embedded 3D atmosphere is handling those layers in world space.
function Weather.paintOverlay(w, h)
  return Core.paintOverlay(w, h)
end

function Weather.invalidate()
  return Core.invalidate()
end

function Weather.status()
  return Core.status()
end

return Weather
