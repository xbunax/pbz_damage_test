-- Exercise real menu callbacks, accounting, and lifecycle with an isolated engine adapter.
local root=arg[1]
local realDofile=dofile
package.loaded['PBZTrainingDummy.UEHelpers']={}
realDofile(root..'/PBZTrainingDummy/Scripts/vendor/ModMenu.lua')
local fs=realDofile(root..'/tests/memory_fs.lua')
local archivePath,languagePath
local now,currentWorld,playerAlive=0,'world1',true
local function obj(id)
 return {id=id,valid=true,hp=10000,max=10000,GetAddress=function(s)return s.id end,
  GetFullName=function(s)return s.id end,GetClass=function()return {GetFName=function()
   return {ToString=function()return 'DamageTakenPayload'end}end}end}
end
local player=obj('player');local nextId=0
local active=false
local A={valid=function(o)return o and o.valid end,player=function()return playerAlive and player or nil end,
 now=function()return now end,world=function()return currentWorld end,
 position=function(_,_,path)return {},path end,
 spawn=function(_,_,path)nextId=nextId+1;local a=obj('dummy'..nextId);a.path=path;return a,{actor=a,tags={},noAggro=false}end,
 configure=function(a,hp)a.hp=hp;a.max=hp end,health=function(a)return a.hp,a.max end,
 heal=function(a)a.hp=a.max end,destroy=function(a)if a then a.valid=false end end,
 hold=function()active=false end,release=function()end,clearAggro=function()end,
 setNoAggro=function(c,_,on)c.noAggro=on end,hasSkill=function()return true end,
 skillActive=function()return active end,busy=function()return false end,
 distance=function()return 180 end,aim=function()end,attack=function()active=true;return true end,
 damage=function(p)return p.amount end,damageHook='test-damage'}
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
local function hit(target,amount)
 local p=obj('payload');p.TargetActor=target;p.amount=amount
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
assert(UI.config.title=='Damage Test Dummy' and UI.config.toggleHint=='[F8] Toggle menu')
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
dofile=realDofile
print('PASS: real menu callbacks; health/DPS; pause/resume; saved metadata; failed-save retention; next-segment pause; comparisons/delete; lifecycle cleanup')
