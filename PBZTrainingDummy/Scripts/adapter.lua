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
function M.position(p,old,classPath)
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
    local cls=LoadAsset(classPath or CLASS)
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
    local control={actor=a,tags={},noAggro=false}
    local ok,err=pcall(function()
        a.AutoPossessAI=0
        gs:FinishSpawningActor(a,t,0)
        a:SpawnDefaultController()
        a['Attribute Component']:ReinitializeAttributes()
        M.hold(control)
    end)
    if not ok then M.destroy(a);error(err) end
    return a,control
end
local function tag(name)return {TagName=FName(name)}end
local function ai(a)
    local controller=a.Controller
    assert(M.valid(controller),'训练目标控制器未就绪')
    local component=controller.SGameAIComponent
    assert(M.valid(component),'训练目标 AI 组件未就绪')
    return component
end
function M.cancelActions(a)
    lib('SGameUtils.Default__AbilityUtils'):CancelAbilitiesByTag(a.AbilitySystemComponent,
        {GameplayTags={tag('Ability.Action')}},{GameplayTags={}})
end
local function lockActive(c)
    return c.lock~=nil and lib('GameplayAbilities.Default__AbilitySystemBlueprintLibrary'):
        IsActiveGameplayEffectHandleActive(c.lock)
end
function M.hold(c)
    local a=c.actor
    if not M.valid(a)then return end
    ai(a):StopAI()
    M.cancelActions(a)
    if not lockActive(c)then
        c.lock=nil
        local asc=a.AbilitySystemComponent
        local handle=asc:BP_ApplyGameplayEffectToSelf(LoadAsset(EFFECT..'GE_AIDisableAction.GE_AIDisableAction_C'),1,asc:MakeEffectContext())
        assert(handle and handle.Handle and handle.Handle~=-1,'无法限制训练目标行动')
        -- Keep a value copy rather than a UFunction return buffer.
        c.lock={Handle=handle.Handle,bPassedFiltersAndWasExecuted=handle.bPassedFiltersAndWasExecuted}
        assert(lockActive(c),'木桩行动限制未生效')
    end
    a:SetDisableMovement(true)
end
function M.release(c,p)
    if c.lock then
        if lockActive(c)then
            c.actor.AbilitySystemComponent:RemoveActiveGameplayEffect(c.lock,-1)
            assert(not lockActive(c),'无法解除木桩行动限制')
        end
        c.lock=nil
    end
    c.actor:SetDisableMovement(false)
    M.aim(c,p)
end
function M.aim(c,p)
    local a=c.actor;local component=ai(a)
    assert(M.valid(component.BlackboardComponent),'训练目标黑板未就绪')
    lib('SGameAI.Default__SGameAIFunctionLibrary'):SetValueAsObjectByTag(
        component.BlackboardComponent,tag('AI.BlackboardKey.Object.TargetActor'),p)
    local from,to=a:K2_GetActorLocation(),p:K2_GetActorLocation()
    local rotation=lib('Engine.Default__KismetMathLibrary'):FindLookAtRotation(from,to)
    a:K2_SetActorRotation({Pitch=0,Yaw=rotation.Yaw,Roll=0},false)
end
function M.distance(a,p)
    local x,y=a:K2_GetActorLocation(),p:K2_GetActorLocation()
    return math.sqrt((x.X-y.X)^2+(x.Y-y.Y)^2+(x.Z-y.Z)^2)
end
local function skillSpec(a,name,callback)
    a.AbilitySystemComponent.ActivatableAbilities.Items:ForEach(function(_,value)
        local spec=value:get()
        if M.valid(spec.Ability) and spec.Ability:GetClass():GetFName():ToString()==name then callback(spec)end
    end)
end
function M.hasSkill(a,name)
    local found=false;skillSpec(a,name,function()found=true end);return found
end
function M.skillActive(a,name)
    local active=false;skillSpec(a,name,function(s)if s.ActiveCount>0 then active=true end end);return active
end
function M.busy(a)return lib('SGameAI.Default__SGameAIStateUtils'):IsActivatingActionAbility(a)end
function M.recoveryReason(a)
    if a.AbilitySystemComponent:GetGameplayTagCount(tag('CharacterState.Space.Ground'))<=0 then return '等待落地' end
end
local function failureReason(a)
    local ok,result=pcall(function()
        local container=lib('SGameUtils.Default__AbilityUtils'):GetActivateAbilityFailureTags(a.AbilitySystemComponent)
        local names={}
        container.GameplayTags:ForEach(function(_,v)names[#names+1]=v:get().TagName:ToString()end)
        return #names>0 and table.concat(names,', ') or '受击或冷却等暂时限制'
    end)
    return ok and result or '技能暂时受限'
end
function M.attack(a,name)
    local cls
    skillSpec(a,name,function(s)cls=s.Ability:GetClass()end)
    if not M.valid(cls)then return false,'目标未拥有此技能' end
    local activated=a.AbilitySystemComponent:TryActivateAbilityByClass(cls,false)
    return activated,not activated and failureReason(a) or nil
end
local function hatred(a)
    return a:GetComponentByClass(StaticFindObject('/SGameAI/Tools/Hatred/BP_SGameHatredManagerComponent.BP_SGameHatredManagerComponent_C'))
end
function M.clearAggro(a,p)
    if not M.valid(a)or not M.valid(p)then return end
    for _,pair in ipairs({{a,p},{p,a}})do
        local h=hatred(pair[1]);local other=pair[2]
        if M.valid(h)then
            h:RemoveActorFromHatredList(other);h:RemoveActorFromBeHatredList(other);h:RemoveFromPendingBeHatredList(other)
        end
    end
end
local NO_AGGRO={'AI.Hatred.CanNotBeHatred','AI.Hatred.CanNotHatredOthers'}
function M.setNoAggro(c,p,on)
    local u=lib('SGameUtils.Default__AbilityUtils')
    for _,name in ipairs(NO_AGGRO)do
        if on and not c.tags[name]then
            u:AddLooseGameplayTag(c.actor,tag(name),false);c.tags[name]=true
        elseif not on and c.tags[name]then
            u:RemoveLooseGameplayTag(c.actor,tag(name),false);c.tags[name]=nil
        end
    end
    c.noAggro=on
    if on then M.clearAggro(c.actor,p)
    elseif M.valid(p)then
        local h=hatred(c.actor)
        assert(M.valid(h),'训练目标仇恨组件未就绪')
        h:AddActorToHatredList(p,{})
        local found=false
        h.HatredList:ForEach(function(_,v)
            local other=v:get()
            if M.valid(other)and other:GetAddress()==p:GetAddress()then found=true end
        end)
        assert(found,'游戏未恢复木桩仇恨，请保持关闭仇恨模式')
    end
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
    assert(type(maxHP)=='number' and maxHP==maxHP and maxHP>=10 and maxHP<=10000000,'无效目标血量')
    local hp,mx,mn=attributes()
    local au=lib('SGameAttributes.Default__AttributeUtils')
    au:ModifyCharacterAttributeValue(a,mn,3,1)
    au:ModifyCharacterAttributeValue(a,mx,3,maxHP)
    au:ModifyCharacterAttributeValue(a,hp,3,maxHP)
    a:SetDisableMovement(true)
    assert(a.AttributeSetBase.Health_Min.CurrentValue==1,'生命下限设置失败')
    assert(math.abs(a.AttributeSetBase.Health_Max.CurrentValue-maxHP)<1,'目标最大生命设置失败')
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
