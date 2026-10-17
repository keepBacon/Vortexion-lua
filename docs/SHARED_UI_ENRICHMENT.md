# 共享 UI 增强与执行证据

本轮覆盖 `src/WindAdapter.luau`，游戏增强、全量构建和客户端实测另行验收。参考只提取交互设计；WindUI 发行库保持原样。

## 已实现

- 自动适配改由适配器统一管理，默认开启；同时处理视口旋转、摄像机替换、宽高控件与原生拖拽尺寸。手动模式保留用户缩放，全屏暂不干预；空摄像机和零视口保持原尺寸。比例向下保留两位小数，范围 0.1–1，双边预留 20 像素。极小视口受最小比例限制，仍需实机检查可访问性。
- 触屏默认侧栏 160 像素、桌面 200 像素；触屏默认关闭亚克力，但保留完整开关。新增一键简化视觉效果、适配当前屏幕，不增加通用业务页。
- 一次延迟任务合并连续布局事件；相同尺寸不重复写缩放或居中。摄像机替换立即断开旧观察器，不将旧连接持续追加到回收表；销毁后排队布局失效。
- 下拉列表内容未变化且原生状态未标记失败时跳过重建；失败允许相同请求重试。滑块精度与库的两位小数显示一致；异常数字、NaN、无穷和非法范围有明确处理，最终值仍落在原始边界。
- 文件写入、损坏配置、名称与列表异常保留诊断，并在 Debug 关闭时仍显示通知；自动加载门控和旧选项 ID 保留。

## 实际回归

执行 `node tests/run_luau.mjs --execute --factory src/WindAdapter.luau tests/test_wind_adapter.luau`，真实 Luau 工厂编译和模拟执行通过，退出码 0。

断言涵盖原生导航、回调恰一次、过时回声、配置门控、数字边界、列表去重、全屏/手动/空摄像机、销毁、存储失败及桌面/手机默认。30 次连续视口事件产生 1 次缩放写入；相同布局再发送 30 次产生 0 次额外写入或居中。连续替换摄像机 50 次后旧观察器断开，最终全部模拟连接断开。`tests/shared-ui-test-results.json` 是历史快照，未随本轮更新；当前冻结哈希与父独立结果见 `docs/SHARED_UI_FINAL_AUDIT_R16.md`。这些是调用计数，不是实机帧率测量。

## 集成边界

业务触控保留各游戏 Common 模块的所有权，四游戏按同一指针归属/稳定次序/起点与当前位置分离/失焦释放规范实现；本轮不强行注入新的共享触控工厂，以免改变现有模块装配协议。Wind 原生控件的滑动、输入、恢复按钮边界及真实 Android 行为仍按 `docs/WIND_ANDROID_QA.md` 实测。

## 原生接口复审进度

独立审查后补修并复跑通过：单轴宽高调整保留另一轴的原生拖拽尺寸；全屏中改尺寸先退出全屏；初次空摄像机等待最多 5 秒且可由销毁取消；初始配置列表异常只降级列表，不中断其他设置；初始化中断后销毁已拿到的窗口并禁止返回半窗口。

