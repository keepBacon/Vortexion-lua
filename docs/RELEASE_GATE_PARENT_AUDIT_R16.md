# 第 16 轮发布门禁父审计（部分进展）

## 改动与目标状态

当前总目标 revision 18、active/armed，第 16/256 轮；整体目标未完成。本轮复用既有构建子代，只将四套共享专项接入发布门禁并审计验收，不执行六包重建、完整发布流水线或归档。游戏源码、vendor、dist 与历史 JSON/ZIP 未由本轮改写。

`tests/run_release_checks.mjs:25-35` 用 addNode 统一 Node 与 Luau 包装，在 native-contracts 后各注册一次预算、视口、输入、Acrylic 专项；由 27 阶段扩为 31，原阶段、顺序、参数及 testsStable/inputsStable/outputsStable 门槛保留。显式 NODE_LAUNCHER 时参数为 [NODE_BINARY, ...args]；未设置时保留桌面默认。该配置不自动解决 Python/Lua 或后续脚本的所有 Android 子进程启动路径。

`tests/test_release_runner.mjs` 的 45 套合同使用真实门禁文本与内存文件系统/进程返回值，独立精确清单检查两模式、四阶段各自非零/skip、八个新增测试文件阶段内漂移及原十套合同。合同不真正构建或启动游戏，模拟成功不等于 31 阶段发布通过。子代证据见 `docs/RELEASE_GATE_SHARED_R16.md`。

## 父独立实际执行

工作目录 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`；实际 Node `/data/user/0/com.dshmobile.shell/files/usr/bin/node`，v24.18.0。本机 process.execPath 实测为 /apex/com.android.runtime/bin/linker64，argv0 才是上述 Node 路径。SDK 直接执行器或显式 /system/bin/linker64 + Node + 绝对 runner；没有用 process.execPath 猜解释器。

| 命令（相对工程根目录） | exit | 父结果 | 耗时 |
| --- | ---: | --- | ---: |
| node tests/run_luau.mjs src/WindAdapter.luau | 0 | 共享源码编译 | 912 ms |
| node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau | 0 | 工厂回归 | 1098 ms |
| node tests/run_wind_native_contracts.mjs | 0 | 124/0 | 1202 ms |
| node tests/run_wind_visual_budget_r14.mjs | 0 | 300068 断言；createWindowCalls/scheduleCalls/getServiceExtra 均 0 | 1146 ms |
| node tests/run_wind_viewport_edges_r14.mjs | 0 | 7/0 | 1188 ms |
| node tests/run_wind_input_queue_r14.mjs | 0 | 7/0 | 1062 ms |
| node tests/run_wind_acrylic_policy_r16.mjs | 0 | 9/0 | 1009 ms |
| node tests/run_luau.mjs | 0 | 34 个活跃源码、6 个历史 bundle、vendor 与 loader，共 42 文件仅语法编译 | 3422 ms |
| node tests/test_release_runner.mjs | 0 | GREEN 45，内存门禁合同 | 502 ms |

七项共享命令之间逐次核对 `docs/SHARED_UI_FINAL_AUDIT_R16.md:33-47` 的 15 个输入，字节数与 SHA-256 一致。全源码编译不执行游戏，也不证明当前源码已进入旧六包。

## 父承重负对照与冻结证据

父保持原合同 ESM 上下文，只劫持门禁文本读取，先确认 45/45 正对照，再逐次只变更一个门禁承重点；未落盘。每次要求 ERR_ASSERTION、预定已通过套数及具体断言，驱动 exit 0、977 ms；其含义是四个预期失败被捕获，不是四个变异门禁通过。

| 内存变异 | 已通过合同数及具体失败 | 变异门禁 SHA-256 |
| --- | --- | --- |
| 漏注册预算阶段 | 0；30 !== 31 | 99791718ba5f38377c7831ee1ce6dfa5ae30d934f04dd665d1f4bf8e5a292570 |
| 总结果忽略 testsStable | 1；0 !== 1 | d7fb07861aff60994275093aee4a263f0d1e8712ba4731ded6d8e24a75fed916 |
| 单阶段忽略 skip | 9；0 !== 1 | 7520621d353f62c77a247431b7424a53eacc5f8a1c33e382d3cac3679af4a9ff |
| launcher 参数漏 Node 前缀 | 27；strictly deep-equal 参数清单失败 | 45929efebd1a2a824a80c94b98039fc26eddd609b7750824008801e1349f9586 |

最初两次父驱动因 URL 字面量误替换、嵌套 VM 未注入 Buffer 而未通过正对照，不计入负对照成功；改用原 ESM 上下文后正对照和四项断言捕获均通过。六个磁盘产物（门禁、自测、共享桥、vendor、构建清单、发布 JSON）在最终变异驱动两端哈希相同。

| 文件 | SHA-256 |
| --- | --- |
| tests/run_release_checks.mjs | 9dceb49f492714ffdd7ee4337ebdda9c8e7ea3e59b399d28df76f51d0bfb985f |
| tests/test_release_runner.mjs | f25bed22b5675b6d2c8af5e0bba034d3f1901aa1cd7cefdf9fad11fa0a30dcc4 |
| src/WindAdapter.luau | 698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981 |
| vendor/WindUI/Source.lua | e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05 |
| dist/build-manifest.json | 456b7d3b3968084e4cde96ac5e52653590e03fea997db6efe3d1b53f32e76e60 |
| tests/release-test-results.json | e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be |

## 未完成与审计点

只读构建核对发现 34 个输入中 7 个与旧清单不同：src/AOTRBattle.luau、src/AOTRMovement.luau、src/BloxStrikeCosmetic.luau、src/ForsakenCore.luau、src/ForsakenVisual.luau、src/SCPESP.luau、src/WindAdapter.luau。旧六包自身哈希/字节数全部匹配旧清单，luau_compiler_tested 仍 false；六包自洽不等于源码/产物一致。未运行 31 阶段真实发布器，未提升 compiler evidence，未重新核对 203 ID 迁移或完整功能差异。

审计点：新套件是否真正执行、原阶段是否保留、skip/非零与文件漂移是否误提升、Android launcher 参数是否保留解释器、旧构建是否被误当当前产物。优化：精确清单、双启动合同和四个父承重负对照；未改变业务源码或扩大游戏测试范围。后续先处理功能差异与历史缺陷、source/dist 一致性和真实发布证据；完整游戏测试暂非用户要求，Roblox/Android 真机与性能数据仍未获得。
