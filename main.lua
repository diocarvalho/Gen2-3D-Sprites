-- Pokemon Stadium 2 Overworld Models - Gold/Silver (Generation 2)
--
-- Standalone Gen1Recomp Gold/Gen-2 graphics/gameplay mod. It embeds the Gen2 Dramatic Shapes
-- voxel renderer and the Wilds of Kanto roaming-Pokemon runtime, but contains no
-- Pokemon Stadium 2 ROM or ROM-derived model data. Models are built locally
-- from the player's own compatible Stadium 2 ROM.
local mod = ...

-- This package has its own Gen2-only mod id. Keep a runtime generation guard
-- anyway so accidentally enabling it on Red/Blue/Yellow fails closed.
local function gameGeneration()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  if ok and type(GameVersion) == "table" then
    if type(GameVersion.generation) == "function" then
      local okGen, generation = pcall(GameVersion.generation)
      if okGen and tonumber(generation) then return tonumber(generation) end
    end
    if type(GameVersion.isGen2) == "function" then
      local okGen2, yes = pcall(GameVersion.isGen2)
      if okGen2 and yes then return 2 end
    end
  end
  return 1
end

local function isGen2()
  return gameGeneration() == 2
end

local detectedGeneration = gameGeneration()
if detectedGeneration == 2 then
  mod.log:info("Gold/Silver standalone build: Pokemon Generation 2 detected; Stadium 2 importer targets National Dex 1-251")
else
  mod.log:warn("STADIUM2_OVERWORLD_MODELS requires Pokemon Gold or Silver. Active game reports Pokemon Generation %s; this Gen 2 port will stay inactive.", tostring(detectedGeneration))
  mod.exports.version = "0.1.85"
  mod.exports.targetGeneration = 2
  mod.exports.generation = detectedGeneration
  mod.exports.gen2Compatible = true
  mod.exports.stadium2Importer = true
  mod.exports.standaloneRenderer = true
  mod.exports.maxDex = 251
  mod.exports.active = false
  mod.exports.rendererInstalled = false
  mod.exports.rendererError = "Pokemon Gold/Silver (Generation 2) must be the active game"
  return
end

-- Wilds of Kanto's embedded entry returns an installer factory instead of
-- executing directly.  Run it against THIS mod object, capture the child's
-- public surface, then restore this package's Stadium exports.  v0.1.74 keeps
-- this definition in the top-level entry: an earlier direct-world refactor
-- accidentally deleted it while leaving the call site behind, which made the
-- mod abort late in main.lua after its Options UI had already been registered.
local function bootEmbeddedWilds()
  local source, readErr = mod:read("lib/EmbeddedWildsMain.lua")
  if not source then return nil, tostring(readErr or "embedded Wilds runtime is missing") end
  local loadcode = loadstring or load
  local chunk, compileErr = loadcode(source, "@" .. mod.path .. "/lib/EmbeddedWildsMain.lua")
  if not chunk then return nil, tostring(compileErr) end

  local okFactory, factory = pcall(chunk)
  if not okFactory then return nil, tostring(factory) end
  if type(factory) ~= "function" then
    return nil, "embedded Wilds entry did not return its installer function"
  end

  mod.exports = mod.exports or {}
  local before = {}
  for k, v in pairs(mod.exports) do before[k] = v end

  local okRun, runErr = pcall(factory, mod)
  if not okRun then
    for k in pairs(mod.exports) do mod.exports[k] = nil end
    for k, v in pairs(before) do mod.exports[k] = v end
    return nil, tostring(runErr)
  end

  local wilds = {}
  for k, v in pairs(mod.exports) do
    if before[k] ~= v then wilds[k] = v end
  end

  for k in pairs(mod.exports) do mod.exports[k] = nil end
  for k, v in pairs(before) do mod.exports[k] = v end

  if type(wilds.logic) ~= "table" or type(wilds.render) ~= "table" then
    return nil, "embedded Wilds runtime did not expose spawn logic/render services"
  end
  return wilds
end

-- Gold/Silver renderer bootstrap (v0.1.85)
--
-- Current Gold exposes a supported whole-window `render.compose` hook.  The
-- embedded voxel bridge is now a renderer PROVIDER only; it does not patch any
-- Gen-2 World method and does not register the inert Gen-1 drawWorld pipeline.
-- GoldComposeBridge invokes it from the live Gold frame seam later below.
local function bootGoldVoxelBridge()
  local source, readErr = mod:read("lib/GoldVoxelBridge.lua")
  if not source then return nil, nil, tostring(readErr or "Gold voxel bridge is missing") end
  local chunk, compileErr = load(source, "@" .. mod.path .. "/lib/GoldVoxelBridge.lua")
  if not chunk then return nil, nil, tostring(compileErr) end
  local okLoad, Bridge = pcall(chunk, mod)
  if not okLoad then return nil, nil, tostring(Bridge) end
  if type(Bridge) ~= "table" or type(Bridge.install) ~= "function" then
    return nil, nil, "Gold voxel bridge did not expose install()"
  end
  local okInstall, installed, libOrErr = pcall(Bridge.install)
  if not okInstall then return nil, nil, tostring(installed) end
  if not installed then return nil, nil, tostring(libOrErr or "Gold voxel bridge install failed") end
  local lib = libOrErr or Bridge.lib
  if type(lib) ~= "table" or type(lib.require) ~= "function" then
    return nil, nil, "Gold voxel bridge did not expose its renderer module loader"
  end
  return Bridge, lib
