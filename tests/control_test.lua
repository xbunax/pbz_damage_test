package.loaded['PBZTrainingDummy.UEHelpers']={}
FName=function(s)return s end
local tags,otherTags={}, {['existing']=2}
local function actor(id)
 return {IsValid=function()return true end,GetAddress=function()return id end}
end
local dummy,player,enemy=actor(1),actor(2),actor(3)
local function arr(values)
 return {ForEach=function(_,fn)for i,v in ipairs(values)do fn(i,{get=function()return v end})end end}
end
local function manager(hated,attackers)
 local h={hated=hated,attackers=attackers,pending={}}
 local function remove(t,o)for i=#t,1,-1 do if t[i]==o then table.remove(t,i)end end end
 function h:IsValid()return true end
 function h:RemoveActorFromHatredList(o)remove(self.hated,o)end
 function h:RemoveActorFromBeHatredList(o)remove(self.attackers,o)end
 function h:RemoveFromPendingBeHatredList(o)self.pending[o]=nil end
 function h:AddActorToHatredList(o,out)
  assert(type(out)=='table','UE4SS requires a table for the Blueprint bool Out parameter')
  self.hated[#self.hated+1]=o
  self.HatredList=arr(self.hated)
 end
 return h
end
local dh,ph=manager({player},{}),manager({enemy},{dummy,enemy})
dummy.GetComponentByClass=function()return dh end
player.GetComponentByClass=function()return ph end
local U={
 AddLooseGameplayTag=function(_,a,t)assert(a==dummy);tags[t.TagName]=(tags[t.TagName]or 0)+1 end,
 RemoveLooseGameplayTag=function(_,a,t)assert(a==dummy);tags[t.TagName]=tags[t.TagName]-1 end,
}
StaticFindObject=function(path)if path=='/Script/SGameUtils.Default__AbilityUtils'then return U end;return {}end
local A=dofile(arg[1]..'/PBZTrainingDummy/Scripts/adapter.lua')
local c={actor=dummy,tags={},noAggro=false}
tags['AI.Hatred.CanNotBeHatred']=2 -- Existing tag counts belong to the game/other effects.
A.setNoAggro(c,player,true);A.setNoAggro(c,player,true)
assert(tags['AI.Hatred.CanNotBeHatred']==3 and tags['AI.Hatred.CanNotHatredOthers']==1)
assert(#dh.hated==0 and #ph.attackers==1 and ph.attackers[1]==enemy and ph.hated[1]==enemy)
A.setNoAggro(c,player,false)
assert(tags['AI.Hatred.CanNotBeHatred']==2 and tags['AI.Hatred.CanNotHatredOthers']==0)
assert(dh.hated[1]==player and otherTags.existing==2)
print('PASS: own tag counts are idempotent/restored; unrelated enemy hatred preserved; aggro can be re-enabled')
