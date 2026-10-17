# R14 审查：TopbarInset 安装所有权 / task.spawn 语义 / 各阶段销毁重入 / callback 晚到

性质声明：本文是**快照回归审查**，不是父级冻结验收。审查窗内 `tests/test_wind_native_contracts.luau` 发生两次漂移（acc568dca8538e58 → 8d3c35c655455324 → 77b1c25942c3e62e），shared 子代 4cb2dfdf-1139-4162-96ff-e9f72e7614e8 在窗内新增了 TopbarInset 契约；以下行号与结论仅对文末快照 hash 成立。

## 快照与执行记录

快照（sha256 全值/前16位）：

- `src/WindAdapter.luau` = 3bfd9e6389163fb1a11362e5bb6c5e2e195fb1cc0ea0d9ab47ccaeabe96abfef（50641 bytes，814 行含尾行），审查全程未变。
- `tests/test_wind_native_contracts.luau` = 77b1c25942c3e62e94372a012632150135f44b22dad5b6a51190213a42483f77（117121 bytes，1976 行，124 checks）。
- `tests/run_wind_native_contracts.mjs` = 9f6d8b92d825c27e06ee838cbbeb2cddd5d9a2e1df039e98e5e3ac31898e675e；`tests/test_wind_adapter.luau` = b054b6395b63c2db3d36976db4c6aee0b7e6720e43e82f684b032ee35e9d64c8；`tests/wind_native_harness.luau` = 09d86aa6a3820f6e53167e79a1d429ad16d918c258cf3c0f82619270403443c5。

实测命令（cwd=/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project，node=/data/user/0/com.dshmobile.shell/files/usr/bin/node，timeoutMs=60000）：

1. `node tests/run_wind_native_contracts.mjs` → exitCode 0，`WIND_NATIVE_CONTRACTS: passed=124 failed=0 checks=124` + `WIND_NATIVE_CONTRACTS_GREEN`，stderr 空。
2. `node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau` → exitCode 0，`PASS execute tests/test_wind_adapter.luau`，stderr 空（`[Fixture/WindUI] ... fixture callback failure` 为夹具内预期注入断言，非失败）。
3. 负对照执行器：与 `run_wind_native_contracts.mjs` 同一装配管线（base 切分 + harness vendor 摘录 + contracts + `__FACTORY__` 全文替换 adapter），仅对 adapter 做定点字符串突变，全部在内存中执行，未落盘任何源码、未改动任何既有文件。

## 结论摘要

未发现新的生产级缺陷。父上轮指出的三项均已修复且有契约覆盖，不应作为现存缺陷重报。TopbarInset watch 的 5 处 fence/守卫经内存负对照证明承重；2 处为纵深防御（去后全绿，但不建议删）。同步 spawn、异步队列、Connect 内真实 yield 暂停三种执行阶段均已覆盖，父问的"同步 spawn 与后台 yield 阶段实际 test 覆盖"问题有肯定答案。

## 父指出项核实（均已修复，避免重复报告）

1. 任务入口：`bridge:CreateWindow` L713 `if windowHandle then return windowHandle end` + L714 `if not self.Active then return nil end` 双 guard 在位。
2. 两处暂停后 Active fence：L726（WindUI:CreateWindow 返回后）与 L759（installSettings 后）`if not self.Active then cancelled = true; return nil end` 在位。
3. install 后 windowHandle 公开缺再检查：L780-782 `if not self.Active then cancelled = true; return nil end` 位于 L783 `windowHandle = win` 之前，窗口句柄只在存活检查通过后才发布。

## watch 所有权与逐阶段审查（src/WindAdapter.luau L68-103）

安装所有权：`installTopbarInsetWatch` 仅在 `bridge:CreateWindow` L779 调用一次；L713/L714 入口 guard 保证同一 bridge 不会二次进入安装；L75-76 `topbarWatchInstalled` 幂等 flag 先置位后 spawn，防同帧重入。连接池化：L100 `topbarConnection = connection`、L101 `table.insert(connections, connection)`；销毁侧 cleanup L146 统一断开池内连接、L147 `table.clear`、L148 `topbarConnection = nil`；诊断 L459 `TopbarInset 监听: %s` 反映真实池状态。callback 晚到：L90 `if not bridge.Active or not bridge.SafeArea or not bridge.AutoFit then return end` 后 L91 `requestLayout()`，requestLayout L61 自带 `if not bridge.Active or layoutQueued then return end`，defer 体内 L65 再次 Active 检查，晚 callback 三重拦截。

