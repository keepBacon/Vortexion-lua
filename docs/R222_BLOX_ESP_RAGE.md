# Vortexion R222 — BloxStrike ESP 修复与 RageBot（Neverlose）

更新时间：2026-10-17。基线：用户上传的 `Vortexion_R221_Neverlose_UI_移动端完整源码.zip`，参考 `FPS通用脚本.zip`。R221 的 Neverlose UI 和其他游戏模块继续保留。

## 一、ESP 不显示：问题链与修复

1. R221 继续使用 R219 的 `BillboardGui` 作为唯一主要 ESP 画面；它可能受到 Roblox/安卓执行器的 3D GUI 可见性、裁剪和自定义角色模型影响。**该问题是已确认的单路径脆弱性，不等同于证明它必然是用户设备的唯一故障。**
2. R221 仅扫描 `Players:GetPlayers()`；2026 年 10 月公开的 BloxStrike 更新记录提到**NPC/Bot 目标识别缺失**。`Workspace.Characters` 内不属于 `Player` 的战斗角色会被遗漏。
3. `BloxStrikeCore.luau` 新增带 0.25s 缓存的混合目标枚举：在线 Player + `Workspace.Characters` 内的 Model NPC；NPC 使用稳定代理并保留所属阵营，已有的无 Humanoid 活体状态逻辑继续工作。更新角色/代理失效时清理缓存引用。
4. `BloxStrikeVisual.luau` 新增 **2D ScreenGui Viewport ESP**（默认开启），直接使用 `WorldToViewportPoint` 将角色顶部/底部映射为非交互方框和文字，`IgnoreGuiInset=true`，独立于 3D Highlight 可见性；Billboard 留作关闭 2D 模式或无法创建 2D 层时的回退。约 12.5Hz 投影、3Hz 文本更新，近距离角色头部超出视口仍可按躯干和身体投影显示、上限 24 目标；动态节流跟随 UI 视觉刷新档位。
5. 新增 UI：`视觉 → 2D 屏幕 ESP（手机推荐）`。诊断按钮输出玩家扫描数量、目标数、2D 创建/绘制数、GUI 容器可用性和最后错误。

**注意**：`WorldToViewportPoint` 可以绘制几何上投影到屏幕的被遮挡角色，但不保证不同 Roblox 设备/执行器的 ScreenGui 层级和可见性；真机需验证 UI 是否可见、位置是否正确、开关是否响应。

## 二、RageBot：实现边界

在 `BloxStrikeCombat.luau` 的**战斗**页添加独立 RageBot，而不是把平滑自瞄强行改成 `瞬间命中`：

- Rage 独立开关、快速/瞬时镜头锁定、头部/躯干/最近部位、自动开火，以及 Camera/Mouse/Auto 输入交付模式。
- 复用玩家+Bot 识别和缓存，但采用独立 Rage FOV、距离与夹角；独立遮挡检查与移动预测（包含 RTT/2）。
- 约 20Hz 目标重新扫描、短时间目标稳定锁定、至少 0.08s 可配置开火间隔；真正开火必须满足镜头角度收敛及发射路径允许条件。
- **针对 BloxStrike 游戏内摄像机覆盖**：增加 `Rage 瞄准输入：Auto / Mouse / Camera`。Auto 在连续帧检测到摄像机 CFrame 写入被覆盖时转为 `mousemoverel`，每次鼠标位移进行限幅并等待后续帧重新检测瞄准收敛；若执行器不提供 `mousemoverel`，诊断明确报告不可用。默认先检查摄像机写入能否保留，不能保证所有 Android 执行器提供鼠标输入通道。
- 射击后端按能力选择 `mouse1press/release`、`mouse1click`、`VirtualUser`、`VirtualInputManager`（实际可用性随执行器变化）。失败记录后端和原因。禁用时立即释放被本脚本按住的输入。
- 可检测游戏摄像机每帧覆盖：连续多次回退后自动尝试 `mousemoverel` 输入，避免镜头锁定数值更新却被下一帧重置。
- 旧版手动自瞄、自动开火、命中箱和子弹模块接口继续保留。开启 Rage 时使用自身目标扫描/锁定，避免两个瞄准模块同时写摄像机。
- Rage 状态按钮打印扫描次数、候选数、锁定对象、模拟输入尝试/成功次数、`aim` 当前传递模式、摄像机覆盖次数、鼠标移动次数、输入后端与最近原因。

**关键限制**：此版 RageBot 是**客户端快速锁定 + 正常射击输入**，没有对未经确认的 `ShootWeapon` 远程数据包进行猜测，也没有把视觉命中当成服务器伤害。在 BloxStrike 采用独立射击视角/服务器核验的版本中，模拟输入或摄像机转向成功仍可能无法命中。必须用游戏内敌人真实掉血验证。

## 三、参考与筛选方法

上传的四套 FPS 参考均进行了静态检查，未执行其代码：

| 参考 | 可借鉴实现 | 已知限制 |
|---|---|---|
| Aimbot-V3 | FOV、目标检测、Triggerbot 输入路径 | 通用 Aimbot，非当前 BloxStrike 协议 |
| Parvus | 通用配置与游戏适配层、射线检查、预测、SilentAim 封装 | 各游戏与当前 BloxStrike 内部类不兼容 |
| Universal-SilentAim | Raycast 和 Mouse 类型的命中目标重定向方式 | 上游 2026-07 归档，不保证可用 |
| 第四份 dddd.lua | Aimbot、射线、方法 Hook 的存在性和调用边界 | 未实际执行或恢复不可信的运行环境 |

公开检索：

