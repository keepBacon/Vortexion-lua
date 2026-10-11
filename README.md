# Vortexion - Forsaken · Starlight UI · 中文手机版

**当前状态：** GitHub 公开工程 `keepBacon/Vortexion-lua`；滑块/开关触控补丁已构建，等待实机验证。Roblox 安卓客户端尚未实际运行验证。

## 品牌与 UI 标题

- 项目正式名称：**Vortexion - Forsaken**（GitHub 仓库 `keepBacon/Vortexion-lua`）。
- Starlight 侧栏的项目名称只显示 **Forsaken**；名称右下偏左位置另显示小号浅灰字 **- Vortexion**。
- 副署名依附于 Starlight 原生 `Sidebar.Header` 标题控件，随窗口拖动与手机缩放，不创建独立漂浮水印。
- 为防止已有用户配置丢失，暂时保持原配置目录 `ForsakenCN`；旧功能控件 ID 不变。

## 核心变化

- 使用提供的 Starlight Interface Suite 源码及本地桥接层，不再加载旧 Fluent UI。
- 保留 Goonsaken v4 原有控件 ID（参见 `tests/option_ids_baseline.json`），以减少现有功能回归。
- **ESP 更正规则**：无障碍物遮挡且在视野内，透明度 **80%**；墙体遮挡或屏幕外，透明度 **0%**（完全不透明）。注：屏幕外的实体无法绘制在屏幕范围外，0% 是下次可绘制时采用的透明度状态。
- 被遮挡高亮仍保持 `Highlight.Enabled = true`；只在 ESP 开关关闭、阵营被过滤或角色不存在时禁用高亮；名字和角色标签可选择显示。
- 新增可选的生命值与距离行，0.5 秒采样一次，和玩家标签使用相同透明度。
- 同步保留杀手红色、幸存者绿色，以及按摄像机射线判定墙体遮挡（根部／头部两点）。
- 修复 Starlight 原生的滚动禁用逻辑、手机小屏缩放、CanvasSize 缩小时的过量空白。
- 修复 Starlight 下拉框反复开启时新增全局输入监听的累积问题；下拉框外区域点击支持手机触控。
- 修复 Starlight 切换按钮两个模板同时触发初始回调的问题；避免多次执行已经绑定的游戏操作。
- 用户提供的 OPAI/c00lSaken/Mangz/Dora 仅作为功能研究参考；新功能采用自行实现，不附带这些第三方源码，以避免许可证和后台循环冲突。

## 目录

- `src/ForsakenCore.luau`：主功能源码（源码编辑入口，不从 v4 反复覆盖）。
- `src/StarlightAdapter.luau`：Starlight 与旧选项 API 适配。
- `vendor/Starlight/Source.lua`：Starlight 源码和本项目手机端修补。
- `vendor/Starlight/LICENSE`：Starlight 原始 CC BY-NC 4.0 许可证。
- `dist/Vortexion_Forsaken.lua`：完整可粘贴执行器的单文件脚本。
- `build.py`、`tests/test_stage2.py`、`dist/build-manifest.json`：重建和静态回归验证。
- `docs/REFERENCES_AND_LICENSE.md`、`docs/ANDROID_QA.md`、`docs/PUBLISH.md`：来源审计、真机测试与发布步骤。

## 构建

在包含本项目的目录运行：

```sh
python3 build.py
python3 tests/test_stage2.py
```

GitHub 上的可执行单文件：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/dist/Vortexion_Forsaken.lua"))()
```

该链接更新为修复版后可继续沿用，无需修改执行器入口。

## 第三方与限制

- Starlight 原作者：**Nebula Softworks**，许可证 **CC BY-NC 4.0（非商业）**；需要保留来源与署名。新工程不可声称整个源码属于 MIT。
- Starlight 仍从 Roblox 资产 `rbxassetid://132866968194043` 加载模型；运行依赖客户端权限和资产可用性。未测试所有执行器。
- Goonsaken 上游仓库没有在所检查根目录提供明确可再分发许可；独立公开仓库发表含其大量派生实现之前，应获得原作者许可或以授权允许的实现替换相应代码。
- 第三方游戏本身可能更新内部 `Sprinting` 等模块，体力/自动战斗功能不保证持续有效；只进行了本地源码检查，不是安卓 FPS 实测结果。

## Touch v6 · 2026-10-11

已检查用户提供的约 52 秒横屏录像。滑块表现出触控指示移动但控件数值响应不可靠的情况；代码审查确认触控起始事件与 MouseButton1Down + Mouse.X 的拖动实现相冲突。同时整个 Sidebar 被绑定为窗口拖动区域，导致触摸滚动/分页操作与窗口移动争用。

- Starlight 原生滑块改为直接根据 Touch InputObject 的 Position.X 计算数值，鼠标仍受支持；同时清理拖动期间的全局监听。
- 开始拖动滑块时锁定父 ScrollingFrame，结束时恢复之前的 ScrollingEnabled 状态；连续改变值的回调限制在最多约 20Hz，结束时提交最新值。
- 手机上的 Sidebar 不再承担窗口拖动，顶部标题栏仍可拖动。
- 新增发电机实时进度标签、到发电机的距离及可选的已完成发电机显示；复用已有 Generator Progress 事件，距离最多每秒更新一次。
- 新增杀手接近提醒，范围 10–100 studs；开启时以 2.5Hz 工作、带 6 秒通知冷却，不复制参考脚本的自动传送逻辑。
- 保留 ESP：遮挡/屏幕外 0% 透明，无遮挡 80%，杀手红色/幸存者绿色。
- 新增 `tests/test_mobile_v6.py`；静态检查不能替代 Roblox 安卓真机验证。

## Touch v7 · Toggle tap fix

- 修复 Android 上功能开关点击无响应：将 Starlight 原生 Toggle 从仅监听
  右侧小区域的 `MouseButton1Click` 改为兼容鼠标、手柄和触控的 `Activated`。
- 对触控额外支持整行标题轻触，记录同一根手指的 InputObject，在释放时校验
  位置、耗时和 ≤18px 的移动阈值，超过阈值视为滑动，避免误触。
- 同一触控触发多个事件时采用 160ms 防重入，回调仅执行一次；
  全局 InputEnded 监听只在当前触摸进行期间存在，结束或控件销毁后释放。
- 保留 Slider v6 修复、ESP 0%／80% 规则、发电机标签、杀手提醒。
- 仅通过静态与回归检查，需 Android 执行器中实测 Toggle 点按。
