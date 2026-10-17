# Vortexion R231 — 原版 Neverlose 窗口创建异常修复

**基础版本**：R230（保留既有 BloxStrike R230、SCP R228、AOTR R223 等业务代码）  
**问题日志**：`Stage: complete / Status: partial / EmergencyNeverlose`；`SystemT` 中 `attempt to index nil with 'TextTruncate'`。  
**修复范围**：所有使用共享 Neverlose 的游戏路线（SCP、Forsaken、BloxStrike、AOTR Lobby、AOTR Battle）。

## 1. 可复现的根因

旧版 `vendor/Neverlose/Source.lua` 的 `Neverlose_Main:Window(config)` 即使接收到 `External.KeySystem = false`，也仍然构造隐藏的 `KeyFrame`、`SetupSystem`、`SystemT`（系统开关）等卡密 UI，然后才创建 `MainFrame`。在 `SystemT` 中，旧代码对不存在的标识符赋值：

```lua
ToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd
```

该函数实际创建的是 `SetupSystemToggleTitle`，因此报错发生在通用原生窗口的构造阶段、早于任何 SCP 游戏 ESP 功能注册。R229 的 `NeverloseEmergency` 成功回退后 Loader 会显示 `partial`；这不代表原生 UI 成功。

## 2. 修改

- **修正错误标识符**：`SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd`。
- **修正初始化生命周期**：用 `if Allow_KeySystem then ... end` 包围卡密 UI 构造/等待/销毁逻辑。Vortexion 始终使用 `KeySystem=false`，正常构建现在完全跳过此无用 UI，避免隐藏卡密控件错误阻断全部游戏。
- **不改视觉排列**：保留原生左侧栏、两个 Section 列和已有控件布局；仍使用 R229 应急双列 UI 作为仅限原生构造失败时的回退路径。
- **版本与构建信息**：Loader 更新为 `2.20.0-r231-native-window-fix`，模块清单版本更新为 `r231-loader-v2-native-neverlose-startup-fix`，完整与模块化脚本均已重新构建并计算 SHA-256。
- **新增回归**：`tests/test_r231_native_boot.py` 模拟执行**实际 vendored Neverlose 源码**，在 `KeySystem=false` 时创建窗口、TSection、Tab、Section、Toggle、Dropdown、Slider、Colorpicker、TextBox，而不是只验证替身适配器；检查所有五个游戏路由和哈希。

## 3. 验证结果

| 验证 | 结果 |
|---|---|
| R231 专项测试 | 4/4 通过 |
| 本轮适用的 Neverlose / UI / BloxStrike / SCP / Loader 定向回归 | 36/36 通过（包含上述 4 项） |
| 完整入口脚本构建 | 7/7 通过 |
| 模块化产物构建 | 6/6 通过 |
| 运行清单 core/modules 哈希 | 全部匹配 |
| ZIP CRC / 文件完整性 | 归档时校验 |
| 安卓 Roblox 执行器中真实打开原生窗口 | **未验证** |

历史旧测试的未通过情况单独记录，不纳入 36/36：
1. `test_r229_startup_recovery` 里两项测试将运行清单版本固定为 R230、Loader 固定为 R229；它们与本次合法版本更新冲突。
2. `test_r227_native_ui.test_business_modules_identical_to_r226` 引用了不在当前工作区的 `/mnt/data/vortexion_r226_work/...`，因此报缺失基线文件。

上述问题不意味着实机兼容性已通过。Luau 官方编译器与 Roblox Android 实机尚未验证。

## 4. 实机验收

1. 上传 R231 完整项目覆盖 GitHub `main` 当前文件（保留 `.git` 和提交历史）。
2. 在 SCP、BloxStrike、Forsaken、AOTR 大厅及战斗场景分别运行原 `loader.lua`。
3. 在 Loader 面板确认 `Build: r231-loader-v2-native-neverlose-startup-fix`；理想情况 `Status: success`，UI 调试页的 `UIBackend` 为 `Neverlose`。`Status: partial` / `EmergencyNeverlose` 表示仍在降级，需保存新的完整日志。
4. 检查真实双列布局、分页、开关、下拉、滑块与触控；随后单独检查游戏业务功能。

**注意**：修复针对 UI 构造，不证明 RageBot、武器修改、碰撞箱命中或 SCP 游戏功能已由服务端验收。
