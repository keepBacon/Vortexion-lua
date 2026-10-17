# Forsaken 参考覆盖与回归证据

当前交接以 `../后续任务.md` 顶部为准；下方早期矩阵与标记历史的章节保留当轮快照，不代表当前缺口或本次已复测；R43的新证据独立列于其专节。后续已加入 Auto-Trick、本机资源外观、Sil 动画驱动鞭影，以及 Terio / TwoTime 本地待机行走和蹲伏起手衔接。它们不等于角色完整技能重做。R34另加入可恢复的世界 Swords 粒子本机隐藏、三段参考音效与两项本地演出。R35已集成 TwoTime 精确聊天指令的本机刀饰/名称同步（SyncScript.lua:24-78，省去远程加载分支），57项断言与三个负对照通过并纳入34/34离线门禁；R40另补Terio聊天枪饰/名称/图标的本机同步，R41再补精确动画触发的2秒挥枪显形，R42补衣裤与正面脸的可恢复同步，R43补凝血动画的名义2秒延迟变脸及0.55秒条件恢复，R45补有界单次白肤与条件恢复；Sil同步、Terio头发与其余动作/音效联动、其他玩家命中特效、Sil完整技能链和1x4目标应用仍待补齐。目标名称1x1x1x1不等同于已证实NPC身份；参考所需主题/语音资产仍缺十二项。资源、动画权限与真实设备表现仍待验证。

当前R46仅修复共享移动测试夹具的错误可见性并按要求交付ZIP，Forsaken生产实现沿用R45的 `src/ForsakenGuest.luau`；固定34阶段重建六包，2026-10-17T00:22:53.409Z通过34/34，104项发布哈希独立核对一致。健康19个布局场景与两个新负对照、同步1608项及16负对照、Guest350/Sil272回归均通过；当前报告见 `tests/release-test-results.json`，使用见 `docs/R46_QUICKSTART.md`。参考文件只读；没有执行参考脚本、下载器或远程加载器。实现保留原生 Wind 战斗、视觉、生存、Guest、设置、表情、统计页，不创建第二套操作浮窗。

## R45历史：Terio一次性白肤（离线已验证）

R45在既有他人Shedletsky/精确`_sync_terio_`本机外观同步中加入一次性白肤：仅扫描角色直属子项、最多256项，将BasePart设为参考白色；复用外观事务的原值快照、身份校验、条件恢复及迟到setter补偿。保留BodyColors与原配件，不递归、不持续锁色、不增加连接或任务；这是有界缩窄，不照搬参考远端的无限循环。默认关闭、203旧ID、自动路由及通用/游戏/UI分组不变。

依据`Terio_Survivor.lua:358-364`的单次直属BasePart白色255/255/255；远端分支`Terio_Survivor.lua:1260-1269`的递归持续改色未照搬。新增146项检查覆盖身体颜色、BodyColors/配件保留、外部Color与Parent改写、关闭与身份失效、六种setter故障、真实userdata及256项边界；四个新增负对照分别撤去白色、Applied条件、Owner条件与上限，均捕获指定业务标签。旧1462项与十二负对照保留。

同步专项1608项检查及16个指定fresh-VM负对照通过，Guest350/Sil272与R44共享布局19场景回归保留；固定34阶段于2026-10-17T00:04:44.529Z通过34/34，输入/测试/输出稳定，独立复算104项哈希零差异。六包已重建，入口 `dist/Vortexion_Wind.lua` 为2154180字节，SHA256 `ba80865b4a741f8a57a8490be5d449d926aad757dea53fc8295372de8c6076e3`；证据为 `tests/release-test-results.json`。未新增ZIP，Roblox/Android与真实触控仍待实测，整体任务继续，原期限不重置。

本节R45和下方R44及更早统计为历史快照，工作区报告以上方R46说明为准；Sil、头发与音效原型继续隔离审查，不宣称完整角色覆盖。

## R44历史：共享UI边界修复，角色覆盖不变

R44修复共享WindUI布局的非有限尺寸：视口与窗口四轴统一过滤NaN及正负无穷；异常时取消自有居中Tween、清除布局缓存，不写缩放或启动动画，尺寸恢复后按当前安全区重新布局。新增十二个四轴场景，旧七场景全部保留；修复前实跑八处失败，其中四处触发无界defer重试，修复后19/19通过。不改变正常尺寸、自动路由、通用/游戏/UI分组或203旧ID。

