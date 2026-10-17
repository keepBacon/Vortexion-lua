# Vortexion R225 · BloxStrike 底层重构审计

日期：2026-10-17。基线：R224 完整源码（本地归档 `Vortexion_R224_Neverlose_宣传图UI_SCP安全启动_完整源码.zip`），保持 Neverlose UI 及全部其他游戏模块。

## 1. 已确认的共同根因

**R224 的 `isEnemy` 把 `Workspace.Characters` 共同父目录当成队伍标识。** 当前公开游戏针对性源码（Mario Hub，2026-10-10 改动）将各角色模型直接放在 `Workspace.Characters` 下，使用 Players 的 `Team` 属性以及角色的 `CharacterName` 对照 `Workspace.CTCharacter` / `Workspace.TCharacter` 判断敌我。

当本地和敌人都在同一根目录时，旧逻辑始终认为两者同队：ESP 绘制对象会被过滤、RageBot 和自瞄候选也可能归零。这个失败和 UI 是否正常显示无关。

R225 新逻辑优先：角色/Player Team Attribute → 角色 CharacterName 与 CTCharacter/TCharacter 映射 → Roblox Team 对象 → 已确认的真实阵营子文件夹。相同根目录不再用作团队标识。Deathmatch 变体按字符串包含识别；用户关闭敌方筛选时不按队伍过滤。

并且从 Player Attribute 回退读取 Health、MaxHealth、Dead，兼容无 Humanoid 的角色（原有虚拟血量路径仍保留）。

## 2. ESP

- 修复队伍错误的共享底层判定，修正字符串死亡状态。
- 保留 2D ScreenGui 投影和 BillboardGui 兜底。保留移动端不拦截点击的设置。
- 实时诊断：扫描数、合格目标数、绘制数、2D 容器和投影错误。
- 不在零候选时假装“正常显示”，改为显示提示。

## 3. RageBot

- 现在候选与 ESP 使用统一修复后的敌我/存活接口；以头部位置优先进行屏幕候选筛选。
- 射线过滤包括角色容器，避免友方/其他角色身体导致射线误判为墙体。
- 安卓自动开火：保留 mouse1press/click，优先尝试 VirtualInputManager，失败则回退 VirtualUser；诊断保留后端信息。
- 输出 roster / alive / enemy / candidates / shots / aim backend / failure reason。
- 改写客户端相机与模拟输入并不意味着服务器承认命中。不存在 100% 命中率保证。

## 4. 武器与子弹

### 武器控制器
旧实现只是替换 Lua Table 的 `owner[key]` 函数值。若游戏早已把该函数保存在 Upvalue 或其他对象中，游戏仍调用旧函数，本地界面开关完全不起作用。

R225 在主动开启时优先通过执行器 `hookfunction` 接管实际函数地址，记录原函数以便卸载。缺少该接口时才使用 Table 替换降级，明确标记该降级可能无效。提供 Native Hook / Table Patch / 调用次数 / 延迟重新探测等状态；不默认假称“已生效”。

### 子弹链路
旧 `installHitscanHooks` 硬编码从 `ReplicatedStorage.Components.Weapon.Classes` 扫描 ModuleScript，与最新版脚本使用的运行时枪械类不完全一致。R225 增加了 GC 中严格特征识别的 Gun / Bullet 类定位 (`shoot`+`setupRecoil` 或 `getSpread`, `create`+`getTrueSpread` / `getSpreadForConfig`)，仅在用户主动选择 Hitscan（或者 PC Auto）模式时挂钩，不在启动时修改任何全局元表。

现在额外统计 Hitscan Hooks、调用次数、参数修改次数，未在游戏内触发的方法不标记有效。移动端默认依然保守；开启危险 Hook 可能受执行器限制。若游戏走的是服务器私有、不可访问的开火协议，仅靠本地 Hook 无法保证子弹追踪和服务器命中。

## 5. 公开参考与验证范围

已检索并阅读公开源码：
- https://github.com/xDTaraZz/Roblox-Scripts/blob/main/All%20Map/BloxStrike.lua — Mario Hub 2026-10-10 的队伍识别、枪械/子弹类、射击输入示例。**原理参考，不直接复制。**
- https://github.com/plalettescripts/bloxstrike/blob/main/loader.lua — 开源但功能较简单，仅作比较。
- https://mariohub.xdtaraz.com/en/changelog — 10 月 10 日多次 BloxStrike 相关修复记录。
- https://scriptblox.com/script/UPDATE%21-BloxStrike-AMP-Hub-or-Anti-Detect-Engine-V2-or-Free-229451 — AMPHub 最新功能描述，收录演示视频：
  - https://youtu.be/EMm78BLKdwI
  - https://youtu.be/Pq-HX60QnBM
  - https://youtu.be/x8P3NJReYQU

这些视频页面可核对，但未进行逐帧画面解析；混淆及付费脚本没有反混淆或付费绕过。功能清单、营销描述不能被当成现场测试证据。

### 离线测试
- `test_r225_blox_gamecontracts.py`：4 项，包含直接同目录场景、团队分支、Native Hook 回调、可恢复性和构建合同。
- `test_r222_blox_esp_rage.py`：5 项。
- `test_r219_billboard_weapon.py`：4 项。
- `test_r223_aotr_farm.py`：4 项。
- `test_r224_brand_scp.py`：6 项。
- 合计 23 项定向测试通过（使用 Lua 5.4 Mock + Python）。
- `python build.py` 与 `python verify_release.py` 通过（7 个完整/统一包 + 6 个模块化脚本）。
- 全量历史单元测试：167 项，21 项失败、2 项加载错误；对照原始 R224 基线（163 项，21 项失败、2 项加载错误）失败项数量未增加。旧版 WindUI 假设、旧哈希和仓库缺失的模块是主要因素。

**未验证：** Roblox 安卓真机、执行器差异、实际服务器命中、武器属性是否被游戏重新覆盖、付费脚本效果。不能承诺全部功能百分之百正常。

## 6. 安卓现场诊断方法

1. 先运行 `dist/Vortexion_BloxStrike.lua`，确认进入真实 BloxStrike 对局，而不是大厅。
2. 开启 视觉 → ESP 总开关及 2D ESP，点击“打印 ESP 目标诊断”。如果 `扫描>0, 合格=0`，观察队伍/模型结构；如果 `合格>0, 标记=0`，检查 PlayerGui 权限与创建失败。
3. 开启 战斗 → RageBot，查看 `RageBot 状态诊断` 的 roster / alive / enemy / candidates。若 candidates 大于零但 shots 为零，检查 aim backend 和 reason；若 input sent 但无伤害，需另行分析游戏发射及服务器判定。
4. 开启 武器 → 降低本地枪械后坐力 / 本地枪械散布控制后实际射击，再查看“检查武器修改器状态”；calls=0 表示调用未经过被 Hook 的方法，不代表 UI 或服务器故障。
5. 子弹追踪默认 LeadOnly 为无侵入预测；选 Hitscan 才会尝试游戏函数 Hook，先完成设备备份/确认执行器支持。查看“检查实际子弹 Hook 调用次数”；rewrites=0 不宣称命中。

日志建议保留 `[Vortexion/Blox]`、`[Vortexion/Rage]`、`[Vortexion/WeaponMods]` 等前缀供继续定位。

## 7. 发布说明

GitHub 未被本地构建脚本更新。所有其他游戏的源文件保持与 R224 相同；只更改 BloxStrike Core、Combat、Visual、Bullet 及新增测试和文档。通过 `python build.py` 生成脚本；Termux 可将 `wind-project/` 作为仓库根目录提交。
