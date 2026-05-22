# Systems Index: Mochi

> **Status**: Draft
> **Created**: 2026-05-21
> **Last Updated**: 2026-05-22
> **Source Concept**: design/gdd/game-concept.md
> **Source Prototype**: prototypes/mochi-concept/ (concluded PROCEED 2026-05-21)

---

## Overview

Mochi is a mobile cozy worry-transformation toy with a 22-30 second core loop:
**type a worry → pull the lever → watch Mochi crush it → tap the silhouette → reveal a tiny keepsake → collect on shelf**. The mechanical scope is narrow but each layer must be *theatrically intense* — the prototype confirmed the loop logic but exposed the bar for "feel": the visual / interaction surface must not be bland (寡淡). This index decomposes Mochi into 17 systems organized into Foundation, Core, Feature, and Polish layers, with **Game Feel / Juice elevated to a first-class concern** (a lightweight Cookbook, not a full GDD) referenced by every Core system.

The game's pillars constrain everything:
- **Pillar 1: Tactile First** → Haptic + Audio are foundation systems treated as first-class, not polish.
- **Pillar 2: Every Pull Is a Theatre** → Lever / Shred / Reveal each get independent GDDs with Juice obligations.
- **Pillar 3: Collection Without Pressure** → Shelf must never push completionism.
- **Pillar 4: Cute But Weighted** → Mochi Character system carries the personality logic for "克制工匠" reactions to heavy content.
- **Pillar 5: Unlimited But Meaningful** → No retention loops, daily quests, login bonuses; Persistence/Lifecycle are designed accordingly.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Persistence System | Persistence | MVP | Reviewed (2026-05-22 v3 cross-review PASS：C1 Rule 10 Carve-out + C3 AudioSystem 依赖补全) | design/gdd/persistence-system.md | — |
| 2 | Input System (inferred) | Core | MVP | Reviewed (2026-05-22 v3 cross-review PASS：本系统无新增 BLOCKING；8/8 历史 BLOCKING + LONG_PRESSING+PAUSED 缺口已 commit 44bf308 修复) | design/gdd/input-system.md | — |
| 3 | Audio System | Audio | MVP | Reviewed (2026-05-22 v3 cross-review PASS：C2 NOTIFICATION_APPLICATION_FOCUS_IN→RESUMED 三处修正 + C7 FADE_DURATION 标 v1.0) | design/gdd/audio-system.md | — |
| 4 | Haptic System | Core | MVP | Reviewed (2026-05-22 v3 cross-review PASS：C1 引用 Persistence Carve-out + C4 set_user_enabled RMW + C6 section 引用 + _notification 模式与同侪对齐) | design/gdd/haptic-system.md | — |
| 5 | Mobile App Lifecycle (inferred) | Core | MVP | Reviewed (2026-05-22 v3 cross-review PASS：本系统无新增 BLOCKING；12/12 历史 BLOCKING 已修复；1 CONCERN 留 Scene Composition GDD 解决：boot_timeout 订阅方) | design/gdd/mobile-app-lifecycle.md | — |
| 6 | Mochi Character System | Gameplay | MVP | Not Started | design/gdd/mochi-character.md | Audio, Mobile Lifecycle |
| 7 | Text Input System | Gameplay | MVP | Not Started | design/gdd/text-input.md | Input, Persistence, Mobile Lifecycle |
| 8 | Lever Interaction System | Gameplay | MVP | Not Started | design/gdd/lever-interaction.md | Input, Audio, Haptic, Juice Cookbook |
| 9 | Shred Process System | Gameplay | MVP | Not Started | design/gdd/shred-process.md | Audio, Haptic, Mochi Character, Juice Cookbook |
| 10 | Product System | Economy | MVP | Not Started | design/gdd/product-system.md | Persistence |
| 11 | Silhouette Reveal System | Gameplay | MVP | Not Started | design/gdd/silhouette-reveal.md | Product, Input, Audio, Haptic, Juice Cookbook |
| 12 | Shelf Collection System | Gameplay | MVP | Not Started | design/gdd/shelf-collection.md | Persistence, Product |
| 13 | Game Feel / Juice Cookbook ⭐ | Meta | MVP | NEEDS REVISION (2026-05-22 Pass 1: 12 BLOCKING + 12 R；Pass 2 cross-review: +5 BLOCKING [B13 WCAG / B14 iOS reduce motion / B15 freeze 技术错误 / B16 5% 覆盖度 / B17 audio specs 跨文档裂缝] + 2 R + creative-director 提议拆 Layer 1/2；详见 design/gdd/reviews/juice-cookbook-review-log.md) | design/gdd/juice-cookbook.md | Audio, Haptic |
| 14 | Onboarding / First-Run System (inferred) | Meta | MVP | Not Started | design/gdd/onboarding.md | Mochi, Text Input, Lever, Product, Silhouette, Shelf, Persistence |
| 15 | Scene Composition / Navigation (inferred) | UI | MVP | Not Started | design/gdd/scene-composition.md | Persistence |
| 16 | Accessibility System (inferred) | Meta | v1.0 | Not Started | design/gdd/accessibility-system.md | Input, Text Input, Mochi, Scene Composition, Juice Cookbook |
| 17 | Privacy & Local Data Boundary | Meta | v1.0 | Not Started | design/gdd/privacy-boundary.md *(audit doc)* | (audits Persistence, Text Input, Product) |

