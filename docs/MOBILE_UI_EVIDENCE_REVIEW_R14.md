# R14 移动 UI 证据审查（快照回归 · 未冻结）

本文件是 R14 Preview 子代的唯一产出：对共享 GUI（`src/WindAdapter.luau` + 共享测试 + 共享文档）做只读勘查，记录实际命令、退出码、计数与源码哈希，并给出 API 语义核对、未证实项与可操作真机验收清单。

性质声明：

- 本文所有回归结论均为**快照回归**，不是父级冻结验收；父级冻结前需按 §1 哈希重跑复核。
- 本地 fixture / 编译通过不等于真机通过；本文不宣称任何真机或整包完成结论。
- 本子代未修改任何既有文件、`vendor/`、`dist/`、`build.py` 与共享测试；仅新建本文件。发现的问题一律交父，不跨所有权修生产代码。
- 项目非 git 仓库，版本边界以 SHA-256 + mtime 界定。

执行环境：DSH Android 沙箱（无 root）；bash 直连被拒（Permission denied），命令统一走 `mcp__mobile_tools__command_run`（shell=false，command 为绝对路径，cwd 为绝对项目目录，timeoutMs≤60000）；node=`/data/user/0/com.dshmobile.shell/files/usr/bin/node`；luau-web=`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-tools/node_modules/luau-web/src/index.js`。项目根：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。

## 1. 快照输入与版本边界（r8 / R13 / 当前源码）

审查期间源码仍在被所有权子代（4cb2dfdf）更新：适配器 mtime 06:14:01、契约 06:18:00、QA 文档 06:20:01。下列哈希为全部四次回归运行时刻的一致快照（运行前后输入哈希无漂移）。

| 文件 | 行数 | SHA-256 | mtime |
| --- | --- | --- | --- |
| `src/WindAdapter.luau` | 813 | `3bfd9e6389163fb1a11362e5bb6c5e2e195fb1cc0ea0d9ab47ccaeabe96abfef` | 2026-10-15 06:14:01 |
| `tests/test_wind_native_contracts.luau` | 1896 | `8d3c35c6554553244f248541efb06ee530c06eafe8da1c4920ee95843803ae15` | 2026-10-15 06:18:00 |
| `tests/test_wind_adapter.luau` | 319 | `b054b6395b63c2db3d36976db4c6aee0b7e6720e43e82f684b032ee35e9d64c8` | — |
| `tests/wind_native_harness.luau` | 51 | `09d86aa6a3820f6e53167e79a1d429ad16d918c258cf3c0f82619270403443c5` | — |
| `tests/run_wind_native_contracts.mjs` | 28 | `9f6d8b92d825c27e06ee838cbbeb2cddd5d9a2e1df039e98e5e3ac31898e675e` | — |
| `tests/run_luau.mjs` | 38 | `af3baef03d85a57c289d0a214a99aeaf6a2ac880b051ab40b25da4fa52334f28` | — |
| `vendor/WindUI/Source.lua` | 39919 | `e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05` | — |
| `docs/SHARED_UI_AUDIT_ROUND13.md` | 41 | `3f1bc661d0bed0e4a1256dae8acf818a9ec0fc44dc0b589219a63dc29ff88311` | 2026-10-15 06:03:19 |
| `docs/WIND_ANDROID_QA.md` | 43 | `5b630e1c4c0b0a1191570e566e17f2b777b1190348ac7e19374d0da4e7ec223f` | 2026-10-15 06:20:01 |
| `docs/SHARED_UI_ENRICHMENT.md` | 62 | `91cf491689d1dacfaaa419c2644251ac92fc3f617e6b4fa1044154d6626cedc1` | — |
| `tests/shared-ui-test-results.json` | — | `cce2470341a1bac30e65194df322264ecfae56afcecb81609cdb7a34b4531463` | 2026-10-14 20:35:23 |

与 R13 冻结记录（`docs/SHARED_UI_AUDIT_ROUND13.md:26-28`）对照，界定如下：

