# Vortexion R2.14 — Forsaken / AOTR / WindUI 源码审计与开发记录

> 2026-10-17。本报告仅说明已修改源码、可重复的离线测试及实现边界。不等同于 Roblox 公共服务器实机功能通过。

## 1. 查证范围

- GitHub `keepBacon/Vortexion-lua` 主分支 R2.13（基线提交：`50b0ab85f8fa95073c63488cf57ee8d3c17b2fda`）。
- 已上传的 `Forsaken.zip` 内四套子包：`Forsaken-Script-main.zip`、`Forsaken-Scripts-main.zip`、`Forsaken-sandbox-script-main.zip`、`forsakenMenu-main.zip`；另外检查《一些通用脚本》与 AOTR 参考包。注意这些包里还有内嵌 ZIP，已按层解开检查 Lua/Luau 源码。
- 额外公开参考：[Goonsaken Hub](https://github.com/NumanLUAU/Goonsaken-Hub/blob/main/main.lua)（历史版 `Generator.Remotes.RE` 请求、陷阱与发电机 ESP）、[Forsaken Autogen](https://github.com/Altairkaaa/Forsaken-Autogen)（PC 外部截图识别 + DFS/路径绘制，依赖 Python/Windows 输入驱动）、[Forsaken-sandbox-script](https://github.com/besto-scripto/Forsaken-sandbox-script/blob/main/forsaken_hub.lua)（仅载入外部求解器，并不提供独立完整求解源码）。
- 性能准则：[Roblox Luau 性能建议](https://create.roblox.com/docs/performance-optimization/improve)、[Roblox MicroProfiler UI 类别](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)。

## 2. 自动修发电机：两类协议不能混淆

### 已查证

1. 历史脚本可见从 `Workspace.Map.Ingame.Map.Generator` 定位目标，并使用无参数 `Generator.Remotes.RE:FireServer()`。这不能证明当前版本服务器仍认可它，也不能通过返回值确认进度。
2. 较新谜题方案使用 **Numberlink/连线题**：从当前可见拼图中读取数字/颜色端点、构造无交叉路径，再在实际拼图 UI 中完成连线。公开的 PC 工具使用截图、鼠标拖拽、Windows 驱动，不能直接照搬到 Android Luau。
3. `ProximityPrompt` 只能尝试打开交互；它本身不是求解器。`Progress` 数值增长才是本地可观察的修理进度证据。

### R2.14 源码实际实现

- 协议选择：`Auto / Prompt / Legacy RE`。`Auto` 优先原生 ProximityPrompt；没有提示而目标存在旧版 `RE` 时才限距（12 studs）尝试。`Prompt` 禁止自动回退，`Legacy RE` 用于明确兼容测试。
- 单次请求后等待下次调度，观察 `Progress`；只有数值增长才能计入 `progressSeen`。连续三次未确认进度停止远程重试，避免无限无效调用。已经显示拼图时，优先记录 `puzzle-open` 并暂停旧模式请求。
- 「复制当前连线谜题结构」按钮，采集当前 PlayerGui 内找到的 Puzzle/Generator GUI 的 **最多 160 个 GUI 节点**（类名、位置、尺寸、可见性），供后续适配当前版本。缺少剪贴板接口时退回打印。
- 手动重新尝试可清理等待状态；修理失败信息改为分页内展示，不再依赖触控通知。

**尚未完成的关键一步：自动解 6×6 谜题并执行实际连线。** 公开的 Windows 外部自动求解器与 Roblox Android Luau 的 GUI 输入接口不同。在没有当前版本 `PuzzleUI` 节点布局及操作协议证据之前，不能宣称「全自动修好发电机」。

## 3. Forsaken 新增六个感知选项

| UI 控件 | 数据来源 | 约束 |
| --- | --- | --- |
| 杀手角色及皮肤 | `Workspace.Players.Killers`；角色模型名称及可见 `CharacterName/Role/SkinName/Skin` 等属性或 StringValue | 未复制到客户端的皮肤标记显示“皮肤未公开”；绝不猜测 |
| 幸存者角色及皮肤 | `Workspace.Players.Survivors`，同样读取实际属性 | 死亡/观战仍可基于相机扫描 |
| 幸存者 HP | 目标 `Humanoid.Health / MaxHealth` | 数值可能受游戏同步延迟影响 |
| 陷阱 ESP | 场景内实际存在且名称包含 `subspace`、`tripwire`、`spike`、`mine` 等的模型/部件 | 仅限客户端可见实体；不虚构服务器隐藏陷阱 |
| 杀手帮手机器人 ESP | 场景内 `pizza`、`delivery`、`minion` 等对象，且需验证是包含 Humanoid / HumanoidRootPart 的 Model | 防止装饰件误认作机器人；名称随游戏版本变化需要更新 |
| 危险提示 | **附近实际复制**的危险实体 + 可识别杀手距离；本地非交互文字条 | 不是“预知”1x1x1x1或 John Doe 尚未复制的远程技能指令 |

### 重要错误修复

- 部分陷阱是 Roblox `BasePart`，不能访问仅属于 `Model` 的 `PrimaryPart`。原候选路径会在此抛异常，中断整个刷新；R2.14 按 `IsA("BasePart")` 分流。
- 目标扫描保留 R2.13 的短暂丢失宽限、距离滞回及遮挡透明度；额外实体扫描缓存 1s、每次最多访问约 650 个对象、生成标记限制 32 个，避免每帧全地图递归。
- BillboardGui 标签跟随实际目标 Part，清理高亮时同步清理文字 GUI；`TextLabel.Active=false` 防止它主动参与触摸输入。

## 4. AOTR 战斗间歇失效与帧抖动

问题存在多种可能原因，不能简单归为“命中率不足”：锁定目标没生成、Android 系统焦点信号被执行器浮窗打断、攻击概率配置不足、后台 RPC 同步等待、服务器拒绝远程请求。

- 取消移动端单纯因 `WindowFocusReleased` 停止战斗目标锁定；PC 仍遵守焦点控制。
- 配置默认 `HitChance=1`、`CooldownJitter=0.05`，避免无故丢掉用户明确开启的本地请求。**这不是服务器命中率承诺。**
- Titan 解析 10Hz、ESP 20Hz、Farm 4Hz；Combat 相机姿态仍走每帧更新。
- 雷枪 `GET:InvokeServer` 与连发等待改为 `task.spawn` 独立单任务；限制同一时刻一个雷枪 burst，卸载或关闭后停止后续发送。
- Farm 服务端设置和可能 yield 的检查异步执行，`farmBusy` 限制重叠任务；避免同步网络等待拖住 `BindToRenderStep`。
- 战斗新增尝试数、已排队数、实际本地发送数、失败数、上次失败原因和「服务器未确认」提示；运行状态展示在设置分页内。

**警示：** 这里的“发送数”仅代表客户端本地 API 请求，不代表服务器注册命中，也不代表所有 AOTR 战斗功能实机恢复。

## 5. WindUI 交互卡顿

- 安卓默认视觉档位由 15Hz 升为 30Hz，减少动画阶段的可见跳帧；用户仍可选 `省电`（10Hz）或 `原速`（60Hz）。
- 触摸布局事件使用约 50ms 合并刷新（桌面约 10ms），减少弹出键盘、拖拽和状态栏变化造成的重复 `FitViewport` 计算。
- 非必要的 AOTR 网络等待和低优先级目标扫描不再争用每个渲染帧。
- 通知浮层维持 R2.13 的默认禁用触控策略，新的战斗、修理结果改在分页内显示。

**性能边界：** 上述属于可检验的算法/调度改动，不是实机 FPS 基准。真实帧时间需 Roblox MicroProfiler 或 Android 实测。

## 6. 已运行的验证门禁

- 当前维护的 Python + Lua 5.4 模拟测试：见 `tests/` 的 R2.14 新增用例和既有多轮回归；首次测试需要更新失效的旧结构断言。
- 构建 `python3 -B build.py` 后 `python3 -B verify_release.py` 验证 **6 模块 + 6 独立 Lua 产物**的 SHA-256 和大小。
- 另外 2 个历史测试仍依赖已删除的 ForsakenGuest/ForsakenCombat 等文件，不能参与当前有效门禁；不应当作成功。
- 部署包基于 `50b0ab85f8fa95073c63488cf57ee8d3c17b2fda`；仅在 main 仍与基线一致时允许正常推送，无 `--force`。

## 7. 实机验收优先级

1. 在 Forsaken 正式回合开启陷阱/机器人 ESP，查看是否存在误标、是否被超过 32 个目标预算截断；单独开启角色/皮肤、血量文本，检查出生、死亡、观战。
2. 有发电机时启用 Auto/Prompt，观察 `repairPhase` 和 Progress；打开谜题后点击「复制当前连线谜题结构」。没有棋盘结构不能完成后续自动解谜步骤。
3. 在 AOTR 战斗中查看 `attempts / attacks / failedRequests / lock / lastRequestError`；服务器受理需通过 HP/奖励等状态变化另行验证。
4. 比较安卓“省电 / 均衡 / 原速”的 UI 响应及实际帧耗时。不要将视觉刷新档位误解成 Android 系统 FPS。
