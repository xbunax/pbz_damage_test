-- PBZ Training Dummy entry point. No game mutation before the API preflight.
local source=debug.getinfo(1,'S').source
local DIR=source:gsub('^@',''):match('^(.*[/\\])')
if not DIR then print('[PBZTrainingDummy] Disabled: cannot resolve Scripts directory\n');return end
local compat=dofile(DIR..'compat.lua')
local available,reason=compat.check(_G)
if not available then
    print('[PBZTrainingDummy] Disabled: '..reason..'\n')
    return
end
-- Private dependencies: do not replace another mod's shared UEHelpers/ModMenu.
package.preload['PBZTrainingDummy.UEHelpers']=function()
    return dofile(DIR..'vendor/UEHelpers.lua')
end
local ok,result=xpcall(function()return dofile(DIR..'runtime.lua')end,debug.traceback)
if not ok then print('[PBZTrainingDummy] Initialization failed: '..tostring(result)..'\n');return end
return result
