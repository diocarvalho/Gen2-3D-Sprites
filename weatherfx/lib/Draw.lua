-- THE PASS: everything that happens to a frame, in the order it happens.
--
-- Both whole-frame stages -- `worldPresent` over a world pipeline's canvas
-- and `present` over the flat composite -- call exactly this one function
-- with a different rectangle, so there is ONE description of what weather
-- looks like and no chance of the renderers drifting apart.  The battle
-- screen has its own small compositor (lib/BattleDraw.lua) because it
-- draws in a different coordinate space.
--
-- THE ORDER IS THE POINT:
--
--   1. TIME-OF-DAY GRADE, multiplied.  Under everything, because the
--      time of day is a property of the light in the world, not of the
--      water in front of it: rain lit by a sun that set an hour ago
--      should be dark, and a grade over the top would dim the drops too.
--   2. WEATHER GRADE, also multiplied.  The gloom of the storm, on top of
--      the hour.  Two multiplies rather than one combined colour because
--      they have different lifetimes -- the hour eases over minutes, the
--      storm over seconds -- and combining them would mean recomputing
--      both whenever either moved.
--   3. FOG banks, between the world and the falling water.
--   4. VEIL, the flat achromatic haze a whiteout or a real murk has, over
--      the banks so it flattens them too.
--   5. PRECIPITATION, in front of all of it.
--   6. GLARE, an additive bloom, over the water: sunlight is on the lens,
--      not in the scene.
--   7. LIGHTNING, over everything including the rain, because a strike
--      lights the drops as well as the ground.
--
-- STATE IS FENCED AT BOTH ENDS.  The engine already wraps a pipeline
-- callback in love.graphics.push("all")/pop() so a mod cannot leak a bound
-- shader into the composite, but this restores blend mode, colour and
-- scissor itself anyway: worldPresent hands its canvas onward to the UI
-- composite within the same frame, and a mod that relies on somebody
-- else's cleanup is a mod that breaks when the cleanup moves.

local V = ...
local Scene = V.require("Scene")
local State = V.require("WeatherState")
local Settings = V.require("Settings")
local Config = V.require("Config")
local Quality = V.require("Quality")
local Particles = V.require("Particles")
local Lightning = V.require("Lightning")
local Fog = V.require("Fog")
local TOD = V.require("TimeOfDay")
local BattleDraw = V.require("BattleDraw")
local Legendary = V.require("Legendary")
local Funnel = V.require("Funnel")
local Rainbow = V.require("Rainbow")

-- Optional 3D atmosphere bridge (Kanto path). Loaded lazily / safely so a
-- missing module never breaks the post-process compositor.
local VoxelAtmos = nil
do
  local ok, mod = pcall(V.require, "VoxelAtmosBridge")
  if ok then VoxelAtmos = mod end
end

local Draw = {}

-- True only for the overworld when the 3D bridge is actively drawing the
-- corresponding layer. Battles always keep the 2D overlays.
local function use3dPrecip()
  if Scene.now.visible == "battle" then return false end
  -- Player chose original 2D Weather FX overlays.
  if Settings.force2dPresent and Settings.force2dPresent() then return false end
  return VoxelAtmos and VoxelAtmos.handlesPrecipitation and VoxelAtmos.handlesPrecipitation()
end

local function use3dFog()
  if Scene.now.visible == "battle" then return false end
  if Settings.force2dPresent and Settings.force2dPresent() then return false end
  return VoxelAtmos and VoxelAtmos.handlesFog and VoxelAtmos.handlesFog()
end

local function use3dRainbow()
  if Scene.now.visible == "battle" then return false end
  if Settings.force2dPresent and Settings.force2dPresent() then return false end
  return VoxelAtmos and VoxelAtmos.handlesRainbow and VoxelAtmos.handlesRainbow()
end

-- WHICH WEATHER THIS FRAME IS SHOWING.
--
-- Two authorities, one per context, and never both at once:
--
--   * the overworld's eased channels (WeatherState) for the world;
--   * the BATTLE's eased channels (BattleDraw) whenever a battle is on
--     screen, because a battle's weather comes from
--     `battle.field.weather` and not from the sky outside -- which is
--     what stops a gym battle raining and lets a Rain Dance rain.
--
-- The whole compositor goes through this, so the two can never be mixed
-- inside one frame.
function Draw.channels()
  if Scene.now.visible == "battle" and BattleDraw.live then
    return BattleDraw.channels()
  end
  return State.ch
