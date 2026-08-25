-- Rainbow after rain.
--
-- The arc is WORLD-ANCHORED: two ends are fixed in map pixel space when the
-- rainbow appears, so walking the map moves the camera under a stationary
-- bow.  A player can walk to either foot of the arc.
--
-- Timing:
--   • Any continuous wet (rain) spell arms a "had rain" flag.
--   • The rainbow only starts once the sky leaves rain entirely
--     (CLEAR / sun / etc.).  Light rain → primal rain does NOT show a
--     rainbow in between; it waits until after the whole wet spell ends.
--   • Fade in gently, hold, then fade out.  One rainbow per rain spell.

local V = ...
local Scene = V.require("Scene")
local Types = V.require("Types")
local State = V.require("WeatherState")

local Rainbow = {}

-- Tunables (real seconds).
local FADE_IN = 10.0
local HOLD = 90.0
local FADE_OUT = 18.0
local TOTAL = FADE_IN + HOLD + FADE_OUT

-- Weather ids that count as "still raining" (no rainbow yet).
local function isRainId(id)
  if not id then return false end
  id = tostring(id):upper()
  if id == "RAIN_LIGHT" or id == "RAIN_HEAVY" or id == "HEAVY_RAIN"
      or id == "STORM" or id == "VERDANT_RAIN" or id == "SLEET" then
    return true
  end
  -- Tagged wet + precipitation channel for any future rain-like weather.
  local def = Types.get(id)
  if def and def.wet and def.ch and (def.ch.rain or 0) > 0.05 then
    return true
  end
  return false
end

local function hashStr(s)
  s = tostring(s or "")
  local h = 2166136261
  for i = 1, #s do
    h = (h * 16777619 + s:byte(i)) % 2147483647
  end
  return h
end

-- Map pixel size when the host exposes it; otherwise a generous default so
-- ends still land somewhere on typical Gen 1/2 outdoor maps.
local function mapPixelBounds()
  local w, h = 1280, 1152  -- conservative fallback
  pcall(function()
    -- Use the generation-neutral mod world service first. Gold's live map is
    -- game.world and exposes widthCells/heightCells; src.core.Game is the Gen1
    -- service owner and gave the embedded port the fallback size on every Gold
    -- map, putting rainbow feet hundreds of tiles from the actual scene.
    local ow = V.mod and V.mod.world and V.mod.world:overworld() or nil
    local map = ow and ow.map
    if not map then return end
    local tw = tonumber(map.widthCells) or tonumber(map.width) or tonumber(map.w)
    local th = tonumber(map.heightCells) or tonumber(map.height) or tonumber(map.h)
    if (not tw or not th) and type(map.def) == "table" then
      tw = tw or tonumber(map.def.widthCells) or (tonumber(map.def.width) and tonumber(map.def.width) * 4)
      th = th or tonumber(map.def.heightCells) or (tonumber(map.def.height) and tonumber(map.def.height) * 4)
    end
    local ts = tonumber(map.tileSize) or 16
    if tw and th and tw > 4 and th > 4 then w, h = tw * ts, th * ts end
  end)
  return w, h
end

-- Two fixed feet for this map. Deterministic so reloading the same map
-- after the same rain spell can regenerate the same places if needed;
-- while active we keep the stored ends so they never drift.
local function anchorsForMap(mapId)
  local mw, mh = mapPixelBounds()
  local h1 = hashStr(mapId .. ":a")
  local h2 = hashStr(mapId .. ":b")
  local margin = 48
  local ax = margin + (h1 % math.max(1, mw - margin * 2))
  local ay = margin + ((h1 / 97) % math.max(1, mh - margin * 2))
  local bx = margin + (h2 % math.max(1, mw - margin * 2))
  local by = margin + ((h2 / 91) % math.max(1, mh - margin * 2))
  -- Ensure ends are meaningfully apart so the arc is readable.
  local dx, dy = bx - ax, by - ay
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist < 220 then
    bx = math.min(mw - margin, ax + 280)
    by = math.min(mh - margin, ay + 120)
  end
  return ax, ay, bx, by
end

Rainbow.active = false
Rainbow.alpha = 0
Rainbow.age = 0
Rainbow.mapId = nil
Rainbow.ax, Rainbow.ay, Rainbow.bx, Rainbow.by = 0, 0, 0, 0
Rainbow.hadRain = false
Rainbow.lastId = nil

