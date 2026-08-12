-- Gold/Silver party-slot-1 follower bridge.
--
-- Current Gen1Recomp already ships src.world.gen2.Follower: an engine-owned
-- trailing NPC/path history loop whose spawn gate is deliberately false until
-- a mod opts in through Follower.setShouldSpawn().  Use that native surface
-- instead of inventing another follower mover.  The visible entity is marked
-- with the live party lead so the Stadium voxel renderer can replace it with
-- the correct 3D model immediately after party reordering.
local V = ...
local mod = V.mod

local Bridge = {
  installed = false,
  spawned = false,
  lastSpecies = nil,
  lastError = nil,
}

local function optionEnabled()
  if not (mod and mod.options and type(mod.options.get) == "function") then
    return true
  end
  local ok, value = pcall(mod.options.get, mod.options, "partyFollower")
  if not ok or value == nil then return true end
  return value ~= false
end

local function leadMon(game)
  local save = game and game.save
  local party = save and save.party
  local mon = type(party) == "table" and party[1] or nil
  if type(mon) ~= "table" or mon.species == nil then return nil end
  local species = tostring(mon.species or "")
  if species == "" or species:upper() == "EGG" then return nil end
  return mon
end

local function normalWalkingState(world)
  if not world then return false end
  local ok, FieldMoves = pcall(require, "src.world.gen2.FieldMoves")
  if not ok or type(FieldMoves) ~= "table" then return true end
  if type(FieldMoves.isBiking) == "function" and FieldMoves.isBiking(world.playerState) then
    return false
  end
  if type(FieldMoves.isSurfing) == "function" and FieldMoves.isSurfing(world.playerState) then
    return false
  end
  return true
end

local function markFollower(game, world, Follower)
  if not (world and Follower and type(Follower.current) == "function") then
    return nil
  end
  local npc = Follower.current(world)
  local mon = leadMon(game)
  if not npc or not mon then return npc end

  -- Renderer-facing identity.  These are visual metadata only; the party Mon
  -- remains owned by Gold.  OverworldStadium also resolves the live party lead
  -- directly for pikachuFollower=true, so this is a redundant safety net.
  npc.pokepcMon = mon
  npc._pokepcFollowerSpecies = mon.species
  npc.pokepcFollowerSpecies = mon.species
  npc.pokemonSpecies = mon.species
  npc.wildsFollower = true
  npc.passable = true
  Bridge.spawned = true
  Bridge.lastSpecies = mon.species
  return npc
end

local function currentGame()
  local ok2, Game2 = pcall(require, "src.core.Game2")
  if ok2 and type(Game2) == "table" then return Game2 end
  return nil
end

function Bridge.install()
  if Bridge.installed then return true end
  local okFollower, Follower = pcall(require, "src.world.gen2.Follower")
  if not okFollower or type(Follower) ~= "table"
      or type(Follower.setShouldSpawn) ~= "function" then
    Bridge.lastError = "src.world.gen2.Follower.setShouldSpawn unavailable"
    return false, Bridge.lastError
  end

  Follower.setShouldSpawn(function(game, world)
    -- Keep metadata fresh on the same 60 Hz cadence the engine already uses
    -- for its follower trail.  Reordering the party therefore changes the 3D
    -- follower without a map reload.
    markFollower(game, world, Follower)
    return optionEnabled() and leadMon(game) ~= nil and normalWalkingState(world)
  end)

  -- World calls Follower.onMapEntered before emitting map.entered.  Mark the
  -- newly-created entity after that emission so its very first rendered frame
  -- already knows which party Pokemon it represents.
  if mod and mod.events and type(mod.events.on) == "function" then
    mod.events:on("map.entered", function()
      local game = currentGame()
      if game and game.world then pcall(markFollower, game, game.world, Follower) end
    end)
    mod.events:on("game.ready", function(game)
      local g = game or currentGame()
      if g and g.world then pcall(markFollower, g, g.world, Follower) end
    end)
    mod.events:on("mod.options_changed", function(payload)
      if not (payload and payload.mod == mod.id and payload.key == "partyFollower") then
        return
      end
      -- No manual spawn/despawn is necessary: Follower.update checks the gate
      -- every logic frame.  Just refresh identity if an entity already exists.
      local game = currentGame()
      if game and game.world then pcall(markFollower, game, game.world, Follower) end
    end)
  end

  Bridge.installed = true
  Bridge.lastError = nil
  return true
end

function Bridge.status()
  return {
    installed = Bridge.installed,
    enabled = optionEnabled(),
    spawned = Bridge.spawned,
    species = Bridge.lastSpecies,
    error = Bridge.lastError,
  }
end

return Bridge
