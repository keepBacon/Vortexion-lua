# Vortexion R2.16 — Roblox 菜单、性能 HUD 与 Forsaken 谜题

## 实际修改

1. `src/RuntimeMonitor.luau`：HUD 使用唯一 `TextLabel` 绘制，不再生成独立背景 `Frame`。文字内边距为左/右 3px、上/下 2px，自动收紧至文字尺寸。位于 `CoreUISafeInsets` 安全区，使用较低 `DisplayOrder=-1000`，显式 `Active=false`、`Selectable=false` 并在 Roblox 支持时设置 `InputSink=None` / `Interactable=false`，不修改 CoreGui。新增「紧急关闭性能 HUD（排查 Roblox 菜单）」按钮。
2. 信息包括 FPS 当前/最低/最高、平均帧时间、Ping、内存 MB、峰值帧耗时、>=50ms 卡顿帧数量、运行时间和 WindUI 视觉刷新 Hz。服务读取仅随原采样间隔 1–5s 执行，不增加每帧性能接口查询。
3. Forsaken 新增 `ForsakenPuzzlePlanner.luau`：识别 `PuzzleUI.Container.GridHolder.Grid`、`Grid.Blobs` 与直接数字格；读取动态编号、颜色和按钮状态；检测矩阵尺寸和配对；对有确定配对的方格支持有预算的单线不交叉路径规划，并复制简明分析报告。独立 Luau 单元测试实际调用读取与求解函数。**不会模拟点击或向服务器虚报修理成功。**

## `123.txt` 里的事实

- 第一种界面含 `Inventory`、`GearElement`、`CenterGear` 等，属于齿轮阶段。
- 第二种界面 `Grid/Blobs` 下有 12 个带按钮的序号节点。
- 第三种界面 `Grid` 下编号直接按 7 列铺开：7、14、21、28、35、42...；文档出现不同次采样，最长一段仅截到第 41 格，源采集器单次上限 160 个节点，说明**无法据此确认完整网格和端点配对关系**。不应把它固定当成 6×6。
- 文档没有 `Number.Text`、`Circle.BackgroundColor3`、按钮真实触控序列（点击/长按/拖动）、游戏实际进度变化，因此无法建立可靠的端到端自动操作。仅凭 `pos` / `size` 不能确定相同颜色的配对，更不能判定服务端认可修理。

## 下一步必须补充的数据（当前脚本可直接协助采集）

- 正式对局中手动打开发电机谜题，进入 7 列网格后点击「发电机 → 分析当前发电机谜题（端点/颜色/路径）」，粘贴复制结果；请在第二个谜题阶段也采集一次。
- 完成一条连线时录一段短视频，包含手指落点、拖动经过的格子、抬起位置，以及谜题连接状态变化；说明手指是否一直按住。
- 如果本次 GUI 采集出现 `pairs=0` 或 `ambiguous`，还需要连线前后至少两次 `Number.Text` / 颜色变化采样，确定哪些颜色或编号是真正的成对端点。
- 保存一次 `Generator.Progress` 在成功连接前/后的真实值，验证脚本操作是否被服务端接受。

**验收边界：** HUD 触控安全性和谜题规划是源码及模拟器层面的验证，真正的 Roblox 原生菜单恢复、完整自动解谜尚无 Android 实机结果。若关闭 HUD 后菜单仍无法打开，需要另行检查 WindUI 其他弹层、执行器输入钩子或游戏客户端状态。
