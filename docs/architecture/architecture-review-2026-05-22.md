# Architecture Review Report — ADR-0001 + ADR-0002

| Field | Value |
|---|---|
| **Date** | 2026-05-22 |
| **Engine** | Godot 4.6 (pinned 2026-02-12) |
| **Mode** | 聚焦审查（`/architecture-review adr-0001 adr-0002`）—— 仅 2 个 ADR 对 5 个 Wave 1 Foundation GDD |
| **Purpose** | 验证 ADR-0001 + ADR-0002 是否可从 `Proposed` → `Accepted`（`/gate-check pre-production` 留下的解锁 `/vertical-slice` 硬条件）|
| **GDDs Reviewed** | 5 (persistence / input / audio / haptic / mobile-app-lifecycle) |
| **ADRs Reviewed** | 2 (ADR-0001 Foundation Autoload Contract, ADR-0002 Anti-Pillar Structural Guards) |
| **Verdict** | ✅ **PASS（附条件）** |

---

## Scope & Approach

聚焦审查（非全量）。仅枚举与 ADR-0001 + ADR-0002 直接对应的 Foundation 层 TR；其余 Foundation 内部 TR 留待全量 `/architecture-review` 时登记。Engine specialist 二次咨询按 lean 模式跳过（0 post-cutoff API 使用 + scope 范围匹配 lean）。

**Known conflict-prone areas** *(from `docs/consistency-failures.md`)*: `entities.yaml` 注册表 vs Haptic / Lifecycle GDD 的同步——本次审查特别关注 ADR 与同侪 GDD 在订阅模式上的对齐，未发现新的 entities/registry 漂移问题。

---

## Traceability Summary

- **Total requirements**: 10 (TR-foundation-001 .. TR-foundation-010)
- **✅ Covered**: 10
- **⚠️ Partial**: 0
- **❌ Gaps**: 0

### Full Matrix

| TR-ID | GDD 来源 | Requirement (短) | ADR Coverage | Status |
|---|---|---|---|---|
| TR-foundation-001 | lifecycle Core Rule 2 + Formula 1 | 统一 `is_ready() -> bool` 契约（4 同侪） | ADR-0001 Decision 1 + 2 | ✅ |
| TR-foundation-002 | persistence Core Rule 10 | 5 Autoload 顺序 + Carve-out 例外清单 | ADR-0001 Decision 4 | ✅ |
| TR-foundation-003 | audio Core Rule 7 + persistence schema | preferences slice MVP（sfx/music_volume，String 键）| ADR-0001 Decision 3 | ✅ |
| TR-foundation-004 | haptic Core Rule 5 + persistence schema | settings slice MVP（haptic_enabled，String 键） | ADR-0001 Decision 5 | ✅ |
| TR-foundation-005 | persistence Core Rule 10 Carve-out | HapticService `_ready()` 同步读 settings | ADR-0001 Decision 5 + Persistence Carve-out | ✅ |
| TR-foundation-006 | audio Core Rule 7 + haptic API | JSON-roundtrip 切片名/键名必须 String | ADR-0001 Decision 3 + 5 | ✅ |
| TR-foundation-007 | lifecycle Core Rule 11 | Lifecycle 信号 Permitted Subscriber 表 | ADR-0002 Decision 1 | ✅ |
| TR-foundation-008 | game-concept Anti-Pillar | Forbidden Pattern 注册到 architecture.yaml | ADR-0002 Decision 2 + registry 已登记 | ✅ |
| TR-foundation-009 | lifecycle Core Rule 11 | `[RESTRICTED — ADR-0002]` doc 注释 | ADR-0002 Decision 3 + 4 | ✅ |
| TR-foundation-010 | lifecycle AC 集合 | GUT 测试 `get_signal_connection_list()` 验证 | ADR-0002 Decision 5 | ✅ |

### Coverage Gaps

**None** for ADRs in scope.

---

## Cross-ADR Conflicts

**0 conflicts detected.**

逐项对比（Data ownership / Integration contract / Performance budget / Dependency cycle / Architecture pattern / State management）均无矛盾。

### 关系结构验证

- **依赖方向干净**：ADR-0002 `Depends On` 明确声明 ADR-0001（建立信号源），无循环。
- **关注层级正交**：ADR-0001 = 服务就绪 + Persistence schema（数据层）；ADR-0002 = Lifecycle 信号订阅策略（事件层）。无重叠。
- **State Ownership 注册**：本次审查发现 `settings.haptic_enabled`（ADR-0001 Decision 5 引入的共享状态）在 `docs/registry/architecture.yaml` `state_ownership` 节遗漏 —— 已在本次审查同步补全（见下 Findings）。

### ADR Dependency Order (topologically sorted)

```
Foundation (no dependencies):
  1. ADR-0001  Foundation Autoload Interface Contract  (Proposed → 推荐 Accepted)

Depends on ADR-0001:
  2. ADR-0002  Anti-Pillar Structural Guards          (Proposed → 推荐 Accepted)
```

**实施顺序约束**：ADR-0001 必须先于 ADR-0002 标记 Accepted。

