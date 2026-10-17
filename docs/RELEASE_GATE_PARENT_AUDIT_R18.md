# 第18轮发布门禁父独立验收

## 结论与边界

本报告验收门禁登记及模拟合同，不是完整发布流水线的运行记录。当前执行器共有32阶段：在原有31阶段的顺序和参数不变的前提下，仅增加一次 `aotr-hud-contract-r18`，位于 Acrylic 专项后。父独立复跑53套合同全部通过；五个仅在内存中修改执行器的负对照均触发具体断言。未执行真实32阶段流水线，未生成新发布结果JSON或集成ZIP，未提升清单编译/实机标记。

源文件核查：`tests/run_release_checks.mjs:25` 保留默认Node及可选launcher前缀；`:36` 新专项登记；`:64` 测试输入稳定检查；`:67-69` 源输入、包输出及三稳定栅栏的合并验收；`:70-73` 仅完整验收通过才提升编译证据。

## 父独立实际运行

使用 `/data/user/0/com.dshmobile.shell/files/usr/bin/node`，工作目录 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。

| 项目 | 实际结果 | 耗时 |
|---|---|---:|
| `tests/test_release_runner.mjs` | exit0；GREEN 53；stderr空，无超时/截断 | 351ms |
| 五个单变量门禁负对照 | exit0；五次均捕获 `ERR_ASSERTION` | 282ms |
| 保护输入及历史发布证据核查 | exit0；75文件摘要不变 | 172ms |

53套合同包括两种Node调用模式的完整清单精确比较，新专项非零退出/SkipTest立即中止且不提升证据，以及专项runner和Luau测试在执行过程中漂移的拦截。调用、文件读写与清单都由VM模拟，真实发布阶段没有被这些合同执行。

## 承重负对照

每次仅在内存中的执行器副本改变一项，并运行未弱化的合同断言：

| 单项改变 | 捕获的精确差异 |
|---|---|
| 删除HUD专项登记 | `31 !== 32` |
| 重复HUD专项登记 | `33 !== 32` |
| 最终验收谓词忽略 `inputsStable` | `0 !== 1` |
| 最终验收谓词忽略 `outputsStable` | `0 !== 1` |
| 最终验收谓词忽略 `testsStable` | `0 !== 1` |

稳定栅栏变更锚定完整且唯一的 `const passed = results.length === cases.length && results.every(item => item.passed) && inputsStable && outputsStable && testsStable;` 行，不修改日志表达式。最初驱动用短片段匹配 `&& outputsStable` 得到两处匹配，触发驱动自身 `2 !== 1` 后退出；那次不算完成五个负对照。修正为唯一完整谓词后全部重新运行，取得上述exit0结果。磁盘执行器和测试没有被负对照改写。

## 冻结与历史证据

| 文件/集合 | SHA-256 |
|---|---|
| `tests/run_release_checks.mjs` | `2bbb67992eea13e134f3302dedb588eff458c9e69a8096ae292766f84ee06909` |
| `tests/test_release_runner.mjs` | `c865d6fb875bdec90c5e8503a1b1e8673cd5b195a969d2b90615d6d0370b1d12` |
| 75项保护输入摘要 | `4ff8abc3c1e3733e993d85ee37591fad02a25eb7324f05439eeb1aeefe00775b` |
| `src/WindAdapter.luau` | `698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981` |
| `vendor/WindUI/Source.lua` | `e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05` |
| `tests/wind_option_ids_baseline.json` | `3da56386c1bccc88467a40a833c27c2ca169ff61a0a806993887763d93f993df` |
| 历史 `tests/release-test-results.json` | `e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be` |

保护集合来自第17轮34消费源码、44个根测试/ID基线及构建器和打包器的80项集合，排除本轮获准修改的两HUD入口、两门禁文件和旧大厅模拟器，剩75项。摘要为按路径排序的 `[path,sha256]` 数组的紧凑UTF-8 JSON SHA-256；新增两HUD测试不在旧保护集合内。本轮原始76项保护基线后来因旧大厅模拟器的调用约定纠正明确缩为75项，未把获准修改混称为字节不变。

探查点与优化：精确登记/顺序、launcher参数、失败与跳过中止、阶段中测试漂移及三稳定条件均有承重合同；本报告形成时HUD健康验收与构建尚待完成；本轮后续最终23项、4组负对照、82冻结后的双build及父当前产物复验已完成，见 `docs/AOTR_HUD_PARENT_AUDIT_R18.md`。完整32阶段、真实游戏协议、Android渲染与性能仍为未验项。
