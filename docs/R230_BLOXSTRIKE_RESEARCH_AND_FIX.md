# Vortexion R230 — BloxStrike 适配与可验证修复

日期：2026-10-17。基线：R229。R230 无需重新开发 Neverlose UI，保留 R229 的 UI、Loader 与 Forsaken / AOTR / SCP 模块。

## 问题与根因

| 症状 | R229 确认的源码原因 | R230 |
|---|---|---|
| 碰撞箱不生效 | fullBody 和 lockedOnly 都从 `state.candidates` 获取目标；此列表先受到 FOV 与屏幕可见性筛选 | 独立 `state.spatialTargets`，按距离/阵营/生命状态判断，offscreen 但邻近的对象仍可加入 |
| 扫描遗漏角色 | 旧 Characters 缓存只覆盖直属 Model 和下一层 Folder；多层地图/队伍容器可能漏人 | 限深扫描 Folder，缓存读取而非全图 `GetDescendants()` |
| 武器修改冲突 | 任意补丁安装后直接从安装函数返回，因此后来开启的另一类修改无法新增 Hook | 每个 owner/key 单独去重，后续启用的无散布能单独安装 |
| 武器控制器异常 | 原 `weaponKick` 接管直接 `return nil`，未知方法签名/返回契约可能被破坏 | 只处理已确认的 CameraController getter/setter 类型，保留其它方法原样 |
| 安卓 2D ESP 无图形 | 2D 容器无法创建时，旧代码直接返回，没有强制显示 3D billboard | 2D 失败时启用 Billboard 回退，并记录可见诊断 |
| 部分执行器启动中断 | 主帧回调 `BindToRenderStep` 未加保护 | 失败时退回 `RenderStepped` 并显示原始警告 |
| RageBot 无实际命中 | 目标、镜头、输入事件与真实服务器伤害是不同链路。旧版没有服务器命中观测 | 保留镜头/鼠标输入双路径和有界尝试；报告目标/门控/输入状态，不宣称服务器命中 |

**限制**：本地改 `BasePart.Size` 不能保证服务器验证的命中盒变大。`getgc`、`hookfunction` 等执行器 API 缺失时，某些武器修改仍会不可用。没有游戏客户端和服务端，就不能认证实际命中率。

## 社区信息（外部检索，非实机验证）

- Mario Hub (`https://github.com/xDTaraZz/Roblox-Scripts/blob/main/All%20Map/BloxStrike.lua`)：2026-10-10 的变更日志明确涉及 ESP team check、机器人、RageBot、Silent Aim 和开火崩溃。其公开代码通过 `Workspace.Characters`、`Team` / `CharacterName` 等属性维护目标，并通过游戏控制器类与网络模块识别枪械。已审阅公开源码的这些结构；未直接复制大段实现。
- AMP Hub (`https://scriptblox.com/script/UPDATE%21-BloxStrike-AMP-Hub-or-Anti-Detect-Engine-V2-or-Free-229451`)：受 Key 保护，发布者称支持 Full/Semi Rage、ESP、武器功能，提供演示链接。未取得原始付费源码、未破密；三个 YouTube 视频链接在当前检索环境无法打开，所以没有作画面级结论。
- noic Rage/Legit (`https://scriptblox.com/script/UPDATE%21-BloxStrike-Silent-aim-or-Wallbang-or-RageLegitbot-KEYLESS-229058`)：9 月版本，描述支持 Wallbang、Rapid Fire 等；评论里作者称尚未完成 Android 支持，不能作为移动端验证依据。
- BeboMods (`https://scriptblox.com/u/BeboMods`)：10 月有 BloxStrike No Recoil/No Spread 开源项目列表。平台详情及最新兼容性有待核查。

## 验证

- `python3 build.py`：全部 7 个独立/统一脚本 + 6 个模块生成成功；运行时清单 SHA-256 可复算。
- 适用定向模拟：43/43，包含新增的 4 项 R230 测试。
- 新模拟测试实际执行了 Luau-to-Lua 转换片段，证明 offscreen 目标加入空间目标池、仍不进入瞄准池，以及碰撞箱不再复用准星门槛。
- 没有完成官方 Luau 编译、安卓 Roblox 实机测试、服务器实际命中、实际执行器的 Hook 效果测试。

## 手机诊断步骤

1. 进入 BloxStrike 正式对局，确保目标存在，打开视觉页的 ESP 总开关。
2. 设置页点击 **战斗 / ESP / 武器关键路径**，查看 `roster`、`enemy`、`aim`、`spatial`、`esp`、`drew`。
3. 打开战斗页的碰撞箱，用离屏附近目标验证 `spatial>0`；不要以服务器击中作为本地碰撞箱判断依据。
4. 开启 RageBot 后执行“RageBot 状态诊断”。`fire=unavailable` 代表当前执行器不支持该输入。`input sent` 只代表向输入后端发出请求。
5. 武器页开启所需项目，进入对局开火，使用“武器修改诊断”检查 `native/table/calls`。若 calls=0，当前接口未被枪械控制器调用；需日志或游戏版本结构进一步适配。
6. 若仍为零，提供 **BloxStrike 运行诊断日志**、执行器名称、当前对局模式与游戏版本。请不要将凭本地输入推断的伤害视为实测命中。
