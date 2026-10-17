# Vortexion R2.17 — BloxStrike 与 AOTR 实机故障专项

## 结论分级

- **源码确认**：BloxStrike ESP 原逻辑已指定 `HighlightDepthMode.AlwaysOnTop`；因此仅凭该属性不能解释“只在无遮挡时显示”。Roblox 3D 对象的渲染剔除及 Android 执行器差异可使高亮间歇不可见。参考 Roblox 官方 Highlight 文档及 2025 年开发者论坛相关故障记录。
- **源码确认**：BloxStrike 原 ESP 每次更新可能执行多条射线、包围盒八角投影、3D 对象管理，最长 20Hz；原第三人称每 0.25 秒重写 CameraMode/CameraType/CameraSubject，与游戏强制第一人称控制器形成状态争夺。
- **源码确认**：BloxStrike 子弹追踪初始路径为 `LeadOnly`，未启动瞄准功能时不存在单独可见的武器操作效果；把它当成强制命中能力是错误结论。
- **源码确认**：AOTR 自动补给原先返回第一个 `Unclimbable.Reloads` 补给点，并每 0.5 秒尝试 `FireServer`，不验证距离、资源是否需要或服务器是否实际增加。上传的 AOTR 参考包还提供了不同地图的 GasTanks 路径。

## 实际改动

### BloxStrike ESP

- 使用 2D `ScreenGui` 投影作为主要穿墙显示路径：只依赖 `WorldToViewportPoint`，即使 3D Highlight 被遮挡剔除仍可显示文本和框；屏幕外目标不会乱画。
- 不创建全屏可交互遮罩；所有 Frame/TextLabel `Active=false`。Overlay 复用目标 UI，限制每轮 24 目标。
- 3D Highlight 默认关闭，提供独立可选项。降低 ESP 更新频率至 8Hz 左右；昂贵包围盒/射线检查只在用户额外开启时计算。
- 保留目标宽限与死亡/离开清理。

### 第三人称

- 移除 Heartbeat 的 250ms 周期抢写 `CameraMode/CameraType/CameraSubject`。
- 使用 `RunService:BindToRenderStep`，在默认及 BloxStrike 战斗镜头更新之后进行一次偏移；避免同帧先后切换一、三人称。
- 保存未偏移的基准 CFrame，防止镜头偏移逐帧累加。墙体射线缩短相机位置以降低穿墙。关闭后解绑及恢复。
- 与服务器/游戏强制摄像机的兼容性仍必须实机验证。

### 武器

- 保留原来的安全、可选路径，不在 Android 上静默安装高风险全局 Hook。
- 开启子弹追踪时默认联动当前瞄准辅助（可关闭）；不会再出现 `LeadOnly` 已开启但没有有效目标预测驱动的静默状态。
- 新增仅用户主动触发的有上限 `getgc(true)` 只读武器类探测，匹配近期 BloxStrike 源码中 `shoot/setupRecoil`、`getTrueSpread/getSpreadForConfig`、相机 recoil 函数结构。
- 新增 `needsAim`/探测说明，不再把“接口扫描成功”当成“服务器命中”。**尚未证实当前武器服务端远程包签名**，也没有声称服务器伤害/无后坐力/无扩散完整修好。

### AOTR 自动补给

- 从上传的 AstaRoth/Zenaru/通用参考文件独立抽象多地图补给点路径、最近站选择与 18 studs 距离前置条件。
- 按 HUD 刀片、雷枪、燃气余量判断补给需求，不再资源满时持续请求。
- 2.5 秒限频；请求之后回读 HUD，分别记录请求数、未确认数、补给站距离和最近状态。
- 保留原 `POST:FireServer("Attacks","Reload",refill)` 协议，仅在观测到资源增长时记录确认；服务器拒绝仍可能发生。

## 参考资料（研究而非复制）

- 用户上传 `FPS通用脚本(1).zip`：Aimbot-V3, Parvus, Universal-SilentAim 等，主要借鉴客户端瞄准状态同步、目标缓存和资源生命周期。
- 用户上传 `Attack the Titan Revolution(1).zip`：AstaRoth、Zenaru 及 script.lua 的补给站路径及补给需求判定。
- 公开 [xDTaraZz/Roblox-Scripts / BloxStrike.lua](https://github.com/xDTaraZz/Roblox-Scripts/blob/main/All%20Map/BloxStrike.lua)，发现运行时武器对象识别约束，但未移植全局 Hook。
- 公开 [plalettescripts/bloxstrike](https://github.com/plalettescripts/bloxstrike)，参考 ESP 与相机更新方法；其按 0.04s 重建全部 Drawing 对象的实现不适合安卓，未采用。
- Roblox 官方 [Highlight](https://create.roblox.com/docs/reference/engine/classes/Highlight)、[Camera](https://create.roblox.com/docs/workspace/camera)、[BindToRenderStep](https://create.roblox.com/docs/reference/engine/classes/RunService/BindToRenderStep)。

## 验收边界

本地 Lua mock 与 bundle 构建无法等同于 Roblox Android 实机。需要重进 BloxStrike，对比：ESP 在墙后是否仍显示 2D 框、持续 5 分钟是否稳定、第三人称是否仍闪动、Weapon 探测状态与射击结果；AOTR 需靠近补给站、耗尽部分资源并观察状态中的 `confirmed by HUD`。

如仍有游戏客户端崩溃，应提交执行器类型、崩溃前诊断及设备帧率；原生崩溃无法从 Lua `pcall` 日志判断堆栈。
