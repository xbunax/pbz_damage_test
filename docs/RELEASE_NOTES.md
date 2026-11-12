# v0.1.0-preview.4：训练场与定时 DPS / Training arena and timed DPS

## 中文

- **Boss 训练（实验）**：加入新娘阿花、普通魔渊、毕远掌门残躯；支持静止受击、原生 AI 自由对练和清理后重新召唤。打开菜单或双方距离超过 30 米时停止对练，尚未开放指定招式与阶段选择。
- **生命与杀气独立设置**：分别自定义上限或保留目标出生上限，写入后读回，失败回滚或保留回收记录。保留更高的原生生命锁血线，生命自动回血不补满杀气。
- **双通道统计**：显示生命与杀气当前值／上限，独立统计生命 DPS 和本次、累计、最高单次、平均及近 5 秒削杀气；纯削杀气命中也支持计时与保存。
- **定时 DPS**：可选不限时、5 秒、10 秒或 30 秒。首次有效命中开始倒计时，暂停统计同步暂停倒计时；准确截止后冻结结果并排除后续命中，提前移除目标保留实际测量时长。到点不暂停游戏或停止目标。
- **分段历史**：历史格式升级为 v2，保存生命／杀气设置、计时窗口及完成状态；兼容旧记录，缺失的杀气或计时信息显示“未记录”，比较不同条件时提示差异。
- **生命周期与菜单**：先登记生成对象再执行登场，初始化超时回收；按归属清理新增附属 Actor，清理失败保留引用供重试。中英文菜单、设置和统计同步更新。
- **最小安装包**：仅包含运行 Lua、默认配置、必要许可证，以及整合包必需的固定版本加载器。文档、测试、维护脚本、日志、个人历史和其他 Mod 均不进入安装包；SHA256SUMS 单独提供。

**验证范围**：20 组 Lua 5.4 离线回归、6 项 Python 打包测试以及源码／安装包一致性校验。Boss 登场、攻击、阶段与剧情隔离、削杀气和真实扣条、倒计时 UI 仍需实机验收；离线通过不代表全部游戏内兼容。黄金火铳反馈尚未完成实机归因，本版不声明修复该反馈。

**安装与升级**：已有正常工作的 UE4SS 使用 `mod-only`；没有运行库才使用 `with-UE4SS`，两者择一。升级前备份 `config.ini`、`ui_language.txt`、`dps_segments.json` 及其 `.bak`；回退 preview.3 时恢复升级前的历史备份。请下载 Release 安装包，不要把 GitHub 的 Source code 当作整合包。

## English

- **Boss training (experimental):** adds Hua, the Bride, regular Mo Yuan and Bi Yuan's Remnant, with stationary targets, native-AI sparring and cleanup followed by respawning. Opening the menu or exceeding a 30-metre player-to-target distance stops sparring. Individual moves and phase selection are not available.
- **Independent HP and Sha-Chi caps:** choose custom caps or restore each target's spawn caps. Writes are read back, with rollback or retained cleanup references on failure. Higher native HP floors are preserved; automatic HP refills do not refill Sha-Chi.
- **Separate damage channels:** live HP/Sha-Chi values and separate HP DPS and last, total, maximum, average and recent-five-second Sha-Chi damage. Sha-Chi-only hits can start timing and be saved.
- **Timed DPS:** unlimited, 5-, 10- and 30-second windows start on the first valid hit. Pausing statistics also pauses the countdown. Results freeze at the exact deadline and exclude later hits; early removal keeps the actual measured interval. The deadline does not pause the game or stop the target.
- **Saved runs:** history v2 records resource settings, timer duration and completion status while reading older records. Missing Sha-Chi or timer information stays “not recorded”; comparisons flag different conditions.
- **Lifecycle and localization:** actors are registered before entrance callbacks, initialization timeouts trigger cleanup, and new actors with explicit ownership links are reclaimed. Failed cleanup retains references for retry. Chinese and English menus cover the added controls and statistics.
- **Minimal packages:** runtime Lua, default configuration, required licences, and the pinned loader only in the bundled variant. No documentation, tests, maintenance scripts, logs, personal history or unrelated mods ship in either ZIP. SHA256SUMS is a separate asset.

**Validation:** 20 offline Lua 5.4 suites, 6 Python packaging tests, and source/package consistency checks. Boss entrance, combat, phase/story isolation, Sha-Chi events versus actual depletion and countdown UI still require in-game validation. Offline tests do not establish complete game compatibility. The Goldblaze report has not been reproduced in-game; this release does not claim to fix it.

