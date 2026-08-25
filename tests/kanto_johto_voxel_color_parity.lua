-- v0.3.78 regression: Kanto voxel GEOMETRY may still use native Gen-2
-- Kanto donors, while COLOR comes from the ACTUAL Johto town/route.  Johto color authority is locked per semantic MATERIAL FAMILY using actual donor-map placement frequency, so rare alternate Johto tiles cannot make neighbouring Kanto surfaces drift. Johto pixel positions and Johto shade-population dithering are never pasted onto Kanto surfaces.
package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.render.Assets"] = function()
  return { imageData = function() error("imageData not needed in pure probe") end }
end
package.preload["src.world.gen2.Permissions"] = function() return {} end

local V = {
  require = function(name)
    if name == "GoldColorAtlas" then return {} end
    error("unexpected V.require: " .. tostring(name))
  end,
  data = function(name)
    if name == "voxel_heights" then return { heights = {}, tilesets = {}, buildings = {} } end
    error("unexpected V.data: " .. tostring(name))
  end,
}

local chunk = assert(loadfile("lib/KantoGen2Style.lua"))
local Style = chunk(V)

local kantoTs = {
  id = "TILESET_KANTO", image = "kanto.png", tilesPerRow = 1,
  tilePalettes = { 7 },
}
local johtoTs = {
  id = "TILESET_JOHTO", image = "johto.png", tilesPerRow = 2,
  -- tile 0 = spare structure slot 3 (not used by Cherrygrove),
  -- tile 1 = Cherrygrove roof slot 6, tile 2 = facade slot 2,
  -- tile 3 = ground slot 4.
  tilePalettes = { 3, 6, 2, 4 },
  blocks = { { 1, 1, 2, 2, 3, 3, 3, 3 } },
}
local world = {
  tilesets = { TILESET_KANTO = kantoTs, TILESET_JOHTO = johtoTs },
  maps = {
    PALLET_TOWN = { id = "PALLET_TOWN", tileset = "TILESET_KANTO" },
    CHERRYGROVE_CITY = {
      id = "CHERRYGROVE_CITY", tileset = "TILESET_JOHTO",
      blocks = { 0 }, borderBlock = 0,
    },
    NEW_BARK_TOWN = {
      id = "NEW_BARK_TOWN", tileset = "TILESET_JOHTO",
      blocks = { 0 }, borderBlock = 0,
    },
    ROUTE_29 = {
      id = "ROUTE_29", tileset = "TILESET_JOHTO",
      blocks = { 0 }, borderBlock = 0,
    },
  },
}

local geometry = Style._donorFor(world, "PALLET_TOWN", { tileset = "OVERWORLD" }, true)
assert(geometry and geometry.engineId == "TILESET_KANTO",
  "Pallet geometry should still be allowed to use native Gen-2 Kanto")

local colors = Style._colorDonorFor(world, "PALLET_TOWN", { tileset = "OVERWORLD" }, true)
assert(colors and colors.engineId == "TILESET_JOHTO",
  "outdoor Kanto color donor must be Johto")
assert(colors.id == "CHERRYGROVE_CITY",
  "Kanto towns should use a real Johto city material family, not New Bark-only slots")
local routeColors = Style._colorDonorFor(world, "ROUTE_1", { tileset = "OVERWORLD" }, true)
assert(routeColors and routeColors.id == "ROUTE_29",
  "Kanto routes should prefer Route 29's Johto material family")

-- Building-template role split: collision sees both as structure, but the
-- screenshot-visible roof and facade must not share one arbitrary slot.
local roles = assert(Style._buildingRoleMap({
  { tiles = { { 1, 1 }, { 2, 2 } }, roofRows = 8 },
}))
assert(roles[1] == "building:roof", "template roof row must classify as roof")
assert(roles[2] == "building:facade", "template lower row must classify as facade")
local materialSlots = assert(Style._dominantMaterialSlots(
  { def = world.maps.CHERRYGROVE_CITY, tileset = johtoTs }, nil, roles))
assert(materialSlots["building:roof"] == 6,
  "roof color must come from Cherrygrove's USED roof slot")
assert(materialSlots["building:facade"] == 2,
  "facade color must come from Cherrygrove's USED facade slot")