end

local GoldVoxelBridge, BaseV, bridgeErr = bootGoldVoxelBridge()
local ds, dramaticShapeId
if GoldVoxelBridge and BaseV then
  ds = mod
  dramaticShapeId = "STADIUM2_GOLD_COMPOSE"
  mod.log:info("Gold/Silver voxel renderer provider loaded; official render.compose hook will own Gold world frames and redraw overlay UI above voxels")
else
  mod.log:error("Gold/Silver voxel renderer provider failed: %s", tostring(bridgeErr))
  mod.exports.version = "0.1.85"
  mod.exports.rendererInstalled = false
  mod.exports.rendererError = "Gold/Silver voxel renderer provider failed: " .. tostring(bridgeErr)
  mod.exports.hostDetected = false
  mod.exports.generation = gameGeneration()
  mod.exports.gen2Compatible = true
  mod.exports.targetGeneration = 2
  mod.exports.stadium2Importer = true
  mod.exports.standaloneRenderer = true
  mod.exports.maxDex = 251
  return
end

-- Followers EX owns its own pack / controlled-Pokemon follower lifecycle.
-- When present, we consume its entity metadata but do not alter Yellow's stock
-- follower spawning rules.
local FollowersEX = mod.find("FOLLOWERS_EX")


-- Followers EX already owns a FOLLOWERS 0-6 option. Older compatibility
-- builds forced save.pokepcFollowerCount=6 every sync, which made its own UI
-- appear broken. v0.1.37 respects Followers EX by default and only overrides
-- the count when this mod's FOLLOWER COUNT option is explicitly set to 0-6.
local function stadiumFollowerOverride()
  local ok, value = pcall(mod.options.get, mod.options, "followersExCount")
  if not ok or value == nil or value == "followers_ex" then return nil end
  local n = tonumber(value)
  if not n then return nil end
  return math.max(0, math.min(6, math.floor(n)))
end

local function followersExSavedOption(game)
  local function fromRoot(root)
    local mods = root and root.modOptions
    local fx = mods and mods.FOLLOWERS_EX
    local n = fx and tonumber(fx.follower_count)
    if n then return math.max(0, math.min(6, math.floor(n))) end
  end
  local save = game and game.save
  local n = fromRoot(save and save.options)
  if n ~= nil then return n end
  n = fromRoot(game and game.mods)
  if n ~= nil then return n end
  return nil
end

local function desiredFollowersExCount(game)
  local forced = stadiumFollowerOverride()
  if forced ~= nil then return forced end

  -- Prefer Followers EX's persisted UI value. This also repairs saves that an
  -- older Stadium build temporarily stamped to 6 in pokepcFollowerCount.
  local saved = followersExSavedOption(game)
  if saved ~= nil then return saved end

  local live = game and game.save and tonumber(game.save.pokepcFollowerCount)
  if live ~= nil then return math.max(0, math.min(6, math.floor(live))) end
  return 1
end

local function syncFollowersExCount(game)
  local fx = mod.find("FOLLOWERS_EX")
  if not fx then return false end
  local g = game
  if not g then
    local ok, Game = pcall(require, "src.core.Game")
    if ok then g = Game end
  end
  if not (g and g.save) then return false end

  local n = desiredFollowersExCount(g)
  g.save.pokepcFollowerCount = n

  local ex = fx.exports or {}
  if type(ex.setFollowerCount) == "function" then
    pcall(ex.setFollowerCount, g, n)
  end
  return true
end

local function loadLocal(rel, arg)
  local source, readErr = mod:read(rel)
  assert(source, ("STADIUM2_OVERWORLD_MODELS: missing %s: %s")
    :format(rel, tostring(readErr)))
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  assert(chunk, ("STADIUM2_OVERWORLD_MODELS: %s did not compile: %s")
    :format(rel, tostring(err)))
  return chunk(arg)
end

-- Load our configuration first, then make a tiny namespace that delegates all
-- Dramatic Shape modules to Dramatic Shape while intercepting our own config.
local Config = loadLocal("lib/OverworldStadiumConfig.lua", BaseV)
local PokemonHeights = loadLocal("lib/PokemonHeights.lua", BaseV)
local PokemonLocomotion = loadLocal("lib/PokemonLocomotion.lua", BaseV)

-- Put Stadium ROM selection inside THIS MOD'S Mod Manager -> Options screen.
-- The manifest also ships options.lua so the recomp mod manager exposes an OPTIONS button
-- for this mod.  StadiumRomMenu converts the STADIUM ROM FILE row into a real
-- Android file-picker action (A/Confirm, Left, or Right all open the system Files picker).
local RomMenuV = { require = BaseV.require }
local StadiumRomMenu = loadLocal("lib/StadiumRomMenu.lua", RomMenuV)
local managerOptionsInstalled = StadiumRomMenu.installModManagerOptions(mod)

