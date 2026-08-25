-- PRECIPITATION AND DEBRIS: everything that moves through the air.
--
-- FOUR DECISIONS WORTH THE COMMENT:
--
-- 1. ONE DRAW CALL, ALWAYS.  Every drop, flake, grain, leaf and splash
--    tick goes into a single SpriteBatch built on a 1x1 white texture, so
--    a full-tier downpour is one draw call and one texture bind rather
--    than 900.  The 1x1 texture is also the reason there is no `assets/`
--    folder: a white pixel stretched to (length, thickness) and rotated IS
--    a rain streak, and scaled square IS a flake.  Nothing is shipped,
--    nothing is derived from the ROM, and the batch's per-sprite colour
--    does the rest.
--
-- 2. NOTHING IS ALLOCATED AFTER WARMUP.  The pools are flat parallel
--    arrays sized once to the quality cap.  A drop that falls off the
--    bottom is not freed and a new one is not created -- the same slot is
--    rewound to the top with fresh randomness.  Density changes by moving
--    an `active` count, so a drizzle is the same memory as a storm and the
--    garbage collector never sees weather.
--
-- 3. THREE POOLS, NOT SIX.  Rain and snow each get their own because they
--    coexist (hail is snow with grains through it) and behave completely
--    differently.  Hail, sand and debris share the GRAIN pool: they are
--    all "a hard little thing thrown across the screen", they differ only
--    in colour, speed, angle and whether they tumble, and two of the three
--    are mutually exclusive weathers anyway.  Each grain carries its kind,
--    assigned at spawn by rolling against the live channel mix -- so a
--    transition from sandstorm to hail is grains changing kind one at a
--    time as they recycle, which reads as the storm turning over rather
--    than as one effect being swapped for another.
--
-- 4. PARTICLES ARE SIZED IN GAME-BOY PIXELS, NOT SCREEN PIXELS.  Every
--    length and speed here is in GB pixels and multiplied by the frame's
--    scale at draw time, so weather looks the same at 1x in a small
--    window, at 6x fullscreen, through the survey zoom, and over a voxel
--    diorama, whose scale is the same number measured the same way.
--
-- SPLASHES AND BOUNCES CARRY THEIR OWN CAMERA.  A splash is on the GROUND,
-- but this system draws in screen space, so one spawned while the player
-- is walking would slide with the screen for its whole life.  Each records
-- the camera position it was born at and is drawn offset by how far the
-- camera has moved since, which pins it to the ground for the third of a
-- second it exists, at the cost of two numbers per splash.

local V = ...

local P = {}

-- LÖVE 11 is LuaJIT, where math.atan2 exists; a 5.3+ host (a headless test
-- runner, a future LÖVE) folds it into math.atan.  One line here beats a
-- version check at the call site.
local atan2 = math.atan2 or math.atan

-- ------- the white pixel

local pixel, batch, batchCap = nil, nil, 0

local function ensureTexture()
  if pixel then return pixel end
  if not (love and love.graphics and love.image) then return nil end
  local ok, image = pcall(function()
    local data = love.image.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 1)
    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
  end)
  if not ok then return nil end
  pixel = image
  return pixel
end

local function ensureBatch(capacity)
  if not ensureTexture() then return nil end
  if batch and batchCap >= capacity then return batch end
  local ok, made = pcall(love.graphics.newSpriteBatch, pixel, capacity, "stream")
  if not ok then return nil end
  batch, batchCap = made, capacity
  return batch
end

function P.ready()
  return ensureTexture() ~= nil
end

function P.invalidate()
  pixel, batch, batchCap = nil, nil, 0
end

-- ------- pools

local function newPool(fields)
  local pool = { n = 0, active = 0 }
  for _, name in ipairs(fields) do pool[name] = {} end
  return pool
end

-- `ld` is the y this drop lands at.  THE WHOLE SCREEN IS GROUND in a
-- top-down game: rain that only bursts along the bottom edge is what a
-- side-on game would do, and it reads as the rain falling behind the world
-- instead of onto it.  Each drop picks its own landing depth at spawn, so
-- splashes appear at every distance at once, the way they do out a window.
local rain  = newPool({ "x", "y", "vs", "ls", "a", "ld" })
local snow  = newPool({ "x", "y", "vs", "ph", "sw", "sz", "a" })
-- grain: kind 1 = hail, 2 = sand, 3 = debris, 4 = ash
local grain = newPool({ "x", "y", "vx", "vy", "kind", "sz", "a", "rot", "spin", "ld" })
-- splash: kind 1 = water burst, 2 = hail bounce, 3 = dust puff
local splash = newPool({ "x", "y", "cx", "cy", "t", "sz", "kind" })

