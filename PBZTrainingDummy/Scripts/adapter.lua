-- PBZ Steam CL301524 / UE4SS 3.0.1-1183. All methods run on the game thread.
local H=require('PBZTrainingDummy.UEHelpers')
local M={}
local CLASS='/Game/RenewalContent/Actors/Mobs/Normal/BP_Monster_GoldMaskMan_Dummy_OnlyHit.BP_Monster_GoldMaskMan_Dummy_OnlyHit_C'
local CONFIG='/PBZCombatAsset/Config/GlobalConfig_Combined_Normal.GlobalConfig_Combined_Normal'
local EFFECT='/PBZCombatAsset/Prototypes/GameplayEffects/'
function M.valid(o) return o~=nil and o:IsValid() end
function M.player()
    local pc=H.GetPlayerController()
    if not M.valid(pc) then return nil end
    local p=pc.Pawn
    if not M.valid(p) or not p:IsA('/Script/ProjectPBZ.PBZCharacter') then return nil end
    return p
end
local function lib(n) return StaticFindObject('/Script/'..n) end
function M.now(p) return lib('Engine.Default__GameplayStatics'):GetTimeSeconds(p) end
function M.world(p) return p:GetWorld():GetAddress() end
function M.position(p,old)
    local loc=p:K2_GetActorLocation();local f=p:GetActorForwardVector()
    local x,y=loc.X+f.X*180,loc.Y+f.Y*180
    local hit={};local ignore={p}
    if M.valid(old) then ignore[#ignore+1]=old end
    local ok=lib('Engine.Default__KismetSystemLibrary'):LineTraceSingle(p,
        {X=x,Y=y,Z=loc.Z+100},{X=x,Y=y,Z=loc.Z-300},0,false,ignore,0,hit,true,
        {R=0,G=0,B=0,A=0},{R=0,G=0,B=0,A=0},0)
    if not ok or not hit.ImpactNormal or hit.ImpactNormal.Z<0.65 then
        return nil,'前方没有平坦地面，请换个位置'
    end
    local cls=LoadAsset(CLASS)
    assert(M.valid(cls),'无法加载训练木桩资产')
    local half=cls:GetCDO().CapsuleComponent:GetScaledCapsuleHalfHeight()
    return lib('Engine.Default__KismetMathLibrary'):MakeTransform(
        {X=hit.ImpactPoint.X,Y=hit.ImpactPoint.Y,Z=hit.ImpactPoint.Z+half+3},
        {Pitch=0,Yaw=p:K2_GetActorRotation().Yaw+180,Roll=0},{X=1,Y=1,Z=1}),cls
end
function M.spawn(p,t,cls)
    local gs=lib('Engine.Default__GameplayStatics')
    -- Reflected deferred spawn avoids this UE4SS build's incompatible native UWorld wrapper.
    local a=gs:BeginDeferredActorSpawnFromClass(p,cls,t,2,p,0)
    assert(M.valid(a),'前方空间不足，召唤失败')
    local ok,err=pcall(function()
        a.AutoPossessAI=0
        gs:FinishSpawningActor(a,t,0)
        a:SpawnDefaultController()
        a['Attribute Component']:ReinitializeAttributes()
        local asc=a.AbilitySystemComponent
        asc:BP_ApplyGameplayEffectToSelf(LoadAsset(EFFECT..'GE_AIDisableAction.GE_AIDisableAction_C'),1,asc:MakeEffectContext())
    end)
    if not ok then M.destroy(a);error(err) end
    return a
end
local function attributes()
    local cfg=LoadAsset(CONFIG)
    local health=cfg['Mechanic Config']['Health Attribute']
    local maximum
    cfg['Mechanic Config']['Percentage Preserved Attributes']:ForEach(function(_,v)
        local a=v:get();if a.AttributeName:ToString()=='Health_Max' then maximum=a end
    end)
    local minimum=LoadAsset(EFFECT..'GE_LockHealth.GE_LockHealth_C'):GetCDO().Modifiers[1].Attribute
    assert(maximum,'Health_Max attribute unavailable')
    -- Keep remote UScriptStruct references: returning GameplayAttribute from a UFunction
    -- loses its FieldPathProperty in this UE4SS build and must NOT be passed back.
    return health,maximum,minimum
end
function M.configure(a,maxHP)
    local hp,mx,mn=attributes()
    local au=lib('SGameAttributes.Default__AttributeUtils')
    au:ModifyCharacterAttributeValue(a,mn,3,1)
    au:ModifyCharacterAttributeValue(a,mx,3,maxHP)
    au:ModifyCharacterAttributeValue(a,hp,3,maxHP)
    a:SetDisableMovement(true)
    assert(a.AttributeSetBase.Health_Min.CurrentValue==1,'生命下限设置失败')
end
function M.heal(a)
    local cfg=LoadAsset(CONFIG)
    lib('SGameAttributes.Default__AttributeUtils'):ModifyCharacterAttributeValue(a,
        cfg['Mechanic Config']['Health Attribute'],3,a.AttributeSetBase.Health_Max.CurrentValue)
end
function M.destroy(a)
    if not M.valid(a) then return end
    local controller=a.Controller
    a:K2_DestroyActor()
    if M.valid(controller) then controller:K2_DestroyActor() end
end
function M.health(a) return a.AttributeSetBase.Health.CurrentValue,a.AttributeSetBase.Health_Max.CurrentValue end
function M.damage(payload)
    local total=0
    for key,value in pairs(payload:GetDamageData()) do
        local tag=key:get().TagName:ToString()
        -- Do not mix poise, anger damage or attacker resource gain into HP damage.
        if tag:match('^Damage%.Damage%.Target%.GeneralDamage%.') then
            local v=value:get()
            if type(v)=='number' and v==v and v>0 and v<math.huge then total=total+v end
        end
    end
    return total
end
M.damageHook='/PBZCombatAsset/Prototypes/Abilities/GA_CommonUtilitiesPassive.GA_CommonUtilitiesPassive_C:OnTaken'
return M
