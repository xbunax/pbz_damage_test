local C=dofile(arg[1]..'/PBZTrainingDummy/Scripts/config.lua')
local keys={F8=119,F9=120,P=80,ESCAPE=27,LEFT_MOUSE_BUTTON=1}
assert(C.parse('',keys).name=='F8')
local b,w=C.parse('[Keybinds]\r\nMenuToggle = f9 ; comment\r\n',keys)
assert(b.name=='F9' and b.key==120 and not w)
assert(C.parse('[Keybinds]\nMenuToggle=P',keys).key==80)
assert(C.parse('[Other]\nMenuToggle=P',keys).name=='F8')
for _,value in ipairs({'NO_SUCH_KEY','ESCAPE','LEFT_MOUSE_BUTTON','F8; os.execute()',''}) do
 local result,warning=C.parse('[Keybinds]\nMenuToggle='..value,keys)
 if value~='F8; os.execute()' then assert(result.name=='F8' and warning) end
end
local result,warning=C.parse('[Keybinds]\nMenuToggle=F8; os.execute()',keys)
assert(result.name=='F8' and not warning)
print('PASS: default/remapped menu key, comments, invalid and reserved keys')
