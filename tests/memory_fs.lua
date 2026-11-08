-- Isolated storage for archive and runtime tests: never touch installed/user records.
local fs={files={},fail=nil}
function fs.open(path,mode)
    if fs.fail==path then return nil,'simulated failure' end
    if mode=='rb' then
        if fs.files[path]==nil then return nil end
        return {read=function(_,n)return fs.files[path]:sub(1,n)end,close=function()return true end}
    end
    assert(mode=='wb');fs.files[path]=''
    return {write=function(self,value)fs.files[path]=value;return self end,close=function()return true end}
end
return fs
