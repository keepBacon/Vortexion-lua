# Vortexion R223 — AOTR 自动换刃 / 自动补给修复

## 变更范围

仅修改 AOTR 资源功能和通用 HUD 路径、战斗分支调度：

- `src/AOTRFarm.luau`：拆分装备换刃与补给；检测当前武器 `Weapon` 属性或 HUD 的 Blades/Spears 可见性；以 `Rig_<name>` 内 `Blade_*` 的可视状态识别刀刃是否已脱落。
- `src/AOTRCommon.luau`：优先精确访问 `Interface/HUD/Main/Top/7/Blades/Sets` 与 `.../Spears/Spears`，再尝试旧路径。
- `src/AOTRBattle.luau`：资源任务脱离 `BindToRenderStep`，使用 `Heartbeat` 与单工作器锁，补充 UI 阈值、诊断按钮、补给站重扫描。
- `build.py`：生成清单标记更新到 R223。

## 旧版问题和修正

1. **自动换刃触发条件错误**：此前只在备用刀刃计数 `<=0` 时调用 `GET("Blades","Reload")`，但装上备用刀刃需要的是**手中刀刃已脱落，背包仍有备用**。新版按照刀刃模型可见性和储备量判断。刀刃模型路径变化时明确给出诊断。
2. **HUD 版本路径错误**：`Top/Blades/Sets` 并不能覆盖实际常见的 `Top/7/Blades/Sets`，导致 `nil` 时完全不触发。新版使用精确路径优先。
3. **远距离补给被硬阻断**：以前超过 18 studs 即退出，哪怕服务器允许远距离请求也不会调用。新版仅记录距离并发起受控请求，服务器是否接受以实际结果为准；**没有静默瞬移或穿墙到补给站**。
4. **补给站缺失**：补充 Waves.Props、Waves.Zones、地图 `Climbable` 与 `Unclimbable` 下 `Refill` 部件的搜索；缓存定时更新并排除失效 Instance。
5. **假成功**：`FireServer` 不反映服务器是否接受。新版仅在目标资源 HUD 计数增加后递增确认计数。GET/POST 两种协议只在等待超时后轮换，含限频与单待确认状态，避免每帧重复调用。
6. **渲染依赖**：之前 `Farm:Update()` 绑定在 `RenderStep`，渲染受限时资源任务也被暂停。新版用 `Heartbeat` 独立驱动，每次只有一个工作器。
7. **初始化竞争**：GET/POST 没有第一次发现时，加入延迟重新探测；资源 HUD 按需重探测。

## UI 使用与诊断

进入 AOTR 战斗 → **农场**：

- `自动换刃（刀片耗尽）`：先有备用刀片且手中刀刃消失后才执行。
- `自动补给（气罐/弹药）`：当前装备备用刀刃或雷枪耗尽，或气体低于设定阈值时执行，默认气体阈值 35%。
- `查看自动补给状态`：显示换刃/补给发起与确认数量、武器模式、补给站距离、最新状态。
- `立即尝试补给一次（诊断）`：绕开自动判断，单次尝试已找到的补给站，仍遵循冷却时间。
- `重新扫描补给站`：强制重新读取场景补给点。

### 状态含义

- `equip requested; awaiting blade model`：已调用装备请求，但尚无可见的刀刃变化证据。
- `confirmed by HUD (GET/POST)`：请求对应的刀片/雷枪/气体数值确认增长。
- `server unconfirmed (...)`：网络调用返回但未观测到增加；可能服务器拒绝、HUD 路径变化、射击状态未结束、游戏协议更新。不能将其视作已经补给成功。
- `station not found`：当前地图未发现可识别的补给零件；按“重新扫描补给站”可再次探测。
- `blade rig unavailable`、`blade reserve HUD missing`：不能可靠判断当前能否换刀。

## 公开研究（未复制商业或混淆源码）

- `Facu7519/aulabloaotr` 的 `src/AOTR-Hub.luau`：展示 Top/7 HUD、Waves 补给位置、武器模型状态、`GET("Blades","Reload")` 及 `POST("Attacks","Reload",refill)`；仅作逻辑比对，本文独立实现。
  https://github.com/Facu7519/aulabloaotr/blob/main/src/AOTR-Hub.luau
- `trong109944/trzhub` 的 `main`：展示 `GET("Attacks","Reload",part)` 在刀片储备补充中的用法，以及雷枪的 POST 分支。仅作为候选协议，不保证当前游戏服端仍支持。
  https://github.com/trong109944/trzhub
- LunarZR、Eclipse、Mist Hub 页面存在换刃/补给特性描述；公开用户评论也存在已失效的反馈。宣传和演示不等于服务器验收。

未购买付费脚本、未绕过付费授权，未执行网上未知 `loadstring`。未完成演示视频逐帧验证。

## 验证范围

- 重新运行 `python3 build.py`：7 个独立/统一输出，另生成 6 个模块化产物。
- `python3 verify_release.py`：14 个生成结果及入口检查通过（6 modular + 7 standalone + loader）。
- `python3 -m unittest -v tests.test_r223_aotr_farm tests.test_r222_blox_esp_rage tests.test_wind_router tests.test_neverlose_mobile_r221`：29/29 通过。其中新增 R223 测试用 Lua 5.4 mock 对实际资源模块片段进行执行，包括远距离、装备、雷枪、确认、无响应与远程替代通道。
- 上述离线测试**不**验证 Roblox 当前服务器真实行为；未使用官方 Luau 编译器或 Android 真机验证。不能声称游戏实际补给已百分百修复。
- 源码 `tests/release-test-results.json`、`dist/R222_TEST_EVIDENCE.json` 等旧文件属于之前的历史快照，不代表 R223 完整测试通过。
