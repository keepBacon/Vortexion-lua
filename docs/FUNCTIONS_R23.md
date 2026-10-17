# R23 本地动画资源与生命周期

## 实际落地

本轮集中两份源码，复用两个既有 stepfun-plan/step-5-preview（low）会话提供非阻塞资源定位和速度/循环控件；父完成原生轨道接入、生命周期事务、百分比换算、专项和构建。独立实现，仅只读参考资源路径；不运行参考加载器，不新增资源ID。首个一小时窗口已结束，整体目标仍未完成。

- BloxStrike：读取既有 `Assets/WeaponAnimations/<刀具>/CameraAnimations` 下的 Equip、Idle、Inspect、Heavy Swing、Swing1、Swing2，仅使用本地克隆中已有的 Animator。新增重挥按钮，普通挥动交替两种动作；正常结束尝试循环 Idle，非Idle轨道最长30秒。缺Animator/资源、加载或播放失败走既有程序姿态，不等待资源，不修改服务器伤害或库存。
- 原生动画活动时只保留刀模基础偏移，避免与程序运动叠加。Motor6D.Transform与本地关节子部件Anchored按轨道保存/归还，不动资源模板。停止、关闭、换相机、卸载及Load/Play期间的迟到结果都有回收栅栏；没有增加常驻帧连接或每帧资源搜索。
- Forsaken Guest：动画速度25..200%，默认100%，传给Play前除以100；循环默认关闭，只影响下一次播放。假格挡复用同一播放函数，也应用这两项。临时Animation、候选Track、Stopped订阅、活动Track分层持有；Load/Connect/Play异常、同步Stopped、停止、换角色和销毁都按身份与请求版本回收。仅成功播放消耗0.35秒节流。弱键回收标记在Stop前写入，避免Play内同步Stopped导致同一轨道重复Stop/Destroy。

参考证据：`reference-inputs/bloxstrike/bloxstrike-main (3)/BloxStrike-main/Source/script.lua:239-249`。这里只确认资源路径与六种名称；不代表资源在所有地图/版本存在或真机动画已经验证。

## 必要验证与边界

- 双次实际 `python3 -B build.py`，六包与manifest共7输出逐字节一致；最终父命令exit0，6273ms，无超时/截断（含42编译、203ID、视口与R19回归）。
- `tests/run_luau.mjs`：34源码、6包、vendor、loader共42次luau-web编译通过；`tests/test_wind_migration.py`：203旧ID及全部来源/输出哈希通过，WindUI vendor保持原哈希。
- `tests/run_wind_viewport_edges_r14.mjs`：7场景/7检查/0失败，仅证明旧共享视口契约，不等同本轮动画/设备验证。
- 原生动画专项：`tests/run_animation_r23.mjs --suite=native`，真实Common/Cosmetic工厂，65检查通过；速度换算与停止后迟到Load两项内存变异负对照均到达指定业务断言。没有把编译/驱动错误当负对照通过。
- `tests/run_local_features_r19.mjs`：25场景/128检查/0失败。仅给旧帧抽取夹具增加 `updateNative` / `tryNative` 两个依赖stub，生产帧路径由原生动画专项另外覆盖；100000闲置帧仍零扫描/零声音回收/零相机读取。
- Guest专项：真实工厂285条断言通过（含控件注册与逐轨道清理，不是285个独立玩法场景），覆盖默认/边界速度、loop、各阶段异常、同步Stopped、Load期间停止/换角色/销毁、旧Track保留、FakeBlock及所有轨道恰好销毁一次/订阅断开。修正子片段的占位注释、门禁时间与跨工厂清理后父执行；未复制产品算法。
- 最终两套健康路径与五项负对照合并父命令exit0、5162ms：native-speed/native-epoch、guest-speed/guest-epoch/guest-disposal均到达指定业务断言；编译及装配错误不计为负对照通过。Guest装配37982字节，SHA-256 `5e1ef8de7b71d1c258df8a8736705b8ae65fb1379ff52449d6363b4bdf63adc3`；原生装配60292字节，SHA-256 `1fd93e90868aabbe677b1e2789a5a02c6bc2e82c66a5d2af942f3301c65d63e0`。

