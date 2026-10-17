# AOTR HUD Contract R18

## 修复的 bug
src/AOTRCommon.luau:142-175 的 HUD 帮助是点函数：app.ProbeHUD=probeHUD(force)、app.ReadCount=readCount(label)。两入口按钮此前用冒号调用，把 app 当首参：app:ProbeHUD(false) 的 false 落在 self 位，app:ReadCount(app.HUD.blades) 的 label 实为 app（app.Parent 为 nil）→ 恒 "未读取"；Battle:17 app:ProbeHUD(true) 的 force 实为 app(table)，不是 boolean true。

修复（仅动独占文件）：
- src/AOTRLobby.luau:22-26 HUD 按钮：Callback 首行加 if not app:Alive() then return end；app:ProbeHUD(false)→app.ProbeHUD(false)；app:ReadCount→app.ReadCount（点）。
- src/AOTRBattle.luau:190-197 HUD 按钮同改。
- src/AOTRBattle.luau:17 app:ProbeHUD(true)→app.ProbeHUD(true)（强制 boolean true，无 self）。
- tests/test_aotr_lobby_runtime.luau:42/:44 两个 stub 改点号以匹配真实入口点调用（Alive/buttons 已在 mock）。

## 契约测试（offline，不执行游戏工厂/remotes/网络）
tests/run_aotr_hud_contract_r18.mjs + tests/test_aotr_hud_contract_r18.luau：
- 从 src/AOTRCommon.luau 用唯一首尾锚点（'local HUD={blades=nil,spears=nil,lastProbe=0}' .. 'app.ReadCount=readCount'）原样提取 HUD 帮助段；从 Lobby/Battle 提取唯一标题 '查看刀片/雷枪余量' 完整 AddButton 段；Battle init 行锚 'ProbeHUD(true)'。锚点/标题/init 计数须恰 1（0 或 2 报错）。
- marker 全字面防线：4 个占位符在整模板（含注释、行内尾部）完整字符串出现恰 1，split/join 替换后全字面 0。装配 source 经一次 Buffer.from(source) 得 buf，state.loadstring(buf.toString('utf8')) 执行、sha256 对同一 buf，执行与哈希同源，可独立复算。4 个磁盘输入的 before/after SHA 以父独立 82 冻结摘要 d61f588bcc1cb730a56fb11ff9a8bc2371eb1e8d50167c6e814ecef7409ef37c 为准（该 82 集合含 34 源码 + 46 测试/基线 + 2 工具，非 4 输入本身的摘要；driver 输入 4 项由父对 SHA/bytes 逐条匹配）；driver 内 R18_INPUT_SHA256 仅为本进程提取/拼接的核对值，不作为冻结权威记录。
- 假 PlayerGui 树（Interface/HUD/Main/Top/{Blades/Sets,Spears/Spears}）+ 可控恒定时钟 _r18clock（2s 边界精确）+ spy 包 ProbeHUD/ReadCount 记录参数类型。
- 覆盖：3/8+2/4、0/5+0/0、单整数 7/7+9/9、缺 label、脱离 Parent、非数值、Text=nil、读 Text 抛错（__index 元方法，Common 内部 pcall→未读取）、numeric Text=123（luau-web 引擎 string.match 强转，不断言必抛，只断言走完 1 条通知）、缓存 0.5/1.99s 命中旧值 / 2s 过期重扫且新 label 可见、按钮缓存、destroyed 后不 probe/notify、battle init 传 boolean true。

## 验证（实测 exit / count / hash）
- 未修源真实红（fixture/runner 加固后）：exit1，RED 10 — init table、lobby/battle notifies 未读取、zero/single 未读取、button cache hit、destroyed x4。sha b657b5e5f3eed41bc10d96c05219ef3d82dba405d1ba8f6baf30ee4887733486，bytes 11677。
- 健康（修源后）：exit0，R18_RESULT GREEN / R18_PASS。sha f26e75d054f2058a12447eb0f920878815919e2ef29fa7fc8b13ab7be05dc0ac，bytes 11755。
- 4 承重 NC（单变量把某点号还原冒号，磁盘源不变，exit0 各捕获预期红）：
  - readcount：changes=[lobby x2, battle x2]，sha 86a4ec8ec7f181acec1b9d3b3d6abc27948542944b10f4e80604017a0ff72423
  - probe：changes=[lobby x1, battle x1]，sha 872bb2732acfab11db28fdd3346a939e07958df4f1b9887ee17c38930fe03b28
  - init：changes=[init x1]，sha f8837ab24e992983c4ee52b66125a7d17f5f263fd66b905a4803fedbac5c2e55
  - alive：changes=[lobby gate-removed x1, battle gate-removed x1]，sha a049e59223a4e4d42f700dfa6dba049baf3b6eccd55d880aecfd5708b23520c4
- 本轮未重新跑完整 Common/ESP/Movement/game py，下列为历史记录、非本轮 R18 重新验收：common 264/0、esp GREEN 54、movement PASS、py PASS。本轮真实覆盖仅 HUD 契约片段 + 旧 Lobby 普通 HUD/相机 + 全 inert entry（父本轮 entry Lobby 9/0/162、Battle 12/0/813，全离线、不作玩法验收）。
- 旧真实入口 tests/test_aotr_lobby_runtime.luau：PASS（HUD readout + camera lifecycle）。

## 剩余差异
- 触摸自由飞行仅 Movement TouchAssist 二维速度写入，未与 Combat 联动。
- WindUI colorpicker API 未确认，ESP 颜色 UI 未加（Boss/Normal Color3 仍代码默认）。
- 真机未验证；全部为离线 fixture/契约测试。
- HUD 只读展示刀片/雷枪；reference-inputs/aotr 的 Zenaru Gas UI 结构与 blades 不同，故不接入。