- 适配器 `ff3d9d1d…` → `3bfd9e63…`：所有权子代已改。R13 第 41 行「纯 inset 变化未订阅 TopbarInset」对当前源码**已过期**（当前已实现，见 §4）。
- 契约 `acc568dc…` → `8d3c35c6…`：119 项 → 123 项，新增 4 项 TopbarInset 契约。R13 的 119/119 是历史冻结快照结论，**不能当作当前源码的验收**。
- `vendor/WindUI/Source.lua` `e29ebad6…` 与 R13 一致，保持原样。
- `docs/WIND_ANDROID_QA.md` 本轮已更新（第 34 行改为 123/123 并列出 TopbarInset 4 项，第 40-41 行已描述订阅实现与真机清单）；`docs/SHARED_UI_ENRICHMENT.md` 第 58 行**未同步**（仍写「未订阅 TopbarInset」），见 §6.1。
- `tests/shared-ui-test-results.json` mtime 早于当前适配器与契约，记录过期，不得引用为本轮证据。
- `dist/` 与发布门禁结论属历史 r8 证据（`docs/SHARED_UI_ENRICHMENT.md:60` 明确「非本轮、当前未重建」）；本轮未运行发布门禁 / build / packager。

## 2. 实际执行记录（命令 / exitCode / 计数）

| # | 命令（cwd=项目根） | 结果 | exitCode |
| --- | --- | --- | --- |
| 1 | `node /data/data/com.dshmobile.shell/files/home/Vortexion-lua/.r14_preview/r14_snapshot_runner.mjs`（隔离执行器，正向） | `WIND_NATIVE_CONTRACTS: passed=123 failed=0 checks=123` → `WIND_NATIVE_CONTRACTS_GREEN`；stderr 空；1196 ms | 0 |
| 2 | 同上，`R14_NEGATIVE=1`（内存负对照，不落盘） | `passed=120 failed=3`；`WIND_NATIVE_CONTRACTS_RED: 3 contract(s) failed`（契约第 1894 行门禁）；1096 ms | 1 |
| 3 | `node tests/run_luau.mjs src/WindAdapter.luau` | `PASS compile src/WindAdapter.luau` | 0 |
| 4 | `node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau` | `PASS execute tests/test_wind_adapter.luau`（4 组全过） | 0 |

说明：

