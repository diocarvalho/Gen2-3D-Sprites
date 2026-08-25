-- v0.4.22 regression: Kanto gets its own larger ambient sky population.
local options={ambientFlyingDensity="normal",performancePreset="medium",voxel3d=true}
local mod={options={get=function(_,key)return options[key] end},exports={}}
local V={mod=mod,TwinRegionWorld={}}
local M=assert(loadfile("lib/AmbientFlyers.lua"))(V)
local f=assert(M._targetCountForTest)
local map={widthCells=20,heightCells=18,def={}}
local johto=f({map=map})
local kanto=f({map=map,_stadiumYellowKanto=true})
assert(kanto>=4,"Kanto normal density should show at least four ambient flyers on medium tier")
assert(kanto>johto,"Kanto ambient flyer density should exceed Johto at the same setting")
print("kanto_ambient_flyer_density_parity: OK")
