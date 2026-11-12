-- Exercise real menu callbacks, accounting, and lifecycle with an isolated engine adapter.
local root=arg[1]
local realDofile=dofile
package.loaded['PBZTrainingDummy.UEHelpers']={}
realDofile(root..'/PBZTrainingDummy/Scripts/vendor/ModMenu.lua')
local fs=realDofile(root..'/tests/memory_fs.lua')
local archivePath,languagePath
local now,currentWorld,playerAlive=0,'world1',true
local function obj(id)
 return {id=id,valid=true,hp=10000,max=10000,shachi=3000,shachiMax=3000,
  IsValid=function(s)return s.valid end,GetAddress=function(s)return s.id end,
  GetFullName=function(s)return s.id end,GetClass=function()return {GetFName=function()
   return {ToString=function()return 'DamageTakenPayload'end}end}end}
end
local player=obj('player');local nextId=0
local active=false
local A={valid=function(o)return o and o.valid end,player=function()return playerAlive and player or nil end,
 now=function()return now end,world=function(o)return o.world or currentWorld end,
 position=function(_,_,path)return {},path end,
 spawn=function(_,_,path,profile)nextId=nextId+1;local a=obj('dummy'..nextId);a.path=path;a.world=currentWorld;return a,{actor=a,tags={},noAggro=false,profile=profile}end,
 ready=function()return true end,
 configure=function(a,hp,shachi)a.hp=hp or a.max;a.max=hp or a.max;a.shachi=shachi or a.shachiMax;a.shachiMax=shachi or a.shachiMax end,
 health=function(a)return a.hp,a.max end,shachi=function(a)return a.shachi,a.shachiMax end,
 restoreShachi=function(a)a.shachi=a.shachiMax end,
 heal=function(a)a.hp=a.max end,destroy=function(a)if a then a.valid=false end end,
 hold=function()active=false end,release=function()end,clearAggro=function()end,
 setNoAggro=function(c,p,on)assert(c.actor.world==(p.world or currentWorld),'Never establish cross-world hatred');c.noAggro=on;c.actor.noAggro=on end,hasSkill=function()return true end,
 skillActive=function()return active end,busy=function()return false end,
 distance=function()return 180 end,aim=function()end,attack=function()active=true;return true end,
 damageSource=function(p)return p.source end,
 damage=function(p)return p.amount,p.shachiDamage end,damageHook='test-damage'}
A.startAI=function(c)c.noAggro=false;c.actor.noAggro=false;active=true end
local UI={sections={},values={},labels={},enabled={},options={},open=false}
function UI.Init(opts)
 UI.config=UI.config or {}
 for k,v in pairs(opts)do UI.config[k]=v end
 UI.tab=UI.config.tabs[1]
end
function UI.GetTab()return UI.tab end
function UI.SetTab(value)UI.tab=value end
function UI.Register(section)
 UI.sections[section.id]=section
 for _,item in ipairs(section.items)do if item.id and item.default~=nil and UI.values[section.id..'.'..item.id]==nil then UI.values[section.id..'.'..item.id]=item.default end end
end
function UI.Get(section,id)return UI.values[section..'.'..id]end
function UI.Set(section,id,value)UI.values[section..'.'..id]=value end
function UI.SetLabel(section,id,value)UI.labels[section..'.'..id]=value end
function UI.SetButtonLabel(section,id,value)UI.labels[section..'.'..id]=value end
function UI.SetButtonEnabled(section,id,value)UI.enabled[section..'.'..id]=value end
function UI.SetOptions(section,id,options,value)UI.options[section..'.'..id]=options;UI.Set(section,id,value)end
function UI.Close()UI.open=false end
function UI.IsOpen()return UI.open end
function UI.OnOpen(cb)UI.onOpen=cb end
function UI.Open()UI.open=true;UI.onOpen()end
local function callback(section,id,method,...)
 for _,item in ipairs(UI.sections[section].items)do
  if item.id==id then return item[method](...)end
 end
 error('missing menu control '..id)
