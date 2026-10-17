# SCP 参考覆盖与验收证据

## 范围

初始专项范围为 `src/SCP*.luau`、`src/SCPCloak.lua` 与 SCP 测试；R37另补普通颜色设置及 `WindAdapter` 原生取色/配置桥接。参考文件仅作只读行为索引：

- `/data/user/0/com.dshmobile.shell/files/home/.dsh/attachments/v1/files/c5/c5e49ed48c95902159e8dee613d50f4f7c07584bd81526ba9edb98ae4b45f868/SCP角色扮演.txt`
- 未执行参考加载器，未复制参考源码。初始专项未覆盖 AOTR、WindAdapter、vendor、build、dist；R37使用只读vendor原样颜色方法补桥接契约，未修改vendor。

## 参考到实现矩阵

| 参考行为主题 | 当前实现 | 真 Luau 证据 |
| --- | --- | --- |
| 角色/候选发现、屏幕投影、距离与视野边界 | `SCPCandidates.luau` | 候选相机丢失、最近目标上限、NPC/迟到 Humanoid、投影有界 |
| 触控归属、按住/切换、焦点恢复 | `SCPCommon.luau`、`SCPCamera.luau` | 触控起点过滤、双指位移、Hold/Toggle、文本框抑制、焦点释放 |
| Camera 状态与锁定恢复 | `SCPCamera.luau` | 锁定重验证队伍/遮挡/死亡，鼠标能力降级，新相机平滑系数，目标标记复用 |
| 移动、飞行、跳跃、传送与角色替换 | `SCPMovement.luau` | 单物理驱动、速度 Y 保留、触屏水平/垂直输入、重生/传送/卸载取消 |
| 命中部位状态与资源回收 | `SCPHitbox.luau` | 20 Hz 节流、R6/R15、模式切换、关闭即时恢复、角色/玩家移除、宽限折叠 |
| 视觉对象池与关闭状态 | `SCPESP.luau` | 延迟分配、部分分配回滚、NPC/R6、特性即时隐藏、Drawing/Highlight 分离、卸载清理 |
| 屏外方向指示（参考缺失，本轮新增） | `SCPESP.luau` | 3 线三角箭头贴视口边缘、独立 `MaxEntries` 预算、关闭即隐藏、不占用屏内条目预算 |
| 原生标签（无 Drawing 时的降级路径） | `SCPESP.luau` | BillboardGui + TextLabel、Adornee 绑 Head/HRP、文本含距离、文本与颜色未变不写、角色替换重建、无 Drawing 仍工作 |
| 共享视觉节流消费 | `SCPCommon.luau`、`SCPESP.luau` | 桥接缺失/异常/NaN/inf/负数回退原节拍、只降频不加速、慢档下投影计数显著下降、相机替换强制刷新不被节流吞掉 |
| 移动端显式操作 | `SCPMovement.luau`、`SCPCore.luau` | 前向传送按 slider 距离步进、移动端起跳按钮走 humanoid 回退、传送纪元重置跳跃防抖 |
| 全局生命周期与旧 UI 合约 | `SCPCore.luau` | 旧 47 个 option ID、新 19 个 option ID、光照快照、共享切服、Render/Heartbeat 卸载 |
| Cloak 钩子生命周期 | `SCPCloak.lua` | 安装后由 common 清理钩子恢复原始 `__namecall`；重复清理保持幂等 |

## 本轮修复

- `SCPCloak.lua` 记录原始元表调用与目标，在 `Stop()` 中恢复原始 `__namecall`，清空保护集合和临时状态，并注册 `common.OnCleanup`。这只修复卸载回收，不增加新行为面。
- `run_scp_enrichment.mjs` 将 `SCPCloak.lua` 按实际扩展名装配进真 Luau 工厂，避免只装配 `.luau` 文件。
- `test_scp_enrichment.luau` 增加元表钩子生命周期回归，并在每个夹具重置时清理钩子全局状态。

## 本轮新增（SCP 独立丰富）

- `SCPCommon.luau` 新增 `common.VisualInterval(baseSeconds)`：仅当 `common.UI` 存在且 `GetVisualInterval` 为函数时才 `pcall` 调用，返回值必须是有限正数才生效，并取 `math.max(base, value)`；方法缺失、抛错、NaN、±inf、负数、非数字、非函数字段、非正 base 一律回退原节拍。接口只降频，不加速。
- `SCPESP.luau` 新增 `Config.OffScreen` 与 `Config.NativeLabels`（默认关闭）。屏外目标在距离内且 `screen.Z > 0` 时画 3 线方向箭头，箭头数与 `MaxEntries` 共用上限、不占用屏内条目预算；原生标签用 BillboardGui + TextLabel，Adornee 优先 Head、回退 HumanoidRootPart，文本为 `<name> [<距离>]`，文本与颜色都未变则跳过写入；创建失败回收已分配的 gui/label，不留半成品。
- `SCPESP.luau` 的 `hideEntry` 现在立即 `Enabled = false` 原生标签并隐藏指示线，因此 `Config.Enabled=false`、相机丢失、死亡、队伍过滤、`MaxEntries` 预算、距离剔除都能即时隐藏原生标签；下一次有效渲染重新 `Enabled = true`。
- `SCPESP.luau` 的 `ESP:Update` 在生产路径消费 `common.VisualInterval(1/clamp(TickRate,1,60))`，节流只影响非关键视觉刷新，不影响即时隐藏、销毁与移动输入。
- `SCPMovement.luau` 新增 `Config.TeleportDistance`（默认 50）与 `Movement:TeleportForward()`（沿 `LookVector` 步进，距离 clamp 1..1000）；`Movement:RequestJump(force)` 增加移动端强制起跳参数，超级跳关闭时回退 `humanoid.Jump = true`。
- `SCPCore.luau` 追加 5 个稳定 ID，默认全部关闭：`SCPESPOffScreen`、`SCPESPNativeLabels`（Visual tab，关闭时立刻 `ESP:Update(0)`）、`SCPTeleportDist`（Move tab，10..200，默认 50）、「立即起跳」「向前传送」两个按钮。旧 47 个 ID 语义未动。

