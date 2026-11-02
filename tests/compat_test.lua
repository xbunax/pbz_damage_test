local C=dofile(arg[1]..'/PBZTrainingDummy/Scripts/compat.lua')
local ok,why=C.check({})
assert(not ok and why:find('RegisterHook',1,true))
local env=setmetatable({Key={F8=119,ESCAPE=27,LEFT_MOUSE_BUTTON=1},ModRef={}},{__index=function()return function()end end})
assert(C.check(env))
env.RegisterHook=false
assert(not C.check(env),'An incompatible loader must be rejected before spawning')
print('PASS: incompatible API preflight')
