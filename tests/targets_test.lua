local T=dofile(arg[1]..'/PBZTrainingDummy/Scripts/targets.lua')
assert(#T.options()==28 and #T.modes('gold')==1)
assert(#T.categories()==6 and #T.options('training')==1)
assert(#T.options('GuaiMian')==12 and #T.options('DragonModified')==7)
assert(#T.options('Puppet')==4 and #T.options('Animal')==1)
assert(#T.options('HumanMaster')==0,'Do not fill a category with bosses merely to make it nonempty')
local seen={}
for _,category in ipairs(T.categories())do
 for _,option in ipairs(T.options(category.value))do
  assert(T.get(option.value).category==category.value and not seen[option.value])
  seen[option.value]=true
 end
end
for _,row in ipairs(T.list)do assert(seen[row.id],'Every target must be reachable through its category')end
assert(#T.modes('spear')==2 and T.get('spear').skills.red and not T.get('spear').skills.blue)
assert(#T.modes('sword')==2 and T.get('sword').skills.blue and not T.get('sword').skills.red)
assert(not pcall(T.get,'boss'))
assert(#T.options('boss')==3)
for _,id in ipairs({'ahua','moyuan','biyuan'})do
 local boss=T.get(id)
 assert(boss.boss and boss.nativeSpawn and boss.category=='boss' and boss.spawnDistance>=600)
 assert(#T.modes(id)==2 and T.modes(id)[2].value=='ai' and next(boss.skills)==nil)
 assert(not boss.class:find('LongZhu',1,true),'Do not include the story-bound MoYuan variant')
end
assert(not pcall(T.get,'leidang')and not pcall(T.get,'lengtu'))
assert(T.get('spear').label:find('红光',1,true) and T.get('sword').label:find('蓝光',1,true))
assert(T.description('gold')=='训练模式：静止受击')
assert(T.description('spear'):find('红光循环',1,true) and not T.description('spear'):find('蓝光',1,true))
assert(T.health(10)==10 and T.health(10000000)==10000000 and T.health(123.9)==123)
for _,n in ipairs({0,9,10000001,math.huge,-math.huge,0/0,'100'})do assert(not pcall(T.health,n))end
assert(T.interval(0.5)==0.5 and T.interval(30)==30)
assert(not pcall(T.interval,0) and not pcall(T.interval,math.huge))
assert(T.shachi(1)==1 and T.shachi(3000.5)==3000 and T.shachi(10000000)==10000000)
for _,n in ipairs({0,10000001,math.huge,-math.huge,0/0,'100'})do assert(not pcall(T.shachi,n))end
print('PASS: explicit actor/skill whitelist and finite bounded health/interval values')
