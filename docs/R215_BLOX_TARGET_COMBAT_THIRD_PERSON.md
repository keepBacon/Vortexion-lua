# Vortexion R2.15 — BloxStrike ESP / 战斗 / 第三人称修复

## 来源与结论

- 目标：本仓库 `src/BloxStrike*.luau`；上传的 `bloxstrike(1).zip`（内含 `BloxStrike-main/Source/script.lua`）以及 `FPS通用脚本.zip`（Aimbot V3、Parvus、Universal SilentAim 等）。参考实现仅用于识别 Roblox 角色模型、镜头操作及瞄准器设计，未复制代码。
- 已确认的共享失效门槛：旧 `BloxStrikeCore.luau::livingCharacter()` **强制要求 Humanoid**。上传的 BloxStrike 游戏专用参考脚本在 `Workspace.Characters.Terrorists` / `Counter-Terrorists` 中通过角色模型判定存活，并不要求 `Humanoid`。自定义角色或没有标准 Humanoid 的实体因此被 ESP、战斗候选扫描及部分锁定逻辑全部过滤。这个失效模式由源码确认，真实 BloxStrike 当前每个角色是否具有 Humanoid 仍需实机采样。
- 原视觉模块为非全局诊断项：初始化异常只写 `bootFailures`，无业务统计。原战斗限制最大 15° 且默认 72% 随机门控，镜头最大仅 22°/s，易造成“不响应”的体验。
- 射击与伤害属于游戏服务端/武器协议范围。镜头瞄准、本地鼠标输入或子弹对象修改成功，**不等于服务器真实命中**。上传源码未证明当前版本稳定、可用的武器远程调用协议，因此本版不宣称“全部命中功能修复”。

## 实施修改

### 目标解析

- 优先读取真实 Humanoid 的 HP。若角色 Model 没有 Humanoid，但存在可渲染 BasePart，使用弱引用缓存的 `vitals` 代理作为存活状态，避免每帧重新创建、导致锁定 `humanoid ~= entry.humanoid` 失败。
- 读取已复制的 `Health / MaxHealth` 属性或数值对象；`Health<=0`、`Dead=true`、`Alive=false` 均过滤。无法获取 HP 时将 `HealthKnown=false`，只支持合法目标识别，ESP 不显示伪造的 HP 数值。
- 缓存角色 BasePart，避免每帧递归遍历完整 Model。继续沿用 BloxStrike 的 `Workspace.Characters` 两阵营解析，不将本游戏误当作通用 `Player.Character` 游戏。对于没有 Humanoid 的本地角色，原有 WalkSpeed 移动功能不会向目标代理写入假属性，而是安全跳过该分支。

### ESP

- 同时支持标准 Humanoid 角色与非 Humanoid 的可渲染角色 Model。
- 目标临时失联保留 0.8s，避免短时间切换或距离边界产生不断销毁/重建的视觉闪烁；离开游戏的目标清理。
- 新增 UI 中「打印 ESP 目标诊断」，报告参与枚举玩家数、有效目标数、非 Humanoid 数、当前高亮数、刷新次数和最近异常；公共功能健康状态也消费这些统计。
- 尝试名称、距离、生命值标签，**没有真实 HP 时不显示虚构 HP**。

### 战斗辅助

- 去掉默认角度过窄、70% 随机跳过本地瞄准造成的主观无响应：默认允许 35°，本地门控默认 100%，最大镜头旋转默认 120°/s（可在 20–360°/s 调节）。
- 增加 Crosshair/Distance/LowHealth 三种目标优先级，LowHealth 模式对未知 HP 降权。
- 新增 「打印战斗识别诊断」和共享健康统计，确认是否发现候选、是否保持锁定。仍需游戏画面确认瞄准是否会被武器摄像机代码覆盖。
- 旧的子弹改写与触发功能未宣称完全恢复：依赖执行器 API 与游戏服务器，无法离线证明。

### 第三人称视角

- 新增 `移动 → 第三人称视角` 开关、`第三人称镜头距离` 5–24 studs 滑块。
- 使用 Roblox `Enum.CameraMode.Classic`、`Player.CameraMinZoomDistance/CameraMaxZoomDistance`、`Workspace.CurrentCamera` 的主体和类型；250ms 状态维护，不在每帧持续反复写镜头设置。
- 关闭/卸载时恢复当前脚本接管前的 `CameraMode`、缩放边界、镜头主体/类型。对于游戏强制锁定 `Scriptable` 摄像机的情况，该功能可能被游戏再次覆盖，诊断不称其为已生效。
- 官方依据：https://create.roblox.com/docs/workspace/camera 以及 https://create.roblox.com/docs/reference/engine/enums/CameraMode 。

## 验证与限制

1. `python3 build.py` + `python3 verify_release.py`：6 个独立包和 6 个模块化产物哈希一致。
2. `tests/test_r215_blox_target_and_camera.py`：使用 **真实 Luau 方法片段** 的 Lua 5.4 模拟，验证没有 Humanoid 时目标代理稳定、数值属性变更、死亡过滤，以及第三人称开启、调整、关闭还原。
3. `tests/test_r215_blox_visual_runtime.py`：真实 `updateESP` 片段在非 Humanoid 角色环境中创建 Highlight、隐藏未知血量、关闭时清理。
4. 当前维护的回归测试和版本完整性由部署脚本运行；两个废弃测试引用已删除的 Forsaken 模块，故单独排除。
5. **未测试**真实 Roblox 安卓执行器，不保证摄像头接管、战斗命中或第三人称在所有服务器生效；需要用户在游戏内观测目标数、标记数、镜头变化和实际伤害。

## 推荐实机验收顺序

1. 更新到 R2.15 后重进 BloxStrike 对局，开启玩家 ESP（若无效果先关闭「仅显示敌方」）；进入视觉页打印 ESP 目标诊断。
2. 战斗页开启自瞄，开启／关闭「墙体检查」分别验证镜头是否移动，再打印战斗识别诊断。候选数=0 时检查角色目录/团队/视角，候选数>0 但镜头不动时检查摄像机是否被游戏重写。
3. 移动页开启第三人称并调节距离，确认相机能围绕自身模型旋转；关闭时应恢复第一人称。若立刻恢复第一人称，属于游戏脚本强制锁定而非控件未响应。
4. 关闭 ESP 及卸载脚本，确认目标高亮及镜头设置都被清理。
