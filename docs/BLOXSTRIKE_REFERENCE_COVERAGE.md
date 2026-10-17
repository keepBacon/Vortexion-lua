# BloxStrike 参考覆盖与回归

当前收口补充：`src/BloxStrikeCosmetic.luau:37-60,226-303` 已支持本机相机副本的 Equip / Idle / Inspect / Heavy Swing / Swing1 / Swing2 原生动画，依赖游戏内 Animation 与 Animator；缺少这些资源时才回退程序式姿态，不等同于内置完整原始资产。声音、手套、Sleeve、触屏按钮与卸载路径已存在，本次不重复实现。下文专项计数为历史快照，本次统一编译/构建结果见 `../后续任务.md`。

## 范围和依据

活动主树为 `wind-project`。本轮只调整 `src/BloxStrikeCommon.luau`、`src/BloxStrikeCombat.luau`、`src/BloxStrikeVisual.luau`、`src/BloxStrikeCosmetic.luau`、`src/BloxStrikeCore.luau` 及对应专测/本文档。共享桥接、构建脚本、分发产物及其他游戏入口保持独立；`BloxStrikeBullet.luau` 与 `BloxStrikeCloak.lua` 本轮未扩展。

参考只作静态需求比对，未运行远程加载器，未复制其功能源码。参考 README 的开源表述不等同于已确认的许可。

| 参考证据（相对工作区） | 功能需求 | 实现与区别 |
| --- | --- | --- |
| `reference-inputs/bloxstrike/bloxstrike.lua:1408-1422` | 瞄准开关、FOV、墙体、队伍、命中率、部位、FOV 配色 | 保留原控制 ID；新增距离上限与 Red/Green/Cyan 配色。最大角与命中率实际执行，墙体射线允许命中目标自身；锁定每次消费重验模型身份、血量、队伍、屏幕、距离和墙体。 |
| `reference-inputs/bloxstrike/bloxstrike.lua:1408-1422` | ESP 方框、血量、名称、距离、追踪线 | 原生 Highlight/BillboardGui 为基础；新增独立名称/血量/距离/可见性开关。Drawing 可用时为投影方框与追踪线；缺少 Drawing 时方框使用原生 SelectionBox，追踪线明确标注需 Drawing。 |
| `reference-inputs/bloxstrike/bloxstrike-main (3)/BloxStrike-main/Source/script.lua:35-291` | 五种刀具、偏移、装备生命周期 | 保留 Butterfly Knife、Karambit、M9 Bayonet、Flip Knife、Gut Knife；相机切换、装备/卸下、死亡、类型切换自动协调；预览部件禁用物理碰撞/查询并跟随相机。资源缺失时保持原外观。 |
| `reference-inputs/bloxstrike/bloxstrike-main (3)/BloxStrike-main/Source/script.lua:111-136,225-257` | 刀具动画、声音、左右手套附着 | 装备/检视/挥动优先读取游戏内 `Assets/WeaponAnimations/<刀具>/CameraAnimations` 的原生动画，仅操作自有相机副本；资源/Animator 缺失才用本地程序式姿态（tick 驱动，不冒充原始动画资产集）；音效从 `ReplicatedStorage/Sounds/<刀具>/<Equip|Inspect|HitTwo|HitThree>/1` 克隆播放，Ended 或有界 lifetime 到期回收；T 侧附着 `Assets/Weapons/T Glove` 左右臂，CT 侧附着 `Assets/Sleeves/IDF` 与 `Assets/Weapons/CT Glove` 左右臂（Motor6D，C0 分别 `(0,0,-1.5)`/`(0,0,0.5)`）。资产缺失按项跳过，不杜撰 assetID。 |
| `reference-inputs/bloxstrike/bloxstrike-main (3)/BloxStrike-main/Source/script.lua:292-513` | 武器分类皮肤、磨损、Sports Gloves | 从 Assets/Skins 生成分类；按 Camera/磨损名选材质，缺磨损回退 Factory New；Sports Gloves 对应 Left Arm/Right Arm 下 Glove。分类清洗名碰撞添加字节后缀，不覆盖既有唯一 ID。 |

