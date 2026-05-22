# Cross-GDD Review Report (Wave 1 Foundation — 第三轮)

> **Date**: 2026-05-22
> **Mode**: full (consistency + design-theory + cross-system scenarios)
> **GDDs Reviewed**: 5 (Persistence / Input / Audio / Haptic / Mobile App Lifecycle)
> **Systems Covered**: all Wave 1 Foundation
> **Run via**: `/review-all-gdds`
> **Registry baseline**: `design/registry/entities.yaml` v2 (28 constants)
> **Verdict**: 🔴 **FAIL** — 3 cross-GDD BLOCKING issues must resolve before architecture begins.

---

## Manifest

| # | GDD | Layer | Status | Last Updated |
|---|---|---|---|---|
| 1 | persistence-system.md | Foundation | Revised — pending re-review | 2026-05-21 |
| 2 | input-system.md | Foundation | Revised — pending re-review | 2026-05-22 |
| 3 | audio-system.md | Foundation | Revised — pending re-review | 2026-05-22 |
| 4 | haptic-system.md | Foundation | Revised — pending re-review | 2026-05-22 |
| 5 | mobile-app-lifecycle.md | Foundation | Revised — pending re-review | 2026-05-22 |

---

## Consistency Issues

### 🔴 Blocking

#### C1. Persistence Rule 10 ↔ Persistence Interactions Table 自相矛盾 + 牵连 Haptic GDD

- `persistence-system.md` Core Rule 10：
  > "Downstream Autoloads **MUST NOT** call `Persistence.get_slice()` or `set_slice()` synchronously inside their own `_ready()` — defer to the next idle frame via `call_deferred` or connect to `tree_entered` signals."
- `persistence-system.md` Interactions 表 Haptic 行：
  > "`get_slice("settings", {}).get("haptic_enabled", true)` **synchronously in `_ready()`** (Persistence is Autoload #1, settled by the time Haptic #4 runs)"
- `haptic-system.md` `_ready()` 伪代码（§ API）按 Interactions 表实施同步读取
- Audio Core Rule 7 用 `call_deferred` 路径（合规）；Haptic 用同步路径（违规）

**根因**：Persistence Rule 10 的"MUST NOT"是绝对禁止，但同一份 GDD 的 Interactions 表又显式允许 Haptic 同步调用。两条规则在同一文件内对立。

**修复路径（用户已选 方案 A）**：
- Persistence Rule 10 增加 carve-out："**例外**：注册顺序在 Persistence 之后的 Foundation 同侪在自身 `_ready()` 执行时，Persistence 已完成 `_ready()` 并进入 READY_* 状态。Haptic #4 同步读 `settings.haptic_enabled` 是首个具名例外。其他下游 / 非 Foundation Autoload 仍受 MUST NOT 约束。"
- Persistence Interactions 表 Haptic 行加链接到 Rule 10 例外子句

#### C2. Audio 订阅 `NOTIFICATION_APPLICATION_FOCUS_IN`，与其余 4 个 Foundation 同侪 + Godot 4.6 lifecycle 通知不一致

- `audio-system.md` Core Rule 8（第 110 行）+ AC-State-02（第 367 行）+ States and Transitions 表 PAUSED 状态退出条件全部使用 `NOTIFICATION_APPLICATION_FOCUS_IN`
- 其余四同侪 resume 端：
  - Persistence: 不订阅 RESUMED（依赖原子 rename 即可）
  - Input: 不订阅 RESUMED（per Input Core Rule 7）
  - Haptic Core Rule 9: 订阅 `application_resumed`
  - Lifecycle Core Rule 3: `NOTIFICATION_APPLICATION_RESUMED`
- Godot 4.6 中 `NOTIFICATION_APPLICATION_FOCUS_IN` 是窗口焦点通知（如 Alt+Tab），≠ `NOTIFICATION_APPLICATION_RESUMED`（lifecycle resume）
- **后果**：Audio 在 PAUSED 后无法收到 RESUMED → `_state` 永久错位 → BGM 由 OS 自动恢复看似无碍但内部状态机错乱，后续 PAUSED→FOCUS_IN→PAUSED 序列触发未预期分支

**修复**：Audio Core Rule 8 + AC-State-02 + States and Transitions 表三处把 `NOTIFICATION_APPLICATION_FOCUS_IN` 改为 `NOTIFICATION_APPLICATION_RESUMED`。

#### C3. Persistence Dependencies / Interactions 表完全遗漏 AudioSystem（preferences slice 拥有方）

- `persistence-system.md` schema 第 44 行：`preferences` slice 标注 "AudioSystem-owned volume preferences (ADR-0001 Decision 3)"
- 但 Persistence Interactions 表无 Audio 一行
- Persistence Dependencies "Downstream" 表无 Audio
- Persistence "Cross-references" 表无 Audio
- `audio-system.md` Dependencies 表（第 273 行）正确声明"双向 - AudioSystem 读取 preferences slice"

**违反 design-docs rule**："Dependencies must be bidirectional — if system A depends on B, B's doc must mention A."