local function rnd(a, b)
  if love and love.math and love.math.random then return love.math.random() * (b - a) + a end
  return math.random() * (b - a) + a
end

local rect = { w = 0, h = 0, scale = 1 }

local function rescale(w, h)
  if rect.w <= 0 or rect.h <= 0 then return end
  local fx, fy = w / rect.w, h / rect.h
  for i = 1, rain.n do
    rain.x[i] = rain.x[i] * fx
    rain.y[i] = rain.y[i] * fy
    rain.ld[i] = rain.ld[i] * fy
  end
  for i = 1, snow.n do snow.x[i] = snow.x[i] * fx; snow.y[i] = snow.y[i] * fy end
  for i = 1, grain.n do
    grain.x[i] = grain.x[i] * fx
    grain.y[i] = grain.y[i] * fy
    grain.ld[i] = grain.ld[i] * fy
  end
  -- splashes are transient; letting them die where they are is cheaper
  -- and invisible
end

function P.setRect(w, h, scale)
  w, h = math.max(1, w or 1), math.max(1, h or 1)
  if w ~= rect.w or h ~= rect.h then
    rescale(w, h)
    rect.w, rect.h = w, h
  end
  rect.scale = math.max(0.25, scale or 1)
end

-- ------- spawners
--
-- `fresh` scatters through the whole field (first fill, so the sky is not
-- empty for a second); otherwise the particle is rewound to just outside
-- the edge it entered from, which is where a recycled one belongs.

-- How far up the screen a drop may land, 0..1 (config `splashSpread`).
-- 1 = anywhere on screen, 0 = the bottom edge only.
P.spread = 1.0

local function landingY(fresh, startY)
  local top = rect.h * (1 - math.max(0, math.min(1, P.spread)))
  local y = rnd(top, rect.h)
  -- A drop rewound to the top must not be given a landing depth it has
  -- already passed, or it recycles instantly and the pool thrashes.
  if startY and y < startY then y = rect.h end
  return y
end

local function spawnRain(i, fresh)
  rain.x[i] = rnd(-0.25 * rect.w, 1.25 * rect.w)
  rain.y[i] = fresh and rnd(0, rect.h) or rnd(-0.2 * rect.h, -2)
  rain.vs[i] = rnd(0.82, 1.25)
  rain.ls[i] = rnd(0.7, 1.4)
  rain.a[i] = rnd(0.45, 1.0)
  rain.ld[i] = landingY(fresh, rain.y[i])
end

local function spawnSnow(i, fresh)
  snow.x[i] = rnd(-0.2 * rect.w, 1.2 * rect.w)
  snow.y[i] = fresh and rnd(0, rect.h) or rnd(-0.15 * rect.h, -2)
  snow.vs[i] = rnd(0.6, 1.5)
  snow.ph[i] = rnd(0, math.pi * 2)
  snow.sw[i] = rnd(0.4, 1.6)
  snow.sz[i] = rnd(0.8, 2.1)
  snow.a[i] = rnd(0.55, 1.0)
end

-- The kind mix, refreshed each tick from the channels.  Rolling per spawn
-- rather than per pool is what makes a weather change look like the air
-- turning over instead of a swap.
local kindMix = { 0, 0, 0, 0 }
local kindTotal = 0

local function rollKind()
  if kindTotal <= 0 then return 1 end
  local roll = rnd(0, kindTotal)
  for k = 1, 4 do
    roll = roll - kindMix[k]
    if roll <= 0 then return k end
  end
  return 1
end

