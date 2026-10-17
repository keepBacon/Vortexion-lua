# R18：普通HUD门禁与离线构建证据

## 结果、所有权与验收边界

阶段A仅修改 wind-project/tests/run_release_checks.mjs 与 wind-project/tests/test_release_runner.mjs。HUD普通界面合同 aotr-hud-contract-r18 通过 addNode 注册恰好一次，命令为 node tests/run_aotr_hud_contract_r18.mjs，置于 wind-acrylic-policy-r16 后；31→32，原31阶段相对顺序及参数保留。Node默认仍为 process.env.NODE_BINARY || process.execPath，NODE_LAUNCHER包装、testsStable/inputsStable/outputsStable三栅栏均保持原样。

VM自测由45→53套。完整独立清单校验direct/launcher两模式的32项name/command/args及cwd/env；新增HUD非零exit9、SkipTest即停并禁止promotion，以及runner.mjs/body.luau在对应阶段内漂移：即使32阶段模拟全过，testsStable=false也禁止写编译提升。所有文件及spawn均由VM内存mock，不执行真实release流水线，不写实际历史JSON。阶段A实际53/53 PASS；阶段B再次53/53 PASS。

阶段B只在父明确“HUD源/测试已冻结”且最终driver=f76480...校准后执行。写入原六dist与manifest，再新建本报告；src/vendor/build.py/HUD新测试/其他既有测试或docs/历史release JSON/参考树/ZIP/父任务文档均未编辑。没有运行完整32门禁、游戏功能或协议，没有联网、归档、发布、子代或真实游戏启动。本子代没有复跑HUD23场景或其负对照，父独立执行结果不混入本命令表。42项只是实际Luau编译，不调用编译后的函数。

构建器仍保留 luau_compiler_tested=false、roblox_android_tested=false。单独42项编译与53套模拟门禁并不等于完整release32通过，因此没有提升字段。

## 冻结输入与82保护证明

原R17 manifest SHA-256为 eb0c08c1875716bc088e9ab55ad1b96647ea3ab7e42e938c46e30eb3e3e193a3。构建前实际比较其34输入：只有下面两个HUD入口源变化，另外32个消费来源（包括AOTRCommon、WindAdapter、vendor、各游戏模块）不变；新构建后34项来源漂移为0。源与新HUD测试由其他owner负责，本子代只读取其冻结内容。

| 来源 | R17 SHA-256 | R18冻结SHA-256 |
| --- | --- | --- |
| wind-project/src/AOTRLobby.luau | ce0291905c92fdf34267bc60cf6777a834916ea6cffc89b28fbe5d28ef17a2cb | cc0547e455fd558dd1a0b33eb554823d1133ddab1193cf5c41005625bd75cbca |
| wind-project/src/AOTRBattle.luau | fb828ac731bdeb4defdd5c4eda3536841f7ae070a9935ff990bb0278bee29139 | 8f829b568a435f107e9cf4e4cd9880979c1deaa6b8f0578bbcf38befc3be9bb9 |

冻结driver实际SHA-256 f76480f8c8d52770a56cde3dc698c8dcc775c4b9184ee4f7ccb71498b5c8a6aa；路径 wind-project/tests/run_aotr_hud_contract_r18.mjs。body路径 wind-project/tests/test_aotr_hud_contract_r18.luau，SHA-256 50934cd04ee8b40c4648a21d192376e1cb55ae0e00428d7e7645163a304a343e。前置先断言两源和这两测试SHA匹配冻结值，才允许build。旧c215driver/fa9保护摘要没有用于本轮构建证据；最终driver校准前本子代尚未开始任何R18构建。

82项集合为34个manifest来源 + tests根46个脚本/baseline + build.py/tools/package_release.py，set去重排序。tests仅根层regular file，suffix属于.mjs/.luau/.lua/.py或basename为wind_option_ids_baseline.json，含既有隐藏文件，不含其他历史JSON。rows=[[relative_path,SHA256],...]；json.dumps(rows,separators=(',',':'),ensure_ascii=False)无空格UTF-8后SHA-256（路径全ASCII）。

实际82摘要在双构建前、第一轮后、第二轮前后、迁移/编译/VM后终检全部为 d61f588bcc1cb730a56fb11ff9a8bc2371eb1e8d50167c6e814ecef7409ef37c；路径集合及每项原始rows也直接相等，不只是数量相等。与父最终独立82摘要一致。测试数46、消费来源34、坏包0、最终来源漂移0。

| 保持不变的文件 | SHA-256 |
| --- | --- |
| wind-project/build.py | 17a96766c184f4fb4f324c6f8de1045d39a7188b48a36f65f3bcfcd2aa06ad7a |
| wind-project/vendor/WindUI/Source.lua | e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05 |
| 历史wind-project/tests/release-test-results.json | e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be |

阶段A更新后两文件在阶段B全程不变：runner SHA 2bbb67992eea13e134f3302dedb588eff458c9e69a8096ae292766f84ee06909；selftest SHA c865d6fb875bdec90c5e8503a1b1e8673cd5b195a969d2b90615d6d0370b1d12。

## 真实双构建：每轮7输出

