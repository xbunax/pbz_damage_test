# UE4SS 与游戏兼容性

## preview.4 定时统计

倒计时仅使用已有 `GameplayStatics.GetTimeSeconds` 和纯 Lua 会话状态，不新增游戏 Hook 或修改伤害计算。5／10／30 秒从首个有效生命或杀气事件开始，按有效计时轴的半开区间 `[开始, 开始+时长)` 接收事件；每次伤害和100ms更新均检查截止。暂停时间扣除，晚到更新仍冻结在准确截止点。

结束后目标仍正常受击和回血，但两通道伤害、命中、自动回血次数和计时冻结。实时生命／杀气显示继续反映游戏状态。提前移除不会伪造完成；历史记录保留测试时长和完成状态。20 组 Lua 5.4 离线测试覆盖核心与菜单路径，实际 UI 倒计时尚未实机验收。

## preview.4 本地开发验证范围

2026-11-11 的开发基线是已安装 Steam build 26367565，PBZ.exe SHA256 为 `4415933ce33476f14c837abb61a1b60af8b78cd81783896501913a7aac69e423`；本轮通过源码与同二进制历史反射核对接口，未启动游戏或生成 Boss。

Boss 生成使用历史反射中 `/SGameAI/FunctionLibrary/BP_SGameAIFunctionLibrary.BP_SGameAIFunctionLibrary_C` 的 `SpawnAIDefered`、`FinishSpawnAIDefered`、`ActivateAI`。结束生成后先临时关闭仇恨，再请求正常登场；组件、属性、地面和非行动状态稳定后才冻结为待训练目标。自由对练明确调用已导出的 `SGameAIComponent.StartAI()`，与单招循环分开。15 秒内未就绪则回收，不自动重新召唤。

血量和杀气使用原生配置中远程 `GameplayAttribute` 描述符；先解析全部描述符，写上限、下限与当前值后读回。当前值恢复跟随上限，失败恢复原值，回滚不确定时回收目标。保留更高的原生 Health_Min，无法保证阻止 Boss 低血阶段或处决；原生阶段改变最低血线时可能需要完整重开。

`BasicAttributeSet.Shachi`／`Shachi_Max` 是实时杀气来源；事件解析把 `GeneralDamage.*` 与 `AngerDamage.*` 分成两通道，排除 `PoiseDamage` 和资源回复。只在防守方被动回调与 payload.TargetActor 一致时处理事件，并根据训练实例是 Target 还是 `GetDamageSourceOwner()` 返回的 Attacker 选择分支。历史本机日志观察到 `AngerDamage.Normal`，但尚未逐击对照真实 Shachi 变化；普通／精准防御可能走不同回调路径，不能声明全部覆盖。条差值不用于累计，避免把自然恢复、自身消耗和破防回满误计为伤害。当前仍按训练目标实例统计，不承诺仅包含玩家来源。

Actor 所有权清理在生成前记录现有 Actor，生成后处理新增且 Owner／Instigator 链能连回目标的对象。已有地图 Actor 不因归属变化被销毁。无归属对象、某些全局 HUD／音乐／镜头和剧情回调不在通用归属清理保证范围内；若主 Actor 被游戏先行销毁，尚未登记的子对象也可能无法追溯。三名 Boss、原生攻击、导航、低血线及清理必须实机验收后再声明支持。清理失败保留对象和控制器引用，不自动反复生成；换图清理不向新玩家 Pawn 建立旧 Boss 仇恨。

离线：19 组 Lua 5.4 测试、6 项 Python 测试；使用 `tools/validate.py`（原生 Lua/luac）或已安装 `lupa.lua54` 的 `tools/validate_lupa.py`。本轮使用后者。发行包包含新增的 `owned.lua`，继续按运行文件白名单检查。

## 固定实测组合

