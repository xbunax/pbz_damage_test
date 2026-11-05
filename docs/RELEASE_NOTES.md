# v0.1.0-preview.2：独立安装说明与精简发布包

- 明确木桩可独立安装运行：with-UE4SS 使用上游 PBZ 专用加载器，不包含卡肉 Mod、面板或 PBZHitEnhance 启动组件。
- 补充新版 build 26367565 / CL302256 的启动排查与旧外置运行库迁移步骤。旧卡肉代理的版本拦截修复独立发布在 [PBZHitEnhance v0.4.0-preview.3](https://github.com/xbunax/pbz_hit_enhance/releases/tag/v0.4.0-preview.3)，更新木桩 Lua 无法修复旧代理。
- 两个 ZIP 移除 Check-Compatibility.ps1、开发依赖清单和历史发布说明；按明确白名单打包并检查禁止的文件类型，防止维护脚本、日志或本地测试文件进入安装包。
- 保留 Mod Only 与含 UE4SS 两个包、F8 按键映射、私有菜单依赖、许可证和校验清单。安装均通过复制文件完成。

游戏新版已在原有运行库环境验证冷启动、Mod 初始化及 F8 菜单。独立上游加载器组合和新版全部伤害功能尚未完成新一轮实测。此次不加入红蓝光攻击、仇恨开关或多小怪选择。

下载本页 ZIP 而不是 Source code。已有正常工作的 UE4SS 使用 mod-only；单独安装木桩使用 with-UE4SS。两套独立整合包不能覆盖叠装。移除 ps1 不代表第三方平台一定不会要求审核，UE4SS DLL 和运行必需 Lua 仍保留。
