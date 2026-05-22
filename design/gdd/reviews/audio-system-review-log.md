# Audio System — Design Review Log

> Persistent revision history for `design/gdd/audio-system.md`. Future re-reviews append below; do not edit prior entries.

---

## Review — 2026-05-21 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: L（Foundation；阻塞 5 个下游 GDD；与 Haptic System 强耦合；Pillar 1 核心义务）

**Specialists**: audio-director, sound-designer, godot-specialist, systems-designer, qa-lead

**Blocking items: 11 | Recommended: 3**

**Prior verdict resolved**: First review — no prior items.

---

### Summary

评审在配对编辑（Haptic 修订同步写入 4 项）之后基于当前 GDD 状态重新独立分析。核心结论：GDD 描述了"播放什么""何时播放"，但没有描述"声音是什么"——音色 brief 完全缺失，使声音设计无法启动。同时存在多处 API/AC 不一致（`&` 前缀缺失、F-3 v1.0 范围混入 MVP、有效键白名单无代码定义）和架构模糊点（NOTIFICATION 来源、is_ready() 边界条件）。修订后需新建 `lever_drag` 事件，补全状态机 PAUSED 状态，以及澄清 F-1+F-2 联动顺序。

已修复（配对编辑 2026-05-22，随 Haptic MAJOR REVISION 同步）：
- ✅ Haptic 对位列写入 Event Catalog
- ✅ `play(key: StringName)` 静态类型
- ✅ Core Rule 9 音触发射顺序（AUDIO_LEAD_MS 35ms）
- ✅ Core Rule 10 `is_ready()` API

---

### Blocking findings (11)

| # | Finding | Severity |
|---|---|---|
| 1 | 音色 brief 缺失——7 个 SFX 事件均无每事件音色 brief（时长估算、频率特征、情感目标、参考音源），声音设计无法在无 brief 情况下推进 | BLOCKING |
| 2 | `lever_drag` 预紧音缺失——摇杆拖拽中段无 SFX；核心循环感官序列不完整（摇杆只有阈值点击，无预紧过程音） | BLOCKING |
| 3 | 事件数矛盾：Summary/Overview 写"7 个 SFX"，Event Catalog 有 8 行（7 SFX + BGM_main_loop） | BLOCKING |
| 4 | AC 多处缺 StringName `&` 前缀：`play("lever_pull")` 应为 `play(&"lever_pull")`——AC 不能验证正确 API 调用 | BLOCKING |
| 5 | F-3 BGM 淡出 v1.0/MVP 矛盾：Core Rule 6 明确说"MVP 不淡出，F-3 留给 v1.0"，但 Formulas 章节完整包含 F-3 | BLOCKING |
| 6 | 有效键白名单未在 API 层定义：Core Rule 4 说"未知键警告"，但 `play()` 实现层无法区分已知/未知键——需要 `VALID_KEYS` 常量或等价定义 | BLOCKING |
| 7 | `NOTIFICATION_APPLICATION_PAUSED` 来源未明确：未说明是直接 OS 通知还是 Lifecycle 信号——ADR-0002 禁止通过 Lifecycle 信号订阅 Analytics 目的，音频暂停模式须明确 | BLOCKING |
| 8 | State Machine 缺 PAUSED 状态：只有 IDLE/SFX_ACTIVE/SHREDDING；Edge Case 7 描述的后台暂停行为在状态机中无表示 | BLOCKING |
| 9 | `play_loop("BGM_main_loop")` 行为未定义：AC-B-12 覆盖了非 shred_loop 键的降级，但 BGM_main_loop 自管理键的重复调用行为未规范 | BLOCKING |
| 10 | F-1 + F-2 联动顺序未说明：BGM 音量由两公式联合决定，但无调用顺序注释，实现者需自行推断 | BLOCKING |
| 11 | `is_ready()` 在 BGM 失败时行为未定义：Core Rule 10 说"BGM 启动后返回 true"，但 BGM 资源可为 null——是否仍应返回 true？未定义会导致 LifecycleService App Ready 卡死 | BLOCKING |

---

### Recommended findings (3)

| # | Finding |
|---|---|
| R1 | Tuning Knobs 缺少 Juice 义务子节（systems-index 要求所有 GDD Tuning Knobs 节包含 Juice Cookbook 义务引用）|
| R2 | Open Questions 的"音量偏好强杀丢失"问题已由 Persistence Core Rule 7（后台保存）隐式解决，建议回填说明 |
| R3 | AC-M-03 缺乏独立"lever_drag 音效可辨度"验收项（待 lever_drag 事件加入后补充） |

---

## Revision — 2026-05-22 — 11 BLOCKING 全量修订

**修订方**: /design-system audio-system --revise

| # | BLOCKING | 修复路径 |
|---|---|---|
| 1 | 音色 brief 缺失 | 新增"Sound Design Brief"子节至 Detailed Design，7 SFX + 1 lever_drag 每事件 4 维度 brief |
| 2 | lever_drag 缺失 | Event Catalog 追加 `lever_drag` 行；haptic 对位 = `none`（拖拽无需触觉配对）；所有者 Lever Interaction |
| 3 | 事件数矛盾 | Summary + Overview 改为"8 个 SFX 事件"或拆分说明（7 SFX 触发音 + 1 BGM 环境音）|
| 4 | AC `&` 前缀 | 所有 AC 中 `play("key")` 改为 `play(&"key")`，`play_loop("shred_loop")` 改为 `play_loop(&"shred_loop")` 等 |
| 5 | F-3 v1.0 矛盾 | F-3 移至 Open Questions 节，标注 v1.0 待实现；Formulas 节仅保留 MVP 公式 F-1、F-2、F-4 |
| 6 | VALID_KEYS 缺失 | Core Rule 4 追加 `_valid_sfx_keys: Dictionary` 常量定义；API 节新增键名白名单说明 |
| 7 | NOTIFICATION 来源 | Edge Case 7 + Core Rule 8 追加"AudioSystem 直接订阅 OS `NOTIFICATION_APPLICATION_PAUSED`（非 Lifecycle 信号），per ADR-0002 pattern" |
| 8 | State Machine | States and Transitions 追加 PAUSED 状态行 |
| 9 | BGM_main_loop 重复调用 | 追加 AC-B-14 |
| 10 | F-1+F-2 联动顺序 | F-2 前追加"前置：先用 F-1 计算 SFX_preference_db"注释 |
| 11 | is_ready() BGM 失败 | Core Rule 10 追加"即使 BGM 资源为 null，`is_ready()` 仍在 `_ready()` 末尾返回 true——BGM 失败不阻塞 Foundation 就绪" |
