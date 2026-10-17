# Vortexion R227 — Uploaded Neverlose UI (native layout preserved)

## Scope

- Input: user-uploaded `Neverlose-UI-main(1).zip`, `Neverlose-UI-main/Source.lua`, attributed to `Mana42138/Neverlose-UI`.
- Baseline: R226 Vortexion full source.
- This release replaces the active UI vendor and adapter only. All game module sources, including SCP, BloxStrike, AOTR, and Forsaken remain identical to R226.
- This is **not** a visual redesign or a reordering of existing game options: control creation follows the existing game registration sequence. Original Neverlose layout: left-hand 203px sidebar; 643px main panel; **two fixed columns** of 285px sections; 682px height. No one-column portrait reflow.

## Adaptation

- Native API `Window({Title,CFG,Key,External}) / TSection / Tab / Section / Toggle / Slider / Dropdown / Colorpicker / TextBox` is wrapped by the existing Vortexion `AddTab / AddToggle / AddSlider / AddDropdown / AddInput / AddColorpicker / AddButton / AddParagraph` API, preserving option identifiers and callbacks.
- Sections are assigned deterministically left / right, avoiding unordered child iteration and asynchronous parent reassignment. Game options retain their registration order; sections group each eight items just as before.
- Slider gains transparent, larger touch-target but retains the original drawn size and position; touch drag and pointer drag supported.
- Sidebar scroll becomes native `ScrollingFrame`; dropdown items use a larger native clickable surface; original scrolling behavior remains.
- Viewport adaptation uses only a single UIScale and geometry positioning calculated from original dimensions. The **original two-column structure is not mutated on phones**. Very small screens necessarily show a physically smaller UI; users can change zoom and drag the title to reposition. This does not guarantee ergonomic controls for every screen size.
- Mobile close/open uses a persistent `V` opener; dragging limited to title to reduce accidental widget dragging. Screen GUI persists across respawn.
- The user's previously uploaded Vortexion icon is reused as available (requires `getcustomasset` and `writefile`); Roblox avatar image remains fallback.
- Removed unconditional third-party Pastebin dependency, automatic Discord RPC / community network traffic, and unused script-editor initialization. Per-widget background polling loops disabled. Added best-effort filesystem fallback when executor lacks APIs.

## Validation

- `python3 build.py` generates seven independent/unified outputs and six modular outputs.
- `python3 verify_release.py` checks all six modular and seven standalone SHA-256 values.
- `tests/test_r227_native_ui.py` uses a Lua 5.4 mock to verify the bridge native API, status callbacks, slider bounds, dynamic dropdown refresh, input/color widgets, tab switching, viewport change, destruction, source integrity, and two-column UI contract.
- Existing R222/R223/R225 and R226 SCP business tests also pass independently.
- Older R224 UI styling tests expect the previous different Neverlose vendor and are intentionally not applicable to this migration.

### Verification limits

- No real Android Roblox app session / executor, no screenshot of a running R227 UI, no phone-based touch/gesture testing, and no server-side gameplay validation.
- Lua 5.4 compilation checks are not a substitute for Luau runtime validation.
- On very small screens, a fixed dual-column layout means reduced physical touch target size. Zoom control and header dragging mitigate this but do not remove the geometric trade-off. Do not claim this release guarantees zero touch failure.
- This ZIP is generated locally; GitHub was **not** modified.
