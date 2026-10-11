# 独立 GitHub 仓库发布（待执行）

目前连接的 GitHub 插件具有读写**已存在**仓库的文件能力，但没有 `create_repository` 创建仓库操作，因此无法由 ChatGPT 在本轮直接创建新仓库。

1. 在 GitHub 创建公开空仓库，例如 `keepBacon/Vortexion-Forsaken`，不要勾选额外 README/LICENSE 以避免冲突；确保 GitHub 插件已授权访问新仓库。
2. 将此源码工程除 `tests/` 生成缓存外的文件上传至新仓库。首先核实 Starlight CC BY-NC 非商用授权和 Goonsaken 上游分发授权。
3. 检查 `dist/Vortexion_Forsaken.lua` 的 SHA-256 与下载下来的 GitHub raw 内容完全一致。确认 Starlight 资源模型成功加载。
4. 独立仓库上线、真机测试通过后，再更新 `src/ForsakenCore.luau` 中的 `hubLoader` 地址以启用传送后重新加载，重新构建、发布和验证。
5. 最后才删除 `Canvas-Linux-Ui` 中 `goonsaken-mobile-zh` 旧分支。不允许删除 `Canvas-Linux-Ui` 整个仓库：它包含无关项目。

此文档不是发布成功声明。新仓库创建、代码推送、旧分支删除均还未完成。
