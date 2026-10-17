# Vortexion R2.3 — WindUI 构造异常诊断与二次回退修正

## 输入证据

安卓 Forsaken (GameId `6331902150`, PlaceId `83645629621104`) 的 Loader 2.2.2 日志，模块路由正确，下载和编译成功，但 UI 校验失败。
主错误为 `Unable to assign property Text. string expected, got table`，接着通用回退发生 `Window is not a valid member of ScreenGui "WindUI"`。

## 根因链路

R2.2 `GameRouter.Run` 从游戏入口的 `pcall(entry)` 取得外层异常摘要，并且仅在摘要为空时读取 `VortexionBootError`。然而 `WindBridgeFactory` 已把更加明确的 `WindUI/CreateWindow` 失败保存到后者，外层错误摘要覆盖了真正原因。
因此 Router 错误地判定可以重试 `ShowUnsupported`，但此前桥接层已销毁 WindUI 的 ScreenGui，二次初始化必然失败。

## R2.3 修改

1. `src/GameRouter.luau`：不管游戏入口是否 rethrow，只要已有 WindUI/CreateWindow 错误就优先保留；构造失败时不再尝试重用旧 GUI。
2. `src/WindAdapter.luau`：对 WindUI 第三方 `CreateWindow` 内部调用使用 `xpcall`。优先 `debug.traceback`，支持 Roblox/Luau 的 `debug.info` 补充栈帧，捕获第三方内部真实出错行而不是只有游戏脚本的调用行。
3. `loader.lua` 和运行时清单：标识为 `2.3.0-vendor-trace`，防止把新版报告与旧的 R2.2 混淆。
4. 新增可执行的 Luau/Lua 回归：即使入口抛错，仍保留最初的构造错误，且不重建已失效的 UI。

## 尚未解决的内容

这次**未**证明 `Text` table 是由哪个具体的第三方组件字段传入，因为日志没有第三方堆栈，之前的 `Creator.New` 类型转换没有覆盖实际路径。
R2.3 主要修复失败恢复链路和异常定位，**不承诺安卓环境 WindUI 已可成功创建**。请再次运行并复制新报告的 `Root cause`、`Vendor frames`（如有）。

未改游戏脚本玩法逻辑、原始 `vendor/WindUI/Source.lua` 和第三方库文件 SHA-256；未验证安卓真机运行。
