-- v0.3.53 regression: text_asm NPC dialogue is presented through a detached
-- sandbox instead of being silently rejected.  Self-contained: texlua-safe.

package.path = "./?.lua;./?/init.lua;" .. package.path

local function eq(a,b,msg)
  if a ~= b then error((msg or "eq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end
local function check(v,msg) if not v then error(msg or "check failed", 2) end end

local handlers = {}
local playedCries = {}

package.preload["data.scripts.init"] = function() return {} end
package.preload["src.script.MapScripts"] = function()
  local function get(mapId,textConst)
    local m = handlers[mapId]; return m and m[textConst] or nil
  end
  return { talkScript = get, baseTalk = get }
end
package.preload["src.core.GameVersion"] = function()
  return {
    isYellow=function() return false end, isRed=function() return false end,
    isBlue=function() return false end, get=function() return "gold" end,
    generation=function() return 2 end,
  }
end
package.preload["src.render.TextBox"] = function()
  local T = {}
  function T.substitute(game,text)
    return tostring(text):gsub("{PLAYER}", game.save.player.name or "RED")
      :gsub("{RIVAL}", (game.save.rival and game.save.rival.name) or "???")
  end
  function T.new(game,text,onDone,opts)
    return { real=true, text=text, onDone=onDone, opts=opts }
  end
  return T
end
package.preload["src.ui.ListMenu"] = function()
  return { new=function(game,title,items,opts)
    return {realMenu=true,title=title,items=items,opts=opts}
  end }
end
package.preload["src.ui.Screens"] = function() return { push=function() return true end } end
package.preload["src.core.Sound"] = function()
  return {
    play=function() return true end,
    playCry=function(data,species)
      playedCries[#playedCries+1]=species
      return { isPlaying=function() return false end }
    end
  }
end
package.preload["src.core.Music"] = function()
  return { play=function() return true end, stop=function() return true end }
end
package.preload["src.script.Commands"] = function()
  return { resolve=function(data,name) return function() end, {} end }
end

-- Minimal asynchronous ScriptRunner used to exercise the table-script path.
package.preload["src.script.ScriptRunner"] = function()
  local R = {}; R.__index=R
  function R.new(game,ow) return setmetatable({game=game,ow=ow,co=nil},R) end
  function R:run(rows,ctx)
    local TextBox=require("src.render.TextBox")
    local i=1
    local function step()
      local row=rows[i]; i=i+1
      if not row then if ctx and ctx.onDone then ctx.onDone() end; return end
      if row[1]=="play_cry" then
        self.pendingCry=row[2]; self.pendingCryWait=row[3]; step()
      elseif row[1]=="show_text" then
        local opts
        if self.pendingCry then
          local species,wait=self.pendingCry,self.pendingCryWait
          self.pendingCry,self.pendingCryWait=nil,nil
          opts={auto={sound=function()
            return require("src.core.Sound").playCry(self.game.data,species)
          end,delay=0,wait=wait==true}}
        end
        self.game.stack:push(TextBox.new(self.game,row[2],step,opts))
      elseif row[1]=="ask" then
        self.game.stack:push(TextBox.new(self.game,row[2],nil,{choice=function(yes)
          self.lastCheck=yes; step()
        end}))
      else step() end
    end
    step()
  end
  return R
end

-- Yellow-only modules: only Oaks Lab contributes in this test.  The other
-- conditionally loaded modules stay empty but must remain require-able.
package.preload["data.scripts.oaks_lab_yellow"] = function()
  return { talk = { TEXT_OAK = function(game,ow,npc,done)
    local TextBox=require("src.render.TextBox")
    game.stack:push(TextBox.new(game,"YELLOW OAK",done))
  end } }
end
for _,name in ipairs({"data.scripts.yellow_gifts","data.scripts.yellow_jessie_james",
                      "data.scripts.yellow_beach_house","data.scripts.yellow_viridian_old_man"}) do
  package.preload[name]=function() return {} end
end

local chunk=assert(loadfile("lib/KantoDialogue.lua"))
local Dialogue=chunk({})

local actualSave={player={name="GOLD"},rival={name="SILVER"},flags={},inventory={},party={}}
local world={game={save=actualSave,data={items={},pokemon={}},stack={}}}
local region={loaded={
  text={_Fallback="SAFE FALLBACK"}, field={}, maps={TEST_MAP={label="TEST_MAP"}},
  textPointers={TEST_MAP={TEXT_ASM={asm=true,label="MissingLocal"}}},
}}

local shown, asks, lists = {}, {}, {}
local adapters={
  show=function(_,text,done,opts) shown[#shown+1]={text=text,done=done,opts=opts}; return true end,
  ask=function(_,text,choice) asks[#asks+1]={text=text,choice=choice}; return true end,
  list=function(_,title,items,onChoose) lists[#lists+1]={title=title,items=items,onChoose=onChoose}; return true end,
  trainerDefeated=function() return false end,
}

-- Function text_asm: raw TextBox pushes are captured, token-substituted with
-- the cloned save, and replayed without mutating the real Gold save.
handlers.TEST_MAP={TEXT_ASM=function(game,ow,npc,done)
  local T=require("src.render.TextBox")
  game.stack:push(T.new(game,"HELLO {PLAYER}",function()
    game.save.flags.SANDBOX_ONLY=true
    game.stack:push(T.new(game,"SECOND LINE",done))
  end))
end}
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_ASM",
  info={asm=true,label="MissingLocal"},adapters=adapters,kantoEvents={EVENT_DOOR=true}},
  "function text_asm handled")
eq(shown[1].text,"HELLO GOLD","first function line")
check(actualSave.flags.SANDBOX_ONLY==nil,"real Gold save stays untouched")
shown[1].done()
eq(shown[2].text,"SECOND LINE","continuation line")
check(actualSave.flags.SANDBOX_ONLY==nil,"continuation still detached")

-- Table script path.
handlers.TEST_MAP.TEXT_ROWS={{"show_text","ROW ONE"},{"show_text","ROW TWO"}}
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_ROWS",
  info={asm=true},adapters=adapters},"row script handled")
eq(shown[3].text,"ROW ONE","row one")
shown[3].done()
eq(shown[4].text,"ROW TWO","row two")

-- Dialogue presentation audio survives the sandbox without exposing the real
-- save/world. Gen1Recomp's pet NPCs use play_cry immediately before show_text;
-- the real Kanto TextBox must receive that auto.sound/wait contract.
handlers.TEST_MAP.TEXT_CRY={{"play_cry","NIDORAN_M",true},{"show_text","NIDORAN!"}}
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_CRY",
  info={asm=true},adapters=adapters},"cry script handled")
