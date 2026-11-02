local root=assert(arg[1])
local M=dofile(root..'/PBZTrainingDummy/Scripts/music.lua')
local function obj(address)
    return {IsValid=function()return true end,GetAddress=function()return address end}
end
local function weak(o) return {Get=function()return o end} end
local dummy,enemy,boss=obj(1),obj(2),obj(3)
local function subsystem(normal,special)
    return {EngagedEnemies=normal,EngagedSpecialEnemies=special,bInBattle=true,updates=0,
        IsValid=function()return true end,
        UpdateGameplayMusic=function(self,ended)
            assert(ended);self.updates=self.updates+1
        end}
end
local m=subsystem({weak(dummy)},{})
assert(M.excludeFrom(m,dummy) and #m.EngagedEnemies==0 and not m.bInBattle and m.updates==1)
assert(not M.excludeFrom(m,dummy) and m.updates==1,'Must not continually override ambient music')
m=subsystem({weak(dummy),weak(enemy)},{weak(boss)})
assert(M.excludeFrom(m,dummy) and #m.EngagedEnemies==1 and m.EngagedEnemies[1]:Get()==enemy)
assert(m.EngagedSpecialEnemies[1]:Get()==boss and m.bInBattle and m.updates==0)
m=subsystem({weak(enemy)},{weak(dummy)})
assert(M.excludeFrom(m,dummy) and #m.EngagedSpecialEnemies==0 and m.bInBattle and m.updates==0)
m=subsystem({weak(enemy)},{weak(boss)})
assert(not M.excludeFrom(m,dummy) and m.bInBattle and m.updates==0)
print('PASS: dummy-only music exit, normal enemy/boss preservation, special list, idempotence')