**Legend**: `(inferred)` = not explicitly named in concept doc, but required for the game to function.

---

## Categories

| Category | Description | Mochi Systems |
|----------|-------------|---------------|
| **Core** | Foundation systems all gameplay needs | Input, Haptic, Mobile App Lifecycle |
| **Gameplay** | Systems that make the game fun | Mochi Character, Text Input, Lever Interaction, Shred Process, Silhouette Reveal, Shelf Collection |
| **Economy** | Resource and content rolls | Product System |
| **Persistence** | Save state and continuity | Persistence System |
| **UI** | Player-facing screens and routing | Scene Composition / Navigation |
| **Audio** | Sound and music | Audio System |
| **Meta** | Outside the core loop | Juice Cookbook, Onboarding, Accessibility, Privacy Boundary |

Note: Mochi does NOT have these typical-game categories — **no Combat**, **no Progression** (no XP/levels — anti-pillar), **no Narrative** (no story), **no Multiplayer** (anti-pillar).

---

## Priority Tiers

| Tier | Definition | Mochi Target |
|------|------------|--------------|
| **MVP** | The 22-30 second core loop must be testable end-to-end on iOS with shelf collection. 15 systems. | 3-4 weeks (per concept doc) |
| **v1.0** | MVP + formal Accessibility audit + Privacy boundary documentation + audio polish + 20 products with rarity tier. | 6-8 weeks cumulative |
| **v1.5+** | Cosmetic skins, seasonal products, settings screen. Out of scope of this systems index. | Post-launch increment |

**Note for Mochi**: There is no separate "Vertical Slice" tier between MVP and v1.0 — the game's focus is so narrow that the MVP *is* the vertical slice. If the MVP works end-to-end, the production-quality `/vertical-slice` validates the same loop with better assets/feel rather than expanding scope.

---

## Dependency Map

### Foundation Layer (no dependencies — design and build first)

1. **Persistence System** — All gameplay state (shelf, text history, first-run flag) needs durable storage. Bottleneck system (5 dependents).
2. **Input System** — Touch gesture routing and system IME bridge. All player interaction routes through here.
3. **Audio System** — SFX bus + BGM loop. Bottleneck system (5 dependents). Pillar 1 obligation.
4. **Haptic System** — iOS CoreHaptics + Android Vibrator fallback. Pillar 1 obligation; technical risk.
5. **Mobile App Lifecycle** — Background/foreground transitions, IME interruption recovery, cold start.

### Core Layer (depends on Foundation)

6. **Mochi Character System** — depends on: Audio, Mobile Lifecycle
7. **Text Input System** — depends on: Input, Persistence, Mobile Lifecycle
8. **Lever Interaction System** — depends on: Input, Audio, Haptic, Juice Cookbook
9. **Shred Process System** — depends on: Audio, Haptic, Mochi Character, Juice Cookbook
10. **Product System** — depends on: Persistence
11. **Silhouette Reveal System** — depends on: Product, Input, Audio, Haptic, Juice Cookbook
12. **Shelf Collection System** — depends on: Persistence, Product

### Feature Layer (cross-cuts Core)

13. **Game Feel / Juice Cookbook** — depends on: Audio, Haptic (subscribes to signals from Lever, Shred, Silhouette via hook pattern — no circular dependency)
14. **Onboarding / First-Run System** — depends on: Mochi, Text Input, Lever, Product, Silhouette, Shelf, Persistence
15. **Scene Composition / Navigation** — depends on: Persistence (for "where I was" recovery)

### Polish Layer (cross-cuts everything; designed late)

