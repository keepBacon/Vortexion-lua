# Vortexion R2.12 — 全游戏失效底层审计与证据链

**范围**：`loader.lua`、`src/GameRouter.luau`、`src/WindAdapter.luau`，Forsaken、AOTR 大厅/战斗、BloxStrike、SCP 的模块，以及用户此前上传的 Forsaken / Attack the Titan Revolution / BloxStrike / SCP 参考脚本与 WindUI-main。基线为 GitHub `main` 的 R2.11，提交 `23a4da46a73ba1c524f09bf7d775b56b6134253c`。本报告不代表已取得 Roblox 安卓实机控制权，也不代表已验证私人游戏服务器逻辑。

## 1. 核心结论（置信分级）

**已证实 A：成功状态的定义错误（系统性）**。`loader.lua` 在 `validate` 阶段只确认 `VortexionWindBridge.Active` 与窗口存在。它未能证明当前游戏模块已识别目标、每一个控件对应的调度器持续执行、游戏属性实际变化或服务器接受了请求。于是存在“UI 正常、状态报成功、玩家感知所有功能没用”的假阳性。`src/GameRouter.luau` 允许在已有窗口时进入 partial，而不是针对每个功能要求效果证据。修复思路不是修改一个 bool，而是将启动、业务调用、观察结果分离。

**已证实 B：服务器结果无法由请求推断（系统性）**。`src/ForsakenEnhancements.luau` 的 `Generator.Remotes.RE:FireServer()` 成功仅表示 Lua API 调用未报错，已有独立进度检查是正确方向；`src/AOTRCombat.luau` 直接调用攻击/命中注册远程；BloxStrike 的命中与投射逻辑同样依赖运行时目标、执行器 Hook 和游戏服务端协议。这些都不具备由客户端调用本身获取“已生效”的保证。Roblox 官方明确 `RemoteEvent` 单向、异步，服务器负责验证游戏状态。游戏协议随版本变化也不能靠模拟测试证明兼容。

**已证实 C：多个局部根因，不能用一个共用 Hook 一次解决**。Forsaken ESP、SCP 的目标池、BloxStrike 的人物阵营判断、AOTR 的巨人后颈与 Remotes 分属不同对象结构。每个模块对目标的假设不同。即使 WindUI 触控完全正常，目标池为空、对象已销毁、距离筛选、权限缺失都可能使效果为零。

**已证实 D：错误隔离掩盖业务失败**。BloxStrike 在某个子模块 factory 失败时创建 `emptyModule()`，其 `Update/Start/Stop` 无操作；SCP 对缺失模块设置空 `Update` 或空候选集合，内层 `common.Guard` 将报错留在日志。隔离有利于 UI 活着，但若仍让控件显示成可用，用户无法区别“选中”与“执行”。

**已证实 E：Forsaken 高亮存在特定渲染兼容风险**。R2.11 代码把 `Highlight` 放在 `PlayerGui` 下。Roblox 官方文档推荐把 `Highlight` 直接作为目标 `Model` / `BasePart` 的子对象；2026-04 官方开发者论坛记录过 `PlayerGui` 下高亮不稳定的问题。R2.12 改为 `highlight.Parent=model`，无需改动目标 `Adornee`，并增加候选数/距离合格数/标记失败数。**这修复一个具体的图形渲染风险，而非证明所有 ESP 都恢复**。

**仍未证实 F：所有游戏唯一共因**。历史截图显示 WindUI 原生事件和一些 Callback 确实执行，Forsaken 角色容器可识别；无法用证据支持“所有游戏都没有回调”“都是执行器名称拦截”“只是没部署新版本”。当前仓库 R2.11 已在线，并且 R2.9 事件修复与 R2.8 功能代码在其中。没有全游戏原始运行日志、目标列表及服务器结果前，声称唯一根因不成立。

## 2. 五条不同的故障路径

| 游戏 | 源码中的关键依赖 | 最可能造成“开关无效果”的阶段 | 验证所需观测 |
|---|---|---|---|
| Forsaken | `Workspace.Players.Killers/Survivors`；地图发电机路径；角色/观战相机；`Generator.Remotes.RE`；Sprinting 模块 | ESP 目标筛选/渲染、因角色死亡导致扫描环境改变、服务器不接受修理 | Native/Bridge/Runtime 开关值；候选/范围内/标记/错误；发电机进度变化 |
| AOTR 大厅 | 玩家角色 HUD、气量/刀片资源、相机、固定大厅 PlaceId | 场景对象尚未建立、HUD 路径过期或切换任务地图 | Scene/PlaceId、HUD 对象存在性、实际读取值 |
| AOTR 战斗 | `Workspace.Titans`、后颈 `Hitboxes`、POST/GET 远程、网络延迟、角色状态 | 巨人池/后颈识别、远程协议参数不匹配或服务器验证 | 巨人池数量、有效后颈数、发送计数与目标生命值差异 |
| BloxStrike | 自定义队伍/角色路径、BloxCommon、Combat、Bullet、视觉、Cosmetic、可选 Hook/Drawing | factory 失败后无操作占位；版本变化、执行器缺特定 API；服务端命中拒绝 | 每个 factory 是否 active/failed、实际目标数、回调/功能更新数、可观察效果 |
| SCP | 玩家/NPC 候选池、Camera、Hitbox、ESP、SilentAim、Movement | NPC/R6/R15 映射空、Hook API 不具备、目标被过滤；服务端阻止客户端改动 | Candidates.Frame/数量、相机/角色可用性、各模块配置与运行更新计数 |

## 3. 为什么过去那么多次“通过测试”仍然没用？

