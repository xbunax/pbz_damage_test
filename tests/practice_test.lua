local M=dofile(arg[1]..'/PBZTrainingDummy/Scripts/practice.lua')
local function fixture()
 local e={active=false,busy=false,far=false,ground=true,accept=true,granted=true,attacks=0,holds=0}
 local actor,player={valid=true,hp=100},{valid=true,hp=100}
 local A={valid=function(o)return o and o.valid end,health=function(o)return o.hp end,
  hold=function()e.holds=e.holds+1;e.active=false end,release=function()end,
  hasSkill=function()return e.granted end,skillActive=function()return e.active end,
  busy=function()return e.busy end,distance=function()return e.far and 2000 or 180 end,
  recoveryReason=function()return not e.ground and '等待落地' or nil end,
  aim=function()end,attack=function()e.attacks=e.attacks+1;return e.accept,'受击恢复中' end}
 local s=M.new(A,{actor=actor})
 local function tick(t)M.tick(s,player,t)end
 return e,s,player,tick
end
local e,s,p,tick=fixture()
M.start(s,p,'red',2,0)
tick(0.4);assert(e.attacks==0)
tick(0.5);assert(e.attacks==1)
e.active=true;tick(0.6);tick(2.5);assert(e.attacks==1,'No overlapping activation')
e.active=false;tick(3);assert(s.completed==1)
e.far=true;tick(5);assert(e.attacks==1 and s.running)
e.far=false;e.busy=true;tick(5.5);assert(e.attacks==1)
e.busy=false;e.ground=false;tick(6);assert(e.attacks==1)
e.ground=true;e.accept=false;tick(6.5);assert(e.attacks==2 and s.running)
tick(6.6);assert(e.attacks==2,'Retries are throttled')
e.accept=true;tick(7);e.active=true;tick(7.1)
assert(s.running and s.phase=='active' and s.retries==0 and e.holds==1,'Recovery never freezes/removes game hit reactions')
-- A perfect-dodge counter interrupts an action, and temporarily blocks the next activation.
e.active=false;tick(7.2);e.accept=false;tick(9.2);tick(9.7)
assert(s.running and s.completed==2)
e.accept=true;tick(10.2);e.active=true;tick(10.3)
assert(s.running and s.phase=='active','Loop must resume after the counter attack restriction expires')
M.stop(s);local previous=e.attacks;tick(100);assert(e.attacks==previous and not s.running)
-- A true-positive API result followed by an interrupted start is recoverable.
e,s,p,tick=fixture();M.start(s,p,'red',0.5,0);tick(0.5);tick(2)
assert(s.running and s.phase=='waiting')
tick(2.5);e.active=true;tick(2.6);assert(s.phase=='active')
-- Continuous false positives are bounded, rather than retried forever.
e,s,p,tick=fixture();M.start(s,p,'red',0.5,0)
for i=1,400 do tick(i*.1)end
assert(not s.running and s.message:find('30',1,true))
-- Continuous rejection is bounded, and skill disappearance is an immediate permanent error.
e,s,p,tick=fixture();e.accept=false;M.start(s,p,'red',0.5,0)
for i=1,320 do tick(i*.1)end
assert(not s.running and e.attacks<70)
e,s,p,tick=fixture();M.start(s,p,'red',1,0);e.granted=false;tick(.5);assert(not s.running and e.attacks==0)
e,s,p,tick=fixture();M.start(s,p,'red',1,0);tick(.5);e.active=true;tick(.6);tick(16);assert(not s.running)
e,s,p,tick=fixture();M.start(s,p,'red',1,0);p.hp=0;tick(.5);assert(not s.running)
e,s,p,tick=fixture();e.granted=false
assert(not pcall(M.start,s,p,'missing',1,0) and not s.running)
assert(not pcall(M.start,s,p,'red',0,0))
-- Twenty normal cycles remain serialized even with transient denials between them.
e,s,p,tick=fixture();M.start(s,p,'red',.5,0)
local time=0
for cycle=1,20 do
 time=time+1;e.accept=false;tick(time)
 time=time+.6;e.accept=true;tick(time);e.active=true;tick(time+.1)
 e.active=false;tick(time+.3)
 assert(s.running and s.completed==cycle)
 time=time+.3
end
assert(s.completed==20)
-- Free AI is not a single ability loop: no 15-second timeout or periodic reactivation.
e,s,p,tick=fixture()
s.control.profile={boss=true,trainingRadius=1500}
local starts=0
s.api.startAI=function()starts=starts+1 end
M.startAI(s,p,0);tick(30);tick(300)
assert(s.running and s.phase=='ai'and starts==1 and e.attacks==0)
e.far=true;tick(301);assert(not s.running and s.message:find('训练范围',1,true))
e.far=false
M.startAI(s,p,302);p.hp=0;tick(303);assert(not s.running)
p.hp=100;s.api.startAI=function()error('AI startup failed')end
assert(not pcall(M.startAI,s,p,304)and not s.running)
assert(s.message=='自由对练启动失败，攻击已停止')
s.control.profile={};assert(not pcall(M.startAI,s,p,305))
print('PASS: interrupted/countered attacks recover; retries throttled and bounded; no overlap; ground/busy/range waits; stop/death/skill loss; 20 cycles')
