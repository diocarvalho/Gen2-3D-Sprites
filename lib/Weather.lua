-- Outdoor weather + cloud layer for the Gold voxel renderer.
local V = ...
local Weather = { outdoor = false, mapKey = "" }

local function option(key, fallback)
  local mod = V.mod
  if mod and mod.options and type(mod.options.get) == "function" then
    local ok, value = pcall(mod.options.get, mod.options, key)
    if ok and value ~= nil then return value end
  end
  return fallback
end

local function clock()
  if love and love.timer and love.timer.getTime then
    local ok, t = pcall(love.timer.getTime)
    if ok and t then return t end
  end
  return os.clock and os.clock() or 0
end

local function hashString(s)
  local h = 5381
  for i = 1, #(s or "") do
    h = (h * 33 + string.byte(s, i)) % 2147483647
  end
  return h
end

function Weather.setContext(outdoor, map)
  Weather.outdoor = outdoor and true or false
  local def = map and map.def or nil
  Weather.mapKey = tostring((def and (def.id or def.name or def.map)) or
                            (map and (map.id or map.name)) or "gold")
end

function Weather.mode()
  if not Weather.outdoor then return "clear" end
  local mode = tostring(option("weatherMode", "auto")):lower()
  if mode ~= "auto" then return mode end
  local bucket = math.floor(clock() / 180)
  local n = (hashString(Weather.mapKey) + bucket * 1103515245) % 100
  if n < 48 then return "clear" end
  if n < 70 then return "rain" end
  if n < 87 then return "fog" end
  return "rain_fog"
end

function Weather.hasRain()
  local m = Weather.mode()
  return m == "rain" or m == "rain_fog"
end

function Weather.hasFog()
  local m = Weather.mode()
  return m == "fog" or m == "rain_fog"
end

local function safeGraphics()
  return love and love.graphics and love.graphics.rectangle
end

local function pushAll(g)
  if g.push then pcall(g.push, "all") end
  if g.origin then pcall(g.origin) end
  if g.setShader then pcall(g.setShader) end
  if g.setDepthMode then pcall(g.setDepthMode) end
  if g.setBlendMode then pcall(g.setBlendMode, "alpha") end
end

local function popAll(g)
  if g.pop then pcall(g.pop) end
end

function Weather.paintSky(w, h, horizonY, cell, skyRay)
  if not Weather.outdoor or not safeGraphics() then return end
  if option("weatherClouds", true) == false then return end
  local g = love.graphics
  local t = clock()
  cell = math.max(1, math.floor((cell or 1) + 0.5))
  local skyBottom = horizonY
  if not (skyBottom and skyBottom > 1 and skyBottom < h) then
    skyBottom = h * 0.28
  end
  if skyRay then skyBottom = h * 0.46 end
  skyBottom = math.max(cell * 5, math.min(h * 0.58, skyBottom))

  local m = Weather.mode()
  local storm = (m == "rain" or m == "rain_fog")
  local alpha = storm and 0.34 or 0.22
  local shade = storm and 0.34 or 0.78

  pushAll(g)
  if g.setScissor then pcall(g.setScissor, 0, 0, w, math.ceil(skyBottom)) end
  local layers = {
    { speed = 5.5, y = 0.16, scale = 1.00, phase = 17 },
    { speed = 2.7, y = 0.30, scale = 0.72, phase = 71 },
  }
  for li, spec in ipairs(layers) do
    local bw = math.max(cell * 5, math.floor(w * 0.13 * spec.scale / cell) * cell)
    local bh = math.max(cell * 2, math.floor(h * 0.035 * spec.scale / cell) * cell)
    local gap = bw + cell * (10 + li * 4)
    local drift = (t * spec.speed + spec.phase * cell) % gap
    local y0 = math.floor((skyBottom * spec.y) / cell) * cell
    for x = -gap, w + gap, gap do
      local bx = math.floor((x + drift) / cell) * cell
      g.setColor(shade, shade, math.min(1, shade + 0.03), alpha * (li == 1 and 1 or 0.8))
      g.rectangle("fill", bx, y0 + bh, bw, bh)
      g.rectangle("fill", bx + bw * 0.16, y0 + bh * 0.40, bw * 0.55, bh)
      g.rectangle("fill", bx + bw * 0.48, y0, bw * 0.28, bh * 1.15)
      g.rectangle("fill", bx + bw * 0.70, y0 + bh * 0.62, bw * 0.24, bh * 0.85)
    end
  end
  if g.setScissor then pcall(g.setScissor) end
  g.setColor(1, 1, 1, 1)
  popAll(g)
end

local function rainOverlay(g, w, h, t)
  local count = math.max(40, math.floor((w * h) / 9000))
  local speed = 510
  local slant = 7
  g.setColor(0.78, 0.86, 1.0, 0.48)
  for i = 1, count do
    local seed = i * 97 + hashString(Weather.mapKey) % 997
    local x0 = (seed * 37) % math.max(1, w + 80) - 40
    local y0 = (seed * 53 + t * speed * (0.78 + (i % 7) * 0.04)) % math.max(1, h + 36) - 18
    local x = (x0 + t * 34) % (w + 80) - 40
    local len = 8 + (i % 5) * 2
    if g.line then g.line(x, y0, x - slant, y0 + len) end
  end
end

local function fogOverlay(g, w, h, t)
  for i = 1, 7 do
    local phase = t * (5 + i * 0.8) + i * 47
    local y = h * (0.30 + i * 0.085) + math.sin(phase * 0.025) * 9
    local hh = h * (0.10 + (i % 3) * 0.025)
    local a = 0.035 + i * 0.007
    g.setColor(0.76, 0.80, 0.84, a)
    g.rectangle("fill", -20, y, w + 40, hh)
  end
  g.setColor(0.70, 0.75, 0.80, 0.055)
  g.rectangle("fill", 0, 0, w, h)
end

function Weather.paintOverlay(w, h)
  if not Weather.outdoor or not safeGraphics() then return end
  local rain, fog = Weather.hasRain(), Weather.hasFog()
  if not rain and not fog then return end
  local g = love.graphics
  pushAll(g)
  local t = clock()
  if fog then fogOverlay(g, w, h, t) end
  if rain then rainOverlay(g, w, h, t) end
  g.setColor(1, 1, 1, 1)
  popAll(g)
end

function Weather.invalidate() end
return Weather
