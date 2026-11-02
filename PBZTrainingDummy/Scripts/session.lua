-- Session accounting. Only the engine adapter supplies final HEALTH damage.
local M = {}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.new()
    return {target=nil, world=nil, generation=0, total=0, last=0, maximum=0,
        events=0, refills=0, started=nil, lastTime=nil, categories={}}
end
function M.reset(s)
    s.total=0;s.last=0;s.maximum=0;s.events=0;s.refills=0
    s.started=nil;s.lastTime=nil;s.categories={}
end
function M.attach(s,target,world)
    assert(target~=nil and world~=nil,'Target and world are required')
    s.generation=s.generation+1;s.target=target;s.world=world;M.reset(s)
end
function M.detach(s)
    s.generation=s.generation+1;s.target=nil;s.world=nil
end
function M.record(s,target,amount,category,time)
    if s.target==nil or target~=s.target then return false end
    if not finite(amount) or amount<=0 or not finite(time) then return false end
    if s.lastTime and time<s.lastTime then return false end
    s.started=s.started or time;s.lastTime=time
    s.last=amount;s.total=s.total+amount;s.maximum=math.max(s.maximum,amount)
    s.events=s.events+1
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
    local duration=s.started and math.max(0,now-s.started) or 0
    return {total=s.total,last=s.last,maximum=s.maximum,events=s.events,
        refills=s.refills,seconds=duration,dps=duration>0 and s.total/duration or 0,
        active=s.target~=nil,generation=s.generation}
end
return M
