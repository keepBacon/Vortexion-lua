# 第17轮构建对齐与父独立验收

## 结果与边界

当前总目标 revision 18、active/armed，第17/256轮；整体未完成。既有构建子代原样运行 build.py 连续两次，更新六个离线 bundle 与清单，34消费输入的7项历史漂移归零，两次清单和包字节一致。父只审计、复验与维护文档；src、vendor、构建器、测试脚本、历史发布 JSON/ZIP、原始参考均未改变。本轮没有游戏功能实现、真实游戏/网络请求、完整31阶段门禁或新归档。子代实跑及失败辅助审计见 docs/BUILD_RECONCILIATION_R17.md。

父独立复验当前六包，而非沿用旧包绿色结果。34个消费输入包含vendor与33个src；语法编译另外包含未被构建消费的 src/AOTRScene.luau，合计34个src、6个当前bundle、vendor与loader共42文件。编译不执行这些游戏文件。

## 父实际命令与承重验证

工作目录 /data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project；SDK command_run 实际使用 /data/user/0/com.dshmobile.shell/files/usr/bin/node 或 python3，Node v24.18.0、Python3.14.6。Python -B 且路由环境 WIND_ROUTER_LUAU_WEB=0；Lua5.4库为liblua5.4.so.5.4。所有下表命令实际exit0、未超时或截断，路由没有skip。耗时为SDK测值，不是手机FPS。

| 命令或内存实验（相对工程根） | 父结果 | 耗时 |
| --- | --- | ---: |
| node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau | 工厂回归通过；fixture callback failure为预期注入 | 871 ms |
| node tests/run_wind_native_contracts.mjs | 124/0 | 1579 ms |
| node tests/run_wind_visual_budget_r14.mjs | 7阶段/300068断言；createWindowCalls、scheduleCalls、getServiceExtra均0 | 924 ms |
| node tests/run_wind_viewport_edges_r14.mjs | 7/0 | 872 ms |
| node tests/run_wind_input_queue_r14.mjs | 7/0 | 890 ms |
| node tests/run_wind_acrylic_policy_r16.mjs | 9/0；装配SHA e8d9422b3ba7a784457a12bfbeb969fb9ee02860d0059ea537953cd5aa6ae383 | 845 ms |
| node tests/test_release_runner.mjs | GREEN 45，仅内存合同，不是31阶段实跑 | 385 ms |
| node tests/run_luau.mjs | 42文件语法编译通过，含本轮六包 | 2171 ms |
| python3 -B tests/test_wind_migration.py | 203旧ID保留、六包、34来源/输出哈希、vendor通过 | 121 ms |
| python3 -B tests/test_wind_router.py -v | 14/14，0skip，内部1.935s；19路由/5入口/错误降级与构建回滚等纯mock | 2135 ms |
| python3 -B -c 内存迁移负对照 | 原套件203ID正对照 + 三个指定AssertionError捕获 | 352 ms |
| node --input-type=module -e 原样HUD片段 | 两个普通显示缺陷成功复现，不计健康功能PASS | 757 ms |
| node --input-type=module -e 六包内容/快照核对 | 六包各含4个当前共享工厂恰一次，输入/产物冻结 | 337 ms |

迁移负对照只劫持Path.read_text/read_bytes，每轮改变一变量、不落盘。移除BloxCustomKnife字面ID捕获 src/BloxStrikeCosmetic.luau: missing option IDs ['BloxCustomKnife']；让共享源码读取多一段字节捕获 src/WindAdapter.luau；让统一包读取多一段字节捕获 Vortexion_Wind.lua。每轮恰一次命中且断言文本精确匹配；正对照先过，三个预期失败才计为承重证据，驱动异常不计。最终88文件两端哈希相同。

父此前尝试读取 docs/QA_WIND_ADAPTER.md 得not found；随后glob定位真实文件 docs/WIND_ANDROID_QA.md 并实际读取。未从不存在的文档采信结论。

## 构建与冻结证据

