# Vortexion R2.2 — WindUI 文本类型与二次回退启动修复

## 诊断输入

用户提供的安卓运行日志：Loader `2.2.1-shared-bootfix`，`GameId=4658598196`，`PlaceId=13379208636`，路由 `AOTR_Lobby`。

原始主错误：`WindUI/CreateWindow: Unable to assign property Text. string expected, got table`。

后续附加错误：`Window is not a valid member of ScreenGui "WindUI"`，发生在窗口创建失败后尝试重用已清理的 WindUI 实例时。不能将后续附加错误误认为首次失败的根因。

## 实现修改

1. **build.py**：仅对嵌入生成产物中的 WindUI `Creator.New` 施加 Text 类型兼容层。如果 Text 收到 table，按 `Text/Title/Content/Desc/Name/[1]/en` 顺序寻找文本内容，缺省使用空字符串；其他输入不改变。记录最多三次简短告警，保留计数及最后一次错误位置。模式变更时构建停止，避免静默误修改第三方代码。`vendor/WindUI/Source.lua` 原始字节不变。
2. **src/GameRouter.luau**：若 `CreateWindow` 已失败，直接将首次异常返回给 Loader，不再复用已销毁 ScreenGui 创建“通用回退界面”。Loader 自身的诊断面板仍可显示。
3. **src/WindAdapter.luau**：将窗口创建划分为 `vendor-constructor` / `window-theme` / `section-creation` / `common-features` / `settings` / `viewport-events`，保留明确失败阶段，错误附上最近的文本兼容事件。
4. **loader.lua**：版本更新至 `2.2.2-textcompat-bootfix`；每次尝试前清空上次文本兼容计数及错误位置。
5. **构建**：重新生成 6 个独立与 6 个模块化 Lua 文件，更新 `dist` manifest，保留游戏逻辑不变。

## 验证范围

- Python/Luau 离线测试：56 项通过；其中新增 Luau 运行时模拟 `Text=table`、正常字符串及空 table 的兼容路径。
- 12 份构建产物哈希与大小：通过。
- 原始 WindUI SHA-256 不变：`e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05`。
- **未完成 Roblox 安卓真机验证；不能保证所有游戏功能恢复。** 如果仍然失败，复制新 Loader 诊断中的 `Root cause`，其中将包含失败阶段及可能的 `TextCompat` 信息。

## 使用

请先部署本包，成功推送后在 Roblox 执行：

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/loader.lua'))()
```

切勿把整个 `dist` 文件直接粘进执行器；应使用短入口。若提示失败，请把新的完整诊断文本发来。
