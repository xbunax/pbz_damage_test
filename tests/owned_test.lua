local Owned=dofile(arg[1]..'/PBZTrainingDummy/Scripts/owned.lua')
local objects={}
local calls={}
local function actor(id,parent,instigator)
 local o={id=id,valid=true,owner=parent,instigator=instigator}
 function o:IsValid()return self.valid end
 function o:GetAddress()return self.id end
 function o:GetOwner()return self.owner end
 function o:GetInstigator()return self.instigator end
 function o:K2_DestroyActor()calls[#calls+1]=self.id;self.valid=false end
 objects[#objects+1]=o;return o
end
local player=actor('player')
local map=actor('map')
local tracker=Owned.new(true,{scan=function()return objects end})
local root=actor('boss');tracker:bind(root,player)
map.owner=root -- A changed owner never makes a pre-existing map actor ours.
local helper=actor('helper',root)
local child=actor('child',helper)
local projectile=actor('projectile',nil,root)
local unrelated=actor('unrelated')
local cycle=actor('cycle');cycle.owner=cycle
assert(tracker:clear())
assert(root.valid and player.valid and map.valid and unrelated.valid and cycle.valid)
assert(not helper.valid and not child.valid and not projectile.valid)
local position={};for i,id in ipairs(calls)do position[id]=i end
assert(position.child<position.helper,'Clean descendants before their owner')
assert(#calls==3,'Each actor gets one destroy request')
-- An exception keeps explicit references even if its parent goes away.
local stuck=actor('stuck',root)
stuck.K2_DestroyActor=function()error('injected failure')end
assert(not tracker:clear()and stuck.valid and tracker.pending.stuck)
stuck.owner=nil
stuck.K2_DestroyActor=function(self)self.valid=false end
assert(tracker:clear()and not stuck.valid,'Failed actors remain retryable without their original owner')
-- Unreal can defer destruction while the wrapper remains valid for this frame.
local delayed=actor('delayed',root);local requests=0
delayed.K2_DestroyActor=function()requests=requests+1 end
assert(tracker:clear()and requests==1,'Do not destroy a pending actor twice in one cleanup pass')
print('PASS: owned descendants/projectiles, map and player isolation, cycles, cleanup retries and deferred destruction')
