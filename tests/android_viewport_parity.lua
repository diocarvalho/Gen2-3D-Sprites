-- v0.3.47 regression: Android TouchSkin gameplay viewport + world pipeline
-- framing.  The Kanto/voxel scene must use the same physical drawable rect as
-- Gen1Recomp Renderer.displayMetrics(), then normalize back to a full-frame
-- worldOverride canvas.  Otherwise a smaller gameplay view is stretched over
-- the whole phone and looks zoomed/cropped when the engine scissors it back.

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function near(actual, expected, label)
  if math.abs(actual - expected) > 1e-6 then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(value, label)
  if not value then error(label or "check failed", 2) end
end

love = {
  graphics = {
    getDimensions = function() return 1000, 600 end,
    getPixelDimensions = function() return 2000, 1200 end,
  },
}

local oldViewport = package.loaded["src.render.GameViewport"]
local oldTouchSkin = package.loaded["src.core.TouchSkin"]

package.loaded["src.render.GameViewport"] = {
  active = function() return true end,
  dimensions = function() return 1000, 600 end,
  pixelDimensions = function() return 2000, 1200 end,
  -- Raw OS touch -> game-viewport logical touch.  Keep a non-zero viewport
  -- origin so the test catches ordering mistakes before TouchSkin subtraction.
  toLocal = function(x, y)
    local lx, ly = x - 10, y - 20
    return lx, ly, lx >= 0 and ly >= 0 and lx < 1000 and ly < 600
  end,
}
package.loaded["src.core.TouchSkin"] = {
  viewport = function(w, h)
    eq(w, 2000, "TouchSkin receives full physical width")
    eq(h, 1200, "TouchSkin receives full physical height")
    return 100, 60, 1600, 900
  end,
}

local Compat = assert(loadfile("lib/EngineViewportCompat.lua"))()

-- Physical gameplay rectangle: exact TouchSkin carve-out inside the full
-- framebuffer, matching Renderer.displayMetrics().
local x, y, w, h, fw, fh, source = Compat.drawablePixelRect()
eq(x, 100, "drawable pixel x")
eq(y, 60, "drawable pixel y")
eq(w, 1600, "drawable pixel width")
eq(h, 900, "drawable pixel height")
eq(fw, 2000, "full framebuffer width")
eq(fh, 1200, "full framebuffer height")
eq(source, "touch-skin", "drawable source")

-- Logical camera/touch rectangle uses the same carve-out scaled through the
-- GameViewport unit<->pixel ratio (2x on both axes in this fixture).
local lx, ly, lw, lh = Compat.drawableLogicalRect()
near(lx, 50, "drawable logical x")
near(ly, 30, "drawable logical y")
near(lw, 800, "drawable logical width")
near(lh, 450, "drawable logical height")

-- Internal resolution may be lower, but the frame handed to worldOverride is
-- still full framebuffer size; only the scene render target shrinks.
local g = Compat.renderGeometry(0.55)
eq(g.frameWidth, 2000, "normalized frame width")
eq(g.frameHeight, 1200, "normalized frame height")
eq(g.x, 100, "scene placement x")
eq(g.y, 60, "scene placement y")
eq(g.width, 1600, "scene placement width")
eq(g.height, 900, "scene placement height")
eq(g.renderWidth, 880, "55% scene render width")
eq(g.renderHeight, 495, "55% scene render height")
check(g.cropped, "TouchSkin geometry is marked cropped")

-- Direct Android camera polling first removes GameViewport's OS-window
-- offset, then the TouchSkin gameplay offset.  Controls outside the gameplay
-- rectangle are intentionally rejected here (TouchControls are tested raw by
-- GoldVoxelBridge before this helper is called).
local tx, ty, inside = Compat.toDrawableLocal(210, 140)
near(tx, 150, "drawable-local touch x")
near(ty, 90, "drawable-local touch y")
check(inside, "touch inside drawable")
local ox, oy, outside = Compat.toDrawableLocal(50, 30)
near(ox, -10, "outside touch local x")
near(oy, -20, "outside touch local y")
check(outside == false, "touch outside drawable rejected")

-- Older/no-skin hosts preserve the historical full-frame behavior.
package.loaded["src.core.TouchSkin"] = { viewport = function() return nil end }
local CompatFull = assert(loadfile("lib/EngineViewportCompat.lua"))()
local full = CompatFull.renderGeometry(0.55)
eq(full.x, 0, "full-frame x fallback")
eq(full.y, 0, "full-frame y fallback")
eq(full.width, 2000, "full-frame drawable width")
eq(full.height, 1200, "full-frame drawable height")
eq(full.frameWidth, 2000, "full-frame output width")
eq(full.frameHeight, 1200, "full-frame output height")
eq(full.renderWidth, 1100, "full-frame 55% render width")
eq(full.renderHeight, 660, "full-frame 55% render height")
check(not full.cropped, "no TouchSkin means no crop")

package.loaded["src.render.GameViewport"] = oldViewport
package.loaded["src.core.TouchSkin"] = oldTouchSkin
print("android_viewport_parity: OK")

-- The provider must also honor that geometry when returning a pipeline frame:
-- a lower-resolution scene is upscaled into the TouchSkin rectangle of a
-- full physical framebuffer canvas.  Renderer.endFrame can then perform its
-- documented 1:1 worldOverride blit without cropping/magnifying the scene.
do
  local currentCanvas = { name = "caller" }
  local drawCall
  local function canvas(w, h)
    return {
      _w = w, _h = h,
      getDimensions = function(self) return self._w, self._h end,
      getWidth = function(self) return self._w end,
      getHeight = function(self) return self._h end,
      setFilter = function() end,
      release = function() end,
    }
  end
  love.graphics.getCanvas = function() return currentCanvas end
  love.graphics.setCanvas = function(c) currentCanvas = c end
  love.graphics.newCanvas = function(w, h) return canvas(w, h) end
  love.graphics.push = function() end
  love.graphics.pop = function() end
  love.graphics.origin = function() end
  love.graphics.clear = function() end
  love.graphics.setColor = function() end
  love.graphics.draw = function(scene, x, y, r, sx, sy)
    drawCall = { scene = scene, x = x, y = y, sx = sx, sy = sy }
  end

  local modStub = {
    path = "tests",
    options = { get = function() return nil end },
    read = function() return nil, "unused in viewport regression" end,
  }
  local Bridge = assert(loadfile("lib/GoldVoxelBridge.lua"))(modStub)
  local scene = canvas(880, 495)
  local caller = currentCanvas
  local out = Bridge._normalizeFrame(scene, g)
  eq(out:getWidth(), 2000, "normalized worldOverride width")
  eq(out:getHeight(), 1200, "normalized worldOverride height")
  eq(currentCanvas, caller, "normalization restores caller canvas")
  eq(drawCall.scene, scene, "normalization draws source scene")
  eq(drawCall.x, 100, "normalization places scene at TouchSkin x")
  eq(drawCall.y, 60, "normalization places scene at TouchSkin y")
  near(drawCall.sx, 1600 / 880, "normalization x scale")
  near(drawCall.sy, 900 / 495, "normalization y scale")
  check(Bridge.frameNormalized == true, "provider reports normalized frame")
end

print("android_viewport_worldoverride_parity: OK")
