-- v0.3.60 regression: Kanto NPC/Pokemon cell lookups use a maintained
-- spatial index. The index must stay correct as walkers/boulders move,
-- actors are removed, duplicate buckets use except correctly, and caches
-- invalidate/rebuild.

package.path = "./?.lua;./?/init.lua;" .. package.path

local function eq(a,b,msg)
  if a ~= b then error((msg or "eq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end

local Spatial = assert(loadfile("lib/KantoSpatial.lua"))()
Spatial.resetCounters()
check(type(Spatial.key(1,2)) == "number",
  "actor cell key is packed numeric hot-path data, not an allocated string")

local region = {
  npcSpatialCache = {},
  pokemonSpatialCache = {},
  npcRoleCache = {},
  actorGeneration = 0,
}
local a={name="a",cellX=1,cellY=2,def={trainerClass="OPP_BUG_CATCHER"}}
local b={name="b",cellX=3,cellY=4,wander=true}
local c={name="c",cellX=1,cellY=2}
local npcs={a,b,c}

eq(Spatial.at(region,"MAP","npc",npcs,1,2,nil),a,"initial npc hit")
eq(Spatial.npcBuilds,1,"one npc index build")
eq(Spatial.at(region,"MAP","npc",npcs,1,2,a),c,"except returns second bucket actor")
eq(Spatial.npcBuilds,1,"repeat lookup reuses index")
check(Spatial.npcHits>=2,"npc hit diagnostic")

-- Immutable trainer/wander roles are filtered once per authoritative NPC list.
local roles1=Spatial.roles(region,"MAP",npcs)
eq(#roles1.trainers,1,"trainer role indexed once")
eq(roles1.trainers[1],a,"trainer role points at authored actor")
eq(#roles1.wanderers,1,"wanderer role indexed once")
eq(roles1.wanderers[1],b,"wanderer role points at walker")
local roles2=Spatial.roles(region,"MAP",npcs)
eq(roles2,roles1,"role cache identity reused")
eq(Spatial.roleBuilds,1,"one role build")
check(Spatial.roleHits>=1,"role cache hit diagnostic")

-- Active walker interpolation is a maintained tiny list, not a full-NPC scan.
b.moving,b._moveT=true,0
Spatial.setMoving(region,"MAP",npcs,b,true)
eq(#roles1.moving,1,"walker enters active mover list")
eq(roles1.moving[1],b,"active mover points at walker")
Spatial.setMoving(region,"MAP",npcs,b,false)
eq(#roles1.moving,0,"walker leaves active mover list")
check(Spatial.movingAdds==1 and Spatial.movingRemoves==1,"mover diagnostics counted")
b.moving,b._moveT=false,nil

local genBeforeMove=region.actorGeneration
Spatial.move(region,"MAP","npc",a,1,2,5,6)
check(region.actorGeneration>genBeforeMove,"actor movement bumps render-generation invalidation")
a.cellX,a.cellY=5,6
eq(Spatial.at(region,"MAP","npc",npcs,1,2,nil),c,"old cell now holds only c")
eq(Spatial.at(region,"MAP","npc",npcs,5,6,nil),a,"moved actor indexed at target")
eq(Spatial.moves,1,"move diagnostic")

-- Pokemon index is separate and removal is immediate.
local p1={species="PIKACHU",cellX=8,cellY=9}
local p2={species="EEVEE",cellX=10,cellY=11}
local mons={p1,p2}
eq(Spatial.at(region,"MAP","pokemon",mons,8,9,nil),p1,"pokemon hit")
eq(Spatial.pokemonBuilds,1,"pokemon index build")
Spatial.remove(region,"MAP","pokemon",p1,8,9)
table.remove(mons,1)
eq(Spatial.at(region,"MAP","pokemon",mons,8,9,nil),nil,"removed pokemon gone")
eq(Spatial.at(region,"MAP","pokemon",mons,10,11,nil),p2,"other pokemon preserved")

-- Invalidation forces a clean rebuild from the authoritative actor list.
local genBeforeInvalidate=region.actorGeneration
Spatial.invalidate(region,"MAP",true,true)
eq(region.npcSpatialCache["MAP"],nil,"npc invalidated")
eq(region.pokemonSpatialCache["MAP"],nil,"pokemon invalidated")
eq(region.npcRoleCache["MAP"],nil,"npc roles invalidated with authoritative list")
check(region.actorGeneration>genBeforeInvalidate,"list invalidation bumps actor generation")
eq(Spatial.at(region,"MAP","npc",npcs,5,6,nil),a,"npc rebuild correct")
eq(Spatial.npcBuilds,2,"npc rebuilt once")

print("kanto_actor_spatial_parity: OK")
