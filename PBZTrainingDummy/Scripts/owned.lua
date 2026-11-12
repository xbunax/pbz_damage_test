-- Reclaim new Actor instances whose owner/instigator chain leads to our target.
-- Existing map actors are excluded even if the game later changes their owner.
local M={}
local function valid(o)return o~=nil and o:IsValid()end
local function key(o)
    if not valid(o)then return nil end
    local ok,value=pcall(function()return o:GetAddress()end)
    return ok and value or nil
end
local function scan()
    return FindAllOf and FindAllOf('Actor')or {}
end
function M.new(enabled,options)
    options=options or {}
    local list=options.scan or scan
    local destroy=options.destroy or function(o)o:K2_DestroyActor()end
    local self={enabled=enabled==true,baseline={},root=nil,protected={},pending={}}
    if self.enabled then
        for _,o in ipairs(list()or {})do local id=key(o);if id then self.baseline[id]=true end end
    end
    function self:bind(actor,player)
        if not self.enabled then return end
        self.root=key(actor)
        local id=key(player);if id then self.protected[id]=true end
    end
    local function depth(o,root,seen,n)
        local id=key(o)
        if not id or seen[id]or n>12 then return nil end
        if id==root then return n end
        seen[id]=true
        for _,method in ipairs({'GetOwner','GetInstigator'})do
            local ok,parent=pcall(function()return o[method](o)end)
            if ok then local d=depth(parent,root,seen,n+1);if d then return d end end
        end
    end
    function self:clear()
        if not self.enabled or not self.root then return true end
        local success=true
        local requested={}
        -- A destroyed summon can spawn its own effects, so collect once more.
        for _=1,2 do
            local children={}
            local ok,actors=pcall(list)
            if not ok then return false end
            for _,o in ipairs(actors or {})do
                local id=key(o)
                if id and id~=self.root and not self.baseline[id]and not self.protected[id]then
                    local d=depth(o,self.root,{},0)
                    if d then self.pending[id]={actor=o,depth=d}end
                end
            end
            for id,child in pairs(self.pending)do
                if not requested[id]then children[#children+1]=child end
            end
            table.sort(children,function(a,b)return a.depth>b.depth end)
            for _,child in ipairs(children)do
                if valid(child.actor)then
                    local called=pcall(destroy,child.actor)
                    local id=key(child.actor)
                    if called then
                        -- Do not request destruction twice while Unreal waits for the end of frame.
                        if id then requested[id]=true;self.pending[id]=nil end
                    else success=false end
                else
                    for id,pending in pairs(self.pending)do
                        if pending==child then self.pending[id]=nil end
                    end
                end
            end
        end
        return success
    end
    return self
end
return M