16. **Accessibility System** — depends on: Input, Text Input, Mochi, Scene Composition, Juice Cookbook (motion reduction overrides)
17. **Privacy & Local Data Boundary** — audits: Persistence, Text Input, Product (validates no upload paths)

---

## Recommended Design Order

Wave 1-6 design GDDs sequentially within each wave but **systems within a wave can be designed in parallel** by the solo developer (one per session, in any order within the wave).

| Order | System | Priority | Layer | Agent(s) | Est. Effort | Notes |
|-------|--------|----------|-------|----------|-------------|-------|
| **─── Wave 1: Foundation Services ───** | | | | | | |
| 1 | Persistence System | MVP | Foundation | game-designer + godot-gdscript-specialist | M | Bottleneck — interface must be stable. Save version v1 from day 1. |
| 2 | Input System | MVP | Foundation | game-designer + godot-specialist | S | Touch + IME bridge. Mostly Godot defaults + thin wrappers. |
| 3 | Audio System | MVP | Foundation | audio-director + sound-designer + godot-specialist | M | Pillar 1. 6-10 SFX inventory + 1 BGM. SFX budget ≥ art budget. |
| 4 | Haptic System | MVP | Foundation | godot-gdextension-specialist (likely) + technical-director | L | iOS CoreHaptics may need GDExtension wrap. Highest technical risk. |
| 5 | Mobile App Lifecycle | MVP | Foundation | godot-specialist | S | Background save, IME interruption, cold start. May qualify for quick-spec instead of full GDD. |
| **─── Wave 2: Juice Legislation ⭐ ───** | | | | | | |
| 6 | Juice Cookbook | MVP | Feature | art-director + audio-director + technical-artist (lean 实际 spawn: systems-designer + qa-lead + art-director + 破例 game-designer/technical-artist) | M (实际 8 节完整 GDD ~850 行) | 升级为完整 8 节 GDD（2026-05-22 用户决策）。含 7 个 JC-R 配方 ID + F-1..F-7 公式 + VA-1..VA-7 视觉/音频边界 + 13 AC。Wave 3-6 硬引用合同（code review BLOCKING）。 |
| **─── Wave 3: Character & Text ───** | | | | | | |
| 7 | Mochi Character System | MVP | Core | narrative-director + game-designer | M | Personality logic: idle behavior, ≤8 expressions, "克制工匠" reaction rules for heavy content. |
| 8 | Text Input System | MVP | Core | game-designer + ux-designer | M | Min-length, repeat rejection, 24h content dedup, IME UX. |
| **─── Wave 4: Crush Loop ───** | | | | | | |
| 9 | Lever Interaction System | MVP | Core | game-designer + gameplay-programmer + technical-artist | M | Drag physics, spring-back, trigger threshold, hook signals for Juice. |
| 10 | Shred Process System | MVP | Core | game-designer + technical-artist | M | Crush timing, debris, internal flash, Mochi reactions, hook signals for Juice. |
| 11 | Product System | MVP | Core | systems-designer + economy-designer | M | 8 products, 80/20 rarity, weighted roll determinism, catalog data structure. |
| 12 | Silhouette Reveal System | MVP | Core | game-designer + technical-artist | M | Silhouette generation from product, pop-out, tap detection, fill animation, hook signals for Juice. |
| **─── Wave 5: Collection ───** | | | | | | |
| 13 | Shelf Collection System | MVP | Core | game-designer + ux-designer | M | Time-ordered display, item view, NO completionism UI. |
| **─── Wave 6: Composition & Onboarding ───** | | | | | | |
| 14 | Scene Composition / Navigation | MVP | Feature | ux-designer + game-designer | S | Main scene ↔ shelf scene + transition. May qualify for quick-spec. |
| 15 | Onboarding / First-Run System | MVP | Feature | game-designer + narrative-director | M | Mochi self-intro + forced special first product. Last — composes everything. |
| **─── Post-MVP (v1.0) ───** | | | | | | |
| 16 | Accessibility System | v1.0 | Polish | accessibility-specialist + ux-designer | M | Full formal GDD. MVP enforces iOS Dynamic Type + Reduce Motion baseline without full doc. |
| 17 | Privacy & Local Data Boundary | v1.0 | Polish | security-engineer + release-manager | S | Audit document — confirms no upload code paths exist. Required for App Store. |

**Effort scale**: S = 1 session (~1-2 hours focused design), M = 2-3 sessions, L = 4+ sessions.

---

## Circular Dependencies