---

## GDD Revision Flags

**None — all GDD assumptions consistent with verified engine behaviour.**

5 个 Foundation GDD 已在 Wave 1 v3 cross-review（commit `9568a3f`）中按 ADR-0001 Decision 1-5 + ADR-0002 全量同步：

- **Persistence**: schema 含 `preferences` + `settings` 双切片；Core Rule 10 加入 Foundation 同侪 Carve-out 例外清单（HapticService #4 显式列入）
- **Audio**: Core Rule 7（String 键 + `call_deferred` 读 preferences）+ Core Rule 8（自订 `NOTIFICATION_APPLICATION_PAUSED/RESUMED`）+ Core Rule 10（`is_ready()` 公开 + BGM 失败不阻塞 Foundation 就绪）
- **Haptic**: Core Rule 5（settings slice 通过 String 常量）+ Core Rule 9（自订 OS 通知与 Foundation 同侪同模式）+ API 含 `is_ready()` + `set_user_enabled()` 走 Read-Modify-Write
- **Input**: Core Rule 1（Autoload 顺序 per ADR-0001 Decision 4）+ API 含 `is_ready()`
- **Lifecycle**: Core Rule 1-2（4-peer `is_ready()` 查询，per ADR-0001 Decision 2）+ Core Rule 11（Anti-Pillar Signal Guard，引用 ADR-0002）+ `boot_timeout` 诊断信号

---

## Engine Compatibility Issues

**Engine**: Godot 4.6
**ADRs with Engine Compatibility section**: 2 / 2 ✅

| ADR | Knowledge Risk | Post-Cutoff APIs Used | Verification 待办 |
|---|---|---|---|
| ADR-0001 | HIGH | `call_deferred` (4.x stable)、`is_node_ready()` (4.1+ stable) —— 不依赖 4.4-4.6 新 API | (1) `kyoz/godot-haptics` plugin 同步初始化校验；(2) iPhone SE 2nd gen 冷启动 < 3 s |
| ADR-0002 | LOW | `Object.get_signal_connection_list()` (4.x stable) | runtime 枚举可用性（Godot 4.x 公共 API，社区已广泛使用）|

### Deprecated API References

**None.** 两个 ADR 均未使用 `deprecated-apis.md` 列出的弃用 API。Lifecycle AC #17 主动禁用 `OS.get_ticks_msec`（4.4+ 弃用）改用 `Time.get_ticks_msec()`。

### Stale Version References

**None.** 两个 ADR 都为 Godot 4.6 撰写，与 `docs/engine-reference/godot/VERSION.md` 一致。

### Post-Cutoff API Conflicts

**None.**

### Engine Specialist Consultation

按 lean 模式跳过 —— scope 仅 2 个 Foundation ADR + 0 post-cutoff API 依赖。Production Sprint 1 真机校准时再启动 `godot-specialist` + `godot-gdextension-specialist`（Haptic plugin 验证）。

---

## Architecture Document Coverage

`docs/architecture/architecture.md` **不存在** —— 这是预期状态：master 架构文档将在 Wave 6 全部 MVP GDD 完成后由 `/create-architecture` 生成（per systems-index Next Steps）。

ADR-0001 + ADR-0002 是 Foundation 层基础契约，先于 master 文档存在。不构成 gap。

---

## Findings

### Blocking Issues
**None.**

### Concerns / Minor

| # | Type | Description | Action | Status |
|---|---|---|---|---|
| C-1 | Registry sync | `settings.haptic_enabled` 是 ADR-0001 Decision 5 新增的共享状态（HapticService 拥 / Persistence 存），但 `docs/registry/architecture.yaml` `state_ownership` 节仅登记 `preferences.sfx_volume` / `preferences.music_volume`，遗漏 `settings.haptic_enabled` | architecture.yaml 追加 1 个 state_ownership 条目 | ✅ **已在本次审查中修复** |
| C-2 | Terminology | ADR-0001 Decision 2 原文 "No retry loop is needed" 与 Lifecycle GDD Formula 1 实现的"未就绪则继续 `call_deferred` 下一帧重试"语义其实一致（处理同侪内部 async 完成），但措辞易引误解 | ADR-0001 Decision 2 末尾扩写 explanation，明确 deferred re-dispatch ≠ failure-recovery retry loop | ✅ **已在本次审查中修复** |
| C-3 | Provisional doc | ADR-0002 Decision 5 GUT 测试硬编码 `obj is MochiCharacter or TextInput or SceneComposition or Onboarding` —— 这 4 个类在 Wave 2/3 之前不存在；已在 Decision 1 / Migration Plan 中标 "provisional" | Wave 3/6 各 GDD 落地时同步更新 Permitted Subscriber 表 | ⏳ **持续追踪**（Migration Plan 第 6 项已覆盖） |

### Verification Items（Accepted 后转入 Production Sprint 1 backlog，不阻塞 Accepted）

