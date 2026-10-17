# VISUAL_BUDGET_R14 — WindAdapter 视觉预算契约快照回归

本文件记录 Step 5 Preview 子代交付的 R14 视觉预算契约测试。**这是快照回归证据，不是父级冻结验收**：工作期间 `src/WindAdapter.luau` 可能变更，复跑时以下 hash 与计数必须重新采集。测试只覆盖普通共享 GUI 的视觉刷新节流契约，不运行游戏功能、网络操作、游戏远程调用或整个发布构建。

## 被测契约

`src/WindAdapter.luau` 中的 `bridge:GetVisualInterval(baseSeconds)`（约 41-44 行，依赖 25-40 行的 `clampHz` / `sanitizeBase`）：

- 上限节流：返回值 = `max(sanitizeBase(base), 1 / clampHz(VisualHz))`，只压低刷新频率，**不加速调用方自有节拍**。
- Hz 钳制：`clampHz` 把 `VisualHz` 四舍五入后夹到 `[5, 60]`；非数字 / NaN / ±inf 一律按 60 处理。
- base 净化：`sanitizeBase` 把非数字 / NaN / ±inf / 负值一律按 0 处理。
- 纯净性：函数不读选项控件、不创建 GUI、不排队（task.defer/spawn/wait），销毁后计算契约不变。

## 夹具设计（tests/test_wind_visual_budget_r14.luau）

真实 Adapter factory 内联进夹具（`__FACTORY__` 占位符由执行器替换），配多类"触发即抛错"桩：

- **WindUI 桩**：`CreateWindow` 是合法最小函数（满足 factory 第 4 行前置断言 `type(WindUI.CreateWindow) == "function"`，父级首跑报 `WindUI missing` 正是缺此桩；本方案不删前置断言），调用即抛错并计数；`ScreenGui` 只是惰性引用标记。
- **调度桩**：`task.defer / task.spawn / task.wait` 全部替换为计数型抛错函数（先累计再抛错，见下），任何排队立即失败且留下计数痕迹。
- **Options 毒化**：先把 `bridge.Options` 换成会改变答案的哨兵控件值（证明读的是 `bridge.VisualHz` 字段而非控件），再换成 `__index / __newindex` 全部抛错并累计 `poisonHits` 的表，任何控件读写立即失败且留下计数；`poisonHits` 在 phase5、phase6 循环后、phase7 destroy 后三处断言为 0（文案带实际计数），专门捕获被 pcall 吞掉的毒化访问。
- **计数型哨兵**：调度桩（`task.defer/spawn/wait`）与 `game:GetService` 都是**先无条件累计计数再抛错**，末尾断言全部为 0。这样即便被测代码用 `pcall(task.spawn, ...)` 吞掉哨兵错误继续返回，计数仍然抓住它。
- **GetService 测量窗口**：每次调用都进 `getServiceCalls` 总数；只有 armed 状态（每个合法 factory 构造的 2 服务 baseline 完成之后）才进 `getServiceExtra` 违规增量。合法 factory 构造调用不误判，构造期后的任何服务获取（哪怕名字合法、不抛错）都被增量 0 断言捕获。
- **服务桩**：只放行 factory 构造期读取的 `UserInputService` / `Workspace`，其他服务名触发即抛错。

独立 oracle（同语义重写，非调用实现）用于交叉验证 150000 次一致性循环。

## 实际执行证据

命令（cwd 为项目根目录，node 走 DSH 内置绝对路径）：

```
/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_wind_visual_budget_r14.mjs
```

结果（两次运行，确定性一致）：

- exitCode: **0**
- 断言计数: **300068**（150000 次循环 × 2 + 68 条显式契约断言，满足 ≥150000 一致性断言）
- 阶段: phase1 factory-no-gui / phase2 tiers-5-15-60 / phase3 custom-bounds / phase4 base-contract / phase5 controls-not-read / phase6 consistency-150000 / phase7 post-destroy 全部 PASS
- createWindowCalls = 0，scheduleCalls = 0，getServiceExtra = 0（全程零 GUI 创建、零排队、零构造期外服务获取）
- fixtureElapsedMs = 922（**仅夹具总耗时，luau-web WASM 内循环；不是手机 FPS，未做任何真机帧率宣称**）
- wallMs = 794，node v24.18.0
- luau-web: `../wind-tools/node_modules/luau-web/src/index.js`（相邻路径优先，回退本地 node_modules）

