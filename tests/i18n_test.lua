local root=arg[1]
local I18n=dofile(root..'/PBZTrainingDummy/Scripts/i18n.lua')
local fs=dofile(root..'/tests/memory_fs.lua')
local path='isolated/ui_language.txt'
local L=I18n.new(path,fs)
assert(L.language=='zh' and L:t('训练设置')=='训练设置')
assert(L:set('en') and fs.files[path]=='en\n')
assert(I18n.new(path,fs).language=='en','Language survives a fresh instance')
local function T(key,...)return L:t(key,...)end
assert(T('平均 DPS  %.2f',123.456)=='Average DPS  123.46')
assert(T('Unknown engine detail')=='Unknown engine detail')
assert(L:message('等待恢复后继续：等待落地')=='Waiting for recovery: Waiting to land')
local Targets=dofile(root..'/PBZTrainingDummy/Scripts/targets.lua')
for _,row in ipairs(Targets.list)do
 assert(I18n.en[row.name],'Missing target translation: '..row.id)
 local label=Targets.label(row.id,T)
 assert(not label:find('[\128-\255]') and Targets.get(row.id)==row,'Target translations must keep IDs unchanged')
end
for _,row in ipairs(Targets.categories(T))do assert(not row.label:find('[\128-\255]'))end
assert(Targets.description('spear',T):find('Red attack loop',1,true))
assert(Targets.modes('sword',T)[2].value=='blue')
local Segments=dofile(root..'/PBZTrainingDummy/Scripts/segments.lua')
local row={id=5,label='用户自填：长刀',targetName='old name',targetId='gold',maxHP=10000,
 dps=100,total=1000,seconds=10,events=5,mode='hold'}
assert(Segments.describe(row,T,Targets.label('gold',T)):find(row.label,1,true),'User labels must not be translated')
row.autoLabel=true;assert(Segments.name(row,T)=='Run 5')
fs.fail=path..'.tmp'
assert(not L:set('zh') and L.language=='en' and fs.files[path]=='en\n')
fs.fail=path;assert(not L:set('zh') and L.language=='en')
fs.fail=nil
assert(not L:set('invalid') and L.language=='en')
assert(L:set('zh') and I18n.new(path,fs).language=='zh')
fs.files[path]='bad'
local fallback=I18n.new(path,fs);assert(fallback.language=='zh' and fallback.warning)
print('PASS: bilingual formatting, stable target IDs, native mode labels, user text retention, saved choice, write failures and fallback')
