-- LIGHTNING.
--
-- A strike is two things drawn together: a FLASH that lights the whole
-- frame, and a BOLT that is the shape of it.  They are separated here
-- because the accessibility setting separates them -- SOFT keeps a slow
-- glow and throws away both the sharp attack and the bolt, and that has to
-- be one branch, not a rewrite.
--
-- THE FLASH IS AN ENVELOPE, NOT A FRAME.  A single white frame is what a
-- naive implementation does and it looks like a dropped frame; real
-- lightning flickers, because a strike is several return strokes down the
-- same channel milliseconds apart.  So the envelope is a sum of decaying
-- pulses at irregular offsets -- and that same envelope, with the pulses
-- removed and the decay stretched, is exactly the SOFT setting.
--
-- ACCESSIBILITY IS A FIRST-CLASS SETTING, NOT A COURTESY.  Repeated
-- full-screen flashes are a genuine hazard for photosensitive players, so
-- LIGHTNING has three positions and every one of them is a supported way
-- to play the mod: FULL is the effect, SOFT is a slow glow with no attack
-- and no bolt, and OFF is silence.  A storm at OFF is still a storm -- the
-- rain, the gloom and the wind all remain -- so nobody has to give up the
-- weather to turn off the flashing.
--
-- THE BOLT is midpoint displacement: a line from the strike point to the
-- horizon, recursively split with each new point pushed sideways by half
-- the remaining span.  Fifteen or so segments and one optional fork.
-- Generated once per strike and held for its life, because regenerating it
-- per frame would make it crawl.

local V = ...

local L = {}

local function rnd(a, b)
  if love and love.math and love.math.random then return love.math.random() * (b - a) + a end
  return math.random() * (b - a) + a
end

-- ------- live state

L.timer = 0            -- seconds until the next strike
L.age = -1             -- seconds since the current strike, negative = none
L.life = 0             -- how long the current strike lasts
L.bolt = nil           -- flat {x1,y1,x2,y2,...} in 0..1 rect space
L.fork = nil
L.pulses = nil         -- {offset, weight} pairs making up the envelope
L.side = 0             -- which side of the sky it came from, for the tint

-- ------- the bolt