固定34阶段于2026-10-16T23:54:17.140Z通过34/34，输入/测试/输出稳定；独立复算104项哈希零差异。六包已重建，当前入口 `dist/Vortexion_Wind.lua` 为2153732字节，SHA256 `fd8526326670b941f5f259d0735a7d05d335176a464b39a2c4a4ef8cc28846cd`；证据为 `tests/release-test-results.json`。R43同步1462项检查、十二个负对照及Guest350/Sil272回归再次通过。未新增ZIP，Roblox/Android与真实触控仍待实测；角色原型未并包，整体任务继续。

R43下方统计保留其历史快照，本段记录R44历史报告；工作区报告以顶部R45为准。此前“未确认布局缺陷”仅指当轮七场景；本轮新构造的NaN/无穷输入已有失败复现，不外推为设备自然产生这些值。

## R43历史：Terio 凝血动画的本机变脸（离线已验证）

依据`Terio_Survivor.lua:1368-1428`，在既有他人Shedletsky/精确`_sync_terio_`记录内监听动画121781457295101。延迟2秒将已同步Front脸133089396665213切为127552301758353，名义0.55秒后条件还原；0.55来自参考0.15秒等待、20×0.01秒渐显与0.2秒停留，不承诺与真实逐帧等待完全等时。共用Heartbeat在0.25秒节流前处理，不创建逐次task；跳过整个窗口的旧请求不会补闪，最新同类事件覆盖上一轮。

只处理建记录时登记、仍在原Head且Texture仍为本项目基底值的Front贴图；已有与自有缺项均支持。恢复同时检查Parent及Applied，外部Texture/父级改动保留；Animator/Head/角色/会话变化取消，关闭先恢复脉冲再恢复R42外观。写入时保留两层快照，setter关闭后迟到完成或抛错有补偿；还原setter重入关闭也补偿。没有停止/销毁原轨、音效或Highlight，未迁本机E技能，也不声称完整凝血演出。

同步专项1462项检查及十二个指定fresh-VM负对照、既有Guest350与Sil272项回归均通过；固定34阶段于2026-10-16T23:38:33.528Z通过34/34，输入/测试/输出稳定，203旧ID保留，父独立复核104项哈希一致。当前入口 `dist/Vortexion_Wind.lua` 为2153480字节，SHA256 `93dacff24fa5ab949b807ef040f66d5a39641c051b968224f326faaff7ad9191`，证据为 `tests/release-test-results.json`。六包已重建，无新ZIP；Roblox/Android未实测，整体目标仍进行。

新增检查覆盖1.999/2/2.549/2.55相邻帧、精确/错误ID、最新pending/active覆盖、整个窗口跳过、外部纹理/Parent、pending/active七类身份失效、旧Animator回调、六种写入setter故障及deadline/new-event还原setter先关闭再commit；借轨Stop/Destroy和Sound/Highlight均为零。四个新增负对照分别提前1ms、延长恢复、删除关闭脉冲恢复、删除迟到补偿，均捕获指定业务断言；旧八个也保留。R43专项由父接手落盘并执行，未采用子代未落盘草稿的错误追踪。下方R42是历史完整离线交付。Step 5 preview已核对名义时序、他人分支及R43两层快照，未确认生产缺陷；曾提出的Heartbeat漏接与旧负对照锚点冲突均经重读撤销（读取了中间态）。共享移动布局窄审也未确认缺陷，r14七场景离线通过；真实旋转/刘海/Tween与触控仍待设备验收，瞬时无效Viewport取消在飞Tween只是后续候选，不当作已复现缺陷。头发15347329623/17612852370只证实为GetObjects模型ID，未取得Handle SpecialMesh的MeshId/TextureId/Scale，不以模型ID冒充网格；三份音频实体/哈希与十二项缺失清单仍一致，其中coagulate确有他人动画触发来源，只是本轮未接。Sil聊天资源契约已查清，尚未接收`_sync_sil_`。

## R42历史：Terio 衣裤与正面脸