end

-- The rect the last draw used, so the update tick has somewhere to
-- simulate before the first frame has told it how big the screen is.
local lastRect = { x = 0, y = 0, w = 0, h = 0, scale = 1 }

-- The wind is one slow oscillator shared by rain, snow, grains and
-- (faintly) fog, so everything leans together instead of each system
-- having its own idea of which way the weather is blowing.  Two sines at
-- unrelated periods: enough never to repeat visibly, cheap enough not to
-- care.
local function windAt(t, gust)
  if gust <= 0 then return 0 end
  local slow = math.sin(t * 0.19) * 0.7 + math.sin(t * 0.53 + 1.7) * 0.3
  return slow * 52 * gust        -- GB pixels per second
end

-- THE GLARE GRADIENT.
--
-- This used to be TWO rectangles -- a brighter one over the top 55% of the
-- frame and a dimmer one over the rest -- which put a hard horizontal seam
-- straight across the middle of the screen wherever they met.  Outdoors in
-- rain it was hidden under the precipitation; indoors, where nothing falls
-- but the grade still draws, it was a band across a Poke Mart.
--
-- A four-vertex mesh with per-vertex alpha gives the same "brighter toward
-- the sky" falloff as one continuous ramp, one draw call, and no edge
-- anywhere.  The lesson is small and general: two adjacent fills at
-- different alphas are a seam, not a gradient.
local glare = { mesh = nil }

local function glareMesh(x, y, w, h, topA, botA)
  if not glare.mesh then
    local ok, made = pcall(function()
      return love.graphics.newMesh({
        { 0, 0, 0, 0, 1, 1, 1, 1 },
        { 1, 0, 1, 0, 1, 1, 1, 1 },
        { 1, 1, 1, 1, 1, 1, 1, 1 },
        { 0, 1, 0, 1, 1, 1, 1, 1 },
      }, "fan", "stream")
    end)
    if not ok then return end
    glare.mesh = made
  end
  local r, g, b = 1.0, 0.94, 0.72
  glare.mesh:setVertices({
    { x,     y,     0, 0, r, g, b, topA },
    { x + w, y,     1, 0, r, g, b, topA },
    { x + w, y + h, 1, 1, r, g, b, botA },
    { x,     y + h, 0, 1, r, g, b, botA },
  })
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(glare.mesh)
end

-- WETNESS: the trace rain leaves behind.
--
-- Weather that simply stops does not read as real -- a downpour ends and
-- the world is instantly as dry as if it had never happened.  So the
-- ground REMEMBERS: `wet` rises while rain falls and drains away over a
-- couple of minutes afterwards, and puddles are drawn from it.
--
-- It is not a channel.  Channels belong to a weather and ease toward that
-- weather's value; wetness belongs to the GROUND and outlives the weather
-- entirely -- a channel would be dragged to zero the moment the rain
-- stopped, which is the one thing this must not do.
Draw.wet = 0

-- Puddle positions are fixed once and reused, so a puddle stays where it
-- is while the player walks past rather than swimming across the screen.
-- They are anchored to the WORLD by the camera, like the splashes.
local puddles = {}
local PUDDLES = 26

local function seedPuddles()
  if #puddles > 0 then return end
  local r = (love and love.math and love.math.random) or math.random
  for i = 1, PUDDLES do
    puddles[i] = {
      x = r() * 2 - 0.5,          -- in screens, so a resize keeps them
      y = r() * 2 - 0.5,
      w = 3 + r() * 9,
      h = 2 + r() * 3,
      a = 0.25 + r() * 0.5,
    }
  end
end

Draw.wind = 0
Draw.lastDt = 1 / 60

-- ------- the tick

