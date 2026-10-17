# Vortexion R233: WindUI 恢复与 BloxStrike ESP 故障隔离

## 改动

- 源码与运行时统一从 `src/WindAdapter.luau` 加载 `vendor/WindUI/Source.lua`（来自用户上传的 WindUI-main.zip，源哈希 e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05）。
- 保留全部游戏、选项 ID 和回调，SCP R232 碰撞箱等业务改动保留。
- 旧 `Vortexion_Neverlose.lua` 入口变成指向 WindUI 的同内容别名，避免旧使用者误入旧库。
- BloxStrike ESP 修复：`projectOverlay` 提前定义并捕获 `espStats`，在投影不可用时保留 Billboard，按需启用 `Highlight`；修正 offscreen 时的回退行为；新增候选/渲染分层诊断。
- BloxStrike 视觉面板增加两项：复制详细运行诊断、独立于目标识别的画面自检，前者也可通过 `getgenv().VortexionBloxESPDiagnostics()` 获取。
- `src/BloxStrikeESPProbe.lua` 为只读执行器探针，不会创建 ESP、调用远程或修改游戏属性；输出可用于后续确认工作区实际角色结构。

## 游戏内验收顺序

1. 进入 BloxStrike 的**实际战斗对局**，WindUI → 视觉 → 打开“原生穿墙 ESP（低负载）”。
2. 点击“ESP 画面自检”，预期左上角出现青色测试矩形 3 秒。没有出现说明先查 ScreenGui/GUI 挂载，而非目标逻辑。
3. 关闭“仅显示敌方”，将 ESP 距离增至 2000，再观察有无 2D 或 Billboard 盒子及 3D 回退。
4. 点击“复制完整 ESP 运行诊断”，粘贴控制台文本给开发者；或单独运行 `src/BloxStrikeESPProbe.lua`。
5. 对 `scanned=0` 优先检查玩家/NPC 目录，`noModel`/`noRoot` 检查当前地图角色 rig；`teamFiltered` 检查 Team/CharacterName；`guiFailed` 检查 GUI 权限；`eligible>0` 但无可见盒子时检查屏幕投影与实例渲染。

## 离线测试/局限

- `python3 build.py`：7 个独立及统一脚本、6 个模块化脚本，生成含 SHA-256 的运行清单。
- `python3 verify_release.py`：发布产物长度与 SHA-256 检查。
- `PYTHONPATH=tests python3 -m unittest -v test_wind_router test_r233_wind_esp`：原始 WindUI 构建/路由模拟 + R233 显示/回退测试。
- 历史测试带旧版标签硬编码或缺失既往源文件可能失败；请勿当作新引入的运行错误。
- 没有安卓 Roblox 实机和真正 BloxStrike 角色网络数据，**不能保证最终游戏内 ESP 已生效**；只有服务器当局状态可以确认剩余根因。
