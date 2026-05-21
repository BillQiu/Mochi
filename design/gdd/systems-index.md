# Systems Index: Mochi

> **Status**: Draft
> **Created**: 2026-05-21
> **Last Updated**: 2026-05-21
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
| 1 | Persistence System | Persistence | MVP | **Designed** (pending review) | design/gdd/persistence-system.md | — |
| 2 | Input System (inferred) | Core | MVP | Not Started | design/gdd/input-system.md | — |
| 3 | Audio System | Audio | MVP | Not Started | design/gdd/audio-system.md | — |
| 4 | Haptic System | Core | MVP | Not Started | design/gdd/haptic-system.md | — |
| 5 | Mobile App Lifecycle (inferred) | Core | MVP | Not Started | design/gdd/mobile-app-lifecycle.md | — |
| 6 | Mochi Character System | Gameplay | MVP | Not Started | design/gdd/mochi-character.md | Audio, Mobile Lifecycle |
| 7 | Text Input System | Gameplay | MVP | Not Started | design/gdd/text-input.md | Input, Persistence, Mobile Lifecycle |
| 8 | Lever Interaction System | Gameplay | MVP | Not Started | design/gdd/lever-interaction.md | Input, Audio, Haptic, Juice Cookbook |
| 9 | Shred Process System | Gameplay | MVP | Not Started | design/gdd/shred-process.md | Audio, Haptic, Mochi Character, Juice Cookbook |
| 10 | Product System | Economy | MVP | Not Started | design/gdd/product-system.md | Persistence |
| 11 | Silhouette Reveal System | Gameplay | MVP | Not Started | design/gdd/silhouette-reveal.md | Product, Input, Audio, Haptic, Juice Cookbook |
| 12 | Shelf Collection System | Gameplay | MVP | Not Started | design/gdd/shelf-collection.md | Persistence, Product |
| 13 | Game Feel / Juice Cookbook ⭐ | Meta | MVP | Not Started | design/gdd/juice-cookbook.md *(type: cookbook, not GDD)* | Audio, Haptic |
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
| 6 | Juice Cookbook | MVP | Feature | art-director + audio-director + technical-artist | S | NOT a full GDD — short reference doc (~500 words) defining principles, vocabulary, and forbidden patterns. All later Core GDDs must reference. |
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
| Design docs started | 1 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 1/15 |
| v1.0 systems designed | 0/2 |

---

## Carry-forward Constraint from Concept Prototype

> "视觉交互层面还是太寡淡了" — user, 2026-05-21 (concept prototype playtest)

**Implication for every system GDD in this index**: The Tuning Knobs section MUST include a Juice subsection that cites Juice Cookbook principles. Code review (godot-gdscript-specialist) will reject Core gameplay systems whose visual / interaction layer does not exercise the Cookbook's vocabulary (squash & stretch, anticipation, follow-through, screen shake, time-scaling, layered audio, particles, color flashes).

See `prototypes/mochi-concept/README.md` Findings for full context.

---

## Next Steps

- [ ] Begin Wave 1: design Persistence, Input, Audio, Haptic, Mobile Lifecycle (parallel within wave)
- [ ] Begin with `/design-system persistence-system` or `/map-systems next`
- [ ] After each GDD: run `/design-review design/gdd/[system].md` in a fresh session
- [ ] After all MVP GDDs are written: run `/review-all-gdds` for cross-system consistency
- [ ] When all 15 MVP GDDs are reviewed: run `/gate-check pre-production`
- [ ] Then: `/create-architecture` → `/vertical-slice` → enter Production