end
local damageHook
Key={F8=119,ESCAPE=27,LEFT_MOUSE_BUTTON=1}
RegisterKeyBind=function()end
RegisterHook=function(_,cb)damageHook=cb;return 1,2 end
LoopInGameThreadWithDelay=function()end
ExecuteInGameThread=function(cb)cb()end
dofile=function(path)
 if path:match('/adapter.lua$')then return A end
 if path:match('/music.lua$')then return {exclude=function()end}end
 if path:match('/vendor/ModMenu.lua$')then return UI end
 if path:match('/segments.lua$')then
  local module=realDofile(path);local make=module.new
  module.new=function(path,codec)archivePath=path;return make(path,codec,fs)end
  return module
 end
 if path:match('/i18n.lua$')then
  local module=realDofile(path);local make=module.new
  module.new=function(path)languagePath=path;return make(path,fs)end
  return module
 end
 return realDofile(path)
end
local mod=realDofile(root..'/PBZTrainingDummy/Scripts/runtime.lua')
UI.Open();assert(UI.Get('dummy','target')=='gold' and UI.Get('dummy','noAggro')==true)
callback('dummy','spawn','onClick');local first=mod.actor();assert(first and not UI.enabled['dummy.start'])
now=1.1;mod.tick();assert(UI.enabled['stats.reset'])
UI.Set('dummy','maxHP',25000);callback('dummy','applyHP','onClick');assert(first.max==25000 and first.hp==25000)
local function hit(target,amount,shachiDamage,source)
 local p=obj('payload');p.TargetActor=target;p.amount=amount;p.shachiDamage=shachiDamage;p.source=source
 damageHook({get=function()return {GetAvatarActorFromActorInfo=function()return target end}end},
  {get=function()return {OptionalObject=p}end})
end
now=2;first.hp=1;hit(first,30000)
assert(mod.state.total==30000 and mod.state.refills==1 and first.hp==25000)
hit(obj('unrelated'),99999);assert(mod.state.events==1)
now=4;mod.tick();assert(UI.labels['stats.average']:find('15000.00',1,true))
assert(UI.labels['stats.recent']:find('6000.00',1,true))
callback('dummy','noAggro','onChange',false);assert(not mod.settings.noAggro)
UI.Set('dummy','maxHP',0);callback('dummy','applyHP','onClick');assert(first.max==25000 and mod.state.total==30000)
UI.Set('dummy','maxHP',25000)
now=5;callback('dummy','remove','onClick');assert(not first.valid and not mod.actor())
now=50;UI.Open();assert(UI.labels['stats.average']:find('10000.00',1,true))
callback('dummy','target','onChange','spear');assert(mod.settings.target=='spear' and mod.settings.mode=='hold')
assert(UI.labels['stats.average']:find('10000.00',1,true),'Type change without actor preserves frozen DPS')
UI.Set('stats','name','金面人长刀');callback('stats','save','onClick')
assert(mod.history:get(1).targetId=='gold' and mod.history:get(1).maxHP==25000,
 'Saving after changing selection must retain the original tested target')