function Draw.update(dt, level)
  pcall(function() Rainbow.update(dt) end)
  Draw.lastDt = dt
  if (level or 0) <= 0 then return end
  Quality.update(dt)

  local ch = Draw.channels()
  Draw.wind = windAt(State.elapsed, ch.gust or 0)

  local vp = Scene.viewport
  if lastRect.w <= 1 and vp then
    lastRect.x, lastRect.y = vp.x, vp.y
    lastRect.w, lastRect.h = vp.w, vp.h
    lastRect.scale = vp.scale
  end
  if lastRect.w <= 1 or lastRect.h <= 1 then return end

  Particles.setRect(lastRect.w, lastRect.h, lastRect.scale)
  Particles.spread = Config.get().splashSpread or 1
  local _, precipitation = Scene.drawScale(Settings)
  local tuning = Config.tuningFor(State.id)
  local splashesOn = precipitation
    and Settings.is("splash", "on") and Config.visual("splashes")
  Particles.update(dt, ch, Quality.budget(tuning.density), Draw.wind,
    Scene.now.camX, Scene.now.camY, splashesOn)

  local mode = Settings.get("lightning")
  if not Config.visual("lightning") then mode = "off" end
  Lightning.update(dt, ch.strike or 0, mode)
  Funnel.update(dt)

  -- Wetness fills fast and drains slowly, which is what makes it a trace
  -- rather than a second rain channel: about twenty seconds of downpour to
  -- soak the ground, and two minutes for it to dry.
  local rain = math.min(1, ch.rain or 0)
  if rain > 0.05 then
    Draw.wet = math.min(1, Draw.wet + dt * rain * 0.05)
  else
    Draw.wet = math.max(0, Draw.wet - dt / 120)
  end
end

-- ------- the pass

