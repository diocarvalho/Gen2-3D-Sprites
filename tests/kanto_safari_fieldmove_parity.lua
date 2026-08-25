-- v0.3.91 regression: Yellow's Safari/Fuchsia HM progression mutates Gold
-- safely, Gold Teeth stay Kanto-local, and Yellow field-HM badge rules use
-- Kanto badges rather than unrelated Johto badge ownership.

package.preload["src.render.Assets"] = function() return {} end

local bagFull, bagAdds = false, {}
package.preload["src.inventory.Bag"] = function()
  return {
    add = function(save, id, count)
      if bagFull then return false end
      save.inventory = save.inventory or {}
      if save.inventory[id] then return false end -- HMs/key items are unique in this harness
      save.inventory[id] = count or 1
      bagAdds[#bagAdds + 1] = id
      return true
    end,
  }
end
package.preload["src.core.Sound"] = function()
  return { play = function() return true end }
end
package.preload["src.world.gen2.FieldMoves"] = function()
  return {
    -- Deliberately claim every Johto badge is present. v0.3.91 must ignore
    -- this while inside Yellow Kanto and consult player.kantoBadges instead.
    hasBadge = function() return true end,
    BADGE = { SURF="FOG", CUT="HIVE", FLY="STORM", STRENGTH="PLAIN", FLASH="ZEPHYR" },
    partyMoveUser = function(party, moveId)
      for _, mon in ipairs(party or {}) do
        for _, move in ipairs(mon.moves or {}) do
          local id = type(move) == "table" and (move.id or move.move) or move
          if tostring(id) == tostring(moveId) then return mon end
        end
      end
    end,
    TEXT = {},
  }
end

_G.love = { math = { random = function(a) return a end } }

local backing, messages = {}, {}
local TextBox = {
  new = function(_, text, onDone, opts)
    messages[#messages + 1] = tostring(text)
    if opts and type(opts.choice) == "function" then opts.choice(true)
    elseif onDone then onDone() end
    return { text=text }
  end,
}
local mod = {
  exports={}, options={get=function() return nil end}, ui={TextBox=TextBox},
  save={
    get=function(_,k,f) local v=backing[k]; return v==nil and f or v end,
    set=function(_,k,v) backing[k]=v; return true end,
  },
}
local stubs = {
  Quality={kantoRadius=function() return 1 end, actorDistanceCells=function() return math.huge end},
  FirstPerson={driving=function() return false end, releaseBody=function() end},
  ChunkMesher={warmPending=function() return 0 end, refresh=function() return true end},
  KantoGen2Style={PROJECTION_REV="test"},
  runtime_sheets={new=function() return {load=function() return true end,isReady=function() return false end} end},
}
local V={mod=mod,require=function(name) return stubs[name] or {} end}
local Twin=assert(loadfile("lib/TwinRegionWorld.lua"))(V)
local Safari=Twin._kantoSafariProgressForTest

local function check(v,label) if not v then error(label or "check failed",2) end end
local function eq(a,b,label) if a~=b then error((label or "value")..": expected "..tostring(b)..", got "..tostring(a),2) end end

local teeth={index=4,name="SAFARIZONEWEST_GOLD_TEETH",x=19,y=7,
  text="TEXT_SAFARIZONEWEST_GOLD_TEETH",item="GOLD_TEETH"}
local guru={index=1,x=3,y=3,text="TEXT_SAFARIZONESECRETHOUSE_FISHING_GURU"}
local warden={index=1,x=2,y=3,text="TEXT_WARDENSHOUSE_WARDEN"}
local region={mapsById={},npcCache={},pokemonCache={},validOutdoor={},records={},loaded={
  items={GOLD_TEETH={name="GOLD TEETH"}}, field={}, tilesets={}, trainerHeaders={},
  maps={
    SAFARI_ZONE_WEST={id="SAFARI_ZONE_WEST",objects={teeth}},
    SAFARI_ZONE_SECRET_HOUSE={id="SAFARI_ZONE_SECRET_HOUSE",objects={guru}},
    WARDENS_HOUSE={id="WARDENS_HOUSE",objects={warden}},
  },
  text={
    _SafariZoneSecretHouseFishingGuruYouHaveWonText="SECRET HOUSE WIN",
    _SafariZoneSecretHouseFishingGuruReceivedHM03Text="RECEIVED {RAM:BUFFER}",
    _SafariZoneSecretHouseFishingGuruHM03ExplanationText="HM03 IS SURF",
    _SafariZoneSecretHouseFishingGuruHM03NoRoomText="NO ROOM SURF",
    _WardensHouseWardenGibberish1Text="WARDEN GIBBERISH",
    _WardensHouseWardenGaveTheGoldTeethText="GAVE GOLD TEETH",
    _WardensHouseWardenThanksText="WARDEN THANKS",
    _WardensHouseWardenReceivedHM04Text="RECEIVED {RAM:BUFFER}",
    _WardensHouseWardenHM04ExplanationText="HM04 IS STRENGTH",
    _WardensHouseWardenHM04NoRoomText="NO ROOM STRENGTH",
  },
}}
local world={game={data={items={
  HM03={name="HM03",teaches="SURF",pocket="TM_HM"},
  HM04={name="HM04",teaches="STRENGTH",pocket="TM_HM"},
}},stack={push=function(self,x) self.last=x; return true end},save=nil}}

local function fresh()
  backing,messages,bagAdds={}, {}, {}
  bagFull=false
  world.game.save={inventory={},party={{species="LAPRAS",moves={"SURF","STRENGTH","CUT","FLY","FLASH"}}},
    player={name="GOLD",kantoBadges={}},badges={FOG=true,STORM=true,HIVE=true,PLAIN=true,ZEPHYR=true}}
  region.npcCache,region.pokemonCache={},{}
  Twin._resetKantoStateCacheForTest()
  local e=Twin._excursionForTest
  e.active=true; e.region=region; e.sourceMapId="SAFARI_ZONE_WEST"; e.forcedBike=false
  e.surfing=false; e.biking=false; e.strengthActive=false; e.battleBusy=false
end

-- Primary-source Yellow badge table: Flash/Boulder, Cut/Cascade, Fly/Thunder,
-- Strength/Rainbow and Surf/Soul.
do
  eq(Safari.requiredBadge("FLASH"),"BOULDER","Flash badge")
  eq(Safari.requiredBadge("CUT"),"CASCADE","Cut badge")
  eq(Safari.requiredBadge("FLY"),"THUNDER","Fly badge")
  eq(Safari.requiredBadge("STRENGTH"),"RAINBOW","Strength badge")
  eq(Safari.requiredBadge("SURF"),"SOUL","Surf badge")
end

-- Johto badge ownership cannot authorize Kanto field HMs. Companion Kanto
-- badges do, including numeric compatibility slots used by older saves.
do
  fresh()
  check(not Twin._kantoFieldBadgeForTest(world,"SURF"),"Johto Fog badge must not unlock Kanto Surf")
  world.game.save.player.kantoBadges.SOUL=true
  check(Twin._kantoFieldBadgeForTest(world,"SURF"),"Soul badge unlocks Kanto Surf")
  world.game.save.player.kantoBadges.SOUL=nil; world.game.save.player.kantoBadges[5]=true
  check(Twin._kantoFieldBadgeForTest(world,"SURF"),"legacy numeric Soul badge works")
end

-- Surf interaction itself follows the same Kanto badge gate even though the
-- stubbed Gold FieldMoves.hasBadge() claims the Johto requirement is met.
do
  fresh()
  local water={isWaterCell=function(_,x,y) return x==1 and y==1 end}
  check(Twin._tryYellowSurf(world,water,1,1),"Surf gate interaction handled")
  check(not Twin._excursionForTest.surfing,"Surf blocked without Soul badge")
  world.game.save.player.kantoBadges.SOUL=true
  check(Twin._tryYellowSurf(world,water,1,1),"Surf prompt handled with Soul badge")
  check(Twin._excursionForTest.surfing,"Surf starts with Soul badge")
end

-- Gold Teeth are a Kanto-local quest key. Picking them up consumes the Yellow
-- object without creating a bogus Gold/Silver inventory item.
do
  fresh()
  check(Twin._pickupYellowItem(world,region,"SAFARI_ZONE_WEST",teeth),"Gold Teeth pickup handled")
  check(Twin._kantoItemHeld(world,"GOLD_TEETH"),"Gold Teeth held locally")
  eq(world.game.save.inventory.GOLD_TEETH,nil,"no Gold Teeth injected into Gold bag")
end

-- Warden faithfully removes the teeth before GiveItem. A full PACK therefore
-- leaves EVENT_GAVE_GOLD_TEETH set and allows HM04 to be retried later without
-- requiring another pair of teeth.
do
  fresh()
  Twin._talkKantoWarden(world,region)
  check(not Twin._kantoEvent(Safari.WARDEN.gaveEvent),"no teeth: Warden still gibberish")
  Twin._giveKantoLocalItem("GOLD_TEETH")
  bagFull=true
  Twin._talkKantoWarden(world,region)
  check(not Twin._kantoItemHeld(world,"GOLD_TEETH"),"Warden consumes Gold Teeth")
  check(Twin._kantoEvent(Safari.WARDEN.gaveEvent),"gave-teeth event persists")
  check(not Twin._kantoEvent(Safari.WARDEN.hmEvent),"full bag does not consume HM reward")
  eq(world.game.save.inventory.HM04,nil,"no Strength HM while full")
  bagFull=false
  Twin._talkKantoWarden(world,region)
  eq(world.game.save.inventory.HM04,1,"Gold HM04 Strength received on retry")
  check(Twin._kantoEvent(Safari.WARDEN.hmEvent),"HM04 event persists")
end

-- Secret House gives Gold's real Surf HM once, retries after a full PACK, and
-- does not duplicate an already-owned unique HM.
do
  fresh(); bagFull=true
  check(Twin._tryKantoSpecialObjectInteraction(world,region,"SAFARI_ZONE_SECRET_HOUSE",guru),"Secret House handled")
  check(not Twin._kantoEvent(Safari.SECRET_HOUSE.event),"full bag keeps Surf reward pending")
  bagFull=false
  Twin._tryKantoSpecialObjectInteraction(world,region,"SAFARI_ZONE_SECRET_HOUSE",guru)
  eq(world.game.save.inventory.HM03,1,"Gold HM03 Surf received")
  check(Twin._kantoEvent(Safari.SECRET_HOUSE.event),"Surf event persists")
  local before=#bagAdds
  Twin._tryKantoSpecialObjectInteraction(world,region,"SAFARI_ZONE_SECRET_HOUSE",guru)
  eq(#bagAdds,before,"Secret House HM cannot duplicate")
end

print("kanto_safari_fieldmove_parity: OK")