-- Per-kind motion.  Hail falls hard and nearly straight; sand is thrown
-- almost horizontally and barely falls at all; debris tumbles across on
-- the wind at every height.
local function spawnGrain(i, fresh)
  local kind = rollKind()
  grain.kind[i] = kind
  if kind == 2 then                                   -- sand
    grain.x[i] = fresh and rnd(0, rect.w) or rnd(-0.3 * rect.w, -4)
    grain.y[i] = rnd(-0.1 * rect.h, rect.h)
    grain.vx[i] = rnd(1.6, 3.0)
    grain.vy[i] = rnd(0.05, 0.35)
    grain.sz[i] = rnd(0.7, 1.5)
    grain.a[i] = rnd(0.35, 0.9)
  elseif kind == 4 then                               -- volcanic ash
    -- Ash is not sand blown sideways: it falls, slowly, almost straight
    -- down, and it drifts rather than streaks.
    grain.x[i] = rnd(-0.15 * rect.w, 1.15 * rect.w)
    grain.y[i] = fresh and rnd(0, rect.h) or rnd(-0.2 * rect.h, -3)
    grain.vx[i] = rnd(-0.10, 0.14)
    grain.vy[i] = rnd(0.18, 0.42)
    grain.sz[i] = rnd(0.9, 2.0)
    grain.a[i] = rnd(0.35, 0.85)
  elseif kind == 3 then                               -- debris
    grain.x[i] = fresh and rnd(0, rect.w) or rnd(-0.3 * rect.w, -6)
    grain.y[i] = rnd(-0.2 * rect.h, rect.h)
    grain.vx[i] = rnd(1.1, 2.2)
    grain.vy[i] = rnd(-0.25, 0.5)
    grain.sz[i] = rnd(1.6, 3.4)
    grain.a[i] = rnd(0.5, 1.0)
  else                                                -- hail
    grain.x[i] = rnd(-0.15 * rect.w, 1.15 * rect.w)
    grain.y[i] = fresh and rnd(0, rect.h) or rnd(-0.2 * rect.h, -3)
    grain.vx[i] = rnd(-0.12, 0.30)
    grain.vy[i] = rnd(1.5, 2.4)
    grain.sz[i] = rnd(1.0, 2.0)
    grain.a[i] = rnd(0.7, 1.0)
  end
  -- hail bounces where it lands, and lands all over the screen for the
  -- same reason rain does
  grain.ld[i] = (kind == 1) and landingY(fresh, grain.y[i]) or (rect.h * 2)
  grain.rot[i] = rnd(0, math.pi * 2)
  grain.spin[i] = (kind == 3) and rnd(-6, 6) or ((kind == 4) and rnd(-1.2, 1.2) or 0)
end

local function spawnSplash(i)
  splash.x[i], splash.y[i] = 0, 0
  splash.cx[i], splash.cy[i] = 0, 0
  splash.t[i] = -1                      -- negative = dead slot
  splash.sz[i], splash.kind[i] = 1, 1
end

local function grow(pool, capacity, spawn)
  while pool.n < capacity do
    pool.n = pool.n + 1
    spawn(pool.n, true)
  end
end

-- Splashes use a rolling cursor rather than a free list: the pool is
-- small, every entry has the same short life, and overwriting the oldest
-- is both correct and one increment.
local splashCursor = 0

local function addSplash(x, y, camX, camY, size, kind)
  if splash.n <= 0 then return end
  splashCursor = splashCursor % splash.n + 1
  local i = splashCursor
  splash.x[i], splash.y[i] = x, y
  splash.cx[i], splash.cy[i] = camX, camY
  splash.t[i] = 0
  splash.sz[i], splash.kind[i] = size, kind or 1
end

-- ------- the tick

local SPLASH_LIFE = 0.30