function Rainbow.reset()
  Rainbow.active = false
  Rainbow.alpha = 0
  Rainbow.age = 0
  Rainbow.mapId = nil
end

function Rainbow.update(dt)
  dt = tonumber(dt) or 0
  if dt < 0 then dt = 0 end
  if dt > 0.25 then dt = 0.25 end

  local id = State.id
  local raining = isRainId(id)

  if raining then
    Rainbow.hadRain = true
    -- Still in a wet spell (including light → primal): no rainbow yet.
    if Rainbow.active then
      -- Rain returned while a bow was up — clear it.
      Rainbow.reset()
    end
  elseif Rainbow.hadRain and not raining then
    -- Wet spell just ended. Start a map-locked rainbow outdoors only.
    local outdoor = Scene.now and Scene.now.outdoor
    local world = Scene.now and Scene.now.visible == "world"
    if outdoor and world and not Rainbow.active then
      local mapId = Scene.now.mapId or "UNKNOWN"
      Rainbow.mapId = mapId
      Rainbow.ax, Rainbow.ay, Rainbow.bx, Rainbow.by = anchorsForMap(mapId)
      Rainbow.active = true
      Rainbow.age = 0
      Rainbow.alpha = 0
    end
    Rainbow.hadRain = false
  end

  Rainbow.lastId = id

  if not Rainbow.active then return end

  -- Drop if we left the map or went indoors / off the world.
  if Scene.now then
    if Scene.now.mapId and Rainbow.mapId and Scene.now.mapId ~= Rainbow.mapId then
      Rainbow.reset()
      return
    end
    if Scene.now.visible ~= "world" or not Scene.now.outdoor then
      Rainbow.reset()
      return
    end
  end

  Rainbow.age = Rainbow.age + dt
  if Rainbow.age >= TOTAL then
    Rainbow.reset()
    return
  end

  if Rainbow.age < FADE_IN then
    Rainbow.alpha = Rainbow.age / FADE_IN
  elseif Rainbow.age < FADE_IN + HOLD then
    Rainbow.alpha = 1
  else
    local t = (Rainbow.age - FADE_IN - HOLD) / FADE_OUT
    Rainbow.alpha = math.max(0, 1 - t)
  end
end

-- Spectral band colours (light → violet), drawn as parallel arcs.
local BANDS = {
  { 0.95, 0.25, 0.22 },
  { 0.95, 0.55, 0.15 },
  { 0.95, 0.88, 0.20 },
  { 0.35, 0.85, 0.35 },
  { 0.30, 0.55, 0.95 },
  { 0.45, 0.30, 0.90 },
  { 0.65, 0.25, 0.80 },
}

local function worldToScreen(wx, wy, x, y)
  local camX = (Scene.now and Scene.now.camX) or 0
  local camY = (Scene.now and Scene.now.camY) or 0
  return x + (wx - camX), y + (wy - camY)
end

