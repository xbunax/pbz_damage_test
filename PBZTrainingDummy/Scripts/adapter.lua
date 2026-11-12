-- PBZ Steam CL301524 / UE4SS 3.0.1-1183. All methods run on the game thread.
local H=require('PBZTrainingDummy.UEHelpers')
local M={}
local CLASS='/Game/RenewalContent/Actors/Mobs/Normal/BP_Monster_GoldMaskMan_Dummy_OnlyHit.BP_Monster_GoldMaskMan_Dummy_OnlyHit_C'
local CONFIG='/PBZCombatAsset/Config/GlobalConfig_Combined_Normal.GlobalConfig_Combined_Normal'
local EFFECT='/PBZCombatAsset/Prototypes/GameplayEffects/'
local AI_LIBRARY='/SGameAI/FunctionLibrary/BP_SGameAIFunctionLibrary.BP_SGameAIFunctionLibrary_C'
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
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
function M.position(p,old,classPath,profile)
    profile=profile or {}
    local loc=p:K2_GetActorLocation();local f=p:GetActorForwardVector()
    local distance=profile.spawnDistance or 180
    local x,y=loc.X+f.X*distance,loc.Y+f.Y*distance
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
    local capsule=cls:GetCDO().CapsuleComponent
    local half=capsule:GetScaledCapsuleHalfHeight()
    local center={X=hit.ImpactPoint.X,Y=hit.ImpactPoint.Y,Z=hit.ImpactPoint.Z+half+3}
    if profile.boss then
        -- Check the target's actual capsule, not just a ground point below it.
        local radius=capsule:GetScaledCapsuleRadius()
        assert(finite(radius)and radius>0 and finite(half)and half>=radius,'训练目标碰撞体不可用')
        local blocked=lib('Engine.Default__KismetSystemLibrary'):CapsuleTraceSingle(p,center,
            {X=center.X,Y=center.Y,Z=center.Z+1},radius,half,0,false,ignore,0,{},true,
            {R=0,G=0,B=0,A=0},{R=0,G=0,B=0,A=0},0)
        if blocked then return nil,'Boss 出生点空间不足，请选择开阔地面' end
    end
    return lib('Engine.Default__KismetMathLibrary'):MakeTransform(
        center,
        {Pitch=0,Yaw=p:K2_GetActorRotation().Yaw+180,Roll=0},{X=1,Y=1,Z=1}),cls
end
local function nativeAI()
    local cls=LoadAsset(AI_LIBRARY)
    assert(M.valid(cls),'原生 AI 生成接口不可用')
    local value=cls:GetCDO()
    assert(M.valid(value),'原生 AI 生成接口不可用')
    return value
