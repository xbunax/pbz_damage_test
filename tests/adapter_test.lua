package.loaded['PBZTrainingDummy.UEHelpers']={}
local A=dofile(arg[1]..'/PBZTrainingDummy/Scripts/adapter.lua')
local values={}
local function damage(tag,value)
 local k={get=function()return {TagName={ToString=function()return tag end}}end}
 values[k]={get=function()return value end}
end
damage('Damage.Damage.Target.GeneralDamage.Physical',606.52801513672)
damage('Damage.Damage.Target.GeneralDamage.Fire',12)
damage('Damage.Damage.Target.AngerDamage.Normal',480)
damage('Damage.Damage.Target.PoiseDamage',100)
damage('Damage.Damage.Attacker.UltimateChargeRegen',3)
damage('Damage.Damage.Target.GeneralDamage.Invalid',0/0)
damage('Damage.Damage.Target.GeneralDamage.Infinite',math.huge)
damage('Damage.Damage.Target.GeneralDamage.Heal',-20)
local total=A.damage({GetDamageData=function()return values end})
assert(math.abs(total-618.52801513672)<1e-8)
print('PASS: full HP damage with overkill, excludes poise/anger/resources/non-finite values')