依据`Terio_Survivor.lua:1271-1276,1301-1304`，在既有精确`_sync_terio_`/Shedletsky同步门内加入Shirt 13132949672、Pants 13132951176、Front Decal 133089396665213。原衣裤或Front贴图保留实例及父级，按模板/纹理、Color3与Transparency逐属性记原值后改写；缺项才创建自有对象。只处理Front，不改其他面或Face属性；Head初始缺失时衣裤降级，后来出现不会自动补脸，需重新启用。捕获Head后其身份/父级变化使整组回收。

恢复仅在属性仍为Applied且Parent仍是Owner时执行，保留外部改写与移交；借用物不进入Items、不Destroy，不删除原ExpressionHolder、Sword、Chicken、配件或BodyColors，不照搬白肤无限循环。发布候选和每次写入前后重验，失败清整组；setter先触发关闭再完成/抛错的迟到写入额外补偿。释放先取出并清空Appearance，反序条件恢复；清理深度门阻断聊天回调重入。

保留所有旧检查，新增缺项/借用实例、颜色/透明度、非Front保留、外部属性/父级、身份与生命变化、创建失败、六种setter关闭/抛错及回收重入。同步专项1268项检查=checks，八个fresh-VM负对照均命中业务断言；新增三项分别撤掉Applied条件、Owner条件与迟到写入补偿，命中`Terio external shirt preserved`、`Terio handed-off shirt not rewritten`、`Terio setter interruption compensates late write close-before`。

固定34阶段于2026-10-16T23:25:59.732Z通过34/34，Guest350/Sil272回归通过，inputsStable/outputsStable/testsStable均true，203旧ID保持，父独立复核104项哈希一致。当轮`tests/release-test-results.json`及六包为R42，现工作区已由上述R45替代；当时统一入口2150609字节，SHA256 `0e3982f32e29b4a834bbc7fa34852d35746d0377c7c4cda77cc4a1f3b7c80d06`。一个Step 5 preview子代完成生产窄审、无确认功能问题；所提旧UI文案已在门禁前改正。两个新增子代分别只读检查测试与剩余外观资源。仍仅离线，Roblox/Android资产权限、真实聊天和流式角色/渲染待验；头发等余项不冒称已迁。

## R41历史：Terio 挥枪显形

依据`Terio_Survivor.lua:1368-1399`，精确动画84413781229733由当前Animator.AnimationPlayed触发：手持枪Transparency=0、背枪=1；2秒后还原为1/0。纯数字、rbxassetid及标准Roblox资产URL归一后全等比对，121781457295101不是本分支。原参考每次独立等待；这里采用最新事件覆盖单deadline，重复触发延长窗口，不监听Stopped、不Stop/Destroy借用轨道。

共用既有Heartbeat，截止每帧检查，0.25秒清理/界面/Animator重绑仍节流，不创建逐轨任务。换Animator断旧、清截止并恢复初态，保留有效枪饰；旧回调、旧epoch和迟到Connect返回均重验。Connect失败保留静态外观，同一故障Animator不逐帧重试，重开/换Animator可再绑定；缺Animator时可后续绑定。关闭、身份失效先断动画监听再销毁自有对象，不影响原衣饰。

共享同步专项由554增至684项，保留原断言；新增精确资产/无效轨、1.999与2秒相邻帧、最新窗口、换代/旧回调、活动窗口关闭、Connect返回前关闭及故障恢复、无Sound副作用。五个fresh-VM负对照包含原四项及故意将截止检查节流到0.25秒，后者命中`Terio deadline restores at exact two seconds`。固定34阶段于2026-10-16T23:15:44.745Z通过34/34，Guest350/Sil272回归通过；三项稳定标记为true、203旧ID保持。此为R41历史统计，工作区`tests/release-test-results.json`现由上述R45更新，仍仅离线验证，Roblox/Android待验。

五路只读核对已收齐：动画、生命周期、测试、真实开火拖尾入口及衣饰。衣服13132949672、裤子13132951176、脸133089396665213分别见参考1271-1276/1301-1304；两组头发15347329623/17612852370仍为GetObjects资源而非已知MeshId。此处仅登记下一步来源，未迁完整外观/变脸音效。三份本地音效实体已存在，本分支未接音效，不将它们算入十二个缺项。BloxStrike逐帧Bullet:Update不是成功开火证据，自动拖尾仍待真实信号契约。

## R40历史：Terio 本机枪饰聊天同步

