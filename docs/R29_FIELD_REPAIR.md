# Vortexion R2.9: AOTR 目标池修复与 Forsaken 场景诊断

## 实机证据
- AOTR：`ChildRemoving is not a valid member of Model "Workspace.Titans"`。Luau AOTRTitans 工厂在初始化时抛错，导致其依赖的目标模块无数据。
- AOTR：`GET=true POST=true` 只证明远程对象可见，并不证明服务器接受命中/修理请求。
- Forsaken：界面仍显示“精简稳定版”，而 `Refresh=0 Markers=0` 在所有感知开关默认关闭时是正常的；仅凭截图无法证明按钮已被打开后仍无效。
- GitHub：制作补丁时 `main` 停留在 R2.7，R2.8 尚未上传，因此本包含 R2.8 + R2.9。

## 修改
1. AOTRTitans 改用官方合法事件 `ChildRemoved`，保留 ChildAdded 和连接清理；同步修正测试夹具中错误的虚构事件。
2. Forsaken 诊断增加容器中模型总数、拥有 Root 的候选数量、感知是否开关关闭。菜单/大厅中容器存在但无候选不再与 ESP 故障混淆。
3. 包含尚未部署的 R2.8 七项 Forsaken 客户端功能，并保留已发布的 R2.7 兼容修改。
4. 按游戏重建分体脚本，更新两个 manifest 的 SHA-256。

## 验证
- 12 个构建产物校验通过。
- AOTRTitans 实际源码 + 修正后的 Lua 模拟夹具：18 个场景 / 133 个断言通过（基于 Lua 5.4 转译，不是 Roblox 真机）。
- 87 个当前可运行 Python 测试通过；2 个过时测试导入已删除的旧 Forsaken 模块而失败，应先迁移后再作为门禁。
- R2.8 的 Forsaken 专项模拟：6/6 通过；R2.9 新增结构检查：4/4 通过。
- 未验证安卓真实服务器中的目标模型、服务器接受的行为、受限执行器 API、实际 FPS 或所有玩法。

## 使用
完成 GitHub `main` 更新后，请重新加载，进入 AOTR 战斗地图，在设置页点击「子模块初始化诊断」与「运行状态」。应不再出现 ChildRemoving 异常；若仍显示巨人=0，请提供 Titans 文件夹内容与游戏更新版本（不需要敏感信息）。

Forsaken 需要先进入实际一局，然后主动打开「杀手高亮」或「幸存者高亮」，再到系统页检查刷新与候选计数。若 Refresh 仍是 0，请附开关与诊断截图。