**None found.** The Juice Cookbook ↔ Lever/Shred/Silhouette relationship looks circular but is resolved via the **signal hook pattern**: the Core systems emit Godot signals at hook points (e.g., `lever_released`, `crush_started`, `silhouette_popped`, `reveal_fired`). The Juice layer subscribes to these signals and attaches effects. Core systems do not import or depend on Juice — Juice depends on the *signal contracts* of Core systems but not their implementations.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| **Haptic System** | Technical | iOS Taptic Engine is Pillar 1 quality bar. Godot has no built-in iOS Haptic API — likely needs GDExtension wrap. Android Vibrator fidelity gap is large. | iOS-first design and validation. Plan GDExtension prototype in Wave 1. Android is "degraded fallback" not co-equal. |
| **Audio System** | Design / Resourcing | "Audio is core sensory satisfaction. Amateur audio nullifies machine feel." Concept allocates **audio budget ≥ art budget**. | Outsource SFX OR curate high-quality library OR AI sound tools. Do not let placeholder audio leak into MVP playtest. |
| **Juice Cookbook** | Design | If not codified early, Wave 4 systems will be designed feature-functional but visually bland (the prototype's exact failure mode). | Cookbook ships as Wave 2 (before any Core gameplay system). Every Wave 3+ GDD must show Juice obligations in Tuning Knobs. |
| **Mobile App Lifecycle** | Technical | First-time Godot iOS packaging has unfamiliar pitfalls. IME interruption and background save can corrupt data. | End-to-end packaging dry-run by end of Week 1. Backgrounding test on real device — not simulator — before any other MVP system ships. |
| **Persistence System** | Scope / Architecture | 5 dependent systems. Interface changes propagate widely. No save versioning = locked into one schema forever. | Define save format v1 with version field on day 1. Migration path documented even if unused. Interface stabilized before Wave 3 starts. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 17 |
| Design docs started | 6 (Wave 1: 5 Foundation + Wave 2: Juice Cookbook) |
| Design docs reviewed (initial + 2026-05-22 v3 cross-review) | 5/5 Wave 1 Reviewed |
| Design docs designed pending review | 0（juice-cookbook.md 已评审完成 → NEEDS REVISION） |
| Wave 1 → Wave 2 unlock gate | ✅ PASS（附条件已解除 2026-05-22：ADR-0001/0002 均 Accepted，commit `7689b9c`） |
| Wave 2 Juice Legislation 状态 | ⚠️ Cookbook 8 节 GDD 完成但 /design-review MAJOR REVISION NEEDED（2026-05-22）：12 BLOCKING + 12 Recommended，Wave 3 启动前修复 B1/B2/B5/B6/B11/B12 |
| BLOCKING resolved 2026-05-22 across 3 commits | 11 独立问题 (44bf308: 4 / 9568a3f: 3 + 4 Warnings) |
| MVP systems designed | 6/15 |
| v1.0 systems designed | 0/2 |

### Wave 1 修订路径决策（2026-05-21 → 2026-05-22 收口）

跨文档结构性问题先用 ADR 收敛，再批量修订单 GDD（避免反复返工）。**全部完成**：

1. ✅ **`docs/architecture/adr-0001-foundation-autoload-contract.md`** (Accepted 2026-05-22) — 5 个 Decision：
   - Decision 1: 统一 `is_ready() -> bool` 契约（4 个 Foundation peer 全部实现）
   - Decision 2: Lifecycle App Ready 检查扩展为 4-peer `is_ready()` 查询
   - Decision 3: `preferences` slice 提升为 MVP（`sfx_volume` + `music_volume`，AudioSystem 拥有）+ String 键约束（防 JSON-roundtrip 时 StringName 静默返回 null）
   - Decision 4: 规范 Autoload 注册顺序 `Persistence → Input → Audio → Haptic → Lifecycle`
   - Decision 5（**2026-05-22 新增**）: 新建 `settings` slice（HapticService 拥有 `haptic_enabled`）+ String 键约束泛化至所有 Persistence slice 名 + 键名
2. ✅ **`docs/architecture/adr-0002-anti-pillar-structural-guards.md`** (Accepted 2026-05-22) — Lifecycle 信号订阅 Permitted Subscriber 表 + Forbidden Pattern `lifecycle_signal_analytics_subscription` + Core Rule 11 写入 Lifecycle GDD + Forbidden Pattern 登记至 `docs/registry/architecture.yaml`
3. ✅ **5 个 GDD 全量修订引用新 ADR**：Persistence / Input / Audio / Haptic / Lifecycle 各自 BLOCKING 收口（commit `c38748c` 主修订 + `44bf308` re-review BLOCKING 二修），5 份独立 re-review 全部通过

500KB 长期用户阈值：按 creative-director 裁定，**降级为 v1.0 Roadmap 必做**（多切片迁移路径），不阻塞 MVP。已在 Persistence GDD 中以 v1.0+ 标注。

✅ **preferences slice MVP 决策已落（ADR-0001 Decision 3）+ settings slice 新增（Decision 5）**。Persistence schema 已含两个顶层切片，HapticService `haptic_enabled` 用户开关持久化路径打通。

---

## Carry-forward Constraint from Concept Prototype

> "视觉交互层面还是太寡淡了" — user, 2026-05-21 (concept prototype playtest)

**Implication for every system GDD in this index**: The Tuning Knobs section MUST include a Juice subsection that cites Juice Cookbook principles. Code review (godot-gdscript-specialist) will reject Core gameplay systems whose visual / interaction layer does not exercise the Cookbook's vocabulary (squash & stretch, anticipation, follow-through, screen shake, time-scaling, layered audio, particles, color flashes).

See `prototypes/mochi-concept/README.md` Findings for full context.

---

## Next Steps

- [x] Wave 1 设计 + 评审 + 修订全量完成（2026-05-22，commits `c38748c` + `44bf308` + `9568a3f`）
- [x] ADR-0001（5 Decisions, 含 settings slice）+ ADR-0002 **Accepted 2026-05-22**（per `/architecture-review adr-0001 adr-0002`，报告 `docs/architecture/architecture-review-2026-05-22.md`）
- [x] `/consistency-check`（commit `f9095dc`：4 conflicts resolved）
- [x] `/review-all-gdds` v3（2026-05-22 三轮 cross-review；C1/C2/C3 BLOCKING + C4/C5/C6/C7 Warnings 全部 commit `9568a3f` 修复）
- [x] `/gate-check pre-production` Wave 1→2 unlock checkpoint：**PASS（附条件 → 已解除：两 ADR 已 Accepted）**
- [x] `/architecture-review adr-0001 adr-0002`（10/10 TR 覆盖、0 conflict、首次登记 tr-registry.yaml）
- [x] **Wave 2 `/design-system juice-cookbook`** — ✅ 完成 8 节完整 GDD（升级路径），含 7 个 JC-R 配方 ID + F-1..F-7 公式 + VA-1..VA-7 视觉/音频边界 + 13 条 AC（2026-05-22）
- [x] **`/design-review design/gdd/juice-cookbook.md` Pass 1** — ⚠️ 完成 2026-05-22，Verdict: **MAJOR REVISION NEEDED**（12 BLOCKING + 12 Recommended）
- [x] **`/design-review design/gdd/juice-cookbook.md` Pass 2 cross-review** — ⚠️ 完成 2026-05-22，Verdict 维持 **MAJOR REVISION NEEDED**；新增 5 BLOCKING（B13 WCAG / B14 iOS reduce motion / B15 freeze 技术错误 / B16 5% 覆盖度 / B17 audio specs 跨文档裂缝）+ 2 Recommended + creative-director 提议拆 Layer 1/Layer 2
- [ ] **下一步推荐：另开独立 session 修订 Juice Cookbook** — Pass 2 修复顺序: B13/B14（WCAG + iOS reduce motion MVP BLOCKING）→ B15（freeze 措辞）→ B16/B17（结构变更，与 Layer 1/2 拆分同步）→ Pass 1 B1-B12 → R items。Wave 3 启动前置硬条件: B13/B14/B15/B16/B17 + Pass 1 B1/B2/B5/B6/B11/B12 全部必修
- [ ] Wave 3 启动前置并行任务：（a）真机 spike 校准 audio_lead_ms（OQ-1，B12）；（b）真机 profile 48 颗粒子上限（B7）；（c）technical-director ADR-R 决定 Mobile vs Forward+ renderer（B8）
- [ ] 修订完成后：第二次 `/design-review` 验证（或 since-last-review 模式）→ /consistency-check → 解锁 Wave 3
- [ ] Then Wave 3-6: Mochi Character / Text Input / Lever / Shred / Product / Silhouette / Shelf / Onboarding / Scene Composition（5 Wave）。每个 Core gameplay GDD 的 Tuning Knobs 必须 cite `JC-R1..R7` 对应配方 ID（Cookbook 硬引用合同，code review BLOCKING）
- [ ] 全 MVP GDD 完成 → `/create-architecture` → 真 Pre-Production gate → `/vertical-slice` → enter Production