复用既有默认关闭的`GuestTwoTimeChatSync`及同一聊天/Heartbeat总线，保留旧ID：`:syncScript`仍仅针对TwoTime；新增精确`_sync_terio_`仅接受其他存活Shedletsky玩家，需直属Right Arm/Torso。角色门依据`Terio_Survivor.lua:247`，比其无角色校验的远端接收分支更窄。Chatted与MessageReceived均按真实Player/UserId归属、重复去重；不发送聊天。

按`Terio_Survivor.lua:1305-1357`本机创建枪饰：MeshId 18858726703、TextureId 18858727747、Scale(1,1,1)，完整C0/C1矩阵保持参考。背枪挂Torso且透明度0；手持枪挂Right Arm且透明度1，因本轮未接动画联动而持续隐藏。名称写Terio，图标115704573151422来自参考第3行/1248-1253。玩家栏用户名用全等而非参考子串匹配；名称/图标先记原值，只有仍等于本项目写入值才恢复。

两个饰件先在角色外构建再提交，创建/挂载失败或代际失效整体回收；共用32条记录上限及0.25秒清理节拍。关闭、离场、死亡、换角色、挂点替换、会话失效与卸载移除自有物件，清理回调中的重新启用被阻断。没有删除/改写原Chicken、Sword、衣物、配件、身体颜色或缩放，因此保留原武器可能与背枪并存；完整衣饰、头发/面部、动作切枪及音效仍是缺口。

R35/R40共享专项554项检查通过，保留原57项业务断言，仅适配启用状态文案；四个fresh-VM负对照分别撤销精确命令、会话门、名称条件回滚与图标条件回滚，均命中指定业务断言。新增覆盖完整矩阵/资产与透明度、两聊天通道去重、精确用户名、候选创建/提交失败、关闭重入、角色/挂点身份和混合32记录上限。既有Guest350、Sil272项检查同时通过；固定34阶段于2026-10-16T12:19:56.737Z通过34/34，输入/测试/输出稳定，203旧ID保留，父独立复核104项哈希一致。此为R40历史统计，工作区`tests/release-test-results.json`已由上述R45更新。未改固定34清单，所有结论仍为离线验证，不代表Roblox/Android实测。

## R39历史：Sil 两项本地动作替换

Guest 页新增默认关闭的 `GuestSilAnimationEnabled` 与状态按钮，监听本机当前 Animator 的 AnimationPlayed：`93368339913846 → 140035118771958` 延迟0.45秒、1x；`119429069577280 → 128730974312965` 立即、1.65x。这是实际事件替换，不是另一个手动预览；不含参考M1分支的BodyVelocity、位移、输入、命中或服务端技能。

参考使用Humanoid动画事件、每次独立延迟回调，并先停原轨。本实现使用Animator事件，替换轨成功播放后才停止借用原轨，失败保留原动作；最近请求优先，最多一个待处理请求和一个自有轨，后到的映射事件会取消旧待处理请求，不复刻并发技能链。自有轨有15秒资源兜底，该值不是参考资产时长。

开启时单个Heartbeat，身份查询10Hz，延迟到期按帧执行。角色/Humanoid/Animator/会话代际不符、死亡、关闭、停止全部动画或卸载均回收；候选Load/Connect/Play返回后重验，Stop失败撤回新轨，借用原轨从不Destroy。Stopped同步重入、Connect返回前关闭和清理回调重新开启均有栅栏。监听Connect故障会明确显示“关闭后重试”，不承诺自动恢复。

R39当轮专项执行整份Guest工厂共272项检查；新虚拟机仅将0.45改为0，必须命中`delayed id does not replace immediately`，不是编译错误或驱动异常。既有Guest350项回归同时通过；该轮固定34阶段于2026-10-16T11:53:41.810Z通过34/34，输入/测试/输出稳定，203旧ID保留，父独立复核104项哈希一致。两项测试文件纳入冻结输入，未改34清单。工作区`tests/release-test-results.json`现已更新为上面的R44证据，并再次执行这272/350项回归；离线结果不等于Roblox/Android实测。

十二项缺失主题/语音仍无可用实体。本轮纠正了来源误判：`Sil_Raw.lua:316-327` 的旧Sound名称/ID只用于识别被替换原曲，实际替换值来自`getcustomasset("TerioThings/...")`，原曲并非缺失自定义音频的来源；没有下载原曲冒充替换文件。