local function displace(points, x1, y1, x2, y2, spread, depth)
  if depth <= 0 then
    points[#points + 1] = x2
    points[#points + 1] = y2
    return
  end
  local mx = (x1 + x2) * 0.5 + rnd(-spread, spread)
  local my = (y1 + y2) * 0.5 + rnd(-spread * 0.15, spread * 0.15)
  displace(points, x1, y1, mx, my, spread * 0.55, depth - 1)
  displace(points, mx, my, x2, y2, spread * 0.55, depth - 1)
end

local function makeBolt()
  local x0 = rnd(0.1, 0.9)
  local x1 = x0 + rnd(-0.18, 0.18)
  local points = { x0, -0.05 }
  displace(points, x0, -0.05, x1, rnd(0.45, 0.75), 0.09, 4)
  -- one fork, from a point a third of the way down
  local fork = nil
  if #points >= 12 and rnd(0, 1) < 0.6 then
    local i = 2 * math.floor(#points / 6) + 1
    local fx, fy = points[i], points[i + 1]
    fork = { fx, fy }
    displace(fork, fx, fy, fx + rnd(-0.22, 0.22), fy + rnd(0.15, 0.3), 0.05, 3)
  end
  return points, fork, (x0 < 0.5) and -1 or 1
end

-- ------- the envelope

local function makePulses(soft)
  if soft then
    -- one long swell, no attack: the light in the room changing rather
    -- than a camera flash
    return { { 0.0, 1.0 } }, rnd(1.1, 1.6)
  end
  local pulses = { { 0.0, 1.0 } }
  local n = math.floor(rnd(1, 3.99))
  local at = 0
  for _ = 1, n do
    at = at + rnd(0.045, 0.13)
    pulses[#pulses + 1] = { at, rnd(0.35, 0.85) }
  end
  return pulses, at + rnd(0.35, 0.6)
end

-- Envelope value at `age`, 0..1.  Each pulse is an instant attack and an
-- exponential decay; SOFT replaces the attack with a raised cosine.
local function envelope(age, pulses, soft, life)
  if soft then
    if age < 0 or age > life then return 0 end
    return 0.5 - 0.5 * math.cos(2 * math.pi * (age / life))
  end
  local v = 0
  for i = 1, #pulses do
    local dt = age - pulses[i][1]
    if dt >= 0 then
      v = v + pulses[i][2] * math.exp(-dt * 11)
    end
  end
  return math.min(1, v)
end

-- ------- the tick
--
-- `rate` is strikes per minute (the `strike` channel); `mode` is the
-- player's LIGHTNING setting.

function L.update(dt, rate, mode)
  if mode == "off" or (rate or 0) <= 0 then
    -- Let a strike already in the air finish rather than cutting it, but
    -- schedule no more.  Cutting it mid-flash is itself a flash.
    if L.age >= 0 then
      L.age = L.age + dt
      if L.age > L.life then L.age = -1 end
    end
    L.timer = 0
    return
  end

  if L.age >= 0 then
    L.age = L.age + dt
    if L.age > L.life then L.age = -1 end
  end

  L.timer = L.timer - dt
  if L.timer > 0 then return end

  -- Strikes are a Poisson process, so the gap is exponential rather than
  -- uniform: strikes cluster the way real ones do instead of ticking like
  -- a metronome, from the same average rate.
  local mean = 60 / math.max(0.01, rate)
  local u = math.max(1e-4, rnd(0, 1))
  L.timer = math.max(0.35, -math.log(u) * mean)

  local soft = (mode == "soft")
  L.pulses, L.life = makePulses(soft)
  L.age = 0
  if soft then
    L.bolt, L.fork, L.side = nil, nil, 0
  else
    L.bolt, L.fork, L.side = makeBolt()
  end
end

-- The flash's current strength, 0..1.  Read by the draw path for the
-- screen wash, and by the tint so the whole frame lifts with it -- which
-- is what makes a strike visible from indoors through a window.
function L.flash(mode)
  if L.age < 0 or mode == "off" then return 0 end
  local soft = (mode == "soft")
  local v = envelope(L.age, L.pulses or {}, soft, L.life)
  return v * (soft and 0.30 or 1.0)
end

-- ------- the draw

-- The colour of a strike.  Default is the cool near-white real lightning
-- has; a roused bird lends its own (lib/Legendary.lua), which is set on
-- L.tint by the compositor each frame.  Kept as a field rather than a
-- parameter so the SOFT glow, the wash and the bolt all read the same one
-- without three call sites needing to agree.
L.tint = nil

local function washColour()
  local t = L.tint
  if not t then return 0.90, 0.93, 1.0 end
  return t[1], t[2], t[3]
end

local function coreColour()
  local t = L.tint
  if not t then return 0.75, 0.84, 1.0 end
  -- the glow around the bolt is the tint pulled toward white, so a yellow
  -- strike still reads as light rather than as a painted line
  return (t[1] + 0.75) * 0.5, (t[2] + 0.84) * 0.5, (t[3] + 1.0) * 0.5
end

function L.draw(x, y, w, h, alpha, mode, drawBolt)
  local f = L.flash(mode)
  if f <= 0 or alpha <= 0 then return end

  -- the wash: a cool white over everything, at the envelope's strength
  love.graphics.setBlendMode("alpha")
  local wr, wg, wb = washColour()
  love.graphics.setColor(wr, wg, wb, math.min(0.72, f * 0.55 * alpha))
  love.graphics.rectangle("fill", x, y, w, h)

  if not (drawBolt and L.bolt and mode == "full") then return end
  -- The bolt is brightest at the very start and gone well before the
  -- flash is, which is how a real one reads: the channel is momentary,
  -- the sky it lit is not.
  local boltA = math.max(0, 1 - L.age * 7) * alpha
  if boltA <= 0.01 then return end

  local function project(points)
    local out = {}
    for i = 1, #points, 2 do
      out[i] = x + points[i] * w
      out[i + 1] = y + points[i + 1] * h
    end
    return out
  end

  local prevWidth = love.graphics.getLineWidth()
  local scale = math.max(1, h / 288)
  -- drawn twice: a wide soft core and a thin bright one, which is a
  -- cheap glow without a shader or a second pass
  love.graphics.setLineWidth(3.2 * scale)
  local cr, cg, cb = coreColour()
  love.graphics.setColor(cr, cg, cb, boltA * 0.45)
  love.graphics.line(project(L.bolt))
  if L.fork then love.graphics.line(project(L.fork)) end
  love.graphics.setLineWidth(1.2 * scale)
  love.graphics.setColor(1, 1, 1, boltA)
  love.graphics.line(project(L.bolt))
  if L.fork then love.graphics.line(project(L.fork)) end
  love.graphics.setLineWidth(prevWidth)
end

function L.reset()
  L.age, L.timer, L.bolt, L.fork = -1, 0, nil, nil
end

return L