end
function M.spawn(p,t,cls,profile,onCreated)
    profile=profile or {}
    local gs=profile.nativeSpawn and nativeAI()or lib('Engine.Default__GameplayStatics')
    -- Never retry an uncertain native spawn: it may already have created an actor.
    local a
    if profile.nativeSpawn then a=gs:SpawnAIDefered(cls,t,nil,p)
    else a=gs:BeginDeferredActorSpawnFromClass(p,cls,t,2,p,0)end
    assert(M.valid(a),'前方空间不足，召唤失败')
    local control={actor=a,tags={},noAggro=false,profile=profile,nativeSpawn=profile.nativeSpawn==true}
    local ok,err=pcall(function()
        if onCreated then onCreated(a,control)end
        if profile.nativeSpawn then
            -- Let the game's entrance finish before hold() cancels action abilities.
            gs:FinishSpawnAIDefered(a,t,p)
            M.setNoAggro(control,p,true)
            gs:ActivateAI(a,p)
        else
            a.AutoPossessAI=0
            gs:FinishSpawningActor(a,t,0)
            a:SpawnDefaultController()
            a['Attribute Component']:ReinitializeAttributes()
            M.hold(control)
        end
    end)
    if not ok then
        -- A registered caller owns rollback, including helpers created before an entrance error.
        if onCreated then error(err)end
        local removed,cleanup=pcall(M.destroy,a)
        if not removed then error(tostring(err)..'; cleanup: '..tostring(cleanup))end
        error(err)
    end
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
function M.ready(c,p)
    local ok,reason=pcall(function()
        local a=c.actor
        assert(M.valid(a)and M.valid(p),'玩家或目标不可用')
        assert(M.world(a)==M.world(p),'玩家或目标已切换场景')
        ai(a)
        assert(M.valid(a.AbilitySystemComponent),'训练目标技能组件未就绪')
        local health,maximum=M.health(a)
        local shachi,shachiMax=M.shachi(a)
        assert(finite(health)and health>0 and finite(maximum)and maximum>0 and
            finite(shachi)and shachi>=0 and finite(shachiMax)and shachiMax>0,'训练目标属性未就绪')
        if c.nativeSpawn then
            assert(a.bHidden~=true,'等待 Boss 登场')
            assert(a.AbilitySystemComponent:GetGameplayTagCount(tag('CharacterState.Space.Ground'))>0,'等待落地')
            assert(not M.busy(a),'等待 Boss 登场动作结束')
        end
    end)
    if not ok then
        c.readySince=nil
        return false,tostring(reason):gsub('^.-:%d+: ','')
    end
    if c.nativeSpawn then
        -- Require a stable idle window, rather than a single moment between entrance frames.
        local now=M.now(c.actor)
        c.readySince=c.readySince or now
        if now-c.readySince<0.5 then return false,'等待 Boss 登场' end
    end
    return true
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
function M.startAI(c,p)
    assert(c.profile and c.profile.boss,'当前目标不支持自由对练')
    local ok,err=pcall(function()
        M.setNoAggro(c,p,false)
        M.release(c,p)
        -- Confirmed reflected SGameAIComponent.StartAI() counterpart of StopAI().
        ai(c.actor):StartAI()
    end)
    if not ok then
        pcall(M.hold,c)
        error(err)
    end
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
    local found={Health=health}
    cfg['Mechanic Config']['Percentage Preserved Attributes']:ForEach(function(k,v)
        local a,b=k:get(),v:get()
        local name=b.AttributeName:ToString()
        if name=='Health_Max' or name=='Shachi_Max'then
            found[name]=b
            found[a.AttributeName:ToString()]=a
        end
    end)
    found.Health_Min=LoadAsset(EFFECT..'GE_LockHealth.GE_LockHealth_C'):GetCDO().Modifiers[1].Attribute
    assert(found.Health and found.Health_Max and found.Health_Min and found.Shachi and found.Shachi_Max,
        '生命或杀气属性描述不可用')
    -- Keep remote UScriptStruct references: returning GameplayAttribute from a UFunction
    -- loses its FieldPathProperty in this UE4SS build and must NOT be passed back.
    return found
end
local function attributeValue(a,name)
    local value=a.AttributeSetBase[name].CurrentValue
    assert(finite(value),'训练目标属性未就绪')
    return value
