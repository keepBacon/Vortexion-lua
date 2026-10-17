# Vortexion R2.11 — 回调追踪和 Forsaken 发电机发现统一

## 本轮目标和范围

- **五个游戏共用**：为 WindAdapter 添加上限 24 条的控件回调诊断环形历史，按 `initial / native / reconcile / setvalue / dropdown / cleanup` 记录触发来源；结果区分 `OK / ERROR / NO_CALLBACK`。
- **Forsaken**：统一发电机 ESP 和自动修理的发现逻辑。兼容 `Workspace.Map.Generators`、`Map.Ingame.Generators`、`Map.Ingame.Map.Generators` 与 `Map.Ingame.Map` 下的直接 `Generator` 模型；扫描限制 192 个候选子节点、缓存 0.5 秒、去重。
- **性能**：回调轨迹在事件发生时写入，不增加每帧调度；发电机查询共用缓存，不再维护两个存在分歧的目标路径。
- **构建**：仅在逻辑有改动的共有源与 Forsaken 源中修改，重新生成 12 个 Lua 产物，并保留 R2.10 的低频状态同步能力。

## 验证边界

- 101 项维护中的 Python/Lua 5.4 模拟与静态测试通过；R2.11 新增 4 项，覆盖真实提取的回调诊断、24 条长度限制、回调错误与已知四种发电机布局。
- `build.py` 生成 6 个独立包及共享核心+5 个游戏模块；`verify_release.py` 校验 12 个输出文件。
- 两项旧测试 `test_forsaken_wind.py`、`test_wind_migration.py` 依赖在 R2.5 已删除的源码，无法导入；它们不是本轮成功项。
- **未做 Roblox 安卓实际运行测试**。`Callback=OK` 仅表示 Lua 回调函数没有抛错，不表示游戏服务器已经接受命中、修理或状态修改。

## 部署后复测

1. 进入任一已适配游戏，进入 `UI → 调试 → 查看最近控件回调（成功/错误）`；也可使用「复制最近控件回调」。
2. 手动开关一项功能，确认新记录来源为 `native` 或延迟同步来源为 `reconcile`。只有 `initial` 不代表真实操作。
3. `ERROR` 显示回调执行异常；`NO_CALLBACK` 表示这个 UI 项没有业务回调。查看原有「游戏功能健康状态」以判断子模块是否初始化。
4. Forsaken 正式对局中打开发电机高亮，检查标记数量；若服务器修理无效，查看现有修理诊断中的请求与实际进度变化，不误判为成功。

## 仍未解决

具体服务器控制的玩法、远程参数、游戏对象版本适配仍需游戏内证据。R2.11 不声称恢复所有游戏的全部功能，不添加新的反检测/隐藏 Hook。