-- v0.3.78 retains the v0.3.77 frequency lock: two roof palette families can both be valid/used,
-- but the one occupying most actual map placements must become the stable roof
-- material.  A unique-tile-id vote would tie these and pick slot 3 first.
local weightedTs = {
  id = "TILESET_JOHTO", image = "weighted.png", tilesPerRow = 2,
  tilePalettes = { 3, 6 },
  blocks = {
    { 0,0,0,0,0,0,0,0 },
    { 1,1,1,1,1,1,1,1 },
  },
}
local weightedRef = {
  def = { blocks = { 0, 1, 1, 1, 1, 1 } },
  tileset = weightedTs,
}
local freq = assert(Style._mapTileFrequencies(weightedRef))
assert(freq[1] == 40 and freq[0] == 8,
  "donor material voting must count actual map placement frequency")
local locked = assert(Style._materialProfiles(weightedRef, nil,
  { [0] = "building:roof", [1] = "building:roof" }))
assert(locked["building:roof"].slot == 6 and locked["building:roof"].tile == 1,
  "the visually dominant Johto roof family must lock Kanto roofs to slot 6")
local merged = Style._mergeMaterialProfiles(
  { ground = { slot = 4, tile = 3 } },
  { ground = { slot = 1, tile = 0 }, ["building:roof"] = { slot = 6, tile = 1 } })
assert(merged.ground.slot == 4 and merged["building:roof"].slot == 6,
  "supplemental Johto scenes must fill missing roles without overriding the primary donor")

local profile = {
  default = 1, ground = 4,
  slots = {
    [1] = { {255,255,255},{200,200,200},{100,100,100},{0,0,0} },
    [2] = { {255,255,255},{235,210,130},{170,120,45},{0,0,0} },
    [3] = { {255,255,255},{120,180,210},{30,60,90},{0,0,0} },
    [4] = { {255,255,255},{170,210,130},{60,120,40},{0,0,0} },
    [6] = { {255,255,255},{235,90,200},{215,35,145},{0,0,0} },
    [7] = { {255,255,255},{220,150,110},{180,70,40},{0,0,0} },
  },
}
local sourceTs = { walkable = { 1 } }
local style = {
  donorTs = kantoTs,
  colorDonorTs = johtoTs,
  -- Deliberately make the per-tile nearest donor WRONG (tile 0 / slot 3).
  -- v0.3.78's scene-wide roof lock must beat it with slot 6.
  colorSlotDonor = { [0] = 0 },
  slotDonor = { [0] = 0 },
  categories = { [0] = "building:roof" },
  materialProfiles = { ["building:roof"] = { slot = 6, tile = 1 } },
  materialSlots = { ["building:roof"] = 6 },
  profile = profile,
}
assert(Style._resolvedColorSlot(style, sourceTs, 0, 0) == 6,
  "scene-wide Johto roof family lock must beat a conflicting per-tile donor")
assert(Style._resolvedColorSlot(style, sourceTs, 1, nil) == 4,
  "unmatched walkable Kanto tile must fall back to Johto profile ground slot")

local function imageData(w, h, value)
  local p = {}
  local obj = {}
  function obj:getDimensions() return w, h end
  function obj:getPixel(x, y)
    local v = p[y * w + x]
    if v then return v[1], v[2], v[3], v[4] end
    return value, value, value, 1
  end
  function obj:setPixel(x, y, r, g, b, a)
    p[y * w + x] = { r, g, b, a }
  end
  return obj
end

-- Scene/role restriction beats a closer unrelated structure tile.  Tile 0
-- is a perfect grayscale match but is NOT a roof; tile 1 is the Johto roof
-- actually used by the donor scene and therefore must win.
local probeSrc = imageData(8, 8, 1/3)
local probeDonor = imageData(16, 8, 1/3)
for y = 0, 7 do for x = 8, 15 do probeDonor:setPixel(x, y, 2/3, 2/3, 2/3, 1) end end
local sceneNearest = assert(Style._buildSceneColorRemap(
  probeSrc, { tilesPerRow = 1 }, nil, { [0] = "building:roof" },
  probeDonor, { tilesPerRow = 2 }, nil, { [1] = "building:roof" },
  { [0] = true, [1] = true }))
assert(sceneNearest[0] == 1,
  "scene color remap must keep a Kanto roof on an actually-used Johto roof tile")

_G.love = { image = { newImageData = function(w, h) return imageData(w, h, 0) end } }