## 使用与核验

在 `wind-project` 目录执行：

```sh
node tests/run_forsaken_enrichment.mjs
node tests/run_forsaken_enrichment.mjs --mutations
node tests/run_luau.mjs src/ForsakenCore.luau src/ForsakenCombat.luau src/ForsakenSurvival.luau src/ForsakenVisual.luau src/ForsakenGuest.luau
```

Android 实际使用的 Node 是 `/data/user/0/com.dshmobile.shell/files/usr/bin/node`。依赖优先取项目 `node_modules/luau-web`，缺省回退到同工作区 `../wind-tools/node_modules/luau-web`，支持 `LUAU_WEB_MODULE` 指定路径。执行器直接调用 Node，没有依赖 shell。

新瞄准功能在战斗页独立开关：最近杀手、Elliot 受伤队友、自动 Slash。Elliot 只调相机，投掷由玩家手动完成。持有模式的桌面输入是右键或 Alt；触屏使用同页的「按下 / 松开瞄准」开关保持或释放。输入框获得焦点、释放输入或窗口失焦时停止辅助。参数包括背刺距离、目标距离、受伤生命阈值、视线检查及按秒平滑速度。自动 Slash 使用参考证明存在的 QCooldown；未知冷却形态跳过动作。

Guest 页启用假格挡后按原生按钮播放 Normal 或 M3 / M4 本地动画；自定义 ID 接受纯数字或 `rbxassetid://数字`，提供停止按钮。生存页保存点只属于当前角色，返回前默认重做碰撞、地面及高度检查。视觉页的全亮、去雾、后处理关闭可组合切换；统计页新增的是客户端 FPS / 帧耗时，不替代旧玩家统计。

## 功能矩阵

「既有保留」仅说明原实现留存，不表示本轮重新验证了其全部真实服务器行为。「占位落实」表示原模块仅有旗标、通知或工具函数，本次接入了实际动作或恢复链。参考定位见下一节。