离线构建仅验证 Luau 字符串拼接、完整性清单与若干结构属性；Lua 5.4 模拟测试并不包含真实 Roblox 游戏的服务器逻辑、引擎渲染状态或安卓执行器 API。过去的测试有效地抓过错误的 `ChildRemoving` 事件、`Text=table` 等源代码错误，但对“服务器未执行操作”没有判定能力。旧测试中的两个文件还引用 R2.5 删除的 `ForsakenCombat.luau` 等文件，必须标为历史弃用、不得算作通过。针对版本号的旧断言更不应误判功能失败。

## 4. 方案比代码更重要：可靠的端到端功能契约

每个功能必须由独立对象实现 `Enable → Preconditions → Bind → Execute → Observe → Restore`，并报告至少以下有限状态：

- `DISABLED`：用户关闭；
- `WAITING_SCENE`：还在大厅、角色死亡或目标容器缺失；
- `UNAVAILABLE`：接口/执行器能力不足或子模块初始化失败；
- `RUNNING_LOCAL`：客户端效果已实际观测（例：FOV、Highlight 实例已存在）；
- `REQUEST_SENT`：请求已发送但无远端效果证据；
- `CONFIRMED`：观察到预期的实际状态变化，例如发电机 Progress 增加（仍需排除其他玩家的影响）；
- `REJECTED_OR_STALE`：连续尝试但游戏状态不变、目标已过期、参数不适用；
- `ERROR`：真实 Luau 异常，含模块、阶段与最近堆栈。

绝不能再使用笼统的 `Callback=OK` 代表功能成功。UI 层只负责选项和结果展示；各游戏模块负责领域前置条件、观察来源与恢复；跨游戏公共层负责日志节流、生命周期资源与诊断结构。所有网络相关功能还必须承认单个客户端无法证明服务器是否采用了某次远程指令。

**拒绝一刀切式全帧监听、全局 Hook 兜底或盲目暴力 `FireServer` 重试**：这既不能修复目标/协议失配，还会引入性能损耗、状态竞争与潜在限制。

## 5. 本次可证实的 R2.12 改动

1. **Forsaken** `Highlight` 改由被标记的模型持有；新增 `candidateCount`、`inRangeCount`、`markerFailures`，点击「检查游戏结构」可看三个诊断数字。它们与 `Refresh`、`Markers` 联合区分“没扫描”“没有目标”“超出距离”“标记构造失败”“已创建但引擎没渲染”。
2. **所有游戏共用** `WindAdapter` 增加「运行客户端自检（短暂检测相机FOV）」与「复制客户端自检结果」。按需观测 `RunService.Heartbeat` 在 0.3 秒内是否推进、摄像机是否存在、立即写入 FOV 是否成功、0.18 秒后 FOV 是否仍为临时值，最后仅在仍为自检值时恢复原值。异常会清理临时监听器，不创建后台扫描。
3. **构建与测试** 更新 R2.12 版本号、重新生成 12 个产物与哈希；新增真实源码片段的测试（目标归属、诊断计数、FOV 恢复、无相机、异常清理、五个模块共用核心）。适用测试通过不代表 Roblox 安卓实机通过。

## 6. 有结果后如何唯一定位下一个阶段？

同一局、同一角色，先点击 `UI → 调试 → 运行客户端自检（短暂检测相机FOV）` 并复制结果，再手动开启一项**纯本地**功能（例如当前游戏存在的 FOV），查看最近控件回调轨迹和最终相机值。特别重要：只允许“native / reconcile”记录代表玩家动作；“initial / setvalue”只是初始化/程序设置。

判定表：

| 现象 | 支持的故障定位 |
|---|---|
| `HeartbeatFrames=0` | 调度器/执行器环境（先不要查服务器） |
| `CameraWriteImmediate=false` | 当前客户端读写能力或相机对象问题 |
| `CameraWriteImmediate=true`、`CameraWriteAfter0.18s=false` | 游戏相机脚本可能在写回 FOV（不等于底层 API 不支持） |
| 回调轨迹 `native ... OK`、目标数=0 | 游戏适配器识别/筛选问题 |
| `Markers>0`、画面没高亮 | 渲染归属/引擎/遮挡/设备兼容 |
| `REQUEST_SENT`、发电机 Progress 不变 | 服务端未确认，或不适用的参数、场景/距离；不能自动称为成功 |
| 某一模块 factory 失败且 UI 仍存在 | 局部模块已不可用，不能静默降级为功能可用 |

## 7. 官方及参考资料

- Roblox `RemoteEvent` / `RemoteFunction`：https://create.roblox.com/docs/scripting/events/remote
- Roblox Server Authority：https://create.roblox.com/docs/projects/server-authority
- Roblox Highlight 使用：https://create.roblox.com/docs/effects/highlighting
- Roblox Player 角色生命周期：https://create.roblox.com/docs/reference/engine/classes/Player
- Roblox 开发者论坛关于 `PlayerGui` 的高亮渲染异常：https://devforum.roblox.com/t/highlight-parented-to-playergui-renders-inconsistently/4566863
- 本地上传参考源：`Forsaken.zip`、`Attack the Titan Revolution(1).zip`、`bloxstrike(1).zip`、`SCP角色扮演(1).txt`、`WindUI-main.zip`。参考脚本仅提供可能的路径/处理模式；其功能现时有效性尚未获得游戏内证据。

**最终审计状态**：已确认系统性假成功和客户端/服务端验证断层，已针对一个具体 ESP 渲染风险落地修复并新增跨游戏可观察性。仍不能诚实宣称“全部游戏、全部功能已恢复”。下一阶段需要实机诊断和逐功能验收，避免盲目追加新功能。
