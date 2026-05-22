# Input System — Design Review Log

> Persistent revision history for `design/gdd/input-system.md`. Future re-reviews append below; do not edit prior entries.

---

## Review — 2026-05-22 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: L（Foundation；阻塞 3 个下游 GDD；触摸路由唯一入口；Pillar 1 物质基础）

**Specialists**: godot-specialist, systems-designer, qa-lead

**Blocking items: 8 | Recommended: 3**

**Prior verdict resolved**: First review — no prior items.

---

### Summary

评审基于 ADR-0001 + ADR-0002 写入后的当前 GDD 状态独立分析。核心结论：GDD 本身架构完整、逻辑清晰，但在 ADR-0001 + Lifecycle GDD MAJOR REVISION 之后出现了 3 处跨文档契约断裂：(1) `is_ready() -> bool` 未在 API 声明；(2) Lifecycle Core Rule 6 确立"Lifecycle 调用 `InputService.release_text_mode()`"的新依赖关系，而 Input GDD 的 Interactions / Dependencies / Core Rule 7 均未更新；(3) Core Rule 7 的前台恢复描述暗示 InputService 自动重置，与实际 Lifecycle 驱动模式矛盾。另有 AC-18 引用未定义的 .tres 资源、两条 Open Questions 可关闭，以及 long-press PAUSED 分支缺少 AC 覆盖。

已修复（由 ADR-0001 同步写入，2026-05-22）：
- ✅ 无（InputService 尚未在 ADR-0001 写入时被更新 — 本次修订处理）

---

### Blocking findings (8)

| # | Finding | Severity |
|---|---|---|
| 1 | Core Rule 9 API 块缺少 `is_ready() -> bool` 声明——ADR-0001 要求所有 Foundation Autoload 实现此接口；Lifecycle Formula 1 调用 `InputService.is_ready()` | BLOCKING |
| 2 | Core Rule 7 前台恢复描述机制错误：当前写"恢复前台时，重置为 GESTURE_MODE"，暗示 InputService 自订 RESUMED 并自动重置——实际是 LifecycleService 在 `app_resumed` 前主动调用 `InputService.release_text_mode()`（per Lifecycle Core Rule 6）；InputService **不** 监听 NOTIFICATION_APPLICATION_RESUMED | BLOCKING |
| 3 | Interactions 表 Lifecycle 行写"无直接依赖"——Lifecycle Core Rule 6 明确调用 `InputService.release_text_mode()`，应更新为 Lifecycle → Input 单向依赖关系 | BLOCKING |
| 4 | Dependencies 跨切面表 Lifecycle 条目"两者均为 Foundation 层，无相互依赖"已过时——现在 Lifecycle → Input 存在依赖（`release_text_mode()` 调用） | BLOCKING |
| 5 | AC-18 引用 `res://config/input_config.tres`——Tuning Knobs 以代码常量定义 `TAP_DRAG_THRESHOLD_PX` / `LONG_PRESS_THRESHOLD_MS`，AC-18 要求零魔术数字并读取自 .tres 文件；该资源在项目中未定义，MVP 无法通过 | BLOCKING |
| 6 | Open Question 4（前台恢复后 IME 状态同步）已由 Lifecycle Core Rule 6 解决，未关闭——实现者可能重复解决已决定的问题 | BLOCKING |
| 7 | Open Question 3（long-press MVP 实现策略）未明确决议，但 AC 3/4 已按"完整实现"编写——若 long-press 不实现，两条 AC 在 MVP 永远不通过；需关闭并确认 | BLOCKING |
| 8 | AC-14 仅覆盖 PAUSED 时 drag 终止，缺少 long-press 计时取消的 AC——Core Rule 7 规定"long-press 计时中取消计时"但无对应验收项，QA 无法独立验证 | BLOCKING |

---

### Recommended findings (3)

| # | Finding |
|---|---|
| R1 | Core Rule 1 Autoload 顺序描述应添加 ADR-0001 引用（完整 5-service 顺序：PersistenceService → InputService → AudioSystem → HapticService → LifecycleService） |
| R2 | Core Rule 9 API 注释补充：`release_text_mode()` 和 `request_text_mode()` 的合法调用方现包含 LifecycleService（不仅是 TextInput System） |
| R3 | Interactions 表中对 Text Input / Lever / Silhouette 的 Provisional Contract 注释保留（合理，下游 GDD 未设计） |

---

## Revision — 2026-05-22 — 8 BLOCKING 全量修订

**修订方**: /design-system input-system --revise

| # | BLOCKING | 修复路径 |
|---|---|---|
| 1 | API 缺 `is_ready()` | Core Rule 9 API 块添加 `func is_ready() -> bool` |
| 2 | Core Rule 7 机制描述错误 | 更新描述：Lifecycle 调用 `release_text_mode()` 驱动重置，InputService 不自订 RESUMED |
| 3 | Interactions Lifecycle 行缺失依赖 | 更新 Lifecycle 行：Lifecycle → Input，`release_text_mode()` 调用 |
| 4 | Dependencies 跨切面已过时 | 更新 Lifecycle 条目：单向依赖 Lifecycle → Input |
| 5 | AC-18 .tres 资源 | 改为 UPPER_SNAKE_CASE const 常量要求（MVP）；v1.0 注记 |
| 6 | Open Question 4 未关闭 | 标 ✅ 已解决（Lifecycle Core Rule 6） |
| 7 | Open Question 3 未决议 | 标 ✅ 已决定：完整实现 long-press（含 AC 3/4） |
| 8 | AC-14 缺 long-press PAUSED 分支 | 添加 AC-14b：long-press 计时中 PAUSED → 计时取消，`long_press_occurred` 不发出 |
