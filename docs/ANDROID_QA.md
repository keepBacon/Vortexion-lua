# Roblox 安卓真机验收清单（待验证）

1. 首次加载：可否通过游戏执行器加载 540KB 左右 Luau、并由 Starlight 取得 GUI 资源 ID；若失败收集执行器报错原文。
2. 主窗口：横竖屏缩放、点击标签、单指/惯性滑动、可滚到底、下拉框打开/关闭 50 次后是否顺畅。
3. ESP：红色杀手、绿色幸存者；无遮挡 80% 透明；隔墙 0% 透明；屏幕外不可见，返回视野时能正确计算；遮挡部分头部时保持判定一致。
4. 独立开关：总 ESP、杀手、幸存者、玩家名字与角色、生命/距离标签，全部组合开启/关闭。
5. 角色刷新：幸存者→杀手→死亡→复活；无限体力不会反复生成线程，关闭后能恢复原参数。
6. 功能回归：自动修机、前空翻、悬浮快捷菜单、设置页面、主题切换和配置保存/加载。
7. 性能：观察开启 ESP 与关闭 ESP 的 FPS/内存；打开 20 次菜单后检查是否累计出现额外监听与 UI 实例。
8. 离开/重进服务器：旧 GitHub URL 不能被自动加载；新链接发布并验证后方可启用自动重载。

所有项目目前均属于 **待真机测试**，不能把本地源码审计当作 Roblox 兼容验证。

## Touch v6 专项复测

1. 按住滑块圆点，从左到右连续拖动，松手后数值保持最后位置；手指离开控件范围后也应恢复滚动。
2. 在滑块附近纵向滑动：未在滑块上按下时应滚动页面；滑块拖动期间不得引发页面滚动。
3. 单指滚动左侧菜单到最底部，并快速切换玩家/游戏/其他，不应带着整个窗口移动。
4. 在触屏连续打开、关闭下拉框 20 次，观察是否有弹窗拦截其他按钮。
5. 反复开关发电机标签、已完成状态和总 ESP；切换回合确认无残留标签、进度实时更新。
6. 警报模式：检测 35 studs 内杀手；切换角色、离开半径、关闭警报后不应重复弹窗刷屏。
7. 对比 10 分钟游戏前后 UI 控件响应、FPS 和任务数量，若仍异常保存执行器日志与视频。


### v7 Toggle touchscreen QA (must be tested on device)

1. Tap the switch knob and also tap the left label area. Each tap must change the state exactly once.
2. Swipe vertically over several Toggle rows: content scrolls, Toggles do not activate.
3. Repeated quick taps (with and without a second finger) should never leave a stuck toggle.
4. Scroll down and back up, change tabs, close/reopen window, and ensure all toggles still work.
5. Repeat with gamepad / USB mouse, verify no duplicated callbacks.
6. Verify sliders still drag correctly, and ESP occluded=0%, visible=80%.