-- `ch` is the eased channel table; `budget` the quality caps; `wind` the
-- frame's gust in GB pixels per second; `camX/camY` the world camera, for
-- splash anchoring; `splashesOn` the player's setting.
function P.update(dt, ch, budget, wind, camX, camY, splashesOn)
  if dt <= 0 then return end
  local px = rect.scale

  if rain.n < budget.rain then grow(rain, budget.rain, spawnRain) end
  if snow.n < budget.snow then grow(snow, budget.snow, spawnSnow) end
  if splash.n < budget.splash then grow(splash, budget.splash, spawnSplash) end

  -- the grain mix has to be set before the pool grows, or the first fill
  -- is all hail whatever the weather
  kindMix[1] = math.max(0, ch.hail or 0)
  kindMix[2] = math.max(0, ch.sand or 0)
  kindMix[3] = math.max(0, ch.debris or 0)
  kindMix[4] = math.max(0, ch.ash or 0)
  kindTotal = kindMix[1] + kindMix[2] + kindMix[3] + kindMix[4]
  if grain.n < budget.grain then grow(grain, budget.grain, spawnGrain) end

  rain.active = math.min(rain.n, math.floor(budget.rain * math.min(1, ch.rain or 0) + 0.5))
  snow.active = math.min(snow.n, math.floor(budget.snow * math.min(1, ch.snow or 0) + 0.5))
  grain.active = math.min(grain.n, math.floor(budget.grain * math.min(1, kindTotal) + 0.5))

  -- ------- rain
  local fall = 210 * (ch.rainSpeed or 1) * px
  local lean = math.tan(ch.rainAngle or 0)
  local drift = (lean * fall) + wind * px
  local splashChance = splashesOn and (ch.splash or 0) or 0
  for i = 1, rain.active do
    local vs = rain.vs[i]
    local ny = rain.y[i] + fall * vs * dt
    local nx = rain.x[i] + drift * vs * dt
    if ny >= rain.ld[i] then
      -- Land it.  A splash for a FRACTION of drops rather than all of
      -- them: every drop bursting reads as a solid line of foam, and the
      -- fraction is the channel, so a drizzle ticks and a downpour boils.
      if splashChance > 0 and rnd(0, 1) < splashChance * 0.35 then
        addSplash(nx, rain.ld[i], camX, camY, rnd(0.7, 1.3), 1)
      end
      spawnRain(i, false)
    elseif nx < -0.3 * rect.w or nx > 1.3 * rect.w then
      spawnRain(i, false)
    else
      rain.x[i], rain.y[i] = nx, ny
    end
  end

  -- ------- snow
  local sfall = 46 * (ch.snowSpeed or 1) * px
  local sdrift = (ch.snowDrift or 0)
  for i = 1, snow.active do
    snow.ph[i] = snow.ph[i] + dt * (0.9 + snow.sw[i])
    local sway = math.sin(snow.ph[i]) * 26 * sdrift * snow.sw[i] * px
    local ny = snow.y[i] + sfall * snow.vs[i] * dt
    local nx = snow.x[i] + (sway + wind * px * 0.8) * dt
    if ny >= rect.h or nx < -0.25 * rect.w or nx > 1.25 * rect.w then
      spawnSnow(i, false)
    else
      snow.x[i], snow.y[i] = nx, ny
    end
  end

  -- ------- grains
  --
  -- One loop for all three kinds: the kind only picks the base speeds,
  -- which were baked into vx/vy at spawn, so the motion here is common.
  local base = 150 * px
  for i = 1, grain.active do
    local kind = grain.kind[i]
    local vx = grain.vx[i] * base + wind * px * (kind == 1 and 0.5 or 1.2)
    local vy = grain.vy[i] * base
    local nx = grain.x[i] + vx * dt
    local ny = grain.y[i] + vy * dt
    if grain.spin[i] ~= 0 then grain.rot[i] = grain.rot[i] + grain.spin[i] * dt end
    if kind == 4 and ny >= rect.h then
      spawnGrain(i, false)                -- ash settles; no bounce, no burst
    elseif kind == 1 and ny >= grain.ld[i] then
      -- hail bounces: the burst is the same pool as a rain splash, in a
      -- colder colour and half the spread
      if splashesOn and rnd(0, 1) < 0.5 then
        addSplash(nx, grain.ld[i], camX, camY, rnd(0.5, 0.9), 2)
      end
      spawnGrain(i, false)
    elseif ny >= rect.h * 1.2 or ny < -0.35 * rect.h
        or nx < -0.35 * rect.w or nx > 1.35 * rect.w then
      spawnGrain(i, false)
    else
      grain.x[i], grain.y[i] = nx, ny
    end
  end

  -- ------- splashes
  for i = 1, splash.n do
    local t = splash.t[i]
    if t >= 0 then
      t = t + dt
      splash.t[i] = (t >= SPLASH_LIFE) and -1 or t
    end
  end
end

-- ------- the draw
--
-- Colours are chosen to read on the Game Boy's four-shade palettes as well
-- as on a full-colour diorama: rain is a cool near-white at low alpha (it
-- reads as a lightening streak on dark tiles and a darkening one on
-- light), snow and hail are flat white, sand is a warm tan, debris is a
-- dark olive.

local RAIN_R, RAIN_G, RAIN_B = 0.74, 0.83, 0.98
local GRAIN_COLOR = {
  { 0.92, 0.96, 1.00 },   -- hail: white with a blue edge
  { 0.85, 0.72, 0.48 },   -- sand: warm tan
  { 0.45, 0.42, 0.24 },   -- debris: dry olive
  { 0.58, 0.55, 0.53 },   -- ash: dead grey, faintly warm
}
local SPLASH_COLOR = {
  { RAIN_R, RAIN_G, RAIN_B },
  { 0.92, 0.96, 1.00 },
  { 0.80, 0.70, 0.50 },
}

