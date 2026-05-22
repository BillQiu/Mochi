# Haptic System — Design Review Log

> Persistent revision history for `design/gdd/haptic-system.md`. Future re-reviews append below; do not edit prior entries.

---

## Review — 2026-05-21 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: L (cross-cutting Foundation; blocks 5 downstream GDDs + paired edit required on `audio-system.md`; likely triggers a Plugin/Backend ADR)

**Specialists**: game-designer, systems-designer, qa-lead, godot-specialist, audio-director, creative-director (synthesis)

**Blocking items: 13 | Recommended: 10 | Nice-to-have: 3**

**Prior verdict resolved**: First review — no prior items.

---

### Summary (creative-director synthesis)

5 位专家从不同视角独立收敛到同一诊断：这份 GDD 把技术妥协写成设计决策，用错误的物理量度量自己的 Pillar（Pillar 1 Tactile First），且与声称协调的姊妹 GDD `audio-system.md` 词汇不通。`sfx_` 前缀错配是构造性静默失败——AC-Y-1 本身用了错误字符串，意味着即便测试通过也验证了错误的东西。Pillar 1 的承诺是"文档让项目向触感卓越弯腰"，但当前 GDD 反过来让 Pillar 1 向 plugin 现有限制弯腰。**不应在此基础上启动 Sprint 1**。结构性章节（Overview / Player Fantasy / Dependencies）可保留；需重写的是 Detailed Design 的 API/状态机、Formulas、AC 的可测性。预计 2–3 天集中修订。

---

### Top 3 fixes (in dependency order)

