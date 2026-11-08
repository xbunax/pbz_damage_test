-- Finite-state attack scheduling; engine calls are supplied by the private adapter.
local M={}
local RETRY_INTERVAL=0.5
local RECOVERY_TIMEOUT=30
function M.new(adapter,control)
 return {api=adapter,control=control,running=false,phase='idle',completed=0,message='攻击已停止'}
end
function M.stop(s,reason)
 s.running=false;s.phase='idle';s.started=nil;s.nextAt=nil;s.recoverySince=nil
 s.message=reason or '攻击已停止'
 if s.api.valid(s.control.actor)then s.api.hold(s.control)end
end
function M.start(s,player,skill,interval,now)
 assert(type(interval)=='number' and interval>=0.5 and interval<=30,'无效攻击间隔')
 assert(type(skill)=='string','当前角色不支持此攻击')
 M.stop(s)
 assert(s.api.hasSkill(s.control.actor,skill),'目标尚未拥有该技能，请重新召唤或选择其他模式')
 s.api.release(s.control,player)
 s.skill=skill;s.interval=interval;s.nextAt=now+0.5;s.completed=0
 s.retries=0;s.retriesTotal=0;s.recoverySince=nil;s.lastFailure=nil
 s.running=true;s.phase='waiting';s.message='等待下一次攻击'
end
local function recover(s,now,reason)
 s.recoverySince=s.recoverySince or now
 s.phase='waiting';s.started=nil;s.nextAt=now+RETRY_INTERVAL
 s.retries=s.retries+1;s.retriesTotal=s.retriesTotal+1;s.lastFailure=reason
 s.message='等待恢复后继续：'..reason
 if now-s.recoverySince>=RECOVERY_TIMEOUT then M.stop(s,'等待恢复超过 30 秒，已停止，请重新召唤')end
end
function M.tick(s,player,now)
 if not s.running then return end
 local A=s.api
 if not A.valid(s.control.actor)or not A.valid(player)or A.health(player)<=0 then
  M.stop(s,'玩家或目标不可用，攻击已停止');return
 end
 local active=A.skillActive(s.control.actor,s.skill)
 if s.phase=='waiting' and now>=s.nextAt then
  if A.distance(s.control.actor,player)>1000 then
   s.message='距离过远，等待靠近';s.recoverySince=nil;s.nextAt=now+RETRY_INTERVAL;return
  end
  if not A.hasSkill(s.control.actor,s.skill)then M.stop(s,'目标已失去此技能，攻击已停止');return end
  if A.busy(s.control.actor)then recover(s,now,'等待当前动作结束');return end
  local reason=A.recoveryReason and A.recoveryReason(s.control.actor)
  if reason then recover(s,now,reason);return end
  A.aim(s.control,player)
  local activated,failure=A.attack(s.control.actor,s.skill)
  if not activated then recover(s,now,failure or '受击或冷却等暂时限制');return end
  s.phase='starting';s.started=now;s.message='攻击启动中'
 elseif s.phase=='starting' then
  if active then
   s.phase='active';s.message='攻击执行中';s.recoverySince=nil;s.retries=0
  elseif now-s.started>=1.5 then recover(s,now,'攻击启动被打断或未生效');return end
 elseif s.phase=='active' and not active then
  s.completed=s.completed+1;s.phase='waiting';s.nextAt=now+s.interval
  s.started=nil;s.message='等待下一次攻击'
 end
 if s.started and now-s.started>15 then M.stop(s,'技能执行超时，攻击已停止')end
end
return M
