# 第18轮普通HUD修复与构建父独立验收

## 结果与范围

本轮修复普通只读HUD展示的点/冒号调用约定，以及销毁后晚到点击的扫描入口。未改变游戏协议、Farm/Combat消费者、Common帮助函数、共享桥接或vendor；未执行完整玩法、真实32阶段发布门禁、Roblox/Android实机、网络协议或新ZIP。整体丰富目标仍未完成。

- `src/AOTRLobby.luau:23-26` 与 `src/AOTRBattle.luau:191-194`：先检查 `app:Alive()`，再用 `app.ProbeHUD(false)` 与 `app.ReadCount(label)`。
- `src/AOTRBattle.luau:17`：实际初始化行改为 `app.ProbeHUD(true)`，传入boolean true而非隐式self。测试只抽取该行，不执行相邻ProbeRemotes或整Battle工厂。
- `src/AOTRCommon.luau:142-175` 原样不变：ProbeHUD(force)、ReadCount(label)是点函数。旧colon把app作为首参，导致ReadCount遇到app.Parent=nil而返回nil，ProbeHUD的force成为真值table、绕过两秒缓存。
- `tests/test_aotr_lobby_runtime.luau:42,44` 两个旧stub纠正为点函数，保留原3/5与1/2通知和相机断言；没有放宽生产帮助函数或既有断言。

HUD专项用唯一锚点从真实Common截取原样帮助段，从两入口截取真实按钮回调和Battle初始化行。假GUI、时钟和UI登记只隔离普通展示，覆盖3/8与2/4、零值、单整数、失效/脱离标签、Text=nil及getter抛错、0.5/1.99/2秒缓存边界、新标签更新、销毁后不扫描/不通知。numeric Text=123在当前luau-web会被string.match强转；父实际验证这一行为，未把必抛当契约。

## 父实际复验与承重点

Node绝对路径 `/data/user/0/com.dshmobile.shell/files/usr/bin/node`；工作目录 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。Node子命令用 `/system/bin/linker64` 加Node路径启动；Python使用同目录python3并传-B。下表是父实际执行，不混入构建子代耗时。

| 项目 | 实际结果 | 父测耗时 |
|---|---|---:|
| 最终f764驱动健康 | exit0；23 green、0 RED；4个输入SHA/bytes逐条匹配 | 587ms |
| `--nc=readcount` | exit0 CAPTURED；19 green、4 RED；两按钮各替换2处 | 600ms |
| `--nc=probe` | exit0 CAPTURED；22/1；两按钮各替换1处 | 603ms |
| `--nc=init` | exit0 CAPTURED；22/1；初始化替换1处 | 601ms |
| `--nc=alive` | exit0 CAPTURED；19/4；两入口各删除1条Alive栅栏 | 618ms |
| 最终驱动装配防线 | exit0；健康前缀对照通过，16项预期R18_ERROR全捕获 | 186ms |
| 旧Lobby普通HUD/相机 | exit0 PASS；真实Lobby工厂，HUD与相机生命周期 | 600ms |
| inert入口生命周期 | exit0；Lobby9/0/162、Battle12/0/813，游戏子模块全inert | 620ms |
| 当前源码与六包编译 | exit0；42/42 PASS compile，无execute或skip | 1540ms |
| ID迁移与清单检查 | exit0；203旧ID、34来源与六包哈希匹配 | 109ms |
| 五入口纯mock路由 | exit0；14 unittest、无skip；不执行真实游戏工厂 | 2479ms |
| 最终门禁合同 | exit0；GREEN53；调用和文件写入均为VM模拟 | 518ms |

最终驱动健康及四NC合并SDK调用exit0/3198ms；四项NC的exit0只表示捕获预期断言红，不是突变后的健康通过。每次都核对四输入当前SHA与实际Buffer字节长度；五种装配哈希与之前相同，健康11755字节。此前c215版本已独立复验，但其fa9摘要只作被替代的历史记录，不用于最终构建。

16项防线为帮助段首/尾锚点各缺失/重复，以及四marker各缺失、独立行重复、注释重复；要求完整字面计数1和替换后0。父本次初始VM未补process.env，健康前缀先出现false!==true，exit1/174ms；那次不计防线通过。补齐env={}后从健康对照开始重新跑全部16项，具体anchor/literal count 0或2错误均被捕获，磁盘未写。更早草稿的4个注释重复漏检已修正，最终16/16。

本轮共享六套复验同样通过：工厂exit0/640ms，原生124/0/794ms，视觉预算7阶段300068断言/714ms，视口7/0/640ms，输入7/0/698ms，Acrylic9/0/732ms。预算三个额外调用计数均0；Acrylic装配SHA仍e8d9422b3ba7a784457a12bfbeb969fb9ee02860d0059ea537953cd5aa6ae383。门禁已从31接为32，只新增一次aotr-hud-contract-r18；53套合同和父5个内存承重对照见 `docs/RELEASE_GATE_PARENT_AUDIT_R18.md`。

