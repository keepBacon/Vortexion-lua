# 功能覆盖与移动/性能差异（r17，只读审查快照）

## 范围与结论

本轮仅创建本文，不改 src/tests/vendor/build/dist、既有文档或参考文件；未运行测试、游戏、远程加载器，未联网、未探测协议。只核对普通 UI、移动输入、本地展示与资源生命周期，不实现玩法或检测规避。所有路径相对 `wind-project/`，另标原始参考根。行号是本轮读取快照；父会话后续源码/构建变动须重新定位，本文不是六包构建证明。

用户目标是根据参考独立丰富各游戏功能并补移动/性能，不是只完成共享 UI；现有玩法完整测试暂不作为完成条件，亦不应因此把功能缺口记成已完成。参考仅作为需求索引，未复制实现。当前已存在大量独立功能，真正问题集中在部分普通展示路径尚有静态契约矛盾、若干参考主题未迁移、设备证据缺失。

五入口为 Forsaken、BloxStrike、SCP、AOTR_Lobby、AOTR_Battle：`src/GameRouter.luau:3-33`。未知 AOTR 不回退战斗入口，未支持体验仅展示说明：`src/GameRouter.luau:36-54`。通用仅低延迟切服，UI 设置在 UI 分组，游戏页归游戏分组：`src/WindAdapter.luau:767-792`。不以新增杂项通用页填补游戏功能差异。

`tests/wind_option_ids_baseline.json:2-245` 经只读解析合计 203 项（AOTR 44、BloxStrike 43、Forsaken 69、SCP 47），是旧字面 ID 的基线，不是 203 项独立可用语义或全功能测试。`tests/option_ids_baseline.json:1-47` 是另一份较早的 Forsaken 基线，两者勿混用。新增按钮、动态分类及生命周期也未被这一个数量完整描述。

