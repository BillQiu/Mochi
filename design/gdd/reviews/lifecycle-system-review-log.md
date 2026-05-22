# Mobile App Lifecycle System — Design Review Log

> Persistent revision history for `design/gdd/mobile-app-lifecycle.md`. Future re-reviews append below; do not edit prior entries.

---

## Review — 2026-05-22 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: L（Foundation；阻塞 4 个下游 GDD；状态机驱动冷启动序列；Pillar 5 核心义务）

**Specialists**: godot-specialist, systems-designer, qa-lead

**Blocking items: 12 | Recommended: 2**

**Prior verdict resolved**: First review — no prior items.

---

### Summary

评审基于 ADR-0001 + ADR-0002 写入后的当前 GDD 状态独立分析。核心结论：Core Rules 1、2、11 已由 ADR 正确更新，但 GDD 内部存在大量"三同侪"旧计数（应为四同侪含 Haptic），Formula 1 仍使用旧接口（`.state ∈ READY_*`、`current_mode()`）而非 ADR-0001 统一的 `is_ready()` 契约，`boot_timeout` 信号在三处被引用但未在 API 块声明，AC-18 引用尚未定义的 `.tres` 配置资源（MVP 无法通过），以及两处已由 Audio MAJOR REVISION + ADR-0001 解决的 Bidirectional Consistency 条目未关闭。

已修复（由 ADR-0001 + ADR-0002 同步写入，2026-05-22）：
- ✅ Core Rule 1 Autoload 顺序扩展至四同侪（含 HapticService）
- ✅ Core Rule 2 App Ready 判定更新至四同侪 `is_ready()` 契约（per ADR-0001 Decision 2）
- ✅ Core Rule 11 Anti-Pillar 信号守护（ADR-0002）

---

### Blocking findings (12)

| # | Finding | Severity |
|---|---|---|
| 1 | Summary + Overview + Core Rule 3 仍说"三大 Foundation 同侪"——Haptic 直接订阅 OS 通知的模式已在 Haptic GDD MAJOR REVISION 中确认，应更新为"四大（含 Haptic）" | BLOCKING |
| 2 | States table BOOTING 行："Foundation 三同侪全部就绪检测通过 \| 在 call_deferred 中轮询 Persistence/Input/Audio 状态"——遗漏 HapticService | BLOCKING |
| 3 | 状态转换表 BOOTING → READY 行："三 Foundation 全部就绪"——遗漏 HapticService | BLOCKING |
| 4 | Formula 1 谓词：`persistence_ready = PersistenceService.state ∈ { READY_FRESH, READY_LOADED, READY_CORRUPTED }`——违反 ADR-0001（应用 `PersistenceService.is_ready()`）；Persistence 已回填 `is_ready()` | BLOCKING |
| 5 | Formula 1 谓词：`input_ready = InputService.current_mode() == InputMode.GESTURE_MODE`——违反 ADR-0001（应用 `InputService.is_ready()`）；Core Rule 2 已正确使用 `is_ready()`，公式与 Core Rule 矛盾 | BLOCKING |
| 6 | Formula 1 缺失 HapticService 第四同侪：`boot_ready` 谓词仅有三项；变量表无 `haptic_ready` 行；示例文本"三个 `_ready` 都为 true"未更新 | BLOCKING |
| 7 | Core Rule 7 API 块缺少 `signal boot_timeout()` 声明——该信号在 Formula 3、Edge Case A、AC-3 中引用，但 API 接口未声明，实现者无法找到契约 | BLOCKING |
| 8 | Dependencies 上游表缺少 HapticService 行——Core Rule 2 依赖 `HapticService.is_ready()` 但 Dependencies 未列出该同侪访问 | BLOCKING |
| 9 | Dependencies 上游表附注"Foundation 三同侪满足以下接口约定"——应为四同侪，需补充 HapticService `is_ready()` 约定 | BLOCKING |
| 10 | AC-16 仅列"三个 Foundation Autoload"（Persistence/Input/Audio）——应包含 HapticService，否则 CI grep 会误报 HapticService 引用 | BLOCKING |
| 11 | Bidirectional Consistency + Open Questions 已解决条目未关闭：(a) AudioSystem `is_ready()` 已由 Audio GDD MAJOR REVISION（2026-05-22）回填；(b) PersistenceService `get_state()` 需求已被 ADR-0001 `is_ready()` 模式取代——两条均应标 ✅ 并关闭对应 Open Question | BLOCKING |
| 12 | AC-18 引用 `res://config/lifecycle_config.tres`——Tuning Knobs 章节将常量定义为代码级 const，AC-18 要求零魔术数字并强制读取自 .tres 文件；该资源在项目中尚未定义，MVP 无法通过此 AC | BLOCKING |

---

### Recommended findings (2)

| # | Finding |
|---|---|
| R1 | Dependencies 跨切面表 Haptic 条目：从 "*(future, #4)*" 改为已完成，从条件语气（"若需要...应自行..."）改为陈述（"已在 Haptic GDD 中确认直接订阅 OS 通知"）|
| R2 | Cross-Reference 节 Audio `is_ready()` + Persistence `get_state()` 引用更新为当前状态（两者均已通过 ADR-0001 解决）|

---

## Revision — 2026-05-22 — 12 BLOCKING 全量修订

**修订方**: /design-system mobile-app-lifecycle --revise

| # | BLOCKING | 修复路径 |
|---|---|---|
| 1 | 三大 → 四大 | Summary/Overview/Core Rule 3 "三大 Foundation 同侪" → "四大（含 Haptic）" |
| 2 | States BOOTING 三同侪 | BOOTING 行补充 HapticService，"三同侪" → "四同侪" |
| 3 | 转换表三同侪 | BOOTING → READY 行改"四 Foundation 全部就绪" |
| 4 | Formula 1 `persistence_ready` | 改 `PersistenceService.is_ready() == true`（per ADR-0001）|
| 5 | Formula 1 `input_ready` | 改 `InputService.is_ready() == true`（per ADR-0001）|
| 6 | Formula 1 缺 Haptic | 添加 `haptic_ready = HapticService.is_ready() == true`；变量表添加行；示例改"四个" |
| 7 | API 缺 boot_timeout | Core Rule 7 添加 `signal boot_timeout()` |
| 8 | Dependencies 缺 HapticService | 上游表添加 HapticService 行 |
| 9 | Dependencies 附注三同侪 | 附注改"四同侪"，补 HapticService 约定 |
| 10 | AC-16 遗漏 HapticService | 添加 HapticService 至 Foundation Autoload 白名单 |
| 11 | 已解决条目未关闭 | Bidirectional Consistency 两条标 ✅；对应 Open Question 条目关闭 |
| 12 | AC-18 .tres 资源 | 改为允许 const 常量（MVP）；注明 v1.0 可迁移至 .tres |
