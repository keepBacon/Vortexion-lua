# Vortexion Loader V2.1 / Runtime R1 审计记录

> 本文档基于用户上传的 `Vortexion-lua-main(2).zip` 与 Forsaken、BloxStrike、SCP、AOTR 和通用脚本参考离线编写；参考脚本仅审阅，不执行。所有实测结论均标注边界。

## 已实施（不是全部功能迁移）

1. **模块化构建**：新增 `dist/Vortexion_Core.lua` + 五个 `dist/Vortexion_Module_*.lua`，共享 UI/工具核心只构建一次，运行时仅下载当前游戏对应模块。继续生成原有六个单包，供显式兼容排障。
2. **路由清单**：`src/loader_routes.json` 为 Loader P1 可阅读路由数据，构建时与 `src/GameRouter.luau` 现有映射进行精确一致性校验，AOTR 未识别地图不会误进其他游戏。
3. **V2.1 入口**：在 P0 诊断 UI 基础上增加 manifest→识别→核心下载/编译→单游戏模块下载/编译→运行→桥接验证的明确步骤。仅网络/数据长度问题重试最多3次（含首次）；编译/运行失败不自动重试。
4. **手动兼容加载**：发生错误时有「兼容单包加载」入口；默认不会用旧版大包掩盖模块化错误。
5. **会话缓存**：按 manifest 中 SHA-256 与长度索引成功下载的代码；重试可复用本次会话的核心。实际 SHA-256 校验取决于执行器是否有兼容的 `crypt.hash`；否则只比对字节数，不宣称强完整性。
6. **共享性能 HUD**：在每个游戏的通用功能中出现「性能诊断」页，可选查看 FPS/最低 FPS、Ping、内存、复制运行诊断。默认关闭；启用才订阅 Heartbeat；关闭和销毁同步断开。
7. **可选自适应视觉调度**：UI→界面，连续3次低帧采样才降低非关键视觉节拍上限，连续6次恢复后撤销；关闭状态没有 Heartbeat 监听。不会改动输入、碰撞或物理更新频率。它并非“保证 FPS 提升”。
8. **Forsaken 生命周期清理**：两个原先未收集的 Heartbeat 常驻连接纳入 `track()` 连接池。碰撞箱候选枚举从启用后每50ms一次 Descendants 变化为至多每500ms一次（对象变更时立即刷新），减少无意义的场景遍历。涉及功能仍需在实机中检验响应及时性。
9. **错误状态改进**：游戏内功能初始化失败时，`GameRouter` 向加载器提供 `BootStatus=partial` 和简要原因，保留通用窗口，但加载器不再将其误报为完整成功。

## 源码组织

| 路径 | 职责 |
|---|---|
| `loader.lua` | 安卓可见状态面板、HTTP、编译与实例校验 |
| `src/GameRouter.luau` / `src/loader_routes.json` | 旧运行时路由 / 轻量下载前路由 |
| `src/RuntimeMonitor.luau` | 跨游戏的可选性能诊断服务 |
| `src/WindAdapter.luau` | 通用 UI 和节流接口；按桥接生命周期释放资源 |
| `src/ForsakenCore.luau` | 本轮生命周期及扫描优化 |
| `build.py` | 生成 V1 兼容包与 V2 共享核心/独立模块 |
| `dist/runtime-manifest.json` | 运行时发布清单；与所有构建文件同一提交发布 |

## 加载流程

```text
loader.lua  (~小型诊断入口)
  -> runtime-manifest.json
  -> route(GameId, PlaceId)
  -> Vortexion_Core.lua [WindUI + bridge + GameRouter + 服务]
  -> Vortexion_Module_{route}.lua [仅当前游戏]
  -> GameRouter.Run + UI 句柄检测

未知游戏 -> core + GameRouter.Run(nil) 通用页面
加载失败 -> 展示阶段、错误详情、手动兼容单包
```

## 静态/模拟测试（本次）

- `python3 -m unittest discover -s tests -p 'test_*.py' -q`: 40 项当前维护测试通过，含构建、路由、加载器 Mock HTTP/编译、手动回退、RuntimeMonitor 心跳清理模拟。Lua 测试运行依赖本机 Lua5.4 共享库；没有时部分测试跳过。
- `python3 -B build.py`: 六个兼容单包、六个模块化产物及 manifest 可重复生成，哈希写入清单。
- 历史旧版断言见 `tests/archive/`，有七份依赖失效字段或旧 UI 的历史快照不能当作当前门禁；原样归档而不是宣称其通过。
- **没有验证** Roblox 安卓运行、执行器 API 行为、外设触控、图像渲染、真实网络时延、游戏场景功能成功率、实际帧率提升、Luau 原生编译器。`luau-web` 依赖离线无法安装，因此没有声称完成原生 Luau 编译。

## 安全和兼容边界

- 只能加载 `dist/` 目录下符合规则的产物路径，但 manifest 与源代码仍来自同一个 GitHub `main`，并非不可篡改的签名发布。
- HTTP 的同步 `game:HttpGet` 在部分执行器中可能不支持可取消/超时；面板不能保证避免其内部阻塞。
- Loader P0/P1 的弹窗显示取决于执行器对 gethui/CoreGui/PlayerGui 的权限；权限不足会回落控制台警告。
- 参考脚本可能依赖游戏当前内部布局和私有对象名，不能据此保证在当前服务器可运行。
- 不会自动引入上传参考中的未知 URL、密钥、动态加载器或检测绕过代码；原始主工程的现有功能保持原状，后续逐项适配须独立验证。

## 尚未完成（禁止误报）

- Forsaken/BloxStrike/SCP/AOTR 全部玩法功能的独立重构和实际功能验证。
- 原始参考里所有 Auto-Block、Auto-Trick、枪械皮肤、泰坦装备、阵营 ESP 等子功能覆盖。
- 版本签名、离线磁盘缓存/回退、完整独立后端；当前只有会话缓存与手动旧单包排障。
- 系统级性能评估（Android CPU/GPU、帧时间、GC、内存峰值）和完整端到端回归。
