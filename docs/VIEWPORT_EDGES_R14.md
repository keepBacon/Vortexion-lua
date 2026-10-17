# WindUI视口边界回归：R46当前证据与r14历史

## R46：修复测试夹具的异步与清理错误漏报

本轮仅修复测试判定，不修改生产 `src/WindAdapter.luau`。原 `check()` 先调用 `resetFixture()` 清空 `asyncErrors`，再判断错误；`restoreGlobals` 与 `Destroy()` 的 `pcall` 结果也被丢弃。父在旧夹具上注入异步错误及清理异常，均错误报告20/20通过。

修复后先记录restore/cleanup异常、保留 `observedErrors` 引用，再重置夹具并根据已捕获错误判定。健康19场景仍全通过；运行器为健康与两个注入各建独立Luau VM，负对照必须同时满足：19正常场景继续执行、注入场景RED、总计20项中恰有一项失败、异常原文与预期一致。

专项已实际执行并退出0：`WIND_VIEWPORT_EDGES_R14: passed=19 failed=0 checks=19`；两个 `R46_VIEWPORT_NEGATIVE_CAPTURED` 分别捕获 `R46_ASYNC_INJECTED` 与 `R46_CLEANUP_INJECTED`。退出0是运行器成功验证了预期RED，不是忽略错误。完整发布结果以 `tests/release-test-results.json` 为准。

捕获的生产桥接59495字节，SHA256 `4fc20bb39b9a5410e0619d3fd65d41644e5203b162cbd052f12811ec7b9b14df`；场景体33944字节，SHA256 `bbb0a3efde98354da66188168bc6522eeebf1dfc03bd7e450c95548ec1785a07`；assembled100798字节，SHA256 `8b08cd4babd5e92ea606bb638e0744074dbe1a2cb98a89664963a8e10eb681eb`。参考原型及独立顺序复现隔离在work目录，不进入ZIP。

独立复现另覆盖cleanup drain期间异步错误与restore抛错，确认同一判定修复适用；这不证明真实Android旋转、触控或帧率已验收。以下为r14原始历史记录，其场景数、行数与“非发布门禁”描述只对应当时快照；当前运行器已纳入固定34阶段。

## r14原始历史记录：WindUI bridge FitViewport

Snapshot regression for the shared-GUI viewport/inset adaptation contract of `src/WindAdapter.luau`.
Scope: normal shared GUI simulation only. No game features, no network, no remote calls, no release build.

**Status: SNAPSHOT REGRESSION, NOT FROZEN ACCEPTANCE.** `src/WindAdapter.luau` is owned by another worker and may
change under this suite. The sha256 lines printed on every run pin exactly which bytes produced the result;
re-run after any source change and update the record below. A green run here is not an acceptance gate.

## Files (exclusive new files of this task)

- `tests/test_wind_viewport_edges_r14.luau` — 591 lines, the scenario body layered on the fixture base.
- `tests/run_wind_viewport_edges_r14.mjs` — 91 lines, the isolated executor (captures, hashes, validates markers, assembles, runs, witnesses drift).
- `docs/VIEWPORT_EDGES_R14.md` — this record.

Nothing else is written: no `src/WindAdapter.luau`, no existing tests/docs, no vendor, no build.py, no dist.

## Run

```
node tests/run_wind_viewport_edges_r14.mjs
```

Runtime: `../wind-tools/node_modules/luau-web/src/index.js` (WASM Luau, `LuauState.createAsync({print,warn})`).

The executor mirrors the assembly of `tests/run_wind_native_contracts.mjs` with hardened evidence rules: it reads the
fixture base, this body and the production module **once** into captured buffers and hashes those captured buffers —
never a re-read, so a concurrent edit cannot be mis-attributed to the bytes that actually ran. It then validates that
the cut marker occurs exactly once and the factory marker exactly once in the sliced base, assembles from the captured
bytes by replacing `__FACTORY__` with the production module wrapped as `(function() ... end)()` (function replacement
keeps any '$' literal), and fails with exit 1 if either marker survives assembly. A missing or duplicated marker is an
explicit `r14 FAIL: ... found N` exit before any Luau executes. After the run a drift witness re-reads the three inputs
and prints `r14 drift: <file> changed during the run; snapshot sha256=... now=...` (witness only; the exit code is
unchanged). A thrown error (any scenario failure) sets `process.exitCode = 1` after printing all failures.