各阶段 fence 与负对照证据（突变后跑全量 124 checks，观察对应契约转 RED）：

| 突变 | 位置 | 结果 |
| --- | --- | --- |
| NC1 删入口 fence | L80 | 1 RED：`scheduled install destroyed before drain must not touch any stage, got 1/0/0` |
| NC6 删 GetService 后 fence | L82 | 1 RED：`teardown during GetService must not reach GetSignal/Connect, got 1/0` |
| NC2 删 Connect 前 fence | L85 | 1 RED：`teardown during GetSignal must not reach Connect, got 1` |
| NC3 删晚连接断开 | L95-98 | 3 RED：fence 契约 `late connection after teardown disconnects exactly once, got 0`；同步重入契约 `got 0`；yield 暂停契约 `got 0` |
| NC8 删 callback 的 SafeArea/AutoFit 守卫 | L90 | 1 RED：`safe-area off: TopbarInset event must not queue a layout, queue=1` |
| NC4 删 callback 的 Active 守卫 | L90 | 0 RED（全绿） |
| NC5 删幂等 guard | L75-76 | 0 RED（全绿） |

NC3 一改即三契约红，说明 L95-98 的"迟到连接立即断开且不池化"是三种执行模型共同依赖的承重结构。NC4/NC5 见下节边界说明。

## task.spawn 语义与三阶段覆盖（回答父的问题）

现有 5 个 TopbarInset 契约（tests/test_wind_native_contracts.luau 当前快照行号）：

- L1680 健康异步：deferred 队列模型（base 夹具 `task = {defer=queue, spawn=queue}`），真 signal 重定位、burst 三次 Fire 合并为 1 个 queue 且读最终 inset、safe-area/auto-fit 关闭静默、destroy 后晚 callback 不动窗不排队、诊断 是/否 翻转。
- L1744 降级：GetPropertyChangedSignal 抛错、Connect 抛错均不破坏 init，显式 Fit 仍落 offset 20。
- L1787 三阶段 fence：destroy 于 GetService 内（signal/connect 0 次，断言 L1831-1832）、于 GetSignal 内（connect 0，L1838-1839）、于 Connect 内（disconnect 恰好 1 且不池化，L1845-1846）。
- L1852 同步执行器：`task = {defer=real, spawn=function(fn) fn() end}`，install 内 Connect 重入销毁 → CreateWindow 返回 nil 且缓存清除（L1886 二次 CreateWindow 仍 nil）。
- L1892 后台 yield 阶段（窗内新增）：`task.spawn` 用真实 `coroutine.create/resume` 实现（生产语义），Connect 内真实 `coroutine.yield()` 暂停 install 协程；健康分支——窗口先合法返回、暂停期诊断为否、暂停期显式 Fit 仍落 offset 20、resume 后订阅真正生效且事件只放 1 次 tween；取消分支——暂停 → Destroy → resume，迟到连接 disconnect 恰好 1 次、不池化、强制晚 callback 不排队不动窗、销毁后 CreateWindow 返回 nil。

生产语义判定：install body（L77-102）不存在 yield 点，真实 Roblox `task.spawn` 会同步执行到首个 yield，因此生产路径与 L1852 的同步模型同构；L1787 的队列模型是更保守的超集；L1892 覆盖了唯一可能的真实暂停点（Connect 内 yield）及其取消路径。三阶段覆盖齐备，无需再补 spawn 语义用例。

重入双装实测（本审查新增场景，内存执行）：令 `workspace.CurrentCamera = nil` 后在相机等待循环的 `task.wait` 内二次调用 `bridge:CreateWindow({})`，重入调用自身撞上 L719 `assert(world.CurrentCamera, ...)` + 5s deadline 失败返回（ok2=false，返回断言错误串），首次调用恢复后正常完成：`signalCalls=1 connectCalls=1 sections=3 allTabs=5 watchLive=true asyncErrors=0`，销毁后 `disconnectCalls=1 watchCleared=true`。即相机等待期内不存在 watch 双装路径；去掉 L75 guard（NC5）重跑该场景结果完全一致，证明该 guard 当前不可达、属纵深防御。

