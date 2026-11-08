-- Only the single actor created by this mod is controlled or counted.
local DIR=debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])')
local A=dofile(DIR..'adapter.lua')
local Session=dofile(DIR..'session.lua')
local Practice=dofile(DIR..'practice.lua')
local Targets=dofile(DIR..'targets.lua')
local Music=dofile(DIR..'music.lua')
local I18n=dofile(DIR..'i18n.lua')
local language=I18n.new(DIR..'../ui_language.txt')
local function T(key,...)return language:t(key,...)end
local ui=dofile(DIR..'vendor/ModMenu.lua')
local Segments=dofile(DIR..'segments.lua')
local Json=require('PBZDummyMenu.store.json')
local history=Segments.new(DIR..'../dps_segments.json',{Encode=Json.Encode,Decode=Json.DecodeObject})
local Config=dofile(DIR..'config.lua')
local binding,bindingWarning=Config.load(DIR..'../config.ini',Key)
local state=Session.new()
local settings={category='training',target='gold',mode='hold',health=10000,interval=3,noAggro=true}
local actor,world,owner,readyAt,hookIds,practice,control
local ready=false
local lastClock=0
local status='未召唤木桩'
local statsNotice='可填写武器名，再保存分段用于对比'
local roundContext
local sourceSections={}
local setLanguage
local pendingLanguage
local function localize(value)
    if type(value)~='table'then return value end
    local out={}
    for k,v in pairs(value)do
        if type(v)=='table'then out[k]=localize(v)
        elseif type(v)=='string'and (k=='label'or k=='title'or k=='tab'or k=='placeholder'or k=='message'or k=='confirmLabel'or k=='cancelLabel')then out[k]=T(v)
        else out[k]=v end
    end
    return out