-- `alpha` is the frame's overall strength; `precipitation` is false
-- indoors, where the grade and the lightning survive but nothing falls.
function Draw.pass(x, y, w, h, scale, alpha, precipitation)
  if alpha <= 0 or w <= 1 or h <= 1 then return end
  local ch = Draw.channels()
  local lightMode = Settings.get("lightning")
  if not Config.visual("lightning") then lightMode = "off" end
  local flash = Lightning.flash(lightMode)

  lastRect.x, lastRect.y, lastRect.w, lastRect.h = x, y, w, h
  lastRect.scale = scale
  Particles.setRect(w, h, scale)
  Particles.camX, Particles.camY = Scene.now.camX, Scene.now.camY

  local prevR, prevG, prevB, prevA = love.graphics.getColor()
  local prevBlend, prevAlphaMode = love.graphics.getBlendMode()

  -- ------- 1. the weather's own grade
  --
  -- The TIME-OF-DAY grade is NOT here.  It used to be, and that was a
  -- design error: it welded a separate feature to the weather pipeline's
  -- ladder, so switching weather off also switched the day/night tint off.
  -- It has its own pipeline now (see main.lua), at a higher priority so it
  -- composites underneath this.
  --
  -- A strike lifts the gloom for as long as it lasts, which is the cue
  -- that sells lightning from inside a building: the room brightens even
  -- though the bolt is not on screen.
  if Config.visual("tint") then
    local dim = math.max(0, (ch.dim or 0) * alpha - flash * 0.55)
    local cool, warm = ch.cool or 0, (ch.warm or 0) * alpha
    if dim > 0.002 or warm > 0.002 then
      local r = 1 - dim * (1.00 + cool * 0.28) + warm * 0.10
      local g = 1 - dim * (1.00 + cool * 0.06) - warm * 0.02
      local b = 1 - dim * (1.00 - cool * 0.48) - warm * 0.16
      love.graphics.setBlendMode("multiply", "premultiplied")
      love.graphics.setColor(math.max(0, math.min(1, r)),
        math.max(0, math.min(1, g)), math.max(0, math.min(1, b)), 1)
      love.graphics.rectangle("fill", x, y, w, h)
      love.graphics.setBlendMode("alpha")
    end
  end

  -- ------- 2. fog
  -- Skipped on the overworld when the optional 3D atmosphere bridge is
  -- handling depth-tested fog (avoids stacking a screen-space fog on top
  -- of real 3D fog). Battles always keep the 2D fog.
  local fog = (ch.fog or 0) * alpha
  if not use3dFog() and Config.visual("fog") and fog > 0.004 and Fog.ready() then
    love.graphics.push()
    love.graphics.translate(x, y)
    Fog.draw(fog, 1.80, Quality.budget(1).fogLayers, State.elapsed,
      Scene.now.camX, Scene.now.camY, scale, w, h, ch.fogSpeed or 0.5)
    love.graphics.pop()
  end

  -- ------- 3. the veil
  local veil = (ch.veil or 0) * alpha
  if Config.visual("veil") and veil > 0.004 then
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0.88, 0.90, 0.94, math.min(0.55, veil * 0.55))
    love.graphics.rectangle("fill", x, y, w, h)
  end

  -- ------- 4. what falls
  -- Skipped on the overworld when 3D rain/snow is active so we never draw
  -- a post-process rain overlay on top of world-space 3D streaks.
  if precipitation and not use3dPrecip()
      and Config.visual("precipitation") and Particles.ready() then
    love.graphics.push()
    love.graphics.translate(x, y)
    Particles.draw(alpha, ch)
    love.graphics.pop()
  end

  -- ------- 4a. post-rain rainbow (map-anchored ends)
  if not use3dRainbow() and Rainbow and Rainbow.active
      and Rainbow.alpha and Rainbow.alpha > 0.01 then
    pcall(Rainbow.draw, x, y, w, h, scale)
  end

  -- ------- 4b. the psychic wash
  --
  -- ADDITIVE, not a multiply like every other tint in this pass: a
  -- psystorm's sky glows violet rather than being darkened toward it, and
  -- a multiply can only ever take light away.  Drawn after the
  -- precipitation so the rain glows too, which is what makes it read as
  -- the air itself being lit rather than a filter over the picture.
  local psy = (ch.psy or 0) * alpha
  if Config.visual("tint") and psy > 0.004 then
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.42, 0.10, 0.55, math.min(0.6, psy * 0.42))
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setBlendMode("alpha")
  end

  -- ------- 5. glare
  local glare = (ch.glare or 0) * alpha
  if Config.visual("glare") and glare > 0.004 then
    love.graphics.setBlendMode("add")
    glareMesh(x, y, w, h, math.min(0.5, glare * 0.34), math.min(0.28, glare * 0.16))
    love.graphics.setBlendMode("alpha")
  end

  -- ------- 6b. puddles
  --
  -- Under the falling water and over the world, because a puddle is ON the
  -- ground: drawn after the grade so it darkens with the sky, and before
  -- the funnel, which is not weather.
  if Config.visual("puddles") ~= false and Draw.wet > 0.02 and precipitation then
    seedPuddles()
    local px = math.max(0.5, scale or 1)
    local camX, camY = Scene.now.camX, Scene.now.camY
    love.graphics.setBlendMode("alpha")
    for i = 1, #puddles do
      local p = puddles[i]
      -- anchored to the world, so they sit still while the player walks
      local sx = x + ((p.x * w) - (camX * px) % (w * 1.5))
      local sy = y + ((p.y * h) - (camY * px) % (h * 1.5))
      if sx > x - 40 and sx < x + w and sy > y - 20 and sy < y + h then
        -- A darker sheen, not a blue blob: a puddle on this palette reads
        -- as the ground gone wet rather than as water lying on it.
        love.graphics.setColor(0.30, 0.36, 0.48, p.a * Draw.wet * 0.55 * alpha)
        love.graphics.rectangle("fill", sx, sy, p.w * px, p.h * px)
        -- one bright edge, which is the whole reason it reads as wet
        love.graphics.setColor(0.75, 0.85, 1.0, p.a * Draw.wet * 0.22 * alpha)
        love.graphics.rectangle("fill", sx, sy, p.w * px, math.max(1, px * 0.5))
      end
    end
  end

  -- ------- 6. lightning
  --
  -- A roused bird lends the strike its colour, so a Zapdos storm is not
  -- merely a storm that happens to contain a Zapdos.
  Lightning.tint = Legendary.boltTint()
  Lightning.draw(x, y, w, h, alpha, lightMode, Quality.budget(1).bolt)

  love.graphics.setBlendMode(prevBlend, prevAlphaMode)
  love.graphics.setColor(prevR, prevG, prevB, prevA)
end

-- ------- clipping
--
-- Two scissors, not one.  The outer one keeps weather inside the playfield
-- so it never falls in the letterbox bars.  The inner one -- only on the
-- flat renderer, and only while a dialog box is open -- keeps the FALLING
-- part above the box, so rain lands behind the text instead of on it.
--
-- The rect the particles are SIMULATED in does not change when a box
-- opens; only the visible region does.  Changing the field would rescale
-- every particle twice per conversation.

