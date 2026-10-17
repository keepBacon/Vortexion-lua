# 第17轮：离线构建清单对齐证据

## 结果与范围

原 wind-project/build.py 连续实际重建两次，六包 SHA-256/字节长度逐项相同，manifest 逐行文本及 sources/bundles 完全相同。34 个消费输入的历史漂移由 7 降为 0；最终独立只读重新计算全部六包哈希和长度，无差异。只持久改变六包、wind-project/dist/build-manifest.json 与本报告；src/vendor/build.py/tests脚本/packager/既有docs/历史JSON和ZIP/参考树/父任务文档均没有编辑。

仅运行离线构建、静态迁移和 Lua 5.4 mock。没有运行真实游戏、游戏功能测试、完整31阶段门禁、packager或归档，没有发布或创建子代。luau_compiler_tested=false、roblox_android_tested=false 保留，未提升。迁移检查实际保留203个附件选项ID。mock路由测试14/14 PASS、0 skip，内部1.940秒，覆盖19组路由、五独立入口、未知/AOTR未知、唯一模块、旧桥接清理、提前退出/异常、合成loader和来源快照。实际游戏工厂/vendor/bridge/HttpGet均为mock；不发送下载请求。测试清理后 tests/wind-router-* 临时目录为0。-B避免新pycache。

## 历史漂移与六包

旧manifest SHA-256：456b7d3b3968084e4cde96ac5e52653590e03fea997db6efe3d1b53f32e76e60。以下7项漂移构建前已存在，本轮只消费现有源重建，没有修改这些源。

| 输入 | 历史 SHA-256 | 当前 SHA-256 |
| --- | --- | --- |
| wind-project/src/AOTRBattle.luau | 152f9c3194d5f58c6adc9b7c29c1a748bc5e31e1f1baa4301c3f0267e2e175cd | fb828ac731bdeb4defdd5c4eda3536841f7ae070a9935ff990bb0278bee29139 |
| wind-project/src/AOTRMovement.luau | 2e7a6e04929f4eca334f59b75af8547a7138523c0ddfb109c747d7b5c48f7837 | 4de9b57f0caf09fd6c072df12698e2a10f40b3242f25378beb9d7d64428078ec |
| wind-project/src/BloxStrikeCosmetic.luau | 1b99406450597eb4419a8d78b147a8acca43e1cba30145dfc895e79035b4362d | 66ab523ddc5e1a4732d375b5a199d0ad66397e720331c9b603eda349ea9c10de |
| wind-project/src/ForsakenCore.luau | c140da035dae3f5d071e43277a39e5e90f64bbfd58ab4e7bdd093611cb01013c | fbb08750adb05928a352941818182625b1e2a0378cd1f885c8f84268f27d698e |
| wind-project/src/ForsakenVisual.luau | 7e84998455f6ef74a1ee2956ad8fd8f5ea1efeb065a37b49095e0b6b5851ea88 | 18365666f6cb035d4e5630ab35d085cd9efa56290f1bada10f3071740c9d8271 |
| wind-project/src/SCPESP.luau | 4f3c874e1f8fe8993d3e8255fd2296033b63c4ebf2945f558d0d6d1f7f725947 | 151fd918237dc5478efee32f9c29517e9c68e8e357d9eac816c595e962d78b04 |
| wind-project/src/WindAdapter.luau | bf72c705edd2d94c1168ffd7e6b3e061072ae35de1c65c08aa225c6cc1c038d8 | 698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981 |

以下为两次实际build一致且最终重新哈希的结果：

| 输出 | 字节 | SHA-256 |
| --- | ---: | --- |
| wind-project/dist/Vortexion_AOTR_Battle.lua | 1525214 | 94deae7a7207aeab61e89c64bb08292b5af4d69ae9997a68c02ee9fa1619d82b |
| wind-project/dist/Vortexion_AOTR_Lobby.lua | 1451901 | a3c35ca9c9ccd15d1d8a16655691a981c4e0cff7672abbb2005cb97619146553 |
| wind-project/dist/Vortexion_BloxStrike.lua | 1569870 | 2f24c39f7190dd511f9e6527aad5c76ed6dcf6b0683ddb36ffa33075a81e7391 |
| wind-project/dist/Vortexion_Forsaken.lua | 1634842 | 861223dac1c27cb38ba2cdc7aad02153778420cb4c66327e30f527652c751eb5 |
| wind-project/dist/Vortexion_SCP.lua | 1548556 | 0cea5fb7c75497426facdda17af06b35d8c86dc574572b1405a65bf77b02b572 |
| wind-project/dist/Vortexion_Wind.lua | 1998243 | 8a45ebe2b983a29d3425f5b368905e9033d35dbd67729aa1256728e5ac4084fc |

