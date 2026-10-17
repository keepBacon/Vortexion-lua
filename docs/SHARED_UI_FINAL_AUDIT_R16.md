# 共享 UI 最终离线验收（r16，部分交付）

## 范围与修复

本快照记录普通 Wind 共享 UI 的既有冻结验收：复用既有子代，父会话负责审计与独立验收。形成快照时总目标为 revision 17、paused/disarmed，游戏功能、六包构建、dist、发布门禁及整包交付未恢复。后续第 16/256 续轮已为 revision 18、active/armed，并补共享专项门禁接入，详见 `docs/RELEASE_GATE_PARENT_AUDIT_R16.md`；整体目标仍未完成。外部暂停包 `/storage/emulated/0/Download/work/Vortexion-lua-main.zip` 未更新。

`src/WindAdapter.luau` 保留构造参数 `Acrylic=true`，用每桥独立偏好过滤 vendor Open 的强制开启；过滤同时检查 self、窗口槽与 Active。真实 Close 的模型状态不覆盖保存偏好。销毁仅归还自己仍持有的方法，保留捕获原函数以供外部委托继续透传；旁窗占槽不受旧桥偏好限制。TopbarInset 监听与窗口发布的取消栅栏、安全区受控 Tween、输入合并、纯计算视觉间隔均由现有共享回归覆盖。监听在 CreateWindow 尾尝试安装一次（src/WindAdapter.luau:96-123、:813），不以 SafeArea/AutoFit 开启为安装条件；事件只受 Active/SafeArea/AutoFit 门控（:110-113）。全屏事件仍可排队，但 FitViewport 早退取消 owned 尾、不写新布局（:636-640）；已纠正共享文档中安装门控和全屏不排队的过强描述。vendor 原件哈希保持一致。

## 父会话冻结复跑

执行目录：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。Node：`/data/user/0/com.dshmobile.shell/files/usr/bin/node`。下表命令均从该目录执行，均 exit 0；前后核对下节 15 个输入的 SHA-256 与字节数完全相同。

| 命令 | 结果 |
| --- | --- |
| `node tests/run_luau.mjs src/WindAdapter.luau` | 编译通过 |
| `node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau` | 工厂回归通过；fixture callback failure 是预期错误注入 |
| `node tests/run_wind_native_contracts.mjs` | 124 通过，0 失败 |
| `node tests/run_wind_visual_budget_r14.mjs` | 7 阶段，300068 条断言；createWindowCalls/scheduleCalls/getServiceExtra 均 0 |
| `node tests/run_wind_viewport_edges_r14.mjs` | 7 通过，0 失败 |
| `node tests/run_wind_input_queue_r14.mjs` | 7 个健康场景通过，0 失败 |
| `node tests/run_wind_acrylic_policy_r16.mjs` | 9 个健康场景通过，0 失败 |

视觉压力为 150000 轮双调用加边界断言，不是 300068 个独立场景或手机 FPS。输入下拉的精确阶段差为 +3：批次 Refresh、vendor Select 自带 Refresh、排队 Refresh 各一次。Acrylic 重复 Open 在 prepareWindow 后取计数基线并断言 exact +3，不把构造期禁用计数当作阶段计数；手动开启后的真实 Close/Open 是健康场景，不是负对照。

连续复跑驱动首试因 Android `process.execPath` 实为 linker，报 `error: expected absolute path: "tests/run_luau.mjs"`，尚未执行测试。已改为显式 `/system/bin/linker64` 加上述 Node 绝对路径重跑，七项全绿；该驱动失败不算测试结果。

## 冻结输入清单

下列路径相对于工程根目录；字节数按磁盘原文件计算，不与切片或装配段混用。

