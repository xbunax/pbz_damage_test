-- Exclude only our dummy from the music subsystem's engagement lists.
-- The combat/targeting systems and the user's music settings stay independent.
local M={}
local cached, cachedWorld
local function valid(o) return o~=nil and o:IsValid() end
local function filtered(array,address)
    local kept,removed={},false
    -- This UE4SS version cannot GetParam a WeakObjectProperty in ForEach;
    -- indexed reads return a supported FWeakObjectPtr instead.
    for i=1,#array do
        local weak=array[i]
        local o=weak:Get()
        if valid(o) and o:GetAddress()==address then
            removed=true
        else
            kept[#kept+1]=weak
        end
    end
    return kept,removed
end
function M.excludeFrom(subsystem,actor)
    if not valid(subsystem) or not valid(actor) then return false end
    local address=actor:GetAddress()
    local normal,changedNormal=filtered(subsystem.EngagedEnemies,address)
    local special,changedSpecial=filtered(subsystem.EngagedSpecialEnemies,address)
    if not changedNormal and not changedSpecial then return false end
    if changedNormal then subsystem.EngagedEnemies=normal end
    if changedSpecial then subsystem.EngagedSpecialEnemies=special end
    -- bInBattle is cached separately from the arrays. End music combat only when
    -- removing the dummy leaves neither normal nor special enemies engaged.
    if #normal==0 and #special==0 then
        subsystem.bInBattle=false
        subsystem:UpdateGameplayMusic(true)
    end
    return true
end
function M.exclude(actor)
    if not valid(actor) then return false end
    local world=actor:GetWorld():GetAddress()
    if not valid(cached) or cachedWorld~=world then
        cached=nil;cachedWorld=nil
        for _,m in ipairs(FindAllOf('MusicSubsystem') or {}) do
            if valid(m) and m:GetWorld():GetAddress()==world then
                cached=m;cachedWorld=world;break
            end
        end
    end
    return M.excludeFrom(cached,actor)
end
return M
