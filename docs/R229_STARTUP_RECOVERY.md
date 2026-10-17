# R229 · 跨游戏启动修复审计

基线：R228 源码（用户上传的 `启动报错.txt`，2026-10-17）。
本版修复共享 **Loader V2 → Neverlose Core → Neverlose Adapter → 游戏入口 → validate** 链路，不修改各游戏玩法实现。

## 1. 已知现场错误

- GameId `1742264997`；PlaceId `5041144419`；Route `SCP`。
- `Stage: validate`：核心与游戏模块下载、编译、执行的外层流程结束后，Loader 报 `WindUI bridge is active but no window was created`。
- 旧版从游戏入口吞掉 `CreateWindow` 异常，并通过通用页面回退覆盖原错误，所以日志没有包含真实构造失败的调用栈。无法仅据该日志证明底层是权限、字体、控件还是执行器 API。

## 2. 修改

1. **原生 Neverlose 优先**：保持 R228 深色主题、侧边栏、原始两列 Section；不把正常模式改成单列。
2. **窗口构造异常保护**：用 `xpcall` 捕获原生库的窗口构造异常（包含可用时的 traceback），写入 `VortexionNativeUIError` 和 `bridge.NativeError`。
3. **备用双列 UI**：原生 UI 抛错或返回不完整窗口时，创建纯 Roblox GUI 的双列兼容窗口；保留 `TSection/Tab/Section`、Toggle/Slider/Dropdown/TextBox/Colorpicker/Button/Paragraph 的桥接协议，旧功能 ID 和业务回调不变。备用下拉通过点击轮转选项，颜色按钮提供常见预设，完整编辑体验低于原生库。
4. **GUI 挂载回退**：vendor 不再认定 `CoreGui` 可读就一定可写；尝试 `gethui`、`CoreGui`、`PlayerGui`；仅在全部失败时报告具体挂载错误。
5. **错误层级改进**：`GameRouter` 使用带调用栈的错误捕获，Loader validate 失败时优先显示原生/游戏入口/桥接的实际错误，而非仅报“无窗口”。
6. **可选组件隔离**：拖动/重开控件、通用功能页和配置页初始化失败不再导致已有主窗口被丢弃，而是标记 partial 并保留诊断信息。
7. **全量重新构建**：独立及统一入口共 7 个、共享核心与游戏模块 6 个；manifest 更新为 `loader-v2-modular-r229-startup-recovery`。

## 3. 验证

- **52/52** 适用定向离线测试通过，包括：Loader/路由、UI 原生失败模拟、备用 GUI 模拟运行、控件回调、SCP/AOTR/BloxStrike 回归、R228 视觉契约。
- 5 个游戏路由的生成模块，均与清单 SHA-256/size 一致。
- 历史测试中包含只允许旧 vendor 主题颜色、只允许 R226 既有文件列表的旧断言；这些约束与 R228/R229 设计相冲突，不能当作 R229 功能失败，也没有混入本次通过数。

## 4. 实机边界

**尚未执行 Roblox 安卓实机测试。** 当前只能证明：可复现的“构造抛异常”模型能进入回退路径，不能保证不同执行器均能创建 GUI，也不能保证各游戏服务器接口功能可用。

实机优先检查：

1. SCP 进入后是否显示主界面或兼容双列 UI；状态标记可能为“部分初始化”，不是启动失败。
2. BloxStrike、Forsaken、AOTR 大厅与战斗分别检查左侧分页、两列 Section、触控开关和下拉。
3. 通过 `getgenv().VortexionLoaderV2.GetDiagnostics()` 读取 Loader 诊断，原生失败原因参考 `getgenv().VortexionNativeUIError`。
4. 若 native 与 fallback 均失败，请提供新的完整错误文本、执行器名称和游戏场景；新版日志应分别记录两次失败原因。

## 5. 构建与发布

项目目录执行：

```sh
python3 build.py
python3 -m unittest discover -s tests -p test_r229_startup_recovery.py
```

`dist/runtime-manifest.json` 和 `loader.lua`、`dist/Vortexion_Core.lua`、五个 `dist/Vortexion_Module_*.lua` 必须**在同一次推送**中更新。否则旧 manifest 的哈希会拒绝加载新核心。此构建未执行 GitHub 推送。