| 路径 | UTF-8 字节数 | SHA-256 |
| --- | ---: | --- |
| `src/WindAdapter.luau` | 53298 | `698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981` |
| `vendor/WindUI/Source.lua` | 1350010 | `e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05` |
| `tests/test_wind_adapter.luau` | 22527 | `b054b6395b63c2db3d36976db4c6aee0b7e6720e43e82f684b032ee35e9d64c8` |
| `tests/run_luau.mjs` | 1789 | `af3baef03d85a57c289d0a214a99aeaf6a2ac880b051ab40b25da4fa52334f28` |
| `tests/wind_native_harness.luau` | 2654 | `09d86aa6a3820f6e53167e79a1d429ad16d918c258cf3c0f82619270403443c5` |
| `tests/test_wind_native_contracts.luau` | 118397 | `c00c2a3c211e4272c4e9d431d8c8178f4a3dc3afe0ebfabd3abda5cacd54c1b1` |
| `tests/run_wind_native_contracts.mjs` | 2620 | `9f6d8b92d825c27e06ee838cbbeb2cddd5d9a2e1df039e98e5e3ac31898e675e` |
| `tests/test_wind_visual_budget_r14.luau` | 12582 | `a729384fbab7b3b6965f0d715e330f0cca988534cf8a23d3bfc746404a290cf3` |
| `tests/run_wind_visual_budget_r14.mjs` | 2730 | `569a97eb5202e6f5ee3b7074d86be7ae8dd74a80d681ac96a6fda22c32769fa0` |
| `tests/test_wind_viewport_edges_r14.luau` | 30925 | `6c74758abd50d96713ed75a89265f85d425c6b661b76bb9d9affd5a3011549c0` |
| `tests/run_wind_viewport_edges_r14.mjs` | 4911 | `8e94bbc08d1ecb607b767feaa7e3c9eb12c1327f9bfecb4e2d3888ac1937f1ab` |
| `tests/test_wind_input_queue_r14.luau` | 18556 | `af36154394ac60d563474e9cfad41f49f03aacb3c02d032ccf3c10707132cf07` |
| `tests/run_wind_input_queue_r14.mjs` | 4634 | `2d99660bd8b98972424269fde21fbc51f5c6c5785b247fc4fb509e1828e52179` |
| `tests/test_wind_acrylic_policy_r16.luau` | 11950 | `3ce0787012a0a25f03df244a47de533dc30ab2e5b023aefeeca7073c31808def` |
| `tests/run_wind_acrylic_policy_r16.mjs` | 3823 | `c6120d65bd84f94fdb5d6350df9fae1b9f834fbedb4cde7325c0d58e3dda0db2` |

Acrylic 实际装配输入 SHA-256：`e8d9422b3ba7a784457a12bfbeb969fb9ee02860d0059ea537953cd5aa6ae383`。视口实际装配输入：89375 字节，`0ba2fe104aa4349437e3fbed9417190cc344e811691f5839bbbdfaff891d1d15`。输入报告中的 harness 013df.../7191B 为装配段；磁盘原文件为表内 09d86.../2654B。

## 负对照、审计点与余项

父以同一冻结 Acrylic runner 做四次顺序内存执行：先正对照 9/0，再只改变生产源码的一个承重点。每次必须出现预期计数及具体断言失败、进程 exit 1，单纯编译/驱动异常不算捕获；六个核心输入前后哈希相同，未向磁盘写变异。

| 内存变异 | 预期红项 | 变异源码 SHA-256 |
| --- | --- | --- |
| 删除偏好过滤 if | 5 通过/4 失败；touch off-preference must not enable blur on real Open | `18a62a81223ba2ba17f6c47f9bc8cba4a93cdc2cce360a71ae2b94a4da0ef8e7` |
| 删除 cleanup 中 acrylicForward 保留行 | 8/1；external delegate must still reach the vendor model after destroy | `86492fe6bfe7ee801e326ff87be9d931b22e2f184cf03aad20ad5bc2ecd4cddf` |
| 将构造参数 Acrylic=true 置 false | 1/8；initial acrylic allocation must stay enabled | `7c266075f3905debd24f0d01c31724068745834f4ddf378fbea0f238ca84602e` |

父另独立删除 changed() 的 `option.Pending = nil`：输入套件 6/1，唯一 R6 提示 `a newer native input must clear the parked write, got 0.8`；变异源码 `551ebdee5933b473cb32151247d01158e48e1f621d087a460af3984c9f11fb40`，生产字节未改。视觉预算及视口装配守卫的专项证据分别见 `docs/VISUAL_BUDGET_R14.md`、`docs/VIEWPORT_EDGES_R14.md`；监听审查见 `docs/REVIEW_TOPBAR_SIGNAL_R14.md`。

审计点已收敛：开窗与用户偏好解耦、销毁后的捕获委托、初始分配、阶段计数基线、输入 supersede、哈希与编译输入一致性。优化是修复生命周期所有权并补承重正负回归，而非增加无效重复测试。

未验证真实 AcrylicPaint/Au 模糊、Tween 时长、TopbarInset 引擎信号时序、硬件安全边缘、键盘、拖窗/滚动争用或帧率；模型与模糊是仪器化对象和计数器。r16 原样提取完整 Open/Close/Toggle 逻辑，但不执行完整 vendor 构造、真实多窗口或资源渲染；初始分配只验证传入配置，旁窗是夹具槽替换。r16 runner 的基础 cut 与三处 harness 替换未具有视口 runner 同等全量装配哨兵。本冻结快照形成时新套件尚未接入 27 阶段发布门禁；后续第 16 续轮已接入四套，发布器扩为 31 阶段并验证 45 套内存合同。原 203 ID 与六包一致性门禁仍待真实完整发布验收，详见 `docs/RELEASE_GATE_PARENT_AUDIT_R16.md`。旧 dist、JSON 验收快照及 r8 历史结果不是当前源码发布证据。普通 UI 离线回归闭环不等于总体目标完成；余项见 `后续任务.md` 和 `docs/WIND_ANDROID_QA.md`。
