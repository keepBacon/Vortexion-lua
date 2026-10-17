# 通用参考覆盖与实现验收清单

## 审计边界与结论

活动项目：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/wind-project`。参考根：`/data/data/com.dshmobile.shell/files/home/Vortexion-lua/reference-inputs/common`。本文中 `wind-project/...` 与 `reference-inputs/...` 均相对于 `/data/data/com.dshmobile.shell/files/home/Vortexion-lua`，路径含行号表示本轮读取时的源码快照，主线程修改后应重新定位。

本轮只用 glob、grep、read 进行静态取证；没有执行任何参考源码、loader、远程执行器或混淆样本，没有下载远程依赖，没有改动 src/build/dist。没有运行游戏，因此“源码已存在”与“运行验收通过”分开记录。本文只交付可复用设计和缺口，不迁移第三方源码。已有 cloak 维持现状，不增加检测规避。

导航约束：通用区保留且仅保留低延迟切服业务页；UI 设置放 UI 分组；SCP/BloxStrike/Forsaken/AOTR 各自承担游戏业务。共享主线程负责 `WindAdapter` 的移动布局与输入归一化，不把参考通用工具箱塞进通用区。当前实现符合这条导航约束：`wind-project/src/WindAdapter.luau:255-275`。

## 七项目证据矩阵

每行的关闭条件见后面的测试编号；P0 表示已观察到静态逻辑矛盾，P1 表示性能/生命周期改进或高价值覆盖，P2 表示体验增强与证据补齐。优先级不是实测严重度。

| ID / 参考 | 具体证据 | 可复用设计（重新实现） | 现项目覆盖、缺口与责任 | 验收 |
|---|---|---|---|---|
| C01 / AimbotV3 | `reference-inputs/common/Aimbot-V3-main/Aimbot-V3-main/src/Aimbot.lua:391-432`：按键按住/切换状态，TextBoxFocused/FocusReleased维护 Typing；`:440-461`断连与移除绘图 | 输入层统一区分按住/切换、文本焦点、释放与销毁；不要照搬其释放时也跳过 Typing 的行为，以免状态卡住 | `wind-project/src/SCPCommon.luau:112-133`没有UI输入过滤且Drag运算错误；`wind-project/src/AOTRCommon.luau:199-220`同类错误。共享主线程归一化，游戏端仅消费意图。P0 | T01、T02、T03 |
| C02 / AirHub | `reference-inputs/common/AirHub-V2-main/AirHub-V2-main/src/Main.lua:1085-1117`：配置列表、名称、手动加载、保存/删除后刷新 | 配置操作显式化、列表刷新、错误可见；只借交互设计，继续使用Wind原生配置 | `wind-project/src/WindAdapter.luau:210-243`已有按能力降级、命名校验、手动Load门控、保存/删除。缺少真实文件异常/损坏配置的运行证据。P1，共享主线程 | T10 |
| C03 / ExunysESP | `reference-inputs/common/Exunys-ESP-main/Exunys-ESP-main/src/ESP.lua:2342-2365`按对象解绑所有连接/绘图；`:2375-2382`共享摄像机参数并处理PlayerRemoving；`:2414-2423`玩家与角色事件 | 同一实体一个记录、成组资源所有权、离场原子清理、帧级摄像机快照。不要迁移其每种视觉单独连接的实现 | `wind-project/src/SCPESP.luau:146-150,350-389`已有池及移除回收；`:244-245,303-304`混合Player/Model键又按Player取Character，NPC第二帧有静态类型冲突。P0，SCP线程 | T05、T06 |
| C04 / ExunysESP | `reference-inputs/common/Exunys-ESP-main/Exunys-ESP-main/src/ESP.lua:2140,2152,2183,2263`：逐对象RenderDistance与距离门控 | 统一实体过滤结果；距离单位studs、来源明确；廉价屏幕裁剪与低频文本/健康更新分层 | `wind-project/src/SCPESP.luau:240-258`已有20Hz更新和每帧距离门控，但距离取摄像机；`wind-project/src/SCPCandidates.luau:69-81`取本地根并投影；SCPESP又重复解角色/投影。定义摄像机/玩家距离用途后复用候选快照。P1，SCP线程 | T04、T07 |
| C05 / MinimaHub | `reference-inputs/common/MinimaHub-main/MinimaHub-main/README.md:3,12-16`宣称视觉/物理分离、可见/遮挡颜色及名称健康距离；`reference-inputs/common/MinimaHub-main/MinimaHub-main/MinimalHub.lua:1`与`reference-inputs/common/MinimaHub-main/MinimaHub-main/OtherScripts/MinimaHub-ViolentDistrict.lua:1`均单行混淆 | README仅作需求候选：可见性颜色、标签、分频调度；不据此宣称缓存或触控实现可靠 | 当前SCP已分Heartbeat与render：`wind-project/src/SCPCore.luau:179-185,299-333`；参考混淆源码未展开/未执行，能力实现证据缺失。四游戏线程按适用对象补测试；不加入无关ViolentDistrict游戏。P2 | T07、T12 |
| C06 / OpenAimbot | `reference-inputs/common/Open-Aimbot-master/Open-Aimbot-master/source.lua:1751-1754,1799-1802`文本焦点；`:1816-1829`窗口失焦状态 | 失焦、UI关闭、角色替换均清除临时输入状态；文本焦点抑制业务Begin但仍接收已持有指针End | `wind-project/src/BloxStrikeCommon.luau:119-146`已过滤processed、限制右半区、独立origin/pos并稳定排序；仍是游戏私有重复实现，未见失焦清零。SCP/AOTR应消费同一共享策略。P0/P1，共享主线程 | T01、T02、T03 |
| C07 / OpenAimbot | `reference-inputs/common/Open-Aimbot-master/Open-Aimbot-master/source.lua:2305-2359`跟踪对象与连接分组回收，`:2362-2365`按UserId存角色条目 | 稳定身份映射+角色代次；角色重生时旧记录清理，连接随实体销毁而非等全局卸载 | `wind-project/src/BloxStrikeVisual.luau:39-44,68-88`已记录Highlight和Ancestry连接；全局线程可用计数确认重进不会累积。现SCP trackConns需离场逐实体回收证据。P1，各游戏线程 | T06、T09 |
| C08 / Sp3arParvus | `reference-inputs/common/Sp3arParvus-main/Sp3arParvus-main/Sp3arParvus.lua:3615-3675`拖动起点、窗口边界夹取、排除交互子控件；但`:3622,3655,3666`只处理鼠标 | 复用拖动边界与控件归属思路；它不是已验证的移动触控方案 | `wind-project/src/WindAdapter.luau:276-293`已有TouchEnabled缩放、ViewportSize/CurrentCamera监听；`:182-187`手动尺寸变更只居中，未重算factor；最小factor=0.3对极窄viewport可能仍越界。共享主线程明确自动/手动缩放模式与安全区。P1 | T08 |
| C09 / Sp3arParvus | `reference-inputs/common/Sp3arParvus-main/Sp3arParvus-main/Sp3arParvus.lua:2373-2386,2412-2418,2426-2442`修改前记录CanCollide/CanTouch/CanQuery/透明度，撤销恢复原值并清表 | 属性修改账本：首写前快照、实体代次、关闭/卸载恢复、每个失败独立处理；只提取恢复模式，不移植其世界破坏功能 | `wind-project/src/BloxStrikeVisual.luau:112-134`已有Lighting备份；`wind-project/src/ForsakenVisual.luau:45-99`已有备份恢复却每帧重写并含自赋值。四游戏逐功能验证原值恢复，避免固定默认值“恢复”。P1 | T09 |
| C10 / Vanity | `reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/UI.lua:168-194`鼠标/触屏指针与移动共用路由；`reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/Movement.lua:201-202`processed/UI抓键过滤 | 集中接收输入、明确UI/游戏指针归属与消费者，不在每个功能重复创建全局监听 | `wind-project/src/WindAdapter.luau:10,47-65,276-293`有输入服务、回收与布局监听，尚未提供共用指针状态；SCP/AOTR/Blox各自Touch。共享主线程实现业务意图接口，保持UI原生控件。P0 | T01、T02、T03 |
| C11 / Vanity | `reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/Candidates.lua:46-87`一次全树预热+Model延后检测+增删事件；`:93-99`多种Root回退 | 事件驱动实体索引、初始化覆盖嵌套层次、延迟构造、动态Humanoid加入、移除立即失效；参考`:84-85`未保留连接句柄，因此不要照搬回收弱点 | `wind-project/src/SCPCandidates.luau:159-175`Model新增即时判定+2s顶层GetChildren，漏嵌套迟到Humanoid；`:89-90`无Camera保留旧Pool；`:102-115`先按玩家枚举截24。SCP线程独立修索引/代次/空帧与稳定限额策略。P0/P1 | T04、T06 |
| C12 / Vanity | `reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/DrawingESP.lua:113-149`能力缺失一次通知、死/无角色隐藏、离场删除、统一Cleanup | 部分能力降级而非整模块失败；绘图对象隐显与销毁分离 | `wind-project/src/SCPESP.luau:44-77`创建Line捕获异常，但createBox第三次失败未回收前两条；`:312-335`NPC非refresh帧直接销毁；`:269-288`关闭单项视觉缺少显式hide路径。P0，SCP线程 | T05、T11 |
| C13 / Vanity | `reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/Visuals.lua:22-30,43-51,78-99`备份/关闭还原/约1s纠偏；`reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/src/Hitbox.lua:18-35,47-53,78-87`离开候选也恢复 | 低频属性差异纠偏+候选离场恢复；快照仅属于当前实体代次 | `wind-project/src/ForsakenVisual.luau:62-84`每帧重复Lighting写入，应保留既有值与功能效果、改为变更/低频校验；AOTR回收注册本身失配见缺陷D02。P1/P0，各游戏线程 | T09 |

## 主线程应先处理的静态缺陷

这些是读取时观察到的源码行为，尚未提交修复，也未执行Roblox复现。

| ID / 优先级 | 证据与触发链 | 最小实现要求 | 关闭证据 |
|---|---|---|---|
| D01 / P0 | `wind-project/src/SCPCommon.luau:112-117,130-132`和`wind-project/src/AOTRCommon.luau:199-204,217-219`：Moved覆写当前位置，Drag用当前位置减input当前Position，通常得到零；第二指是标量Y减Vector3 | 保留origin/pos独立值，二维/标量运算，按到达次序选择指针；归入共享WindAdapter意图层 | T01实际源码工厂fixture，非另写一份算法模型 |
| D02 / P0 | `wind-project/src/AOTRCommon.luau:106`的`app.OnCleanup=function() app:OnStop() end`吞掉fn；`:182`定义`function app:OnStop(fn)`，`wind-project/src/AOTRESP.luau:181-183`点调用把fn当self | 统一约定并兼容既有注册调用；OnCleanup传递fn；游戏线程修调用者，避免共享线程越界改AOTR业务 | 注册3个回收器，Stop后各执行1次，第二次Stop无效果；Touch所有连接归零 |
| D03 / P0 | `wind-project/src/SCPESP.luau:244-245`所有pool键当Player；`:303-304`加入Model；`:312-335`把refresh和有效性合为一个条件，非刷新帧销毁NPC绘图 | 分Player/NPC池或有kind的统一记录，所有身份分支一致；非refresh只做廉价cull，不销毁活实体 | NPC开启连续10帧、20Hz、ToggleNPC开关，零非法Character访问且对象数量稳定 |
| D04 / P0 | `wind-project/src/SCPESP.luau:71-77`createBox任一Line失败立即return；此前分配资源丢失 | 创建事务：所有子对象成功才提交，失败回收已分配资源；其他组合绘图同样检查 | Drawing.new第3次故障：Create=2/Remove=2，live=0；后续Highlight仍可用 |
| D05 / P1 | `wind-project/src/SCPCandidates.luau:89-90`空Camera返回前未清Pool；`:102-115`枚举前24截断，`:159-175`仅Model事件+顶层补扫 | 空帧清理、稳定选择/明确限额策略，嵌套与迟到组件事件补齐；索引线程受session代次约束 | T04、T06 |
| D06 / P1 | `wind-project/src/SCPESP.luau:253-255`拿到onScreen但没有使用；`:269-288`只在开关为true时写/显；`wind-project/src/SCPCore.luau:289-313`把dt<0.004描述为hitch，实际代表高帧率短帧 | 明确屏幕内定义；单项关闭立即hide/移除Chams；预算/刷新基于elapsed累积而非把高帧率当卡顿 | T05、T07，在dt=1/300持续情况下仍更新且不会长期冻结 |

## 实现边界与分层顺序

1. 共享主线程：给WindAdapter增加可销毁的输入意图服务。状态至少包含指针ID、序号、起点、当前位置、UI归属、文本焦点与Held；Begin只接未被UI占用的业务指针，End无条件结束已跟踪指针。失焦、销毁、旋转/摄像机替换及业务禁用重置意图。不同游戏只订阅各自作用域；不要把任何触屏按住都当触发。
2. 四游戏线程：消费归一化输入；各自拥有实体索引/候选快照/ESP实例池/属性账本，实体代次变化立即清旧记录。距离和可见性规则由游戏决定，不让共享布局适配器接管游戏世界规则。
3. 游戏线程：先修D01-D04再补视觉功能；缓存发现慢、坐标/候选快照快、标签低频、隐显立即、物理Heartbeat。性能调节只降低非关键视觉刷新，不让回收或关闭状态延迟。
4. 主线程：确认UI新增项有稳定ID、明确默认值、能力降级反馈、配置保存/恢复契约。既有功能与ID全部保留；新增功能只放游戏页或UI分组，不新增通用游戏功能页。

参考能力扩展候选：SCP/Blox/Forsaken的对象标签可考虑名称、健康、距离、队伍颜色、Tracer、骨架、屏内/屏外可见性；AOTR对象是Titan，使用既有boss/normal/后颈与健康标签，不把Player团队过滤硬套到Titan。每项先对照各游戏线程自己的参考矩阵；本文不宣称七项目功能并集已实现。`wind-project/src/AOTRESP.luau:112-158`已有Titan实体复用、距离与健康、seen清理；`wind-project/src/BloxStrikeVisual.luau:51-105`已有20HzHighlight和距离过滤，超距销毁频繁跨边界可能产生分配抖动，可用隐藏复用与上限管理替代。

## 可执行验收向量

以下是主线程实施/测试清单，不是本轮已运行的结果。fixture应装载当前项目单一工厂，不装载参考loader；对引擎事件、InputObject可变Position、绘图失败、连接计数使用mock。不要以源码字符串匹配或另写算法模型代替实际业务函数。

| 测试 | 输入/操作 | 断言与观测 | 所属 |
|---|---|---|---|
| T01 指针运算 | 指针A (100,200) Begin后可变Position变(130,180)并Moved；指针B (200,300)到(200,340)；改变pairs枚举次序；先抬A再抬B | 单指drag=(30,-20)，双指vertical=40（方向符号由公开契约固定）；稳定首/次指，无类型异常；最后Held=false；重复End幂等 | 共享 + SCP/AOTR/Blox消费者 |
| T02 UI争用 | UI滑块、滚动、弹窗、TextBox、恢复按钮手势；同InputObject同时收到InputBegan/TouchStarted，End来自两渠道；释放时文本焦点已变化 | UI操作正常且业务Held不误开；同一指针一次捕获/一次释放；滚动不激活业务；已捕获指针在TextBox聚焦后仍可释放 | 共享WindAdapter |
| T03 生命周期输入 | 业务按住后窗口失焦/Destroy/角色替换/旋转；清理后发旧Moved与异步回调；重建20次 | 意图归零，旧回调不修改新会话，所有旧连接断开，活跃监听数回基线；业务关闭后不继续速度/瞄准输入 | 共享 + 四游戏 |
| T04 候选索引 | 25+玩家，第25名最近；嵌套NPC先Model后延迟Humanoid；Camera有→nil→新实例；角色根替换、删除 | 策略确定且不永久忽略新增实体；空Camera返回空快照、没有旧目标；迟到Humanoid加入且删除即失效；避免每帧全树扫描 | SCP；同策略按需复用四游戏 |
| T05 ESP隐显/代次 | 玩家+NPC连续10帧，每帧dt=1/60；20Hz刷新；Box/Health/Skeleton/Tracer/Chams逐一开关；NPC标记整体关闭；对象死亡/出屏/超距/重生 | Model键无Character访问；非刷新帧不重建；关闭项即隐藏，关闭NPC移除或隐藏NPC专属视觉；旧实体无残影；屏外过滤契约一致 | SCP |
| T06 实体回收 | 新增/退出玩家及CharacterAdded/Removing各20轮；嵌套NPC与延迟组件；销毁后才执行defer | 每实体连接/对象计数回基线，Drawing Remove和Instance Destroy各至多1次；缓存无离场引用；旧defer不复活已销毁服务 | 四游戏 |
| T07 刷新/预算 | dt=1/30、1/60、1/120、1/300及一次0.2s；玩家近/远、镜头独立移动；可见性开/关、遮挡变化 | 关闭可见性检查时Raycast计数=0；开启时按实体/样本预算有界并记录调用计数；无功能启用时不做重型扫描；距离来源一致；300Hz不长期冻结；文本写入变化/刷新时发生 | 四游戏 |
| T08 移动布局 | 360x800、800x360、320x568、240x320；手动改变窗口宽高；Camera更换20次；最小化/恢复按钮拖到边界 | 窗口与恢复按钮在安全区，横竖屏可访问最后控件；自动/手动缩放行为明确；摄像机旧连接已断且registry不无限累加；控件交互与滚动不被拖动抢走 | 共享WindAdapter，真实Android补验 |
| T09 属性回滚 | Lighting/CanCollide/透明度/FOV原值设置非默认；开关20次，NPC变队/死亡，卸载；某一个恢复写入抛错 | 快照首写前保存，按当前实体代次恢复；失败不阻止其余恢复；第二次Stop幂等；低频纠偏与全帧写入计数对比记录 | 四游戏 |
| T10 配置契约 | 文件API缺1项、delfile缺失、空/非法名称、未知选项、坏文件、Save/Load/Delete抛错；创建配置触发旧__autoload异步Load | 会话UI继续可用；只显式Load执行；Save不触发Load；LastError/状态可见；游戏默认不被暗中开启；PlaceId隔离；稳定ID清单不丢失 | 共享WindAdapter |
| T11 能力降级 | Drawing缺失、table/userdata两型、第三条Line失败、clipboard缺失；局部工厂初始化异常 | 失败资源全部回收；仅禁用依赖该能力的视觉，不使Highlight/UI全部失败；错误一次或有节流；卸载无残留 | 共享 + 四游戏 |
| T12 全功能清单 | 用当前option IDs逐项登记：默认→启用→参数极值→禁用→重生→卸载→重载；异步功能加入取消/重入/远端失败 | 每ID对应实际callback和业务效果断言、回收断言；区分静态、mock、Roblox PC、Android四种证据。未运行项留“待验证”，不写“全功能测试通过” | 主线程集成 + 四游戏 |

性能记录用对象/连接/Raycast/扫描/属性写入计数为主；真实帧时由设备实测，避免把预设1ms预算写成已达标。每个新增开关绑定一个测试编号和一个停止路径。

## 现有测试与未执行样本记录

`wind-project/tests/test_touch_v8.py:2,6-9,49-50,65-66`明确是Starlight源码/独立手势模型，且执行会写dist测试报告；本轮未运行。它不证明当前WindAdapter或SCP/AOTR触控正常。`wind-project/tests/test_wind_adapter.luau:9-27,30-45`使用自建信号和Wind mock，目前输入服务仅TouchEnabled，缺少上述真实可变InputObject及UI归属覆盖；应在主线程的新专属fixture扩充。`wind-project/tests/run_luau.mjs:29-30`只在带--execute时执行装载结果；编译通过不证明运行回收/引擎行为正确。本轮未运行该runner，也未新增重复测试脚本，避免写出仅复制算法的假回归。

| 样本 | 静态观察与本轮处置 |
|---|---|
| AirHub加载入口 | `reference-inputs/common/AirHub-V2-main/AirHub-V2-main/src/Main.lua:28-32`有远程loadstring依赖；只读，未请求远程内容、未执行 |
| Exunys依赖 | `reference-inputs/common/Exunys-ESP-main/Exunys-ESP-main/src/ESP.lua:45,54,84`远程加载辅助/配置/绘图；只读，未执行 |
| OpenAimbot入口 | `reference-inputs/common/Open-Aimbot-master/Open-Aimbot-master/source.lua:289-297,2399`远程UI/模块与传送队列；只读，未执行 |
| Sp3arParvus入口 | `reference-inputs/common/Sp3arParvus-main/Sp3arParvus-main/Sp3arParvus.lua:10025-10038`本地/远程loadstring入口；只读，未执行 |
| MinimaHub | 两个`.lua:1`混淆样本仅识别头部，README仅为声明证据；未执行、未解混淆、不据此证明实现行为 |
| Vanity loader/混淆产物 | `reference-inputs/common/Vanity-General-Roblox--main/Vanity-General-Roblox--main/release/loader.lua:7-20`远程HTTP多后端入口只读；dist/VanityGeneral_OBF.lua仅发现路径，未读取/未执行。设计证据来自src明文 |

审计询问点：UI与业务指针归属、距离来源、候选限额策略、视觉低频与立即隐藏边界、属性快照代次、回收API调用约定、真实Android验证。优化方向：集中输入、事件索引、候选快照复用、事务式资源创建、逐实体回收、低频差异写入；关闭状态和回收不受性能节流延迟。
