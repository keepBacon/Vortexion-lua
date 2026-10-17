# AOTR 参考覆盖

## 证据来源

实现只采用 workspace root 下 `reference-inputs/aotr/`（相对本文档 `../../reference-inputs/aotr/`）中已观察到的行为；参考目录保持只读，远程加载器未执行。AstaRoth 证据确认了巨人/Nape 解析、`Hitboxes/Register`、`Attacks/Slash`、`Spears/S_Fire`、`Spears/S_Explode`、`Unclimbable/Reloads`、补给与 FPS 设置，以及 HUD 余量路径 `Interface.HUD.Main.Top.Blades.Sets`/`...Spears.Spears`。Zenaru 证据确认了安全的 Nape 路径解析和缓存策略，以及799-800行的 `Interface.HUD.Main.Top["7"].Gas.Percentage` 燃气路径。

## 已覆盖

| 参考能力 | 代码位置 | 说明 |
| --- | --- | --- |
| 场景与生命周期 | `src/AOTRScene.luau`, `src/AOTRCommon.luau` | 已知 PlaceId 分类、单一清理入口、模块停止回调、输入连接释放。 |
| 触摸控制 | `src/AOTRCommon.luau` | 优先使用 InputBegan/InputChanged/InputEnded；过滤 processed 输入；默认只接受视口右半触控；按触点开始次序保存所有权与起点，重复开始不重置；支持双指垂直拖动、失焦清理；Touch* 兼容路径保留 processed 标志。 |
| 巨人/Nape 感知 | `src/AOTRTitans.luau` | 安全候选遍历、Nape 缓存、Boss 优先选择；文件夹替换/移除即换绑监听；无根/无相机/范围外清失效派生字段，移出模型/死亡/停止清已持有引用；每次扫描读取当前相机，稳定帧保留 0.1s 节拍；选择逻辑保持。投影更新属于扫描缓存，不是已实测的逐帧保证。 |
| 斩击注册 | `src/AOTRCombat.luau` | 依据已确认远程面执行 Slash 与 Hitboxes/Register，保留冷却、伤害、暴击、连击和目标选择配置。 |
| 雷枪 | `src/AOTRCombat.luau` | 依据已确认参数执行 Spears/S_Fire 与 Spears/S_Explode；未探测到远程时保持空操作。 |
| 换刃与补给 | `src/AOTRFarm.luau` | 从 Unclimbable/Reloads 解析补给点，支持 Blades/Reload 与 Attacks/Reload，部件离开后重新解析。 |
| ESP 与 Nape 高亮 | `src/AOTRESP.luau` | 复用标签；名称/生命/距离独立开关、显示范围与高亮动态同步，替换 Nape 更新 Adornee；候选丢失/禁用/停止回收；GUI 与标签分配中断回滚，卸载后晚到更新不复活。非关键视觉刷新经 `app:GetVisualInterval(0.1)` 限速，共享桥接 `src/WindAdapter.luau:31-33` 已实现 `GetVisualInterval`（返回 `max(sanitize(base),1/VisualHz)`，`VisualHz` 有界 5..60）；桥接缺失/异常/越界值回退 0.1，`math.huge`/NaN/非正已清洗；标签文本、距离、血条与 Adornee 做变化检测，仅在变化时写入；角色失效每帧即时隐藏距离，不等节拍。 |
| 移动与重生 | `src/AOTRMovement.luau` | Hover/Teleport、速度与 Noclip 状态；速度及碰撞按原对象记录基线；关闭后下一帧恢复，重生与卸载恢复混合碰撞状态；新增部件纳入快照。新增触屏飞行辅助（默认关闭）：右半屏单指左右=侧移、单指上下=前后、双指上下=升降，均按相机朝向映射增量速度；松手或关闭仅停止写入并保留当前动量，不自动制动；仍在 Heartbeat 写入，不降低移动/输入频率。 |
| FOV 与相机替换 | `src/AOTRLobby.luau`, `src/AOTRBattle.luau` | 仅在启用时取得原始 FOV；默认应用值匹配有界整数滑块。相机替换或消失即时归还旧属性，禁用/卸载释放快照，晚到回调失效，不覆盖未拥有的外部变化。 |
| 大厅/战斗入口 | `src/AOTRLobby.luau`, `src/AOTRBattle.luau` | 保留原 ID、UI、路由和模块拼接方式；按名称卸载帧回调，调试协程醒来后再次检查存活，缺窗口时不安装入口资源。Common 初始化中断统一清理，晚到 Bridge 句柄回收。大厅/战斗已有刀片/雷枪/燃气余量只读展示（读 Common 已解析的 HUD 状态）与战斗 ESP 刷新间隔查询，均不新增 Remote 或地图路由。燃气由 `src/AOTRCommon.luau:156-181` 逐级非阻塞读取 `Interface/HUD/Main/Top/7/Gas/Percentage`，缺失即清缓存；`src/AOTRCommon.luau:197-215` 严格解析0–100的百分比，拒绝非有限值与混合文本。入口见 `src/AOTRLobby.luau:69-96` 和 `src/AOTRBattle.luau:199-208`。 |