-- Uniform direct-shade test. The native-Kanto geometry tile is uniformly
-- shade 3 while the representative Johto roof happens to be shade 2. v0.3.78
-- must IGNORE that donor histogram and keep native shade 3, recolored through
-- Johto slot 6.
local src = imageData(8, 8, 1)
local geometryDonor = imageData(8, 8, 1/3)
local johtoMaterial = imageData(16, 8, 1/3)
for y = 0, 7 do for x = 8, 15 do johtoMaterial:setPixel(x, y, 2/3, 2/3, 2/3, 1) end end
style.donorPixels = geometryDonor
style.colorDonorPixels = johtoMaterial
style.remap = { [0] = 0 }
local out = assert(Style.colorize(src, sourceTs, style))
local r, g, b = out:getPixel(0, 0)
local function near(a, b) return math.abs(a - b) < 0.00001 end
assert(near(r, 215/255) and near(g, 35/255) and near(b, 145/255),
  "visible Kanto roof must use Johto slot-6 color while preserving native shade 3")

-- Spatial-preservation test. Give native Kanto a LEFT/RIGHT light-dark split
-- and Johto an unrelated TOP/BOTTOM split with the same histogram. If donor
-- pixels were pasted (the v0.3.74 bug), bottom-left would turn dark and
-- top-right light. v0.3.78 must keep Kanto's left/right pattern exactly.
local geomPattern = imageData(8, 8, 1)
for y = 0, 7 do
  for x = 0, 7 do
    local v = (x < 4) and 1 or 0
    geomPattern:setPixel(x, y, v, v, v, 1)
  end
end
local johtoPattern = imageData(16, 8, 1)
for y = 0, 7 do
  for x = 8, 15 do
    local v = (y < 4) and 1 or 0
    johtoPattern:setPixel(x, y, v, v, v, 1)
  end
end
style.donorPixels = geomPattern
style.colorDonorPixels = johtoPattern
local spatial = assert(Style.colorize(src, sourceTs, style))
local lr1, lg1, lb1 = spatial:getPixel(0, 7) -- Kanto left side: light
local rr1, rg1, rb1 = spatial:getPixel(7, 0) -- Kanto right side: dark
assert(near(lr1, 1) and near(lg1, 1) and near(lb1, 1),
  "bottom-left must stay Kanto-light; Johto top/bottom pixels must not be pasted")
assert(near(rr1, 0) and near(rg1, 0) and near(rb1, 0),
  "top-right must stay Kanto-dark; Johto top/bottom pixels must not be pasted")

-- v0.3.78 screenshot regression: donor shade-population must NOT be injected
-- into the visible Kanto texture.  The v0.3.76/77 exact-population transfer
-- generated the black/brown checker field visible on paths and noisy walls.
-- A flat Kanto/native-Kanto shade therefore stays flat even if the representative
-- Johto material tile contains all four shades; only the selected Johto PALMAP
-- ramp changes the RGB value.
local flat = imageData(8, 8, 1/3) -- source shade 3 everywhere
local fourWay = imageData(8, 8, 1)
for y = 0, 7 do
  for x = 0, 7 do
    local i = y * 8 + x
    local band = math.floor(i / 16)
    local v = ({ 1, 2/3, 1/3, 0 })[band + 1]
    fourWay:setPixel(x, y, v, v, v, 1)
  end
end
style.donorPixels = flat
style.colorDonorPixels = fourWay
style.colorSlotDonor = { [0] = 0 }
style.colorDonorTs = { tilesPerRow = 1, tilePalettes = { 6 } }
style.materialProfiles = { ["building:roof"] = { slot = 6, tile = 0 } }
local cleanOut = assert(Style.colorize(src, sourceTs, style))
local seen = {}
for y = 0, 7 do
  for x = 0, 7 do
    local cr, cg, cb = cleanOut:getPixel(x, y)
    local key = string.format("%.4f/%.4f/%.4f", cr, cg, cb)
    seen[key] = (seen[key] or 0) + 1
  end
end
local distinct, total = 0, 0
for _, n in pairs(seen) do distinct = distinct + 1; total = total + n end
assert(distinct == 1 and total == 64,
  "visible material color must not invent checker/dither shades from the Johto donor histogram")
local fr, fg, fb = cleanOut:getPixel(0, 0)
assert(near(fr, 215/255) and near(fg, 35/255) and near(fb, 145/255),
  "flat source shade 3 must map directly to Johto slot-6 shade 3")

assert(Style.PROJECTION_REV == "g2-johto-colors-380-r1",
  "v0.3.80 must invalidate older projected geometry/color caches after the Kanto water-mesh fix")

print("kanto_johto_voxel_color_parity: OK")