## 新发现与边界（无 P0/P1；均为 informational / coverage note）

- B1（informational，加固建议）：L100 先 `topbarConnection = connection` 发布、L101 才 `table.insert(connections, connection)`。两点之间无 yield 点，当前执行模型下不可观察（NC 无法构造失败）；但若未来在 Connect 与池化之间引入暂停，销毁落在窗口内会漏断连接。建议对调两行并把 L95 fence 后移到 insert 之后，属预防性加固，非现存缺陷。
- B2（informational，设计内降级）：GetService/GetPropertyChangedSignal/Connect 任一抛错后 `topbarWatchInstalled` 永为 true，该 bridge 实例不再重试安装，诊断仅显示"否"、无法区分"未安装"与"安装失败"。L68-73 注释已明示此降级策略（不破坏 init、不破坏显式 Fit），记录备查即可。
- B3（coverage note）：L75-76 幂等 guard 无直接契约（NC5 去后 124 全绿，重入场景实测亦不可达）。建议 shared 子代后续补一条"双装尝试只产生 1 个连接"的契约，或在对调 L100/L101 时一并覆盖。
- B4（verified-not-defect）：callback 的 Active 守卫（L90）删除后全绿，因为 requestLayout L61 与 defer 体 L65 已双重拦截。该守卫冗余但正确，与 L90 的 SafeArea/AutoFit 守卫（NC8 证明承重）并存无成本，不建议删。

## 健康路径对照

burst 合并后读最终 inset（三次 Fire 只排 1 次 layout、只放 1 个 owned tween）；显式 Fit 在 watch 缺失/暂停/取消三种降级下均落 offset 20；yield 暂停期窗口已合法返回且订阅恢复后真实生效；销毁路径下监听诊断翻"否"、池清空、晚 callback 完全惰性。

## 残余边界

- 本文为快照回归：审查窗内 contracts 文件两次漂移，最终以 77b1c25942c3e62e（124 checks）为准；后续任何源码/契约变更都需重跑本文命令与 NC 矩阵。
- 全部证据来自 luau-web fixture 与内存负对照，未在真实 Roblox 客户端运行；`tests/shared-ui-test-results.json` 记录 roblox_android / roblox_pc / integrated_bundle_tested 均为 false，且其内 WindAdapter hash（93eecbf44aef2204）已过时，fixture 通过不等于真机通过、不等于整包完成。
- 未修改 `src/WindAdapter.luau` 及任何既有文件、vendor、build.py、dist、历史包、原测试；负对照全部内存执行，未落盘。

## 附：Acrylic 修补设计审查（父 m00207 转向；快照：src 未落补丁）

本轮快照：`src/WindAdapter.luau` = 3bfd9e6389163fb1a11362e5bb6c5e2e195fb1cc0ea0d9ab47ccaeabe96abfef（50641B/814 行，与上节同一 hash，补丁未落）；`tests/test_wind_native_contracts.luau` = c00c2a3c211e4272c4e9d431d8c8178f4a3dc3afe0ebfabd3abda5cacd54c1b1（118397B/1988 行，shared 继续新增契约，acrylic 相关仍为 0）。vendor 事实（vendor/WindUI/Source.lua，obfuscated）：

- L38574 `function aw.Open(F)`：整体在 `task.spawn` 内，`task.wait(0.06)` 后 L38667 `av.WindUI:ToggleAcrylic(true)` 无条件强开；OnOpenCallback（L38579-38581）触发早于该强置。
- L38671 `function aw.Close(F)`：L38684 `av.WindUI:ToggleAcrylic(false)` 无条件强关；OnCloseCallback（L38678-38681）同样早于它。
- L39715 `function aa.ToggleAcrylic(az,aA)`：guard `aa.Window and aa.Window.AcrylicPaint and aa.Window.AcrylicPaint.Model`，写 `aa.Window.Acrylic=aA`、`Model.Transparency=aA and 0.98 or 1`，并调 `au.Enable()/au.Disable()`；`au` 为 L39574 `a.load z` 的模块级单例（全局副作用）。
- L39786 `function aa.CreateWindow(az,aA)`：L39899 `aa.Window=h`（模块级当前窗口单槽），L39901-39903 `if aA.Acrylic then au.init() end`；CreateWindow 自身不调 Open——窗口创建后为关闭态，首次 Open 由 K 键/开放按钮/`native:Toggle` 触发。
- L37405-37408：仅当窗口配置 `Acrylic` 为真才创建 `AcrylicPaint`——创建时传 false 会导致 L39716 guard 永假、亚克力开关彻底失效。