| 功能簇 | 参考证据 | 原有状态 | 本次落实与边界 | 验证 |
| --- | --- | --- | --- | --- |
| 背刺判定 / 按钮 / 冷却 | R1 | Combat 背刺循环既有 | 保留旧开关，消除 Heartbeat 内 yielding 重入；0.15 秒节流；Dagger 冷却与可调 2–25 studs | 100 同时刻帧仅一次；就绪门、关闭断线 |
| Slash | R2 | 独立原生入口缺口 | 本地 Q 按下/释放，12 studs + 已知冷却，0.4 秒动作节流；不构造新远程请求 | Q 两事件、正冷却阻挡、输入框暂停 |
| 最近杀手瞄准 | R3 | Chance 已有，不重复替换 | 新独立近身相机辅助；最近存活目标、视线检查、0.2 秒选择缓存；无位置改写 | 远目标先列仍选最近、死亡/遮挡、相机替换 |
| Elliot 支援瞄准 | R4 | 缺口 | 原创最近受伤队友选择，默认 HP < 60；不搬用参考 teleport/restore 链 | 排除自己、健康队友、死亡角色 |
| 持有 / 触屏 / 参数 | R3 | 原模块无交互模式 | 原生页控件；右键/Alt 持有、触屏保持开关，释放及失焦清理 | processed、typing、release、focus、touch 状态 |
| Chance / 命中框 / 预测 | R5 | Core 既有 | 既有实现与 `timeAhead` 段原样保留；新近身辅助不覆盖旧 Chance 参数 | Core 编译；不宣称真实游戏命中验证 |
| Guest 自动格挡 / 面向 / 预测 / Punch / Fling | R6 | Core 既有 | 保留旧专项与动画 ID；独立工具快照按 Humanoid 隔离 | 自定义快照的 0 值及跨角色隔离 |
| 假格挡 / 自定义动画 | R7、R6 | 原假格挡只有通知；自定义 Track 未管理 | 实际播放两个有证据的本地动画；节流、停止、自然结束、respawn、Destroy 回收 | 真实 LoadAnimation mock、替换 Track、加载失败重试 |
| 无限体力 | R6、R8 | 每帧重复 require / 无完整复原 | 0.2 秒更新；异步 single-flight；角色和源绑定缓存；晚返回代际门；恢复初始字段 | 100 帧一次 require；nil/新角色、0/false、迟到加载 |
| 安全点 | R9 | 只有校验工具和开关旗标 | 保存/返回原生按钮；改为空间查询，避免克隆碰撞件；绑定角色并重校验 | 碰撞、无地面、NaN、销毁高度、换角色 |
| 全亮 / 去雾 / 后处理 | R8 | Fullbright 既有 | 组合状态共用原值快照；0.5 秒复核；按 Lighting / 当前 Camera 管理后处理 | 独立开关恢复；原 false；旧/新 Camera 分别复原 |
| 临时标记 | R10 | 第一个杀手、重复连接、延迟对象未归属 | 最近存活目标；2 秒期限；单渲染连接；关闭立刻销毁对象 | 最近选择、期限、重复开关、Destroy |
| 本地 Life1 / Life2 部件隐藏 | R11 azureSkin.lua:4-15、1x4TwoTimeSkin.lua:69-81 | 缺口 | 只改本机角色 BasePart Transparency 快照并复原；0.1 秒档位节拍重应用；重生下一帧重绑，关闭/销毁同步恢复 | 部件显隐、透明快照精确恢复、重生重绑、关闭即时恢复 |
| ExtraModels 附加模型隐藏 | R11 Sil_Raw.lua:6-11 | 缺口 | 保存原 Parent 后切 nil，恢复按原父级；同上节拍与回收链 | 父级可逆、换角色、销毁无残留 |
| 本地 Highlight 透明度 | R11 1x4TwoTimeSkin.lua:72、Sil_Raw.lua:6 | 缺口 | 保存 FillTransparency，滑块 0–100% 实时生效；缺失 Highlight 时降级 | 滑块实时改写、原值恢复、缺失降级 |
| 本地皮肤应用 | R11 1x4TwoTimeSkin.lua:68 | 缺口 | `ReplicatedStorage.Assets.Skins.Survivors.<角色>.<皮肤名>` Clone，按 Attachment/部件名匹配 Weld；名空或资源缺失降级并 Notify；Clone 单一归属，关闭即毁 | 命名皮肤应用、空名降级、资源缺失降级、销毁回收 |
| 本地角色缩放 | R11 Sil_Raw.lua:6-11 | 缺口 | Humanoid:ScaleTo（缺失时降级），关闭恢复 scaleBase；不做远程角色数据改动 | ScaleTo 调用、恢复、缺失降级 |
| 视觉/ESP 节流桥接 | 性能接口约定 | 硬编码节拍 | `visualInterval`/`espThrottleInterval` 经 pcall 调 `Fluent:GetVisualInterval`，结果须 finite 正数且不小于基数；方法缺失或返回 inf/NaN/负值回退原节拍；ESP.CheckHz 外部配置 NaN/±inf 回退默认 10 并 clamp 2–20 | 桥接缺失回退、五种非有限值拒绝、max 生效；三档 5/10/60 真实 render 循环计数 49/77/80 |
| FPS / 帧耗时 | R8 更新说明 | 玩家统计已有 | 新增本地渲染样本，1 秒汇总（接入节流桥接）；共享统计页，非远程统计 loader | 60 Hz dt 得出 FPS 60，关闭清理 |
| 移动 / VoidRush / FOV | R8、R9 | Core 既有 | 保留移速/跳跃等旧 ID；VoidRush 精确快照恢复；FOV 按 Camera 快照含暂空状态 | 真 Core 片段执行；0/false / 22/true 与 FOV 70/95 |
| 玩家/道具/生成器/陷阱 ESP、警报 | R8、R9 | Core 既有 | 既有 ESP / 预测算法保持原样，不借本轮改写 | Core 编译、59 个旧 ID 保留 |
| 表情 / 玩家统计 / 生成器 / 名称保护 / LMS / 设置 | R8、R9 | Core 既有 | 八槽表情与 1 秒玩家统计是旧功能；原系统、音效及任务开关留存 | ID 基线、Core 编译；不计为新增 |
| Auto-Trick 专项能力 | R10 | 参考有专用 Veeronica 路径 | 只采用对象所有权和事件清理思想；没有冒充新增专项技能自动触发 | 清理模型测试；专项能力本身未迁移 |
| 角色皮肤 / 技能重做集 | R11 | 独立角色脚本参考 | 目录登记，未把角色脚本或其远程依赖直接并入通用模块 | 未执行，未计为已实现 |
| 社区远程工具按钮 | Core 原文 | 历史 loader 仍在 | 保留历史入口；本次所有新增实现均在源码内，没有用这些 loader 替代新增功能 | 仅编译，不运行下载器 |