function P.draw(alpha, ch)
  local total = rain.active + snow.active + grain.active + splash.n * 2
  if total <= 0 or alpha <= 0 then return end
  local b = ensureBatch(math.max(64, total + 32))
  if not b then return end
  b:clear()

  local px = rect.scale
  local added = 0

  -- rain: a 1x1 pixel stretched to (length, thickness) and rotated to the
  -- direction of travel, so the streak always points the way the drop is
  -- going however hard the wind is blowing
  if rain.active > 0 then
    local angle = atan2(1, math.tan(ch.rainAngle or 0))
    local len = 9 * (ch.rainLen or 1) * px
    local thick = math.max(1, 0.7 * px)
    local base = alpha * 0.55
    for i = 1, rain.active do
      b:setColor(RAIN_R, RAIN_G, RAIN_B, base * rain.a[i])
      b:add(rain.x[i], rain.y[i], angle, len * rain.ls[i], thick, 0, 0.5)
      added = added + 1
    end
  end

  -- snow: an axis-aligned square, no rotation -- a flake is a pixel in
  -- this art style and spinning it would only alias
  if snow.active > 0 then
    local base = alpha * 0.85
    for i = 1, snow.active do
      local s = snow.sz[i] * px
      b:setColor(1, 1, 1, base * snow.a[i])
      b:add(snow.x[i], snow.y[i], 0, s, s, 0.5, 0.5)
      added = added + 1
    end
  end

  -- grains: hail is a short vertical dash, sand a long horizontal one,
  -- debris a tumbling flake.  All three are the same quad at different
  -- aspect ratios and rotations.
  if grain.active > 0 then
    for i = 1, grain.active do
      local kind = grain.kind[i]
      local c = GRAIN_COLOR[kind]
      local s = grain.sz[i] * px
      local w, h, rot
      if kind == 2 then
        w, h, rot = s * 3.2, math.max(1, s * 0.45), grain.rot[i] * 0 + 0.12
      elseif kind == 4 then
        -- a soft flake, barely rotated: ash tumbles lazily
        w, h, rot = s * 1.1, s * 1.1, grain.rot[i]
      elseif kind == 3 then
        w, h, rot = s * 1.5, s * 0.9, grain.rot[i]
      else
        w, h, rot = math.max(1, s * 0.7), s * 1.6, 0
      end
      b:setColor(c[1], c[2], c[3], alpha * grain.a[i] * 0.9)
      b:add(grain.x[i], grain.y[i], rot, w, h, 0.5, 0.5)
      added = added + 1
    end
  end

  -- splashes: two ticks thrown apart and up, shrinking as they fade, drawn
  -- at the camera offset they were born with so they stay on the ground
  if splash.n > 0 then
    for i = 1, splash.n do
      local t = splash.t[i]
      if t >= 0 then
        local k = t / SPLASH_LIFE
        local kind = splash.kind[i]
        local c = SPLASH_COLOR[kind] or SPLASH_COLOR[1]
        local spread = (1 + k * (kind == 2 and 2.0 or 3.2)) * splash.sz[i] * px
        local rise = -k * (kind == 2 and 3.4 or 2.4) * px
        local a = alpha * 0.7 * (1 - k) * (1 - k)
        local ox = splash.x[i] + (splash.cx[i] - P.camX) * px
        local oy = splash.y[i] + (splash.cy[i] - P.camY) * px
        local w = math.max(1, 1.1 * px * (1 - k * 0.5))
        b:setColor(c[1], c[2], c[3], a)
        b:add(ox - spread, oy + rise, 0, w, math.max(1, 0.7 * px), 0.5, 0.5)
        b:add(ox + spread, oy + rise, 0, w, math.max(1, 0.7 * px), 0.5, 0.5)
        added = added + 2
      end
    end
  end

  if added == 0 then return end
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(b)
end

-- The camera the CURRENT frame is drawn at; splashes subtract the one they
-- were born at from it.  Set by Draw before P.draw.
P.camX, P.camY = 0, 0

function P.counts()
  return rain.active, snow.active, grain.active, splash.n
end

-- The y of one live splash, or nil for a dead slot.  For the test suite:
-- "splashes land at many depths" is the property that makes rain read as
-- falling ONTO a top-down world rather than behind it, and it is worth
-- asserting rather than eyeballing.
function P.splashY(i)
  if i < 1 or i > splash.n then return nil end
  if splash.t[i] < 0 then return nil end
  return splash.y[i]
end

function P.reset()
  rain.active, snow.active, grain.active = 0, 0, 0
  for i = 1, splash.n do splash.t[i] = -1 end
end

return P
