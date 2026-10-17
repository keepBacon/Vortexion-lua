# Vortexion R2.19 BloxStrike 实现与验证审计

## 适用范围

本轮针对 R2.18 工程的 BloxStrike 模块，改动 `BloxStrikeVisual.luau`、`BloxStrikeCombat.luau` 和 `BloxStrikeBullet.luau`。R2.18 的 Forsaken 自动谜题相关变更一并包含在累计升级包中；未修改 AOTR/SCP 的游戏逻辑。仓库基线以实际 GitHub `main` 上的 R2.17 提交 `57cdcf4bb42490c86df6da18cd68b0aaad432e43` 为准。

## 资料区分

**上传文件**：`bloxstrike(2).zip` 包含 `bloxstrike.lua`、`loader.lua`、`sirczx.script` 与嵌套源码包；`FPS通用脚本(1).zip` 包含 `Aimbot-V3`、`Parvus`、`Universal-SilentAim` 等。它们是参考实现，不保证能在当前 BloxStrike 生效；使用的是自己的引擎和 UI，不直接复制到本仓库。

**联网参考**：
- `https://github.com/xDTaraZz/Roblox-Scripts/blob/main/All%20Map/BloxStrike.lua`：公开源码中包含武器类 `shoot/setupRecoil/weaponKick/getTrueSpread` 等特征，以及 `ShootWeapon` 路径。可能随版本变化，当前游戏是否仍暴露这些函数未实机确认。
- `https://github.com/sabeenabagum4-dot/sakiscripts/blob/main/saaki/blox_strike_delta.lua`：尝试 `ReplicatedStorage.Controllers.CameraController` 直接覆写函数；仅作为查找模块的参考。
- `https://github.com/seltonmt012/sel01-rbx/blob/main/games/universal.lua`：提到 BloxStrike 相机逐帧覆写与不可靠的屏幕包围盒投影，属于作者的测量记录，未在本环境重复测量。
- `https://robloxscripts.com/script/bloxstrike-script-esp-silent-aim-aimbot-triggerbot-recoil-control-key-system-free-4h-key-updated-28082026`：展示付费／混淆脚本功能的页面，只有文字宣称，未取得源代码／许可或验证其性能。
- `https://create.roblox.com/docs/reference/engine/classes/BillboardGui`：`AlwaysOnTop`、`Adornee`、`Size` 与 `Active` 的官方行为，作为原生渲染依据。
- `https://create.roblox.com/docs/effects/highlighting`：频繁创建 Highlight 有几何重建开销，移动端屏幕覆盖面积影响 GPU 成本。

未获取私有付费脚本，不进行未授权破解；公开视频只能表明演示展示过某个效果，不证明当前版本仍可用。

## 关键缺陷及方案

### ESP 高频负载和掉帧
旧实现为每个目标同时创建 Highlight、BillboardGui、ScreenGui 的 Frame、可选 Drawing；即便默认不使用 Highlight，也创建了对应实例。开启 Drawing 时每目标刷新还需投影 8 个包围盒顶点。每次镜头切换还会清空重建所有对象。

新实现只默认创建一个 `BillboardGui`，`Adornee` 绑定根部，`AlwaysOnTop = true`，`Active = false`；借助 Roblox 引擎每帧跟踪位置，不在脚本帧循环重新投影。最多 24 个对象；Lua 目标同步上限 4Hz，标签上限约 3Hz（实际受 4Hz 调度约束）；无更新则不重复改写 Text/血条/尺寸。镜头切换不销毁目标。可选 Highlight 和 Drawing 追踪线仍是显式开关，默认关闭。失效目标短暂保留但隐藏，超过宽限即销毁；关闭立即释放。

**成本边界**：原生 BillboardGui 本身仍占 GPU 绘制、缓存和 UI 内存；无实机 profile 不能称为零开销或保证 60FPS。若发生 GUI 剔除或显存限制，需使用 MicroProfiler/FPS 叠加和设备日志继续判断。

### 碰撞箱
旧逻辑编辑客户端角色 `Size`，不会可靠复制至服务器；同时 Bullet 改写代码又使用放大后的 Size 构造命中包络，可能导致服务器判为不合理命中。新逻辑保留本地可视化，并将预测包络严格锁回修改前的原始部件尺寸（加有限公差）。默认全身目标范围，限额 8；不宣称服务器 hitbox 被放大。

### 武器模块
新模块不再把 `LeadOnly` 的本地预测误报为武器改写。额外增加两个**按需启用**的本地枪械改装控件：后坐力和散布。先按 `CameraController` / `Bullet` 模块或 `getgc(true)` 中已知方法签名定位对应 Lua table，然后保存函数，覆写对应 table 字段；关闭或卸载会恢复原始函数；模块不存在、表冻结或调用类型不兼容时报告失败。武器类扫描最多检查 3500 个 GC 条目，只在用户切换控件时进行；不会在帧循环扫描。该处理可能不影响游戏早期缓存的局部函数引用；并不保证服务器精度、弹药和命中。

## 离线回归与交付
- 142/142 有效维护测试通过，包含 4 项 R2.19 专项测试：Billboard 生命周期、武器方法恢复、碰撞包络静态检查、零投影源码契约。
- 两个旧测试文件 `test_forsaken_wind.py`、`test_wind_migration.py` 仍引用删除的 Forsaken 文件，不能导入，已排除并记录，不能计为成功。
- 所有游戏构建产物及 runtime manifest 重新生成并校验；不等于 Roblox 安卓实测。
- `build.py` 输出仍有 6 个模块化、6 个独立游戏包及共用 Wind 包（发行门禁对指定 6 主入口）。

## 实机验收重点
1. ESP：在手机内连续 10 分钟观察透墙位置与名称；检查 24 人以下大厅不崩溃、系统菜单和触控不受影响。记录 FPS/Ping/内存曲线，分别关闭 ESP、开启原生 ESP、加上可选 3D 高亮作 A/B 测试。
2. 碰撞箱：检查对局内被修改的本地视觉是否正确恢复；通过服务器实际血量变化判断命中，不以角色 Size 的变化当成成功。
3. 武器：分别开启本地后坐力、散布，点击「检查武器修改器状态」；若输出 `not supported: class unavailable`，请复制「检查真实武器类」结果以适配当前游戏或执行器；如果是 patched 但无效果，很可能是游戏缓存了原始函数或使用服务端计算。
4. 若出现卡退，提供 Android logcat 关键报错、游戏版本 PlaceId、脚本诊断的 `creates / refreshes / lastError`、以及设备 FPS 与内存，不要只看 UI 是否显示。
