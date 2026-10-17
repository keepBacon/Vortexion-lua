# Vortexion R2.8 — Forsaken 功能扩充（2026-10-17）

新增七项 Forsaken 可选功能：无限体力、反减速、反塔夫亚空间炸弹（本地视觉抑制）、自动关闭 1x1x1x1 弹窗、移动倍率（1–2）、自动修发电机、修理间隔（2.5–10 秒）。发电机另提供可选的自动前往功能（默认关闭）和手动重试按钮。

实现位于 `src/ForsakenEnhancements.luau`，由 `ForsakenCore.luau` 装配。所有功能默认关闭，统一低频调度（4Hz），角色重生后自动重新绑定，退出 UI 时清理监听及可恢复数据。模拟测试只能证明回调和客户端写入路径，不能证明远程游戏接口接受请求。详见 [R2.8 技术说明](docs/FORSAKEN_ENRICHMENT_R28.md)。

> **R2.7:** 修复按执行器名称整模块退出的问题；新增原生控件触控回调链路诊断；Loader 区分部分失败与整套启动失败。详见 [R2.7 诊断报告](docs/FEATURE_HEALTH_R27.md)。未宣称全部游戏功能已恢复。

> **R2.5 当前状态（2026-10-17）**：Forsaken 已精简为 3 页，旧功能组和失效控件移出活动构建；AOTR 战斗关闭启动期全局方法 Hook 并减少空闲帧扫描。详细变更及未验证范围见 [R2.5 专项报告](docs/FORSAKEN_AOTR_STABILITY_R25.md)。以下 R1–R46 章节仅作历史记录，原有 Forsaken 功能描述不再适用。

> **R1 更新（2026-10-17）**：`loader.lua` 已改为 V2.1 分阶段加载器。先获取 `dist/runtime-manifest.json`，再按当前游戏加载共享 UI 核心和单一游戏模块；新增共享性能 HUD、可选自适应视觉节拍以及 Forsaken 常驻连接清理。详细边界见 [REFACTOR_R1](docs/REFACTOR_R1.md)。本地自动测试不代表 Roblox 安卓实测，发布之前请将 loader / dist 清单和模块文件放在同一 Git 提交。

# Vortexion · WindUI

此版本基于提供的 Vortexion 与 WindUI 附件，使用附件内 WindUI v1.6.66 发行库。主入口是 `dist/Vortexion_Wind.lua`，执行时按当前 GameId/PlaceId 只初始化对应游戏。旧 R46 文档记录的是离线交付状态；`main` 现有统一包已发布到 GitHub。当前 Loader V2 P0 修改尚需单独提交，详见 `docs/LOADER_P0.md`。


## Loader V2 / P0（仅加载诊断）

本次仅重写 `loader.lua`：执行前创建轻量 ScreenGui，提供加载阶段状态、失败后重试、复制诊断、关闭提示；环境、HTTP、Luau 编译、入口运行及桥接注册分开检查。GUI 权限被拒绝时保留 `warn()` 控制台信息。不会修改六个 `dist` 构建产物、游戏功能、WindUI 库或 GameRouter 的路由规则。首次成功以 `VortexionWindBridge.Active` 作为桥接注册检查，不宣称 UI 已在安卓屏幕可见。

