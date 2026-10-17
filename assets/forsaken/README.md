# forsaken 音频资产包

本目录只存放已证实的 Forsaken 音频文件，供本地表现层使用。dist 构建为单文件，不带二进制；如需音效，请把 `TerioThings/` 整个目录放到执行器 workspace 下（与脚本同级的相对路径），`getcustomasset("TerioThings/sil_whip.mp3")` 按执行器 workspace 相对路径解析。

## 文件清单（3 个）

- `TerioThings/sil_whip.mp3`，61440 字节，sha256 7f35d7cc07d52d3cb770f9b85d06feee41339e9234ea11f7e5510752c08b8a7b。参考用法 Sil_Raw.lua:253-264：挥鞭动画（116814116277716）播放后约 0.45s，Sound 挂 PlayerGui，PlaybackSpeed 1、Volume 1.5、Debris 2s。本项目已接入该动画观察器；真实函数离线mock验证延迟、失效取消与声音回收，Roblox播放仍待验。
- `TerioThings/coagulate.mp3`，41760 字节，sha256 6a46e12c76812c437d86336d2b8b1272b76fd9d6af5b02f3ab809f11f254124e。参考用法 Terio_Survivor.lua:240 定义 coagulatesfx、:1082-1088 用于 E 键凝血技能（freezePlayer 后 task.wait(2)，PlaybackSpeed 1.5、Volume 1.5、Debris 2s）。本项目仅手动本地预览，不冒充凝血技能。
- `TerioThings/lance_swing.mp3`，50688 字节，sha256 2e4742e14585772e8f0c2ea0834150df95f0c973f97b540a88370e109b0135e5。参考用法 Terio_Survivor.lua:239 定义 piercesfx、:1158-1164 用于挥砍技能（先等待 0.5s，再紧邻播放声音与 slashTrack；动画观察器额外延迟为 0，PlaybackSpeed 2、Volume 1.5、Debris 2s）。Terio_Survivor.lua:965-966定义该动画为84413781229733，:1153装载并于:1165播放；本项目已按零额外延迟接入观察器，离线mock通过，非原完整挥砍技能。

三个文件均由本地参考副本原样复制，未修改原件，大小与 SHA256 已逐一核对一致。大小、SHA、来源与缺失情况以 `asset-manifest.json` 为准。

## 缺失资源（12 个，尚未提供，UI 应显式标缺，不用其他音频顶替）

- resentment.mp3（1x4TwoTimeSkin.lua:20，Themes 主题 rbxassetid://97690757653206）
- phoenix.mp3（1x4TwoTimeSkin.lua:22，Themes LastSurvivor）
- TerioThings/sil_layer4.mp3（Sil_Raw.lua:318）
- TerioThings/sil_layer1.wav（Sil_Raw.lua:320）
- TerioThings/sil_layer2.wav（Sil_Raw.lua:322）
- TerioThings/sil_layer3.wav（Sil_Raw.lua:324）
- TerioThings/sil_terio_lms.mp3（Sil_Raw.lua:327）
- TerioThings/lmsan_e.mp3（Terio_Survivor.lua:31，Themes LastSurvivor 换乐，Volume 1.8）
- TerioThings/ena_pierce1.mp3（Terio_Survivor.lua:45，VampireShedletsky voiceline，Volume 1.5，Debris 4s）
- TerioThings/ena_pierce2.mp3（Terio_Survivor.lua:52，同上）
- TerioThings/ena_coagulate1.mp3（Terio_Survivor.lua:63，VampireShedletsky voiceline，Volume 1.5，Debris 4s）
- TerioThings/ena_coagulate2.mp3（Terio_Survivor.lua:70，同上）

Terio_Survivor.lua 引用已读 20-77 与 225-254、1070-1099、1145-1179 行核验：路径均带 TerioThings/ 前缀；两份副本（reference-inputs 与 work/attachments）SHA256 相同（4b9360a9…8e1f）。

## 使用说明

- 播放完全本地完成，无需联网；`getcustomasset`/`isfile` 不可用时降级为静默或提示，不报错堆栈。
- 这是已提供资产的最小落地，不是完整音频重做；缺失的 12 项在补齐前不具备部署条件。
- 运行时需用户自行把 `TerioThings/` 放入执行器 workspace；本仓库副本仅作来源与备份。