本轮新增控制：`BloxAimDistance`、`BloxTouchRegion`、`BloxFovColor`、`BloxESPNames`、`BloxESPHealth`、`BloxESPRange`、`BloxESPVisibility`、`BloxESPBox`、`BloxESPTracer`、`BloxKnifeTouch`（触屏检视/挥动/停止按钮，默认关闭）、`BloxTrailPreview` 与 `BloxTrailPreviewColor`（本地拖尾手动预览开关与 RGB 取色器，默认关闭）。旧固定控制共 33 个均保留；动态皮肤分类 ID 对无碰撞分类保持原形式。

## 移动、性能与恢复

- 触控忽略界面已消费事件，默认只使用右半屏；起点独立保存，按到达顺序选择双指。第二指纵向位移实际返回，失焦与卸载清空触控。左半屏虚拟摇杆不进入瞄准/飞行状态。
- 对战目标扫描 10Hz；独立 Trigger 与 Hitbox 不依赖瞄准开关；Hitbox 按 20Hz 调整原始尺寸计算出的有界目标值，关开关立即恢复原始 Size/Transparency/CanCollide。原有 fullBody 选项表示多目标根部/头部范围，并非扩大所有肢体。离场同步清除预测、随机概率和候选引用。
- 开火按下/抬起在帧循环配对，无延迟释放任务；关闭、失焦、Stop 立即抬起。缺少成对鼠标 API 时使用成对 VirtualUser 操作。命中率只门控客户端辅助动作，不代表服务器命中保证。
- ESP、速度与穿墙共享一个 Heartbeat，ESP/速度/穿墙 20Hz，飞行逐帧。ESP 对象按玩家池化，不在稳定帧反复分配；快速开关不产生旧 worker。Drawing 方框启用时每个目标投影 8 个包围盒角点。Ping 缓存 0.5 秒。
- 速度重生更换备份对象并恢复旧对象；飞行恢复原始根部速度；穿墙保留原始 true/false；全亮完整恢复光照。皮肤恢复保存的原 SurfaceAppearance，并清理脱离树的原材质及应用材质。
- 相机监听重绑并断开旧连接；延迟分类任务再次检查当前代；Core 卸载幂等，解除对应 generation 的 render binding、所有工厂 disposer、UI 和自身全局通知/cleanup 所有权。旧 cleanup 不影响新实例；debug 格式参数与整数槽一致。
- 刀具预览的附加成本只在事件时发生：程序式姿态每帧只做标量运算且静止时直接返回静态偏移表；音效克隆在 Ended 或停止/禁用/重生/换相机/cleanup 时销毁；手套/Sleeve 附件一次创建并随预览一起回收；触屏按钮层仅在触屏设备且开关打开时创建。ESP 20Hz 改走共享桥接 GetVisualInterval(0.05)（max(base,1/VisualHz)，VisualHz 5..60），桥接缺失或返回非法值回退原节拍且永不加速；移动/输入/回收/战斗冷却频率不变。

## R38本地拖尾预览（离线已验证，设备待验）

`src/BloxStrikeCosmetic.luau` 新增默认关闭的 `BloxTrailPreview`、RGB取色器 `BloxTrailPreviewColor` 及手动预览按钮。相机前方固定长度50 studs、挂载相机的自有Neon部件，0.5秒平方衰减，最多32条（资源条目上限，不作卡顿承诺），关闭/换相机/失效/卸载回收；颜色在生成时捕获，已存在条目不实时变色；换相机仅清旧条目、不自动重建，须再按预览按钮。复用现有刀具跟随的 RenderStepped 连接，不新增协程、Tween或事件连接。创建与挂载失败、挂载中重入关闭均走回滚。

这只补齐参考拖尾的本地表现与预览：参考使用真实射线结果的Origin/Direction/Distance；这里使用相机姿态和固定预览长度，不代表真实弹道或命中位置。当前没有独立只读射击事件，未修改 `src/BloxStrikeBullet.luau`、战斗、命中重写或网络接口；随真实开火自动显示仍未接入，继续作为未完成项。本轮完整工厂667项检查与fresh-VM寿命负对照通过：仅撤销到期分支即命中`trail preview expires at 0.5 seconds`；另跑原生刀具动画67/67。固定34阶段于2026-10-16T11:35:47.161Z通过34/34，inputsStable/outputsStable/testsStable均为true、203旧ID保留；证据为`tests/release-test-results.json`。父独立复核102项哈希，六包已重建，无新ZIP；设备效果仍未验，ADB启动失败不是可用连接证据。

