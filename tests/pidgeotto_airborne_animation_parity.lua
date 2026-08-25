-- v0.4.25: Pidgeotto must use a flight-safe non-combat Stadium loop while airborne.
local function check(v,msg) assert(v,msg) end
local src=assert(io.open("lib/OverworldStadium.lua","rb")):read("*a")

check(src:find("AIRBORNE_CLIP_OVERRIDES",1,true),
  "overworld Stadium bridge defines narrow airborne clip overrides")
check(src:find('[17] = { "idle_alt", "idle_return", "entrance_alt" }',1,true),
  "Dex 17 Pidgeotto only considers non-combat airborne contexts")
check(src:find('candidate == baseIdle',1,true),
  "airborne selector rejects context aliases that resolve to the frozen primary idle")
check(src:find('StadiumPack.tracks',1,true) and src:find('airborneClipMotion',1,true),
  "Pidgeotto airborne selection scores real Stadium skeletal motion")
check(not src:find('for candidate, anim in ipairs(mon.model.anims)',1,true),
  "Pidgeotto no longer scans every animation and accidentally selects attacks")
check(src:find('AIRBORNE_COMBAT_CONTEXTS',1,true)
    and src:find('forbidden[candidate]',1,true),
  "airborne selector rejects aliases to attack/struggle/reaction contexts")
check(src:find('label:find("attack"',1,true)
    and src:find('label:find("reaction"',1,true),
  "airborne selector also rejects combat-labelled clips")
check(src:find('if entity and airbornePresentation(entity) then',1,true),
  "all airborne presentations bypass the ground locomotion bridge")
check(src:find('slot.walkBlend = 0',1,true),
  "airborne mount cannot have its flight clip overwritten by a ground gait")
check(src:find('entity._ambientFlyingPokemon == true',1,true),
  "ambient sky Pidgeotto receives the airborne clip")
check(src:find('entity._flyYourPokemonMount == true',1,true)
    and src:find('_flyYourPokemonMode',1,true),
  "Fly Your Pokemon Pidgeotto mount receives the same airborne clip")
check(src:find('startAirborneClip(slot, mon, dex)',1,true),
  "airborne clip is selected before StadiumMon update")
check(src:find('stopAirborneClip(slot, mon)',1,true),
  "leaving flight restores the normal authored idle")

print("pidgeotto_airborne_animation_parity: OK")
