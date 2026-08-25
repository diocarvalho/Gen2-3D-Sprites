-- v0.4.09 regression: iOS never auto-rotates the finished Game2 frame.
-- Instead it asks SDL/UIKit for Portrait + BOTH landscape directions and lets
-- the native view controller own framebuffer/touch orientation.  Only the
-- explicit IPHONE FORCE 180 emergency switch may rotate the final frame.

local function eq(a,b,msg)
  assert(a == b, (msg or "values differ") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function near(a,b,msg)
  assert(math.abs(a-b) < 1e-9, (msg or "values differ") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end

local oldLove = love
local oldPlatform = package.loaded["src.core.Platform"]
local oldGame2 = package.loaded["src.core.Game2"]
local oldOrientation = package.loaded["src.core.Orientation"]
local oldFfi = package.loaded["ffi"]

local function graphicsFixture()
  local current = nil
  local draws, canvases = {}, {}
  local G = {}
  function G.getDimensions() return 844, 390 end
  function G.newCanvas(w,h)
    local c = { w=w, h=h, released=false }
    function c:setFilter() end
    function c:release() self.released = true end
    canvases[#canvases+1] = c
    return c
  end
  function G.getCanvas() return current end
  function G.setCanvas(c) current = c end
  function G.push() end
  function G.pop() end
  function G.origin() end
  function G.clear() end
  function G.setShader() end
  function G.setScissor() end
  function G.setBlendMode() end
  function G.setColor() end
  function G.draw(canvas,x,y,r) draws[#draws+1] = {canvas=canvas,x=x,y=y,r=r} end
  return G, draws, canvases
end

local function fresh(platform, orientationRef, values, opts)
  opts = opts or {}
  local G, draws, canvases = graphicsFixture()
  love = {
    graphics=G,
    window={ getDisplayOrientation=function() return orientationRef.value end },
  }
  package.loaded["src.core.Platform"] = { detect=function() return {os=platform} end }

  local hints = {}
  if opts.noFfi then
    package.loaded["ffi"] = false
  else
    package.loaded["ffi"] = {
      cdef=function() return true end,
      C={ SDL_SetHint=function(name,value)
        hints[#hints+1] = {name=name,value=value}
        return 1
      end },
    }
  end
  local engineApplies = {}
  package.loaded["src.core.Orientation"] = {
    apply=function(mode)
      engineApplies[#engineApplies+1] = mode
      return opts.engineApply == true
    end,
  }

  local nativeDraws, lastTouch = 0, nil
  local Game2 = {
    draw=function() nativeDraws=nativeDraws+1 end,
    touchpressed=function(self,id,x,y,dx,dy,pressure)
      lastTouch={id=id,x=x,y=y,dx=dx,dy=dy,pressure=pressure}
    end,
    touchmoved=function() end,
    touchreleased=function() end,
  }
  package.loaded["src.core.Game2"] = Game2
  local mod={id="STADIUM2_OVERWORLD_MODELS",options={get=function(self,key) return values[key] end}}
  local M=assert(loadfile("lib/AndroidFullFrameFlip.lua"))({mod=mod})
  assert(M.install())
  return M,Game2,draws,canvases,hints,engineApplies,
    function() return nativeDraws end,
    function() return lastTouch end
end

-- A flipped landscape report is DIAGNOSTIC ONLY: modern iOS gets an explicit
-- normal-orientation mask and no second 180-degree frame/touch transform.
do
  local orientation={value="landscapeFlipped"}
  local values={iosOrientationFix=true,iosForceFlip=false,screenFlip=false}
  local M,Game2,draws,canvases,hints,_,native,lastTouch=fresh("iOS",orientation,values)
  Game2:draw()
  eq(native(),1,"iOS native frame runs once")
  eq(#draws,0,"iOS never double rotates the native frame")
  eq(#canvases,0,"iOS allocates no auto-flip canvas")
  eq(M.status().enabled,false,"iOS automatic frame flip disabled")
  eq(M.status().iosNativeApplied,true,"native orientation mask applied")
  eq(M.status().iosNativePath,"sdl-mask","direct SDL mask is preferred")
  eq(#hints,2,"both SDL2 and SDL3 hint names are written")
  eq(hints[1].value,"Portrait LandscapeLeft LandscapeRight","normal iPhone orientation mask")
  eq(hints[2].value,"Portrait LandscapeLeft LandscapeRight","same mask reaches legacy key")
  Game2:touchpressed(1,100,50,3,-4,1)
  local t=lastTouch()
  eq(t.x,100,"native iOS touch X stays native")
  eq(t.y,50,"native iOS touch Y stays native")
end

-- Current engine fallback: if direct FFI is unavailable, use the engine's
-- newly iOS-aware Orientation.apply and explicitly allow both landscapes.
do
  local orientation={value="landscape"}
  local values={iosOrientationFix=true,iosForceFlip=false,screenFlip=false}
  local M,Game2,draws,_,_,engineApplies,native=fresh("iOS",orientation,values,{noFfi=true,engineApply=true})
  Game2:draw()
  eq(native(),1,"engine-fallback iOS native frame")
  eq(#draws,0,"engine fallback still never post-flips")
  eq(M.status().iosNativeApplied,true,"engine fallback lands")
  eq(M.status().iosNativePath,"engine-landscape","engine fallback recorded")
  eq(engineApplies[1],"landscape","engine enables both landscape directions")
end

-- Emergency override remains available for a genuinely broken sideload.
do
  local orientation={value="landscape"}
  local values={iosOrientationFix=true,iosForceFlip=true,screenFlip=false}
  local M,Game2,draws,canvases,_,_,native,lastTouch=fresh("iOS",orientation,values)
  Game2:draw()
  eq(native(),1,"forced iOS still runs native draw once")
  eq(#draws,1,"forced iOS rotates final frame")
  eq(draws[1].x,844,"forced iOS rotates about width")
  eq(draws[1].y,390,"forced iOS rotates about height")
  near(draws[1].r,math.pi,"forced iOS uses 180 degrees")
  eq(#canvases,1,"forced iOS allocates one canvas")
  eq(M.status().flipReason,"ios-force-180","forced iOS reason")
  Game2:touchpressed(7,100,50,3,-4,1)
  local t=lastTouch()
  eq(t.x,744,"forced iOS touch X remapped")
  eq(t.y,340,"forced iOS touch Y remapped")
  eq(t.dx,-3,"forced iOS dX remapped")
  eq(t.dy,4,"forced iOS dY remapped")
end

-- Android remains manual-only and never consumes the iOS mask path.
do
  local orientation={value="landscapeflipped"}
  local values={iosOrientationFix=true,iosForceFlip=false,screenFlip=false}
  local M,Game2,draws,_,hints,_,native=fresh("Android",orientation,values)
  Game2:draw()
  eq(native(),1,"Android native frame")
  eq(#draws,0,"Android is not auto flipped")
  eq(#hints,0,"Android does not write iOS orientation mask")
  values.screenFlip=true
  Game2:draw()
  eq(#draws,1,"Android manual flip unchanged")
  eq(M.status().flipReason,"android-manual","Android manual reason")
end

package.loaded["src.core.Platform"] = oldPlatform
package.loaded["src.core.Game2"] = oldGame2
package.loaded["src.core.Orientation"] = oldOrientation
package.loaded["ffi"] = oldFfi
love = oldLove
print("ios_orientation_flip_parity: OK")