- **xDTaraZz/BloxStrike**：https://github.com/xDTaraZz/Roblox-Scripts/blob/main/All%20Map/BloxStrike.lua 。2026-10-10 公开提交 `0ed9cbd` 说明 RageBot 对游戏更新后的适配、Bot 扫描、阵营/血量修复；`59a83b8` 说明瞄准、ESP、透墙与镜头恢复。**GitHub 更新日志与源码声明不代表已在本设备验证。**
- **摄像机覆盖专项开源参考**：https://github.com/seltonmt012/sel01-rbx/blob/main/games/universal.lua 。作者记录 BloxStrike 的 `Camera.CFrame` 被游戏每帧覆盖，因而使用执行器鼠标移动回退；属于作者披露的实测结果，本项目未在真机复测。
- **公开演示**：https://www.youtube.com/watch?v=CrNPwzFK7MY （2026-01-20，标题及介绍包括 Ragebot/Legitbot/ESP）；https://www.youtube.com/watch?v=oEb-ROZbg_U （2025-12-19，标题及介绍包括 Ragebot）。另有 https://www.youtube.com/watch?v=L-HW-t05hAI （2026-06-13，演示说明提供 00:11 Rage / 00:47 Legit 时间戳）。本环境只取得公开视频元数据/描述，**未成功抓取视频画面或逐帧分析**，不将演示宣称为有效验证。
- **2026-09 公开脚本功能页面**：https://robloxscripts.com/script/bloxstrike-script-esp-silent-aim-aimbot-triggerbot-recoil-control-key-system-free-4h-key-updated-28082026 ，列出 ESP、预测、触发开火、枪械后坐力等规格。页面内容是作者宣传，不能据此保证功能有效。
- **其他开源参考**：https://github.com/Averiias/Universal-SilentAim 和 https://github.com/plalettescripts/bloxstrike 。

没有取得付费私有脚本授权或明文源码；没有尝试破解付费授权或执行来源未知的混淆加载器；本项目代码为独立实现，不直接拼装其他作者的整份脚本。

## 四、离线测试（已做）

- `python3 build.py`：生成 7 个独立入口及 6 个模块化包，构建通过。
- `python3 verify_release.py`：生成包/摘要校验通过。
- 新 R222 Lua 5.4 真实片段执行 5/5：Player/NPC 混合 roster、独立 2D ESP 创建复用与关闭销毁、Rage 选目标/开火限频/关闭、摄像机写入反复被覆盖后的 Mouse 回退、生成包 UI 功能标识。
- 旧回归分别通过：R219 Billboard/武器 4/4，R215 目标/镜头 3/3，R221 Neverlose 桥接与移动端策略 4/4，R26 BloxStrike 启动 3/3。
- R221 原“所有玩法文件必须与 R220 字节相同”测试现已调整为“其他游戏玩法文件仍与 R220 相同”：R222 对 BloxStrike 的 Core/Combat/Common/Visual 是有意改动。

**未测试**：官方 Luau 编译器完整包、真实 Roblox 安卓执行器、UI 手感、当前 BloxStrike 回合的 NPC 身份准确率、服务器掉血、各种枪械射击事件。请勿把离线 19 项通过视作实机通过。

## 五、实机核查与故障定位

1. 启动 `dist/Vortexion_BloxStrike.lua`；如果是自动识别游戏，用 `dist/Vortexion_Neverlose.lua`。避免与 R221 同时运行。
2. 进入真实战斗回合：视觉 → ESP 总开关、2D ESP 打开，暂时**关闭“仅显示敌方”**，距离设 2000，观察是否有屏幕边框及名称。
3. 运行“打印 ESP 目标诊断”：`玩家` 是扫描的 Players + NPC 总数，`合格` 是距离/队伍/状态过滤后的数；`2D创建>0` 而 `2D绘制=0` 应查视口投影/角色模型；`2D绘制>0` 却屏幕无画面应查 ScreenGui 父级/执行器覆盖。
4. 战斗 → RageBot 总开关打开 → Fast/Instant、Rage Auto/Mouse/Camera 输入模式及自动射击开启 → `Rage 瞄准输入=Auto`；先保留遮挡检查，实测瞄准是否跟随敌人。
5. 点击“RageBot 状态诊断”读取 `target` / `attempts` / `sent` / `aim` / `camera_misses` / `mouse_moves` / `fire` / `reason`。`input sent` 仅说明输入 API 未报错；**真实伤害请对照敌人生命值或击杀统计**。
6. 不成功时保留上述两段诊断输出、游戏 PlaceId、执行器名称、机型、横竖屏尺寸与失败时录屏。特别区分空房间、观战/死亡、机器人、真实玩家与改动后回合场景。

## 六、改动文件

`src/BloxStrikeCore.luau`、`src/BloxStrikeCommon.luau`、`src/BloxStrikeCombat.luau`、`src/BloxStrikeVisual.luau`；新增 `tests/test_r222_blox_esp_rage.py`，保留旧测试并调整 R221 基线不变断言。`dist/` 下全部包与 manifest 重新生成。**没有提交或推送远程 GitHub。**

## 七、额外代码复核（R222 收尾）

- 修正 BillboardGui `MaxDistance` 设定值与比较值不一致导致的每次刷新重复写入。
- 2D 投影错误按目标单独隔离，防止某个模型抛错终止其他目标 ESP。
- 角色头部投影在屏外、身体还在视口内时保持 ESP；对应修改已进入 Lua 模拟用例。
- 新增摄像机控制器覆盖探测和受控 Mouse 输入回退；每次输入仍不代表游戏接收射击或发生伤害。
- 重新通过 `test_generated_whitespace.py`；原 153 项全量历史测试仍有 14 失败、2 加载错误，完整控制台记录仅在本次工作环境中，未一并打入 ZIP。
- 公开视频尚未成功获取画面，来源参考仅限公开脚本源码与作者文字说明，没有声称分析过实际视频帧、破解付费脚本或实测其运行效果。
