# Vortexion R226 — SCP: Roleplay 客户端战斗 / ESP / 秒交互重构

## 作用范围

- 游戏：SCP: Roleplay，Roblox 体验 ID `5041144419`（SCP | Roleplay Community）。**不是**另一个 Roblox 游戏 SCP: Foundation Roleplay。
- 起点：R225 Neverlose 全量源码，保留 Forsaken / BloxStrike / AOTR 分支。
- 启动：`dist/Vortexion_SCP.lua`（独立版），或 `dist/Vortexion_Neverlose.lua`（统一自动路由）。
- 本构建只修改本地源码和产生离线产物，**未向 GitHub 推送**。

## 已确认根因

1. 碰撞箱默认 `lockedOnly`，依赖自瞄已经选中的目标；自瞄关着、触屏没有持续按住、目标超出 120px FOV 或没有通过 WallCheck，碰撞箱自然不触发。
2. 自瞄默认右键/触控按住，缺少移动端开关激活直接寻敌的选项，且旧分类仅对比 Roblox `Team`，无法辨别本游戏 Foundation / Chaos / Class-D 中立。
3. ESP 2D 框依赖 `Drawing.new("Line")`，Android 执行器经常没有完整 Drawing API；原模块仍为每个角色创建大量绘图对象，持续读取角色结构。
4. NPC 发现是事件缓存、首次预算化 BFS；旧 ESP 又单独遍历缓存的 NPC，并创建另一套对象，和候选池维护重复。
5. “UI 已开启”不证明服务器接受本地改变：客户端 Part.Size 增大不会自动使服务器验证的命中体增大；服务端真实命中仍需游戏内确认。

## 实现

### 目标池 / 阵营

- `SCPCandidates.luau` 加入 `GetSide`, `IsHostile`, `GetJob`。
- 两大对抗阵营：`FOUNDATION`、`HOSTILE`（Chaos Insurgency 等）。Class-D 归为 `NEUTRAL`，不默认归入任意阵营；未知队伍依靠明确的 Team 对比回退，避免一律判敌。
- SCP NPC 另标记 `SCP`，ESP 标签统一显示 **SCP收容体**。
- 玩家职位优先读取 Job / Role / TeamRole / Rank / TeamRank / Title 等 Attribute，再尝试 leaderstats，最终回退到阵营名称。具体角色服务器未公开属性时不会捏造军衔。

### 自瞄

- 安卓默认在自瞄开启后使用 `Always` 寻敌；PC 保留右键触发，可手动切换。
- 默认 FOV 从 120 增为 240px；最大距离从 300 增为 700 studs；锁定概率默认 100%（**不是服务器命中概率**）。
- 阵营筛选调用统一 `IsHostile`。保留视野、遮挡、平滑度和触摸兼容逻辑。
- 新增 Camera.Stats.Reason/Locked，调试页可直接看到为什么未锁定。

### 碰撞箱

- 默认为 `all`（独立于自瞄锁定），8 个目标上限、12Hz 尺寸更新、允许 NPC、自定义只处理敌对阵营。
- 本地物理 Part.Size 修改仍进行透明度/CanCollide 恢复和生命周期清理；不会假设本地调整等于服务端增大命中判定。
- `Hitbox.Stats.Eligible/Expanded` 记录筛选及实际展开数量。

### ESP

- **3D**：原生 `BoxHandleAdornment` 显示 Head/Torso 真实 BasePart 的 Size；引擎随部件更新，Lua 不每帧重新计算顶点。
- **2D**：`ScreenGui + Frame + UIStroke`；以 BasePart 的八个包围角向屏幕投影，确保显示实际碰撞框而非固定像素身高。
- 每个角色独立缓存：仅创建必要的 Head/Torso 和一个 Billboard 标签，未使用 Drawing API 或 GetDescendants 全图扫描；离屏/距离/数量过滤、20Hz 默认更新、若开销升高则降至不高于12Hz。
- 关闭、角色死亡、候选池变化和 UI 销毁时隐藏或释放资源；关闭的视觉子模块不会占用每帧更新预算。
- `ESP.Stats` 报告扫描数、可见数、每次刷新耗时和平滑耗时。
- 新 UI 调试：仅显示敌对阵营、显示名称（用户名/实体名）、ESP 样式 3D/2D、显示职位/SCP收容体、SCP收容体颜色（默认黑色）。同时保留敌方/其他阵营颜色、距离、刷新率。

