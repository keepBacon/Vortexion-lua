# GitHub 发布信息与安全回退

- 目标公开仓库：`https://github.com/keepBacon/Vortexion-lua`（`main` 分支）。
- 单文件加载入口：`https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/dist/Vortexion_Forsaken.lua`。
- 只有实际提交、读取远程文件并对比 SHA-256 后，才可认定发布完成。
- 运行时仍依赖 Roblox 资源 `rbxassetid://132866968194043`。游戏内运行／安卓触控／FPS 尚未实测。
- 原 Goonsaken 入口与分支保留供回退；不要删除包含其他项目的 `Canvas-Linux-Ui` 主仓库。
- 传送后自动加载 `hubLoader` 暂时仍为 nil，待真机验证后再决定是否启用。
- Starlight 使用 CC BY-NC 4.0 非商业授权；Goonsaken 派生部分需要进一步核对原作者再分发许可。