## Fixture additions (layered on the sliced base)

- `vec2(x,y)` — a real `newproxy(true)` userdata whose metatable resolves only `.X`/`.Y` and errors on any other key, so a
  passing inset scenario also proves the adapter reads X/Y only and never type-checks the inset pair.
- `installInsetFixture()` — fake `GuiService:GetGuiInset()` returning the userdata pair, fake `TweenService` with
  `plays`/`cancels` counters and a deferred landing tail (a cancelled tween must not land), `TweenInfo` and a narrowed `Enum`.
- `wrapMain()` — proxy over the window `Main` frame counting real `Position` writes while still landing them.
- `drainLayout()` — drains the deferred queue with pcall, collects async errors, asserts bounded retries (<1000).
- `resetFixture()` / `newBridge(name)` — fresh counters, camera 420x800, bridge via `createBridge(wind,{Name,Env={}})` and a
  700x500 window.
- `check(name,fn)` — per-scenario global snapshot/restore, bridge destroy, async-error leak detection; a failing
  scenario never blocks the next one.

Assertions read the window's real writes (`native.scale`, `native.scaleWrites`, `native.centerWrites`,
`Main.Position`, tween `plays`), never just callback counts.

## Scenario families and verified expectations

Window 700x500 unless noted; portrait baseline 420x800.

1. **Real userdata X/Y four-edge inset.** Creation fit without the safe area: native centering, scale 0.54. With inset
   (top,bottom,left,right) = (40,20,60,30) and the safe area on: margins 90x60, availW 330, availH 740 -> scale **0.47**,
   offset (left-right)/2 = **15**, (top-bottom)/2 = **10**, exactly one tween, one real `Position` write, no native
   centering fallback.
2. **Continuous portrait/landscape rotation.** Six steps 800x600 -> **1**, 500x400 -> **0.58**, 420x800 -> **0.47** (x2),
   driven through the real camera `ViewportSize` signal; each step lands the exact scale, keeps offset 15/10, plays exactly
   one tween. A same-geometry refire writes nothing (layout cache coalescing).
3. **Camera replacement.** Swap through `workspace.CurrentCamera` to a 900x700 camera -> scale clamps to **1**, offset
   30/20 unchanged, one tween + one scale write. The stale camera's signal and direct reads stay inert after rebind;
   swapping back re-binds and refits 0.51; a nil `CurrentCamera` is a guarded no-op that resumes on restore.
4. **Inset-only change.** Baseline (40,0,60,0) -> 0.51 at offset 30/20. Raising the top inset to 80 keeps marginX at 60, so
   the quantized scale stays 0.51 with **no scale write** while the offset re-centers to 30/40. Widening left to 120 moves
   the scale to 0.42 at offset 60/40. Releasing all insets while the safe area stays on (sum 0) falls back to native
   centering (centerWrites 2), returns to the classic-margin 0.54, and does not tween or write Position; re-applying an
   inset returns to the tween path.
5. **No late writes after auto-fit is disabled.** A pending safe-area tail is cancelled by the disable with no late
   `Position` write; quiesced viewport/inset/root-size changes early-return with zero writes; re-enabling refits the
   accumulated geometry (800x600 four-edge -> 1); fullscreen early-exits with zero writes and leaving refits 0.47; an
   in-flight suspension (coroutine.yield inside the patched `SetUIScale`) commits only the scale write already in
   progress (0.58) and no centering, then re-enable re-centers without a redundant scale write.
6. **Narrow viewport + ReadabilityGuard / min-scale overflow boundary.** 300x500 classic margin: availW 260 -> **0.37**
   (259 <= 260, fits). Guard with min-scale 0.5 floors the scale at 0.5 and the resulting **350px frame in a 260px column
   is the documented, explicitly asserted overflow** — legibility over completeness, not a claim of full adaptation.
   min-scale 1 clamps the factor to exactly 1; min-scale 0.3 lets the computed 0.37 win with no overflow. Guard off with
   identical geometry writes nothing. Narrow + safe area (60,40,80,60): margins 140x100, availW 160, computed 0.22 floored
   to **0.3** with the documented 210 > 160 overflow and offset 10/10 through one tween. 45x45: avail clamps to the 40px
   floor, factor 0.05 -> clamp floor **0.1**; the guard holds **0.3**. 30x30: below the hard guard, every write stays
   frozen.