Python内存driver使用subprocess.run分别启动两次原解释器 -B build.py，每次cwd显式工程root。每轮返回后直接read_bytes保存六包及manifest，实际读取字节后计算下表，不复用manifest自述作唯一证据。第二轮dict中的全部7份原始bytes与第一轮完全相等。既验证了哈希/字节长度，也做了逐字节相等断言。两轮间无源码写入，82输入逐项相同。

| 输出 | 第一轮字节 | 第一轮SHA-256 | 第二轮字节 | 第二轮SHA-256 |
| --- | ---: | --- | ---: | --- |
| wind-project/dist/Vortexion_AOTR_Battle.lua | 1525253 | a7be5e1e9cdafa749b222dd902176981bf10f48c49442f6c49e8e5bda0dbd227 | 1525253 | a7be5e1e9cdafa749b222dd902176981bf10f48c49442f6c49e8e5bda0dbd227 |
| wind-project/dist/Vortexion_AOTR_Lobby.lua | 1451940 | dde6698d3d344601f700c62e06e5190cec63251aa6a5b4425bcd086474b87b7c | 1451940 | dde6698d3d344601f700c62e06e5190cec63251aa6a5b4425bcd086474b87b7c |
| wind-project/dist/Vortexion_BloxStrike.lua | 1569870 | 2f24c39f7190dd511f9e6527aad5c76ed6dcf6b0683ddb36ffa33075a81e7391 | 1569870 | 2f24c39f7190dd511f9e6527aad5c76ed6dcf6b0683ddb36ffa33075a81e7391 |
| wind-project/dist/Vortexion_Forsaken.lua | 1634842 | 861223dac1c27cb38ba2cdc7aad02153778420cb4c66327e30f527652c751eb5 | 1634842 | 861223dac1c27cb38ba2cdc7aad02153778420cb4c66327e30f527652c751eb5 |
| wind-project/dist/Vortexion_SCP.lua | 1548556 | 0cea5fb7c75497426facdda17af06b35d8c86dc574572b1405a65bf77b02b572 | 1548556 | 0cea5fb7c75497426facdda17af06b35d8c86dc574572b1405a65bf77b02b572 |
| wind-project/dist/Vortexion_Wind.lua | 1998321 | 5ce65d0a6abcac11ca785bc7c624d33905d2bf9055a56e70b4c766f7004d8010 | 1998321 | 5ce65d0a6abcac11ca785bc7c624d33905d2bf9055a56e70b4c766f7004d8010 |
| wind-project/dist/build-manifest.json | 5047 | 691946afcce759a8fa64e896c2a33a266c8230b826c58d75ba2ba09e119ea6ec | 5047 | 691946afcce759a8fa64e896c2a33a266c8230b826c58d75ba2ba09e119ea6ec |

相对R17内容实际只改变两AOTR包、统一包和manifest；BloxStrike/Forsaken/SCP仍按构建器重写但字节与R17相同。阶段A两测试接线文件之外，阶段B写范围就是此7输出加本新报告。

## 本子代实际执行表与探查点

SDK command_run的Node绝对路径为 /data/user/0/com.dshmobile.shell/files/usr/bin/node，Python为同目录python3。所有cwd=/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project，timeoutMs=60000。Node三次命令均显式env NODE_BINARY=上述Node、NODE_LAUNCHER=/system/bin/linker64；Python显式PYTHONDONTWRITEBYTECODE=1且-B。父HUD/NC/其他场景的命令与耗时没有列入下表。

| 阶段/实际命令参数 | exitCode | 毫秒 | 实际结果 |
| --- | ---: | ---: | --- |
| A：Node tests/test_release_runner.mjs | 0 | 316 | 53/53 VM合同GREEN |
| B：Python -B -c（内存双构建driver，含前后82快照及7输出验证） | 0 | 466 | 两次原build，7输出逐字节相等 |
| B/子进程第一轮：Python -B build.py | 0 | 156.744 | 6包+manifest全部生成 |
| B/子进程第二轮：Python -B build.py | 0 | 149.668 | 6包+manifest全部生成 |
| B：Python -B tests/test_wind_migration.py | 0 | 87 | 203ID、全部源/包SHA、未改vendor PASS |
| B：Node tests/run_luau.mjs | 0 | 1558 | 实际42/42 compile PASS，无execute/skip |
| B：Node tests/test_release_runner.mjs | 0 | 381 | 最终53/53 VM合同GREEN |
| B：Python -B -c（最终只读82/34源/六包/manifest/历史JSON复核） | 0 | 80 | 82摘要未变、零漂移/坏包、false字段未提升 |

SDK外层6次合计2888毫秒；两build子进程的156.744/149.668毫秒由time.monotonic_ns测量，已包含于466毫秒driver，勿重复相加。6次SDK均signal=null、timedOut=false、truncated=false、stderr为空。compile共34个活动src（排除历史StarlightAdapter）+6dist+vendor+loader=42，输出全部PASS compile，无--execute，不执行游戏入口。迁移stdout为PASS attachment option IDs 203; six Wind bundles, all source/output hashes, unmodified Wind vendor。

探查点是新HUD阶段遗漏/重复、顺序或参数退化、fail/skip和tests漂移失去承重、最终driver冻结更新、构建陈旧源与确定性。优化结果为一次接线并增加8套双模式承重合同、最终82快照后真实连续双build、独立203迁移及42编译复核。未执行完整32门禁或Roblox实机，发布与实机结论保持未验证。