| 内容 | 标识 |
| --- | --- |
| PBZ | Steam build 26266538 / UE 5.7.4 / CL 301524 |
| PBZ.exe SHA256 | `7b4fcd286a350780faf0824d73aa150b21cbf1bccde883e6a96386cbe09973b4` |
| UE4SS | `v3.0.1-1183-gcdbc0b66`，PBZ 专用发行归档 |
| UE4SS.dll SHA256 | `c273e7228687b647226fd63d7ca65888d313ece6be18996ec1320d00a5efe1f8` |
| 上游 ZIP SHA256 | `5328f91d13bd93f080fafae9e7c07790ae838d65e94545831d6676c4c1870d4d` |

上游：[KintaroModding/ue4ss 发行页](https://github.com/KintaroModding/ue4ss/releases/tag/v3.0.1-1183-gcdbc0b66)。具体下载地址固定在 `dependencies.json`，不会自动取 latest 或其他游戏的变体。该发行页也含其他游戏的 ZIP，不能互换。

实测使用上述 DLL 与已有 PBZHitEnhance 加载器。with-UE4SS 发行包采用同一上游归档里的独立 `dwmapi.dll`；CI 对归档、DLL 和包布局进行验证，尚未对该独立加载组合完成新的游戏启动回归。兼容性边界应以此说明为准。

## 所需接口与设置

需要 Lua 5.4、`RegisterHook` / `UnregisterHook`、`RegisterKeyBind`、`LoadAsset`、`StaticConstructObject`、`ExecuteInGameThread`、`LoopInGameThreadWithDelay`、`FName`、对象查找和 `ModRef`。入口先检查基本 API，缺失时记录日志并停止初始化，不生成目标。

`FName` 是可调用的构造器，UE4SS 可以通过带受保护元表的 userdata 暴露它；不能仅用 `type(FName)` 或读取 `getmetatable().__call` 判定是否存在。入口改为通过 `FNAME_Find` 查找现有 `None` 名称，直接验证构造器可用性，不新增名称。预览版重发修复了这个导致正确安装仍被停用的检查，并加入了受保护元表的回归测试。

with-UE4SS 自带的设置来源于实测运行库配置：

- `DefaultExecuteInGameThreadMethod = EngineTick`，`HookEngineTick = 1`，`HookUObjectProcessEvent = 1`。
- `HookProcessInternal = 1`、`HookProcessLocalScriptFunction = 1` 用于游戏蓝图伤害回调。
- 保留 PBZ 专用签名、MemberVariableLayout 和上游 SDK backend 文件。
- 关闭自动热重载；更新后正常重启游戏。当前不支持重复热加载。

mod-only 不写上述设置，不带公共签名、DLL、mods.txt 或 shared 文件夹。已有运行库应自行核对能力与设置；不要用本项目整合配置覆盖其他 Mod 所需的配置。

## 本项目做出的兼容处理

- 通过反射的 `BeginDeferredActorSpawnFromClass` / `FinishSpawningActor` 生成目标，避免当前 UE4SS 构建中的原生 `UWorld:SpawnActor` 兼容问题。
- 修改属性时使用资产中远程 `GameplayAttribute` 结构引用。当前构建会在某些 UFunction 返回值转换时漏掉 `FieldPathProperty`；把转换后的 Lua 表重新传入属性接口曾导致游戏退出。
- 伤害 Hook 过滤目标实例及防守方 Avatar，只统计本项目生成目标的生命伤害，避免同一次攻击重复计数。
- 弱对象数组使用下标访问，规避此版本 `ForEach` 对 `WeakObjectProperty` 的 GetParam 不支持问题。
- 音乐处理仅移除本项目目标；仍有普通敌人或特殊敌人时，不结束音乐战斗状态。
- ModMenu 与 UEHelpers 随 Mod 私有打包，模块名分别隔离为 `PBZDummyMenu.*` 和 `PBZTrainingDummy.UEHelpers`，不会替换其他 Mod 的 shared 库。
- 菜单模块隔离仅修改 require/preload 的模块路径字符串，不修改库内部 `ModMenu` 变量；自动化检查实际执行菜单库和整个入口的加载，验证 F8 注册，避免仅语法检查漏过启动错误。
- 不写固定安装路径，不修改其他 Mod，不接管 UE4SS 加载入口。整合包与已有运行库通过两个安装包分开。

API 检查不能确认原生 ABI、签名和资产结构完全一致。新游戏 build 或新 UE4SS 版本必须重新进行游戏内验证；仅通过 CI 不能声明支持。

## 本机功能验证

中英文菜单使用本地翻译表覆盖菜单呈现，语言偏好单独保存在 `ui_language.txt`，不改游戏语言、目标资产 ID 或按键配置。切换通过私有 ModMenu 的幂等 Init 与分区替换刷新，放到训练更新回调执行以避开正在遍历的 UI 控件。离线检查覆盖现有目标、DPS、暂停、输入和历史选择保留，实际英文换行与输入交互仍待验收。

DPS 暂停在纯 Lua 统计层使用有效计时轴，暂停时忽略伤害事件并冻结统计，继续后扣除暂停时长。独立分段模块通过 ModMenu 私有 JSON 编解码和 Lua `io` 写入实际 Mod 根目录，不新增原生游戏 API。模拟菜单验证保存失败保留、下一段暂停与目标元数据隔离；存储测试验证重新加载、备份恢复和容量上限。实际目录写入权限、中文输入、按钮布局和重启读取仍需游戏内验收。

分类与循环恢复依据本地训练原型实机日志修复三处问题：反击后一次技能拒绝会永久停止、重新开启仇恨缺少 bool Out 参数表，以及行动限制效果失效后仍保留旧句柄。新增原生 `IsActiveGameplayEffectHandleActive` 检查和受击恢复重试。目录按图鉴 EnemyType 扩展为 25 个，新增角色的资产初始化与原生预警仍待逐个实测；二级菜单过滤和恢复调度有离线回归检查。

v0.1.0-preview.3 增加目标白名单、Health_Min/Health_Max 写入与读回、木桩仇恨标记、StopAI、行动效果句柄撤销、精确已授予技能激活及 ActiveCount 检查。依赖来自 build 26367565 的本地反射与早期原型；全部新功能需要在当前游戏内重新验收。离线测试验证调度、菜单回调和统计，不替代 UE4SS 实际参数转换及资产初始化测试。

完成：中文菜单、独立目标召唤、移除/重建、F8 切换、重置满血、普通攻击/连招伤害、多次致命伤害后回满、累计统计延续，以及木桩音乐过滤。观察到一次 606.528015 的攻击使 10000 血降到约 9393.47；低血量时相同攻击仍记录完整伤害，目标回满。用户确认音乐恢复后继续攻击不会重新播放战斗 BGM。

重发修复后，mod-only 的私有依赖布局已通过实际冷启动、F8 菜单、召唤/移除和攻击伤害记录验证；日志记录到初次 606.528015 伤害后生命为约 9393.47。配置按键映射有自动化检查，默认 F8 已实测，其他键映射仍需人工验证。处决、全部元素/持续伤害、旅行清理和所有其他 Mod 的组合未完成覆盖，不作稳定性保证。

## v0.1.0-preview.2：新版启动记录与独立发行

2026-11-05，Steam build 26367565 / CL302256，PBZ.exe SHA256 为 `4415933ce33476f14c837abb61a1b60af8b78cd81783896501913a7aac69e423`。在已修复版本拦截的现有 PBZHitEnhance 环境中，确认 UE4SS 加载、PBZTrainingDummy 初始化和 F8 菜单可见。此记录仅证明该组合的启动，不等同于独立上游代理组合或全部木桩功能回归。

本项目自身没有游戏版本白名单。此次问题的根因是旧 PBZHitEnhance 代理记录 unsupported_game_skipped 后返回；原始修复代码在其独立仓库和 v0.4.0-preview.3 Release。木桩 with-UE4SS 始终使用上游独立代理，不引入卡肉项目启动器、面板或其他 Mod。两套整合包不能覆盖叠装。

preview.3 的 ZIP 按最小白名单构建：只保留木桩运行 Lua、配置、私有依赖和许可证；整合包另带必要的 UE4SS 文件。不包含 README、docs、Word/PDF、维护脚本、测试、个人数据或包内构建清单。安装和兼容说明仅在仓库/Release 页面提供，ZIP 的 SHA256SUMS 作为独立 Release 附件发布。Lua 与签名脚本属于运行必需文件。
