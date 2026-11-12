package.loaded['PBZTrainingDummy.UEHelpers']={}
FName=function(s)return s end
local path='/SGameAI/FunctionLibrary/BP_SGameAIFunctionLibrary.BP_SGameAIFunctionLibrary_C'
local clock,busy,ground,blocked,finishFails=0,false,true,false,false
local calls={}
local function valid()return true end
local world={GetAddress=function()return 1 end}
local asc={IsValid=valid,GetGameplayTagCount=function(_,tag)
 assert(tag.TagName=='CharacterState.Space.Ground');return ground and 1 or 0
end}
local component={IsValid=valid,StopAI=function()calls[#calls+1]='stop'end,
 StartAI=function()calls[#calls+1]='start'end}
local controller={IsValid=valid,SGameAIComponent=component,K2_DestroyActor=function()calls[#calls+1]='destroy controller'end}
local spawned={IsValid=valid,GetWorld=function()return world end,AbilitySystemComponent=asc,Controller=controller,
 AttributeSetBase={Health={CurrentValue=1000},Health_Max={CurrentValue=1000},Shachi={CurrentValue=300},Shachi_Max={CurrentValue=300}},
 K2_DestroyActor=function()calls[#calls+1]='destroy actor'end}
local native={IsValid=valid}
function native:SpawnAIDefered(cls,t,spawner,p)
 assert(spawner==nil and p==player);calls[#calls+1]='defer';return spawned
end
function native:FinishSpawnAIDefered(a,t,p)
 assert(a==spawned and p==player);calls[#calls+1]='finish';if finishFails then error('finish failed')end
end
function native:ActivateAI(a,p)assert(a==spawned and p==player);calls[#calls+1]='entrance'end
local capsule={GetScaledCapsuleHalfHeight=function()return 100 end,GetScaledCapsuleRadius=function()return 45 end}
local cls={IsValid=valid,GetCDO=function()return {CapsuleComponent=capsule}end}
LoadAsset=function(p)
 if p==path then return {IsValid=valid,GetCDO=function()return native end}end
 assert(p=='boss-class');return cls
end
StaticFindObject=function(p)
 if p=='/Script/Engine.Default__GameplayStatics'then return {GetTimeSeconds=function()return clock end}end
 if p=='/Script/SGameAI.Default__SGameAIStateUtils'then return {IsActivatingActionAbility=function()return busy end}end
 if p=='/Script/Engine.Default__KismetMathLibrary'then return {MakeTransform=function(_,position,rotation,scale)return {Translation=position}end}end
 if p=='/Script/Engine.Default__KismetSystemLibrary'then return {
  LineTraceSingle=function(_,p,start,finish,channel,complex,ignore,debug,hit)
   assert(start.X==600 and finish.X==600)
   hit.ImpactPoint={X=600,Y=0,Z=0};hit.ImpactNormal={Z=1};return true
  end,
  CapsuleTraceSingle=function(_,p,start,finish,radius,half)
   assert(start.X==600 and start.Z==103 and radius==45 and half==100);return blocked
  end,
 }end
 error('Unexpected library '..p)
end
player={IsValid=valid,GetWorld=function()return world end,K2_GetActorLocation=function()return {X=0,Y=0,Z=100}end,
 GetActorForwardVector=function()return {X=1,Y=0,Z=0}end,K2_GetActorRotation=function()return {Yaw=0}end}
local A=dofile(arg[1]..'/PBZTrainingDummy/Scripts/adapter.lua')
local noAggro=A.setNoAggro
A.setNoAggro=function(c,p,on)
 assert(p==player and on==true);calls[#calls+1]='no aggro';c.noAggro=true
end
local profile={boss=true,nativeSpawn=true,spawnDistance=600}
local t,cclass=A.position(player,nil,'boss-class',profile)
assert(t.Translation.X==600 and cclass==cls)
blocked=true;assert(A.position(player,nil,'boss-class',profile)==nil);blocked=false
local actor,c=A.spawn(player,t,cls,profile)
assert(actor==spawned and c.nativeSpawn and c.profile==profile)
assert(table.concat(calls,',')=='defer,finish,no aggro,entrance','Entrance stays neutral without canceling its action')
assert(not A.ready(c,player));clock=.6;assert(A.ready(c,player))
spawned.bHidden=true;assert(not A.ready(c,player));spawned.bHidden=false
clock=1;assert(not A.ready(c,player));clock=1.6;assert(A.ready(c,player))
busy=true;assert(not A.ready(c,player));busy=false
ground=false;assert(not A.ready(c,player));ground=true
clock=2;assert(not A.ready(c,player));clock=2.6;assert(A.ready(c,player))
local order={}
A.setNoAggro=function(control,p,on)assert(control==c and p==player and on==false);order[#order+1]='aggro'end
A.release=function(control,p)assert(control==c and p==player);order[#order+1]='release'end
A.hold=function()order[#order+1]='hold'end
component.StartAI=function()order[#order+1]='start'end
A.startAI(c,player);assert(table.concat(order,',')=='aggro,release,start')
component.StartAI=function()error('start failed')end
assert(not pcall(A.startAI,c,player)and order[#order]=='hold','An AI start error returns the target to hold')
calls={};finishFails=true
assert(not pcall(A.spawn,player,t,cls,profile))
assert(table.concat(calls,',')=='defer,finish,destroy actor,destroy controller','Failed initialization cleans the single created actor and controller')
calls={};local registered
assert(not pcall(A.spawn,player,t,cls,profile,function(a,control)
 registered={actor=a,control=control};calls[#calls+1]='registered'
end))
assert(registered.actor==spawned and table.concat(calls,',')=='defer,registered,finish',
 'A registered caller keeps the root alive so it can reclaim helpers before destroying the root')
A.destroy(registered.actor,registered.control)
local alive,controllerAlive,failController=true,true,true
local retryController={IsValid=function()return controllerAlive end,K2_DestroyActor=function()
 if failController then error('controller delete failed')end;controllerAlive=false
end}
local retryActor={IsValid=function()return alive end,Controller=retryController,K2_DestroyActor=function()alive=false end}
local retryControl={}
assert(not pcall(A.destroy,retryActor,retryControl)and not alive and controllerAlive)
failController=false;A.destroy(retryActor,retryControl)
assert(not controllerAlive,'A cached controller can be reclaimed after its Actor is already invalid')
print('PASS: Boss capsule clearance, native entrance order, stable readiness, explicit AI restart and initialization cleanup')
