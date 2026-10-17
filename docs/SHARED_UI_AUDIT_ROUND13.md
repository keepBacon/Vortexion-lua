# 第 13 轮共享 UI 独立审计

本轮仅验收普通共享窗口源码、夹具与文档。整体目标仍未完成；未重建 dist、未运行整包发布门禁、未生成新发布包。当前最新历史发布包仍为 r8。

## 修复与证据

- 安全边距读取真实 `GuiService:GetGuiInset()` 的 topLeft/bottomRight 两向量，使用四边差值的一半计算中心偏移。依据：[Roblox 官方 GuiService 文档](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GuiService.yaml)。这只是给 ScreenInsets=None 窗口人工预留 GUI 边距，不证明物理刘海或系统手势区域适配。
- 统一取消自有居中动画，覆盖销毁、关闭自动适配、关闭安全边距、全屏/空相机/无效视口早退、手动居中与 Create/Play 失败；缺 Main 不提交缓存，同几何恢复可重试。稳定重复几何不取消仍在执行的动画。
- 坐标夹具使用 `newproxy(true)` 并断言真实 Luau `type == "userdata"`，只暴露 X/Y；它不是 Roblox 引擎的 Vector2。待执行尾帧回归直接比较 Position 写入次数与落点，不只检查 Cancel 调用次数。
- 修正当前文档中的整包验收、dist 同步与必然可达等未经本轮证据支持的表述。

## 父代理冻结复跑

工作目录：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。执行器：`/data/user/0/com.dshmobile.shell/files/usr/bin/node`。

| 参数 | 结果 | 耗时 |
| --- | --- | --- |
| `tests/run_luau.mjs src/WindAdapter.luau` | 编译通过，exit 0 | 1295 ms |
| `tests/run_wind_native_contracts.mjs` | 119 passed / 0 failed，exit 0；4 个健康协程对照 | 1877 ms |
| `tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau` | 执行通过，exit 0 | 1656 ms |

三个命令 stderr 为空，均未超时、未截断。执行前后 8 个输入文件 SHA-256 一致：适配器、原生契约、基础夹具、原生装配夹具、契约执行器、两份共享文档及 vendor。`fixture callback failure` 是预期错误注入，不是失败结果。119 是分组契约计数，不是实机场景计数。

关键 SHA-256：

- `src/WindAdapter.luau`：`ff3d9d1d499094ee4f0e18b395bed9b008c6cead0f4ebcab00b2abc8fc30a1b8`。
- `tests/test_wind_native_contracts.luau`：`acc568dca8538e5822e538f49a8a6b58928f1c7537c85f5ec21e9d548a621466`。
- `vendor/WindUI/Source.lua`：`e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05`，保持原样。

## 不落盘负对照

在契约执行器装配出的 Luau 字符串内单独注入缺陷；源文件、夹具、dist 和 vendor 均未写入。

- 在向量摊平返回前插入 `if type(topLeft) ~= "table" then error("INJECTED_TABLE_ONLY_VECTOR2") end`：116 passed / 3 failed，exit 1，门禁报 `WIND_NATIVE_CONTRACTS_RED`。说明 userdata 类型回归会被捕获。
- 将自有取消助手中的 `pcall(function() tween:Cancel() end)` 替换为 `do end`：117 passed / 2 failed，exit 1；直接发现销毁后 Position 写入，以及关闭自动适配后旧尾仍写入。

这些 exit 1 是预期负对照，不是实际源码的回归失败。

## 待验证

纯 inset 变化未订阅 TopbarInset，只随显式适配或既有布局事件重读。真实 Tween、键盘、触控、拖窗/双击、全屏恢复、物理边缘与可读性溢出仍需客户端核查。最小缩放与可读性保护都可能使窗口超出视口。旧 r8 和历史发布证据不代表本轮源码；其他模块与整包构建尚未完成集成验收。
