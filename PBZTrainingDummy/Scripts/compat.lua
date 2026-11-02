local M={}
local required={
    'CreateInvalidObject','FindFirstOf','FindAllOf','StaticFindObject','LoadAsset',
    'StaticConstructObject','RegisterHook','UnregisterHook','RegisterKeyBind',
    'ExecuteInGameThread','LoopInGameThreadWithDelay',
}
function M.check(env)
    local missing={}
    for _,name in ipairs(required) do
        if type(env[name])~='function' then missing[#missing+1]=name end
    end
    -- UE4SS exposes FName as userdata with a protected metatable. Neither type()
    -- nor getmetatable().__call reliably describes whether the constructor works.
    -- Find the existing None name (FNAME_Find=0); this adds no names to the game.
    local nameOK,name=pcall(function()
        return env.FName('None',env.EFindName and env.EFindName.FNAME_Find or 0)
    end)
    if not nameOK or name==nil then missing[#missing+1]='FName constructor' end
    if not env.Key or not env.Key.F8 or not env.Key.ESCAPE or not env.Key.LEFT_MOUSE_BUTTON then
        missing[#missing+1]='Key enum'
    end
    if not env.ModRef then missing[#missing+1]='ModRef' end
    if #missing>0 then return false,'Missing UE4SS APIs: '..table.concat(missing,', ') end
    return true
end
return M
