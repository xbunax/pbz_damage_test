-- Final health and Shachi damage share one measured clock and one hit count.
local M = {}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.new()
    return {target=nil, world=nil, generation=0, total=0, last=0, maximum=0,
        shachiTotal=0,shachiLast=0,shachiMaximum=0,
        events=0, refills=0, started=nil, lastTime=nil, stoppedAt=nil, categories={}, recent={},
        paused=false,pausedAt=nil,pausedTotal=0,lastWall=nil,testDuration=0,completed=false}
end
function M.reset(s,testDuration)
    if testDuration==nil then testDuration=s.testDuration or 0 end
    assert(testDuration==0 or testDuration==5 or testDuration==10 or testDuration==30,'不支持的测试时长')
    s.total=0;s.last=0;s.maximum=0;s.events=0;s.refills=0
    s.shachiTotal=0;s.shachiLast=0;s.shachiMaximum=0
    s.started=nil;s.lastTime=nil;s.stoppedAt=nil;s.categories={};s.recent={}
    s.paused=false;s.pausedAt=nil;s.pausedTotal=0;s.lastWall=nil
    s.testDuration=testDuration;s.completed=false;s.finishedMeasured=nil;s.finishedWall=nil
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
-- Close the half-open damage window at the exact measured deadline, even on a late tick.
function M.advance(s,now)
    if not s.target or s.completed or s.paused or not s.started or s.testDuration==0 or not validTime(s,now)then return false end
    if measuredTime(s,now)-s.started<s.testDuration then return false end
    s.completed=true;s.finishedMeasured=s.started+s.testDuration
    s.finishedWall=s.finishedMeasured+s.pausedTotal;s.lastWall=s.finishedWall
    return true
end
function M.pause(s,now)
    if not s.target or s.paused or not validTime(s,now)then return false end
    M.advance(s,now)
    if s.completed then return false end
    s.paused=true;s.pausedAt=now;s.lastWall=now
    return true
end
function M.resume(s,now)
    if not s.target or s.completed or not s.paused or not validTime(s,now)then return false end
    s.pausedTotal=s.pausedTotal+now-s.pausedAt
    s.paused=false;s.pausedAt=nil;s.lastWall=now
    return true
end
function M.detach(s,now)
    M.advance(s,now)
    if s.target~=nil then s.stoppedAt=finite(now) and now or s.lastTime end
    s.generation=s.generation+1;s.target=nil;s.world=nil
end
function M.record(s,target,amount,category,time,shachi)
    if s.target==nil or target~=s.target or s.paused then return false end
    if shachi==nil then shachi=0 end
    if not finite(amount) or amount<0 or not finite(shachi) or shachi<0 or
        (amount==0 and shachi==0) or not finite(time) then return false end
    if not validTime(s,time)then return false end
    M.advance(s,time)
    if s.completed then return false end
    if not finite(s.total+amount)or not finite(s.shachiTotal+shachi)then return false end
    s.lastTime=time;s.lastWall=time
    local measured=measuredTime(s,time)
    s.started=s.started or measured
    s.last=amount;s.total=s.total+amount;s.maximum=math.max(s.maximum,amount)
    s.shachiLast=shachi;s.shachiTotal=s.shachiTotal+shachi;s.shachiMaximum=math.max(s.shachiMaximum,shachi)
    s.events=s.events+1
    local kept={}
    for _,hit in ipairs(s.recent)do if hit.time>measured-5 then kept[#kept+1]=hit end end
    kept[#kept+1]={time=measured,damage=amount,shachi=shachi};s.recent=kept
    if amount>0 then
        category=category or '生命伤害'
        s.categories[category]=(s.categories[category] or 0)+amount
    end
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
    M.advance(s,now)
    now=s.finishedWall or s.stoppedAt or now
    if not finite(now)then now=s.lastTime or 0 end
    now=s.finishedMeasured or measuredTime(s,now)
    local duration=s.started and math.max(0,now-s.started) or 0
    local recent,recentShachi=0,0
    for _,hit in ipairs(s.recent)do
        if hit.time>now-5 and hit.time<=now then recent=recent+hit.damage;recentShachi=recentShachi+(hit.shachi or 0) end
    end
    return {total=s.total,last=s.last,maximum=s.maximum,events=s.events,
        refills=s.refills,seconds=duration,dps=s.started and s.total/math.max(1,duration) or 0,
        recentDps=recent/5,
        shachiLast=s.shachiLast,shachiTotal=s.shachiTotal,shachiMaximum=s.shachiMaximum,
        shachiDps=s.started and s.shachiTotal/math.max(1,duration) or 0,shachiRecentDps=recentShachi/5,
        active=s.target~=nil,paused=s.paused,generation=s.generation,
        testDuration=s.testDuration,completed=s.completed,
        remaining=s.testDuration>0 and math.max(0,s.testDuration-duration)or nil}
end
return M