assert(mod.state.total==0 and not mod.actor() and fs.files[archivePath])
callback('dummy','spawn','onClick');local second=mod.actor();assert(second.path:find('Spear_Blue',1,true))
assert(mod.state.total==0)
now=52;mod.tick()
callback('dummy','mode','onChange','red');assert(UI.enabled['dummy.start'])
callback('dummy','start','onClick');assert(not UI.IsOpen())
now=52.6;mod.tick();now=52.7;mod.tick();assert(active)
UI.Open();assert(not active and UI.labels['dummy.attackStatus']:find('打开菜单',1,true))
callback('stats','reset','onClick');assert(mod.state.total==0 and second.hp==second.max)
now=60;hit(second,1000);now=62;callback('stats','pause','onClick')
assert(mod.state.paused and UI.labels['stats.pause']=='继续统计')
now=100;second.hp=1;hit(second,9999)
assert(mod.state.total==1000 and mod.state.refills==0 and second.hp==second.max)
mod.tick();assert(UI.labels['stats.average']:find('500.00',1,true))
second.hp=1;mod.tick();assert(mod.state.refills==0 and second.hp==second.max)
callback('stats','pause','onClick');now=102;hit(second,1000)
assert(mod.state.total==2000 and UI.labels['stats.average']:find('500.00',1,true))
UI.Set('stats','name','枪兵长刀');fs.fail=archivePath..'.tmp'
callback('stats','save','onClick')
assert(mod.state.total==2000 and mod.state.paused and #mod.history.rows==1,'Failed save preserves current segment')
fs.fail=nil;callback('stats','save','onClick')
assert(#mod.history.rows==2 and mod.state.total==0 and mod.state.paused)
assert(UI.Get('stats','name')=='' and UI.Get('comparison','b')=='2')
assert(UI.labels['comparison.detailB']:find('枪兵长刀',1,true))
assert(UI.labels['comparison.result']:find('不同',1,true))
hit(second,100);assert(mod.state.total==0,'Next segment stays paused while changing weapons')
UI.Set('dummy','maxHP',30000);callback('dummy','applyHP','onClick');assert(mod.state.paused)
callback('stats','reset','onClick');assert(mod.state.paused and #mod.history.rows==2)
now=120;callback('stats','pause','onClick');now=121;hit(second,300)
assert(UI.labels['stats.average']:find('300.00',1,true),'New segment starts at its first hit')
now=123;UI.Set('stats','name','枪兵双刀');callback('stats','save','onClick')
assert(mod.history:get(3).dps==150 and mod.history:get(3).maxHP==30000)
callback('comparison','delete','onClick');assert(not mod.history:get(3) and #mod.history.rows==2)
assert(UI.Get('comparison','b')=='2')
-- Switching presentation must preserve actor, unsaved inputs, stats, selection and pause state.
UI.Set('stats','name','用户武器名');UI.Set('dummy','maxHP',12345);UI.SetTab('分段对比')
local total,events,rows=mod.state.total,mod.state.events,#mod.history.rows
callback('dummy','language','onChange','en');mod.tick()
assert(mod.language.language=='en' and fs.files[languagePath]=='en\n')
assert(UI.config.title=='Training Arena' and UI.config.toggleHint=='[F8] Toggle menu')
assert(UI.GetTab()=='Compare Runs' and UI.IsOpen() and mod.actor()==second)
assert(UI.Get('stats','name')=='用户武器名' and UI.Get('dummy','maxHP')==12345)
assert(mod.state.total==total and mod.state.events==events and mod.state.paused and #mod.history.rows==rows)
assert(UI.Get('dummy','target')=='spear' and UI.Get('dummy','mode')=='red' and UI.Get('comparison','b')=='2')
assert(UI.labels['stats.pause']=='Resume stats' and UI.labels['stats.phase']:find('Paused',1,true))
assert(UI.labels['comparison.detailB']:find('枪兵长刀',1,true),'User-entered names must remain unchanged')
assert(UI.options['dummy.target'][1].label:find('Spear Thug',1,true))
for _,item in ipairs(UI.sections.comparison.items)do
 if item.id=='delete'then assert(item.confirm.confirmLabel=='Delete')end
end
for _,section in pairs(UI.sections)do
 assert(not section.title:find('[\128-\255]') and not section.tab:find('[\128-\255]'))
 for _,item in ipairs(section.items)do
  if item.label and item.id~='language'and item.type~='label'then
   assert(not item.label:find('[\128-\255]'),'Untranslated menu item: '..item.label)
  end
 end
end
UI.Set('dummy','maxHP',0);callback('dummy','applyHP','onClick')
assert(UI.labels['stats.notice']:find('Target health must be',1,true),'Errors must follow the selected language')
UI.Set('dummy','maxHP',30000)
fs.fail=languagePath..'.tmp';callback('dummy','language','onChange','zh');mod.tick()
assert(mod.language.language=='en' and UI.Get('dummy','language')=='en')
assert(UI.labels['stats.notice']:find('Could not save language setting',1,true))
fs.fail=nil;callback('dummy','language','onChange','zh');mod.tick()
assert(mod.language.language=='zh' and UI.GetTab()=='分段对比' and UI.labels['stats.pause']=='继续统计')
assert(UI.Get('stats','name')=='用户武器名' and mod.actor()==second)
currentWorld='world2';mod.tick();assert(not mod.actor() and not second.valid)
callback('dummy','category','onChange','Puppet')
assert(mod.settings.category=='Puppet' and #UI.options['dummy.target']==4 and mod.settings.mode=='hold')
assert(UI.Get('dummy','target')==mod.settings.target)
callback('dummy','category','onChange','Animal')
assert(mod.settings.target=='dog' and #UI.options['dummy.target']==1)
callback('dummy','target','onChange','spear')
assert(mod.settings.category=='GuaiMian' and #UI.options['dummy.target']==12)
callback('dummy','spawn','onClick');local third=mod.actor();now=125;mod.tick()
player.hp=0;mod.tick();assert(not mod.actor() and not third.valid)
hit(third,100);assert(mod.state.events==0)
-- Boss controls and dual-resource statistics use the real menu callbacks.
player.hp=10000
UI.Open()
callback('dummy','category','onChange','boss')
assert(mod.settings.target=='ahua' and UI.Get('dummy','healthPolicy')=='native')
now=130;callback('dummy','spawn','onClick');local boss=assert(mod.actor())
now=132;mod.tick();assert(UI.enabled['stats.reset'])
UI.Set('dummy','healthPolicy','custom');UI.Set('dummy','shachiPolicy','custom')
UI.Set('dummy','maxHP',40000);UI.Set('dummy','maxShachi',5000)
callback('dummy','applyHP','onClick');assert(boss.max==40000 and boss.shachiMax==5000)
now=133;boss.shachi=4500;hit(boss,0,500,player)
assert(mod.state.events==1 and mod.state.total==0 and mod.state.shachiTotal==500)
assert(UI.labels['stats.shachiTotal']:find('500.00',1,true))
assert(UI.labels['stats.resources']:find('4500 / 5000',1,true))
now=134;callback('stats','pause','onClick');boss.shachi=4700;mod.tick()
hit(boss,100,100,player)
assert(mod.state.shachiTotal==500 and mod.state.total==0)
assert(UI.labels['stats.resources']:find('4700 / 5000',1,true),'Live bar is independent from paused accounting')
callback('stats','pause','onClick')
now=135;hit(player,0,250,boss)
assert(mod.state.shachiTotal==750,'Attacker-side damage can count a parried training target')
UI.Set('stats','name','杀气训练');callback('stats','save','onClick')
local saved=mod.history.rows[#mod.history.rows]
assert(saved.total==0 and saved.shachiTotal==750 and saved.maxShachi==5000)
callback('dummy','noAggro','onChange',true)
callback('dummy','mode','onChange','ai');callback('dummy','start','onClick')
assert(active and not UI.IsOpen())
now=170;mod.tick();assert(active,'Free AI does not use the single-move timeout')
A.distance=function()return 5000 end
now=171;mod.tick();assert(not active and boss.noAggro,'Range stop restores the chosen no-aggro policy')
A.distance=function()return 180 end
callback('dummy','start','onClick');assert(active)
UI.Open();assert(not active,'Opening the menu stops autonomous combat')
boss.shachi=0;callback('stats','reset','onClick');assert(boss.shachi==5000)
UI.Set('dummy','healthPolicy','native');UI.Set('dummy','shachiPolicy','native')
callback('dummy','applyHP','onClick')
assert(boss.max==10000 and boss.shachiMax==3000,'Native mode restores this spawn original maxima')
UI.Set('dummy','maxHP',0);UI.Set('dummy','maxShachi',0)
callback('dummy','applyHP','onClick')
assert(boss.max==10000 and boss.shachiMax==3000,'Native settings ignore invalid unused custom inputs')
callback('dummy','restart','onClick');assert(not boss.valid and mod.actor()~=boss)
now=172;mod.tick();local restarted=mod.actor()
A.ready=function()return false,'等待 Boss 登场'end
callback('dummy','restart','onClick');local pending=mod.actor()
assert(not restarted.valid and pending)
now=190;mod.tick();assert(not pending.valid and not mod.actor(),'Timed-out initialization is reclaimed')
A.ready=function()return true end
now=191;callback('dummy','spawn','onClick');local failed=mod.actor();now=193;mod.tick()
local configure=A.configure
A.configure=function(a)a.shachiMax=123;error('资源恢复未确认，请移除目标')end
callback('dummy','applyHP','onClick')
assert(not failed.valid and not mod.actor(),'Unconfirmed resource rollback removes the target and freezes statistics')
A.configure=configure
now=194;callback('dummy','spawn','onClick');local retained=mod.actor();now=196;mod.tick()
local destroy=A.destroy
A.destroy=function()error('injected destroy failure')end
player.hp=0;mod.tick();player.hp=10000;UI.Open()
assert(mod.actor()==retained and retained.valid and UI.enabled['dummy.remove'],'Failed cleanup remains retryable')
assert(UI.labels['dummy.status']:find('清理失败',1,true),'Player-death status must not hide a cleanup failure')
local beforeId=nextId
callback('dummy','spawn','onClick');assert(nextId==beforeId,'Do not create a replacement before old cleanup succeeds')
A.destroy=destroy;callback('dummy','remove','onClick');assert(not mod.actor()and not retained.valid)
local spawnActor=A.spawn
local partial
A.spawn=function(p,t,path,profile,onCreated)
 local a,c=spawnActor(p,t,path,profile);partial=a;onCreated(a,c);error('injected entrance failure')
end
callback('dummy','spawn','onClick')
assert(partial and not partial.valid and not mod.actor(),'Registered roots are reclaimed when Finish/entrance throws')
A.spawn=spawnActor
-- Timed DPS controls: first-hit start, exact deadline, saved result and repeat runs.
now=200;callback('dummy','spawn','onClick');local timed=assert(mod.actor());now=202;mod.tick()
UI.Set('stats','testDuration',5);callback('stats','beginTest','onClick')
assert(mod.state.testDuration==5 and not mod.state.started and not mod.state.paused)
now=210;mod.tick();assert(UI.labels['stats.countdown']:find('等待首次命中',1,true))
now=211;hit(timed,1000,500,player)
now=213;hit(timed,500,0,player)
now=216;hit(timed,99999,99999,player)
assert(mod.state.completed and mod.state.total==1500 and mod.state.shachiTotal==500)
assert(UI.labels['stats.average']:find('300.00',1,true)and not UI.enabled['stats.pause'])
assert(UI.labels['stats.countdown']:find('结束',1,true))
local refills=mod.state.refills
now=300;timed.hp=1;mod.tick()
assert(timed.hp==timed.max and mod.state.refills==refills,'Post-deadline healing does not change frozen statistics')
UI.Set('stats','name','5s DPS');callback('stats','save','onClick')
local five=mod.history.rows[#mod.history.rows]
assert(five.testDuration==5 and five.timerCompleted and five.seconds==5 and five.dps==300)
assert(mod.state.paused and not mod.state.completed,'Saving arms a separate paused next run')
UI.Set('stats','testDuration',10);callback('stats','beginTest','onClick')
now=301;hit(timed,0,100,player);now=302;callback('stats','pause','onClick')
now=350;mod.tick();assert(UI.labels['stats.countdown']:find('9.0',1,true))
callback('stats','pause','onClick')
now=359;mod.tick();assert(mod.state.completed and mod.state.total==0 and mod.state.shachiTotal==100)
UI.Set('stats','name','10s Shachi');callback('stats','save','onClick')
local ten=mod.history.rows[#mod.history.rows]
assert(ten.seconds==10 and ten.shachiDps==10 and ten.timerCompleted)
UI.Set('stats','testDuration',30);callback('stats','beginTest','onClick')
now=400;hit(timed,900,300,player);now=432;mod.tick()
assert(mod.state.completed and UI.labels['stats.average']:find('30.00',1,true))
UI.Set('stats','testDuration',0);callback('stats','beginTest','onClick')
now=500;hit(timed,1000,100,player);now=700;mod.tick()
assert(not mod.state.completed and UI.labels['stats.countdown']=='当前计时：不限时')
callback('dummy','language','onChange','en');mod.tick()
assert(UI.labels['stats.countdown']=='Current timer: unlimited'and UI.Get('stats','testDuration')==0)
for _,item in ipairs(UI.sections.stats.items)do
 if item.id=='testDuration'or item.id=='beginTest'then
  assert(not item.label:find('[\128-\255]'),'Timer control must be translated: '..item.label)
 end
end
dofile=realDofile
print('PASS: real menu callbacks; health/DPS; pause/resume; saved metadata; failed-save retention; next-segment pause; comparisons/delete; lifecycle cleanup')
