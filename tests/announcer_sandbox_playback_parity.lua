-- v0.4.22 regression: Stadium announcer playback must survive current
-- Gen1Recomp sandboxes where reading love.filesystem itself is blocked.
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
local function check(v,msg) assert(v,msg) end

local function le16(n)
  return string.char(n % 256, math.floor(n / 256) % 256)
end
local function le32(n)
  return string.char(n % 256, math.floor(n / 256) % 256,
    math.floor(n / 65536) % 256, math.floor(n / 16777216) % 256)
end
local function wav()
  local pcm = le16(1200) .. le16(0) .. le16(800) .. le16(0)
  return "RIFF" .. le32(36 + #pcm) .. "WAVE"
    .. "fmt " .. le32(16) .. le16(1) .. le16(1) .. le32(16000)
    .. le32(32000) .. le16(2) .. le16(16)
    .. "data" .. le32(#pcm) .. pcm
end

local bytes = wav()
local files = {
  ["stadium2_overworld_models/announcer/v2/voicepack.ready"] =
    "format=SFXA2\nclip_count=823\nsample_rate=16000\nsource=stadium-rom-v1\n",
  ["stadium2_overworld_models/announcer/v2/000.wav"] = bytes,
  ["stadium2_overworld_models/announcer/v2/223.wav"] = bytes,
  ["stadium2_overworld_models/announcer/v2/822.wav"] = bytes,
}
local fs = {
  getInfo = function(path) return files[path] and {type="file", size=#files[path]} or nil end,
  read = function(path) return files[path] end,
  createDirectory = function() return true end,
  write = function(path,data) files[path]=data; return true end,
  remove = function(path) files[path]=nil; return true end,
}

local played, createdSound = 0, 0
local function source()
  return {
    play=function() played=played+1; return true end,
    stop=function() return true end,
    isPlaying=function() return true end,
    setLooping=function() end,
    setVolume=function() end,
    seek=function() end,
  }
end
local soundApi = {
  newSoundData=function(samples,rate,bits,channels)
    createdSound=createdSound+1
    eq(rate,16000,"announcer sample rate")
    eq(bits,16,"announcer bit depth")
    eq(channels,1,"announcer channels")
    return {setSample=function() end}
  end,
}
local audioApi = { newSource=function() return source() end }
_G.love = setmetatable({ sound=soundApi, audio=audioApi }, {
  __index=function(_,key)
    if key=="filesystem" then error("sandbox: love.filesystem blocked") end
  end,
})

local options = { announcer=true, announcer_scope="gym" }
local mod = {
  options={get=function(_,key) return options[key] end},
  read=function() return nil end,
  log={info=function() end,warn=function() end,error=function() end},
}
local namespace = {
  mod=mod,
  storage=nil,
  log=mod.log,
  hostRequire=function(name)
    if name=="EngineCompat" then return {fs=function() return fs end} end
  end,
  require=function(name)
    if name=="StadiumAnnouncerRom" then return {} end
    return nil
  end,
}
local Announcer=assert(loadfile("lib/StadiumBattleFX217/Announcer.lua"))(namespace)
local ok,err=Announcer.testVoice(223)
check(ok,err or "sandboxed announcer test voice should play")
check(played>=1,"voice source play called")
check(createdSound>=1,"blocked FileData path falls back to in-memory SoundData")

local battle={
  kind="trainer", stadiumBoss=true, oppClass=nil, partyIndex=1,
  player={mon={species="PIKACHU"},isPlayer=true,shownHP=20},
  enemy={mon={species="PIDGEOTTO"},shownHP=20},
  data={pokemon={PIKACHU={dex=25},PIDGEOTTO={dex=17}}},
  sendingOut=true, enemySendingOut=true,
}
check(Announcer.beginBattle(battle),"default GYM scope accepts Gold boss without Stadium1-specific intro")

local ordinary={
  kind="trainer", stadiumBoss=false, oppClass=nil, partyIndex=1,
  player=battle.player, enemy=battle.enemy, data=battle.data,
  sendingOut=true, enemySendingOut=true,
}
check(not Announcer.beginBattle(ordinary),"default GYM scope still rejects ordinary trainers")
print("announcer_sandbox_playback_parity: OK")
