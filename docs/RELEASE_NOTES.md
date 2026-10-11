# Vortexion - Forsaken · UI 品牌更新

- 正式项目名：`Vortexion - Forsaken`，公开仓库：`keepBacon/Vortexion-lua`。
- Starlight 项目主标题：`Forsaken`，右下略偏左使用 10px 浅灰 `- Vortexion`。
- 品牌副标题挂载在 Starlight 原生标题控件下，跟随 UIScale 与窗口移动。
- 保留 ESP 80%/0% 透明度规则、现有回调和稳定 ID，未修改其他游戏功能。
- 新构建产物：`dist/Vortexion_Forsaken.lua`，用于 GitHub `keepBacon/Vortexion-lua` 公开托管。

# 第二阶段变更记录

- **ESP 纠错**：墙体遮挡／屏幕外透明度 0%；无遮挡透明度 80%；被遮挡时高亮仍处于 Enabled 状态。
- **ESP 功能**：新增生命值和距离可选标签，限频 0.5 秒；阵营红／绿不变。
- **性能**：更新高亮对象的属性前先比较变化；修复 Starlight 下拉框每次开启都会增加 InputBegan 监听的问题；控制切换按钮双模板初始化时重复调用回调。
- **滚动**：禁用滚动的旧代码被修正，缩小时重新计算 CanvasSize，不再只增不减；小屏缩放下限可至 0.32。
- **构建**：已生成独立仓库结构与单文件 `dist/Vortexion_Forsaken.lua`。不再需要阶段一来源压缩包或 prepare_core.py。
- **来源**：没有将 c00lSaken、Mangz、Dora 或 OPAI 第三方原始主代码复制到拟公开仓库。
- **验证**：33 项静态检查及 16 组逻辑真值表通过。Luau 编译、Roblox 安卓端、GitHub 公开托管仍未验证。