-- Compatibility fallback only for much older builds without per-mod options.
-- On current builds this never runs, so the ROM row lives only under this
-- mod's own Options screen rather than the game's general OPTIONS menu.
if not managerOptionsInstalled then
  StadiumRomMenu.installOptionsHook(mod)
end

-- Gold voxel renderer status.  The `voxel3d` option is read inside
-- GoldVoxelBridge.renderFrame() on every compose frame; no engine class is
-- monkey-patched and src.render.Pipelines is untouched.
local voxelPipelineState = GoldVoxelBridge

-- Android may recreate the app while the native document picker is open.
-- Finish a pending Stadium selection as soon as the live Gold service owner is
-- ready.  Rendering itself is installed later through mod.hooks:wrap.
mod.events:on("game.ready", function(game)
  pcall(StadiumRomMenu.poll, game)
end)

mod.events:on("map.entered", function()
  if GoldVoxelBridge then GoldVoxelBridge.mapId = nil end
end)

-- Yellow's stock follower controller normally exists only while a healthy
-- Pikachu is somewhere in the party. For this add-on the entity is our
-- generic first-party follower, so keep the STOCK controller/pathing alive
-- whenever party slot #1 exists. We do this without replacing its movement
-- code: during only the controller's private spawn check we expose a temporary
-- healthy Pikachu proxy. Bike/surf/event gates are still enforced by Yellow.
local function installFirstPartyFollowerSpawnPatch()
  -- This is specifically a Pokemon Yellow compatibility shim. Gold/Silver do
  -- not use Yellow's Pikachu follower spawn rule, so touching that controller
  -- in Gen 2 would be both unnecessary and unsafe.
  if isGen2() then return end
  if not Config.firstPartyFollower then return end

  local ok, Follower = pcall(require, "src.world.PikachuFollower")
  if not ok or type(Follower) ~= "table" then return end
  if Follower._stadiumFirstPartyPatched then return end

  local originalEnter = Follower.onMapEntered
  local originalUpdate = Follower.update
  if type(originalEnter) ~= "function" or type(originalUpdate) ~= "function" then
    return
  end

  local function needsProxy(game)
    local save = game and game.save
    local party = save and save.party
    local lead = type(party) == "table" and party[1] or nil
    if type(lead) ~= "table" or lead.species == nil then return false end

    -- When a healthy real Pikachu is present, Yellow's own check already
    -- passes and no temporary party entry is needed.
    for _, mon in ipairs(party) do
      if type(mon) == "table" and mon.species == "PIKACHU"
          and (mon.hp or 0) > 0 then
        return false
      end
    end
    return true
  end

  local function callWithSpawnProxy(game, fn, ...)
    if not needsProxy(game) then return fn(...) end
    local party = game.save.party
    local proxy = { species = "PIKACHU", hp = 1, _stadiumFollowerProxy = true }
    party[#party + 1] = proxy

    local result = { pcall(fn, ...) }
    -- Remove by identity in case another callback touched party order.
    for i = #party, 1, -1 do
      if party[i] == proxy then
        table.remove(party, i)
        break
      end
    end

    if not result[1] then error(result[2], 0) end
    return result[2], result[3], result[4], result[5]
  end

  Follower.onMapEntered = function(game, ow, opts, viaMapLoad)
    return callWithSpawnProxy(game, originalEnter, game, ow, opts, viaMapLoad)
  end
  Follower.update = function(game, ow)
    return callWithSpawnProxy(game, originalUpdate, game, ow)
  end
  Follower._stadiumFirstPartyPatched = true
end

if FollowersEX then
  mod.log:info("Followers EX detected; respecting configured follower count")
  pcall(syncFollowersExCount)

  -- Followers EX 1.0.19 intentionally filters its trailer roster to mons with
  -- hp > 0. For Stadium visual compatibility the user expects every occupied
  -- party slot to remain visible, even when a mon is fainted. Wrap the already-
  -- installed Followers EX PikachuFollower.update and temporarily expose 1 HP
  -- only while its private syncTrailers() builds/updates the follower entities.
  -- The real HP values are restored before this wrapper returns, so battle/save
  -- state is never healed or modified by the graphics compatibility layer.
  local function installFollowersExAllPartyVisualPatch()
    local okFollower, Follower = pcall(require, "src.world.PikachuFollower")
    if not okFollower or type(Follower) ~= "table"
        or type(Follower.update) ~= "function" then
      return false
    end
    if Follower._stadiumFollowersExAllPartyPatched then return true end

    local previousUpdate = Follower.update

    local function withVisualHp(game, fn, ...)
      local party = game and game.save and game.save.party
      if type(party) ~= "table" then return fn(...) end

      local savedHp = {}
      for i, mon in ipairs(party) do
        if type(mon) == "table" and mon.species ~= nil then
          savedHp[i] = { had = mon.hp ~= nil, value = mon.hp }
          if tonumber(mon.hp) == nil or tonumber(mon.hp) <= 0 then
            mon.hp = 1
          end
        end
      end

      local result = { pcall(fn, ...) }
      for i, old in pairs(savedHp) do
        local mon = party[i]
        if type(mon) == "table" then
          if old.had then mon.hp = old.value else mon.hp = nil end
        end
      end

      if not result[1] then error(result[2], 0) end
      return result[2], result[3], result[4], result[5], result[6]
    end

    Follower.update = function(game, ow, ...)
      -- Synchronize the selected count before Followers EX rebuilds its roster.
      -- By default this mirrors Followers EX rather than forcing six.
      pcall(syncFollowersExCount, game)
      return withVisualHp(game, previousUpdate, game, ow, ...)
    end
    Follower._stadiumFollowersExAllPartyPatched = true
    return true
  end

  pcall(installFollowersExAllPartyVisualPatch)
  mod.events:on("game.ready", function(game)
    pcall(syncFollowersExCount, game)
    pcall(installFollowersExAllPartyVisualPatch)
  end)
  mod.events:on("map.entered", function()
    local ok, Game = pcall(require, "src.core.Game")
    if ok then pcall(syncFollowersExCount, Game) end
    pcall(installFollowersExAllPartyVisualPatch)
  end)
  mod.events:on("mod.options_changed", function(payload)
    if not (payload and payload.mod == mod.id
        and payload.key == "followersExCount") then return end
    local ok, Game = pcall(require, "src.core.Game")
    if ok then pcall(syncFollowersExCount, Game) end
    local fx = mod.find("FOLLOWERS_EX")
    local ex = fx and fx.exports
    if ok and ex and type(ex.syncAll) == "function" then
      pcall(ex.syncAll, Game, Game and Game.overworld)
    end
  end)
else
  if isGen2() then
    mod.log:info("Gold/Silver detected; Yellow stock-follower patch disabled (Followers EX remains optional)")
  else
    installFirstPartyFollowerSpawnPatch()
  end
end

-- Dramatic Sky Ride compatibility ------------------------------------------------
-- DSR intentionally removes every follower entity while airborne and swaps the
-- player's pose to a generated 2D SKY_RIDE_<SPECIES> mount sheet. Stadium's
-- VoxelScene bridge handles that mount sheet as a Pokemon model; this wrapper
-- restores Followers EX's live follower objects AFTER DSR performs its purge.
local SkyRide = mod.find("DRAMATIC_SKY_RIDE")
local skyFollowerCache = { mapId = nil, entities = {} }

local function skyRideFlying()
  local h = mod.find("DRAMATIC_SKY_RIDE") or SkyRide
  local ex = h and h.exports
  if not (ex and type(ex.isFlying) == "function") then return false end
  local ok, value = pcall(ex.isFlying)
  return ok and value == true
end

local function skyRideAltitude()
  local h = mod.find("DRAMATIC_SKY_RIDE") or SkyRide
  local ex = h and h.exports
  if ex and type(ex.currentAltitude) == "function" then
    local ok, value = pcall(ex.currentAltitude)
    if ok then return tonumber(value) end
  end
  if ex and type(ex.altitude) == "function" then
    local ok, value = pcall(ex.altitude)
    if ok then return tonumber(value) end
  end
  return nil
end

local function skyRideLift()
  local h = mod.find("DRAMATIC_SKY_RIDE") or SkyRide
  local ex = h and h.exports
  if ex and type(ex.currentLift) == "function" then
    local ok, value = pcall(ex.currentLift)
    if ok then return tonumber(value) end
  end
  return nil
end

local function skyRideMountSpecies()
  local h = mod.find("DRAMATIC_SKY_RIDE") or SkyRide
  local ex = h and h.exports
  if ex and type(ex.mountSpecies) == "function" then
    local ok, value = pcall(ex.mountSpecies)
    if ok and value ~= nil then return tostring(value):upper() end
  end
  return nil
end

local function followerSpeciesName(e)
  if type(e) ~= "table" then return nil end
  local mon = e.pokepcMon
  local value = (type(mon) == "table" and (mon.species or mon.pokemonSpecies))
      or e._pokepcFollowerSpecies or e.pokepcFollowerSpecies
      or e._wildsFollowerSpecies or e.pokemonSpecies or e.stadiumSpecies
  if value ~= nil then return tostring(value):upper() end
  if e.pikachuFollower == true then return "PIKACHU" end
  local def = e.sprite and e.sprite.def
  local sid = tostring(e.spriteId or (def and def.id) or ""):upper()
  if sid == "SPRITE_PIKACHU" then return "PIKACHU" end
  local image = def and def.image
  if type(image) == "string" then
    local base = image:gsub("\\", "/"):match("([^/]+)$") or image
    base = base:gsub("%.[^%.]+$", "")
               :gsub("^[Ff][Oo][Ll][Ll][Oo][Ww][Ee][Rr][_-]", "")
               :gsub("^[Pp][Oo][Kk][Ee][Pp][Cc][_-]", "")
    if base ~= "" then return base:upper() end
  end
  return nil
end

local function isCompatFollower(e, player)
  if type(e) ~= "table" or e == player then return false end
  local id = tostring(e.id or ""):lower()
  local def = e.sprite and e.sprite.def
  local sid = tostring(e.spriteId or (def and def.id) or ""):upper()
  return e.pikachuFollower == true or e.pokepcTrailer == true
      or e.pokepcMon ~= nil or e._pokepcFollowerSpecies ~= nil
      or id:find("pokepc", 1, true) ~= nil
      or sid == "SPRITE_PIKACHU" or sid:find("POKEPC", 1, true) ~= nil
end

local function cacheFollowers(ow)
  if not (ow and ow.map) then return end
  local seen, out = {}, {}
  for _, list in ipairs({ ow.entities or {}, ow.npcs or {} }) do
    for _, e in ipairs(list) do
      if isCompatFollower(e, ow.player) and not seen[e] then
        seen[e] = true
        out[#out + 1] = e
      end
    end
  end
  if #out > 0 then
    skyFollowerCache.mapId = ow.map.id
    skyFollowerCache.entities = out
  end
end

local function containsIdentity(list, value)
  for _, v in ipairs(list or {}) do if v == value then return true end end
  return false
end

local function rebuildFollowerCache(ow)
  local fx = mod.find("FOLLOWERS_EX")
  local ex = fx and fx.exports
  if ex and type(ex.syncTrailers) == "function" then
    pcall(ex.syncTrailers, Game, ow, { mapEnter = true, catchUp = true })
  elseif ex and type(ex.syncAll) == "function" then
    pcall(ex.syncAll, Game, ow)
  end
  local okPika, Pika = pcall(require, "src.world.PikachuFollower")
  if okPika and Pika and type(Pika.onMapEntered) == "function" then
    pcall(Pika.onMapEntered, Game, ow, {})
  end
  cacheFollowers(ow)
end

local function restoreSkyFollowers(ow)
  if not (ow and ow.map) then return end
  if skyFollowerCache.mapId ~= ow.map.id or #skyFollowerCache.entities == 0 then
    rebuildFollowerCache(ow)
  end

  local altitude = skyRideAltitude()
  local relativeLift = skyRideLift()
  local mountSpecies = skyRideMountSpecies()
  local mountEntity = nil

  -- Prefer the existing follower whose Pokemon identity matches the active
  -- Sky Ride mount. That exact entity becomes the one 3D mount -- no proxy and
  -- no player-as-Pokemon conversion.
  if mountSpecies then
    for _, e in ipairs(skyFollowerCache.entities or {}) do
      if followerSpeciesName(e) == mountSpecies then
        mountEntity = e
        break
      end
    end
  end

  local trailing = 0
  for _, e in ipairs(skyFollowerCache.entities or {}) do
    if type(e) == "table" then
      if altitude then
        if e == mountEntity then
          -- Mark exactly one existing Followers EX Pokemon as the active Sky
          -- Ride mount.  IMPORTANT: do not move the actual follower NPC here;
          -- Followers EX owns that entity's trail state and needs it intact for
          -- landing.  Instead publish a render-only anchor at the live player
          -- position. OverworldStadium consumes these fields when building the
          -- Stadium model matrix, so the mount is under the rider rather than
          -- one trail slot behind them.
          e._stadiumSkyRideMount = true
          e._stadiumSkyRideAltitude = altitude
          e._stadiumSkyRideLift = relativeLift
          if ow.player then
            e._stadiumSkyRideAnchorPx = ow.player.px
            e._stadiumSkyRideAnchorPy = ow.player.py
            e._stadiumSkyRideAnchorFacing = ow.player.facing
            e._stadiumSkyRideAnchorCellX = ow.player.cellX
            e._stadiumSkyRideAnchorCellY = ow.player.cellY
          end
          if altitude and relativeLift then
            e._stadiumSkyRideGround = altitude - relativeLift
          else
            e._stadiumSkyRideGround = nil
          end
        else
          e._stadiumSkyRideMount = nil
          e._stadiumSkyRideAnchorPx = nil
          e._stadiumSkyRideAnchorPy = nil
          e._stadiumSkyRideAnchorFacing = nil
          e._stadiumSkyRideAnchorCellX = nil
          e._stadiumSkyRideAnchorCellY = nil
          e._stadiumSkyRideGround = nil
          trailing = trailing + 1
          e._stadiumSkyRideAltitude = altitude - math.min(5, trailing * 0.55)
          e._stadiumSkyRideLift = relativeLift and math.max(0, relativeLift - math.min(5, trailing * 0.55)) or nil
        end
      else
        e._stadiumSkyRideMount = nil
      end
      if not containsIdentity(ow.entities, e) then table.insert(ow.entities, e) end
      if not containsIdentity(ow.npcs, e) then table.insert(ow.npcs, e) end
    end
  end
end

local function clearSkyFollowerAltitude()
  for _, e in ipairs(skyFollowerCache.entities or {}) do
    if type(e) == "table" then
      e._stadiumSkyRideAltitude = nil
      e._stadiumSkyRideLift = nil
      e._stadiumSkyRideMount = nil
      e._stadiumSkyRideAnchorPx = nil
      e._stadiumSkyRideAnchorPy = nil
      e._stadiumSkyRideAnchorFacing = nil
      e._stadiumSkyRideAnchorCellX = nil
      e._stadiumSkyRideAnchorCellY = nil
      e._stadiumSkyRideGround = nil
    end
  end
end

local function installSkyRideFollowerCompat()
  if not mod.find("DRAMATIC_SKY_RIDE") then return false end
  local okState, OverworldState = pcall(require, "src.world.OverworldState")
  if not okState or type(OverworldState) ~= "table"
      or type(OverworldState.update) ~= "function" then return false end
  if OverworldState._stadiumSkyRideFollowersPatched then return true end
  local innerUpdate = OverworldState.update
  OverworldState.update = function(self, dt, ...)
    if not skyRideFlying() then cacheFollowers(self) end
    local result = { pcall(innerUpdate, self, dt, ...) }
    if not result[1] then error(result[2], 0) end
    if skyRideFlying() and Game.overworld == self then
      restoreSkyFollowers(self)
    else
      clearSkyFollowerAltitude()
      cacheFollowers(self)
    end
    return result[2], result[3], result[4], result[5]
  end
  OverworldState._stadiumSkyRideFollowersPatched = true
  return true
end

if SkyRide then
  mod.log:info("Dramatic Sky Ride detected; enabling Stadium mount + airborne follower compatibility")
  mod.events:on("game.ready", function() pcall(installSkyRideFollowerCompat) end)
  mod.events:on("map.entered", function() pcall(installSkyRideFollowerCompat) end)
end

local V = {
  mod = mod,
  path = mod.path,
  voxelHostId = dramaticShapeId,
}
setmetatable(V, { __index = BaseV })
function V.require(name)
  if name == "OverworldStadiumConfig" then return Config end
  if name == "PokemonHeights" then return PokemonHeights end
  if name == "PokemonLocomotion" then return PokemonLocomotion end
  return BaseV.require(name)
end

local Stadium = loadLocal("lib/OverworldStadium.lua", V)
V.OverworldStadium = Stadium

-- Stage 1 battle performances: exact Stadium move animations when available,
-- entrance/faint animation, and a short victim recoil without touching damage
-- calculations or the engine's own move-effect graphics.
local BattleStadiumAnimations = loadLocal("lib/BattleStadiumAnimations.lua", V)
local battleAnimationsInstalled, battleAnimationsErr = BattleStadiumAnimations.install()
if battleAnimationsInstalled then
  mod.log:info("Pokemon Stadium Stage 1 battle performances enabled")
else
  mod.log:warn("Pokemon Stadium Stage 1 battle performances not installed: %s",
               tostring(battleAnimationsErr))
end

-- Phase 2 + Phase 3 + Phase 4 battle effects: common elemental families, dedicated
-- signature-move renderers, and safe visual hit-stop/shake/impact polish
-- drawn on the recomp engine's own move-animation layer. Dramatic Shape already maps
-- that layer onto the 3D arena, so this does not touch battle model lifecycle.
local BattleStadiumEffects = loadLocal("lib/BattleStadiumEffects.lua", V)
local battleEffectsInstalled, battleEffectsErr = BattleStadiumEffects.install()
if battleEffectsInstalled then
  mod.log:info("Pokemon Stadium Phase 2 + Phase 3 + Phase 4 battle presentation enabled")
else
  mod.log:warn("Pokemon Stadium Phase 2 + Phase 3 + Phase 4 battle presentation not installed: %s",
               tostring(battleEffectsErr))
end

-- Phase 5: real world-space procedural effects. This wraps Dramatic Shape's
-- exported Stadium begin/update/draw functions, so the particles are drawn
-- inside the active Voxel3D scene and follow camera orbit/depth naturally.
local BattleStadium3DFx = loadLocal("lib/BattleStadium3DFx.lua", V)
local battle3DInstalled, battle3DErr = BattleStadium3DFx.install()
if battle3DInstalled then
  mod.log:info("Pokemon Stadium Phase 5 world-space battle effects enabled")
else
  mod.log:warn("Pokemon Stadium Phase 5 world-space effects not installed: %s", tostring(battle3DErr))
end

-- Patch only structural seams in the exact VoxelScene source from the installed
-- Dramatic Shape build. Stadium operations are isolated per Pokemon, so one
-- bad model falls back to its own sprite without disabling the full overlay.
local VoxelScenePatch = loadLocal("lib/VoxelScenePatch.lua", V)
local rendererInstalled, rendererErr = VoxelScenePatch.install(ds, BaseV, V, Stadium)
if rendererInstalled then
  mod.log:info("Pokemon Stadium overworld renderer installed on current Dramatic Shape VoxelScene")
else
  mod.log:warn("Stadium overworld renderer not installed; Dramatic Shape voxel renderer preserved: %s",
               tostring(rendererErr))
end

-- Standalone roaming Pokemon.  Always boot the embedded, Gen-2-patched Wilds
-- runtime.  Do not let a separately installed Gen-1 Wilds build hijack this
-- package: independence means Gold uses the copy that was actually ported for
-- morning/day/night encounters and the Gen-2 world facade.
local wildsExports, wildsSource, wildsErr
wildsExports, wildsErr = bootEmbeddedWilds()
if wildsExports then
  wildsSource = "embedded"
  mod.log:info("Embedded Wilds of Kanto 1.12.2 Gen-2 roaming spawn runtime enabled")
else
  wildsSource = "failed"
  mod.log:warn("Embedded Wilds roaming spawn runtime failed; Stadium renderer remains available: %s",
               tostring(wildsErr))
end

-- Visible roaming Pokemon provider/fallback drawer.  This no longer patches
-- World:drawPeople; it stays independent from voxel and is consumed by the
-- supported Gold render.compose bridge below.
local GoldWildsBridge, goldWildsBridgeErr
if wildsExports then
  local source, readErr = mod:read("lib/GoldWildsBridge.lua")
  if source then
    local loadcode = loadstring or load
    local chunk, compileErr = loadcode(source,
      "@" .. mod.path .. "/lib/GoldWildsBridge.lua")
    if chunk then
      local okLoad, bridgeOrErr = pcall(chunk, mod, wildsExports)
      if okLoad and type(bridgeOrErr) == "table" then
        GoldWildsBridge = bridgeOrErr
        local okInstall, installErr = GoldWildsBridge.install()
        if not okInstall then
          goldWildsBridgeErr = tostring(installErr)
          GoldWildsBridge = nil
        end
      else
        goldWildsBridgeErr = tostring(bridgeOrErr)
      end
    else
      goldWildsBridgeErr = tostring(compileErr)
    end
  else
    goldWildsBridgeErr = tostring(readErr)
  end
  if GoldWildsBridge then
    mod.log:info("Gold visible-Wilds provider/fallback renderer ready")
  else
    mod.log:warn("Gold visible-Wilds provider failed: %s",
                 tostring(goldWildsBridgeErr))
  end
end

-- Feed the same visible roaming-Pokemon set into the voxel scene.  The Stadium
-- VoxelScene overlay can then replace those entities with their imported
-- Stadium 2 models; if voxel fails, GoldComposeBridge still draws their sprites.
if GoldVoxelBridge and GoldWildsBridge
   and type(GoldVoxelBridge.setExtraEntitiesProvider) == "function"
   and type(GoldWildsBridge.visibleEntities) == "function" then
  local okProvider, providerErr = GoldVoxelBridge.setExtraEntitiesProvider(function(world)
    return GoldWildsBridge.visibleEntities(world)
  end)
  if okProvider then
    mod.log:info("Gold visible-Wilds entities bridged into voxel/Stadium scene")
  else
    mod.log:warn("Gold Wilds voxel entity bridge failed: %s", tostring(providerErr))
  end
end

-- Official Gold frame hook.  This is the first v0.1.74 path that does NOT rely
-- on a Gen-1 pipeline or a Gen-2 class mutation.  Voxel gets first chance on a
-- free-roam frame.  When it is unavailable/pending/broken, the already-drawn
-- Gold scene is preserved and visible Wilds sprites are overlaid independently.
local GoldComposeBridge, goldComposeBridgeErr
do
  local source, readErr = mod:read("lib/GoldComposeBridge.lua")
  if source then
    local loadcode = loadstring or load
    local chunk, compileErr = loadcode(source,
      "@" .. mod.path .. "/lib/GoldComposeBridge.lua")
    if chunk then
      local okLoad, bridgeOrErr = pcall(chunk, mod, GoldVoxelBridge, GoldWildsBridge)
      if okLoad and type(bridgeOrErr) == "table" then
        GoldComposeBridge = bridgeOrErr
        local okInstall, installErr = GoldComposeBridge.install()
        if not okInstall then
          goldComposeBridgeErr = tostring(installErr)
          GoldComposeBridge = nil
        end
      else
        goldComposeBridgeErr = tostring(bridgeOrErr)
      end
    else
      goldComposeBridgeErr = tostring(compileErr)
    end
  else
    goldComposeBridgeErr = tostring(readErr)
  end
end
if GoldComposeBridge then
  mod.log:info("Gold render.compose integration enabled")
else
  mod.log:error("Gold render.compose integration failed: %s",
                tostring(goldComposeBridgeErr))
end

-- `game.ready` happens before a new Gold World necessarily exists, while
-- `map.entered` happens after the live map/people are built.  The embedded
-- Wilds event listener normally initializes there, but this idempotent repair
-- makes a current map visible even if event ordering differs across builds or
-- after a save reload.
local function ensureWildsCurrentMap(ev)
  if not (wildsExports and type(wildsExports.logic) == "table") then return end
  local worldApi = mod.world
  local ow = worldApi and worldApi.overworld and worldApi:overworld()
  local map = ow and ow.map
  local mapId = (ev and ev.mapId) or (map and map.id)
  if not mapId then return end

  local logic = wildsExports.logic
  local initialized = logic.state and logic.state.initialized == true
  if logic.activeMapId == mapId and initialized then return end
  if type(logic.onMapEntered) ~= "function" then return end

  local ok, err = pcall(logic.onMapEntered, logic, {
    mapId = mapId, map = map, via = "stadium2_gen2_bootstrap",
  })
  if not ok then
    mod.log:warn("Gold visible-Wilds map bootstrap failed: %s", tostring(err))
  end
end

mod.events:on("map.entered", ensureWildsCurrentMap)
mod.events:on("save.loaded", ensureWildsCurrentMap)
mod.events:on("game.ready", ensureWildsCurrentMap)
pcall(ensureWildsCurrentMap)

-- Gold/Silver can change land encounter slots with time of day. Rebuild the
-- embedded Wilds population when the engine announces a TOD transition so the
-- visible roster stays in lockstep with vanilla encounters.
if wildsExports and type(wildsExports.logic) == "table" then
  mod.events:on("world.tod_changed", function(ev)
    local logic = wildsExports.logic
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    local mapId = (ev and ev.mapId) or (ow and ow.map and ow.map.id)
    if mapId and logic.activeMapId == mapId
       and type(logic.onMapReloaded) == "function" then
      local okReload, reloadErr = pcall(logic.onMapReloaded, logic, { mapId = mapId })
      if not okReload then
        mod.log:warn("Wilds time-of-day refresh failed: %s", tostring(reloadErr))
      end
    end
  end)
end

-- Companion mods can tag a Pokemon entity explicitly through this mod.
mod.exports.version = "0.1.85"
mod.exports.overworld = Stadium
mod.exports.red3dPlayerCompat = true
mod.exports.red3dPlayerCompatStatus = function()
  local selector = mod.find and mod.find("red_3d_player") or nil
  local okPlayer, Player = pcall(require, "src.world.gen2.Player")
  local renderer = okPlayer and type(Player) == "table" and Player.red3dPlayerRenderer or nil
  return {
    selectorDetected = selector ~= nil,
    rendererReady = type(renderer) == "table" and type(renderer.drawVoxel) == "function",
    activeId = type(renderer) == "table" and renderer.activeId or nil,
  }
end
mod.exports.romMenu = StadiumRomMenu
mod.exports.chooseStadiumRom = function(game)
  if game then return StadiumRomMenu.choose(game) end
  local okGame2, Game2 = pcall(require, "src.core.Game2")
  return StadiumRomMenu.choose(okGame2 and Game2 or nil)
end
mod.exports.tag = function(entity, speciesOrDex)
  return Stadium.tag(entity, speciesOrDex)
end
mod.exports.untag = function(entity)
  return Stadium.untag(entity)
end

mod.exports.active = true
mod.exports.hostDetected = true
mod.exports.hostId = dramaticShapeId
mod.exports.generation = gameGeneration()
mod.exports.gen2Compatible = true
mod.exports.targetGeneration = 2
mod.exports.stadium2Importer = true
mod.exports.standaloneRenderer = true
mod.exports.maxDex = 251
mod.exports.rendererInstalled = rendererInstalled
mod.exports.rendererError = rendererErr
mod.exports.voxelHostId = dramaticShapeId
mod.exports.voxelHostGeneration = 2
mod.exports.voxelPipelineState = voxelPipelineState
mod.exports.voxelDirectWorldHook = false
mod.exports.voxelComposeHook = GoldComposeBridge ~= nil
-- Legacy default target remains FULL/diorama level 1. v0.1.85 can select the
-- live first/third-person levels through GoldVoxelBridge without changing this
-- compatibility value expected by older diagnostics.
mod.exports.voxelTargetLevel = 1
mod.exports.voxelStatus = function()
  return GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
end
mod.exports.voxelCameraMode = function()
  local status = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  return status and status.cameraMode or "diorama"
end
mod.exports.voxelCameraLevel = function()
  local status = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  return status and status.cameraLevel or 1
end
mod.exports.cycleVoxelCamera = function()
  if GoldVoxelBridge and type(GoldVoxelBridge.cycleCameraMode) == "function" then
    return GoldVoxelBridge.cycleCameraMode(true)
  end
  return nil
end
mod.exports.inWorld3DBattles = true
mod.exports.inWorld3DBattleStatus = function()
  local voxel = GoldVoxelBridge and GoldVoxelBridge.status and GoldVoxelBridge.status() or nil
  local compose = GoldComposeBridge and GoldComposeBridge.status and GoldComposeBridge.status() or nil
  return {
    installed = voxel and voxel.battleInstalled or false,
    active = voxel and voxel.battleActive or false,
    error = (voxel and voxel.battleError) or (compose and compose.lastBattleError) or nil,
    frames = compose and compose.battleFrames or 0,
    fallbacks = compose and compose.battleFallbackFrames or 0,
  }
end
mod.exports.battleAnimationsInstalled = battleAnimationsInstalled
mod.exports.battleAnimationsError = battleAnimationsErr
mod.exports.battleEffectsInstalled = battleEffectsInstalled
mod.exports.battleEffectsError = battleEffectsErr

mod.exports.battle3DInstalled = battle3DInstalled
mod.exports.battle3DError = battle3DErr
mod.exports.lib = BaseV
mod.exports.wilds = wildsExports
mod.exports.wildSpawnsInstalled = wildsExports ~= nil
mod.exports.wildSpawnsSource = wildsSource
mod.exports.wildSpawnsError = wildsErr
mod.exports.goldWildsDrawBridgeInstalled = GoldWildsBridge ~= nil
mod.exports.goldWildsDrawBridgeError = goldWildsBridgeErr
mod.exports.goldWildsDrawBridgeStatus = function()
  return GoldWildsBridge and GoldWildsBridge.status and GoldWildsBridge.status() or nil
end
mod.exports.goldComposeBridgeInstalled = GoldComposeBridge ~= nil
mod.exports.goldComposeBridgeError = goldComposeBridgeErr
mod.exports.goldComposeBridgeStatus = function()
  return GoldComposeBridge and GoldComposeBridge.status and GoldComposeBridge.status() or nil
end
mod.exports.visibleWildsForced = true
mod.exports.entryCompleted = true
