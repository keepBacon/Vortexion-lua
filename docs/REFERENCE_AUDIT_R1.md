# 用户补充参考材料 / R1

范围：2026-10-17 上传的五组脚本（仅静态分析；没有执行第三方脚本）。

| 输入 | 观察到的主要内容 | R1 采用与边界 |
|---|---|---|
| `SCP角色扮演(2).txt` | Rayfield 界面；Combat/Character/ESP/Misc；自瞄 FOV、碰撞箱、骨骼线和服务器重进/切服；两个常驻 RenderStepped/Heartbeat 循环。 | 保留既有 SCP 独立子系统与 WindUI，**没有复制** Rayfield 与常驻循环。共享性能诊断用于调查帧循环代价；不宣称新 SCP 战斗功能已迁移。 |
| `Forsaken(2).zip` | 四个嵌套项目；Auto-Backstab V1–V3、Auto-Block V1–V4、Auto-Slash/Auto-Trick、Terio/角色脚本。 | 首先修复现有 Forsaken 常驻事件未释放及世界枚举分配问题；其他战斗算法尚未逐项适配，不能按文件名认定已迁移。 |
| `bloxstrike(2).zip` | BloxStrike UI 源码、主脚本以及数个独立 Lua 文件。 | 保留现有皮肤/武器/子弹/战斗子模块，利用按路由加载避免其他游戏模块参与启动；未复制参考中的隐藏 API 和动态加载代码。 |
| `Attack the Titan Revolution(2).zip` | AstaRoth、Zenaru、script.lua、main 和嵌套 Roblox-scripts 项目。 | 保留 AOTR 大厅/战斗两入口，复用旧项目对未识别场景的保护，新增按当前场景下载对应模块。未进行战斗功能真实性测试。 |
| `一些通用脚本(1).zip` | Aimbot-V3、AirHub、Exunys-ESP、MinimaHub、Open-Aimbot、Sp3arParvus、Vanity General 的源码与文档。 | 参考它们的分层与清理需求，优先建立独立 RuntimeMonitor 和可选性能节拍。没有执行外部入口，也没有拷贝算法/许可证受限资源。 |

R1 是基础架构与跨游戏可用性重构，不等于“所有参考内容已吸收”。
