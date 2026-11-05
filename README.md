# 影之刃零：伤害测试木桩

[![Build and release](https://github.com/xbunax/pbz_damage_test/actions/workflows/release.yml/badge.svg)](https://github.com/xbunax/pbz_damage_test/actions/workflows/release.yml)

通过游戏内菜单召唤一个独立训练目标，用于测试攻击和连招的生命伤害。当前为预览版，训练目标使用游戏自带的金面人训练资产，外观是人形。

- 默认 **F8** 打开 / 关闭菜单，可修改按键映射。
- 菜单中召唤、重新召唤到面前、移除目标、重置测试。
- 目标不主动攻击，生命值为 **10000**；降至 **1 血**后自动回满，累计伤害继续保留。
- 显示最近一次伤害、累计伤害、命中次数、自动回满次数。多段攻击按伤害事件分别统计。
- 从游戏的伤害数据读取完整生命伤害，包括超出剩余生命的部分；架势、怒气伤害和攻击者资源回复不混入生命伤害。
- 排除木桩触发的战斗音乐，正常敌人的音乐触发仍由游戏处理。
- 同时只保留一个目标，切换世界或玩家角色时清理；不把木桩写入存档。

## 下载与安装包

从 [Releases](https://github.com/xbunax/pbz_damage_test/releases) 下载 ZIP，不要把源码 ZIP 当作 UE4SS 整合包。

| 文件名包含 | 适用情况 | 包含内容 |
| --- | --- | --- |
| `mod-only-windows-x64.zip` | 已经有正常工作的 UE4SS，包括已安装其他 UE4SS Mod | 木桩 Mod、私有 UI/辅助库、文档；不含加载器或共享设置 |
| `with-UE4SS-windows-x64.zip` | 尚未安装 UE4SS 或其他代理加载器 | 木桩 Mod、锁定版本的 PBZ 专用 UE4SS、上游 `dwmapi.dll`、配置和签名 |

两个包包含相同的木桩代码，均不包含 PBZHitEnhance / UnifiedHitstop 的代码、面板或启动组件。木桩整合包可单独安装运行，不需要卡肉 Mod；两者的独立整合包不能覆盖叠装。发行 ZIP 不附带 PowerShell、批处理或 Python 维护脚本。**已有 UE4SS 时使用 mod-only，不要再装一套运行库。** 每次发布附带 `SHA256SUMS.txt`，ZIP 内还有逐文件校验清单。

## 已验证版本

| 项目 | 实测版本 |
| --- | --- |
| 游戏 | Steam App `4115450`，build `26266538`，UE `5.7.4`，CL `301524` |
| UE4SS | KintaroModding 的 PBZ 专用 `v3.0.1-1183-gcdbc0b66` |
| Lua | Lua 5.4 |
| 同时启用的其他 Mod | 本机测试环境中的 UnifiedHitstop |

2026-11-05 补充：build `26367565` / CL `302256` 已在原有运行库环境验证冷启动和 F8 菜单；新版完整伤害回归及独立整合包启动仍需另行验证。木桩代码没有按游戏版本跳过加载的限制。其他游戏版本、UE4SS 版本和 Mod 组合未经验证。API 检查通过也不能证明 ABI 或游戏资产兼容。详细哈希、依赖来源、所需设置和兼容处理见 [兼容性说明](docs/COMPATIBILITY.md)。

## 安装 mod-only：已有 UE4SS

1. 完全退出游戏，备份现有 Mod 配置。
2. 找到**当前实际加载的 UE4SS** 所使用的 `Mods` 目录。不要仅凭游戏目录里有一个同名文件夹就判断位置。
3. 将 ZIP 中的整个 `PBZTrainingDummy` 文件夹复制到该 `Mods` 目录：

   ```text
   <实际 Mods 目录>/
   ├─ PBZTrainingDummy/
   │  ├─ config.ini
   │  ├─ Scripts/
   │  │  ├─ main.lua
   │  │  ├─ runtime.lua
   │  │  └─ vendor/...
   │  └─ licenses/...
   └─ mods.txt
   ```

4. 在 UE4SS **实际使用的控制列表**中新增或启用这一行，保留其他 Mod 的条目：

   ```text
   PBZTrainingDummy : 1
   ```

5. 启动游戏，进入可自由行动的场景后按 F8。

如果使用 `Overrides.ModsFolderPath`、`Overrides.ControllingModsTxt`、`mods.json` 或外置运行库，以现有加载器配置为准；只通过一种控制方式启用本 Mod。不要用发行包中的 `mods.txt` 覆盖已有列表。Mod 不修改共享 UE4SS 设置；请核对[所需 API 与 Hook 设置](docs/COMPATIBILITY.md#所需接口与设置)。

从 PBZHitEnhance / UnifiedHitstop 外置运行库迁移为独立木桩安装：退出游戏，备份原木桩 `config.ini`；确认并停用原 PBZHitEnhance 代理及其 `PBZHitEnhance.ini`，保留外置目录作为备份，再按下方 with-UE4SS 步骤安装并恢复木桩配置。只处理已确认属于旧项目的代理文件。独立木桩使用 `PBZ.exe` 旁的 `ue4ss/Mods`，不再读取卡肉项目的数据目录。

若继续使用旧卡肉运行库：日志中的 `unsupported_game_skipped` 是旧 PBZHitEnhance 加载器的拦截，木桩 mod-only 无法修复该代理；应单独升级 [PBZHitEnhance v0.4.0-preview.3](https://github.com/xbunax/pbz_hit_enhance/releases/tag/v0.4.0-preview.3)。这属于旧环境的迁移说明，不是独立木桩的依赖。

## 安装 with-UE4SS：尚未安装运行库

1. 完全退出游戏，确认目标位置没有其他 UE4SS 或代理加载器。若已存在 `ue4ss`、`UE4SS.dll`、其他来源的 `dwmapi.dll`，或通过 `dxgi.dll` / `version.dll` / `dinput8.dll` 等加载其他 Mod，先使用原加载器的安装说明确认用途，优先改用 mod-only。
2. 在 Steam 中浏览游戏本地文件，找到 `PBZ.exe` 所在的目录。本次实测布局为 `<游戏目录>/platform/steam/PBZ.exe`。
3. 将 ZIP 中的 **`dwmapi.dll` 和整个 `ue4ss` 文件夹**复制到 `PBZ.exe` 旁边，结构如下：

   ```text
   <PBZ.exe 所在目录>/
   ├─ PBZ.exe
   ├─ dwmapi.dll
   └─ ue4ss/
      ├─ UE4SS.dll
      ├─ UE4SS-settings.ini
      ├─ UE4SS_Signatures/...
      ├─ UE4SS_SDK_Backends/...
      └─ Mods/
         ├─ mods.txt
         └─ PBZTrainingDummy/...
   ```

4. 通过 Steam 正常启动游戏，进入场景后按 F8。不要再同时复制其他 UE4SS 加载器。

整合包直接使用校验过的上游 PBZ 专用代理和 UE4SS，不包含其他 Mod、调节面板或本机绝对路径。上游加载器与本项目的安装组合仍应按预览版进行验证；游戏内功能验证使用的是同一 UE4SS DLL，配合已有加载器完成。

## 使用与按键映射

1. 在平坦、前方留有空间的位置打开菜单，点击“召唤木桩”，等待约 1 秒显示“木桩已就绪”。
2. 关闭菜单后攻击目标，再打开菜单查看统计。关闭菜单会保留木桩。
3. “重置测试并回满血”清空统计；“移除木桩”移除目标并保留当前统计。重新召唤会开始新一轮统计。

只开放菜单开关键的映射。退出游戏后编辑 `PBZTrainingDummy/config.ini`：

```ini
[Keybinds]
MenuToggle = F9
```

默认是 `F8`；可改为当前 UE4SS `Key` 枚举支持的键名，例如 `F9`、`F10`、`INSERT`、`P`。**修改后重启游戏生效**。Esc 固定用于关闭菜单；Esc 和鼠标按键不能映射为菜单开关键。无效值会记录日志并回退 F8。请选择没有被其他 Mod 或游戏动作占用的按键。

## 卸载与更新

- **mod-only：**退出游戏，把 `PBZTrainingDummy` 文件夹移出实际 Mods 目录，并将控制列表中的本项改为 `PBZTrainingDummy : 0` 或删除本项。保留 UE4SS 和其他 Mod。
- **with-UE4SS：**可以先按上面的方法只停用木桩。若要移除运行库，仅在确认 `dwmapi.dll` 和 `ue4ss` 属于这次整合安装、且没有其他 Mod 依赖时，将它们移出游戏目录；不要移除其他来源的文件。
- **更新：**退出游戏，备份 `config.ini`，替换本 Mod 文件夹后恢复自己的按键配置。已有运行库使用新版本的 mod-only 即可。

## 已知边界与故障排查

- 已验证普通攻击、连招、完整伤害记录、重复回血、菜单召唤/移除/重置，以及木桩战斗音乐排除。处决、所有异常状态/持续伤害和全部武器组合没有完成覆盖测试；当前不将它作为正式伤害基准工具。
- 目标保留游戏训练资产的受击和防御属性。数值用于这个目标上的相对测试，不代表所有敌人的受伤结果。处决可能产生很大的伤害数字。
- 召唤后约 1 秒初始化期间不要攻击。悬空、狭窄或斜坡位置可能召唤失败，换到平坦空地重试。
- F8 没反应：先进入实际场景，检查控制列表、`config.ini`、按键冲突，以及实际运行库的 `UE4SS.log` 中是否有 `[PBZTrainingDummy] loaded`。
- 启动失败或 API 缺失：停用本 Mod，核对游戏/UE4SS 版本；不要通过叠加第二套加载器尝试修复。
- 反馈问题时提供游戏 build、UE4SS 版本/哈希、操作步骤和相关日志片段，避免提交存档或个人路径。

版本哈希见[兼容性说明](docs/COMPATIBILITY.md)。维护脚本只保留在源码仓库中，不随安装 ZIP 分发。

## 源码与构建发布

```text
PBZTrainingDummy/Scripts/   正式代码、独立的私有 UI/UEHelpers
tests/                     统计、伤害筛选、音乐隔离、按键与 API 检查
tools/                     Lua 编译检查、打包、安装包校验
docs/                      兼容性与版本说明
.github/workflows/         GitHub Actions 构建及发布
```

需要 Python 3.10+ 和 Lua 5.4 / luac；构建脚本本身只使用 Python 标准库：

```bash
python tools/validate.py
python -m unittest discover -s tests -p 'test_*.py'
python tools/build.py
python tools/verify_packages.py
```

在源码仓库中运行上述命令。构建会下载 `dependencies.json` 锁定的 UE4SS 归档并校验归档与 DLL 哈希。已有归档可传 `--ue4ss-archive <zip>`。产物在 `dist/`。Lua 源码会先经过 `luac -p` 编译检查，发行包保留 Lua 源码，避免跨 Lua/UE4SS 版本的字节码问题。构建工具、维护脚本和开发依赖清单不随安装 ZIP 分发。

Actions 在 main 推送、PR 和手动运行时验证并构建；只有 main 分支的成功运行能够发布。修改 `VERSION` 后推送 main，流程全部通过才创建对应版本的 Release，上传两个 ZIP 和校验文件。预览版本发布为 prerelease；已存在的版本不会覆盖。CI 不运行游戏，不代替游戏内验证。

## 许可

本项目代码采用 MIT。私有打包的 ModMenu 和 UEHelpers 各自保留上游 MIT 许可，见 [第三方说明](THIRD_PARTY_NOTICES.md)。仓库与发行包不包含游戏模型、动作、关卡或存档。