end
local function close(a,b)return finite(a)and math.abs(a-b)<=math.max(0.001,math.abs(b)*0.00001)end
function M.configure(a,maxHP,maxShachi,policy)
    policy=policy or {}
    assert(maxHP==nil or finite(maxHP)and maxHP>1 and (policy.healthNative or maxHP>=10 and maxHP<=10000000),'无效目标血量')
    assert(maxShachi==nil or finite(maxShachi)and maxShachi>0 and (policy.shachiNative or maxShachi>=1 and maxShachi<=10000000),'无效目标杀气')
    local fields={'Health_Max','Shachi_Max','Health_Min','Health','Shachi'}
    local before={}
    for _,field in ipairs(fields)do before[field]=attributeValue(a,field)end
    maxHP=maxHP or before.Health_Max;maxShachi=maxShachi or before.Shachi_Max
    assert(maxHP>1 and maxShachi>0,'训练目标属性未就绪')
    local floor=math.max(1,before.Health_Min)
    assert(maxHP>floor,'生命上限须高于目标原生锁血线')
    -- Resolve every remote descriptor before the first write. Neither value is changed if lookup fails.
    local attr=attributes()
    local au=lib('SGameAttributes.Default__AttributeUtils')
    local function write(field,value)
        au:ModifyCharacterAttributeValue(a,attr[field],3,value)
        assert(close(attributeValue(a,field),value),'资源写入未确认')
    end
    local ok,err=pcall(function()
        write('Health_Min',floor)
        write('Health_Max',maxHP)
        write('Shachi_Max',maxShachi)
        write('Health',maxHP)
        write('Shachi',maxShachi)
    end)
    if not ok then
        -- Maxima first, current values last: restoring a maximum may preserve a percentage or clamp a current.
        local restored=true
        for _,field in ipairs(fields)do
            local wrote=pcall(write,field,before[field]);restored=wrote and restored
        end
        for _,field in ipairs(fields)do
            local read,value=pcall(attributeValue,a,field)
            restored=read and close(value,before[field])and restored
        end
        error((restored and '资源设置失败，已恢复原值' or '资源恢复未确认，请移除目标')..': '..tostring(err))
    end
end
function M.heal(a)
    local cfg=LoadAsset(CONFIG)
    lib('SGameAttributes.Default__AttributeUtils'):ModifyCharacterAttributeValue(a,
        cfg['Mechanic Config']['Health Attribute'],3,a.AttributeSetBase.Health_Max.CurrentValue)
end
function M.restoreShachi(a)
    local attr=attributes()
    local maximum=attributeValue(a,'Shachi_Max')
    lib('SGameAttributes.Default__AttributeUtils'):ModifyCharacterAttributeValue(a,attr.Shachi,3,maximum)
    assert(close(attributeValue(a,'Shachi'),maximum),'杀气恢复未确认')
end
function M.destroy(a,control)
    control=control or {}
    local controller=control.controller
    if M.valid(a)then controller=a.Controller or controller;control.controller=controller end
    local removed,err=true,nil
    if M.valid(a)then removed,err=pcall(function()a:K2_DestroyActor()end)end
    local cleaned,cleanup=true,nil
    if M.valid(controller)then cleaned,cleanup=pcall(function()controller:K2_DestroyActor()end)end
    assert(removed and cleaned,tostring(err or cleanup or '训练目标清理失败'))
end
function M.health(a) return a.AttributeSetBase.Health.CurrentValue,a.AttributeSetBase.Health_Max.CurrentValue end
function M.shachi(a) return a.AttributeSetBase.Shachi.CurrentValue,a.AttributeSetBase.Shachi_Max.CurrentValue end
function M.level(a)
    local ok,value=pcall(function()return a.AttributeSetBase.Level.CurrentValue end)
    if ok and finite(value)and value>=0 then return value end
end
function M.damageSource(payload)
    -- Reflected on DamageTakenPayload; do not unpack an unknown interface representation.
    local ok,owner=pcall(function()return payload:GetDamageSourceOwner()end)
    if ok and M.valid(owner)then return owner end
end
function M.damage(payload,side)
    side=side or 'Target'
    assert(side=='Target' or side=='Attacker','未知伤害作用对象')
    local total,shachi=0,0
    local prefix='Damage.Damage.'..side..'.'
    for key,value in pairs(payload:GetDamageData()) do
        local name=key:get().TagName:ToString()
        local v=value:get()
        if finite(v)and v>0 then
            -- AngerDamage.Normal is present in local payload observations; the family names the
            -- resolved Sha-Chi damage channel. Resource gain and PoiseDamage are separate channels.
            if name:sub(1,#prefix+14)==prefix..'GeneralDamage.'then total=total+v
            elseif name:sub(1,#prefix+12)==prefix..'AngerDamage.'then shachi=shachi+v end
        end
    end
    return total,shachi
end
M.damageHook='/PBZCombatAsset/Prototypes/Abilities/GA_CommonUtilitiesPassive.GA_CommonUtilitiesPassive_C:OnTaken'
return M