| ADR | Verification 项 | Resolution Path |
|---|---|---|
| ADR-0001 | `kyoz/godot-haptics` plugin 是否同步初始化 | 若 async → ADR-0001 amend，新增 `haptic_initialized` 信号；amendment 而非重做 |
| ADR-0001 | iPhone SE 2nd gen cold start < 3 s | Production Sprint 1 真机 profiling；超标则 Audio BGM lazy-load 优化或调整预算 |
| ADR-0002 | `get_signal_connection_list()` runtime 枚举 | GUT 测试落地时自然校验；社区已使用，不预期阻塞 |

---

## Verdict: ✅ PASS（附条件）

**ADR-0001 + ADR-0002 满足从 `Proposed` → `Accepted` 的形式与实质条件：**
- 10/10 TR 覆盖率 100%
- 0 cross-ADR conflict
- 0 deprecated API 引用
- 0 GDD revision flag（已在 Wave 1 v3 cross-review 全量预先收口）
- 依赖序列清晰（ADR-0001 在前，ADR-0002 在后）
- 3 项 verification 全部可移交 Sprint 1，不阻塞 Accepted

**条件**：
1. ~~C-1：`settings.haptic_enabled` 登记到 `state_ownership`~~ ✅ 本次完成
2. ~~C-2：ADR-0001 Decision 2 措辞扩写~~ ✅ 本次完成
3. C-3：每个新 Wave 2/3 系统订阅 Lifecycle 信号时同步更新 ADR-0002 Permitted Subscriber 表（持续追踪，不阻塞 Accepted）

---

## Required ADRs (Wave 2+ 持续追踪)

本次审查未发现立即需要新建的 ADR。Foundation 层 ADR 覆盖完整。后续触发新 ADR 的可能场景：
- **ADR-0003 (potential)**: Network I/O prohibition for Foundation Autoloads（per ADR-0002 Architecture Diagram Layer 4 标注）—— 仅在 Wave 2+ 有系统试图发起网络请求时触发
- **ADR-XXXX (potential)**: GDExtension wrap for `NSURLIsExcludedFromBackupKey`（per persistence-system.md Open Questions）—— iOS 真机构建前 Sprint 启动

---

## Files Written by This Review

1. `docs/registry/architecture.yaml` —— 追加 `settings.haptic_enabled` state_ownership 条目；`last_updated` 设为 `2026-05-22`
2. `docs/architecture/adr-0001-foundation-autoload-contract.md` —— Decision 2 末尾措辞扩写消除 "No retry loop" 歧义
3. `docs/architecture/tr-registry.yaml` —— 首次注册 10 个 TR-foundation-001 .. TR-foundation-010；`last_updated` 设为 `2026-05-22`
4. `docs/architecture/architecture-review-2026-05-22.md` —— 本审查报告
5. `production/session-state/active.md` —— 本审查的 Session Extract 追加（在写完此文件后执行）

### Reflexion Log
**Not appended.** 本次审查 0 个 🔴 CONFLICT；按 skill 规则 "Only append CONFLICT entries"，`docs/consistency-failures.md` 不追加。C-1（registry omission）是 minor sync 项，已在审查中修复，不构成 CONFLICT。

---

## Handoff

### Immediate Actions (用户决定)

1. **将 ADR-0001 + ADR-0002 状态从 `Proposed` 改为 `Accepted`** —— 这是 `/gate-check pre-production` 留下的解锁 `/vertical-slice` 硬条件，本次审查已确认满足所有前置条件
2. **可选**：在 ADR-0001 / ADR-0002 文件头 `## Status` 节追加 `Accepted: 2026-05-22 (per /architecture-review)` 时间戳，留下审计痕迹

### Pre-Gate Checklist (针对未来的 Pre-Production gate-check，本次审查不阻塞 Accepted)

| 项目 | 状态 | 行动 |
|---|---|---|
| `tests/unit/` + `tests/integration/` 目录 | ❌ MISSING | 后续在 `/test-setup` skill 中创建（建议在 Wave 6 末或进入 Production 之前） |
| `.github/workflows/tests.yml` | ❌ MISSING | `/test-setup` 同步创建 |
| `design/ux/interaction-patterns.md` | ❌ MISSING | `/ux-design` 在 Wave 6（Scene Composition 设计）时触发 |
| `design/ux/accessibility-requirements.md` | ❌ MISSING | `/ux-design` 同步创建；v1.0 才正式审查（per systems-index #16 Accessibility System v1.0 优先级） |

> **注**：以上四项是 `/gate-check pre-production` 的全量门禁项，**不是 ADR Acceptance 的前置条件**。Mochi 当前 Wave 2 启动阶段（Juice Cookbook）远未到达 Pre-Production gate，这些工件按 systems-index 计划在后续 Wave 自然产出。

### Rerun Trigger
- Wave 2 Juice Cookbook 落地后，第一个订阅 Lifecycle 信号的下游 GDD（首个 Wave 3+ GDD）写入时，重新跑 `/architecture-review` 验证 ADR-0002 Permitted Subscriber 表同步更新。
- Production Sprint 1 真机 verification 完成（ADR-0001 两项 + ADR-0002 一项），如有 verification failure 触发 amend，再次跑 `/architecture-review`。
