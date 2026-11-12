package.loaded['PBZTrainingDummy.UEHelpers']={}
local function descriptor(name)return {AttributeName={ToString=function()return name end}}end
local names={'Health_Min','Health_Max','Health','Shachi_Max','Shachi'}
local desc={};for _,name in ipairs(names)do desc[name]=descriptor(name)end
local values={Health_Min=0,Health_Max=1000,Health=400,Shachi_Max=500,Shachi=100}
local actor={AttributeSetBase={}}
for name,value in pairs(values)do actor.AttributeSetBase[name]={CurrentValue=value}end
local writes,fail,missing=0,nil,false
local preserved={ForEach=function(_,callback)
 callback({get=function()return desc.Health end},{get=function()return desc.Health_Max end})
 if not missing then callback({get=function()return desc.Shachi end},{get=function()return desc.Shachi_Max end})end
end}
local cfg={['Mechanic Config']={['Health Attribute']=desc.Health,['Percentage Preserved Attributes']=preserved}}
LoadAsset=function(path)
 if path:find('GlobalConfig_Combined_Normal',1,true)then return cfg end
 assert(path:find('GE_LockHealth',1,true))
 return {GetCDO=function()return {Modifiers={{Attribute=desc.Health_Min}}}end}
end
StaticFindObject=function(path)
 assert(path=='/Script/SGameAttributes.Default__AttributeUtils')
 return {ModifyCharacterAttributeValue=function(_,a,attribute,op,value)
  assert(a==actor and op==3)
  local name=attribute.AttributeName:ToString()
  assert(attribute==desc[name],'Keep the exact asset-backed descriptor')
  writes=writes+1
  if fail==name then fail=nil;error('injected write failure')end
  a.AttributeSetBase[name].CurrentValue=value
  if name=='Health_Max'then a.AttributeSetBase.Health.CurrentValue=math.min(value,a.AttributeSetBase.Health.CurrentValue)end
  if name=='Shachi_Max'then a.AttributeSetBase.Shachi.CurrentValue=math.min(value,a.AttributeSetBase.Shachi.CurrentValue)end
 end}
end
local A=dofile(arg[1]..'/PBZTrainingDummy/Scripts/adapter.lua')
A.configure(actor,10000,3000)
assert(select(2,A.health(actor))==10000 and A.health(actor)==10000)
assert(select(2,A.shachi(actor))==3000 and A.shachi(actor)==3000)
assert(actor.AttributeSetBase.Health_Min.CurrentValue==1)
actor.AttributeSetBase.Health.CurrentValue=4;actor.AttributeSetBase.Shachi.CurrentValue=88
A.heal(actor);assert(A.health(actor)==10000 and A.shachi(actor)==88,'HP refills never refill Sha-Chi')
A.restoreShachi(actor);assert(A.shachi(actor)==3000)
A.configure(actor,nil,nil);assert(select(2,A.health(actor))==10000 and select(2,A.shachi(actor))==3000)
local count=writes
for _,n in ipairs({0,0/0,math.huge,10000001})do assert(not pcall(A.configure,actor,10000,n))end
assert(writes==count,'Reject invalid values before mutating any attribute')
missing=true;assert(not pcall(A.configure,actor,5000,2000)and writes==count,'Resolve every descriptor before writes')
missing=false
actor.AttributeSetBase.Health.CurrentValue=600;actor.AttributeSetBase.Shachi.CurrentValue=120
local before={};for name,field in pairs(actor.AttributeSetBase)do before[name]=field.CurrentValue end
fail='Shachi'
assert(not pcall(A.configure,actor,1500,1000))
for name,value in pairs(before)do assert(actor.AttributeSetBase[name].CurrentValue==value,'Rollback must restore '..name)end
actor.AttributeSetBase.Health_Min.CurrentValue=500
A.configure(actor,2000,1000)
assert(actor.AttributeSetBase.Health_Min.CurrentValue==500,'Do not weaken a native Boss health floor')
assert(not pcall(A.configure,actor,400,1000),'A custom cap must exceed the native health floor')
A.configure(actor,20000000,20000000,{healthNative=true,shachiNative=true})
assert(select(2,A.health(actor))==20000000 and select(2,A.shachi(actor))==20000000,
 'Preserving a native cap is not limited by the custom-input bounds')
print('PASS: independent HP/Sha-Chi limits, remote descriptors, native maxima, HP-only refill, read-back and transactional rollback')
