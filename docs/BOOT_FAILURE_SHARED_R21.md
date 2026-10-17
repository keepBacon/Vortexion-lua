# Vortexion R2.1 — 跨游戏 WindUI 启动诊断与稳定性修补

## 问题来源与证据

安卓日志显示 AOTR 大厅、战斗和 Forsaken 等不同路由共享相同的 `validate` 失败：`No active WindUI bridge`。下载和编译完成不等于 WindUI 窗口初始化成功；此前模块入口与 GameRouter 的 `pcall`/清理会掩盖首个窗口异常。

## 本轮调整

1. `src/WindAdapter.luau` 在清理失败窗口之前将原始异常保存到 `getgenv().VortexionBootError`，并打印 `[Vortexion/Wind/BOOT]` 提示。
2. Loader 在 `validate` 阶段报告 `Root cause: ...`，而非仅输出无桥接的二次症状。每次加载尝试都重置错误诊断。
3. Android (`TouchEnabled=true`) 的默认 Acrylic 改为关闭，避免移动端在创建窗口阶段强制分配 blur；保留其他 UI 设置。
4. 主题切换与浮动按钮配置为可恢复的可选功能；失败不会直接将主窗口判为失败，但会输出 warning。
5. AOTR、SCP、BloxStrike 和 GameRouter 在提前退出 / 降级失败时保留启动原因。不会假装功能加载成功。
6. 旧的单包和新的模块化入口均使用相同共享桥接改进。

## 仍有待确认的部分

这些是静态可确认的错误链路及移动端防护修复。由于没有安卓执行器运行环境，不能断言已消除具体第三方 WindUI 不兼容问题，也不能声称 AOTR 战斗、Forsaken 等玩法功能已实机恢复。再次运行后请复制 **新 Loader 诊断中的 `Root cause`**；如果创建窗口仍失败，它应当包含更底层的 WindUI 异常。

## 验证

`python3 build.py` 重新生成 12 个 Lua bundles，`python3 -m unittest discover -s tests -p 'test_*.py' -q`；Git 空白检查、运行时清单字节数和 SHA-256 对齐。
