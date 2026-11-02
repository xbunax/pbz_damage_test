# UE4SS 与游戏兼容性

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

完成：中文菜单、独立目标召唤、移除/重建、F8 切换、重置满血、普通攻击/连招伤害、多次致命伤害后回满、累计统计延续，以及木桩音乐过滤。观察到一次 606.528015 的攻击使 10000 血降到约 9393.47；低血量时相同攻击仍记录完整伤害，目标回满。用户确认音乐恢复后继续攻击不会重新播放战斗 BGM。

重发修复后，mod-only 的私有依赖布局已通过实际冷启动、F8 菜单、召唤/移除和攻击伤害记录验证；日志记录到初次 606.528015 伤害后生命为约 9393.47。配置按键映射有自动化检查，默认 F8 已实测，其他键映射仍需人工验证。处决、全部元素/持续伤害、旅行清理和所有其他 Mod 的组合未完成覆盖，不作稳定性保证。