**Install/upgrade:** use `mod-only` with an existing working UE4SS installation; use `with-UE4SS` only when no loader is installed. Choose one. Back up `config.ini`, `ui_language.txt`, `dps_segments.json` and its `.bak` before upgrading; restore the old history backup when reverting to preview.3. Download the Release installation ZIP rather than GitHub's automatic Source code archive.

# v0.1.0-preview.3：训练设置、分段 DPS 与双语菜单

- **分类选择小怪**：共 25 个训练目标，按照原生图鉴 EnemyType 分类，两级菜单选择，第二级支持搜索。Boss 仍处于调研阶段。
- **血量与仇恨**：血量可设为 10～10000000；可关闭木桩仇恨，方便攻击后更换武器。
- **原生红蓝循环（实验）**：各角色仅显示已配置的原生模式；完美闪避反击或临时状态阻止攻击时，等待恢复并限频重试。打开 F8 菜单停止攻击。
- **DPS 暂停与继续**：统计平均 DPS、近 5 秒 DPS、时长和最高单次伤害；暂停期间冻结计时与伤害，继续时扣除暂停时长。
- **分段保存与对比**：填写武器名或备注，保存后下一段保持暂停，换武器后继续。最多保存 100 段，重启保留；对比页选择 A/B，显示 DPS 差值、百分比及目标条件差异。
- **中英文切换**：训练设置页顶部选择“简体中文 / English”，即时刷新并记住选择。切换保留当前木桩、统计、暂停状态和输入；用户武器名、备注保持原文。英文目标名和分类为 Mod 说明性译名。
- **修复**：恢复仇恨的 bool Out 参数、受击后失效的行动限制句柄，以及反击后循环无法继续的问题。
- **最小安装包**：只打包运行 Lua、配置、必要加载器依赖及许可证。无 README、docs、Word/PDF、维护脚本、测试、个人数据或包内构建清单；SHA256SUMS 单独提供。

**安装与升级**：已有 UE4SS 使用 `mod-only`；没有运行库才使用 `with-UE4SS`，安装位置为真实 `PBZ.exe` 所在目录（通常是 `platform/steam`）。升级前备份 `config.ini`、`ui_language.txt`、`dps_segments.json` 及其 `.bak`。详细步骤见[仓库 README](https://github.com/xbunax/pbz_damage_test/blob/v0.1.0-preview.3/README.md)。

验证：14 组 Lua 5.4 回归覆盖统计、暂停、循环恢复、分类、语言和菜单联动，打包测试检查白名单、文件一致性与多余文件拦截。中文输入、英文布局、全部小怪和红蓝防御判定仍需实机验收；CI 通过不等于游戏内完整验证。

# v0.1.0-preview.2：独立安装说明与精简发布包

- 明确木桩可独立安装运行：with-UE4SS 使用上游 PBZ 专用加载器，不包含卡肉 Mod、面板或 PBZHitEnhance 启动组件。
- 补充新版 build 26367565 / CL302256 的启动排查与旧外置运行库迁移步骤。旧卡肉代理的版本拦截修复独立发布在 [PBZHitEnhance v0.4.0-preview.3](https://github.com/xbunax/pbz_hit_enhance/releases/tag/v0.4.0-preview.3)，更新木桩 Lua 无法修复旧代理。
- 两个 ZIP 移除 Check-Compatibility.ps1、开发依赖清单和历史发布说明；按明确白名单打包并检查禁止的文件类型，防止维护脚本、日志或本地测试文件进入安装包。
- 保留 Mod Only 与含 UE4SS 两个包、F8 按键映射、私有菜单依赖、许可证和校验清单。安装均通过复制文件完成。

游戏新版已在原有运行库环境验证冷启动、Mod 初始化及 F8 菜单。独立上游加载器组合和新版全部伤害功能尚未完成新一轮实测。此次不加入红蓝光攻击、仇恨开关或多小怪选择。

下载本页 ZIP 而不是 Source code。已有正常工作的 UE4SS 使用 mod-only；单独安装木桩使用 with-UE4SS。两套独立整合包不能覆盖叠装。移除 ps1 不代表第三方平台一定不会要求审核，UE4SS DLL 和运行必需 Lua 仍保留。
