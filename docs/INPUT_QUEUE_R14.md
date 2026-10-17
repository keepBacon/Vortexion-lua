# R14 输入队列快照回归（普通共享 GUI）

状态：快照回归通过。本文件由 Step 5 Preview 子代独有维护，记录当前源码时点的行为快照，
不是父代冻结验收结论。源码漂移后需重跑再记录。

## 独占文件

- `tests/test_wind_input_queue_r14.luau`：测试体（假业务回调，不涉及任何游戏选项）。
- `tests/run_wind_input_queue_r14.mjs`：隔离执行器（node + luau-web），从 vendor/WindUI/Source.lua
  切片装配真实 slider/dropdown 逻辑，复用 tests/test_wind_adapter.luau 的 base mock 与
  tests/wind_native_harness.luau 的 drain 基建，不改这两个既有文件。
- `docs/INPUT_QUEUE_R14.md`：本文件。

## 运行方式

```
node tests/run_wind_input_queue_r14.mjs
```

（通过 mcp__mobile_tools__command_run，command=/data/user/0/com.dshmobile.shell/files/usr/bin/node，
args=[tests/run_wind_input_queue_r14.mjs]，cwd=项目绝对目录，timeoutMs<=60000。）

## 本轮快照结果

- R14 runner：exitCode=0，passed=7 failed=0 checked=7。
- 既有基线 tests/run_wind_native_contracts.mjs：exitCode=0，passed=124 failed=0 checks=124
  （WIND_NATIVE_CONTRACTS_GREEN），确认 shared 所有者对 src/WindAdapter.luau 的 Acrylic 修复
  未破坏原生契约。

快照 hash（runner 头部打印；bytes 为 Buffer.byteLength(text,'utf8') 真实 UTF-8 字节数，此前 .length 是 JS UTF-16 码元数，windAdapter 因含中文注释两者相差 1492）：

| 组件 | sha256 | bytes |
| --- | --- | --- |
| src/WindAdapter.luau | 698951714297d75ef0335597123c1e5def06bb90f643644f1534ed03073a6981 | 53298 |
| tests/test_wind_input_queue_r14.luau | af36154394ac60d563474e9cfad41f49f03aacb3c02d032ccf3c10707132cf07 | 18556 |
| 装配后的原生 harness（runner 注入 vendor 切片后的 harness 段，非磁盘原文件） | 013df859dd22f5eee0e4936847c6453bf8c5e4129cbd557fe953fbd5f0919a9a | 7191 |
| base mock（tests/test_wind_adapter.luau 切片） | 5749c1cd5c2444c154ac1ece4a2254cf1ef1db3489b0d31aad8630800df333b4 | 5144 |
| vendor/WindUI/Source.lua | e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05 | 1350010 |

磁盘原文件 tests/wind_native_harness.luau 的 sha256 为 09d86aa6a3820f6e53167e79a1d429ad16d918c258cf3c0f82619270403443c5（父代 file_hash 实读）；上表 harness 行为 runner 注入 __VENDOR_SLIDER__/__VENDOR_CONFIG_LOAD__/__VENDOR_PARSERS__ 之后的装配结果，两者不可混用。

## 覆盖场景

七个场景全部落在值与写次数上，不只计 callback。以下均为正向健康场景；唯一的负对照是文末“变异对照”节的内存变异，不把正向场景本身称作 NC：

1. 触屏滑块密集更新：10 次 RenderStepped 去重后 8 次发布，business callback 1->2->10 次，
   最终 Value=1、Native.Value.Default=1、TextBox 刷新；释放后 SetValue(0.3) 同步落地（calls=11）。
2. drag/focus busy 门停车：drag 中 SetValue(0.8) 返回 false 且 Pending=0.8；释放 flush 恰好
   应用一次（calls=2，Value=0.8）。
3. Input 文本归一化：'beta'、42->'42'、'gamma' 逐值校验，OnChanged 回放加后续各一次。
4. Dropdown 批量并发修订：vendor Refresh 挂起期间 Select('b') 与 SetValues({'e','f'}) 排队，
   恢复后 business/listener 各恰好 2 次，最终 Value='b'、列表 {'e','f'}；原生 refreshCount 相对
   构造期 baseline(=0) 恰 +3，selectCount=1，refreshCount==selectCount+2。
5. 关闭冻结：drag 中 Destroy，之后 RenderStepped/InputEnded/release flush 全部不写业务
   （calls=2、Value 冻结 0.7、Pending=nil、无异步错误泄漏）。