| 当前产物 | 字节 | SHA-256 |
| --- | ---: | --- |
| dist/Vortexion_AOTR_Battle.lua | 1525214 | 94deae7a7207aeab61e89c64bb08292b5af4d69ae9997a68c02ee9fa1619d82b |
| dist/Vortexion_AOTR_Lobby.lua | 1451901 | a3c35ca9c9ccd15d1d8a16655691a981c4e0cff7672abbb2005cb97619146553 |
| dist/Vortexion_BloxStrike.lua | 1569870 | 2f24c39f7190dd511f9e6527aad5c76ed6dcf6b0683ddb36ffa33075a81e7391 |
| dist/Vortexion_Forsaken.lua | 1634842 | 861223dac1c27cb38ba2cdc7aad02153778420cb4c66327e30f527652c751eb5 |
| dist/Vortexion_SCP.lua | 1548556 | 0cea5fb7c75497426facdda17af06b35d8c86dc574572b1405a65bf77b02b572 |
| dist/Vortexion_Wind.lua | 1998243 | 8a45ebe2b983a29d3425f5b368905e9033d35dbd67729aa1256728e5ac4084fc |
| dist/build-manifest.json | 5047 | eb0c08c1875716bc088e9ab55ad1b96647ea3ab7e42e938c46e30eb3e3e193a3 |

80个保护输入：34个manifest.sources + tests根44个脚本/ID基线 + build.py + tools/package_release.py，set去重排序；tests仅suffix .mjs/.luau/.lua/.py或wind_option_ids_baseline.json，不递归、不包含其余4个历史JSON。每项[相对路径,SHA256]的数组用JSON无空格UTF-8序列化，再取SHA256。前后摘要669d4be9f943d5bf557893e698eeb6a3e49f9d4bf88bd8d8dee012580df33e40一致；34输入摘要1a6b35b60161fc0ccbc6d7fc169489aa2225ef5819bc12535a373034ebd32a79。保护集合再加六包、manifest、历史release JSON得到88项，迁移变异两端与最后内容检查同为0e8e97bdaedf79513d212927bb8aeeb3820300fa7a81b7e5ca369fa9671ede5d。

完整34输入哈希在当前manifest；vendor保持e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05。历史tests/release-test-results.json保持e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be，它不是本轮发布证明。清单luau_compiler_tested=false、roblox_android_tested=false与未发布状态保留：父单独编译成功不会绕过真实31阶段门禁的证据提升。

## 当前缺口与最窄下一项

只读全入口矩阵见 docs/FEATURE_COVERAGE_R17.md。203旧ID仅证明旧标识存在，不证明203项语义完整；静态功能、历史mock、当前复验和设备结果分开。原始参考仅用作需求索引，未复制实现。

父从 src/AOTRCommon.luau:142-175 唯一首尾锚点截取原样HUD函数，不执行common工厂或游戏协议。使用Parent有效且Text=7 / 11的标签，dot ReadCount返回7/11，colon ReadCount返回nil；先强制探测计数1，0.5秒后dot ProbeHUD(false)仍为1，colon同参数变2。源SHA5cb3c338a6ee0dfc63ed143d8f4b902fde5c07a0d45441e524b75918ded68416；原样片段SHA7dd60fd713797b4c81b15e766bd4dab1b6f3be6158693d3452488b214c79c461，源未变。此为当前缺陷复现，不是修复验收或真实HUD路径已适配。

下一项优先仅将 src/AOTRLobby.luau:23-25 与 src/AOTRBattle.luau:191-193 的普通只读按钮统一为dot约定；同时核对 src/AOTRBattle.luau:17 初始化强制probe。保留Common点函数和 src/AOTRFarm.luau:54、src/AOTRCombat.luau:88,90,96 已正确的dot消费者，避免修显示时破坏别的路径。先补真实帮助函数/实际按钮的最小离线fixture，再改源、重新编译/回归与构建，不扩大玩法协议测试。之后复核Forsaken严格Instance属性/原始Model尺度保存恢复、SCP脱离GUI后的标签重建。当前SCP MaxDistance差异写已静态存在，旧28/2不当作本轮失败。

审计点：消费源码与当前包是否一致、缺ID/文件漂移是否真的阻断、mock是否skip、dot/colon约定与严格对象模型、可读性溢出/键盘/物理边缘、资源真实性。优化：双次真实构建、父独立当前包验收、三个指定迁移负对照、分层矩阵与原样HUD缺陷复现。完整31门禁、全部功能差异修复、Roblox/Android渲染与实际性能、最终整包交付仍待完成；目标保持active。