eq(shown[5].text,"NIDORAN!","cry text")
check(shown[5].opts and shown[5].opts.auto and shown[5].opts.auto.wait==true,
  "cry keeps wait-for-button")
eq(#playedCries,0,"cry waits for textbox audio beat")
shown[5].opts.auto.sound()
eq(playedCries[1],"NIDORAN_M","cry species replayed")
eq(Dialogue.presentationAudio,1,"presentation audio diagnostic")
shown[5].done()

-- YES/NO is replayed as a real Kanto choice, then resumes the sandbox.
handlers.TEST_MAP.TEXT_CHOICE=function(game,ow,npc,done)
  local T=require("src.render.TextBox")
  game.stack:push(T.new(game,"DO YOU AGREE?",nil,{choice=function(yes)
    game.stack:push(T.new(game,yes and "YES PATH" or "NO PATH",done))
  end}))
end
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_CHOICE",
  info={asm=true},adapters=adapters},"choice handled")
eq(asks[1].text,"DO YOU AGREE?","question text")
asks[1].choice(true)
eq(shown[6].text,"YES PATH","yes continuation")

-- A handler that pushes a battle/screen-like state cannot leak it to the real
-- game; with no speech it falls back instead of making the NPC mute.
handlers.TEST_MAP.TEXT_STATE=function(game)
  game.stack:push({isBattle=true})
end
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_STATE",
  info={asm=true},adapters=adapters},"state-only handler gets fallback")
eq(shown[7].text,"...","state-only ellipsis fallback")
check(Dialogue.suppressedStates>=1,"battle-like state suppressed")

-- Extracted text fallback beats ellipsis when the local/far label is present.
handlers.TEST_MAP.TEXT_FALLBACK=nil
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_FALLBACK",
  info={asm=true,text="_Fallback"},adapters=adapters},"extracted fallback handled")
eq(shown[8].text,"SAFE FALLBACK","real extracted fallback")

-- No handler and no text still produces a usable interaction instead of
-- silently swallowing A.
check(Dialogue.try{world=world,region=region,mapId="TEST_MAP",textConst="TEXT_MISSING",
  info={asm=true,label="NoSuchText"},adapters=adapters},"ellipsis handled")
eq(shown[9].text,"...","missing handler fallback")

-- Gold's MapScripts has R/B OaksLab attached, but the bridge must prefer the
-- explicitly loaded Yellow module for a Yellow-cache excursion.
handlers.OAKS_LAB={TEXT_OAK=function(game,ow,npc,done)
  local T=require("src.render.TextBox"); game.stack:push(T.new(game,"RED OAK",done))
end}
check(Dialogue.try{world=world,region=region,mapId="OAKS_LAB",textConst="TEXT_OAK",
  info={asm=true},adapters=adapters},"yellow overlay handled")
eq(shown[10].text,"YELLOW OAK","Yellow OaksLab wins over Gold-host R/B attachment")

local auditRegion={loaded={
  maps={ A={label="A",objects={{text="T1"},{text="T2"}},signs={{text="S1"}}} },
  text={_Plain="plain"},
  textPointers={A={T1={text="_Plain"},T2={asm=true,label="AsmNpc"},S1={nurse=true}}},
}}
local audit=Dialogue.audit(auditRegion)
eq(audit.npcText,2,"audit NPC text count")
eq(audit.signText,1,"audit sign count")
eq(audit.plain,1,"audit plain")
eq(audit.asm,1,"audit asm")
eq(audit.service,1,"audit service")
eq(audit.guaranteedInteractive,3,"audit guaranteed interaction count")

print("kanto_npc_dialogue_parity: OK")
