-- v0.3.57 regression: Pokemon Tower 5F purified-zone physical parity.
-- Self-contained: no ROM/GPU required.

package.preload["src.render.Assets"] = function() return {} end
_G.love = {
  math = { random = function(a) return a end },
  graphics = {
    setColor = function() end,
    rectangle = function() end,
  },
}

local shown = {}
local TextBox = {
  new = function(_, text, onDone)
    local box = { text = text, onDone = onDone }
    shown[#shown + 1] = tostring(text)
    return box
  end,
}

local backing = {}
local mod = {
  exports = {},
  options = { get = function() return nil end },
  ui = { TextBox = TextBox },
  save = {
    get = function(_, key, fallback)
      local v = backing[key]
      return v == nil and fallback or v
    end,
    set = function(_, key, value) backing[key] = value; return true end,
  },
}

local Tower = assert(loadfile("lib/KantoTower.lua"))()
local Spatial = assert(loadfile("lib/KantoSpatial.lua"))()
local stubs = {
  Quality = { kantoRadius = function() return 1 end,
              actorDistanceCells = function() return math.huge end },
  FirstPerson = { driving = function() return false end,
                  releaseBody = function() end },
  ChunkMesher = { refresh = function() end },
  KantoGen2Style = { PROJECTION_REV = "test" },
  KantoTower = Tower,
  KantoSpatial = Spatial,
  runtime_sheets = { new = function() return { load = function() return true end } end },
}
local V = { mod = mod, require = function(name) return stubs[name] or {} end }
local Twin = assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local e = Twin._excursionForTest

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected)
      .. ", got " .. tostring(actual), 2)
  end
end
local function check(v, label) if not v then error(label or "check failed", 2) end end

-- ---- 1. exact 2x2 coordinates -------------------------------------------
for _, cell in ipairs({ {10,8}, {11,8}, {10,9}, {11,9} }) do
  check(Tower.isPurifiedCell("POKEMON_TOWER_5F", cell[1], cell[2]),
    ("(%d,%d) is purified"):format(cell[1], cell[2]))
end
check(not Tower.isPurifiedCell("POKEMON_TOWER_5F", 9, 8), "left neighbor is not purified")
check(not Tower.isPurifiedCell("POKEMON_TOWER_5F", 10, 7), "upper neighbor is not purified")
check(not Tower.isPurifiedCell("POKEMON_TOWER_4F", 10, 8), "same coordinate on 4F is not purified")

-- ---- 2. enter/stay/leave/re-enter latch ---------------------------------
Tower.reset(e)
local on, entered, left = Tower.step(e, "POKEMON_TOWER_5F", 10, 8)
check(on and entered and not left, "first pad step enters")
check(e.towerPurifiedZone, "visit-local latch set")
on, entered, left = Tower.step(e, "POKEMON_TOWER_5F", 11, 9)
check(on and not entered and not left, "staying on pad is consumed without re-entry")
on, entered, left = Tower.step(e, "POKEMON_TOWER_5F", 12, 9)
check(not on and not entered and left, "stepping off clears latch")
check(not e.towerPurifiedZone, "latch cleared off pad")
on, entered = Tower.step(e, "POKEMON_TOWER_5F", 11, 8)
check(on and entered, "re-enter heals again")

-- ---- 3. Twin integration heals Gold once and suppresses pad landings -----
Tower.reset(e)
local heals = 0
local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end
local world = {
  healParty = function() heals = heals + 1; return true end,
  game = { save = { party = {} }, data = {}, stack = stack },
}
local region = { loaded = { text = {
  _PokemonTower5FPurifiedZoneText = "Entered purified,\nprotected zone!",
} } }
local before = Twin.yellowTowerPurifiedHeals or 0
check(Twin._handleTowerPurifiedZone(world, region, "POKEMON_TOWER_5F", 10, 8),
  "first purified landing is consumed")
eq(heals, 1, "Gold heal API called once on entry")
eq(Twin.yellowTowerPurifiedHeals, before + 1, "Tower heal diagnostic increments")
eq(#stack.states, 1, "white heal presentation queued")

check(Twin._handleTowerPurifiedZone(world, region, "POKEMON_TOWER_5F", 11, 8),
  "staying on purified zone remains encounter-blocking")
eq(heals, 1, "staying does not re-heal")
eq(#stack.states, 1, "staying does not queue another presentation")

check(not Twin._handleTowerPurifiedZone(world, region, "POKEMON_TOWER_5F", 12, 8),
  "leaving purified zone stops consuming landings")
check(not e.towerPurifiedZone, "Twin integration clears latch on leave")
check(Twin._handleTowerPurifiedZone(world, region, "POKEMON_TOWER_5F", 11, 9),
  "fresh re-entry is consumed")
eq(heals, 2, "fresh re-entry heals again")

-- ---- 4. presentation timing: 24 out + 6 hold + 24 in, then text ----------
-- Reset to one transition so we can assert the authored sequence cleanly.
stack.states = {}
shown = {}
Tower.reset(e)
check(Twin._handleTowerPurifiedZone(world, region, "POKEMON_TOWER_5F", 10, 9),
  "timing test starts presentation")
local fx = stack:top()
check(fx and type(fx.alpha) == "function" and type(fx.update) == "function",
  "white fade state exposes timing")
eq(fx:alpha(), 0, "fade starts at normal palette")
for _ = 1, 8 do fx:update(1/60) end
eq(fx:alpha(), 0.5, "first white fade step after 8 frames")
for _ = 1, 8 do fx:update(1/60) end
eq(fx:alpha(), 1, "screen reaches white by third palette hold")
for _ = 1, 14 do fx:update(1/60) end -- t=30: 24 out + Delay3x2
eq(fx:alpha(), 1, "two Delay3 holds keep screen white")
for _ = 1, 8 do fx:update(1/60) end
eq(fx:alpha(), 0.5, "fade-in staircase returns from white")
for _ = 1, 16 do fx:update(1/60) end -- total 54, pops + shows text
check(#shown == 1, "purified-zone text appears after white sequence")
eq(shown[1], "Entered purified,\nprotected zone!", "uses extracted Yellow text when available")
check(stack:top() and stack:top().text, "TextBox replaces completed white overlay")

print("kanto_tower_purified_zone_parity: OK")
