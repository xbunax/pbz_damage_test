local root=arg[1]
package.loaded['PBZTrainingDummy.UEHelpers']={}
dofile(root..'/PBZTrainingDummy/Scripts/vendor/ModMenu.lua')
local json=require('PBZDummyMenu.store.json')
local codec={Encode=json.Encode,Decode=json.DecodeObject}
local Segments=dofile(root..'/PBZTrainingDummy/Scripts/segments.lua')
local fs=dofile(root..'/tests/memory_fs.lua')
local path='isolated/dual-history.json'
local legacy={id=1,label='old',targetId='gold',targetName='金面人',mode='hold',created='2026-11-08',
    maxHP=10000,total=500,maximum=500,seconds=5,dps=100,events=1,refills=0}
fs.files[path]=json.Encode({version=1,nextId=2,records={legacy}})
local store=Segments.new(path,codec,fs)
assert(not store.blocked and #store.rows==1)
assert(store:get(1).shachiTotal==nil and store:get(1).maxShachi==nil)
assert(Segments.describe(store:get(1)):find('杀气统计：未记录',1,true))
assert(store:options()[1].label:find('杀气未记录',1,true))
local snap={total=0,maximum=0,events=2,refills=0,seconds=4,
    shachiTotal=1000,shachiMaximum=700,shachiLast=300,shachiDps=250,shachiRecentDps=200,testDuration=0,completed=false}
local meta={targetId='ahua',targetName='阿花',maxHP=10000,maxShachi=3000,mode='free',
    healthPolicy='native',shachiPolicy='custom',level=19,difficulty=2,profile='ahua',testDuration=0}
local row=assert(store:add(snap,meta,'纯削杀气'))
assert(row.id==2 and row.dps==0 and row.shachiDps==250 and row.shachiMaximum==700)
assert(row.maxShachi==3000 and row.healthPolicy=='native' and row.level==19)
local saved=json.DecodeObject(fs.files[path])
assert(saved.version==2 and saved.records[1].shachiTotal==nil,'Migrated legacy rows stay unknown, not zero')
local reload=Segments.new(path,codec,fs)
assert(not reload.blocked and #reload.rows==2 and reload:get(2).shachiDps==250)
assert(reload:get(1).shachiDps==nil)
assert(Segments.describe(row):find('1000.00',1,true))
assert(Segments.compare(row,row):find('相同',1,true))
assert(Segments.compare(store:get(1),row):find('削杀气比较：未记录',1,true))
meta.shachiPolicy='native'
local different=assert(reload:add(snap,meta,'原生杀气'))
assert(Segments.compare(row,different):find('不同或未记录',1,true),'Policy differences affect comparison conditions')
meta.shachiPolicy='custom';meta.maxShachi=6000
different=assert(reload:add(snap,meta,'不同上限'))
assert(Segments.compare(row,different):find('不同或未记录',1,true))
meta.maxShachi=3000;snap.shachiTotal=2000
different=assert(reload:add(snap,meta,'更高削杀气'))
assert(Segments.compare(row,different):find('削杀气/s +250.00',1,true))
fs.fail=path..'.tmp'
local count=#reload.rows
assert(not reload:add(snap,meta,'failure') and #reload.rows==count)
fs.fail=nil
snap.shachiMaximum=3000
assert(not reload:add(snap,meta,'bad max'))
snap.shachiMaximum=700;meta.healthPolicy='invalid'
assert(not reload:add(snap,meta,'bad policy'))
meta.healthPolicy='native';meta.maxShachi=-1
assert(not reload:add(snap,meta,'bad max Shachi'))
local doc=json.DecodeObject(fs.files[path]);doc.records[2].shachiDps=999
fs.files[path]=json.Encode(doc);fs.files[path..'.bak']=nil
assert(Segments.new(path,codec,fs).blocked,'Inconsistent saved Shachi rates are rejected')
print('PASS: v1 migration, missing-vs-zero Shachi, Shachi-only runs, comparisons, persistence and corrupt-data rejection')
