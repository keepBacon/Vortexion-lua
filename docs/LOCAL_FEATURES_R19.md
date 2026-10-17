# R19 功能、移动显示与外观恢复

本批对应用户重定向后的实际代码工作；R19 是批次名，不是 goal 轮次。整体目标仍 active、revision 20、18/256，尚未全部完成。参考只作需求索引，未直接复制实现。

## 已落地

- 五个 `stepfun-plan/step-5-preview`、medium 子代理各交回一份独占小改，未另建替代代理：Forsaken 外观归还、BloxStrike 关闭状态降耗、AOTR 大厅状态复制、切服采样状态查看、触屏/桌面显示推荐。架构、复杂修复、集成与本报告由父线程完成。
- Forsaken 不再读取真实 Instance 未定义的 Destroyed 属性；逐项保护 IsA/恢复写入，按已识别类型释放快照。父线程将尺度 API 修正为 Model:GetScale/ScaleTo，同一角色只保存一次真实原值，换角色时先归还旧对象，默认关闭后恢复原值。新增 VisualCharScaleRestoreOriginal；旧 VisualCharScaleBase 保留为显式手动恢复选项。
- BloxStrike 仅在外观关闭、刀具关闭、无模型、无活动音效且动画 idle 时提前返回并清 elapsed；五类活动路径仍执行原有处理。100000 次闲置夹具帧的扫描、音效回收、相机读取均为零；不是实机 FPS 结论。
- 大厅可复制已有等级/经验、生命、FOV、刀片/雷枪及 GameId/PlaceId；缺项和读异常逐字段降级，不伪造未同步数据。剪贴板显式 false/异常走文本通知，读取后或复制后销毁不再继续后续动作。
- 切服页新增只读采样状态；保留原请求与切服状态机，停止后不读取活动状态，非有限数值不展示为 nan/inf。
- UI 新增触屏/桌面推荐按钮，只走既有七项 SetValue，auto_fit 最后，不覆盖手动最小缩放、背景、尺寸、自定义刷新率。预检缺项、排队、实际值未接受、回调异常与销毁均阻止虚报成功；私有回调异常序号也能识别重复的同一错误。

## 验证

父线程实际运行，所有命令 exit 0、无超时/输出截断：

| 检查 | 结果 |
| --- | --- |
| `node tests/run_local_features_r19.mjs` | 25 场景、128 检查、0 失败；1467ms |
| 同驱动 `--negative=restore/baseline/character/idle/clipboard/acceptance/callback`（分别运行） | 7 组单变量内存负对照全部在指定业务断言变红，驱动捕获；不修改生产文件 |
| 共享工厂、native、预算、视口、输入、Acrylic | 通过；native 124/0，预算 300068 断言，视口 7/0、输入 7/0、Acrylic 9/0 |
| 原 R18 HUD、旧大厅相机生命周期 | 通过 |
| `node tests/test_release_runner.mjs` | 61 套模拟合同通过；新阶段仅注册一次，保留原 32 阶段顺序/参数/launcher 和三项稳定性栅栏 |
| 两次 `python3 -B build.py` | 476/294ms；六包及清单共七输出原始字节完全一致 |
| `node tests/run_luau.mjs`（不加 execute） | 当前 42 文件编译通过；3356ms |
| `python3 -B tests/test_wind_migration.py` | 203 旧 ID、全部来源/输出哈希通过；160ms |
| `python3 -B tests/test_wind_router.py` | 14 项纯 mock 路由通过；3505ms |

新专项从同一次 Buffer 读取中计算来源哈希并截取原样函数；全部标记恰好一次替换、无标记残留。实际装配执行 Buffer：`d47a0aa8cab67a95e7346bb046d42377e114b6e36abdf646578324097c9b0aaa`，30041 字节。只装配普通展示/外观/帧回调；大厅整入口使用无网络的空 UI/角色模型。没有运行真实玩法、远程请求或游戏客户端。

84 个冻结输入定义：34 个 manifest 消费来源 + 48 个 tests 根目录脚本/旧ID基线 + build.py + tools/package_release.py；排序 `[path,sha256]` 紧凑 UTF-8 JSON 的 SHA-256 为 `185b5b8b47eae154ca26ad6fde0cba8d39ac1410cd7579511528c1451bf984ca`。专项和双构建前后逐项未变。构建后 sourceDrift=0；vendor、旧ID基线及历史 release-test-results.json 均保持原字节。

## 当前产物

| 文件（相对 dist/） | 字节 | SHA-256 |
| --- | ---: | --- |
| Vortexion_AOTR_Battle.lua | 1530306 | 33dbbf76d794e6c30af8e13f16b45973a5a720caeec06a0b2dad3942aa0857e5 |
| Vortexion_AOTR_Lobby.lua | 1459318 | 4ff79e817ba46489d1286c23a2d4827bf96c9103e7cc5aec8a9603a2cbeabedc |
| Vortexion_BloxStrike.lua | 1575099 | 820e6f3e53a648db704d31613ff454528e3c597ddd57240a6afaea04a982fb6a |
| Vortexion_Forsaken.lua | 1640418 | 230d49ef188cd06725878117a7e819fb59b2c2012365b9cb2bb2f0d4574b9aa5 |
| Vortexion_SCP.lua | 1553609 | a910aab8f90f8b2f82251486123ab3947734b0f5ac2511c631ba3249d1e14a27 |
| Vortexion_Wind.lua | 2006398 | 13c1efe6704aa8b418940469c0012c7deab707d4dcfc34053751b71d8db9d061 |
| build-manifest.json | 5047 | ed7fda47e263a2329d6e19b2dd0b335e00b5e5a00179e3c75de9a23712739589 |

## 尚未验收与下一差异

完整 33 阶段发布门禁没有执行；61 套 VM 合同不是 33 阶段全跑。清单 `luau_compiler_tested=false`、`roblox_android_tested=false`、`status=local_build_unpublished`、`publication=not_published_to_github` 保持原规则，单独编译不提升发布标记。未更新历史发布 JSON、整合 ZIP、外部下载 ZIP 或原始参考。

Forsaken 标签分配/引用回收、SCP 展示生命周期、BloxStrike 完整原始资产替代主题、其余参考功能和移动端实际交互/性能仍待逐项落实。本文不把旧 203 ID、局部修复或模拟通过当成全功能完成。