## 构建、冻结和剩余验收

构建方只在最终f764驱动冻结后首次启动R18构建。两个独立原 `build.py` subprocess实际exit0/156.744ms与exit0/149.668ms，每轮读取六包和manifest原始bytes并作7份逐字节相等断言；详见 `docs/RELEASE_BUILD_HUD_R18.md`。父没有把阅读报告称为自己再次双构建，而是另行核对当前7份输出与报告逐轮记录、manifest消费来源及保护集合，再实际跑编译/迁移/路由/合同。此父独立合并审计exit0/4902ms，stderr空、无超时或截断。

| 当前输出 | UTF-8字节 | SHA-256 |
|---|---:|---|
| `dist/Vortexion_AOTR_Battle.lua` | 1525253 | a7be5e1e9cdafa749b222dd902176981bf10f48c49442f6c49e8e5bda0dbd227 |
| `dist/Vortexion_AOTR_Lobby.lua` | 1451940 | dde6698d3d344601f700c62e06e5190cec63251aa6a5b4425bcd086474b87b7c |
| `dist/Vortexion_BloxStrike.lua` | 1569870 | 2f24c39f7190dd511f9e6527aad5c76ed6dcf6b0683ddb36ffa33075a81e7391 |
| `dist/Vortexion_Forsaken.lua` | 1634842 | 861223dac1c27cb38ba2cdc7aad02153778420cb4c66327e30f527652c751eb5 |
| `dist/Vortexion_SCP.lua` | 1548556 | 0cea5fb7c75497426facdda17af06b35d8c86dc574572b1405a65bf77b02b572 |
| `dist/Vortexion_Wind.lua` | 1998321 | 5ce65d0a6abcac11ca785bc7c624d33905d2bf9055a56e70b4c766f7004d8010 |
| `dist/build-manifest.json` | 5047 | 691946afcce759a8fa64e896c2a33a266c8230b826c58d75ba2ba09e119ea6ec |

只有Lobby/Battle两消费源码相对R17变化；另外32来源由旧75保护摘要独立证明未变，当前34来源漂移0。BloxStrike/Forsaken/SCP三个独立包字节与R17一致；两AOTR包各增39字节，统一包增78字节。

| 冻结集合或关键文件 | SHA-256 |
|---|---|
| 旧75保护集合 | 4ff8abc3c1e3733e993d85ee37591fad02a25eb7324f05439eeb1aeefe00775b |
| 最终82输入集合 | d61f588bcc1cb730a56fb11ff9a8bc2371eb1e8d50167c6e814ecef7409ef37c |
| 父90文件集合 | d50f9f2bec060ce1df837596e49ab6ed6d0e1e45aaa67778bc5bc78ca28f7aed |
| 最终HUD驱动 | f76480f8c8d52770a56cde3dc698c8dcc775c4b9184ee4f7ccb71498b5c8a6aa |
| HUD测试body | 50934cd04ee8b40c4648a21d192376e1cb55ae0e00428d7e7645163a304a343e |
| 历史 `tests/release-test-results.json` | e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be |

集合摘要均是相对路径排序的[path,sha256]紧凑UTF-8 JSON再SHA-256。82=34消费来源+46根测试/ID基线+构建器/打包器；90=82+六包+manifest+历史发布JSON，不声称覆盖整个项目。75是R17原80排除本轮获准改的两HUD源、两门禁文件及旧Lobby模拟器；新增两HUD测试不属旧75。82在最终驱动五次复跑前后、构建方两轮前后相同；父90在当前编译/迁移/路由/合同前后逐项一致。历史release JSON原样，vendor和WindAdapter仍是已记录冻结字节。

清单 luau_compiler_tested=false、roblox_android_tested=false、status=local_build_unpublished、publication=not_published_to_github 保持原值。42编译成功不替代真实32阶段发布验收；203ID保留不等于功能语义完整。未重新跑完整Common/ESP/Movement/game py，旧报告计数已在HUD文档明确标为历史。无新集成ZIP，历史r8与外部原包保留。

探查点：self错位、缓存被强制扫描、销毁后晚回调、旧mock假红、装配注释重复漏检、最终驱动/构建冻结竞态。优化：只改两入口点调用和Alive栅栏，纠正两旧stub，4输入与执行Buffer同源核对，32阶段一次登记及53承重合同，最终82冻结后双构建。设备HUD树差异、触屏/渲染性能、完整发布和其他既有功能差异继续待验。