**修复**：Persistence GDD 三处补 AudioSystem 行：
1. Interactions 表：`AudioSystem | get_slice("preferences", {}).get("sfx_volume"/"music_volume") via call_deferred in _ready(); writes on volume change. | preferences (owns)`
2. Downstream 表：`AudioSystem → Persistence | Data (read+write) | Hard | preferences slice 读写`
3. Cross-references：`preferences slice 契约 | design/gdd/audio-system.md | Core Rule 7 + Dependencies`

### ⚠️ Warnings

#### C4. Haptic `set_user_enabled()` 全量覆写 settings slice，破坏未来共用扩展

- `haptic-system.md` `set_user_enabled()`：`PersistenceService.set_slice(SETTINGS_SLICE, {SETTINGS_HAPTIC_ENABLED: enabled})`
- Persistence Edge Case C 明确 merge 责任在 domain wrapper（read-modify-write 原子化）
- 当前 settings 仅 `haptic_enabled` 一键，无副作用；但 ADR-0001 Decision 5 把 settings 定为多用户开关共用 slice
- 一旦下游加入第 2 个键，Haptic 下一次 set_user_enabled 会清空它

**修复**：Haptic `set_user_enabled` 改为 read-modify-write：
```gdscript
var s: Dictionary = PersistenceService.get_slice(SETTINGS_SLICE, {})
s[SETTINGS_HAPTIC_ENABLED] = enabled
PersistenceService.set_slice(SETTINGS_SLICE, s)
PersistenceService.save_when_idle()
```

#### C5. `AUDIO_LEAD_MS` 跨 GDD 引用但无 source-of-truth；entities.yaml 未登记

- Audio Core Rule 9：默认 35ms（真机校准）
- Haptic F-1 + Tuning Knobs：AUDIO_LEAD_MS = 40 − 5 = 35
- entities.yaml 登记了 `audio_haptic_sync_window_ms`（30ms 窗口）但缺补偿提前量 / 管线延迟三常量

**修复**：entities.yaml 增加 3 条 constants（source = haptic-system.md F-1）：
- `audio_lead_ms` = 35, unit: ms
- `audio_pipeline_latency_ms` = 40, unit: ms
- `haptic_pipeline_latency_ms` = 5, unit: ms

#### C6. Haptic GDD 引用 Lifecycle "line 317" 行号漂移

- `haptic-system.md` Core Rule 9 + Dependencies 两处写"Lifecycle GDD line 317 已声明此模式"
- 实际契约已迁移到 Lifecycle Core Rule 3 + Dependencies "Cross-cutting" Haptic 行
- 行号 317 不再对应原文

**修复**：把硬编码"line 317"改为 section 引用（如 "per `mobile-app-lifecycle.md` § Cross-cutting #4 Haptic 行"）。

#### C7. Audio Tuning Knobs `FADE_DURATION` 标 MVP 旋钮，与 Core Rule 6 内部矛盾

- `audio-system.md` Tuning Knobs 表第 280 行：`FADE_DURATION` 800ms 列为 MVP 旋钮
- Audio Core Rule 6 + F-3 章明确 MVP 不实现淡出
- 内部不一致（不跨 GDD），但会误导实现者

**修复**：旋钮行加 "(v1.0 only)" 后缀或移到 "Explicitly NOT MVP knobs" 子节。

### ℹ️ Info

#### C8. lever_drag 无 Haptic 对位（设计意图，已确认）
Audio Core Rule 2 "Haptic 对位"列写 "none"；Haptic Event Catalog 不收 lever_drag。两侧对齐 ✓。

#### C9. Persistence AC 7 BLOCKED-ON-DECISION（version numbering）
不阻塞架构起步，记录在案。

---

## Game Design (Theory) Issues

Foundation 层无玩法/经济/进度系统，3a–3e 不适用。

### ✓ Pillar Alignment（PASS）

| GDD | Pillar 映射 |
|---|---|
| Persistence | Pillar 3 + 5 + Anti-Pillar（隐私默认） |
| Input | Pillar 1 + Pillar 2 |
| Audio | Pillar 1 + Pillar 2（concept doc explicit "音效预算 ≥ 美术预算"） |
| Haptic | Pillar 1（与 Audio 并列） |
| Lifecycle | Pillar 5 + Anti-Pillar |

### ✓ Player Fantasy 一致性（PASS）
5 个 Fantasy 收敛于"不可见但可信赖的基础设施"：Persistence "absence of doubt"、Input "零察觉延迟"、Lifecycle "玩家从未注意到"、Audio "情绪标点"、Haptic "物理重量感"。无身份冲突。

### ✓ Anti-Pillar 防御（PASS）
- ADR-0002 注册 `lifecycle_signal_analytics_subscription` 为禁止模式
- Persistence Core Rule 4（无明文 worry）+ Rule 5（iCloud Backup excluded）+ Rule 12（grep guard）三重防御
- 无 anti-pillar 违规

---

## Cross-System Scenario Issues

**Scenarios walked**: 5