允许直接读取的原始参考根为 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua/work/extracted/Vortexion-lua-main`。其 `README.md:61-89` 和 `docs/ANDROID_QA.md:4-22,27-43` 给出滑块终值、滚动归属、重复下拉、弹窗恢复与十分钟性能需求；并明确历史静态结果不等于安卓实测。本轮未访问历史覆盖文档中提及的外部附件或额外 reference-inputs 目录，故那些参考细节仅是历史文档陈述，不算本轮重新核实。

## 可实施清单（按用户可见收益排序）

| 优先级 / 收益 | 当前实际路径与证据 | 状态与最窄下一步 |
| --- | --- | --- |
| P1：AOTR 余量按钮显示真实已有读数，而非一直未读取 | `src/AOTRCommon.luau:151-175` 定义 `probeHUD(force)`、`readCount(label)`，直接赋给 app；`src/AOTRLobby.luau:23-25`、`src/AOTRBattle.luau:191-193` 却用冒号调用。普通 app 无 Parent，readCount 的 label 实为 self，`:164` 早返 nil；ProbeHUD(false) 的 force 实为 self，绕过两秒缓存。 | **部分实现，当前静态缺陷**，非单纯未实测。最优下一项：只统一普通只读按钮与帮助函数的调用约定，测试有效 3/8 与 2/4、缺标签、重复点击两秒门控及销毁。不要扩大到远程战斗流程。本轮未修改或执行。 |
| P1：Forsaken 本地外观关闭/重生后可靠归还 | `src/ForsakenVisual.luau:163,181` 在内部写操作 pcall 之前读取 `object.Destroyed`；真实 Instance 不提供通用 Destroyed 属性。`:258-265` 在 Humanoid 上查/调 ScaleTo，并以用户 scaleBase 恢复；`:17` 默认基线 1，`:461` 允许手调。`:21-22` 虽有 Model:GetScale 注释和弱表，读取时实际缩放函数未消费。 | **部分实现，静态契约风险**。严格对象模型应在未知属性读取时报错；为原角色对象保存初始尺度，换角色先恢复旧对象；一项恢复失败不阻断其余回收。历史 mock 通过不足以证明引擎 API 合同。 |
| P1：SCP 标签在 GUI 脱离树后能重新出现且不泄漏 | `src/SCPESP.luau:270-287` 复用只比 Adornee，没有 Parent 有效性门；相同 Adornee 的脱离 GUI 会直接 Enabled=true 后返回。`:317-320` 已有半分配回滚。 | **部分实现**。补 GUI/TextLabel 脱离/销毁的有效性合同与事务重建。降低/提高 MaxDistance 的差异写已存在于 `src/SCPESP.luau:279-283`，勿再当未实现。历史 28/2 仅见 `后续任务.md:30`，本轮未复跑，亦不宣称现为 28/2。 |
| P1：小屏与键盘场景能抵达最后控件 | `src/WindAdapter.luau:636-648,659-721` 已做相机有效性、四边 inset、布局栅栏及受控 Tween；`:693-697` 可读性下限可主动放大超出视口。UI 默认关闭可读性和安全边距：`:479-482`。 | **已有实现 + 明确部分边界**。自动适配不是缺功能；但开启可读性保护仍不保证所有入口可达。设备验证 240×320/320×568、键盘、横竖屏/分屏、收起恢复与滚动/拖窗归属；物理刘海/系统手势区未证明。 |
| P2：BloxStrike 外观能力表述与实际资源一致 | `src/BloxStrikeCosmetic.luau:462-473` 已有触屏开关、检视/挥动/停止及程序式预览说明；声音与附件处理定位于 `src/BloxStrikeCosmetic.luau:56-127`，非全套原动画替换。 | **程序式本地预览已实现；完整原始动画集未实现/不等价**。先验资源存在/缺失、Model/BasePart、声音回收与按钮可触达，避免把整包资产替换作为既成事实。 |
| P2：SCP 标签可读性配置 | `src/SCPESP.luau:294-305` 尺寸 220×32、GothamBold、TextSize=14 固定；`docs/SCP_REFERENCE_COVERAGE.md:62-65` 明记字号/描边/背景、屏外数字/图标与快捷视角尚缺。 | **真正未实现的展示选项**，与当前已实现原生标签不同。优先字体/字号与布局预览，再考虑普通视角复位交互；不新增与业务无关的独立浮窗。不把“不另设 SCP 私有性能档”算缺陷，共享档位已承担此职责。 |
| P2：AOTR 更多只读 HUD 状态 | `src/AOTRCommon.luau:142-175` 仅 blades/spears；`docs/AOTR_REFERENCE_COVERAGE.md:24-28` 明记 gas 路径尚未确认。 | **真正未实现，但需求/路径未核实**。现有两项先修调用合同；gas 不应靠猜路径补齐。本轮未重读其额外参考。 |
| P2：参考全量语义盘点 | `docs/FORSAKEN_REFERENCE_COVERAGE.md:49-51,67` 明记 Auto-Trick 专项、角色技能集未迁移，历史 loader 仍在。 | **真实差异仍在**。本轮只登记，不扩技能/loader，不把共享 UI 回归当这些功能的实现证明。需父会话单独判断具体需求与支持范围。 |

## 五入口覆盖矩阵（静态存在 / 历史离线 / 设备分开）

下列“历史”均为已读文档原文口径，不是本轮执行，也不是当前构建验收。普通移动输入只列状态和恢复边界，不给玩法操作流程。

| 入口 / 功能簇 | 当前静态入口 | 已读历史证据 | 当前结论与待验 |
| --- | --- | --- | --- |
| 全入口：通用/游戏/UI 分组、主题、诊断、配置 | `src/WindAdapter.luau:430-499,630-633,754-792`；主题来自 GetThemes，触屏紧凑侧栏、原生恢复按钮、文件接口能力降级已有 | `docs/SHARED_UI_FINAL_AUDIT_R16.md:15-21` 原文“124 通过，0 失败”、输入“7 个健康场景通过，0 失败”、Acrylic“9 个健康场景通过，0 失败” | **已实现、历史离线有证据，设备未验**。选择/列表交错的设备行为仍待验证；父第17轮只离线构建/审计，未改共享源码；r16 结果不自动代表父后续源码。 |
| 全入口：视觉档位、可读性、安全边距 | `src/WindAdapter.luau:63`、`:457-482`、`:636-721` | `docs/SHARED_UI_FINAL_AUDIT_R16.md:18-23` 原文“7 阶段，300068 条断言”；明确 150000 轮双调用，不是 300068 个场景或 FPS | **已实现，部分边界**。档位仅间隔上限、非实测帧率；可读性溢出与硬件边缘见上表。 |
| Forsaken：本地角色显示、光照、客户端帧耗时 | `src/ForsakenVisual.luau:8-24,123-186,256-280,443-461`；Core 视觉节拍桥接 `src/ForsakenCore.luau:1222-1223` | `docs/FORSAKEN_REFERENCE_COVERAGE.md:39-45,92-94` 原文“共 183 个断言”，指五套旧 fixture；不覆盖后来全部外观语义 | **多项已实现但外观恢复/尺度仅部分**。本地缩放、未知属性、半分配/脱离回收需独立窄证据。 |
| BloxStrike：皮肤/刀具本地预览与触屏动作 | `src/BloxStrikeCosmetic.luau:450-484`；视觉独立项及节流说明 `src/BloxStrikeVisual.luau:434-440`，共享节流消费 `src/BloxStrikeCommon.luau:111-124` | `docs/BLOXSTRIKE_REFERENCE_COVERAGE.md:40-44` 原文“560 条断言通过”；含缓存重复读与 ID 校验，不是独立场景数 | **本地预览已实现/资源兼容未验，非完整动画替换**。实际按钮、声音、模型尺寸与材质效果待设备。 |
| SCP：原生标签、方向展示与触控归属 | `src/SCPCore.luau:470-471`；`src/SCPESP.luau:262-334`；触控重置与拖动 `src/SCPCommon.luau:150-158` | `docs/SCP_REFERENCE_COVERAGE.md:52-54` 原文“28 passed, 0 failed”；`后续任务.md:30` 另记后续历史红灯 28/2 | **已实现/脱离 GUI 回收部分**。MaxDistance 差异写当前静态存在；两组历史结果不互相覆盖，不替本轮证据。 |
| AOTR 大厅：信息按钮、本地 FOV 与余量显示 | `src/AOTRLobby.luau:16-33,35-65` | `docs/AOTR_REFERENCE_COVERAGE.md:32` 原文入口“12 passed/813 checks（业务模块为惰性 stub）” | **FOV/信息已有，余量按钮部分且静态有错**。stub 入口通过不证明真实 Common 的 ReadCount 调用合同正确。 |
| AOTR 战斗：只读信息、标签刷新、触控状态 | `src/AOTRBattle.luau:183-199,224-225`；视觉节流 `src/AOTRESP.luau:238-245`；触控区域/释放 `src/AOTRCommon.luau:208-254` | `docs/AOTR_REFERENCE_COVERAGE.md:32` 原文 ESP“17 个渲染套件/54 个检查”、Titan 缓存“18 个缓存套件/133 个检查”、Common“264 个检查” | **普通视觉与触控路径已存在、设备未验；余量调用部分**。保持移动/输入/回收不受视觉降频。松手保留动量是 `docs/AOTR_REFERENCE_COVERAGE.md:18` 已声明行为，是否符合用户体验待确认。 |

## 证据限制与最优下一项

旧 `docs/COMMON_REFERENCE_COVERAGE.md:17-41` 中“缺失共享间隔、未清失焦、零拖动、每帧全亮”等是历史行号和当时缺陷，当前多处已有新实现；本文未将它们机械重列为当前缺口。旧 `docs/ANDROID_QA.md:3-12` 带 Starlight/旧大小语境，Wind 当前设备清单以 `docs/WIND_ANDROID_QA.md:3-45` 为准。其“当前尚未进入 dist”也是写文时状态；父后续构建可能变化，本文不据此断言最新 dist 仍旧。

**最优下一项：先收敛 AOTR 普通 HUD 按钮调用约定。** 收益直接、静态触发链清楚、只涉及本地只读展示，可用真实 Common 加两个入口按钮的最小 fixture 验证，不要求跑游戏或补齐全部玩法。其次修 Forsaken 本地外观的严格 Instance/API 合同，再修 SCP 脱离 GUI 的重建与回收。之后补设备适配证据及真正未实现的展示选项。父第17轮仅对齐构建并审计，本轮不修改共享源码/测试。

审计询问点：严格对象模型是否覆盖未知属性、HUD helper 点/冒号约定、GUI 脱离后的所有权、原始尺度而非用户默认、物理安全区/键盘与滚动争用、动量保留是否符合预期。优化总结：把旧 ID 保留、静态实现、历史 mock、当前离线运行与真实设备结果分层；优先修可观察的普通展示合同，不用更多共享绿色计数替代全功能差异清单。
