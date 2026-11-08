local root=arg[1]
package.loaded['PBZTrainingDummy.UEHelpers']={}
dofile(root..'/PBZTrainingDummy/Scripts/vendor/ModMenu.lua')
local json=require('PBZDummyMenu.store.json')
local codec={Encode=json.Encode,Decode=json.DecodeObject}
local Segments=dofile(root..'/PBZTrainingDummy/Scripts/segments.lua')
local fs=dofile(root..'/tests/memory_fs.lua')
local path='isolated/dps_segments.json'
local store=Segments.new(path,codec,fs)
local snap={total=1000,seconds=10,maximum=200,events=5,refills=1}
local meta={targetId='gold',targetName='金面人',maxHP=10000,mode='hold'}
assert(#store.rows==0 and store:options()[1].value=='none')
local a=assert(store:add(snap,meta,'长刀 A','2026-11-08'))
assert(a.id==1 and a.dps==100 and a.label=='长刀 A' and #store.rows==1)
a.total=1;snap.total=2000;meta.maxHP=25000
assert(store:get(1).total==1000 and store:get(1).maxHP==10000,'Saved records are immutable copies')
local b=assert(store:add(snap,meta,'双刀 B','2026-11-08'))
assert(b.id==2 and b.dps==200 and fs.files[path..'.bak'])
assert(Segments.compare(store:get(1),b):find('+100.00%%'))
assert(Segments.compare(store:get(1),b):find('不同',1,true))
assert(Segments.describe(b):find('双刀 B',1,true))
local reload=Segments.new(path,codec,fs)
assert(#reload.rows==2 and reload.nextId==3 and reload:get(2).label=='双刀 B')
fs.fail=path..'.tmp'
local row,why=reload:add(snap,meta,'写入失败')
assert(not row and why and #reload.rows==2 and reload.nextId==3)
fs.fail=path..'.bak';assert(not reload:delete(1) and #reload.rows==2)
fs.fail=path;assert(not reload:add(snap,meta,'主文件不可写') and #reload.rows==2)
fs.fail=nil
local empty={total=0,seconds=0,maximum=0,events=0,refills=0}
assert(not reload:add(empty,meta,'empty'))
assert(not reload:add(snap,{maxHP=10000,targetId='gold',targetName='金面人',mode={}},'bad'))
local long=assert(reload:add(snap,meta,string.rep('刀',80)))
assert(utf8.len(long.label)==64,'Truncation must preserve complete UTF-8 characters')
assert(reload:delete(2) and not reload:get(2) and reload.nextId==4)
local replacement=assert(reload:add(snap,meta,''));assert(replacement.id==4 and replacement.label=='分段 4')
local valid=fs.files[path]
fs.files[path]='corrupt'
local recovered=Segments.new(path,codec,fs)
assert(not recovered.blocked and recovered.warning and #recovered.rows==2)
fs.files[path..'.bak']='also corrupt'
local blocked=Segments.new(path,codec,fs)
assert(blocked.blocked and not blocked:add(snap,meta,'do not overwrite'))
assert(fs.files[path]=='corrupt')
fs.files[path]=valid
local tampered=json.DecodeObject(valid);tampered.records[1].dps=999
fs.files[path]=json.Encode(tampered);fs.files[path..'.bak']=nil
assert(Segments.new(path,codec,fs).blocked,'Reject inconsistent saved DPS')
fs.files={};local full=Segments.new(path,codec,fs)
for i=1,Segments.LIMIT do assert(full:add(snap,meta,'武器 '..i))end
assert(not full:add(snap,meta,'overflow') and #full.rows==Segments.LIMIT)
print('PASS: archive persistence/reload, immutable snapshots, UTF-8 names, comparisons, deletes, write failures, corruption recovery and capacity')