| ID | 场景 | 涉及系统 |
|---|---|---|
| A | Cold Start Autoload 链 | 全 5 个 Foundation |
| B | PAUSE → RESUME（含 debounce） | 全 5 个 Foundation + (future Mochi Character) |
| C | 用户在 Settings 切换 haptic_enabled | Haptic + Persistence |
| D | 存档腐败 → corruption notice | Persistence + (future Scene Composition) |
| E | 音触同步事件（lever_lock） | Audio + Haptic + (future Lever Interaction) |

### 🔴 Blockers

**S1. Scenario A — Cold Start 链中 Haptic 同步读 Persistence**
- Trigger: Autoload `_ready()` 链 Persistence → Input → Audio → Haptic
- Step: Haptic `_ready()` 同步调 `PersistenceService.get_slice(SETTINGS_SLICE, {})`
- Failure mode: Persistence Rule 10 "MUST NOT" vs Interactions 表 "synchronously" 同时为真——实现者无法判断遵循哪条
- 见 **C1**

**S2. Scenario B — Audio 在 RESUME 路径失联**
- Trigger: `NOTIFICATION_APPLICATION_RESUMED` 被 OS 发出
- Step: 其余 Foundation 同侪（Haptic）和 Lifecycle 接收并切状态；Audio 等的是 `NOTIFICATION_APPLICATION_FOCUS_IN`
- Failure mode: Audio `_state` 永久停在 PAUSED；BGM 由 OS 自动恢复掩盖问题；下次 PAUSED 进入分支错乱
- 见 **C2**

### ⚠️ Warnings

**S3. Scenario B — 5 Foundation 独立订阅 OS 通知，响应时序未对齐**
- Audio 在 PAUSED 瞬间停 shred_loop；Lifecycle 等 1000ms 防抖才发 `app_paused`
- 对于 < 1s 瞬时切换：Audio 已停 loop 但上层（Mochi/Scene）从未收到 `app_paused`
- 语义缝隙："shred 已停但角色仍以为在粉碎中"
- Mitigation：Audio Edge Case "前台恢复后由 Shred Process 自行决定是否重启"——但 Shred Process GDD 尚未写，无法验证
- 建议：Wave 4 写 shred-process.md 时，明确：app_paused 信号 vs OS PAUSED 通知 二者的语义分工，并在 shred-process 订阅 `app_paused` 而非直订 OS 通知

**S4. Scenario C — Haptic 全量覆写 settings slice**
- 见 **C4**

### ℹ️ Info

**S5. Scenario E — `AUDIO_LEAD_MS` 跨 GDD 但无 entities.yaml 登记**
- 见 **C5**

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|---|---|---|---|
| persistence-system.md | C1 (Rule 10 ↔ Interactions 矛盾) + C3 (漏 Audio) | Consistency | **Blocking** |
| audio-system.md | C2 (FOCUS_IN ≠ RESUMED) | Consistency | **Blocking** |
| audio-system.md | C7 (FADE_DURATION 旋钮 vs Core Rule 6) | Consistency | Warning |
| haptic-system.md | C1 (同步读违 Rule 10) | Consistency | **Blocking** |
| haptic-system.md | C4 (settings 覆写) + C6 (行号漂移) | Consistency | Warning |
| input-system.md | — | — | — |
| mobile-app-lifecycle.md | — | — | — |
| design/registry/entities.yaml | C5 (缺 audio_lead_ms 三常量) | Consistency | Warning |

---

## Verdict: 🔴 **FAIL**

3 个跨 GDD BLOCKING（C1 / C2 / C3）必须在 `/create-architecture` 之前解决。

### Required actions before re-running

1. **C1 修复（方案 A，用户已选）**：
   - Persistence Core Rule 10 加 carve-out 子句（Foundation 同侪在注册顺序之后的同步读取例外）
   - Persistence Interactions 表 Haptic 行加链接到该例外子句
2. **C2 修复**：Audio Core Rule 8 + AC-State-02 + States and Transitions 表 PAUSED 退出条件三处把 `NOTIFICATION_APPLICATION_FOCUS_IN` 改为 `NOTIFICATION_APPLICATION_RESUMED`
3. **C3 修复**：Persistence GDD 三处补 AudioSystem `preferences` slice owner / consumer 行（Interactions / Dependencies / Cross-References）
4. **C4 修复**：Haptic `set_user_enabled()` 改 read-modify-write
5. **C5 修复**：entities.yaml 增加 `audio_lead_ms` / `audio_pipeline_latency_ms` / `haptic_pipeline_latency_ms` 三条 constants
6. **C6 修复**：Haptic GDD "line 317" 改 section 引用
7. **C7 修复**：Audio Tuning Knobs FADE_DURATION 标 "(v1.0 only)"

### Recommended Re-run

完成 C1–C7 修复后，运行 `/consistency-check`（轻量 grep）确认 entities.yaml 与 GDD 同步；再 `/review-all-gdds since-last-review` 以本报告为基线确认无新增不一致。然后才进入 `/gate-check pre-production`。

---

> Report authored by `/review-all-gdds` 2026-05-22 v3. Previous v1/v2 reports (initial + post-MAJOR-REVISION) preceded ADR-0001 Decision 5 + commit 44bf308. This v3 evaluates the post-ADR-0001-Decision-5 + post-`/consistency-check` state.
