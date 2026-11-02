local M={}
local required={
    'CreateInvalidObject','FindFirstOf','FindAllOf','StaticFindObject','LoadAsset',
    'StaticConstructObject','RegisterHook','UnregisterHook','RegisterKeyBind',
    'ExecuteInGameThread','LoopInGameThreadWithDelay','FName',
}
function M.check(env)
    local missing={}
    for _,name in ipairs(required) do
        if type(env[name])~='function' then missing[#missing+1]=name end
    end
    if not env.Key or not env.Key.F8 or not env.Key.ESCAPE or not env.Key.LEFT_MOUSE_BUTTON then
        missing[#missing+1]='Key enum'
    end
    if not env.ModRef then missing[#missing+1]='ModRef' end
    if #missing>0 then return false,'Missing UE4SS APIs: '..table.concat(missing,', ') end
    return true
end
return M