对父列六点的审查结论（源码未落，均为设计层建议，已通过父转交 shared 4cb2dfdf；直发失败：subagent belongs to another parent session）：

1. 保留初始分配：L724 `Acrylic = true` 是正确的且不可改为偏好值——false 会连 paint 都不分配。偏好必须在分配之后作为独立状态施加。
2. 独立偏好：禁止把 `native.Acrylic`/`WindUI.Window.Acrylic` 当偏好回读（L39717 会被 Open/Close 写脏）；应以 bridge 自有字段/选项值为唯一真相，诊断补偏好/实际对比。
3. Close false / Open true 时序：现行真实 vendor 流下，移动端偏好 off 会在首次 Open 被 L38667 无条件强开（UI 仍显示关，偏好被静默覆盖）；桌面偏好在 Close 后被 L38684 强关、下次 Open 再强开。因 Open 强置在 `task.spawn + task.wait(0.06)` 之后，同步包 `native.Open` 或挂 OnOpenCallback 都会早于它执行而被反覆盖；可靠方案为包 Open/Close 后延时重申（wait 大于 0.06），或把 `WindUI.ToggleAcrylic` 替换为偏好感知版（推荐）。
4. 所有权归还与构造回滚：任何包装/替换必须存 original，并在 cleanup（L140-160）与 CreateWindow 失败分支（L786-809，error 重抛前）幂等恢复；现失败路径 L794-805 不清替换，补丁若在 L723 pcall 内生效而构造后续失败，会污染下一次尝试/新实例。
5. 多窗口/新实例污染：`aa.Window` 单槽（L39899）+ `au` 全局单例，偏好只能写本窗口创建时持有的 `native.AcrylicPaint.Model`，或施加前断言 `aa.Window == native`；不得经全局 ToggleAcrylic 互踩。
6. 真实 vendor 流测试：现有 fixture `wind:ToggleAcrylic`（tests/test_wind_adapter.luau L83）仅 `self.acrylic = v`，无 Open/Close 强置、无 Model、无 au；L92/L201/L288 断言对 Open-stomp 无鉴别力。需补 vendor 流夹具（Open 无条件 true/Close 无条件 false + Model.Transparency + au 计数器）与承重负对照（删重申逻辑→移动端 Open 后实际为 on 的断言 RED；偏好回读改 native.Acrylic→Close 后 RED）。

不确定项（快照内无法定论）：vendor AddToggle 的 Default 是否在创建时即触发 Callback 未在 vendor 侧最终确认（建议方案不依赖它）；`au` 的 Enable/Disable 跨窗口视觉影响未实机验证；shared 补丁未落，落地后需按本节快照重跑复核。

## 附二：Acrylic 候选补丁收尾与审查关闭（父 m00237-m00283 轮）

### 原生 38920 异步开窗纠正（对本文 L85 的更正）

实读 vendor/WindUI/Source.lua L38908-38935：L38920 `task.spawn(function()` / L38922 `aw:Open()` / L38923 `end)` 位于窗口构造流程内——`aa.CreateWindow` 虽不直接调 Open，但构造流程异步触发 Open。故附一 L85「创建后为关闭态，首次 Open 由用户触发」的表述过强，实际首次 Open 由构造内 spawn 的协程触发（L38585 `task.wait(0.06)` 后执行 L38667 强置）。因该协程在 wait 处挂起，adapter 在 CreateWindow 返回后同步安装 wrapper 早于 38667 首次执行，在已验证路径上首次 Open 必被 wrapper 覆盖，附一第 3 点中「挂 OnOpenCallback 会早于它执行而被反覆盖」的担忧在包装方案下不成立。该结论仅对原样 vendor 的当前同步返回路径成立：fixture 未证明所有外部重入/yield 介入或真实渲染调度下的安装时序。

### 候选补丁迭代与父实证

补丁在审查窗内三次漂移（shared 4cb2dfdf 独占修改，本子代只读）：