已覆盖的原生契约回归：`node tests/run_wind_native_contracts.mjs` 的 124 项测试通过（114 旧契约 + 2 视觉档位 + 3 安全区/生命周期 + 5 TopbarInset 监听）。新增 10 项契约：档位恢复驱动 `GetVisualInterval`、新桥恢复移动默认；销毁后 `GetVisualInterval` 仍有界、不调度恢复、不复活桥接；安全区受控居中：`GuiService:GetGuiInset()` 取 topLeft/bottomRight 两 Vector2 算四边 inset，中心目标 =(left-right)/2、(top-bottom)/2，用受控 Tween 移 Main 避 vendor 固定居中覆盖，Create/Play 失败或缺 Main 先取消旧 owned tween 再降级直写/延后不缓存，缺接口 inset=0 保持居中不报错，关闭即回 vendor 屏幕中心，销毁取消挂起尾。owned 居中生命周期：关闭自动适配/关闭安全边距/进入全屏/桥接失活/无相机/无效视口时统一 `cancelOwnedCenter` 取消挂起 owned 尾并清空 coalescing 缓存，使后续同几何 FitViewport 重跑而非信任陈旧布局；稳定重复几何不取消（避免连续相机/尺寸事件阻止居中动画完成）；手动「窗口居中」也先取消 owned 尾。TopbarInset 监听：`GuiService:GetPropertyChangedSignal("TopbarInset")` 只作重读 `GetGuiInset()` 的触发器（TopbarInset 是只读 Rect，不当坐标用、不保证覆盖所有硬件 inset），事件仅在 Active && SafeArea && AutoFit 时 requestLayout；安装 task.spawn 入口与 GetService/GetSignal/Connect 每次暂停返回后都检查 Active，晚到 connection 恰一次 Disconnect 且不入池；CreateWindow 在 install 后复查 Active，同步 executor 或重入销毁时不返回旧窗口/不清缓存外泄；事件突发同帧合并为一次 Fit；CreateWindow 尾主动尝试安装一次，与 SafeArea/AutoFit 开关无关；开关关时保留连接但事件不排队，不重复安装；全屏事件仍可排队，FitViewport 早退并取消 owned 尾；GetService/GetPropertyChangedSignal/Connect 缺失或抛错不影响初始化与显式 Fit；诊断显示「TopbarInset 监听: 是/否」；销毁释放监听与挂起布局。真 coroutine.yield 对照：fixture 让 Connect 在 install 协程内真实 yield（用 coroutine.running() 捕获 install 协程，避免被后续 task.spawn 覆盖），CreateWindow 先合法返回窗口；健康 resume 后订阅真实可 Fire 触发重定位，取消（yield 后 Destroy 再 resume）晚 connection 恰一次 Disconnect、不入 pool、强制晚回调不排队/无 Position 写、后续 CreateWindow nil；fake c:Disconnect 改为无条件计数 + Connected 另置，使「恰 1」等于调用次数（重复调用可见）。以上均为本地 fixture/编译结论，未过发布门禁、未进 dist、未真机。忙碌/聚焦期间只保存最后一次滑块请求，释放事件合并为一次延迟刷新；锁定不重试，新的原生输入优先，销毁取消排队写入。量化后重新限制边界，同步回调重入不传播旧值。配置子项异常被隔离；构造返回前的目录故障回收本次拥有的四个 GUI 与全部 Creator 监听，保留既存窗口。新增真实桥接工厂的健康构造协程对照与取消后的晚到返回/异常/空返回回归；恢复后先检查存活，取消时不再装配设置或注册监听，资源到达后独立回收，原异常保留、取消返回 nil，既存外部窗口/GUI/监听保持原样。进一步覆盖窗口已返回后的切服页与配置枚举暂停：健康恢复完成设置，取消恢复不添加控件/监听，晚到切服句柄恰一次停止，已经清理的窗口不重复销毁。半窗口不向外公布，关闭后清空缓存句柄。测试执行原始发行库选定控件函数体与可暂停初始化夹具，不是完整 Roblox GUI。

配置操作新增 26 项真实桥接回归：准备失败后重新创建候选，配置完整注册与选定后才公开 `bridge.Config`；单次进行中的文件操作阻止第二次点击重入，正常/异常完成都释放门禁。创建、准备、注册、选定、保存、加载、刷新与删除暂停后卸载，不追加调用或更新状态；手动加载暂停期间，旧自动加载入口仍无效。健康协程对照验证保存和显式加载完成。配置管理器为可暂停夹具，已模拟发行库创建阶段提前设置 `native.CurrentConfig` 与管理器缓存，桥层延迟公开不构成原生管理器事务。准备/注册/选定异常、改名失败、逐 ID 注册、文件异常与 false 返回后的重试均有直接断言；晚到创建的旧加载入口保持封闭，卸载后加载错误不再更改旧状态。已进入外部调用的磁盘副作用不保证撤回，真实文件接口行为仍待实测。

回调新增 20 项契约：卸载中止主回调与监听的后续分发，包括清理协程暂停时恢复旧事件；用事件代际阻止值变更后回到原值的重入重复，200 轮突发对照通过。监听数量在本轮分发前固定，期间追加的监听只初始化一次；相同值的幂等重入仍产生一次真正事件。卸载结束后释放监听与 Pending，晚到注册不留存；已关闭后恢复的回调/通知异常不更改旧诊断，原生设置返回后不读取已销毁值。健康协程、活动错误提示、清理重置和清理异常仍有对照。上述为真实桥接加仪器化接口的调用/保留引用断言，不是实机帧率或堆内存测量。

移动布局新增 20 项契约：缩放期间卸载、禁用自动适配或全屏后不再居中，布局重入不重复提交旧事件；相机/视口/窗口尺寸变化只排队一次最新适配，相机身份判断在旧视口读取之前。缓存仅在居中成功返回并且代际、状态、几何仍有效时提交；失败可重试，暂停返回不覆盖较新缓存。暂停居中后卸载不再读取失效尺寸，新增布局夹具逐例核对异步任务错误为零。健康暂停缩放/居中对照与 100 轮视口重入通过，每轮只完成一次最新布局居中调用。原生方法返回仅表示调用提交，不等于 Tween 动画结束。原生缩放/居中与失效相机均有局部仪器化；已经进入的原生调用可以完成，不保证撤回，也不把调用计数描述为实机帧率。

