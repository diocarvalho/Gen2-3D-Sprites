-- v0.3.48 regression: Gold's official render_pipelines drawWorld contract is
-- LOGICAL scene size, not Gen1 Renderer.worldOverride's physical framebuffer.
-- World:drawPipeline draws the returned canvas at (0,0) with no DPI divisor.
-- Returning a 2x/2.75x Android framebuffer therefore looks massively zoomed.

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

local currentCanvas = { name = "caller" }
local lastDraw
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

-- Simulate a 2.75x Android surface: Gold itself draws in 1000x600 logical
-- units while the physical framebuffer is 2750x1650.
love = {
  graphics = {
    getDimensions = function() return 1000, 600 end,
    getPixelDimensions = function() return 2750, 1650 end,
    getCanvas = function() return currentCanvas end,
    setCanvas = function(c) currentCanvas = c end,
    newCanvas = function(w, h) return canvas(w, h) end,
    push = function() end,
    pop = function() end,
    origin = function() end,
    clear = function() end,
    setColor = function() end,
    draw = function(scene, x, y, r, sx, sy)
      lastDraw = { scene = scene, x = x, y = y, sx = sx, sy = sy }
    end,
  },
}

local modStub = {
  path = "tests",
  options = { get = function() return nil end },
  read = function() return nil, "unused in Gold pipeline sizing regression" end,
}
local Bridge = assert(loadfile("lib/GoldVoxelBridge.lua"))(modStub)

-- Generation 2 MUST ignore the larger physical framebuffer and TouchSkin/
-- Gen1 worldOverride sizing rules.  Gold will draw this canvas directly.
local g = Bridge._frameGeometry({
  generation = 2,
  ww = 1000, wh = 600,
  pw = 2750, ph = 1650,
}, 1)
eq(g.frameWidth, 1000, "Gold output width is logical")
eq(g.frameHeight, 600, "Gold output height is logical")
eq(g.width, 1000, "Gold drawable width is logical")
eq(g.height, 600, "Gold drawable height is logical")
eq(g.renderWidth, 1000, "Gold 100% render width")
eq(g.renderHeight, 600, "Gold 100% render height")
eq(g.source, "gold-logical-pipeline", "Gold sizing source")
check(not g.cropped, "Gold pipeline never applies Gen1 TouchSkin crop")

-- Internal resolution is private. The returned frame still normalizes to the
-- logical Gold scene, so a 55% render cannot become a smaller top-left image.
local low = Bridge._frameGeometry({ generation = 2, ww = 1000, wh = 600 }, 0.55)
eq(low.renderWidth, 550, "Gold 55% render width")
eq(low.renderHeight, 330, "Gold 55% render height")
eq(low.frameWidth, 1000, "Gold 55% output width")
eq(low.frameHeight, 600, "Gold 55% output height")

local scene = canvas(550, 330)
local caller = currentCanvas
local out = Bridge._normalizeFrame(scene, low)
eq(out:getWidth(), 1000, "normalized Gold output width")
eq(out:getHeight(), 600, "normalized Gold output height")
eq(currentCanvas, caller, "normalization restores caller canvas")
eq(lastDraw.scene, scene, "normalization draws source scene")
eq(lastDraw.x, 0, "Gold scene starts at x=0")
eq(lastDraw.y, 0, "Gold scene starts at y=0")
near(lastDraw.sx, 1000 / 550, "Gold internal-resolution x upscale")
near(lastDraw.sy, 600 / 330, "Gold internal-resolution y upscale")

-- Gen1 still keeps the physical framebuffer behavior when no viewport helper
-- is installed in this isolated fixture.
local g1 = Bridge._frameGeometry({ generation = 1, ww = 1000, wh = 600 }, 1)
eq(g1.frameWidth, 2750, "Gen1 fallback remains physical width")
eq(g1.frameHeight, 1650, "Gen1 fallback remains physical height")

print("android_gold_pipeline_size_parity: OK")