## 明确未实现

- 未从参考材料确认的 Remote 名称、参数顺序或服务路径没有新增。
- 旧说明“gas未接入”已纠正：燃气读取与入口展示均已存在，R36补齐真实片段端到端离线专项，没有重复实现燃气功能；真实客户端HUD层级、触屏操作和余量变化仍待设备验收。
- 未复制远程 loader、动态下载、未知地图适配或参考脚本中的无证据功能。
- AOTR Cloak 本轮仅补充停止回调，未扩展其他行为。
- 大厅/战斗入口已在本地执行真实入口与空操作模块夹具；初始化与相机有专项回归。战斗远程参数、真实业务模块的全玩法装配、候选视角与全部玩法仍未在真实客户端验收。

## 验证

R36在原 `tests/run_aotr_hud_contract_r18.mjs` / `tests/test_aotr_hud_contract_r18.luau` 内补齐燃气真实片段验证：183项断言，覆盖Common精确路径及0–100严格解析、大厅/战斗通知、三段强刷、两秒缓存、换GUI、缺GUI、卸载与读取中失活。先复现缺PlayerGui时刀片/雷枪仍显示旧数值的四项红态，再在 `src/AOTRCommon.luau:178` 同时清除三项引用；撤销该修复、移除区间校验、放宽递归搜索、移除入口存活门的四个独立VM负对照均命中指定断言，而非把运行异常当成功。三处读中失活各自恢复存活状态并验证实际到达读取点，避免后续入口因提前退出而假通过。此专项保留在固定34阶段的原HUD阶段内。复现命令：`/system/bin/linker64 /data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_aotr_hud_contract_r18.mjs`。

`tests/test_aotr_enrichment.luau` 使用真实 Luau mock 覆盖 Common 的 processed touch、左右区域、稳定单指/双指顺序、重复开始、无关释放、失焦、兼容事件、幂等 cleanup 与 Alive 状态，并对七个 AOTR 工厂检查返回模块、可选 Config 和停止回调注册。`tests/test_aotr_movement_lifecycle.luau` 覆盖关闭、重生、动态部件与卸载后的速度/碰撞基线恢复；这些测试不执行线上远程请求。`tests/test_aotr_esp_lifecycle.luau` 在本地实例模型执行 17 个渲染套件/54 个检查，覆盖显示同步、100 次稳定刷新零新增实例、分配/设置失败回滚、外部 GUI 销毁/移除、候选缺失、节拍与卸载；未调用第三方服务。`tests/test_aotr_titans_lifecycle.luau` 执行 18 个缓存套件/133 个检查，包含延迟文件夹、替换/重父级、30 轮监听 churn、空场景节拍、无角色根/相机、范围外、死亡、外来 Nape、模型移除与停止后引用失效。无角色根时健康且有 Nape 的 Titan 保持 alive=true；Nearest 仍返回 nil。`tests/test_aotr.py` 校验当前 `GameRouter.luau` 路由与构建键名；`tests/test_aotr_lobby_runtime.luau` 校验相机替换、FOV 基线恢复与完整 Cleanup。新增 `tests/test_aotr_common_lifecycle.luau` 的 264 个检查涵盖初始化异常、空返回、同步销毁、Bridge/窗口构造协程挂起、晚到 Open 和触控/监听幂等回收；`tests/run_aotr_entry_lifecycle.mjs` 运行真实大厅/战斗入口的 12 passed/813 checks（业务模块为惰性 stub），覆盖有界默认 FOV、多轮启停、100 次相机替换、无窗口早退、命名帧卸载及调试协程停止。测试命令固定为：

`/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_aotr_entry_lifecycle.mjs`

`/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_luau.mjs --execute --factory src/AOTRCommon.luau tests/test_aotr_common_lifecycle.luau`

`/data/user/0/com.dshmobile.shell/files/usr/bin/python3 tests/test_aotr.py`

`/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_luau.mjs --execute --factory src/AOTRLobby.luau tests/test_aotr_lobby_runtime.luau`

`/data/user/0/com.dshmobile.shell/files/usr/bin/node tests/run_luau.mjs --execute --factory src/MODULE.luau tests/test_aotr_enrichment.luau`
