-- Smoke-test the complete installed entry point and its real bundled dependencies.
-- UE4SS/game APIs are mocked; nothing is spawned and the menu remains closed.
local root=arg[1]
local shared,bindings,loops={}, {}, {}
local invalid={IsValid=function()return false end}
Key={F6=117,F8=119,ESCAPE=27,LEFT_MOUSE_BUTTON=1}
EFindName={FNAME_Find=0,FNAME_Add=1}
FName=setmetatable({},{__metatable='protected',__call=function(_,name)
    return {ToString=function()return tostring(name)end}
end})
ModRef={
    GetSharedVariable=function(_,name)return shared[name]end,
    SetSharedVariable=function(_,name,value)shared[name]=value end,
}
CreateInvalidObject=function()return invalid end
FindFirstOf=function()return invalid end
FindAllOf=function()return {}end
StaticFindObject=function()return invalid end
StaticConstructObject=function()error('Unexpected widget creation during startup')end
LoadAsset=function()error('Unexpected asset loading during startup')end
RegisterHook=function()return 1,2 end
UnregisterHook=function()end
RegisterKeyBind=function(key,callback)
    assert(key and type(callback)=='function');bindings[key]=callback
end
ExecuteInGameThread=function(callback)callback()end
LoopInGameThreadWithDelay=function(_,callback)
    loops[#loops+1]=callback;return #loops
end
local mod=dofile(root..'/PBZTrainingDummy/Scripts/main.lua')
assert(type(mod)=='table' and type(mod.ui)=='table','Installed mod did not initialize')
assert(bindings[Key.F8] and bindings[Key.ESCAPE],'Menu bindings were not registered')
assert(#loops>0,'Game thread monitor was not installed')
assert(mod.actor()==nil and not mod.ui.IsOpen(),'Startup must not spawn or open automatically')
print('PASS: complete packaged startup, private dependencies, protected FName and F8 registration')