## R35覆盖复核（历史快照）

R35当时确认缺参考的自动开火弹道拖尾；R38仅完成上述手动表现预览，自动事件关联仍缺：`reference-inputs/bloxstrike/bloxstrike.lua:441-459` 创建短时Neon弹道，1424/1426行提供开关与颜色；当前 `src/BloxStrikeBullet.luau` 没有相应外观生成或配置。`src/BloxStrikeVisual.luau` 的 ESPTracer 是屏幕到目标的追踪线，不等同于子弹拖尾。此项列为后续功能，不把当前34/34门禁当作参考全覆盖证明。Random部位档已有稀疏模型回退测试，未确认缺陷；ESP可见/隐藏分色尚未核实等价性，不列为确证缺口。真实客户端与Android验收继续待补证。

## 可重放验证

从 `wind-project` 执行：

```sh
node tests/run_bloxstrike_enrichment.mjs
node tests/run_luau.mjs src/BloxStrikeCommon.luau src/BloxStrikeCombat.luau src/BloxStrikeVisual.luau src/BloxStrikeCosmetic.luau src/BloxStrikeCore.luau src/BloxStrikeBullet.luau src/BloxStrikeCloak.lua
```

`run_bloxstrike_enrichment.mjs` 从当前源码注入真实 Common/Combat/Visual/Cosmetic 工厂及 Core 入口，不复制生产实现。Roblox 实例、信号、矢量、相机和 UI 使用确定性模型；仅 Core 的共享桥接、Cloak、Bullet 作为协作者桩，避免测试执行其运行时钩子。也校验旧33个UI ID与两个新增预览ID；夹具按控件注册检查重复ID。

历史早期阶段结果（非R37的590项基线，亦非R38当前结果）：560 条断言通过（含 68 条共享视觉节流契约与真实 Common+Visual 贯穿计数、40 条刀具程序式预览/声音/附件/触屏按钮回收与能力链降级），连续多次复跑通过，七模块真实 Luau 编译通过。复跑曾暴露稀疏模型 Random 部位六次抽空后的回退未缓存；已缓存回退头部/根部并用强制六次抽空用例验证。断言计数包含 100 次 Ping 缓存读及重复 UI ID 校验，不是 535 个独立场景。

覆盖 processed/左半屏/双指/失焦/cleanup、CoreGui 挂载失败回退、Ping 缓存、Both 投影第二返回值、角度/距离/概率/墙/队伍/死亡/重生、独立 Trigger/Hitbox、离场与停止恢复、VirtualUser 配对、ESP 绘图及原生回退、50 次 ESP 快速开关、移动重生与光照恢复、磨损/手套、相机重绑、刀具即时切换/卸下、孤儿材质销毁、延迟分类释放竞态。新增：共享桥接只降频边界（回显/1/10/1/120/inf/NaN/负数/字符串/抛错/方法缺失/base 非法）、真实 Common+Visual 60Hz 与 10Hz 刷新计数对比、0.5s 慢桥接相机替换立即清 ESP 并下一帧重建、装备音效克隆播放与 Ended 回收、T/CT 手套与 IDF Sleeve 的 Motor6D 附着数量、装备/检视/挥动/停止程序式姿态位移、触屏三按钮创建/点击驱动/关闭回收、换相机先回收再重建、缺音效或缺手套资产按项跳过、未知刀具不装备、禁用与 cleanup 全回收。真实 Core 还执行重载、幂等卸载、旧 owner cleanup、render 解绑和 debug formatter。

待现场验证：实际 Roblox 移动端手势手感、原生 GUI 权限组合、不同 Drawing 实现、真实资源命名与模型尺寸、视角/皮肤/刀具视觉效果。执行模型验证不等于游戏内兼容性证明。分发文件由主构建任务生成；旧 `tests/test_bloxstrike_v2.py` 仍依赖 Starlight v2 产物，非此轮 Wind v3 工厂回归依据。