### 参考定位

以下路径相对工作区根目录，而非 `docs/`：

- R1：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Auto-Backstab-V1.lua:243-287` 的 `MainUI.AbilityContainer.Dagger.CooldownTime`；V2 / V3 是路径与冷却读取的交叉参考。
- R2：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Auto-Slash.lua:237-255` 的本地 Q 输入与 NumberValue <= 0 / BoolValue 就绪。参考未知类型默认 true，本实现改为跳过。
- R3：`reference-inputs/common/Aimbot-V3-main/Aimbot-V3-main/src/Aimbot.lua:391-419` 的 hold/toggle 与输入焦点处理；同文件 `:100`、`:225-229` 的存活/墙检边界。只取设计与判定依据，不复制整个瞄准库。
- R4：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Elliot-Aimbot.lua:67-95` 的 HP < 60 队友选择；参考传送及投掷链没有搬入。
- R5：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Chance-Aimbot-V1.lua`、`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Chance-Aimbot-V2.lua`；既有 Core Chance 入口保留。
- R6：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Auto-Block-V4.lua:94-102` 的体力及 respawn 路径、`:353-397` 的动画；V1–V3 作为格挡形态参考。
- R7：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Fake-Block.lua:68-87` 的 Normal `72722244508749` / M3&4 `96959123077498`。这是动画视觉表现，不声明产生服务器格挡效果。
- R8：`reference-inputs/forsaken/Forsaken-sandbox-script-main/Forsaken-sandbox-script-main/forsaken_hub.lua:16-56` 的 `ReplicatedStorage.Systems.Character.Game.Sprinting` 字段、`:160-175` 全亮、`:245-258` 外部统计入口、`:266-324` 体力与速度、`:378-385` FPS / VoidRush 更新说明。该参考有格式异常，只读取，不执行。
- R9：`reference-inputs/forsaken/forsakenMenu-main/forsakenMenu-main/main.lua:279-306` 目标选择、`:333-350` 保存点、`:400-425` 路径/碰撞、`:430-454` panic。保存点校验采用新的空间查询，未搬用自动 reset / 追逐链。
- R10：`reference-inputs/forsaken/Forsaken-Script-main/Forsaken-Script-main/Auto-Trick.lua:39-147` 的局部高亮归属、事件清理、Veeronica 行为路径。
- R11：`reference-inputs/forsaken/Forsaken-Scripts-main/Forsaken-Scripts-main/` 下独立的 TwoTime / Terio / YiSang / Ishmael / skin / sync / status 脚本；本次只登记其存在，不作全量已迁移声明。

## 修复链与约束

证据 → 缺陷 → 修改路径：

| 证据 | 缺陷 | 修改路径 |
| --- | --- | --- |
| 原 Combat Heartbeat 回调中包含 while + task.wait | 帧事件会生成叠加的 yielding 工作体 | `src/ForsakenCombat.luau`：单次非 yielding 回调 + nextAt |
| 原 Survival 每帧 WaitForChild / require | 启停、换角色、模块等待导致重复工作或迟到状态写入 | `src/ForsakenSurvival.luau`：single-flight + source/character 缓存 + generation |
| 原 Guest 假格挡仅 notify、Animation/Track 无归属 | 功能空转；对象/Track 留存 | `src/ForsakenGuest.luau`：实际资产加载、Stopped 与 Stop/Destroy 生命周期 |
| 原 Visual 首目标 + 每帧 Lighting 写入 + 无拥有者延迟销毁 | 目标选择偏差、频繁赋值、关闭后对象残留 | `src/ForsakenVisual.luau`：最近选择 + 0.5 秒维护 + 对象到期表 |
| 原 Core Dash 退出写固定 16 / true | 覆盖角色自己的原速度与旋转状态，respawn 引用过期 | `src/ForsakenCore.luau`：当前 Humanoid 查询 + 按实例保存/复原 |
| 原 Core FOV 只有一个 oldFov | 替换相机时把旧 Camera 基线还给新 Camera | `src/ForsakenCore.luau`：按 Camera 保存并复原出场相机，含 nil Camera |
| 原 track 只 append | 反复开关保留所有已断开的连接对象 | `src/ForsakenCore.luau`：加入前移除已断开的连接；保留所有仍活动连接 |
| 原 group 返回 API 未接 Core 销毁 | 本地状态与动画/Lighting 快照在销毁或重注入时残留 | `src/ForsakenCore.luau`：保存组 API，统一幂等 cleanup；重注入先调用旧 cleanup |

