-- Only the independently spawned actor is modified.
local DIR=debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])')
local A=dofile(DIR..'adapter.lua')
local Session=dofile(DIR..'session.lua')
local Music=dofile(DIR..'music.lua')
local ui=dofile(DIR..'vendor/ModMenu.lua')
local Config=dofile(DIR..'config.lua')
local binding,bindingWarning=Config.load(DIR..'../config.ini',Key)
local state=Session.new()
local actor,world,owner,readyAt,hookIds
local ready=false
local status='未召唤木桩'
local MAX_HP=10000
local pinned={}
local function pin(fn) pinned[#pinned+1]=fn;return fn end
local function log(s) print('[PBZTrainingDummy] '..tostring(s)..'\n') end
if bindingWarning then log(bindingWarning) end
local function update()
    ui.SetLabel('dummy','status',status)
    local hp,mx=0,MAX_HP
    if A.valid(actor) then hp,mx=A.health(actor) end
    ui.SetLabel('dummy','health',string.format('木桩生命  %.0f / %.0f',hp,mx))
    ui.SetLabel('dummy','last',string.format('本次伤害  %.2f',state.last))
    ui.SetLabel('dummy','total',string.format('累计伤害  %.2f',state.total))
    ui.SetLabel('dummy','hits',string.format('命中 %d 次    自动回满 %d 次',state.events,state.refills))
    ui.SetButtonLabel('dummy','spawn',A.valid(actor) and '重新召唤到面前' or '召唤木桩')
    ui.SetButtonEnabled('dummy','remove',A.valid(actor))
    ui.SetButtonEnabled('dummy','reset',ready and A.valid(actor))
end
local function remove()
    local old=actor
    if A.valid(old) then Music.exclude(old) end
    actor=nil;world=nil;owner=nil;readyAt=nil;ready=false
    Session.detach(state)
    A.destroy(old)
    status='木桩已移除，测试记录保留'
    log('removed')
end
local function guarded(fn)
    return function(...)
        local ok,err=pcall(fn,...)
        if not ok then status='操作失败，请查看日志或重新召唤';log(err) end
        update()
    end
end
local onDamage=pin(function(context,event)
    if not ready or not A.valid(actor) then return end
    local ok,err=pcall(function()
        local avatar=context:get():GetAvatarActorFromActorInfo()
        if not A.valid(avatar) or avatar:GetAddress()~=state.target then return end
        local payload=event:get().OptionalObject
        if not A.valid(payload) or payload:GetClass():GetFName():ToString()~='DamageTakenPayload' then return end
        if not A.valid(payload.TargetActor) or payload.TargetActor:GetAddress()~=state.target then return end
        local amount=A.damage(payload)
        Session.record(state,state.target,amount,'生命伤害',A.now(actor))
        -- Health_Min is enforced by the game's attribute system before this event.
        -- This callback runs synchronously after damage, including a lethal hit.
        if A.health(actor)<=1 then
            A.heal(actor);state.refills=state.refills+1
        end
        log(string.format('hit=%.6f total=%.6f hp=%.2f refills=%d',amount,state.total,A.health(actor),state.refills))
        if ui.IsOpen() then update() end
    end)
    if not ok then log('damage callback: '..tostring(err)) end
end)
local function spawn()
    local p=A.player();assert(p,'请先进入可自由行动的场景')
    local t,cls=A.position(p,actor)
    if not t then status=cls;return end
    if not hookIds then
        local a,b=RegisterHook(A.damageHook,onDamage);hookIds={a,b}
    end
    remove()
    actor=A.spawn(p,t,cls);world=A.world(p);owner=p:GetAddress()
    Music.exclude(actor)
    Session.attach(state,actor:GetAddress(),world)
    readyAt=A.now(p)+1.0
    status='木桩正在初始化…'
    log('spawned '..actor:GetFullName())
end
local function reset()
    if ready and A.valid(actor) then A.heal(actor);Session.reset(state);status='测试已重置，木桩满血';log('reset') end
end
ui.Init({title='伤害测试木桩',instanceId='PBZTrainingDummy',key=binding.key,keyHint=binding.name,
    dock='right',theme='dark',ignoreLook=true,showClose=false,widthFrac=0.25,topFrac=0.10,bottomFrac=0.12,
    canOpen=function() return A.player()~=nil end})
ui.Register({id='dummy',title='独立训练目标',items={
    {type='label',id='status',label=status},
    {type='label',id='health',label='木桩生命  0 / 10000'},
    {type='button',id='spawn',label='召唤木桩',onClick=guarded(spawn)},
    {type='button',id='remove',label='移除木桩',onClick=guarded(remove)},
    {type='separator'},
    {type='label',id='last',label='本次伤害  0.00'},
    {type='label',id='total',label='累计伤害  0.00'},
    {type='label',id='hits',label='命中 0 次    自动回满 0 次'},
    {type='button',id='reset',label='重置测试并回满血',onClick=guarded(reset)},
    {type='label',label='降至 1 血自动回满，保留累计伤害。\n关闭菜单后可继续攻击木桩。'},
    {type='button',id='close',label='关闭菜单',onClick=function()ui.Close()end},
}})
ui.OnOpen(update)
local close=pin(function() if ui.IsOpen() then ui.Close() end end)
RegisterKeyBind(Key.ESCAPE,function() ExecuteInGameThread(close) end)
local tick=pin(function()
    local ok,err=pcall(function()
        if actor then
            local p=A.player()
            if A.valid(actor) then Music.exclude(actor) end
            if not A.valid(actor) or not p or A.world(p)~=world or p:GetAddress()~=owner then
                remove();status='场景或角色已切换，木桩已清理';ui.Close()
            elseif not ready and readyAt and A.now(p)>=readyAt then
                -- The actor's deferred ability/config initialization finishes after spawn.
                A.configure(actor,MAX_HP);ready=true;readyAt=nil
                status='木桩已就绪';log('ready hp='..A.health(actor))
            elseif ready and A.health(actor)<=1 then
                -- Backup for non-attack health drains. Normal attacks refill in onDamage.
                A.heal(actor);state.refills=state.refills+1
            end
        end
        if ui.IsOpen() then update() end
    end)
    if not ok then log('update: '..tostring(err));ready=false;readyAt=nil;status='初始化失败，请移除后重试' end
    return false
end)
LoopInGameThreadWithDelay(200,tick)
log('loaded; '..binding.name..' toggles menu; tested UE4SS: v3.0.1-1183-gcdbc0b66 (other builds unverified)')
-- Return a small control surface for offline/live verification; no script-command channel.
return {ui=ui,state=state,spawn=spawn,remove=remove,reset=reset,actor=function()return actor end}