旧套件的失败保留：BloxStrike旧声音夹具只模拟Ended.Once，而当前实现订阅Connect，断言 `sound reclaimed on Ended` 失败；父将R22归档原Cosmetic源码在内存注入同一runner，复现同一失败，归档源码SHA-256为 `dcdaa6c4309d52c2f80196004ac426a53e5efc909886f82b324c9fd5d5c59470`。旧Forsaken Visual报 `scale applied: expected 1.06, got nil`；Visual源码本轮未修改，旧夹具仍用Humanoid标尺而当前使用Model尺度。两个旧runner都exit1，未宣称通过，也未为其改回产品行为。

完整34阶段门禁尚未执行；本轮新增专项尚未接入门禁，历史 `tests/release-test-results.json` 原样保留，不代表当前版本通过。实际Roblox/安卓触屏、渲染、资源兼容、原生编译器验收与性能测量仍待进行，manifest设备/原生编译器标记保持false。

## 冻结与保护输入

从R22归档重建原86项冻结集合（34来源、50个tests根级mjs/py/luau及ID基线、build.py与packager；包含隐藏Luau，不包含tests/test_server_switch.lua），紧凑排序[path,sha256]摘要精确复现 `4263798e2957a4dc5c41e7a1f99c2e3799685117dbe56ee06f2130fb79c9d9dd`。仅排本轮两源码与R19帧夹具的83项逐文件与归档相同，摘要 `8d09125622dc7436882c8e65e92076b43cc293dbdd1d579f3d9c3d563b11ee60`。新的R23测试/文档另计，不把夹具更新说成全部tests未改。历史发布结果SHA-256仍为 `e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be`。

## 源码与构建快照

| 路径 | 字节 | SHA-256 |
| --- | ---: | --- |
| src/BloxStrikeCosmetic.luau | 32160 | 1a6a2e9d71e47d2fcd1fcf7eab7803962f5355da34f4d3e4cd380b224ad18506 |
| src/ForsakenGuest.luau | 10177 | 997269b6668d4de494cee90f6ddfb07f863702191ff11ef306b3b9534e704c8f |
| dist/Vortexion_Wind.lua | 2037924 | fb562d59ce00dc18b5c4fdb18c070f84e4bbe1291435303e94d130b0be943aac |
| dist/Vortexion_Forsaken.lua | 1647754 | 1aa80e430d40c795ff8cece64d2e8312c2ccf342d9807e5d942665c7a8d584b6 |
| dist/Vortexion_BloxStrike.lua | 1585566 | d7ac9a10faf3ad824b0193218781ab0997c534788285b3549aa3a1277fa87e5d |
| dist/Vortexion_AOTR_Lobby.lua | 1463103 | 6b93acff51ac1873fb64abd04e2b081929d384b2e8ad7c5bbe3cfac39c30ab88 |
| dist/Vortexion_AOTR_Battle.lua | 1534232 | f02529721d893bcf3fea74ecc24e9f6ce09b23385bd287beea1cfc12e62a889e |
| dist/Vortexion_SCP.lua | 1563145 | 2f698492c6f099c75053e9a6a0d564ba8480c31777fd3e868c4a4b79d078ed78 |
| dist/build-manifest.json | 5047 | 01944814e939d5406166761c02204bc9135f78ecccde1cad0bfcb8fba8480610 |

本地交付为 `Vortexion_WindUI_local_R23.zip`，沿用R22的135个磁盘成员并加入本轮4个新文件；另含归档生成的 `wind-project/ARCHIVE_STATUS.json`，与旧测试结果明确区分。归档只标记本地构建/定向模拟检查，保留历史R22压缩包，不充当完整门禁发布。

未完成差异仍包括Forsaken Auto-Trick、完整角色技能重做、完整原始资源集及其余参考覆盖。原有203ID、自动路由、Common/Game/UI折叠分组、vendor、原始参考与历史归档保持；不得把本地动画消费等同全部参考迁移完成。
