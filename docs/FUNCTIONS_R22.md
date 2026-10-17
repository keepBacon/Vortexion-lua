# R22 本地展示与移动适配

## 本批结果

复用5个既有 stepfun-plan/step-5-preview（low）会话，各自只改一份独占源码；父处理共享桥接、复杂修正、集成和验收。沿用独立实现，不运行参考加载器，不复制参考实现，不新增资源ID或玩法协议。首个一小时窗口已结束；本批不是全部目标完成声明。

- WindAdapter：新增「完整显示优先适配」「文字可读性优先适配」。复用既有设置事务，顺序设置可读性保护、四边GUI边距、自动适配；保留用户最小缩放、尺寸、主题、背景、Acrylic与刷新档位。默认策略及原两项推荐不变。完整显示优先仍受0.1缩放底限与40像素可用区底限约束，极小视口仍有局限；文字优先可能裁切。
- Forsaken：皮肤选择白名单绑定角色身份，旧角色列表不再应用到新角色。失败/空目录清白名单并显示占位；读取完成后先复核生命周期。成功刷新先清旧授权，只有 SetValues 返回 true 且角色/生命周期仍有效才发布新白名单；刷新同步回调不应用未提交条目。未新增常驻扫描或监听；换角色后旧菜单文字仍可能保留至手动刷新，身份检查会挡住旧选择。
- BloxStrike：新增手套自动/T Glove/CT Glove/不附着与CT袖套开关，仅消费现有 Assets.Weapons 与 Sleeves.IDF。只回收/重建附件，不重建刀体或新增帧连接。父补输入归一、同值早返、附件销毁后再次检查当前实例。此项不是完整原始手套/动画资源迁移。
- SCP：屏外箭头大小8..30（默认14）、边距8..80（默认28），前后端有限数校验与整数限幅；小视口可用距离下限为0，避免负半径翻侧。沿用原Drawing预算、回收和距离数字，不新增目标扫描。
- AOTR大厅：新增「立即刷新全部余量」，一次强制 ProbeHUD(true) 后显示本次刀片、雷枪和燃气。失败显示未读取，扫描/通知前有生命周期检查；不新增定时器、网络调用或战斗逻辑。

## 本次实际校验

同一条父执行命令 exitCode=0，耗时5451ms，stderr为空、未超时、未截断。先冻结，再双构建、编译、迁移和旧视口专项，末尾逐项验证输入不变及manifest来源。未写入或扩张测试脚本。

1. 两次实际 python3 -B build.py 均 exit0；六包与manifest共7输出逐字节一致。
2. run_luau.mjs：34源码、6包、vendor和loader共42编译通过；这是luau-web语法编译，不提升清单中原生编译器/设备标记。
3. test_wind_migration.py：203旧ID保留、六包与34来源/输出哈希匹配、原始WindUI未修改。
4. run_wind_viewport_edges_r14.mjs：7场景/7检查、failed=0，验证旧四边inset、旋转、相机替换、冻结和可读性溢出契约。装配93853字节，SHA-256 c5ec3cca81237a18903b55f9027b68c8879eca5a44977b431e0ad853282b7f5f。该夹具没有实际点击本批两个新按钮，也不验证其他新业务。

冻结86输入（34 manifest来源、50 tests根脚本/ID基线、build.py及packager），排序紧凑UTF-8 [path,sha256]摘要为 `4263798e2957a4dc5c41e7a1f99c2e3799685117dbe56ee06f2130fb79c9d9dd`，执行前后不变。排除本批6源码的80项保护摘要 `76a9690a47a112de9d7a61a1e9500ddf2c6d8572c775fdda965b6579d031f661`；另排除初次漏计的 tests/option_ids_baseline.json 后79项摘要与动手前 `91cfbabdfab4808c11588afd30f5ef88d1418411ad5164bb3b4575673f209e81` 精确相同。其余28来源、全部测试、构建器及packager保持不变。

## 冻结源码与输出

相对本工程根目录，SHA-256：

| 路径 | 字节 | SHA-256 |
| --- | ---: | --- |
| src/WindAdapter.luau | 57776 | 2d9ae79e9a4275749dc97baf26de4b6171df9af49f4ca806f05b27615f92b193 |
| src/ForsakenVisual.luau | 24225 | 22af25565714f8f23ca172d017ff039addbbb13ff997c9d2e386e61bb2f550fa |
| src/BloxStrikeCosmetic.luau | 25850 | dcdaa6c4309d52c2f80196004ac426a53e5efc909886f82b324c9fd5d5c59470 |
| src/SCPESP.luau | 25882 | 7a21fc00f8887f8d939e7b68b9b04faffead38870fe9901f6409e35b22e1ac12 |
| src/SCPCore.luau | 31439 | e84d8f11b922bfc3ea7f888225ad605653af667cd6dc93c19f26721c5560ab38 |
| src/AOTRLobby.luau | 6684 | 87ad2e8c82226ebcd8b0783ac3ce24a1ef902d662343a517176bf21cbab218f9 |
| dist/Vortexion_AOTR_Battle.lua | 1534232 | f02529721d893bcf3fea74ecc24e9f6ce09b23385bd287beea1cfc12e62a889e |
| dist/Vortexion_AOTR_Lobby.lua | 1463103 | 6b93acff51ac1873fb64abd04e2b081929d384b2e8ad7c5bbe3cfac39c30ab88 |
| dist/Vortexion_BloxStrike.lua | 1579256 | 3f8109ae9006861bd6eb18de1debd8047c32b5699880bfd88805e85aa032825b |
| dist/Vortexion_Forsaken.lua | 1645245 | a99af31539bf1813104ad7ebd7c4db0a61f907a7d7ed7d06c76080faf845fea2 |
| dist/Vortexion_SCP.lua | 1563145 | 2f698492c6f099c75053e9a6a0d564ba8480c31777fd3e868c4a4b79d078ed78 |
| dist/Vortexion_Wind.lua | 2029105 | 750feaddc9fff1a3f9c481af65630db899f1d125238a800f25acb6797d0a0b63 |
| dist/build-manifest.json | 5047 | b4dd896fdfbd6cf4829fa7d080f4ca2773e97acf2479457b4c4a3c81458fb43f |

## 质询点与边界

重点审查了刷新返回false但pcall成功、刷新回调重入、换角色晚结果、重复设置附件重建及超小视口负半径；上述实现已调整。旧203ID、自动路由与通用/游戏/UI结构保留，通用仍仅低延迟切服。

本批新业务尚未执行Luau专项，也未执行完整34阶段发布门禁；旧R19/R20数字不作新业务验收。真实触屏/渲染/FPS/引擎调度尚未验证。Auto-Trick/角色技能重做和原始完整动画音效资源差异仍未补齐。goal保持active，未发布GitHub，历史发布JSON/ZIP和外部历史包不变，manifest的luau_compiler_tested与roblox_android_tested仍为false。