6. 原生 supersede（健康承重场景）：drag 中 SetValue(0.8) 停车后 touch 到 0.9，新原生值清空 Pending
   （changed 语义），release flush 零额外原生写（nativeSetCalls 停在 2，calls 停在 3）。
7. 异步 callback 异常捕获：business 对 0.8 抛错，safeCallback pcall 捕获，bridge.LastError 记录，
   drainer 不泄漏（#__windAsyncErrors==0），写入仍落地（Value=0.8），随后 SetValue(0.4) 正常。

## 夹具错误与根因（均非 prod 缺陷）

- 三处 slider.Native:Set(nil,nil,touch) 多传 nil：vendor 真实签名 function al.Set(az,aA,aB)，
  冒号调用下 touch 落第四实参被丢弃，aB=nil 走 programmatic 分支触发 clamp(nil)。改为
  slider.Native:Set(nil,touch)。
- R1 TextBox 期望值写错：vendor FormatValue 小数 step 走 tonumber(string.format('%.2f',...))，
  TextBox.Text 是数字 1 而非字符串 '1.00'；断言改为 == 1。
- R6/R7 图标路径写错：可用路径是 Native.UIElements.SliderIcon。
- R4 refreshCount 总数假设不成立：构造期不 Refresh（baseline=0，Dropdown mock 构造只 task.spawn
  一次 Callback）。实测 +3 = 批量 Refresh 1 + vendor Select 内部附带 Refresh 1
  （vendor/WindUI/Source.lua:33039-33046：function as.Select(au,av) 尾部 as:Refresh(ap.Values)）
  + 排队 Refresh 1。改为阶段 baseline 差值加结构性断言，未弱化合并语义验证。

## Runner 加固（tests/run_wind_input_queue_r14.mjs）

- 所有 vendor 切片注入改用函数形式 replace（callback 返回字面量），避免替换串中的
  $&、$1、$$ 被 String.replace 当作替换模式解释。
- bytes 统计改用 Buffer.byteLength(text, 'utf8')，与 sha256 的 UTF-8 口径一致。
- between() 的 start marker 在 vendor 中必须恰好出现 1 次，否则抛错（防 vendor 漂移后
  切片静默错位）。
- harness 的 __VENDOR_SLIDER__/__VENDOR_CONFIG_LOAD__/__VENDOR_PARSERS__、testbody 的三个
  __VENDOR_DROPDOWN_*__、base mock 的 local createBridge = __FACTORY__（实际位于
  tests/test_wind_adapter.luau:2，经 split 切片进入 base）均校验恰好 1 次。
- 装配完成后断言 source 不含任何残留 __VENDOR_ 或 __FACTORY__ 标记。

## 变异对照（承重验证，未落盘）

内存变异：将 src/WindAdapter.luau 中 changed() 的 option.Pending = nil 一行删除
（needle 带 revision += 1 / emit(value) 精确上下文，全文唯一），经临时 runner（/tmp 不存在，
用 home 下临时文件，跑完即删）跑同一套件：

- 变异 adapter hash 551ebdee5933b473cb32151247d01158e48e1f621d087a460af3984c9f11fb40，
  bytes 53257（原 53298，恰差被删行的 UTF-8 长度）。
- 结果 exitCode=1，passed=6 failed=1 checked=7；唯一红项为 R6，失败信息
  'a newer native input must clear the parked write, got 0.8'，由 check 的 pcall 捕获为断言 RED，
  非装配/驱动异常；其余 6 场景（含 R7）保持 PASS。
- 结论：R6 的 supersede 断言直接承重于 changed() 清 Pending 这一行生产逻辑，不是空转场景。
  src/WindAdapter.luau 未被修改，正式 runner 复跑 hash 仍为 69895171...，7/7 全绿。

## 残余边界

- 父代先前对 R4 的 baseline+2 假设有误：构造期不 Refresh，vendor Select 尾部另带一次
  as:Refresh（vendor/WindUI/Source.lua:33039-33046），实测阶段差为 +3，本文件保留该更正。
- 早期记录的 windAdapter hash d9d752... 与当前 69895171... 的差异已确认为源码注释迭代
  （shared 所有者改动）；父代当前实读与 runner 打印完全一致，不再按口径差异解读。
- 覆盖限普通 Slider/Input/Dropdown 输入队列路径；不涉及游戏选项、网络、游戏远程调用、
  发布构建。
- flushSliders 的 Native.Locked 跳过分支、以及多滑块共享一次 flush 的批量场景未单独建场景
  （既有 native contracts 已覆盖 locked 与 coalesce releases）。
- task.defer 排泄深度仅到当前队列耗尽；跨帧迟到提交未构造。