原 Core 的 `local timeAhead = 0.2` 至统计创建段未作算法改动；所有原 Core 59 个、Guest 3 个字面选项 ID 保留。运行器也检查 Combat 3、Survival 2、Visual 2 个旧选项，没有修改 baseline 来掩盖遗失。新增选项数量分别为 Combat 10、Guest 1、Survival 1、Visual 4；Core 数量仍为 59。

单帧目标不重新扫描整个人员列表：选择每 0.2 秒刷新，间隔内仍复核存活及距离。视线来自选择时 Raycast，最多存在 0.2 秒遮挡缓存；不宣称每帧视线重查。安全点检测为根部包围盒和向下地面检查，不是整个角色完整碰撞体的路径导航保证。

模块缺失、服务能力缺失及未知冷却字段均跳过相应动作。旧 Core 社区 loader 与现有远程协议留存，但不在 mock 中执行；这轮没有新增远程协议，也没有加入反作弊绕过。共享 UI / build / dist 由上层集成任务负责，本文件不宣称已完成 Android 实机体验或服务器效果验收。

## 可执行验证结果

实际 Luau VM 执行五套 fixture，最后一轮退出码 0：Combat 55、Survival 31、Visual 41、Guest 30、Core lifecycle 26，共 183 个断言（包含原生选项注册、可观察行为、恢复与连接检查）。五个源码均通过真实 Luau 编译。

测试不只查字符串。`tests/run_forsaken_enrichment.mjs` 为四组完整工厂分别创建新 LuauState；Core 测试从当前源码提取 Connections、VoidRush、FOV 和 cleanup 实现，再执行 mock 的输入、帧、角色/相机替换及销毁。task.wait / task.delay 在 fixture 中会抛错，检出帧循环 yielding 或遗留延迟任务。真实 Roblox 渲染、物理与网络行为未由该模拟替代。

| 验证面 | 实际观测 |
| --- | --- |
| 原选项契约 | Core 59/59；Guest 原 3 全保留；Combat / Survival / Visual 原 ID 全保留；无重复 ID |
| Combat | 100 同时刻回调仅一次动作；死亡与墙检、持有/输入焦点、冷却、相机更换、Destroy 断线 |
| Survival | 同角色 100 帧仅一次 require；原 0/false 精确恢复；角色暂空及换人；迟到 require 无状态写入 |
| Visual | 最近而非列表第一个目标；全亮/雾独立复原；新旧相机效果恢复；标记过期/立即清理；FPS 60 |
| Guest | 两个实际参考 ID；临时 Animation 回收；旧 Track 替换/停止；错误后可重试；respawn / Destroy |
| Core | 200 次重复 Dash 开关连接桶保持有界；原速度/旋转与每个 Camera FOV 恢复；组销毁及清理幂等 |

### 突变红测

`--mutations` 只在内存改变执行源码，不改生产文件。五个故意退化版本均被行为断言检出，退出码 0 表示全部突变被捕获：

| 故意引入的退化 | 被断言观察到的差异 |
| --- | --- |
| 移除背刺 nextAt 节流 | 期望 1 次，得到 100 次 |
| 跳过体力恢复 | 期望原值 0，仍为 75 |
| 临时标记改为列表首目标 | 最近目标断言失败 |
| 动画 lastAnimAt 恢复为 0 | 初次假格挡播放失败 |
| 所有 Camera 保存成固定 70 | 期望第二相机 95，得到 70 |

随后正常源码五套再执行通过。专用输出入口为 `tests/run_forsaken_enrichment.mjs`、`tests/test_forsaken_enrichment.luau`。
