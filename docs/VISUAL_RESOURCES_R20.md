# R20：展示功能与资源生命周期交付

## 已完成代码

- SCP新增4个游戏页控件：字号10..28、原生字体4选1、文字描边、原生背景透明度；默认14/GothamBold/开启/全透明，保留既有视觉。字号与描边同时消费于Drawing和原生标签，字体与背景只作用于原生标签。既有标签实时差异更新，稳定样式不重建、不重复写样式；字号改变同时调整标签高度。
- SCP原生GUI脱离、子标签被单独改父节点、GUI父节点更换或读异常时独立回收并事务重建；文本与颜色都写成功才提交文本缓存，样式写失败下次重试。Drawing/Highlight初始化失败回滚，单项回收异常不阻断其他owned对象。销毁栅栏阻止晚到帧与玩家/角色事件重新订阅。
- Forsaken标记与helper半分配回滚；新建helper启动回收器，失去Parent/读取失败/到期均清引用后独立销毁。同名外部helper不被登记或销毁。NaN/无穷时长降级2秒；查找与类型读取异常不进入分配。
- BloxStrike声音统一实例/订阅所有权：停止、Ended、五秒超时共用幂等回收，先清记录再断开订阅并销毁；同步Ended、晚到回调、播放或订阅失败均被覆盖。模板读取异常不创建clone，R19闲置早退与动画/资产逻辑保持。
- AOTR渲染记录保存barBack并验证整棵已提交UI关系；子节点单独脱离或读异常后重建，销毁逐一回收各owned节点，避免只销毁根而遗留被改父节点的孩子。

父线程完成主要代码、样式/缓存合同、严格夹具与集成。恢复后5个stepfun-plan/step-5-preview精简子代理仅处理两处读取保护、销毁栅栏、门禁接线和两项负对照；没有复制参考实现。

## 实际验证

新专项25场景81检查通过，执行装配SHA-256 `69cd57a0a21a4cefd9d9d3314d74a209ec87e09c1d29b50f59e5157e891b29bb`（73674 UTF-8字节）；驱动读取5源码和夹具各一次Buffer，同时计算来源哈希并装配原样片段/两个完整工厂。每个标记与锚点唯一，源码替换用回调，编译/驱动错误不算业务负对照成功。

11组单变量、仅内存负对照全部命中指定场景和业务断言：drawing、gui、child、cache、style、helper、sound、aotr、dispose、chams、owned-child。七项专项输入在12次运行前后不变，按驱动输入顺序加driver的[path,sha]摘要为 `b1683a0db61495835a2616b53e8a50bcf3e07f06efcf204867870637ff721427`。首次健康预跑在子代理读取保护尚未交回时于helper查找断言红，未计为成功；最终冻结后全绿。

既有回归通过：共享工厂、原生124/0、视觉预算300068断言（3类额外调用均0）、视口7/0、输入7/0、Acrylic9/0、R18 HUD、R19的25/128、AOTR渲染54检查及大厅HUD/相机。42份源/包编译、203旧ID迁移和14项纯mock路由通过；WIND_ROUTER_LUAU_WEB=0。原路由、通用仅切服、可折叠通用/游戏/UI分组不变。均非真实游戏/手机渲染或FPS结论。

发布执行器33→34，仅在R19后增加visual-resources-r20，原顺序/参数/launcher与三个稳定门保留；69套VM门禁合同通过。真实完整34阶段未执行，未提升发布证据标记。

## 冻结与构建

77项未改输入摘要 `081bb52c3253f070544037e262790c4b04c36f770b3a41840f61b2eebd478e48` 保持；最终86输入为34个manifest消费来源、50个tests根脚本/ID基线、build.py及packager。排序紧凑UTF-8[path,sha]摘要 `fb012b453a11b50e10cd4a2e39760ec448be2ad2277f1a809c1df91d0b198693` 在专项后、双构建与最终检查前后不变。实际python3 -B build.py连续两次exit0（374/220ms），七输出原始字节一致，34来源漂移0。

| dist文件 | 字节 | SHA-256 |
| --- | --- | --- |
| Vortexion_AOTR_Battle.lua | 1531050 | b37107cac0eea869a8ddd5526d3174662c7b34742c638515181447a405a33a95 |
| Vortexion_AOTR_Lobby.lua | 1459318 | 4ff79e817ba46489d1286c23a2d4827bf96c9103e7cc5aec8a9603a2cbeabedc |
| Vortexion_BloxStrike.lua | 1575813 | 926e62ff725f016d1efa0b0aa9089d9324c4005760f88c6c51b951a0f0c822fd |
| Vortexion_Forsaken.lua | 1641172 | 650a2a8b0d68ad98816a1931ecfdc852ee71bce84c73d713f18cc938087f3f90 |
| Vortexion_SCP.lua | 1557254 | 16db429f20a6cfb244b44661a1b0073ac09acdc77d2a388dfdb7a6a5f58a8610 |
| Vortexion_Wind.lua | 2012255 | 4be4a4af15c2d0b755b82e86f75a06209ee2a67638ba9e3dd70cda357e67ff79 |
| build-manifest.json | 5047 | 1ec03aeb9699ddc46293d1db379d3127cfdd508720f6013acafa4f848811a901 |

主入口为dist/Vortexion_Wind.lua。vendor、原始参考、旧ZIP、历史release-test-results.json保持；旧JSON SHA-256仍 `e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be`。manifest保持luau_compiler_tested=false、roblox_android_tested=false、local_build_unpublished与not_published_to_github；单独编译结果不代替完整门禁提升。

## 未完成与核查点

整体目标仍active，不能把本批等同全功能完成。剩余包括Forsaken其他参考角色/Auto-Trick差异、BloxStrike完整原始资源主题与动画集、尚未核实的额外HUD路径，以及真机小屏/键盘/触控/帧耗时验证。旧SCP历史28/2没有重跑，现有目标过滤/几何的全部组合不由新资源专项代验。

核查点为分配提交顺序、原生父/子身份、缓存写成功才提交、异步连接所有权、卸载最终性和严格字段/API；优化是异常局部化、独立回收及样式差异写，不宣称实际手机FPS提升。