local function textBoxCut(x, y, w, h)
  if not Config.visual("textBoxClear") then return nil end
  local box = Scene.now.textBox
  if not box then return nil end
  -- the box rect is in 160x144 canvas units; the playfield is that canvas
  -- scaled to (w, h), so the conversion is one ratio per axis
  local topFrac = box.y / 144
  local visible = math.floor(h * topFrac)
  if visible <= 4 then return nil end
  return { x = x, y = y, w = w, h = visible }
end

function Draw.frame(x, y, w, h, scale, allowTextBoxCut)
  local alpha, precipitation = Scene.drawScale(Settings)
  if alpha <= 0 then return false end

  local sx, sy, sw, sh = love.graphics.getScissor()
  local ok, err

  local cut = allowTextBoxCut and textBoxCut(x, y, w, h) or nil
  if cut and precipitation then
    -- Everything except the precipitation covers the whole playfield --
    -- a grade that stopped at the text box would be worse than no grade.
    -- So the pass runs twice: once full-rect with nothing falling, once
    -- clipped with only the precipitation.
    love.graphics.setScissor(x, y, w, h)
    ok, err = pcall(Draw.pass, x, y, w, h, scale, alpha, false)
    if ok then
      love.graphics.setScissor(cut.x, cut.y, cut.w, cut.h)
      ok, err = pcall(Draw.passPrecipitationOnly, x, y, w, h, scale, alpha)
    end
  else
    love.graphics.setScissor(x, y, w, h)
    ok, err = pcall(Draw.pass, x, y, w, h, scale, alpha, precipitation)
  end

  if sx then
    love.graphics.setScissor(sx, sy, sw, sh)
  else
    love.graphics.setScissor()
  end
  if not ok then error(err, 0) end   -- let the engine retire the pipeline
  return true
end

-- The precipitation layer on its own, for the clipped second pass.
function Draw.passPrecipitationOnly(x, y, w, h, scale, alpha)
  -- When the 3D atmosphere bridge is drawing world-space rain, skip the
  -- 2D particle pass so the two never stack.
  if use3dPrecip() then return end
  if not (Config.visual("precipitation") and Particles.ready()) then return end
  local prevR, prevG, prevB, prevA = love.graphics.getColor()
  local prevBlend, prevAlphaMode = love.graphics.getBlendMode()
  love.graphics.push()
  love.graphics.translate(x, y)
  Particles.draw(alpha, Draw.channels())
  love.graphics.pop()
  -- ------- 7. the funnel, over everything
  --
  -- Last, and outside the weather's own alpha: a tornado is an event
  -- happening TO the frame rather than weather in it, so it is not thinned
  -- by the BATTLES setting or the indoor rule.
  Funnel.draw(x, y, w, h, scale)

  love.graphics.setBlendMode(prevBlend, prevAlphaMode)
  love.graphics.setColor(prevR, prevG, prevB, prevA)
end

-- THE TIME-OF-DAY GRADE, on its own.
--
-- Its own pass, called by its own pipeline, so it survives the weather
-- being switched off entirely.  A multiply for the colour of the light and
-- an add to put a little back into the shadows -- an add is what stops a
-- night grade reading as "the brightness control is broken".
--
-- Returns true if it drew, which the pipeline's stage handshake needs.
function Draw.grade(x, y, w, h, indoors)
  local mr, mg, mb, ar, ag, ab = TOD.grade(indoors)
  if not mr then return false end
  local prevR, prevG, prevB, prevA = love.graphics.getColor()
  local prevBlend, prevAlphaMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode("multiply", "premultiplied")
  love.graphics.setColor(mr, mg, mb, 1)
  love.graphics.rectangle("fill", x, y, w, h)
  if ar > 0.001 or ag > 0.001 or ab > 0.001 then
    love.graphics.setBlendMode("add")
    love.graphics.setColor(ar, ag, ab, 1)
    love.graphics.rectangle("fill", x, y, w, h)
  end
  love.graphics.setBlendMode(prevBlend, prevAlphaMode)
  love.graphics.setColor(prevR, prevG, prevB, prevA)
  return true
end

function Draw.invalidate()
  glare.mesh = nil
  puddles = {}
  Particles.invalidate()
  Fog.invalidate()
  Lightning.reset()
  lastRect.w, lastRect.h = 0, 0
end

return Draw
