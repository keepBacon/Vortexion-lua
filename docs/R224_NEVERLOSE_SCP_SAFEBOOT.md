# R224 — Neverlose 视觉调整 + SCP 安全启动

## 范围

以 R223 为唯一改动基线。保留 BloxStrike R222 的 ESP/RageBot 改动、AOTR R223 的补给修复以及其他玩法分支。发布包构建命令：`python3 build.py && python3 verify_release.py`。

## 图标资产的真实使用方式

- `assets/ui/Vortexion_Original.png`：用户提供的第二张 PNG 原件（不改变造型）。
- `assets/ui/Vortexion_Logo_256.png`：裁去透明外边界并缩放，保留 RGBA，减轻运行时负担。
- `src/VortexionLogoEmbedded.lua`：在打包阶段编入所有 `dist` 运行脚本，解码后写入 `Vortexion_r224_brand-<SHA>.png`。
- 支持 `writefile` + `getcustomasset` / `getsynasset` / `getfileasset` 的执行器：作为图片资源载入；并非 Roblox 官方 asset ID。
- 不支持这类私有文件 API 的执行器：保留库内置 `rbxassetid` 图标；不将回退冒充图片2已加载成功。`外观与布局 → 图标资源状态`可读具体原因。
- Native 头部和移动悬浮入口的 UIGradient 默认禁用，以免银色原图被主题色污染。

## UI 设计对齐

- 默认主题：参考宣传图的近黑底色、灰青色导航、低对比度分组描边及克制的青蓝焦点色。
- 主视觉：顶部品牌、左侧分类导航、右侧内容面板；PC 双列（790×590 逻辑尺寸），移动端横屏双列、竖屏单列，自适应缩放并避开状态栏安全区。
- 结构：功能区由无意义的「功能1/2」改为 `Main/ESP/Targeting/Advanced/Other` 等语义分组；PC 每 8 个控件形成新分区，触屏每 10 个。保留每个功能原始 ID 和回调。
- 保留 `UIScale` 单一拥有者、控件触控增强、ScrollFrame 垂直滚动、移动拖动限制、状态回写与调试。
- 视觉只模仿构图、密度和层级，未声称与截图使用的原版 Neverlose 完全像素一致。

## SCP 加载崩溃：源码风险路径与修复

**已确认的代码风险**：原 `src/SCPCore.luau` 在完成 UI 初始化前，无条件调用 `common.Cloak.Start()`，尝试 `hookmetamethod(game, "__namecall", ...)`。此调用修改整个游戏共享的元方法，可能与执行器能力和既有 Hook 冲突；运行时 Hook 的底层异常无法保证被 `pcall` 捕获。单凭源码不能证明所有设备上的实际崩溃都由它引起。

**已确认的性能风险**：原 `SCPCandidates:StartNPCScan()` 在主线程同步 `Workspace:GetDescendants()`，地图内容多时一次性分配大数组并扫描，会阻塞 UI 完成初始化。

**R224 行为**：
1. 默认禁止启动阶段注入全局 Hook；信息页新增 `高级隐藏 Hook（兼容性风险，默认关闭）`，只有用户主动选择才尝试安装。
2. `task.defer` 启动 NPC 扫描；改为 `GetChildren()` 分批 BFS，每 160 个对象 yield 一次，已处理引用立即释放，卸载时停止。
3. `BindToRenderStep` 加 `pcall`，不可用时退回 `RenderStepped:Connect`，并报告故障。
4. 保留每个子模块的 `pcall` 创建与状态诊断；关闭原有错误隔离会让总体恢复力下降，因此不这样处理。

**未确认事项**：未能访问用户手机上的 Roblox 日志和执行器栈，无法确定是否还存在其它导致进程级崩溃的根因。Luau 官方编译器与实际安卓游戏环境均不可用；Lua 5.4 模拟宿主测试不等于 Luau 真机测试。

## 验证

- `build.py`：7 份独立/统一包生成成功，含 SCP、BloxStrike、Forsaken、AOTR，以及 `Core` 和模块分包。
- `verify_release.py`：6 个模块化 + 7 个独立包的 SHA / manifest 通过。
- R224 定向测试：PNG 内容还原与资源回退、主题颜色、SCP 模拟启动、无自动 Hook、延迟 NPC 扫描路径，6/6 通过（含 900 NPC 的模拟分帧扫描）。
- R222 BloxStrike 和 R223 AOTR 回归，加上构建相关测试：本轮精选 31/31 通过。
- 全部历史 Python 测试：162 项中 21 项失败、2 项加载错误；含过去 WindUI 专项断言、历史散列值、R220 原文件不变性假设、新旧 AOTR 逻辑差异及缺少测试依赖。不能称全部通过。

## 建议的手机验收步骤

1. 先在 SCP 角色扮演专用战斗地图加载 `dist/Vortexion_SCP.lua`，确认 UI 显示、图标状态、七个游戏分页可进入。
2. 不要先启用 `高级隐藏 Hook`；确认无崩溃后检查运行状态与 ESP，再按具体问题打开功能。
3. 在多人密集场景中观察 UI 是否停止响应、内存是否上升，以及 NPC 是否在数秒内渐进显示。
4. 轮换横竖屏、打开下拉选项、滚动多控件页面并关闭/重开，确认图标、开关、尺寸和点击坐标准确。
5. 若仍崩溃，提交执行器、GameId/PlaceId、触发时机及崩溃日志，而不是以「脚本无错误」代替游戏端验收。

**GitHub 未推送。**
