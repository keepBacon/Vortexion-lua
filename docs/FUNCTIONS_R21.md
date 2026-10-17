# R21：一小时窗口内继续补功能

## 本批代码

- AOTR新增燃气余量读取：父重读reference-inputs/aotr/Zenaru.lua:358、799-803，已证实PlayerGui.Interface.HUD.Main.Top["7"].Gas.Percentage；Common按精确非递归路径查找并复用两秒HUD节拍，ReadPercent只接收完整0..100十进制百分数，负值、混杂文本、越界、读取失败或脱离标签返回nil。大厅与任务各新增只读按钮，大厅复制状态包含燃气；路径缺失显示未读取，不猜另一套HUD路径，不改补给或远程请求。
- Forsaken新增VisualLocalSkinChoice与刷新按钮：仅用户点击时枚举现有Assets.Skins.Survivors.<当前角色>的直接资源名，去重排序，保持占位且校验白名单，不后台扫描、不自动开皮肤。统一名称变更入口，先回收旧clone再应用；同步输入框不重复重建；销毁/换角色后旧列表提交失效。原皮肤输入框与全部旧ID保留。
- BloxStrike新增本地程序式预览速度25..200%、音效音量0..100%，默认均100%；输入非数/NaN/无穷降级，合法数再限幅，默认音量不额外读Volume。只改变下一次程序式姿态持续时间和新建音效clone的音量，不是完整原始动画或游戏声音设置；没有增加帧连接。
- SCP新增屏外距离数字和独立1..64屏外数量上限（默认16，数字默认关），不占用原屏内预算；距离Text按需创建并池化，关闭数字立即隐藏、回屏内同时清旧箭头/数字，统一销毁回收，无Drawing时按能力降级。预算每次Update只清洗一次。
- SCP信息页新增普通视角复位：关闭相机辅助、重置触发、同步原开关，再为当前Camera绑定当前Humanoid并设Custom；中途卸载停止后续写，无角色/相机只说明现状，两属性写失败不报成功；不传送、不猜坐标、不添加悬浮窗。

5个既有stepfun-plan/step-5-preview low子会话分别独占ForsakenVisual、BloxStrikeCosmetic、SCPESP、SCPCore、AOTRCommon。父线程完成两入口接线、跨控件克隆重入、占位/白名单、预算与隐藏、限幅和视角生命周期的复杂集成。没有执行参考加载器或直接复制参考实现。

## 本批实际验证与边界

按用户先功能、暂不管测试的最新优先级，本批没有新增或执行Luau业务夹具、完整玩法或发布门禁，没有把R20的25/81或69套VM合同说成本批证据。只做父源码审查、42文件真实编译、203旧ID/六包来源与输出静态校验，以及实际两次python3 -B build.py（exit0，262/242ms）；六包和manifest七输出原始字节一致。

86输入为34消费来源、50个tests根脚本/ID基线、build.py与packager；排序紧凑UTF-8[path,sha]摘要 `aeb5f47ce5f66c3cdca171df750ede8abf5da3fe5e4d405d39d951666325c324` 在编译/双构建前后不变。七源码以外的79输入摘要 `ee2bf5e248d0cda2505b975a1160c2ab34eee9a077f812fcea9b64d76edcebfc` 保持，其他27来源相对R20漂移0；最终34来源与manifest匹配。tests、vendor、构建器、发布执行器、原始参考与历史包未改。历史release-test-results.json仍 `e111fcc93663e42e24a078314aadfcd9b3ce058da883b02fcb3913582568e7be`。

| dist文件 | 字节 | SHA-256 |
| --- | --- | --- |
| Vortexion_AOTR_Battle.lua | 1533351 | f853501a29b395532a513ebd1b025014be60665226fd14078acbe39e0f206bd8 |
| Vortexion_AOTR_Lobby.lua | 1461712 | 548225ef0096a32b5372512d645a64fb460d19576877f5a5e420822829663e6b |
| Vortexion_BloxStrike.lua | 1577034 | 23045b29f17519fc8360050415683f1fa8a3cf999896d459a5f6222ea7ead5d4 |
| Vortexion_Forsaken.lua | 1643365 | 9fc8f82d976e607eb11b41cb0dd099f1df6019958124acdccc18a51ba66be39c |
| Vortexion_SCP.lua | 1560437 | 18bc835016bc58a73acdb04aea69de19d4731437e6b701986bdf7ee6f74720d0 |
| Vortexion_Wind.lua | 2023547 | ac13507919f70f4c89cf5edfdae14a1d499f412ba75f163c310561d90b0ba137 |
| build-manifest.json | 5047 | f02eb7c20c54ab535d9173e40d1cc97f4a254fbdb074289f4d21e8294a8942a0 |

主入口dist/Vortexion_Wind.lua；原自动路由、通用仅低延迟切服和可折叠通用/游戏/UI分组保持。清单仍local_build_unpublished/not_published_to_github，luau_compiler_tested=false与roblox_android_tested=false；单独编译不替代完整发布证据提升，未生成新发布ZIP。

## 尚未完成

本批不是全目标完成：Auto-Trick/独立角色技能重做、完整原始动画/音效/手套主题仍有差异；燃气仅接已证实路径，其他HUD版本未验；标签/触屏/视角/资源在真实Roblox与Android上的渲染、时序、手感及FPS尚未验收。完整34阶段与本批业务回归暂缓，旧历史测试计数不迁移到新源码。整体goal保留active。

核查点：精确资源/标签身份、负值百分数、克隆所有权与回调重入、控件范围和卸载后尾；优化为手动枚举、一次重建、池化与即刻隐藏，不宣称实测手机性能提升。
