# Vortexion Loader V2 · P0

## Scope

本阶段只修改轻量启动入口 `loader.lua`，不触及游戏逻辑、构建产物、游戏识别或发布回退。旧的统一包 `dist/Vortexion_Wind.lua` 原样保留，约 2.15 MB；P1 之后才按需拆分。运行时 UI 由独立的原生 Roblox `ScreenGui` 提供，不依赖 WindUI 加载成功。

## 状态机

`bootstrap → preflight → game-ready（必要时）→ source → download → compile → runtime → complete`

- 下载失败：显示 HTTP 阶段、网络错误、重试操作。
- 编译失败：显示 Luau 错误，而不是继续尝试运行。
- 运行失败：捕获同步异常，保留诊断窗口；GameRouter 内部捕获的错误仍需通过控制台和注册桥接辅助判断。
- `VortexionWindBridge.Active` 未注册：视为初始化失败。注册成功仅表示桥接创建，不表示安卓 UI 已正确渲染。
- 无法创建或挂载最小 GUI：`warn()` 记录降级信息，加载流程继续。
- 重复执行：只清理旧的加载诊断面板，游戏 UI 的重载交给原 Wind bundle 的生命周期机制。
- 取消：点击“关闭提示”只关闭诊断面板，并忽略未完成的异步响应，不承诺取消已经发出的 HTTP 操作或销毁游戏 UI。

## 使用

仓库 `main` 更新后，执行：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/loader.lua"))()
```

如主界面没出现，截图诊断浮窗；点击“复制诊断”，提供 `Stage`、`Error`、`GameId`、`PlaceId` 和日志。也可以检查执行器控制台包含 `[Vortexion/Loader V2]` 的日志。可选更换来源 `getgenv().VortexionSourceBase = "https://example.com/hosted/"`，只接受 HTTP(S) 基础地址；不会替换为本地文件路径。

## 测试

```sh
cd wind-project
texlua tests/test_loader_p0.lua
```

覆盖：正常桥接、网络失败与重试、编译失败、运行失败、未注册桥接、无效地址、GUI 权限缺失、重复加载清理。测试通过只意味着 **模拟宿主下的 P0 行为通过**。未运行真实 Roblox 安卓、完整 GUI 渲染、真实网络链路或原 34 阶段完整门禁；不把旧版本验证报告套用于新加载器。

## 已知边界

1. 外部脚本下载（用于加载 `loader.lua` 的第一段 `game:HttpGet`）发生在引导器启动之前，无法由引导器自身的 UI 捕获；仍需执行器控制台诊断。
2. `game:HttpGet` 无网络超时控制能力，连接长时间挂起时，状态停留在 `download`，无法中断底层阻塞调用。
3. 当前仅观测同步编译/初始化。脚本运行后发生的异步回调异常不会全部被捕获。
4. 依赖执行器允许 `loadstring`、HTTP、Roblox 原生 ScreenGui 和相应的 UI 父节点；不保证全部安卓执行器兼容。
