-- Execute the bundled menu's module initialization, rather than syntax-checking it only.
-- No UMG objects or game hooks should be needed until the host calls Init/Open.
package.loaded['PBZTrainingDummy.UEHelpers']={}
local menu=dofile(arg[1]..'/PBZTrainingDummy/Scripts/vendor/ModMenu.lua')
assert(type(menu)=='table')
for _,name in ipairs({'Init','Register','Open','Close','Toggle','SetLabel','SetButtonLabel','SetButtonEnabled'}) do
    assert(type(menu[name])=='function','Missing bundled menu API: '..name)
end
assert(package.preload['PBZDummyMenu.core.util'],'Private module namespace missing')
assert(not package.preload['ModMenu.core.util'],'Public/shared module namespace was overwritten')
print('PASS: private menu bundle loads and exports its API without touching shared namespaces')