1. **Plugin + CoreHaptics decision spike** [godot-specialist #1 + game-designer BLOCKING #1]
   - 真机核实 `kyoz/godot-haptics` 存在性 / 版本 / 许可证 / 是 GDExtension 还是 GDScript 包装 / iOS XCFramework 支持
   - 同时做"5 预设 vs CoreHaptics 自定义波形"对照原型，3 名外部测试者盲测
   - 决议必须在 GDD 批准前落地，而非推迟到 Production Sprint 1
   - 此为所有其他修订的前置——CoreHaptics 路径会改写 Detailed Design 和 Event Catalog

2. **Audio/Haptic 契约统一编辑（配对 PR）** [audio-director #1/#2/#3/#6 + godot-specialist #2]
   - 修复 `sfx_` 前缀错配——Haptic Event Catalog 的 "Audio 对位" 列对齐 Audio GDD 实际键名（无 `sfx_` 前缀）
   - 修复 AC-Y-1 中的错误字符串
   - Lifecycle GDD 第 317 行与 Haptic GDD 第 89 行的架构冲突二选一：要么 Haptic 自订 OS 通知（Lifecycle GDD 当前立场），要么 Lifecycle 转发并将 HapticSystem 加入 Autoload 顺序列表（Haptic GDD 当前立场）
   - Audio GDD SFX 目录补充 "Haptic 对位" 镜像列；Audio GDD 增加"音触发射顺序"对等声明
   - 定义 `shred_loop` ↔ `shred_pulse` 协调规则（BPM 对齐 or 自由节奏）；明确 `play_loop("shred_loop")` 相对 `shred_start` 触觉的毫秒偏移
   - Audio GDD 补全静态类型注解（`play(key: StringName)`）

3. **同步、调度、状态机、AC 可测性重写** [systems-designer F-1-A / F-2-A,B / Missing-A + godot-specialist #5/#8 + qa-lead #1/#9/#10]
   - F-1 改为感知到达同步：引入 `AUDIO_LEAD_MS` 补偿参数（推荐 ~35 ms 真机校准），AC-Y-1 测量项从 "API 调用时刻差" 改为 "感知到达时刻差"
   - F-2 补充脉冲调度公式：`pulse_schedule[i] = shred_start_time + pulse_offset + i × interval`；调优安全上限从 0.6 s 改为 0.5 s（Apple HIG 连续性阈值）
   - F-3 修正 Tuning Knobs 边界描述与代码语义一致（`< 16` 改为 `≤ 16`）；安全上限标注"待 Lever Interaction GDD 完成后确认"
   - F-4 增加 `OS.get_model_name()` iPad 显式 gate，或修正 Edge Case A 与第 372 行的 iPad Pro 矛盾
   - `set_enabled()` API 重构：拆分 `_user_enabled: bool` + `_lifecycle_state` 两个正交维度，使 AC-S-4 "除非" 分支可实现
   - 引入 backend 依赖注入（Godot 4.5 `@abstract` HapticBackend 接口），打通 GUT mock 路径 + CoreHaptics 替换接缝
   - 新建 `production/qa/haptic-quality-rubric.md`，AC-Q-1~5 引用该量表打分；AC-Q-4 外部测试者样本量 ≥ 3
   - 补全状态机 AC：MUTED→READY、MUTED→BACKGROUNDED、BACKGROUNDED→MUTED 三条转换
   - 新增 AC-Q-6（Q-1 prototype gate 退出条件）
   - 修复 AC-Priv-3 grep 语法（`-E` 扩展正则，扩展白名单到 printerr/printraw/print_rich）
   - 替换 AC-D-2 iPhone 6 测试设备（不在支持矩阵）

---

### Blocking findings (13)

| # | Finding | Source agents | Severity |
|---|---|---|---|
| 1 | `sfx_` 前缀错配（致命，构造性静默失败 + AC-Y-1 自带错字符串） | audio-director, qa-lead, game-designer | BLOCKING |
| 2 | Q-1 P0 未决即批准 GDD（Pillar 1 自我矛盾） | creative-director, game-designer | BLOCKING |
| 3 | shred_pulse Fantasy 错位 + F-2 调度算法缺失 | game-designer, systems-designer | BLOCKING |
| 4 | F-1 度量错误的物理量（API 时刻 vs 感知到达，35–65 ms 系统性偏差） | systems-designer, audio-director | BLOCKING |
| 5 | AC-Q-4 当前预设分布下不可能通过（reveal_pop / shelf_add 同为 `selection`） | game-designer, qa-lead | BLOCKING |
| 6 | `kyoz/godot-haptics` plugin 未经核实（应 P0，非 P1） | godot-specialist, creative-director | BLOCKING |
| 7 | `set_enabled()` 单 `_state` 枚举无法表达正交维度，AC-S-4 不可实现 | godot-specialist | BLOCKING |
| 8 | GUT 测试路径未定义，AC-D-1 mock 无法实现 | godot-specialist | BLOCKING |
| 9 | Autoload 顺序 + 信号订阅与 Lifecycle GDD 第 317 行直接矛盾 | game-designer, godot-specialist | BLOCKING |
| 10 | iPad 路径 GDD 内部矛盾（第 372 行 vs Edge Case A） | systems-designer, godot-specialist | BLOCKING |
| 11 | F-3 调优范围 off-by-one + 100 ms 上限失效 | systems-designer | BLOCKING |
| 12 | AC-Q-1~5 无评分量表 + AC-Priv-3 grep 语法错误 | qa-lead | BLOCKING |
| 13 | 状态机 AC 覆盖缺失（MUTED→READY 等关键转换 + Q-1 退出条件无 AC） | qa-lead | BLOCKING |

---

### Recommended findings (10)

| # | Finding | Source |
|---|---|---|
| R1 | 事件目录不对称未论证（`lever_pull_start/progress/mochi_blink` 无音频对位） | game-designer |
| R2 | "Audio 先 Haptic 后" 顺序契约单向；reveal_pop 可能要触觉先（预期感） | game-designer, audio-director |
| R3 | `mochi_blink` "可选触发" 在封闭目录中的语义未定义 | game-designer |
| R4 | `shred_loop` ↔ `shred_pulse` 协调真空（BPM 对齐 / 启动时机） | audio-director |
| R5 | Audio GDD API 无静态类型注解（违反项目规范）；Haptic 用 StringName 不匹配 | audio-director |
| R6 | `_last_emit_ms` → `Dictionary[StringName, int]`；`VALID_KEYS` Array → Dictionary | godot-specialist |
| R7 | `Persistence.set_slice()` 无错误路径 | godot-specialist |
| R8 | AC-Perf-1 / AC-Perf-2 阈值低于测量工具分辨率/噪声底 | qa-lead |
| R9 | AC-D-2 测试 iPhone 6（不在支持矩阵） | qa-lead |
| R10 | AC-F-4 "一次 push_warning" 作用域歧义；缺去重测试 | qa-lead |

---

### Nice-to-have findings (3)

- Godot 4.5+ `@abstract` HapticBackend 接缝（CoreHaptics 替换零成本预留）
- 音量↔触觉强度对应矩阵（避免独立调优产生不匹配）
- 全局触觉速率限制（per-key debounce 无法防止跨键密集发射）

---

### Files affected by revision

- `design/gdd/haptic-system.md`（主要重写：Detailed Design / Formulas / Acceptance Criteria）
- `design/gdd/audio-system.md`（配对编辑：补 Haptic 对位列、补静态类型、补镜像顺序声明）
- `design/gdd/mobile-app-lifecycle.md`（如选择 Lifecycle 转发路径，Autoload 顺序列表需加 HapticSystem）
- `production/qa/haptic-quality-rubric.md`（新建，AC-Q-* 依赖）
- 可能触发新 ADR：`docs/architecture/adr-XXX-haptic-backend-selection.md`（plugin + CoreHaptics 决策）

---

### Re-review trigger

Re-run `/design-review design/gdd/haptic-system.md` in a fresh session after:

1. Plugin spike 完成且决议记录到 ADR 或 Open Q-1 关闭
2. `audio-system.md` 配对编辑完成
3. 上述 13 个 BLOCKING 全部消项
4. `haptic-quality-rubric.md` 存在

预期下一次裁定：APPROVED 或 NEEDS REVISION（小范围）。