## 初始验收证据（28套历史快照；R37当前专项见下节）

命令：

```text
/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_scp_enrichment.mjs
```

工作目录：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`

结果：**28 passed, 0 failed**，退出码 0，运行时约 2.5 秒。

专项计数包含 28 套：候选相机丢失、NPC 缓存、Drawing 回滚、共享清理/触控、Cloak 清理、候选 roster、Camera 锁定、移动 Camera 降级、Camera 触控、Hitbox 节流、Hitbox 重生、Movement 单驱动、触屏飞行、Noclip、跳跃/传送、ESP 特性、ESP NPC/R6、核心旧 ID/新参数、核心高帧触发、Anti-AFK、桌面兼容、候选投影上限、Hitbox 宽限回收、传送与跳跃恢复、共享视觉节流回退矩阵、ESP 投影消费节流与相机替换强制刷新、屏外箭头/原生标签/即时拆毁、前向传送与移动端起跳回退。

另跑 `node tests/run_luau.mjs`：全部 `PASS compile`（含 `dist/Vortexion_SCP.lua`），退出码 0。

## R37 颜色设置与原生契约

`SCPCore`新增敌人、队友、低血量三个原生取色器；保留既有默认色，颜色变化由既有视觉tick消费，无额外定时器。共享桥接按WindUI实际的`Default`字段读取颜色，并在原生静默`Set/Update`后同步业务值；配置以六位十六进制保存，加载经严格校验后走同一同步路径。仅RGB，不暴露透明度。当前会话失效或分量非有限0..1时忽略写入。

已执行SCP专项31/31与共享桥接夹具；真实vendor颜色`Set/Update`、`Parser.Save`及异步`Load`加入原生契约，总计126/126通过。撤销配置同步的独立VM负对照命中“原生色块恢复但业务值未恢复”的指定断言。固定34阶段完整门禁于2026-10-16T10:58:13.460Z通过34/34，源码/测试/输出哈希稳定，原203ID保留；当前证据为`tests/release-test-results.json`。这些结果仍是离线验证，不是Roblox/Android实测。

## 当前范围与剩余差异

当前源码重新核对，不再把初始快照中的旧缺口列为待办：

- `src/SCPESP.luau:31-45` 与 `src/SCPCore.luau:507-533` 已有屏外距离数字、独立 `MaxOffScreen` 预算、箭头尺寸/边距，以及原生标签字体、字号、描边、背景设置；普通视角恢复按钮亦已存在。早期段落中的共用预算与无字体设置仅描述初始版本。
- `src/SCPCore.luau:508` 已有 `SCPTracerOrigin` 下拉（Bottom/Center）。R37在 `src/SCPCore.luau:406-426` 接入原生取色器：`SCPESPColorEnemy`、`SCPESPColorAlly`、`SCPESPColorLowHealth`，默认沿用既有颜色；只接RGB，不暴露透明度设置。回调先核对当前会话，再验证Color3分量有限且位于[0,1]，不增加绘制定时器；正常视觉tick消费新值。
- 视觉档位复用共享 UI，不另设 SCP 私有 VisualHz；`src/SCPCore.luau:451-458` 保留重新加入，并将参考Server Hop替代为通用低延迟切服委托。参考公服枚举并选择首个可用实例，与通用低延迟筛选不是逐项同一算法，不把已有替代入口列成完全缺失。
- Chams为既定渲染适配而非逐像素复刻：参考 `SCP角色扮演.txt:148-161` 是每部件SelectionBox、SurfaceTransparency=0.5、LineThickness=0；当前 `src/SCPESP.luau:301-305` 为整角色Highlight、FillTransparency=0.75、OutlineTransparency=0、AlwaysOnTop与配置颜色。参考不是“仅描边”，不依据这一误读改动源码。
- 本次 `SCPCamera` 的普通 FOV GUI 检查根界面与子环归属，脱离后重建；缺 PlayerGui 按帧重试而不无限等待，卸载后停止再次创建。仅源码修复，不据此宣称设备已验。
- 图标、敌人朝向、SCP 私有悬浮球/边缘热区没有在本次追加；真实 Roblox 设备适配仍未验证。当前统一编译/构建结果见 `../后续任务.md`，上方历史专项计数不代表当前版本已复跑。

## 局限

- 这是 Luau-Web 夹具验收，不是实时 Roblox 客户端验收；事件、实例、Camera、Drawing、输入和任务调度均为可控夹具。
- Cloak 测试模拟 `hookmetamethod` 的安装/恢复契约，未依赖真实执行器元表实现。
- 未验证真实设备上的不同屏幕尺寸、系统手势抢占、网络延迟、角色自定义部件命名和第三方 UI 运行时差异。
- 真机未验证项（与"未实现"不同）：BillboardGui 在真实 Roblox 中的 `MaxDistance`/`StudsOffset` 表现、原生标签与 Cloak 保护的共存、屏外箭头在异形屏上的边缘内缩、触屏按钮与系统手势的抢占、`GetVisualInterval` 桥接在真实共享 UI 中的实际下限，均只在夹具中断言契约，没有真机证据。
- 参考行为与当前实现的差异以当前模块契约为准；参考加载器、远程依赖和网络服务不在测试路径内。