快照 hash（复跑时若 `src/WindAdapter.luau` 变更，windAdapterSha256 必须不同并重新评估）：

- windAdapterSha256 = `3bfd9e6389163fb1a11362e5bb6c5e2e195fb1cc0ea0d9ab47ccaeabe96abfef`（src 未动，与首轮一致）
- testSha256 = `a729384fbab7b3b6965f0d715e330f0cca988534cf8a23d3bfc746404a290cf3`（poisonHits 循环后/销毁后零访问断言补齐后）
- runnerSha256 = `569a97eb5202e6f5ee3b7074d86be7ae8dd74a80d681ac96a6fda22c32769fa0`（marker 断言修订后）

## 覆盖清单

- factory 构造不创建 GUI：CreateWindow 计数为 0、`Window()` 为 nil、`GUI` 仅为 ScreenGui 引用、env 发布正确。
- 三档 5/15/60Hz：0.2s / 1/15s / 1/60s 上限；base 大于上限时原样返回（不加速）。
- 默认档位接线：触屏 fixture → 15Hz，非触屏 fixture → 60Hz（第二个真实 factory 实例验证）。
- 自定义上下界：界内自定义（20/24）、越界夹取（1/3/4.6 → 5；100/59.6 → 60）、半上入整、NaN/±inf/数字字符串/布尔/表/nil → 60。
- base 契约：有限值、0、恰好等于上限、NaN、+inf、-inf、负值、数字字符串、非数字字符串、布尔、nil、缺参、表。
- 控件不读证明：哨兵控件值 + Options 毒化双重证据，150000 次循环全程在毒化态下执行。
- poisonHits 零访问断言三处：phase5 即时断言（VisualHz=60 档）+ phase6 循环后 + phase7 destroy 后，文案均带实际命中计数。phase6 后断言专门捕获"藏在 hz==5 分支里、被 pcall 吞掉"的毒化访问——这类变异在 phase5 即时断言处是绿的，只在含 5Hz 样本的循环里现形。
- 销毁契约：`Active=false`、env 取消发布、二次 Destroy 幂等；销毁后 5/60Hz、NaN/负 base 计算不变。
- 零增量断言：`scheduleCalls`（defer/spawn/wait 计数）与 `getServiceExtra`（构造 baseline 后的服务获取增量）末尾必须为 0，`createWindowCalls` 全程为 0；`poisonHits` 为 0。
- 执行器 marker 断言：替换前 `__FACTORY__` 必须恰好出现 1 次（区分 missing / duplicated 两种文案），替换后必须 0 次残留。
- 变异对照（内存内，不落盘）：NaN-Hz 回落最小值、GetVisualInterval 读控件、去掉 Hz 上界钳制——均被测出失败；删掉 CreateWindow 桩复现 `WindUI missing` 前置失败。
- pcall 吞错负对照（内存内，不落盘）：在 GetVisualInterval 返回前插入 `pcall(task.defer, function() end)`——被 `scheduleCalls.defer=300048` 零增量断言 CAUGHT（抛错被吞也逃不过计数）；插入 `pcall(game.GetService, game, "UserInputService")`（合法名、完全不抛错）与 `pcall(game.GetService, game, "Players")`（非法名、错误被吞）——均被 `getServiceExtra=300048` 零增量断言 CAUGHT。
- pcall 毒化读/写负对照（内存内，不落盘，本轮新增）：在 GetVisualInterval 返回前插入 `if self.VisualHz == 5 then pcall(function() return self.Options.wind_visual_hz end) end`（读）与其 `self.Options.wind_visual_hz = 1`（写）变体——原夹具 300068 断言全绿（正对照），两个变异均被 phase6 循环后零访问断言 CAUGHT，文案 `no Options access happened across the consistency loop (hits=17648)`（read/write 一致）。证明毒化访问即使被 pcall 吞错也留下计数，尾端断言不再漏检。

## 残余边界

- `sanitizeBase` 的 `n < 0` 守卫在当前钳制域内**输出等价**（1/clampHz 恒为正，max 后负 base 不可观测），变异对照证实无法经输出区分；夹具只钉住"负 base → 上限"的外显行为。
- 未覆盖：`computeVisualHz` 控件联动回调、真实 vendor WindUI 行为、真机触屏与 TopbarInset 订阅（由其他所有者负责）；本测试一律不宣称整包完成或真机通过。
- 本测试是快照回归：源码变更后复跑须重新采集 hash 与计数，由父级做最终审计与验收。