function Rainbow.draw(x, y, w, h, scale)
  if not Rainbow.active or Rainbow.alpha <= 0.01 then return end
  if not (love and love.graphics) then return end
  scale = scale or 1

  local a1x, a1y = worldToScreen(Rainbow.ax, Rainbow.ay, x, y)
  local b1x, b1y = worldToScreen(Rainbow.bx, Rainbow.by, x, y)

  -- Arc geometry: midpoint + height proportional to span.
  local mx, my = (a1x + b1x) * 0.5, (a1y + b1y) * 0.5
  local span = math.sqrt((b1x - a1x) ^ 2 + (b1y - a1y) ^ 2)
  if span < 8 then return end
  local arch = math.min(h * 0.55, span * 0.42)

  local alpha = Rainbow.alpha * 0.55
  local prevR, prevG, prevB, prevA = love.graphics.getColor()
  local prevBlend, prevMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode("alpha")
  love.graphics.setLineStyle("smooth")

  local steps = 32
  for bi, col in ipairs(BANDS) do
    local offset = (bi - 4) * (2.2 * scale)
    local bandA = alpha * (1.0 - math.abs(bi - 4) * 0.06)
    love.graphics.setColor(col[1], col[2], col[3], bandA)
    love.graphics.setLineWidth(math.max(1.2, 2.4 * scale))
    local pts = {}
    for i = 0, steps do
      local t = i / steps
      -- Quadratic Bezier-like arch: ends on the ground, peak above midpoint.
      local px = a1x + (b1x - a1x) * t
      local py = a1y + (b1y - a1y) * t - math.sin(t * math.pi) * arch + offset
      pts[#pts + 1] = px
      pts[#pts + 1] = py
    end
    if #pts >= 4 then
      pcall(love.graphics.line, pts)
    end
  end

  -- Soft feet so the player can hunt the ends on the ground.
  local footA = alpha * 0.35
  love.graphics.setColor(1, 1, 1, footA)
  local fr = 5 * scale
  pcall(love.graphics.circle, "fill", a1x, a1y, fr)
  pcall(love.graphics.circle, "fill", b1x, b1y, fr)
  love.graphics.setColor(0.85, 0.9, 1.0, footA * 0.6)
  pcall(love.graphics.circle, "line", a1x, a1y, fr * 1.6)
  pcall(love.graphics.circle, "line", b1x, b1y, fr * 1.6)

  love.graphics.setLineWidth(1)
  if prevBlend then love.graphics.setBlendMode(prevBlend, prevMode) end
  love.graphics.setColor(prevR, prevG, prevB, prevA)
end

-- Stadium2 / voxel presentation. The original Weather FX rainbow is correct
-- for a flat scrolling camera, but subtracting camX/camY is not a projection
-- under a free 3D camera. Keep the same map-locked feet and lifetime, then
-- project a real world-space arch through the host camera. Because this is
-- painted with the sky before terrain, roofs/trees/ground naturally draw over
-- the lower parts of the bow instead of the rainbow being pasted over them.
function Rainbow.draw3D(Voxel3D, w, h)
  if not Rainbow.active or Rainbow.alpha <= 0.01 then return end
  if not (love and love.graphics and Voxel3D and Voxel3D.project) then return end
  if Scene.now and (Scene.now.visible ~= "world" or not Scene.now.outdoor) then return end
  w, h = tonumber(w) or 0, tonumber(h) or 0
  if w <= 1 or h <= 1 then return end

  local dx, dz = Rainbow.bx - Rainbow.ax, Rainbow.by - Rainbow.ay
  local span = math.sqrt(dx * dx + dz * dz)
  if span < 16 then return end
  local arch = math.max(72, math.min(190, span * 0.44))
  local groundY = 8
  local screenScale = math.max(0.75, h / 144)
  local alpha = Rainbow.alpha * 0.52

  local pr, pg, pb, pa = love.graphics.getColor()
  local prevBlend, prevMode = love.graphics.getBlendMode()
  local prevWidth = love.graphics.getLineWidth and love.graphics.getLineWidth() or 1
  love.graphics.setBlendMode("alpha")
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(math.max(1.4, 2.35 * screenScale))

  local steps = 48
  for bi, col in ipairs(BANDS) do
    -- Red is the outer/high band and violet the inner/low band. The offset is
    -- in WORLD height, so perspective naturally compresses the bands at distance.
    local bandY = (4 - bi) * 2.2
    local bandA = alpha * (1.0 - math.abs(bi - 4) * 0.055)
    love.graphics.setColor(col[1], col[2], col[3], bandA)
    local pts = {}
    local function flush()
      if #pts >= 4 then pcall(love.graphics.line, pts) end
      pts = {}
    end
    for i = 0, steps do
      local t = i / steps
      local wx = Rainbow.ax + dx * t
      local wz = Rainbow.ay + dz * t
      local wy = groundY + math.sin(t * math.pi) * arch + bandY
      local sx, sy = Voxel3D.project(wx, wy, wz)
      if sx and sy and sx > -w * 0.5 and sx < w * 1.5 and sy > -h and sy < h * 1.5 then
        pts[#pts + 1], pts[#pts + 1] = sx, sy
      else
        flush()
      end
    end
    flush()
  end

  love.graphics.setLineWidth(prevWidth or 1)
  if prevBlend then love.graphics.setBlendMode(prevBlend, prevMode) end
  love.graphics.setColor(pr, pg, pb, pa)
end

function Rainbow.describe()
  if not Rainbow.active then return "off" end
  return string.format("on a=%.2f map=%s", Rainbow.alpha, tostring(Rainbow.mapId))
end

return Rainbow
