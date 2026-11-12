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
local payload={GetDamageData=function()return values end}
local total,shachi=A.damage(payload)
assert(math.abs(total-618.52801513672)<1e-8)
assert(shachi==480)
damage('Damage.Damage.Attacker.AngerDamage.Normal',77)
damage('Damage.Damage.Target.AngerDamage.Invalid',0/0)
damage('Damage.Damage.Target.AngerDamage.Heal',-30)
damage('Damage.Damage.Target.AngerDamageExtra.Normal',999)
local attackerHP,attackerShachi=A.damage(payload,'Attacker')
assert(attackerHP==0 and attackerShachi==77)
assert(select(2,A.damage(payload))==480,'Branches must not leak into one another')
assert(not pcall(A.damage,payload,'Other'))
local owner={IsValid=function()return true end}
assert(A.damageSource({GetDamageSourceOwner=function()return owner end})==owner)
assert(A.damageSource({GetDamageSourceOwner=function()error('not supported')end})==nil)
print('PASS: separate HP/Sha-Chi event channels, source ownership, branch isolation and non-finite/resource/poise exclusion')
