# R2.4 · WindUI 主题下拉框底层类型故障修复

## 真实故障证据

用户提供的 `3.txt`：Loader `2.3.0-vendor-trace`、Forsaken `GameId=6331902150`，已经成功下载及编译，但在 `WindUI/CreateWindow` 的 `[settings]` 阶段失败：`Unable to assign property Text. string expected, got table`。

## 静态代码链路（确定）

1. `vendor/WindUI/Source.lua` 中 `aa.SetTheme` 执行 `aa.Theme=aa.Themes[aA]`。这里的 `WindUI.Theme` 是包含颜色等字段的配置**表**，不是字符串。
2. `src/WindAdapter.luau` 旧 `installSettings` 使用 `Default = config.Theme or WindUI.Theme or "Dark"`。没有自定义 `config.Theme` 时，默认值成为主题表。
3. WindUI 原始 Dropdown `Display()` 执行 `aw = typeof(ap.Value)=="table" and (ap.Value.Title or ap.Value[1]) or ap.Value or ""`。颜色表不存在 `Title` 或第一个元素，故 `aw` 回退为原来的 table。
4. 随后执行 `ap.UIElements.Dropdown.Frame.Frame.TextLabel.Text=(aw=="" and "--" or aw)`，把 table 赋给 Text 属性，触发上述 Lua/Roblox 错误。
5. 原先 R2.2 的 `Creator.New` 文本兼容仅拦截元素**创建过程**中的 Text 属性，无法拦截 DropDown.Display 对已创建 TextLabel 的**直接赋值**。

## 修复

- 新增 `resolveThemeName(configuredName)`：仅允许使用已注册主题的字符串名称；优先自定义合法名称，再使用 `WindUI:GetCurrentTheme()`；最后使用有效的默认主题。
- 修改主题 Dropdown 的 Default 为 `resolveThemeName(config.Theme)`，回调只接受字符串。
- 将 Loader 标记为 `2.4.0-theme-type-rootfix`，构建清单标记为 `loader-v2-modular-r2.4-theme-type-rootfix`。
- 不修改原始 `vendor/WindUI/Source.lua`、游戏玩法源码及其他控件语义。

## 测试与限制

- Python/Lua 回归：62 项通过，其中新加 3 项专门检查真实 Vendor 函数、旧版故障复现、修复路径、构建产物及第三方库原始 SHA。
- Node release-runner contract：69 项通过。
- `python verify_release.py` 检查 6 个独立脚本和 6 个模块化产物通过。
- **尚未在 Roblox Android 真实执行器运行。**以上证明的是已识别的 `settings / Text table` 缺陷在测试范围内被修复，不能保证所有其他启动与玩法功能无问题。

## GitHub 部署

使用 `Vortexion_R24_Root_Cause_Fix_Deploy.zip` 中 `deploy_vortexion_r24.sh`，不需要删除仓库；只替换关联文件，检查远程 SHA 后推送，不执行 force push。
