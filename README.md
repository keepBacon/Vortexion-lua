# Vortexion - Forsaken · Starlight UI · 中文手机版

**当前状态：** 源码已准备发布至 GitHub 公开仓库 `keepBacon/Vortexion-lua`；尚未进行 Roblox 安卓真机实测。

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

公开仓库地址：[keepBacon/Vortexion-lua](https://github.com/keepBacon/Vortexion-lua)。发布完成后，在支持 `loadstring` / `HttpGet` 的 Roblox 执行器可使用：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/dist/Vortexion_Forsaken.lua"))()
```

这里的 `loadstring` 仅表示脚本加载入口，并不代表已通过安卓实机功能验证。`dist/build-manifest.json` 和 `dist/test-results.json` 记录的是本地构建时的检查状态，非实时 GitHub 发布检测。

## 第三方与限制

- Starlight 原作者：**Nebula Softworks**，许可证 **CC BY-NC 4.0（非商业）**；需要保留来源与署名。新工程不可声称整个源码属于 MIT。
- Starlight 仍从 Roblox 资产 `rbxassetid://132866968194043` 加载模型；运行依赖客户端权限和资产可用性。未测试所有执行器。
- Goonsaken 上游仓库没有在所检查根目录提供明确可再分发许可；独立公开仓库发表含其大量派生实现之前，应获得原作者许可或以授权允许的实现替换相应代码。
- 第三方游戏本身可能更新内部 `Sprinting` 等模块，体力/自动战斗功能不保证持续有效；只进行了本地源码检查，不是安卓 FPS 实测结果。
