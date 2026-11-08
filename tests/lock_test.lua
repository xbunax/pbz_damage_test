package.loaded['PBZTrainingDummy.UEHelpers']={}
local alive,nextId,applies,removes={},0,0,0
local buffer={}
local BP={IsActiveGameplayEffectHandleActive=function(_,h)return alive[h.Handle]==true end}
local U={CancelAbilitiesByTag=function()end}
StaticFindObject=function(path)
 if path=='/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary'then return BP end
 if path=='/Script/SGameUtils.Default__AbilityUtils'then return U end
 return {}
end
LoadAsset=function()return {}end
FName=function(s)return s end
local asc={MakeEffectContext=function()return {}end}
function asc:BP_ApplyGameplayEffectToSelf()
 nextId=nextId+1;applies=applies+1;alive[nextId]=true
 buffer.Handle=nextId;buffer.bPassedFiltersAndWasExecuted=true
 return buffer
end
function asc:RemoveActiveGameplayEffect(h)
 removes=removes+1;alive[h.Handle]=nil;return true
end
local actor={IsValid=function()return true end,AbilitySystemComponent=asc,
 Controller={IsValid=function()return true end,SGameAIComponent={IsValid=function()return true end,StopAI=function()end}},
 SetDisableMovement=function()end}
local A=dofile(arg[1]..'/PBZTrainingDummy/Scripts/adapter.lua')
A.aim=function()end
local c={actor=actor}
A.hold(c);local original=c.lock.Handle
buffer.Handle=9999
assert(c.lock.Handle==original,'Lock handle must not alias the UFunction return buffer')
A.hold(c);assert(applies==1,'Holding twice must not stack locks')
alive[original]=nil -- The game's hit-reaction logic removed this effect.
A.release(c,{});assert(c.lock==nil and removes==0,'An already-expired handle is not a release error')
A.hold(c);local second=c.lock.Handle;alive[second]=nil
A.hold(c);assert(applies==3 and c.lock.Handle~=second,'A stale lock must be replaced when holding again')
alive[12345]=true -- Another effect is never removed.
A.release(c,{});assert(removes==1 and alive[12345])
print('PASS: lock handles copied by value; stale/removed locks handled; repeat hold/release idempotent; unrelated effects preserved')
