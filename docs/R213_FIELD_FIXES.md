# Vortexion R2.13 — Forsaken 实机报告对应修复与验证边界

## 五项需求、证据与行为

| 报告 | 旧代码原因 | 修改后 | 尚需实测 |
|---|---|---|---|
| 通知导致触控失灵 | WindUI 通知有独立 ScreenGui 和可交互的关闭按钮；弹窗处理也模拟鼠标按下/抬起 | 触屏默认 `NotificationGui.Enabled=false`，通知转控制台及可复制日志；关闭弹窗不再发全局虚拟鼠标事件 | Android 执行器/特定 GUI 层是否仍抢输入 |
| 移动倍数无效 | `Humanoid.WalkSpeed` 被 Forsaken 自己的运动逻辑更新；参考脚本使用 `SpeedMultipliers` | 新建并管理 `SpeedMultipliers/VortexionMoveMultiplier` NumberValue，缺失才回退 WalkSpeed；重生和关闭时清理 | 游戏是否读取新建的 multiplier 名称；服务器是否校正实际速度 |
| ESP 时有时无 | 超过 240 studs 即删除；模型短暂缺失同样立即销毁 | 默认距离 400，已建立高亮的退出容差 +40、1.25 秒短暂失联宽限，保留目标 Model 挂载 | 大场景 ESP slot 限额、客户端渲染和实时目标路径 |
| ESP 遮挡/无遮挡透明度 | 原生 Highlight 仅提供一组 Fill/OutlineTransparency | 新增两滑块，0%=不透明、100%=完全透明；以 4Hz 射线检测并 2 连续采样确认状态变化 | 原生 Highlight 不支持每像素同时双透明度，因此是按目标近似切换 |
| 自动修发电机无效 | 仅 `Generator.Remotes.RE:FireServer()` 空参数，未解决连线小游戏，也无服务器确认 | 删除无依据的远程请求；尝试原生 ProximityPrompt InputHoldBegin/End，加入阶段诊断与三次失败暂停 | **真正的 6×6 连线自动识别、求解和拖拽仍未实现**，必须获取当局谜题 UI/交互协议方可完成 |

## 关键设计依据

- 上传的 `Forsaken-Scripts-main/Sil_Raw.lua`、`Terio_Survivor.lua`、`statusModule.lua` 均有 `SpeedMultipliers` 参考，证明仅调整 `Humanoid.WalkSpeed` 不是唯一控制路径；但参考不能证明任意新建名称都被当前版本采用。
- 上传的 `Forsaken-sandbox-script-main/forsaken_hub.lua` 和 `forsakenMenu-main/main.lua` 显示角色目标位于 `Workspace.Players`，发电机位于 `Map.Ingame.Map` 的不同形式；旧开关扫描存在即时清理或周期重建导致的闪烁风险。
- Roblox Creator Hub `Highlight`：`DepthMode=AlwaysOnTop` 可透视遮挡，FillTransparency/OutlineTransparency 是整个效果的属性，没有“遮挡百分比”原生双通道；本轮以摄像机 raycast 近似选择值。
- Roblox Creator Hub `GuiObject.InputSink` 和 `Active`：交互 GUI 可能吸收触控。触屏默认完全不创建通知卡片，防止即使透明仍拦截下层。
- Roblox Creator Hub `ProximityPrompt:InputHoldBegin/End`：可按游戏原生提示触发，但并不能替代其后出现的连线谜题。
- `RemoteEvent:FireServer()` 没有返回服务器处理结果，空参数请求不能证明完成修理。

## 资源与性能

- ESP 扫描最高每 0.25 秒一次，预算 32 个在范围内目标。相机 raycast 仅作用于选中的目标，状态变化需连续两次确认。
- 1.25s marker grace 能跨短暂目标消失；切换功能关闭会立即清理。
- NumberValue 由脚本唯一持有，角色重生与关闭时销毁，防止重复加载叠加倍率。
- 交互重试受 2.5s–10s 间隔控制；同一目标最多三次尝试后暂停。

## 验证与交付约束

本地 Python/Lua 5.4 模拟测试检验业务行为，`build.py` 和 `verify_release.py` 检验 6 模块 + 6 单包。**没有 Roblox 安卓实机或目标游戏服务器验收，不能称自动修发电机完成。**

## 实机建议

1. 移动端重新注入后测试通知按钮：不会弹出 WindUI 卡片，控制台打印 `[Vortexion/Notice]`，不应再抢触控。
2. Forsaken 角色分页调移动倍数：看「查看移动倍率诊断」的模式是否是 `game-SpeedMultipliers`，在走动时看估算位移速度。
3. 感知分页分别调「ESP 遮挡时透明度」「ESP 无遮挡时透明度」，靠近障碍测试变化。
4. 发电机交互分页看「查看修理与防御诊断」：`no-target` / `no-prompt` / `interaction-attempted` / `puzzle-open` 指向不同阶段；**只有获取现行发电机拼图 UI 的结构才能继续完整自动求解**。