**本次 P0 不是前述 P1/P2 的按游戏分包方案**。当前仍然下载并编译原统一大文件。GitHub 远程更新后，统一启动命令为：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/loader.lua"))()
```

本地模拟测试：`texlua tests/test_loader_p0.lua`（8 场景）。此用例不替代真实 Roblox 安卓/执行器兼容性和完整 34 阶段发布门禁；旧 `tests/release-test-results.json` 属于 R46 历史结果。

## 界面

原生可折叠侧栏依次为 **通用 / 游戏功能 / UI**。通用仅低延迟切服；游戏分组保留当前游戏的功能页与原选项 ID；UI 集中提供全部 16 个内置主题、窗口设置、原生 Debug、回调诊断和配置管理。未知游戏及未知 AOTR 场景保留通用、UI 与游戏说明，不加载错误的战斗模块。

Forsaken 内置表情八槽、统计列表、假格挡和手机快捷动作均迁入 Wind 分页；ESP、FOV、视频属于游戏绘制，不被伪装成菜单。原业务的独立第三方工具入口仍保留，例如 Infinite Yield，其自带界面不是本项目的内置菜单。

支持 Forsaken、BloxStrike、SCP，以及 AOTR 大厅与已列明的任务地图。五个游戏专用 `dist/Vortexion_*.lua` 也独立可执行；统一入口不需要在运行时下载这些游戏包。

## 切服

自动切服默认关闭。客户端 GetNetworkPing 采样使用毫秒单位；阈值 180ms、连续 4 次、间隔 5 秒、开启后等待 20 秒。默认地区 HK/JP/SG/TW/KR，冷却 240 秒，最多 3 页列表和 12 个候选 IP 查询。

地区须经真实 IP 解析；IP 失败会显示失败，不虚构地区。服务器列表 ping 仅作排序参考，不等于换服后的客户端延迟。传送失败事件验证目标，明确失败才重试；等待超时视为结果未确认，避免重复传送。关闭界面停止采样与后续请求，已发出的平台传送仍由客户端处理。

## 当前交付：R46 ZIP

R46修复移动回归夹具先清空错误再判定造成的漏报，记录异步、restore与cleanup异常；生产桥接和角色代码不改。健康19场景保留，两个独立fresh-VM负对照分别捕获异步错误和清理抛错。固定34阶段于2026-10-17T00:22:53.409Z通过34/34，输入/测试/输出稳定，独立复算104项哈希零差异；既有同步1608项及16负对照、Guest350/Sil272继续通过。

本轮交付 `Vortexion-lua-main.zip` 与SHA256校验文件，统一入口为包内 `wind-project/dist/Vortexion_Wind.lua`（2154180字节，SHA256 `ba80865b4a741f8a57a8490be5d449d926aad757dea53fc8295372de8c6076e3`）。使用方法见 `docs/R46_QUICKSTART.md`；旧同名归档保留，新件位于工程外的 `delivery/R46/`。离线门禁不代替Roblox PC/Android和真实触控验收；原型未并包，整体任务继续，原期限不重置。

### R45历史交付

R45在既有他人Shedletsky/精确`_sync_terio_`本机外观同步中加入一次性白肤：仅扫描角色直属子项、最多256项，将BasePart设为参考白色；复用外观事务的原值快照、身份校验、条件恢复及迟到setter补偿。保留BodyColors与原配件，不递归、不持续锁色、不增加连接或任务；这是有界缩窄，不照搬参考远端的无限循环。默认关闭、203旧ID、自动路由及通用/游戏/UI分组不变。

同步专项1608项检查及16个指定fresh-VM负对照通过，Guest350/Sil272与R44共享布局19场景回归保留；固定34阶段于2026-10-17T00:04:44.529Z通过34/34，输入/测试/输出稳定，独立复算104项哈希零差异。六包已重建，入口 `dist/Vortexion_Wind.lua` 为2154180字节，SHA256 `ba80865b4a741f8a57a8490be5d449d926aad757dea53fc8295372de8c6076e3`；证据为 `tests/release-test-results.json`。未新增ZIP，Roblox/Android与真实触控仍待实测，整体任务继续，原期限不重置。

### R44历史交付

R44修复共享WindUI布局的非有限尺寸：视口与窗口四轴统一过滤NaN及正负无穷；异常时取消自有居中Tween、清除布局缓存，不写缩放或启动动画，尺寸恢复后按当前安全区重新布局。新增十二个四轴场景，旧七场景全部保留；修复前实跑八处失败，其中四处触发无界defer重试，修复后19/19通过。不改变正常尺寸、自动路由、通用/游戏/UI分组或203旧ID。

固定34阶段于2026-10-16T23:54:17.140Z通过34/34，输入/测试/输出稳定；独立复算104项哈希零差异。六包已重建，当前入口 `dist/Vortexion_Wind.lua` 为2153732字节，SHA256 `fd8526326670b941f5f259d0735a7d05d335176a464b39a2c4a4ef8cc28846cd`；证据为 `tests/release-test-results.json`。R43同步1462项检查、十二个负对照及Guest350/Sil272回归再次通过。未新增ZIP，Roblox/Android与真实触控仍待实测；角色原型未并包，整体任务继续。

### R43历史交付

R43在既有他人Shedletsky/精确`_sync_terio_`同步中接入动画121781457295101：2秒后本机切换正面脸，名义0.55秒后恢复；共享Heartbeat逐帧执行，最新事件覆盖，跳过整个窗口不补闪。保留R42衣裤/脸及R41挥枪，默认关闭、旧ID与TwoTime不变。关闭先还原脉冲再还原原脸，外部Texture/Parent改动保留，setter迟到/抛错与清理重入均有两层快照补偿。未接音效、红光或本机E技能，不是完整凝血演出。

同步专项1462项检查及十二个指定fresh-VM负对照、既有Guest350与Sil272项回归均通过；固定34阶段于2026-10-16T23:38:33.528Z通过34/34，输入/测试/输出稳定，203旧ID保留，父独立复核104项哈希一致。当前入口 `dist/Vortexion_Wind.lua` 为2153480字节，SHA256 `93dacff24fa5ab949b807ef040f66d5a39641c051b968224f326faaff7ad9191`，证据为 `tests/release-test-results.json`。六包已重建，无新ZIP；Roblox/Android未实测，整体目标仍进行。

R41历史交付为精确84413781229733动画的2秒挥枪显形，684项检查及五个负对照通过；当轮34/34生成于2026-10-16T23:15:44.745Z，入口2147538字节，SHA256 `095a4fde32ca2cc4f98f0166ac7cc94aa3d2cdbc95a9dca53180e91c160ceef2`。工作区报告已更新为上述R46证据。

R40历史交付新增Terio枪饰/名称/图标，554项检查及四个负对照通过；当轮34/34生成于2026-10-16T12:19:56.737Z，入口2144383字节，SHA256 `c59644691a37b885ce09866ce349b8f7573c8d91aea51306ef79e7a7481987d4`。手持枪当时持续隐藏，R41才接入显形；工作区报告已更新为上述R46证据。

R39历史交付为Sil两项本地动画替换，272项检查、延迟负对照与Guest350项回归通过；当轮34/34生成于2026-10-16T11:53:41.810Z，入口2141840字节，SHA256 `dc1b462c0f2745ba827e8f86232d5ba4be3ffd27136e48cfbb669259609f60b8`。工作区报告已更新为上面的R46证据，实机仍未验。

R38历史交付为本地手动拖尾预览与RGB取色器：50 studs、0.5秒平方衰减、32条上限，BloxStrike667检查及寿命负对照通过；当轮完整34/34生成于2026-10-16T11:35:47.161Z，入口2133453字节，SHA256 `b9d4b7f3fdfcab8fbad1edf20166936d443a50e200b52ac9ba4467ad00704ecc`。该轮证据已被上面的R46工作区报告替代，真实开火自动拖尾仍未接入，Roblox/Android未实测。

R37补齐共享颜色控件与SCP敌人/队友/低血量三色，真实vendor契约126/126、SCP31/31及配置同步负对照通过；该轮34/34报告生成于2026-10-16T10:58:13.460Z，入口当时2128021字节，SHA256 `c0685e09f80cf6453a27fa2f05a491c6d5dc3f07508df8f90b39e90cf8608d6d`。这是R37历史证据，当前入口和工作区报告已更新为上面的R46结果，Roblox/Android仍未实测。

R36修复AOTR缺界面旧余量缓存，183项HUD断言与四个负对照通过。该轮34/34报告生成于2026-10-16T10:34:52.576Z，当时入口2125171字节，SHA256 `0b482eb9acb928bc509eab52b34b700a4dbde85d26e1310a0b6af86784978995`。这是R36历史结果；工作区报告和入口已更新为上面的R46证据，Roblox/Android仍未实测。

BloxStrike、SCP、AOTR的上一轮已实现范围通过离线检查；参考全覆盖、真实游戏行为与安卓触控/性能验收分别记录，不将工程收口表述为整个游戏模块全部完成。

R35 已集成 Guest 页默认关闭的 TwoTime 聊天外观同步：精确 `:syncScript` → 他人 TwoTime 的本机刀饰与玩家栏名称；关闭/角色变化/离场/会话失效回收，不发聊天或执行远程加载器。专项57项断言与三个有效负对照已并入固定34阶段；2026-10-16T10:14:39.913Z完整门禁34/34通过，源码/测试/输出哈希稳定，203旧ID保留。R35当时入口 `dist/Vortexion_Wind.lua` 为2125107字节，SHA256 `4cff5f3c8ce692ef2ab094f4ffac9e8371ffa101096770726591f15dffb6f725`；此为R35历史结果，当前报告已更新为上述R46证据。仅离线验证，Roblox/Android仍未实测。

R34 已交付入口当时为 `dist/Vortexion_Wind.lua`；新增可恢复的世界 Swords 粒子隐藏、默认关闭的三段本地音效与两项参考动作演出，并修复SCP无效距离配置。三段音频及来源/哈希见 `assets/forsaken/`，运行时使用执行器workspace的 `TerioThings/` 相对路径。最终固定34阶段离线门禁全部通过，世界粒子45项与音效99项断言、七个负对照已并入原流水线；打包保护22项通过。源码、测试与输出哈希均保持稳定。R34历史报告生成于2026-10-16T09:49:12.065Z，随原归档保留；工作区的 `tests/release-test-results.json` 已更新为上面的R46证据。R33工程快照继续保留。范围、十二项缺失音频及未实现功能见 `后续任务.md` 顶部；本地表现不代表完整服务端技能，Roblox/Android未实测。

## 重建与验证

下列为完整验证/发布流程；`tools/package_release.py` 要求匹配当前源码、构建及测试脚本的完整门禁证据，并在归档前核对资源清单大小/SHA256与路径归属，保留已有同名归档。

```sh
python3 build.py
python3 tests/test_wind_router.py
python3 tests/test_wind_migration.py
python3 tests/test_forsaken_wind.py
lua5.4 tests/test_server_switch.lua
npm install --no-audit --no-fund
node tests/run_luau.mjs
node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau
node tests/run_release_checks.mjs
python3 tools/package_release.py
```

Luau 编译验证使用固定的 luau-web 1.5.1。切服测试使用 Lua 5.4；路由测试的 Lua 共享库缺失时会明确跳过，不当成成功。构建清单记录全部构建输入和六个输出的 SHA256。整合执行器会先重建，再运行全部门禁阶段，跳过测试不计通过；测试、选项基线、构建和打包脚本须在执行前后保持一致，结果、输入哈希与完整输出写入 `tests/release-test-results.json`。可用 `NODE_BINARY`、`PYTHON_BINARY`、`LUA_BINARY` 指定实际解释器，Android 链接器启动方式须同时传入 `NODE_BINARY` 与 `NODE_LAUNCHER=/system/bin/linker64`；本机验证同时指定 `/data/user/0/com.dshmobile.shell/files/usr/bin/` 下的 `node`、`python3` 与 `lua5.4`，避免默认 PATH 选到不同运行环境而漏跑路由测试。`docs/WIND_ANDROID_QA.md` 是当前安卓验收清单。打包默认保留已有同名归档；R34等历史ZIP及其SHA256继续保留，R46按最新要求另行交付 `delivery/R46/Vortexion-lua-main.zip`。最终归档时通过 `--output` 指定新的独立文件名，打包器再次核对实际读取快照并附带SHA256校验。

本地编译、mock 和静态回归不等于 Roblox 真机验证，安卓触控与游戏实时接口仍待实测。重复执行会先清理旧桥接，再创建新库，避免堆叠窗口和任务。配置页手动操作且进行中的文件操作不重入，准备失败可重新创建配置；首次打开不会自动加载配置或打开自动切服，手动加载暂停时也保持旧自动加载入口关闭。文件 API 不完整时显示能力说明。卸载停止旧回调后续分发并释放监听与待提交值，正常错误提示和清理重置仍保留。布局重入复查最新相机、尺寸和自动适配状态，居中失败不缓存为完成。下拉列表成功返回后再提交，失败可重试；列表刷新重入合并最新请求，分批重建，卸载取消待刷新列表。

## 来源与历史文件

WindUI 原始发行库与 MIT 许可证保留在 `vendor/WindUI/`，未修改附件库。WindUI 在部分执行器中仍联网获取图标，游戏音视频/资产和可选第三方功能也有网络依赖，单文件构建不代表完全离线运行。

`src/StarlightAdapter.luau`、`vendor/Starlight/`、旧 `test_stage2/mobile/toggle/touch` 测试及旧发布文档作为原附件历史保留，不进入 Wind 活动构建，不作为此版本验收结果。原项目与派生业务的其他来源说明仍保留，新增 WindUI MIT 许可不改变旧代码的许可。


## R2 (本地交付；远程部署前需确认)

- 详见 [R2 修复记录](docs/REFACTOR_R2.md)。本轮修复子模块启动错误感知、BloxStrike 动态皮肤 UI、SCP 兼容降级和 AOTR Cloak 异常隔离。
- 共享性能诊断增加帧耗时/卡顿计数。未经过 Roblox 安卓实机验证。