下拉刷新新增 20 项契约：成功返回并复查存活后才公开列表，异常保留最后已提交快照；原生部分失败后的同一列表与旧列表均可显式重建。SetValues 之间的暂停/重入请求串行处理，最新列表覆盖中间待办，单批最多 8 次同步重建再延迟续批；500 次嵌套请求合并为 2 次重建。卸载清空 RefreshPending，晚到返回不提交；失败清空批次待办，延迟失败保留通知并可重试。健康刷新、空列表、深拷贝与 Select 正常选择事件保持兼容，异步任务错误门禁仍为零。夹具执行原库 Callback、Refresh 提交尾段和 Select，但不执行完整菜单项/图标构建；并发 Select 与 SetValues 的菜单交错、真实图标资源与渲染仍待验证，不保证撤回已进入的原生调用，也不将重建次数当作实机 FPS。

## 共享视觉刷新契约（四游戏消费）

桥接新增 `bridge:GetVisualInterval(baseSeconds)`，只限制非关键视觉刷新（ESP/轨迹/高亮/覆盖层节流），返回 `max(sanitize(base), 1/VisualHz)`。`VisualHz` 有界 5..60；纯计算，不在每次调用分配表、不读控件、不重建。`sanitizeBase`：`tonumber` 失败（含非数字字符串）、NaN、±inf、负值归 0；可解析为有限非负数的字符串按该数处理（如 `"0.5"`→0.5）。`clampHz`：`tonumber` 失败（含非数字字符串）、NaN、±inf 取上限 60；否则 `floor(v+0.5)` 后夹到 5..60，故负值/过小值落下限 5、过大值落上限 60，可解析数字字符串按该数取整夹取。`max` 语义保证从不超过调用方自身节拍——"原速60" 只把高于 60Hz 的刷新压到 60Hz，不会把旧有更慢节拍加速。

档位：原速 60 / 均衡 15 / 省电 5 / 自定义（滑块 5..60）。默认 移动均衡、桌面原速（`input.TouchEnabled`）。选项落在 UI 组"界面"页（`wind_perf_tier`、`wind_visual_hz`），档位保存走原生选项配置（按 PlaceId 隔离的同一机制）。诊断页追加"视觉档位/视觉刷新 Hz(上限 60)"，只报实际档位与上限，不宣称实测 FPS。

四游戏必须按同一防御式模式消费，方法缺失时保留原节拍以兼容旧桥接/旧 fixture：

```lua
local function visualInterval(bridge, base)
    local getter = bridge and bridge.GetVisualInterval
    return getter and bridge:GetVisualInterval(base) or base
end
```

入口指针：Blox `ctx.UI`、SCP `common.UI`、AOTR `app.ui`、Forsaken `ctx.Fluent`（使用前以当前源码确认）。四路代理仅消费此方法、互不改源。禁止把该间隔用于移动、输入、回收或战斗/冷却频率——那些保持原频率。动态降档对新帧即时生效（每次调用现取 `bridge.VisualHz`），销毁后不再调度恢复。

## 移动可读性与安全区（实现与取舍）

可读性保护（`wind_readability_guard`，默认关）+ `wind_min_scale`（0.3–1，默认 0.5）：开启后 FitViewport 的 factor 取 `max(适配值, 最小缩放)`。取舍：窗口可能大于「铺满视口」尺寸（牺牲边缘留白换文字可读），可能裁切窗口边缘；用户可降低最小缩放或关闭保护；标题栏可拖、悬浮恢复按钮独立，但「核心入口始终可达」未在真机验证，不作保证。默认关闭，不改变既有缩放着色器与 114 旧契约定值。

