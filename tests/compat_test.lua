local C=dofile(arg[1]..'/PBZTrainingDummy/Scripts/compat.lua')
local ok,why=C.check({})
assert(not ok and why:find('RegisterHook',1,true))
local env=setmetatable({Key={F8=119,ESCAPE=27,LEFT_MOUSE_BUTTON=1},ModRef={},EFindName={FNAME_Find=0},
    FName=function(text,mode)assert(text=='None' and mode==0);return {}end},
    {__index=function()return function()end end})
assert(C.check(env))
env.FName=setmetatable({},{__call=function()return {}end})
assert(C.check(env),'UE4SS callable class constructors must pass the preflight')
env.FName=setmetatable({},{__metatable='protected UE4SS constructor',__call=function()return {}end})
assert(C.check(env),'Protected metatables must not hide a working constructor from preflight')
env.FName={}
assert(not C.check(env),'A non-callable constructor must still be rejected')
env.FName=false
assert(not C.check(env),'A missing constructor must still be rejected')
env.FName=function()return {}end
env.RegisterHook=false
assert(not C.check(env),'An incompatible loader must be rejected before spawning')
print('PASS: incompatible API preflight')