7. **Fixture hygiene.** `game.GetService`, `TweenInfo`, `Enum`, `workspace.CurrentCamera`, camera viewport, window `Main`,
   `IsFullscreen`, queue and connections are all restored/reset after the scenarios.

## Recorded run (snapshot)

```
node tests/run_wind_viewport_edges_r14.mjs
exitCode 0
WIND_VIEWPORT_EDGES_R14: passed=7 failed=0 checks=7
WIND_VIEWPORT_EDGES_R14_GREEN
```

| artifact | bytes | sha256 |
| --- | --- | --- |
| fixture base `tests/test_wind_adapter.luau` | 22527 | `b054b6395b63c2db3d36976db4c6aee0b7e6720e43e82f684b032ee35e9d64c8` |
| body `tests/test_wind_viewport_edges_r14.luau` | 30925 | `6c74758abd50d96713ed75a89265f85d425c6b661b76bb9d9affd5a3011549c0` |
| target `src/WindAdapter.luau` | 52175 | `d0b7ed38c3010bbf019a9b872cadc733afc0be0750cbb3a89628cecf4c30df2a` |
| assembled source | 88252 | `ef30df585131d43afd14d20ee111a608801f60926a14906bc98a5e4a031128b3` |

The shared worker edited `src/WindAdapter.luau` while this hardening pass ran: the target moved from
`3bfd9e6389163fb1a11362e5bb6c5e2e195fb1cc0ea0d9ab47ccaeabe96abfef` (50641 bytes) to
`d0b7ed38c3010bbf019a9b872cadc733afc0be0750cbb3a89628cecf4c30df2a` (52175 bytes) and all seven checks stayed green on
the new bytes. Because every run hashes the bytes it captured itself, a green line is valid only for the snapshot
printed with it; re-run after any further source change and update this table.

Failure mode verified earlier in the same session: runs 1 and 2 exited 1 (passed=4 failed=3, then passed=5 failed=2) and
printed every RED scenario before stopping — all five failures were expectation arithmetic errors in this file, not
production defects. The fix history is preserved here so the numbers are reproducible: inset-only steps must keep the
left inset at 60 to preserve the quantized scale; the leaving-fullscreen refit consumes one scaleWrites increment before
the in-flight suspension commit; the guard toggle must be re-enabled after the step that switches it off.

### Executor hardening and negative control

The hardened runner fails closed, before any Luau executes, on assembly damage. Verified with a throwaway harness run
outside the project tree (node-spawned, because this shell exposes no `bash`): the positive control stays green, and
every injected corruption exits 1 with no green line and no scenario summary.

| injected corruption | exit | result |
| --- | --- | --- |
| none (positive control) | 0 | `passed=7 failed=0 checks=7` + GREEN |
| cut marker dropped | 1 | `r14 FAIL: fixture cut marker must occur exactly once ... found 0` |
| cut marker duplicated | 1 | `r14 FAIL: fixture cut marker must occur exactly once ... found 2` |
| factory marker dropped | 1 | `r14 FAIL: factory marker must occur exactly once ... found 0` |
| factory marker duplicated | 1 | `r14 FAIL: factory marker must occur exactly once ... found 2` |
| factory residue injected into the body | 1 | `r14 FAIL: factory marker residue after assembly: 1 occurrence(s) remain` |

## Residual boundaries

- The fixture base is sliced out of `tests/test_wind_adapter.luau`; if that file's pre-marker section changes, the
  assembly and these expectations must be re-derived (the sha256 lines make the drift visible).
- `src/WindAdapter.luau` is being edited concurrently by the shared worker, and a manual read that races a save can
  observe a transient size; only the bytes a run captured itself count — trust the per-run `r14 snapshot` lines over any
  later manual inspection.
- Overflow expectations cover the documented legibility-over-completeness trade-off only; they do not certify full
  adaptation on every narrow viewport.
- The fake `TweenService` models Play/Cancel semantics, not real Tween timing; only cancellation and landing are asserted.
- All targets are local synthetic fixtures; nothing here touches a real device, account, or network endpoint.
