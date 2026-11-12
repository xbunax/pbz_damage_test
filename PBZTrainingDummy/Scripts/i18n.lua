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
-- Training arena and independent Sha-Chi statistics.
M.en['附属对象清理失败，已停止训练，请再次移除目标']='Helper cleanup failed; training stopped. Remove the target again'
M.en['目标清理失败，已保留回收记录，请再次移除']='Target cleanup failed; references retained. Try removing it again'
M.en['请先完成旧目标清理']='Remove the previous target before spawning another'
M.en['生命上限须高于目标原生锁血线']='HP cap must exceed the target native health floor'
M.en['训练目标清理失败']='Target cleanup failed'
M.en['自由对练：与目标相距超过 30 米时停止。']='Free sparring stops when you and the target are more than 30 metres apart.'
M.en['削杀气统计（预览）']='Sha-Chi statistics (preview)'
M.en['Boss 训练（实验）']='Boss Training (experimental)'
M.en['Boss 对练（实验）']='Boss training (experimental)'
M.en['新娘阿花']='Hua, the Bride'
M.en['魔渊']='Mo Yuan'
M.en['毕远掌门残躯']='Bi Yuan\'s Remnant'
M.en['训练模式：静止受击、自由对练（实验）；单招和阶段选择暂未开放']='Modes: stationary target and free sparring (experimental); individual moves and phase selection are not available'
M.en['自由对练（实验）']='Free sparring (experimental)'
M.en['当前目标不支持自由对练']='This target does not support free sparring'
M.en['自由对练启动失败，攻击已停止']='Could not start free sparring; attacks stopped'
M.en['自由对练进行中，打开菜单可停止']='Free sparring; open the menu to stop'
M.en['超出训练范围，攻击已停止']='Outside the training range; attacks stopped'
M.en['目标杀气须为 1～10000000']='Target Sha-Chi must be 1 to 10000000'
M.en['无效目标杀气']='Invalid target Sha-Chi'
M.en['训练目标碰撞体不可用']='Target collision capsule is unavailable'
M.en['Boss 出生点空间不足，请选择开阔地面']='Not enough space for the boss; choose open ground'
M.en['原生 AI 生成接口不可用']='Native AI spawn API is unavailable'
M.en['玩家或目标不可用']='Player or target is unavailable'
M.en['玩家或目标已切换场景']='Player or target changed scene'
M.en['训练目标技能组件未就绪']='Target ability component is not ready'
M.en['训练目标属性未就绪']='Target attributes are not ready'
M.en['等待 Boss 登场']='Waiting for the boss entrance'
M.en['等待 Boss 登场动作结束']='Waiting for the boss entrance action to end'
M.en['生命或杀气属性描述不可用']='Health or Sha-Chi attribute descriptors are unavailable'
M.en['资源写入未确认']='Resource write could not be verified'
M.en['资源设置失败，已恢复原值']='Resource settings failed; original values restored'
M.en['资源恢复未确认，请移除目标']='Resource restoration could not be verified; remove the target'
M.en['杀气恢复未确认']='Sha-Chi restoration could not be verified'
M.en['未知伤害作用对象']='Unknown damage recipient'
M.en['本段杀气统计不完整，无法保存']='Sha-Chi statistics are incomplete; cannot save this run'
M.en[' | 削杀气/s %.2f']=' | Sha-Chi/s %.2f'
M.en[' | 杀气未记录']=' | Sha-Chi not recorded'
M.en['杀气上限 %s | 累计削杀气 %.2f\n平均削杀气/s %.2f | 最高单次 %.2f']='Sha-Chi cap %s | Total Sha-Chi damage %.2f\nAverage Sha-Chi/s %.2f | Maximum hit %.2f'
M.en['未记录']='Not recorded'
M.en['杀气统计：未记录']='Sha-Chi statistics: not recorded'
M.en['削杀气比较：未记录']='Sha-Chi comparison: not recorded'
M.en['（A 的削杀气为零）']='(A has zero Sha-Chi damage)'
M.en['B 相比 A：削杀气/s %+.2f %s']='B vs A: Sha-Chi/s %+.2f %s'
M.en['目标、生命杀气设置与训练模式相同；请保持其他测试条件一致']='Target, HP/Sha-Chi settings and mode match; keep other conditions consistent'
M.en['目标、生命杀气设置或训练模式不同或未记录，比较时请注意条件差异']='Target, HP/Sha-Chi settings or mode differ or were not recorded; account for these differences'
M.en['目标杀气  %.0f / %.0f']='Target Sha-Chi  %.0f / %.0f'
M.en['生命 %.0f / %.0f    杀气 %.0f / %.0f']='HP %.0f / %.0f    Sha-Chi %.0f / %.0f'
M.en['开始自由对练']='Start free sparring'
M.en['本次削杀气  %.2f']='Last Sha-Chi damage  %.2f'
M.en['累计削杀气  %.2f']='Total Sha-Chi damage  %.2f'
M.en['平均削杀气/s  %.2f']='Average Sha-Chi/s  %.2f'
M.en['近 5 秒削杀气/s  %.2f']='Recent 5s Sha-Chi/s  %.2f'
M.en['最高单次削杀气  %.2f']='Maximum Sha-Chi hit  %.2f'
M.en['目标已移除，部分附属对象清理失败']='Target removed; some attached actors could not be cleaned up'
M.en['不支持的资源设置']='Unsupported resource settings'
M.en['统计已重置，生命与杀气已回满']='Stats reset; HP and Sha-Chi restored'
M.en['生命与杀气设置已应用，统计已重置']='HP and Sha-Chi settings applied; stats reset'
M.en['生命与杀气设置将在下次召唤生效']='HP and Sha-Chi settings will apply to the next spawn'
M.en['已停止自由对练']='Free sparring stopped'
M.en['自由对练已开始，打开菜单可停止']='Free sparring started; open the menu to stop'
M.en['目标杀气  0 / 3000']='Target Sha-Chi  0 / 3000'
M.en['二级：选择训练目标']='2. Select training target'
M.en['生命上限来源']='HP cap source'
M.en['杀气上限来源']='Sha-Chi cap source'
M.en['自定义']='Custom'
M.en['保留出生上限']='Keep spawn cap'
M.en['自定义生命上限']='Custom HP cap'
M.en['自定义杀气上限']='Custom Sha-Chi cap'
M.en['应用生命与杀气设置并重置统计']='Apply HP and Sha-Chi caps and reset stats'
M.en['完整重开（清理后重新召唤）']='Restart (clean up and respawn)'
M.en['生命 0 / 10000    杀气 0 / 3000']='HP 0 / 10000    Sha-Chi 0 / 3000'
M.en['本次削杀气  0.00']='Last Sha-Chi damage  0.00'
M.en['累计削杀气  0.00']='Total Sha-Chi damage  0.00'
M.en['平均削杀气/s  0.00']='Average Sha-Chi/s  0.00'
M.en['近 5 秒削杀气/s  0.00']='Recent 5s Sha-Chi/s  0.00'
M.en['最高单次削杀气  0.00']='Maximum Sha-Chi hit  0.00'
M.en['削杀气按伤害事件统计，自然恢复和自身消耗不计入。\n生命 DPS 与削杀气速率分别计算；杀气保留原生破防与恢复。']='Sha-Chi damage excludes regeneration and the target’s own spending.\nHP DPS and Sha-Chi/s are separate; native guard break and recovery remain active.'
M.en['清空统计并回满生命与杀气']='Clear stats and restore HP and Sha-Chi'
M.en['目标初始化中：%s']='Target initializing: %s'
M.en['初始化或更新失败，目标已清理，请重新召唤']='Initialization or update failed; target removed. Spawn again'
M.en['训练场']='Training Arena'
M.en['不支持的测试时长']='Unsupported test duration'
M.en['%d 秒测试已结束，结果已冻结；可保存分段或开始新一轮']='The %ds test has ended; results are frozen. Save the run or start a new one'
M.en['定时测试已完成，结果已冻结']='Timed test completed; results frozen'
M.en['当前计时：不限时']='Current timer: unlimited'
M.en['倒计时结束：%d 秒']='Countdown finished: %d seconds'
M.en['当前计时：%d 秒，等待首次命中']='Current timer: %d seconds; waiting for the first hit'
M.en['倒计时已暂停：剩余 %.1f 秒']='Countdown paused: %.1f seconds remaining'
M.en['测试提前结束：剩余 %.1f 秒']='Test ended early: %.1f seconds remaining'
M.en['倒计时：剩余 %.1f / %d 秒']='Countdown: %.1f / %d seconds remaining'
M.en['（已完成）']=' (completed)'
M.en['（未完成）']=' (incomplete)'
M.en['已准备 %d 秒测试，首次有效命中开始倒计时']='%ds test armed; the first valid hit starts the countdown'
M.en['本轮测试时长']='Test duration'
M.en['不限时']='Unlimited'
M.en['5 秒']='5 seconds'
M.en['10 秒']='10 seconds'
M.en['30 秒']='30 seconds'
M.en['应用时长并开始新一轮（清空统计）']='Apply duration and start a new run (clear stats)'
M.en['首次有效命中开始倒计时；暂停时倒计时也暂停。\n到时仅冻结统计，不暂停游戏。切换时长后点击开始新一轮。']='The first valid hit starts the countdown; pausing stats also pauses it.\nThe deadline freezes stats without pausing the game. Apply a new duration to begin another run.'
M.en['本段计时设置不一致，无法保存']='Timer settings do not match this run; cannot save'
M.en['计时模式：未记录']='Timer mode: not recorded'
M.en['计时模式：不限时']='Timer mode: unlimited'
M.en['计时模式：%d 秒%s']='Timer mode: %d seconds%s'
M.en['目标、资源与计时设置相同；请保持其他测试条件一致']='Target, resource and timer settings match; keep other conditions consistent'
M.en['目标、资源、模式或计时设置不同或未记录，比较时请注意条件差异']='Target, resources, mode or timer settings differ or were not recorded; account for these differences'
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