wind-project/dist/build-manifest.json：5047字节，SHA-256 eb0c08c1875716bc088e9ab55ad1b96647ea3ab7e42e938c46e30eb3e3e193a3。完整34输入哈希在该清单。WindUI vendor SHA仍为 e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05；构建离线不表示运行时全部离线。

## 实际执行记录

全部为本子代SDK command_run，非父复核。command=/data/user/0/com.dshmobile.shell/files/usr/bin/python3，Python3.14.6，cwd=/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project，timeoutMs=60000。下表参数省略重复解释器路径，-c审计为内存Python字符串，没有写脚本。durationMs为SDK实测，全部signal=null/timedOut=false/truncated=false。

| 顺序 | args/实际内容 | exitCode | durationMs | 决定性结果 |
| --- | --- | ---: | ---: | --- |
| 1 | -B -c：旧manifest来源SHA/解释器/Lua发现 | 0 | 687 | 34输入、7漂移、发现liblua5.4.so.5.4 |
| 2 | -B build.py | 0 | 206 | 首次6包 |
| 3 | -B build.py | 0 | 228 | 连续第二次6包；SHA/字节一致 |
| 4 | -B -c：源/包SHA和长度、baseline数量、ctypes.CDLL加载 | 0 | 321 | 源漂移0、坏包0、203ID、Lua5.4实际加载成功 |
| 5 | -B tests/test_wind_migration.py | 0 | 123 | 203ID、六包、来源/输出哈希、原vendor PASS |
| 6 | -B tests/test_wind_router.py -v | 0 | 2208 | 14/14 PASS、0skip；详细unittest正常输出在stderr |
| 7 | -B -c：首次80file对照，误取根package_release.py | 1 | 106 | FileNotFoundError；仅只读，无文件副作用 |
| 8 | -B -c：修正tools/package_release.py但纳入tests全部根文件 | 1 | 134 | 48个tests文件共84项，计数AssertionError；源/包仍无差异 |
| 9 | -B -c：父明确44项筛选后的80file对照/源包/历史JSON | 0 | 101 | 精确80file摘要与父前置相同，源漂移0、坏包0、临时fixture0 |

9命令SDK耗时合计4114毫秒。第6命令env显式 WIND_ROUTER_LUAU_WEB=0、PYTHONDONTWRITEBYTECODE=1。迁移stdout：PASS attachment option IDs 203; six Wind bundles, all source/output hashes, unmodified Wind vendor。router stderr末行：Ran 14 tests in 1.940s / OK，没有SkipTest。

第7实际失败路径 /data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project/package_release.py 不存在。正确路径由 wind-project/tests/run_release_checks.mjs:19 定位为tools/package_release.py，只读哈希，没有执行packager。第8不是构建/测试失败：保护集合误含全部48个测试根文件，因此计数断言失败；重新使用父明确规则后第9通过。两次审计失败均如实记录，不改测试或删除文件。另首次写报告run_code触发TypeScript语法guard Expected comma, got #，写工具未执行；改用双引号字符串数组传write成功，该事件不计入command_run表。

## 保护摘要与探查点

集合：34个manifest源 + tests根仅suffix为.mjs/.luau/.lua/.py或basename=wind_option_ids_baseline.json的44个regular file + build.py + tools/package_release.py；set去重排序80项。包含既有隐藏tests/.__dbg_scp.luau，不递归，不含其他4个历史JSON。rows=[[relative_path,SHA256],...]，Python json.dumps(rows,separators=(comma,colon),ensure_ascii=False)无空格UTF-8再SHA；文件名全ASCII，与JS JSON.stringify一致。以下是父前置给定值与本子代最终实际哈希一致的结果：

| 项目 | SHA-256 |
| --- | --- |
| 80file rows | 669d4be9f943d5bf557893e698eeb6a3e49f9d4bf88bd8d8dee012580df33e40 |
| 34input rows | 1a6b35b60161fc0ccbc6d7fc169489aa2225ef5819bc12535a373034ebd32a79 |
| wind-project/build.py | 17a96766c184f4fb4f324c6f8de1045d39a7188b48a36f65f3bcfcd2aa06ad7a |
| wind-project/tests/wind_option_ids_baseline.json | 3da56386c1bccc88467a40a833c27c2ca169ff61a0a806993887763d93f993df |
| 历史wind-project/tests/release-test-results.json | e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be |

探查点：历史源清单漂移、构建决定性、Lua实可加载、mock skip真值及变更范围。优化为以当前来源快照刷新六包/清单，使用二次真实构建与最终独立哈希消除7项陈旧漂移，不动原实现与测试判定。真实Roblox Android和完整release门禁未在本轮执行；父独立compile/migration/router不混入本子代命令记录。
