# R46 压缩包使用说明

## 运行入口

解压 `Vortexion-lua-main.zip` 后，工程位于 `wind-project/`。使用 `dist/Vortexion_Wind.lua` 的完整脚本作为统一入口；已内嵌 WindUI 1.6.66 与游戏模块，按 GameId/PlaceId 自动路由。五个专用包保留在同一 `dist/` 目录，通常无需分别执行。

此交付尚未发布到 GitHub；不要用默认 `loader.lua` 的远程地址代替包内入口。普通 Lua/Python 终端不是 Roblox 客户端运行环境。WindUI 图标、游戏资产和可选第三方功能仍有网络及客户端能力依赖，单文件不等于全部功能脱网运行。

自动切服与新增外观同步默认关闭；首次打开不自动加载配置。未知游戏显示通用/UI及场景说明，不套用其他游戏战斗模块。窗口重复执行、关闭和重开已做离线生命周期回归；真实设备表现另行验收。

## 可选本地音频

包内 `assets/forsaken/TerioThings/` 含 `sil_whip.mp3`、`lance_swing.mp3`、`coagulate.mp3`。执行器的 workspace 中应有同名 `TerioThings/` 目录及三文件，即运行时路径 `TerioThings/sil_whip.mp3`、`TerioThings/lance_swing.mp3`、`TerioThings/coagulate.mp3`。只解压到下载目录不等于已部署到执行器 workspace。

音效默认关闭；对应能力依赖 `isfile` 与 `getcustomasset`。缺能力或文件时，资源音效状态显示原因；这三文件不代表十二项缺失参考音频已经补齐。凝血音频目前仍是本地手动预览，不是聊天同步全演出。

## 归档检查

在 ZIP 和 `.zip.sha256` 所在目录执行：

```sh
sha256sum -c Vortexion-lua-main.zip.sha256
python3 -m zipfile -t Vortexion-lua-main.zip
```

包内 `release-package-manifest.json` 列出各成员的字节数与 SHA256；`tests/release-test-results.json` 记录固定34阶段证据及源码、测试、六包哈希。SHA256用于核对交付一致性，不代替实机验收。

## 开发重建

以下命令在解压的 `wind-project/` 内执行，需要 Python 3、Node.js、Lua 5.4。Node 依赖固定为 `luau-web@1.5.1`，未把 `node_modules/` 放入 ZIP：

```sh
npm install --ignore-scripts --no-audit --no-fund
node tests/run_release_checks.mjs
```

完整门禁先重建六包；任一失败、跳过或输入漂移均不计通过。可用 `NODE_BINARY`、`PYTHON_BINARY`、`LUA_BINARY` 指定解释器；Android 链接器启动另见 README。

## 已验证与待验

R46修复移动回归夹具的异步/清理错误漏报，保留19个健康场景，并以两个独立 fresh-VM 负对照证明错误确实被捕获。角色生产实现沿用R45，不将隔离原型混入发布包。完整门禁、干净解压和六包重建的最终结果见随包发布说明。

Roblox PC/Android、真实触控、网络资产权限与游戏实时行为尚未实测。验收步骤见 `docs/WIND_ANDROID_QA.md`；剩余参考覆盖见 `后续任务.md`，不把本轮ZIP交付表述为整体功能全部完成。
