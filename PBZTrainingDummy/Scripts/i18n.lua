-- Menu translations are presentation only; stable actor IDs and user labels never change.
local M={}
M.en={
 ['伤害测试木桩']='Damage Test Dummy', ['训练设置']='Training', ['伤害统计']='Damage & DPS', ['分段对比']='Compare Runs',
 ['训练目标']='Training Target', ['本轮伤害与 DPS']='Current Damage & DPS', ['已保存的武器测试']='Saved Weapon Tests',
 ['[%s] 打开 / 关闭菜单']='[%s] Toggle menu', ['菜单语言 / Language']='菜单语言 / Language',
 ['一级：图鉴分类']='1. Codex category', ['二级：选择小怪']='2. Select enemy', ['目标最大血量']='Maximum health',
 ['应用血量并重置统计']='Apply health and reset stats', ['关闭木桩仇恨（便于换武器）']='Disable target aggro (weapon swapping)',
 ['召唤木桩']='Spawn target', ['重新召唤到面前']='Respawn in front', ['移除木桩并保留统计']='Remove target and keep stats',
 ['训练模式']='Training mode', ['攻击结束后间隔（秒）']='Delay after attack (seconds)', ['开始循环攻击']='Start attack loop',
 ['停止攻击']='Stop attacks', ['关闭菜单']='Close menu', ['暂停统计']='Pause stats', ['继续统计']='Resume stats',
 ['武器名 / 分段备注']='Weapon / run notes', ['留空则自动编号']='Leave blank for an automatic name',
 ['保存本段，下一段保持暂停']='Save run; pause next run', ['重置统计并回满血']='Reset stats and heal target',
 ['A：基准分段']='A: Baseline run', ['B：对比分段']='B: Comparison run', ['删除 B 选中的记录']='Delete selected run B',
 ['删除保存分段']='Delete saved run', ['删除 B 当前选中的记录？']='Delete the run currently selected as B?', ['删除']='Delete', ['取消']='Cancel',
 ['按角色原生招式开放模式，不移植其他武器招式。\n受击后等待恢复再继续；打开菜单会停止攻击。\n设置在本次游戏内保留。']='Modes use each enemy\'s native attacks.\nThe loop waits for recovery after hits. Opening this menu stops attacks.\nTraining settings last for this game session.',
 ['平均 DPS：首次命中起计时，最短按 1 秒计算。\n暂停冻结时间与全部伤害统计；继续后扣除暂停时长。\n近 5 秒 DPS：最近 5 秒有效计时内的伤害 ÷ 5。\n保存后清空本段并暂停下一段；武器名需手动填写。\n重新召唤会清空未保存的统计；历史分段保留。']='Average DPS starts at the first hit (minimum 1 second).\nPause freezes time and all stats; paused time is excluded.\nRecent DPS = damage in the last 5 measured seconds / 5.\nSaving clears this run and pauses the next. Enter weapon names manually.\nRespawning clears unsaved stats; saved runs are kept.',
 ['记录保存在本机 dps_segments.json，重启后保留。\n最多 100 段；满后请删除不需要的记录。\n比较时请使用相同目标、血量、招式与其他条件。']='Runs are saved locally in dps_segments.json and survive restarts.\nUp to 100 runs; delete unwanted records when full.\nKeep target, health, moves and other test conditions consistent.',
 ['未召唤木桩']='No target spawned', ['等待召唤目标']='Waiting for target', ['木桩已移除，统计与 DPS 保留']='Target removed; damage and DPS retained',
 ['目标正在初始化…']='Initializing target...', ['木桩已就绪']='Target ready', ['测试已重置，木桩满血']='Stats reset; target fully healed',
 ['已选择 %s，请召唤']='Selected %s; spawn to begin', ['血量已应用，统计已重置']='Health applied; stats reset',
 ['血量已设置，下次召唤生效']='Health set for the next spawn', ['木桩仇恨已关闭']='Target aggro disabled', ['木桩仇恨已开启']='Target aggro enabled',
 ['循环攻击已开始，打开菜单可停止']='Attack loop started; open the menu to stop', ['场景或角色已切换，木桩已清理']='Scene or player changed; target removed',
 ['玩家已倒下，木桩已清理']='Player defeated; target removed', ['初始化或更新失败，请移除后重试']='Initialization or update failed; remove target and retry',
 ['操作失败：%s']='Action failed: %s', ['目标生命  %.0f / %.0f']='Target HP  %.0f / %.0f',
 ['目标已移除，结果已冻结']='Target removed; results frozen', ['统计已暂停：伤害与计时均不计入']='Paused: damage and time are excluded',
 ['等待首次命中开始计时']='Waiting for first hit to start timing', ['正在统计，停手仍计时']='Measuring; time continues between hits',
 ['可填写武器名，再保存分段用于对比']='Enter a weapon name and save runs to compare', ['已开始新一轮，等待首次命中']='New run; waiting for first hit',
 ['本轮已清空，继续统计后再开始测试']='Run cleared; resume stats before testing', ['本轮已清空，等待首次命中']='Run cleared; waiting for first hit',
 ['已继续统计，暂停期间的时间与伤害不会计入']='Stats resumed; paused time and damage are excluded', ['已暂停，可更换武器或保存本段']='Paused; swap weapons or save this run',
 ['已保存 #%d %s；%s']='Saved #%d %s; %s', ['下一段已暂停，换武器后点击继续统计']='next run paused; swap weapons, then resume stats',
 ['请召唤目标开始下一段']='spawn a target to start the next run', ['已删除选中的保存分段']='Selected saved run deleted',
 ['本次伤害  %.2f']='Last hit  %.2f', ['累计伤害  %.2f']='Total damage  %.2f', ['命中 %d 次    自动回满 %d 次']='Hits %d    Refills %d',
 ['平均 DPS  %.2f']='Average DPS  %.2f', ['近 5 秒 DPS  %.2f']='Recent 5s DPS  %.2f', ['本轮计时  %.1f 秒%s']='Measured time  %.1f s%s',
 ['（已冻结）']=' (frozen)', ['（已暂停）']=' (paused)', ['最高单次伤害  %.2f']='Maximum hit  %.2f', ['已保存 %d / %d 段%s']='Saved %d / %d runs%s',
 ['暂无保存分段']='No saved runs', ['请选择保存分段']='Select a saved run', ['分段 %d']='Run %d',
 ['#%d %s\n目标：%s / 血量 %.0f\n平均 DPS %.2f | 伤害 %.2f\n有效时间 %.2f 秒 | 命中 %d 次']='#%d %s\nTarget: %s / HP %.0f\nAverage DPS %.2f | Damage %.2f\nMeasured time %.2f s | Hits %d',
 ['保存两段后，可选择 A 与 B 比较']='Save two runs, then select A and B to compare', ['（%+.2f%%）']='(%+.2f%%)', ['（A 的 DPS 为零）']='(A has zero DPS)',
 ['B 相比 A：DPS %+.2f %s\n%s']='B vs A: DPS %+.2f %s\n%s',
 ['目标、血量与训练模式相同；请保持其他测试条件一致']='Target, health and mode match; keep other conditions consistent',
 ['目标、血量或训练模式不同，比较时请注意条件差异']='Target, health or mode differ; take test conditions into account',
 ['训练木桩']='Training Dummies', ['怪面']='Guai Mian', ['龙体改造']='Dragon Modified', ['人偶']='Puppets', ['动物']='Animals', ['人类高手']='Human Masters',
 ['金面人训练木桩']='Gold Mask Training Dummy', ['长枪暴徒']='Spear Thug', ['暴徒']='Sword Thug', ['黄袍暴徒']='Yellow-Robed Thug',
 ['大盾暴徒']='Greatshield Thug', ['刀盾暴徒']='Sword and Shield Thug', ['双斧暴徒']='Twin-Axe Thug', ['疯妇']='Madwoman',
 ['双镐疯妇']='Twin-Pick Madwoman', ['巨刃疯妇']='Greatblade Madwoman', ['山贼']='Bandit', ['山贼高手']='Bandit Master', ['活铜人.拳']='Living Copper Man (Fists)',
 ['无面剑客']='Faceless Swordsman', ['无面枪兵']='Faceless Spearman', ['无面剑客队长']='Faceless Sword Captain', ['无面枪兵队长']='Faceless Spear Captain',
 ['白山女徒']='White Mountain Disciple', ['白山双刺护法']='White Mountain Twin-Spike Guardian', ['鬼差']='Underworld Guard',
 ['阳体人偶']='Yang Puppet', ['阴体人偶']='Yin Puppet', ['剑盾人偶']='Sword and Shield Puppet', ['枪盾人偶']='Spear and Shield Puppet', ['狂犬']='Rabid Dog',
 ['原生红光']='Native red attack', ['原生蓝光']='Native blue attack', ['静止受击']='Stationary target', ['（%s）']=' (%s)',
 ['训练模式：%s%s']='Modes: %s%s', ['、']=', ', ['红光循环']='Red attack loop', ['蓝光循环']='Blue attack loop',
 ['（红蓝招式待核验）']=' (red/blue attacks pending verification)', ['循环红光（实验）']='Red attack loop (experimental)', ['循环蓝光（实验）']='Blue attack loop (experimental)',
 ['攻击已停止']='Attacks stopped', ['等待下一次攻击']='Waiting for next attack', ['等待恢复后继续：%s']='Waiting for recovery: %s',
 ['等待恢复超过 30 秒，已停止，请重新召唤']='Recovery exceeded 30 seconds; stopped. Respawn the target', ['玩家或目标不可用，攻击已停止']='Player or target unavailable; attacks stopped',
 ['距离过远，等待靠近']='Out of range; move closer', ['目标已失去此技能，攻击已停止']='Target lost this skill; attacks stopped', ['等待当前动作结束']='Waiting for current action to finish',
 ['受击或冷却等暂时限制']='Temporarily blocked by hits or cooldowns', ['攻击启动中']='Starting attack', ['攻击执行中']='Attacking', ['攻击启动被打断或未生效']='Attack start interrupted or ineffective',
 ['技能执行超时，攻击已停止']='Skill timed out; attacks stopped', ['打开菜单，攻击已停止']='Menu opened; attacks stopped', ['操作失败，攻击已停止']='Action failed; attacks stopped', ['更新失败，攻击已停止']='Update failed; attacks stopped',
 ['无效攻击间隔']='Invalid attack interval', ['当前角色不支持此攻击']='This target does not support that attack', ['目标尚未拥有该技能，请重新召唤或选择其他模式']='Target lacks this skill; respawn or choose another mode',
 ['等待落地']='Waiting to land', ['技能暂时受限']='Skill temporarily blocked', ['目标未拥有此技能']='Target does not have this skill',
 ['前方没有平坦地面，请换个位置']='No flat ground ahead; try another position', ['无法加载训练木桩资产']='Cannot load target asset', ['前方空间不足，召唤失败']='Not enough space ahead; spawn failed',
 ['训练目标控制器未就绪']='Target controller is not ready', ['训练目标 AI 组件未就绪']='Target AI component is not ready', ['无法限制训练目标行动']='Cannot restrict target movement',
 ['木桩行动限制未生效']='Target movement restriction did not take effect', ['无法解除木桩行动限制']='Cannot release target movement restriction', ['训练目标黑板未就绪']='Target blackboard is not ready',
 ['训练目标仇恨组件未就绪']='Target aggro component is not ready', ['游戏未恢复木桩仇恨，请保持关闭仇恨模式']='Game did not restore target aggro; keep aggro disabled',
 ['无效目标血量']='Invalid target health', ['生命下限设置失败']='Failed to set minimum health', ['目标最大生命设置失败']='Failed to set maximum health',
 ['请先进入可自由行动的场景']='Enter a playable scene first', ['请先召唤并等待木桩就绪']='Spawn a target and wait until it is ready', ['请先召唤并等待目标就绪']='Spawn a target and wait until it is ready',
 ['无法继续统计，请重置后重试']='Cannot resume stats; reset and retry', ['无法暂停统计，请重置后重试']='Cannot pause stats; reset and retry', ['暂停失败，未保存']='Could not pause; run was not saved',
 ['不支持的训练模式']='Unsupported training mode', ['当前角色或模式不支持循环攻击']='This target or mode does not support attack loops', ['目标正在初始化，请稍后再试']='Target is initializing; try again shortly',
 ['该图鉴分类暂未加入训练目标']='This codex category has no training targets yet', ['未知训练目标']='Unknown training target', ['目标血量须为 10～10000000']='Target health must be 10 to 10000000', ['攻击间隔须为 0.5～30 秒']='Attack interval must be 0.5 to 30 seconds',
 ['此目标缺少伤害统计被动，暂不支持，请更换目标']='Target lacks the damage-tracking passive; choose another target',
 ['历史主文件异常，已从本地备份恢复']='History file was invalid; restored the local backup', ['历史文件无法读取；请先备份并检查 dps_segments.json']='Cannot read history; back up and check dps_segments.json',
 ['已恢复历史备份']='History backup restored', ['历史备份无法读取，请先检查文件']='Cannot read history backup; check the file',
 ['分段数据无法保存或已超过大小限制']='Run data cannot be saved or exceeds the size limit', ['临时分段文件写入失败，当前统计已保留']='Temporary file write failed; current stats retained',
 ['历史备份写入失败，当前统计已保留']='Backup write failed; current stats retained', ['历史文件写入未确认，当前统计已保留']='History write could not be verified; current stats retained',
 ['已保存 100 段，请先删除不需要的对比记录']='100 runs saved; delete unwanted records first', ['本段还没有有效伤害，无法保存']='No valid damage in this run; cannot save',
 ['本段目标信息不完整']='Run target details are incomplete', ['分段名称不是有效文字']='Run name is not valid text', ['本段目标名称无效']='Run target name is invalid', ['没有选中保存记录']='No saved run selected',
 ['语言设置保存失败，已保留原语言']='Could not save language setting; previous language retained', ['语言设置无效，已使用简体中文']='Invalid language setting; using Simplified Chinese',
 ['已切换菜单语言']='Menu language changed',
}
function M.new(path,fs)
    fs=fs or io
    local s={language='zh',warning=nil}
    local f=fs.open(path,'rb')
    if f then
        local value=(f:read(1024)or ''):match('^%s*(.-)%s*$');f:close()
        if value=='zh' or value=='en' then s.language=value else s.warning='语言设置无效，已使用简体中文' end
    end
    function s:t(key,...)
        local value=self.language=='en' and M.en[key]or key
        value=value or key
        if select('#',...)>0 then return string.format(value,...)end
        return value
    end
    -- Engine errors may include a source prefix; translate the known reason only.
    function s:message(value)
        if type(value)=='function' then return value()end
        value=tostring(value)
        local reason=value:match('^等待恢复后继续：(.*)$')
        if reason then return self:t('等待恢复后继续：%s',self:message(reason))end
        return self:t(value)
    end
    function s:set(language)
        if language~='zh' and language~='en' then return false,'语言设置无效，已使用简体中文' end
        if language==self.language then return true end
        local f=fs.open(path..'.tmp','wb')
        if not f then return false,'语言设置保存失败，已保留原语言' end
        local written=f:write(language..'\n');local closed=f:close()
        local function checked(filePath)
            local check=fs.open(filePath,'rb');if not check then return false end
            local data=check:read(1024);check:close();return data==language..'\n'
        end
        if not written or not closed or not checked(path..'.tmp')then return false,'语言设置保存失败，已保留原语言' end
        local oldFile=fs.open(path,'rb')
        local oldData
        if oldFile then oldData=oldFile:read(1024);oldFile:close()end
        f=fs.open(path,'wb');if not f then return false,'语言设置保存失败，已保留原语言' end
        written=f:write(language..'\n');closed=f:close()
        if not written or not closed or not checked(path)then
            if oldData then
                local restore=fs.open(path,'wb')
                if restore then restore:write(oldData);restore:close()end
            end
            return false,'语言设置保存失败，已保留原语言'
        end
        self.language=language;self.warning=nil;return true
    end
    return s
end
return M