end
local function register(source)
    sourceSections[#sourceSections+1]=source
    ui.Register(localize(source))
end
local pinned={}
local function pin(fn)pinned[#pinned+1]=fn;return fn end
local function log(s)print('[PBZTrainingDummy] '..tostring(s)..'\n')end
if bindingWarning then log(bindingWarning)end
if history.warning then log(history.warning)end
if language.warning then statsNotice=language.warning;log(language.warning)end
local function clock()
    local p=A.player()
    if p and (not world or A.world(p)==world)then lastClock=A.now(p)end
    return lastClock
end
local function stop(reason)
    if practice then Practice.stop(practice,reason)end
end
local function captureContext()
    local target=Targets.get(settings.target)
    roundContext={targetId=settings.target,targetName=target.label,maxHP=settings.health,mode=settings.mode}
end
local function refreshHistory(a,b)
    local options=history:options(T)
    local oldA=a or ui.Get('comparison','a')
    local oldB=b or ui.Get('comparison','b')
    ui.SetOptions('comparison','a',options,history:get(oldA)and tostring(oldA)or options[1].value)
    ui.SetOptions('comparison','b',options,history:get(oldB)and tostring(oldB)or options[#options].value)
end
local function update()
    local snap=Session.snapshot(state,clock())
    local hp,mx=0,settings.health
    if ready and A.valid(actor)then hp,mx=A.health(actor)end
    ui.SetLabel('dummy','status',language:message(status))
    ui.SetLabel('dummy','health',T('目标生命  %.0f / %.0f',hp,mx))
    ui.SetLabel('dummy','attackStatus',language:message(practice and practice.message or '攻击已停止'))
    ui.SetLabel('dummy','capabilities',Targets.description(settings.target,T))
    ui.SetButtonLabel('dummy','spawn',T(A.valid(actor) and '重新召唤到面前' or '召唤木桩'))
    ui.SetButtonEnabled('dummy','remove',A.valid(actor))
    ui.SetButtonEnabled('dummy','start',ready and settings.mode~='hold')
    ui.SetButtonEnabled('dummy','stop',practice~=nil and practice.running)
    ui.SetButtonEnabled('stats','reset',ready and A.valid(actor))
    ui.SetButtonLabel('stats','pause',T(state.paused and '继续统计' or '暂停统计'))
    ui.SetButtonEnabled('stats','pause',ready and A.valid(actor))
    ui.SetButtonEnabled('stats','save',snap.events>0 and not history.blocked)
    local phase=not snap.active and '目标已移除，结果已冻结' or
        (snap.paused and '统计已暂停：伤害与计时均不计入' or (snap.events==0 and '等待首次命中开始计时' or '正在统计，停手仍计时'))
    ui.SetLabel('stats','phase',T(phase))
    ui.SetLabel('stats','notice',language:message(statsNotice))
    local a,b=history:get(ui.Get('comparison','a')),history:get(ui.Get('comparison','b'))
    local function targetName(row)
        if not row then return nil end
        local ok,name=pcall(Targets.label,row.targetId,T)
        return ok and name or row.targetName
    end
    ui.SetLabel('comparison','detailA',Segments.describe(a,T,targetName(a)))
    ui.SetLabel('comparison','detailB',Segments.describe(b,T,targetName(b)))
    ui.SetLabel('comparison','result',Segments.compare(a,b,T))
    ui.SetLabel('comparison','count',T('已保存 %d / %d 段%s',#history.rows,Segments.LIMIT,
        history.warning and ('\n'..T(history.warning))or ''))
    ui.SetButtonEnabled('comparison','delete',b~=nil and not history.blocked)
    for _,pair in ipairs({
        {'last',T('本次伤害  %.2f',snap.last)},
        {'total',T('累计伤害  %.2f',snap.total)},
        {'hits',T('命中 %d 次    自动回满 %d 次',snap.events,snap.refills)},
        {'average',T('平均 DPS  %.2f',snap.dps)},
        {'recent',T('近 5 秒 DPS  %.2f',snap.recentDps)},
        {'duration',T('本轮计时  %.1f 秒%s',snap.seconds,T(not snap.active and '（已冻结）' or (snap.paused and '（已暂停）' or '')))},
        {'maximum',T('最高单次伤害  %.2f',snap.maximum)},
    })do ui.SetLabel('stats',pair[1],pair[2])end
end
local function remove()
    clock()
    local old=actor
    if practice then local ok,err=pcall(stop);if not ok then log('stop during cleanup: '..tostring(err))end end
    if A.valid(old)then
        local p=A.player()
        if p and A.world(p)==world then
            local ok,err=pcall(A.clearAggro,old,p);if not ok then log('hatred cleanup: '..tostring(err))end
        end
        Music.exclude(old)
    end
    Session.detach(state,lastClock)
    actor=nil;control=nil;practice=nil;world=nil;owner=nil;readyAt=nil;ready=false
    A.destroy(old)
    status='木桩已移除，统计与 DPS 保留';log('removed')
end
local function guarded(fn)
    return function(...)
        local ok,err=pcall(fn,...)
        if not ok then
            pcall(stop,'操作失败，攻击已停止')
            local reason=tostring(err):gsub('^.-:%d+: ','')
            status=function()return T('操作失败：%s',language:message(reason))end;log(err)
            statsNotice=status
        end
        update()
    end
end
local onDamage=pin(function(context,event)
    if not ready or not A.valid(actor)then return end
    local ok,err=pcall(function()
        local avatar=context:get():GetAvatarActorFromActorInfo()
        if not A.valid(avatar)or avatar:GetAddress()~=state.target then return end
        local payload=event:get().OptionalObject
        if not A.valid(payload)or payload:GetClass():GetFName():ToString()~='DamageTakenPayload' then return end
        if not A.valid(payload.TargetActor)or payload.TargetActor:GetAddress()~=state.target then return end
        local amount=A.damage(payload)
        lastClock=A.now(actor)
        local first=state.events==0
        if Session.record(state,state.target,amount,'生命伤害',lastClock)and roundContext then
            if first then roundContext.mode=settings.mode
            elseif roundContext.mode~=settings.mode then roundContext.mode='mixed' end
        end
        if A.health(actor)<=1 then A.heal(actor);if not state.paused then state.refills=state.refills+1 end end
        if control.noAggro then A.clearAggro(actor,A.player())end
        log(string.format('hit=%.6f total=%.6f hp=%.2f refills=%d',amount,state.total,A.health(actor),state.refills))
        if ui.IsOpen()then update()end
    end)
    if not ok then log('damage callback: '..tostring(err))end
end)
local function spawn()
    local p=A.player();assert(p,'请先进入可自由行动的场景')
    settings.health=Targets.health(tonumber(ui.Get('dummy','maxHP')))
    local t,cls=A.position(p,actor,Targets.get(settings.target).class)
    if not t then status=cls;return end
    if not hookIds then local a,b=RegisterHook(A.damageHook,onDamage);hookIds={a,b}end
    clock();remove()
    actor,control=A.spawn(p,t,cls)
    world=A.world(p);owner=p:GetAddress();practice=Practice.new(A,control)
    lastClock=A.now(p);Session.attach(state,actor:GetAddress(),world)
    captureContext();statsNotice='已开始新一轮，等待首次命中'
    readyAt=lastClock+1;status='目标正在初始化…'
    A.setNoAggro(control,p,settings.noAggro);Music.exclude(actor)
    log('spawned '..actor:GetFullName()..' type='..settings.target)
end
local function reset()
    assert(ready and A.valid(actor),'请先召唤并等待木桩就绪')
    local paused=state.paused
    stop();A.heal(actor);Session.reset(state);captureContext()
    if paused then Session.pause(state,clock())end
    statsNotice=paused and '本轮已清空，继续统计后再开始测试' or '本轮已清空，等待首次命中'
    status='测试已重置，木桩满血';log('reset')
end
local function togglePause()
    assert(ready and A.valid(actor),'请先召唤并等待木桩就绪')
    local now=clock()
    if state.paused then
        assert(Session.resume(state,now),'无法继续统计，请重置后重试')
        statsNotice='已继续统计，暂停期间的时间与伤害不会计入'
    else
        assert(Session.pause(state,now),'无法暂停统计，请重置后重试')
        statsNotice='已暂停，可更换武器或保存本段'
    end
end
local function saveSegment()
    local now=clock()
    assert(state.events>0,'本段还没有有效伤害，无法保存')
    if state.target and not state.paused then assert(Session.pause(state,now),'暂停失败，未保存')end
    local row,why=history:add(Session.snapshot(state,now),roundContext,ui.Get('stats','name'))
    assert(row,why)
    Session.reset(state)
    if state.target then Session.pause(state,now);captureContext()end
    ui.Set('stats','name','')
    refreshHistory(nil,tostring(row.id))
    local nextMessage=state.target and '下一段已暂停，换武器后点击继续统计' or '请召唤目标开始下一段'
    statsNotice=function()return T('已保存 #%d %s；%s',row.id,Segments.name(row,T),T(nextMessage))end
    log('segment saved id='..row.id..' dps='..row.dps)
end
local function deleteSegment()
    local ok,why=history:delete(ui.Get('comparison','b'));assert(ok,why)
    refreshHistory();statsNotice='已删除选中的保存分段'
end
local function setType(id)
    Targets.get(id)
    if id~=settings.target then
        clock();remove();settings.target=id;settings.mode='hold'
        if settings.category~=Targets.get(id).category then
            settings.category=Targets.get(id).category
            ui.Set('dummy','category',settings.category)
            ui.SetOptions('dummy','target',Targets.options(settings.category,T),id)
        else ui.Set('dummy','target',id)end
        ui.SetOptions('dummy','mode',Targets.modes(id,T),'hold')
        status=function()return T('已选择 %s，请召唤',Targets.label(id,T))end
    end
end
local function setCategory(id)
    local options=Targets.options(id)
    assert(#options>0,'该图鉴分类暂未加入训练目标')
    if id~=settings.category then setType(options[1].value)end
end
local function applyHealth()
    local value=Targets.health(tonumber(ui.Get('dummy','maxHP')))
    if A.valid(actor)then
        assert(ready,'目标正在初始化，请稍后再试')
        local paused=state.paused
        stop();A.configure(actor,value);Session.reset(state)
        if paused then Session.pause(state,clock())end
    end
    settings.health=value;ui.Set('dummy','maxHP',value)
    if ready then captureContext()end
    status=ready and '血量已应用，统计已重置' or '血量已设置，下次召唤生效'
end
local function setNoAggro(on)
    if control and A.valid(actor)then
        local ok,err=pcall(A.setNoAggro,control,A.player(),on==true)
        if not ok then
            pcall(A.setNoAggro,control,A.player(),settings.noAggro)
            ui.Set('dummy','noAggro',settings.noAggro);error(err)
        end
    end
    settings.noAggro=on==true
    status=settings.noAggro and '木桩仇恨已关闭' or '木桩仇恨已开启'
end
local function start()
    assert(ready and practice,'请先召唤并等待目标就绪')
    local skill=Targets.get(settings.target).skills[settings.mode]
    assert(skill,'当前角色或模式不支持循环攻击')
    settings.interval=Targets.interval(tonumber(ui.Get('dummy','interval')))
    Practice.start(practice,A.player(),skill,settings.interval,clock())
    status='循环攻击已开始，打开菜单可停止';ui.Close()
    log('practice started '..skill..' interval='..settings.interval)
end
ui.Init({title=T('伤害测试木桩'),instanceId='PBZTrainingDummy',key=binding.key,keyHint=binding.name,
    toggleHint=T('[%s] 打开 / 关闭菜单',binding.name),
    dock='right',theme='dark',ignoreLook=true,showClose=false,widthFrac=0.30,topFrac=0.06,bottomFrac=0.06,
    tabs={T('训练设置'),T('伤害统计'),T('分段对比')},canOpen=function()return A.player()~=nil end})
register({id='dummy',tab='训练设置',title='训练目标',items={
    {type='dropdown',id='language',label='菜单语言 / Language',options={{label='简体中文',value='zh'},{label='English',value='en'}},default=language.language,onChange=function(value)pendingLanguage=value end},
    {type='label',id='status',label=status},
    {type='label',id='health',label='目标生命  0 / 10000'},
    {type='dropdown',id='category',label='一级：图鉴分类',options=Targets.categories(),default='training',onChange=guarded(setCategory)},
    {type='dropdown',id='target',label='二级：选择小怪',options=Targets.options('training'),default='gold',searchable=true,maxVisible=8,onChange=guarded(setType)},
    {type='label',id='capabilities',label=Targets.description('gold')},
    {type='number',id='maxHP',label='目标最大血量',default=10000,min=10,max=10000000,integer=true},
    {type='button',id='applyHP',label='应用血量并重置统计',onClick=guarded(applyHealth)},
    {type='checkbox',id='noAggro',label='关闭木桩仇恨（便于换武器）',default=true,onChange=guarded(setNoAggro)},
    {type='button',id='spawn',label='召唤木桩',onClick=guarded(spawn)},
    {type='button',id='remove',label='移除木桩并保留统计',onClick=guarded(remove)},
    {type='separator'},
    {type='dropdown',id='mode',label='训练模式',options=Targets.modes('gold'),default='hold',onChange=guarded(function(mode)
        assert(mode=='hold' or Targets.get(settings.target).skills[mode],'不支持的训练模式')
        stop();settings.mode=mode
    end)},
    {type='number',id='interval',label='攻击结束后间隔（秒）',default=3,min=0.5,max=30},
    {type='label',id='attackStatus',label='攻击已停止'},
    {type='button',id='start',label='开始循环攻击',onClick=guarded(start)},
    {type='button',id='stop',label='停止攻击',onClick=guarded(function()stop()end)},
    {type='label',label='按角色原生招式开放模式，不移植其他武器招式。\n受击后等待恢复再继续；打开菜单会停止攻击。\n设置在本次游戏内保留。'},
    {type='button',id='close',label='关闭菜单',onClick=function()ui.Close()end},
}})
register({id='stats',tab='伤害统计',title='本轮伤害与 DPS',items={
    {type='label',id='phase',label='等待召唤目标'},
    {type='label',id='last',label='本次伤害  0.00'},
    {type='label',id='total',label='累计伤害  0.00'},
    {type='label',id='hits',label='命中 0 次    自动回满 0 次'},
    {type='label',id='average',label='平均 DPS  0.00'},
    {type='label',id='recent',label='近 5 秒 DPS  0.00'},
    {type='label',id='duration',label='本轮计时  0.0 秒'},
    {type='label',id='maximum',label='最高单次伤害  0.00'},
    {type='button',id='pause',label='暂停统计',onClick=guarded(togglePause)},
    {type='textinput',id='name',label='武器名 / 分段备注',default='',placeholder='留空则自动编号'},
    {type='button',id='save',label='保存本段，下一段保持暂停',onClick=guarded(saveSegment)},
    {type='label',id='notice',label=statsNotice},
    {type='button',id='reset',label='重置统计并回满血',onClick=guarded(reset)},
    {type='label',label='平均 DPS：首次命中起计时，最短按 1 秒计算。\n暂停冻结时间与全部伤害统计；继续后扣除暂停时长。\n近 5 秒 DPS：最近 5 秒有效计时内的伤害 ÷ 5。\n保存后清空本段并暂停下一段；武器名需手动填写。\n重新召唤会清空未保存的统计；历史分段保留。'},
}})
register({id='comparison',tab='分段对比',title='已保存的武器测试',items={
    {type='label',id='count',label='已保存 0 / 100 段'},
    {type='dropdown',id='a',label='A：基准分段',options=history:options(),default='none',searchable=true,maxVisible=6},
    {type='label',id='detailA',label='请选择保存分段'},
    {type='dropdown',id='b',label='B：对比分段',options=history:options(),default='none',searchable=true,maxVisible=6},
    {type='label',id='detailB',label='请选择保存分段'},
    {type='label',id='result',label='保存两段后，可选择 A 与 B 比较'},
    {type='button',id='delete',label='删除 B 选中的记录',confirm={title='删除保存分段',message='删除 B 当前选中的记录？',confirmLabel='删除',cancelLabel='取消'},onClick=guarded(deleteSegment)},
    {type='label',label='记录保存在本机 dps_segments.json，重启后保留。\n最多 100 段；满后请删除不需要的记录。\n比较时请使用相同目标、血量、招式与其他条件。'},
}})
local function refreshTargetOptions()
    ui.SetOptions('dummy','category',Targets.categories(T),settings.category)
    ui.SetOptions('dummy','target',Targets.options(settings.category,T),settings.target)
    ui.SetOptions('dummy','mode',Targets.modes(settings.target,T),settings.mode)
end
setLanguage=function(value)
    local previous=language.language
    local ok,why=language:set(value)
    if not ok then ui.Set('dummy','language',previous);error(why)end
    if previous==value then return end
    local active=ui.GetTab()
    local tabIndex=1
    for index,key in ipairs({'训练设置','伤害统计','分段对比'})do
        if active==(previous=='en'and I18n.en[key]or key)then tabIndex=index end
    end
    local wasOpen=ui.IsOpen()
    ui.Close()
    -- Init is idempotent: updates presentation without installing more key bindings.
    ui.Init({title=T('伤害测试木桩'),toggleHint=T('[%s] 打开 / 关闭菜单',binding.name),
        tabs={T('训练设置'),T('伤害统计'),T('分段对比')}})
    for _,source in ipairs(sourceSections)do ui.Register(localize(source))end
    ui.Set('dummy','language',language.language)
    refreshTargetOptions();refreshHistory()
    ui.SetTab(T(({'训练设置','伤害统计','分段对比'})[tabIndex]))
    if wasOpen then ui.Open()end
end
refreshTargetOptions()
refreshHistory()
ui.OnOpen(function()
    local ok,err=pcall(function()if practice and practice.running then stop('打开菜单，攻击已停止')end end)
    if not ok then log(err)end
    update()
end)
local close=pin(function()if ui.IsOpen()then ui.Close()end end)
RegisterKeyBind(Key.ESCAPE,function()ExecuteInGameThread(close)end)
local tick=pin(function()
    local ok,err=pcall(function()
        -- Rebuild outside the menu's widget poll so old controls are no longer in use.
        if pendingLanguage then
            local value=pendingLanguage;pendingLanguage=nil;guarded(setLanguage)(value)
        end
        if actor then
            local p=A.player()
            if not A.valid(actor)or not p or A.world(p)~=world or p:GetAddress()~=owner then
                remove();status='场景或角色已切换，木桩已清理';ui.Close()
            else
                lastClock=A.now(p);Music.exclude(actor)
                if A.health(p)<=0 then
                    remove();status='玩家已倒下，木桩已清理';ui.Close()
                elseif not ready and readyAt and lastClock>=readyAt then
                    assert(A.hasSkill(actor,'GA_CommonUtilitiesPassive_C'),'此目标缺少伤害统计被动，暂不支持，请更换目标')
                    A.configure(actor,settings.health);A.hold(control)
                    A.setNoAggro(control,p,settings.noAggro)
                    ready=true;readyAt=nil;status='木桩已就绪'
                    log('ready hp='..A.health(actor)..' noAggro='..tostring(settings.noAggro))
                elseif ready then
                    if A.health(actor)<=1 then A.heal(actor);if not state.paused then state.refills=state.refills+1 end end
                    local wasRunning,completed,retries=practice.running,practice.completed,practice.retries
                    Practice.tick(practice,p,lastClock)
                    if practice.retries and practice.retries~=retries then
                        if practice.retries==1 then log('practice waiting for recovery: '..tostring(practice.lastFailure))end
                        if practice.retries==0 then log('practice resumed after recovery')end
                    end
                    if practice.completed~=completed then log('practice completed='..practice.completed)end
                    if wasRunning and not practice.running then log('practice stopped: '..practice.message)end
                end
            end
        end
        if ui.IsOpen()then update()end
    end)
    if not ok then
        pcall(stop,'更新失败，攻击已停止');ready=false;readyAt=nil
        status='初始化或更新失败，请移除后重试';log('update: '..tostring(err))
    end
    return false
end)
LoopInGameThreadWithDelay(100,tick)
log('loaded preview.3; '..binding.name..' toggles menu; bilingual menu, DPS pause and saved comparisons enabled')
return {ui=ui,state=state,settings=settings,spawn=spawn,remove=remove,reset=reset,
    start=start,stop=stop,setType=setType,setCategory=setCategory,setNoAggro=setNoAggro,applyHealth=applyHealth,
    language=language,setLanguage=setLanguage,history=history,actor=function()return actor end,tick=tick}
