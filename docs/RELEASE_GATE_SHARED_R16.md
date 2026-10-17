# R16 共享 UI 发布门禁接线证据

## 变更与门禁合同

仅修改 `tests/run_release_checks.mjs`、`tests/test_release_runner.mjs`，新增本文档。未执行完整发布器、构建器或打包器，未写入 dist、JSON、历史 ZIP，未运行游戏代理或创建子代。

`native-contracts` 后依次新增 `wind-visual-budget-r14`、`wind-viewport-edges-r14`、`wind-input-queue-r14`、`wind-acrylic-policy-r16`；共 31 阶段。原 27 阶段的名称、顺序、命令参数全部保留。`testsStable`、`inputsStable`、`outputsStable` 及成功提升条件保持原实现。

统一 `addNode(name, args)` 覆盖全部 Node 阶段与 Luau 包装调用。无 `NODE_LAUNCHER` 时仍直接调用 `NODE_BINARY || process.execPath`，保留桌面当前 Node 默认；有 launcher 时调用 `NODE_LAUNCHER`，参数为 `[NODE_BINARY, ...args]`。Android system linker 场景由调用方显式指定实际 `NODE_BINARY` 和 `NODE_LAUNCHER`；不推导根目录，缺省当前解释器路径不保证适用于 Android linker。Python/Lua 的命令与参数不变。

合同测试通过 VM 执行真实 runner 文本，替换 `spawnSync` 和文件系统为内存 fixture。每一阶段仅登记调用，所有构建、游戏测试及报告写入均为内存模拟。完整清单在直接与 launcher 两模式分别精确校验 31 个名称/命令/参数，四个新阶段各出现一次。四阶段逐个非零退出和 SkipTest 输出都使流水线停止、状态 failed、禁止 manifest 提升；各专项 mjs/luau 在对应阶段中改变后，即使 31 个模拟阶段均 exit0，`testsStable=false` 仍使总门禁 failed。原十套输入、输出、baseline、builder、packager、skip、非零与稳定提升合同全部保留。

## 本轮执行：合同与真实四专项分开记账

执行接口：SDK `command_run`，`command=/data/user/0/com.dshmobile.shell/files/usr/bin/node`，`cwd=/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`，每条 `timeoutMs=60000`。无 shell、无 `process.execPath` 子进程启动，未运行 `tests/run_release_checks.mjs`。以下参数均为该 command 的单个文件参数。

| 参数 | exitCode | SDK 耗时 | 结果性质与摘要 |
| --- | ---: | ---: | --- |
| `tests/test_release_runner.mjs` | 0 | 617 ms | 内存合同：GREEN 45；故障红灯为模拟注入并验证阻断，不是实际 31 阶段成功。 |
| `tests/run_wind_visual_budget_r14.mjs` | 0 | 1179 ms | 真实 luau-web fixture：300068 assertions；createWindowCalls、scheduleCalls、getServiceExtra 均 0。内部 fixtureElapsedMs=656、wallMs=924。 |
| `tests/run_wind_viewport_edges_r14.mjs` | 0 | 987 ms | 真实 luau-web fixture：passed=7 failed=0 checks=7。 |
| `tests/run_wind_input_queue_r14.mjs` | 0 | 1033 ms | 真实 luau-web fixture：passed=7 failed=0 checked=7。 |
| `tests/run_wind_acrylic_policy_r16.mjs` | 0 | 1169 ms | 真实 luau-web fixture：passed=9 failed=0 checks=9。 |

五条命令合计 SDK 耗时 4985 ms，均无 stderr、timeout 或输出截断。四专项使用已有 luau-web fixture；不是完整 Roblox GUI 或 Android 真机渲染测试。budget 输出记录 Node v24.18.0 与运行时 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-tools/node_modules/luau-web/src/index.js`。launcher 注册仅经内存合同验证，本轮未实际通过 linker 启动完整发布流水线。

## 指纹与残余

下列 14 个文件在四专项执行前后逐一 SHA256 相等。该证据证明采样两端未漂移；专项中提取的 harness/base 片段摘要与下面整文件摘要不是同一对象。

| 文件 | SHA256 |
| --- | --- |
| `tests/run_release_checks.mjs` | `9dceb49f492714ffdd7ee4337ebdda9c8e7ea3e59b399d28df76f51d0bfb985f` |
| `tests/test_release_runner.mjs` | `f25bed22b5675b6d2c8af5e0bba034d3f1901aa1cd7cefdf9fad11fa0a30dcc4` |
| `src/WindAdapter.luau` | `698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981` |
| `vendor/WindUI/Source.lua` | `e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05` |
| `tests/test_wind_adapter.luau` | `b054b6395b63c2db3d36976db4c6aee0b7e6720e43e82f684b032ee35e9d64c8` |
| `tests/wind_native_harness.luau` | `09d86aa6a3820f6e53167e79a1d429ad16d918c258cf3c0f82619270403443c5` |
| `tests/run_wind_visual_budget_r14.mjs` | `569a97eb5202e6f5ee3b7074d86be7ae8dd74a80d681ac96a6fda22c32769fa0` |
| `tests/test_wind_visual_budget_r14.luau` | `a729384fbab7b3b6965f0d715e330f0cca988534cf8a23d3bfc746404a290cf3` |
| `tests/run_wind_viewport_edges_r14.mjs` | `8e94bbc08d1ecb607b767feaa7e3c9eb12c1327f9bfecb4e2d3888ac1937f1ab` |
| `tests/test_wind_viewport_edges_r14.luau` | `6c74758abd50d96713ed75a89265f85d425c6b661b76bb9d9affd5a3011549c0` |
| `tests/run_wind_input_queue_r14.mjs` | `2d99660bd8b98972424269fde21fbc51f5c6c5785b247fc4fb509e1828e52179` |
| `tests/test_wind_input_queue_r14.luau` | `af36154394ac60d563474e9cfad41f49f03aacb3c02d032ccf3c10707132cf07` |
| `tests/run_wind_acrylic_policy_r16.mjs` | `c6120d65bd84f94fdb5d6350df9fae1b9f834fbedb4cde7325c0d58e3dda0db2` |
| `tests/test_wind_acrylic_policy_r16.luau` | `3ce0787012a0a25f03df244a47de533dc30ab2e5b023aefeeca7073c31808def` |

viewport assembled SHA256=`0ba2fe104aa4349437e3fbed9417190cc344e811691f5839bbbdfaff891d1d15`；acrylic assembled SHA256=`e8d9422b3ba7a784457a12bfbeb969fb9ee02860d0059ea537953cd5aa6ae383`。

探查点：原 27 阶段是否保留、四阶段是否重复/漏接、非零与 skip 是否误提升、测试文件漂移是否漏检、Node 与 Luau 是否统一 launcher 包装。优化：精确清单双模式校验、逐项故障与漂移注入、保留桌面默认及三类稳定性门禁。

31 阶段完整发布结果尚未产生；本轮不提升 dist 的 compiler evidence，不更新 release JSON。Roblox Android/PC、真实游戏协议、完整 vendor GUI 均未据此宣称通过。
