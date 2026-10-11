# Vortexion - Forsaken · Touch v6（2026-10-11）

## 用户视频和根因

- 录屏 `1000547754.mp4`，约 52.14 秒，画面为 Roblox 安卓横屏操作。
- 视频观察：分页/滚动能触发，但滑块拖动指示与数值响应不可靠。仅凭视频不能确认所有点击失败都由同一原因造成。
- 源码证据：旧 Starlight Slider 先允许 `Touch` 设置 `SLDragging`，实际更新只监听 `MouseButton1Down`、轮询 `Mouse.X`；另一处整个 Sidebar 被注册成拖拽面。

## 触控修复

- Slider 改为 InputObject 启动和位置更新，支持真实触控和鼠标，清理拖动期间的临时输入连接。
- 按下时暂停所在滚动层，松手恢复；高频 Callback 采样限速 20Hz。
- 手机端不把侧栏作为整体窗口拖动面；顶部标题栏仍可拖动。

## 新功能（重新设计实现而非复制粘贴）

- `GeneratorProgressESP`：发电机进度/距离标签，使用已有对象索引和 Progress 变化监听；距离 1Hz 更新。
- `GeneratorShowCompleted`：单独选择显示完成的发电机标签。
- `KillerProximityAlert`：杀手接近提醒，只在开启时工作，扫描 2.5Hz，通知冷却 6 秒。
- `KillerProximityRadius`：通知半径 10–100 studs。

## 保留项与限制

- 原有功能 ID / ESP 阵营颜色与遮挡透明度规则不变。
- 39 项旧检查 + 30 项专项源码检查通过；未进行 Luau CLI 编译或 Roblox 安卓真机测试。
- 仅作为个人游戏改造研究，尊重上传参考源码的原作者；保留 Starlight CC BY-NC 4.0 许可证。


## Touch v7: Toggle click and swipe separation

- Replaced toggle-only `MouseButton1Click` binding with `Activated` plus bounded touch capture covering the full toggle row.
- Ignore swipe movement over 18 screen px or taps lasting over 0.8 s.
- Deduplicate touch `InputEnded` vs `Activated`, protect open modal dialogs, and detach InputEnded on release.
- Preserves touch-v6 slider fix, generator ESP details and proximity alerts.
- Static checks only: Roblox Android interaction and FPS are not verified.

## v8 Touch Router

- 重构 Starlight 全局触控路由：整行 Toggle/按钮/滑块由同一 InputObject 状态机处理，兼容 TouchStarted/TouchMoved/TouchEnded；修复弹窗内容区交互状态。
- 避免多次事件触发；回收 UI 监听；禁用手机 Tooltip 的无意义 RenderStepped；重新运行时旧版 v8 计时任务退出。
- 保留 v7 游戏功能及所有选项 ID。安卓真机验证仍待完成。
