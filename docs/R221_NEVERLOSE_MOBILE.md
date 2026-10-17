# Vortexion R221 — Neverlose UI 移植与安卓触控适配

## 交付范围

以用户上传的 R220 完整工程和 `neverlose-ui-main.zip` 为输入。所有当前**构建产物**使用上传的 Neverlose-style Lua UI，不再把 WindUI 实现打入构建产物；旧 `WindUI`、`WindBridgeFactory` 标识仅作为游戏模块与既有加载器的 API 兼容别名。原有 Forsaken、BloxStrike、AOTR Lobby、AOTR Battle、SCP 业务源文件保持不变；未声称修复各游戏服务端功能。

- **首选单文件**：`dist/Vortexion_Neverlose.lua`。复制脚本到适配 Roblox 的 Luau 执行环境。`dist/Vortexion_Wind.lua` 与之内容相同，为旧加载入口兼容保留。
- **模块化**：`dist/Vortexion_Core.lua` 和 5 个 `dist/Vortexion_Module_*.lua`。请在上线到远程仓库后同步更新 `dist/runtime-manifest.json` 及远程加载路径。
- **改动主文件**：`vendor/Neverlose/Source.lua`（修改过的上游库）、`src/NeverloseAdapter.luau`（游戏功能桥接）、`build.py`（离线构建）。
- **历史备份**：`src/WindAdapter.luau`、`vendor/WindUI/`、`src/StarlightAdapter.luau`、旧 WindUI 文档和测试保留供审计，不参与活跃构建。
- **不使用旧版 `loader.lua` 作为本地 Neverlose 启动方式**：它的远程发布路径并未在这次离线改动中更新。此轮未发布 GitHub。

## 移动端行为

| 场景 | 本轮处理 |
|---|---|
| 竖屏、横屏、窗口大小变化 | 监听相机 ViewportSize 与相机替换，重新计算大小和居中位置；按可用区域缩放 |
| 状态栏、刘海、安全区域 | 接入 GuiService GUI inset；在适配内使用左右上下 inset，监听 TopbarInset 变化 |
| 竖屏内容拥挤 | 单列 Section、窄侧栏、导航自动滚动、超长页签省略与裁剪 |
| 不可点击和误触 | 在常用按钮/下拉/切换页签上使用 `Activated`，手机禁用整个窗口拖动及边缘缩放手柄 |
| 滑块拖动困难 | 增大手机滑块命中区域，使用当前触摸 Input 的位置，并限定活动指针；滚动区域与控件分离 |
| 下拉项太小或越界 | 手机下拉项加高、列表滚动、弹层按屏幕空间定位，底部空间不足时向上展开 |
| 关闭后无法重开 | 关闭按钮仅最小化，手机悬浮入口可再次打开；桌面保留 Insert 菜单热键 |
| 视觉性能 | 安卓默认关闭屏幕通知，移除高成本菜单模糊，支持 60/30/10 Hz 视觉档位，缩短常规动画 |
| 动态功能列表 | 保留原始 ID、`OnChanged`、`GetValue`、`SetValue`、`SetValues`，对丢失的 Toggle 回调每秒进行一次状态对账 |

不同安卓手机的 Roblox 视口 / 执行器 GUI inset 行为不同，因此上述是源代码策略，**并非真机无误触保证**。特别窄的 320px 以下可用区域、屏幕方向快速切换、第三方执行器安全区覆盖仍需实机确认。

## Neverlose UI 调试面板

界面左侧 `VORTEXION · UI` 下提供：

- **外观与布局**：自动尺寸、安全区域、UI 缩放 65%–120%、主题强调色、屏幕通知、视觉更新档位、恢复默认大小。
- **UI 调试**：实时显示输入设备、窗口是否可见、视口尺寸、实际 UI 倍率、收到输入次数、回调次数、异常次数、对账修复次数、最后触控测试事件、最近选项事件。并提供触控测试开关、回调追踪、游戏开关同步、触控/视口自检、最近 24 条日志、模块健康查询。
- **配置**：按 `PlaceId` 隔离；支持执行器文件 API 时手动存取 JSON。未提供接口时有提示，不在启动时强制申请或下载外部配置。

**注意**：`UI 调试` 面板的开关能够证明事件是否到达客户端 UI；它不能证明某个功能在 Roblox 服务器上实际生效。判断游戏功能须同时查看 `游戏模块状态` 和游戏内真实表现。

## 真机验收步骤（尚未执行）

1. 全新启动 Roblox，确保没有其他 Vortexion/WindUI 同时显示；加载 `dist/Vortexion_Neverlose.lua`。
2. 竖屏与横屏分别点击所有侧栏分类，至少滚动到最底，确认分类不会遮挡页面。
3. 在 `UI 调试` 连续轻点测试开关 20 次，观察每次只有一次状态翻转；上下滑动经过开关时不能把滚动误识别为点击。
4. 在 Forsaken、BloxStrike、AOTR、SCP 各选择至少一个普通开关和滑块：拖动滑块、松开、快速反向拖动、第二指触碰都不能导致控件卡住。
5. 多次打开/收起下拉列表，分别测试选项很多时上下滚动，以及接近屏幕底部时能否正确翻转；切换 30 次页面后仍可点击。
6. 键盘弹出时填写输入框并关闭键盘，检查 UI 未移到可视区域外；旋转、切到后台再切回后仍能打开/关闭菜单。
7. 点击菜单关闭按钮，再点手机悬浮入口，确保不重新加载业务和不产生重复回调。
8. 检查 `UI 调试 → 运行视口 / 触控自检`；录下屏幕、保留 Roblox 输出/执行器日志、失败时记录分辨率与安全区状态。
9. 游戏内逐项检查业务功能；旧源码功能不等于实机已经正常工作。

## 验证边界

- **已通过**：本地 Python 离线构建、生成产物一致性、新桥接 Lua 5.4 mock 集成、回调/状态对账、动态选项更新、模拟视口改变、原游戏源文件字节一致性、移动触控代码防护的静态断言。专项 `4/4`。
- **未进行**：官方 Luau 编译器或 Roblox Studio 环境下的完整 Neverlose 库编译，Android Roblox/注入器真实触控、所有游戏功能实际执行、性能跑分。不能宣称百分百没有点击失灵。
- **原旧测试兼容性**：部分历史测试强依赖 WindUI 源码名称、主题/文本兼容实现和六包数量；源 ZIP 中另有两个旧测试引用不存在的历史文件。它们不作为 R221 Neverlose 的验收通过项，保留以供迁移对照。

## 构建与离线专项测试

```sh
cd wind-project
python3 build.py
python3 -m unittest discover -s tests -p test_neverlose_mobile_r221.py -v
```

库来源见 `vendor/Neverlose/README.md`。原 ZIP 自述 MIT，但未提供独立 LICENSE；正式公开分发前须核实上游许可。
