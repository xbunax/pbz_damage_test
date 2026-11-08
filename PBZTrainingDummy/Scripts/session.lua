-- Session accounting. Only the engine adapter supplies final HEALTH damage.
local M = {}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.new()
    return {target=nil, world=nil, generation=0, total=0, last=0, maximum=0,
        events=0, refills=0, started=nil, lastTime=nil, stoppedAt=nil, categories={}, recent={},
        paused=false,pausedAt=nil,pausedTotal=0,lastWall=nil}
end
function M.reset(s)
    s.total=0;s.last=0;s.maximum=0;s.events=0;s.refills=0
    s.started=nil;s.lastTime=nil;s.stoppedAt=nil;s.categories={};s.recent={}
    s.paused=false;s.pausedAt=nil;s.pausedTotal=0;s.lastWall=nil
end
function M.attach(s,target,world)
    assert(target~=nil and world~=nil,'Target and world are required')
    s.generation=s.generation+1;s.target=target;s.world=world;M.reset(s)
end
local function validTime(s,now)
    return finite(now) and (not s.lastWall or now>=s.lastWall)
end
local function measuredTime(s,now)
    return (s.paused and s.pausedAt or now)-s.pausedTotal
end
function M.pause(s,now)
    if not s.target or s.paused or not validTime(s,now)then return false end
    s.paused=true;s.pausedAt=now;s.lastWall=now
    return true
end
function M.resume(s,now)
    if not s.target or not s.paused or not validTime(s,now)then return false end
    s.pausedTotal=s.pausedTotal+now-s.pausedAt
    s.paused=false;s.pausedAt=nil;s.lastWall=now
    return true
end
function M.detach(s,now)
    if s.target~=nil then s.stoppedAt=finite(now) and now or s.lastTime end
    s.generation=s.generation+1;s.target=nil;s.world=nil
end
function M.record(s,target,amount,category,time)
    if s.target==nil or target~=s.target or s.paused then return false end
    if not finite(amount) or amount<=0 or not finite(time) then return false end
    if not validTime(s,time)then return false end
    s.lastTime=time;s.lastWall=time
    local measured=measuredTime(s,time)
    s.started=s.started or measured
    s.last=amount;s.total=s.total+amount;s.maximum=math.max(s.maximum,amount)
    s.events=s.events+1
    local kept={}
    for _,hit in ipairs(s.recent)do if hit.time>measured-5 then kept[#kept+1]=hit end end
    kept[#kept+1]={time=measured,damage=amount};s.recent=kept
    category=category or '生命伤害'
    s.categories[category]=(s.categories[category] or 0)+amount
    return true
end
-- Called synchronously before a lethal health update, never from a timer.
function M.health_after(health,damage,maxHealth)
    assert(finite(health) and health>=1,'Invalid current health')
    assert(finite(damage) and damage>=0,'Invalid damage')
    assert(finite(maxHealth) and maxHealth>1,'Invalid maximum health')
    local remaining=math.max(1,health-damage)
    return remaining,remaining<=1
end
function M.snapshot(s,now)
    now=s.stoppedAt or now
    if not finite(now)then now=s.lastTime or 0 end
    now=measuredTime(s,now)
    local duration=s.started and math.max(0,now-s.started) or 0
    local recent=0
    for _,hit in ipairs(s.recent)do if hit.time>now-5 and hit.time<=now then recent=recent+hit.damage end end
    return {total=s.total,last=s.last,maximum=s.maximum,events=s.events,
        refills=s.refills,seconds=duration,dps=s.started and s.total/math.max(1,duration) or 0,
        recentDps=recent/5,
        active=s.target~=nil,paused=s.paused,generation=s.generation}
end
return M