### 秒交互

- `SCPInteract.luau` 订阅 `ProximityPromptService.PromptShown / PromptHidden / PromptTriggered`。
- 启用时将当前展示的 Prompt.HoldDuration 设为 0；隐藏或关闭时恢复原值。
- 无持续扫描、无自动攻击、不增加合法交互距离、不循环 FireServer。
- 只能控制客户端按住动画；如果服务器还有时间/权限要求则可能拒绝操作。对于非 ProximityPrompt 的独立 UI 交互也不生效。

## 测试与交付边界

- 新增 7 项 R226 专项：敌/友/中立/NPC 分类；职位回退；Prompt 激活/撤销恢复；无 Drawing 的 ESP 架构；3D/2D Frame 实际创建与清理；触屏默认和碰撞箱分离；三个构建入口包含新模块；构建清单健全。
- R222~R225 原定向回归 19 项通过（其中 R224 安全启动用模拟工厂）。总计 26 项不重复测试通过。
- 重新生成 7 个统一/独立入口及 6 个模块化入口，共 13 个 Lua 构建产物；R226 ZIP CRC、入口存在、哈希可核对。
- **没有 Roblox 安卓执行器、当前真实 SCP: Roleplay 战斗服务器的命中/交互回执、Luau 官方编译器**。因此真实自瞄射击命中、服务端碰撞判定、秒交互的服务器接受以及 Android FPS 都是未验证，不得宣称“全功能正常”或“性能损耗为零”。

## 社区参考（截至 2026-10-17，限公开证据）

- SCP: Roleplay 官方体验：https://www.roblox.com/games/5041144419/SCP-Roleplay
- 自定义服务器队伍分类 FOUNDATION / HOSTILE / NEUTRAL：https://scproleplay.com/docs/server-settings/
- SCP: Roleplay 社区团队：https://scproleplay.fandom.com/wiki/Category:Teams
- SCP: Roleplay 社区职位等级：https://scproleplay.fandom.com/wiki/Ranks
- Ryn SCP：https://scriptblox.com/script/SCP%3A-Roleplay-Ryn-SCP-136185 — 宣称游戏专属自瞄/ESP，最近用户仍反馈 ESP 问题。未据此假设其实现有效。
- Magnesium Reborn：https://scriptblox.com/script/SCP%3A-Roleplay-Magnesium-Reborn-146479 — 用于 UI 控件、颜色和刷新率交互参考。
- Neverlose SCP：https://scriptblox.com/script/SCP%3A-Roleplay-Neverlose-SCP%3ARoleplay-226000 — 页面含 NPC Scanner、即时交互等功能，但当时有效报告为 0/1，不采信为成功样本。
- Overhaul SCPRP：https://scriptblox.com/script/SCP%3A-Roleplay-GUI-with-tons-of-features-17564 — 用户报告新加入玩家后 ESP 和碰撞箱不再工作，启发了事件缓存与生命周期清理。
- 公开演示视频**未做逐帧检验**；无付费/加密脚本的授权源码，未破解其保护。没有将功能宣传当作测试证据。

## 手机回归步骤

1. 单独加载 `dist/Vortexion_SCP.lua`，先不要开启 Silent Aim/高级 Cloak。
2. 开启 ESP：先 3D 模式确认 Head/Torso 原生碰撞框；切换 2D 查看屏幕投影是否出现。
3. 切换“仅显示敌对阵营”，选择混沌分裂者/基金会阵营互相验证；处于 Class-D 时应避免直接推断敌我。
4. 开启“显示名称 / 显示职位 / SCP收容体”，切换颜色；用“ESP / 自瞄 / 碰撞箱诊断”读取 Seen/Visible/耗时。
5. 自瞄：安卓默认 Always，测试敌对目标在 FOV 内无遮挡时锁定；如果没锁定，查看诊断中的 Reason。
6. 碰撞箱：测试 `all` 独立生效；关闭功能确认原 Size、Transparency、CanCollide 恢复；区分“本地变大”和“服务端实际命中”。
7. 秒交互：启用后靠近一个新出现的 ProximityPrompt，检查按住时间变 0；关闭后应恢复。
8. 分别记录待机 / 3D / 2D 各 60 秒的 FPS、目标数、平均耗时；无实测前不保证具体增益。