安全区（`wind_safe_area`，默认关）：受控居中。读 `GuiService:GetGuiInset()` 返回的 topLeft/bottomRight 两 Vector2（官方 API，https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GuiService.yaml ）算四边 inset，中心目标 UDim2 偏移 =(left-right)/2、(top-bottom)/2（父级屏幕像素；vendor ScreenGui IgnoreGuiInset=true/ScreenInsets=None、Main AnchorPoint=.5、UIScale 在 Main 自身，offset 不乘除 scale）；用受控 Tween 把 Main 移到目标，避 vendor 固定居中动画覆盖；Create/Play 失败或缺 Main 先取消旧 owned tween 再降级直写/延后、不缓存未完成布局；无 GuiService/GetGuiInset 时 inset 记 0、保持居中、不报错（fixture 即此路径）；关闭即回 vendor 屏幕中心，销毁取消挂起尾。owned 居中生命周期：关闭自动适配/关闭安全边距/进入全屏/桥接失活/无相机/无效视口统一 `cancelOwnedCenter`（仅取消自有 Tween，不动 vendor 的 SetToTheCenter/拖拽/双击），并清空 coalescing 缓存让后续同几何 FitViewport 重跑；稳定重复几何不取消，避免连续相机/尺寸事件阻止居中动画完成；手动「窗口居中」按钮也先取消 owned 尾。inset 变化重读来源有三：显式 FitViewport、已有布局事件（相机/视口/输入），以及 `GuiService:GetPropertyChangedSignal("TopbarInset")` 订阅。该订阅在 CreateWindow 尾主动尝试安装（不以 SafeArea/AutoFit 开启为安装条件；无独立开关、只注册一次、销毁释放），仅作「重读 GetGuiInset」的触发器：不读 Rect 坐标当像素、不保证覆盖所有硬件 inset；事件只在 Active && SafeArea && AutoFit 时 requestLayout，突发同帧合并 1 次；关闭安全边距/自动适配时事件不排队；全屏仍可排队，但 FitViewport 早退取消 owned 尾，不写新布局；取服务/取信号/连接抛错均降级（不影响初始化与显式 Fit），销毁中晚到的连接恰一次 Disconnect 且不入池；诊断行「TopbarInset 监听: 是/否」。这是给 ScreenInsets=None 窗口人工预留 GUI 边距，未验证物理刘海/系统手势区；真实 inset、Tween 时序与拖窗双击（仍走 vendor 屏幕中心不含 offset）需真机核对（见 `docs/WIND_ANDROID_QA.md`）。

## Acrylic 模糊偏好同步（实现与取舍）

`bridge:CreateWindow` 仍恒传 `Acrylic=true` 给 vendor（底层模糊画布分配照常）。但 vendor `aw.Open`（vendor/WindUI/Source.lua:38574-38670）在 `task.wait(0.06)` 后于 :38667 无条件 `ToggleAcrylic(true)`，晚于 OnOpenCallback，无法用回调挡，真实开窗会覆盖触屏/用户 false 偏好。实现：在 bridge 自有所有权生命周期内 wrap `WindUI.ToggleAcrylic`——仅当 `self==WindUI` 且 `WindUI.Window==native`（当前自建窗口占槽）且 `bridge.Active` 且 `value==true` 且 `acrylicPref==false` 时把 value 改成 false；其他窗口/其他 self/失活/清除指令原样透传。安装只在 CreateWindow 一次（per-instance 保存原函数，不用模块级标记），cleanup 仅当 `WindUI.ToggleAcrylic==acrylicWrapper` 时归还原函数并把原函数转存 `acrylicForward`，使卸载后 wrapper 仍是可用 passthrough（外部委托 `local previous=WindUI.ToggleAcrylic` 后仍须调到真原函数改 model/blur）。`wind_acrylic` Toggle（默认触屏关/桌面开）Callback 只改 `acrylicPref` 并转发用户值；Close（vendor 强制关）只改 vendor 模型、不写 option.Value，重开按偏好恢复。

验证：新增 `tests/run_wind_acrylic_policy_r16.mjs` + `tests/test_wind_acrylic_policy_r16.luau`，直接装配真实 vendor `aw.Open`/`aw.Close`/`aa.ToggleAcrylic` 原样函数（非假想 Open），9 项 check：触屏真实 Open 挡（enable 0/Acrylic false/Transparency 1）、桌面 Open 放行（true/.98/enable>=1）、手动开关经 wrapper、真实 Close+Open 不污染偏好、重复 Open x3 每挡（prepareWindow 后捕获 baseline 断言 exact +3，构造期 emit 可能先烧 1 次不 mask）、旁窗占槽不受旧偏好污染、外部委托 Destroy 后仍 forward 真原函数、构造失败回滚归还、未来新实例再 wrap 生效；`makeBridge` 加承重断言 `wind.windowConfig.Acrylic==true`（prepareWindow 手注入 Paint 会掩盖分配开关回归）。fixture 无真实 AcrylicPaint/Au 模糊渲染/真实 Tween，blur 计数是闭包计数器（vendor 39720/39722 点调用 au.Enable/Disable 无 self，禁用冒号定义）；fixture≠真机。

集成门禁 `node tests/run_release_checks.mjs` 的 27/27 阶段、四游戏专项、切服 22 项、路由/构建 14 项、旧 203 个选项 ID、源码/六包哈希及 42 个 Luau 文件编译，以及「本轮源码进入六个 `dist`」，均为**历史 r8 证据，非本轮、当前未重建**；本轮未运行发布门禁/build/packager，`dist` 未随本轮共享 UI 更新。详细历史输出在 `tests/release-test-results.json`，需父统一重建 dist 后复验。

审计询问点：最小比例下的可访问性、键盘弹出、原生拖窗与滚动争用、全屏恢复及重复加载。本轮普通共享 UI 离线回归已冻结验收（见 `docs/SHARED_UI_FINAL_AUDIT_R16.md`），**整体发布验收尚未完成**；客户端实测仍独立于上述编译与模拟结论。