- d0b7ed38c3010bbf019a9b872cadc733afc0be0750cbb3a89628cecf4c30df2a（52175B/836 行）：首版 wrapper，L24 单向降级 `if value and not acrylicPref then value = false end`，无身份判别；安装 L748-752 带 `__VortexionOrigToggleAcrylic` marker；cleanup L162-166 恢复+清 marker 后 `originalToggleAcrylic = nil`。
- 67ca794d79af7037b7722adf481603dedda87b398fc4935400d3c54d1185c4d2（52542B/840 行）：shared 落身份栅栏 L28 `if self == WindUI and self.Window == native and bridge.Active and value and not acrylicPref then value = false end`，删 marker 字段；cleanup L168-171 仅字段==acrylicWrapper 时恢复、L171 清 nil。
- d9d752605d3f3cc67cc9d86e84f23e97ed60ebd4408400d3083897cc58a27543（父 m00283 报）及当前快照 698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981（53298B/848 行）：L29 `local originalToggleAcrylic, acrylicForward = nil, nil`；L34-35 `local forward = originalToggleAcrylic or acrylicForward` + `if forward then return forward(self, value) end`；cleanup L172-174 恢复（仅字段仍是本桥 wrapper）、L178 `acrylicForward = originalToggleAcrylic or acrylicForward` 保留最后捕获的 original 不释放、L179 才清 `originalToggleAcrylic = nil`。

父实证（d9d752605d3f3cc6，父 m00283）：外部委托链正对照转发 1 次且值 true；删除 L178 保留路径的内存负对照转发 0 次且值 false 并捕获错误；driver exit0。67ca 上父曾复现 `EXTERNAL_DELEGATE_FORWARDED_CALLS 0 / ACTUAL_VALUE false / EXTERNAL_DELEGATE_STOPPED_FORWARDING_AFTER_DESTROY`（cleanup L171 清 nil 后 L31 return 分支消失、wrapper 变 no-op 吞调用），d9d752 起该半死链已修。

### 本子代独立复现（快照 698951714297d75e，前后 hash 一致）

夹具复刻 tests/run_wind_native_contracts.mjs 装配（base 切分 + wind_native_harness.luau vendor 摘录 + `__FACTORY__` 全文替换，luau-web createAsync），场景全内存执行：

- E0 移动端健康路径：vendor Open 强置 true 被 L31 栅栏降级为 false；主题页 toggle `Set(true)`+drain 开启偏好后强置透传 true；Destroy 后字段恢复原计数桩，晚调用转发 1 次、acrylic=true。
- E3 单桥+外部 wrapper 盖写（父 m00278 同构场景）：cleanup 跳过恢复（字段≠acrylicWrapper），外部委托存活，转发 1 次、acrylic=true。
- E7 双桥逆序销毁（g1 先 Destroy、g2 后 Destroy；夹具层双 createBridge 委托组合，不代表原生 vendor 多窗口）：字段最终停在中间 wrapperG1（非 realStub，链多一跳但经 L178 fallback 仍转发 1 次、acrylic=true）；同场景在 67ca794d 上为死链（0 转发、acrylic 不写），证明 acrylicForward fallback 承重。
- E1 双桥正序销毁（同为夹具委托组合，非原生多窗口证明）：字段恢复 realStub，转发 1 次、acrylic=true。

### 审查结论（关闭）

无开放生产缺陷项。附一六点设计建议、67ca 半死链、marker 污染均已由 shared 修复，且有父实证或本子代独立复现支撑。残余边界（记录不追修）：双桥逆序销毁后字段经中间 wrapper 转发（功能正确、链多一跳）；桌面偏好开启时 vendor Close 强置 false 透传（L31 单向降级为有意设计）；每桥独立偏好——`acrylicPref` 是 createBridge 工厂函数内每桥闭包 local，并非模块级共享，不存在跨桥确定性偏好顺序；vendor `aa.Window` 为单槽且 CreateWindow L39804-39806 拒绝第二窗口，E1/E7 双桥场景仅为夹具委托组合，不证明真实 vendor 多窗口行为或偏好安装顺序；原生多桥/多窗口不在本夹具结论内。r16 真实 vendor 流回归由 shared 4cb2dfdf 1139 4162 96ff e9f72e7614e8 负责最后落盘，本子代未闭环该项，交父后续冻结验收。本文整体为快照回归，不替代父冻结验收。