- 命令 1 使用自建隔离执行器（项目外 scratch：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/.r14_preview/r14_snapshot_runner.mjs`），复刻 `tests/run_wind_native_contracts.mjs` 的夹具装配逻辑（vendor 八段切片、base 前缀、harness 占位符替换、`__FACTORY__` 注入适配器全文），绝对路径 import luau-web，运行前打印 5 个输入 SHA-256；未运行也未修改原执行器与任何测试文件。
- 命令 2 为内存负对照：仅在装配字符串内移除 `src/WindAdapter.luau:779`（CreateWindow 内 `installTopbarInsetWatch()` 调用点）。3 个 RED 全部落在 TopbarInset 契约组（1680 / 1787 / 1852 行），报错分别为「watch live after the queued install drains」「GetService reached once, got 0」「synchronous reentrant teardown … must make CreateWindow return nil」；「接口抛错不影响初始化」组（1744 行）在负对照下仍 PASS（移除安装后该不变量平凡成立）。结论：4 项新契约中 3 项对安装调用点有效，门禁非空转；这与 R13 第 30-37 行的负对照纪律一致（exit 1 是预期对照，不是源码回归）。
- 命令 3/4 与 R13 第 18/20 行记录的命令一致，均 exit 0；`tests/test_wind_adapter.luau` execute 输出 4 组全过。

## 3. API 语义逐条核对

- `GuiService:GetGuiInset()` 返回 topLeft/bottomRight 两个 Vector2（官方 API）。适配器 `src/WindAdapter.luau:633-652` 以 pcall 读取并把 `.X`/`.Y` 摊平为 left/top/right/bottom，`clampInset` 限 0..4096。按 Roblox 屏幕坐标（左下原点）语义：topLeft=(left,top)、bottomRight=(right,bottom)，摊平方向正确。
- `TopbarInset` 是只读 Rect。适配器只把它当「重读 GetGuiInset」的触发器（`src/WindAdapter.luau:68-73` 注释、84 行取 `GetPropertyChangedSignal("TopbarInset")`、88-92 行 handler 内 `requestLayout()`），从不把 Rect 当坐标使用。语义正确。
- 偏移量纲：vendor ScreenGui `IgnoreGuiInset=true` / `ScreenInsets="None"`（`vendor/WindUI/Source.lua:39589-39590`），Main `AnchorPoint=.5` 且 UIScale 挂在 Main 自身 → 适配器用父级屏幕像素 offset（`UDim2.new(0.5,offsetX,0.5,offsetY)`，`src/WindAdapter.luau:674-702`）成立，offset 不乘除 scale。
- 居中目标数学：`offsetX=(left-right)/2`、`offsetY=(top-bottom)/2`（`src/WindAdapter.luau:660-661`）等于「可用区中心 − 屏幕中心」，正确。
- `factor=clamp(floor(min(availW/sizeX,availH/sizeY)*100+1e-6)/100,0.1,1)`（`src/WindAdapter.luau:663`）：两位小数、范围 0.1–1，与 `docs/SHARED_UI_ENRICHMENT.md:7` 表述一致。
- 可读性保护：`factor=max(factor,clamp(minScale,0.1,1))`（`src/WindAdapter.luau:665-668`）；`wind_min_scale` 0.3–1、默认 0.5（`src/WindAdapter.luau:450`）。
- 受控 Tween：safeActive 时把 `native.UIElements.Main` 移到目标；Create/Play 失败降级直写、缺 Main 取消并 return 不缓存（`src/WindAdapter.luau:674-702`）；非 safeActive 走 `native:SetToTheCenter()`（`src/WindAdapter.luau:703-705`）。
- 提前退出：not Active / not native / not AutoFit / IsFullscreen → `cancelOwnedCenter` + `lastLayout=nil`（`src/WindAdapter.luau:607-611`）；空相机与极小视口同处理（`src/WindAdapter.luau:615-618`）。
- 缓存键：`lastLayout` 含四 inset + 相机身份（`src/WindAdapter.luau:672-673,708`），故纯 inset 变化也重排——这正是 TopbarInset 订阅要可靠触发的那条路径。
- 销毁：`cleanup` 先断开 connections 全表并清空、`topbarConnection=nil`（`src/WindAdapter.luau:146-148`），再 `cancelOwnedCenter()`（`src/WindAdapter.luau:149`）。
- 诊断：`src/WindAdapter.luau:459` 新增 `TopbarInset 监听: 是/否`（`topbarConnection and "是" or "否"`）。

## 4. 纯 inset 监听覆盖（本轮变化）

实现要点（`src/WindAdapter.luau`）：

- `installTopbarInsetWatch()`（74-103）：`task.spawn` 内四段 `bridge.Active` 围栏（80/82/85/95 行）；`GetPropertyChangedSignal("TopbarInset")`（84 行）；handler 门控 `Active && SafeArea && AutoFit` 后 `requestLayout()`（90-91 行）；晚到连接立即 `Disconnect` 不入表（95-98 行）；`topbarConnection` 入 `connections` 回收表（100-101 行）。
- CreateWindow 在 `bridge:FitViewport()` 之后调用（`src/WindAdapter.luau:778-779`）；同步 executor 重入销毁时返回 nil 并清缓存（`src/WindAdapter.luau:782`）。

fixture 覆盖（`tests/test_wind_native_contracts.luau:1649-1890`）：

- `probeVec2` 用 `newproxy(true)` 且断言 `type=="userdata"`（1650-1659 行），拒绝 table 替身；`withGuiFixture`（1662-1667 行）逐组 pcall + 全局还原，单组失败不级联。
- 四组契约：1680 行（健康异步连接后事件真实重定位、突发同帧合并、SafeArea/AutoFit 关时静默、销毁 inert）；1744 行（`GetPropertyChangedSignal`/`Connect` 抛错不破坏初始化与显式 Fit）；1787 行（安装三阶段 fence + 晚到 connection 恰一次 Disconnect）；1852 行（同步 executor 安装中重入销毁 → CreateWindow 返回 nil 且缓存清除）。
- 汇总行 1892、RED 门禁 1894、GREEN 1896。

fixture 无法证、仍需真机（与 `docs/WIND_ANDROID_QA.md:41` 一致）：真实 `TopbarInset` 信号时序与频率；真实 Tween 时长/插值；拖窗与双击仍走 vendor 屏幕中心（不含 offset）；物理刘海 / 显示屏切口 / 系统手势区；分屏与软键盘弹出导致的 inset 与视口变化。

## 5. 文字溢出与窗口可达性

- 事实：可读性保护开启且 `wind_min_scale` 偏低时，窗口可能大于视口、可能裁切边缘——这是已声明的取舍（`docs/SHARED_UI_ENRICHMENT.md:56`、`docs/WIND_ANDROID_QA.md:38`：清晰度优先于完整性，不保证不裁切、不保证全视口可达）。
- 缺口：没有任何 TextScaled / 自动换行 / 裁切检测类契约；窗口可达性只依赖标题栏可拖（vendor 行为）与「恢复触控入口」按钮（`src/WindAdapter.luau:442`）；「核心入口始终可达」未验证。
- 建议真机检查：最长配置名与分区标题在 `wind_min_scale=0.5`、小视口（约 320×480 等效）下是否被裁切；触屏侧栏 160px（`src/WindAdapter.luau:724`）下文字是否截断；裁切后标题栏是否仍可拖、悬浮恢复按钮是否可达。

## 6. 文档与源码不一致（交父，本子代未改）

1. `docs/SHARED_UI_ENRICHMENT.md:58` 仍写「inset 变化只在显式 FitViewport 或已有布局事件时重读，未订阅 TopbarInset」，与当前源码（`src/WindAdapter.luau:74-103,779`）及 `docs/WIND_ANDROID_QA.md:40-41` 矛盾。QA 已同步、ENRICHMENT 未同步；属所有权子代文档，待其更新。
2. 亚克力初始状态存疑（新发现）：`vendor/WindUI/Source.lua:38667` 位于 `aw.Open`（38574-38670 行）内，每次开窗无条件执行 `av.WindUI:ToggleAcrylic(true)`；适配器 CreateWindow 传 `Acrylic = true`（`src/WindAdapter.luau:724`，vendor 37405-37407 据此创建亚克力涂层），而开关 `wind_acrylic` 的 `Default = not input.TouchEnabled`（`src/WindAdapter.luau:409`）在触屏显示为关；适配器未在 CreateWindow 后按 `wind_acrylic` 当前值回写同步。运行时关闭路径存在（「简化视觉效果」按钮 `src/WindAdapter.luau:444` → `option:SetValue` → `self.Native:Set`（`src/WindAdapter.luau:339`）→ toggle Callback → `WindUI:ToggleAcrylic(v)`（`src/WindAdapter.luau:409`）），但 `native:Set` 是否触发 callback 未经 fixture 证明。结论：触屏无存档首启时，「开关显示关」与「亚克力实际为开」可能不一致，与 `docs/SHARED_UI_ENRICHMENT.md:8`「触屏默认关闭亚克力」矛盾；需真机确认，修复属所有权子代。
3. `tests/shared-ui-test-results.json`（mtime 2026-10-14 20:35）早于当前适配器与契约，记录过期，不得作为本轮证据引用。

## 7. 可操作真机验收清单（未证实项）

1. 旋转：开 `wind_safe_area`，横竖屏旋转 → 窗口应在新的四边 inset 内受控居中、同帧合并为一次；诊断行「TopbarInset 监听: 是」。（`src/WindAdapter.luau:90-91,660-661`；`docs/WIND_ANDROID_QA.md:41`）
2. 系统状态栏 / 分屏变化导致 GUI inset 变化 → 同上重排；关闭 SafeArea 或自动适配后事件不再排队、无残留位移。
3. 键盘弹出 / 收起 → 视口变化经相机观察器触发重排（`src/WindAdapter.luau:770-772`）；确认当前聚焦输入框不被遮挡（fixture 无键盘，必须真机）。
4. 触屏首启亚克力状态 → 按 §6.2 核对开关显示与实际模糊是否一致。
5. 拖窗 / 双击 → 仍走 vendor 屏幕中心（不含 offset）；确认 SafeArea 开启时拖窗后无异常回弹。
6. 全屏进入 / 退出 → owned 居中尾取消与恢复，真实动画无残留位移（fixture 已覆盖 early-exit 逻辑，真机核对时序）。
7. 物理刘海 / 系统手势区 → SafeArea 开启后窗口不被遮挡（`docs/WIND_ANDROID_QA.md:39,41` 未验证项）。
8. 可读性裁切 → 按 §5 检查最长文案与最小视口组合。
9. 视觉刷新档位 → 只验证档位与算出的间隔（5–60Hz 夹取），不宣称实测 FPS（`docs/WIND_ANDROID_QA.md:36`）。
10. 触控紧凑侧栏（160px）→ 文字与图标不截断、可滚动。

## 8. 边界与移交

- 本文件为 R14 Preview 子代唯一产出；未创建子代或目标；未修改任何既有文件、`vendor/`、`dist/`、`build.py` 与共享测试。
- 隔离执行器位于项目外 scratch（`.r14_preview/r14_snapshot_runner.mjs`），不属项目交付物；父级可借其复刻快照回归。
- 全部结论为快照回归（快照哈希见 §1）；父级冻结验收前需重跑复核；fixture / 编译结论不得宣称真机通过。
- 移交父级的问题：§6.1（ENRICHMENT 第 58 行未同步）、§6.2（触屏亚克力初始状态）、§6.3（过期测试结果 JSON）。
