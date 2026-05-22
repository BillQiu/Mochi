# ADR-0002: Anti-Pillar Structural Guards

## Status
Proposed

## Date
2026-05-22

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Signal Architecture / Design Policy) |
| **Knowledge Risk** | LOW — No post-cutoff engine APIs used; policy enforced via code review + GUT testing |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | `Object.get_signal_connection_list(signal_name)` — available in Godot 4.x — can enumerate all callables connected to a signal at runtime; use in GUT integration test to assert no unauthorized subscribers are present |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Foundation Autoload Interface Contract — defines the Lifecycle signals this ADR governs; must be Accepted) |
| **Enables** | Wave 2 GDD authoring for systems that subscribe to Lifecycle signals (Mochi Character #6, Text Input #7, Scene Composition #15, Onboarding #14) |
| **Blocks** | Wave 2 GDDs that subscribe to Lifecycle signals must appear in the Permitted Subscriber table (Decision 1) before implementation |
| **Ordering Note** | Wave 2 GDDs for signal-subscribing systems should reference this ADR in their Dependencies section and confirm their subscription purpose is listed here |

## Context

### Problem Statement

LifecycleService emits three signals (`app_ready`, `app_paused`, `app_resumed`) that carry implicit behavioral metadata:
- `app_ready` fire time → session start timestamp
- `app_paused` / `app_resumed` pair → session duration
- `app_paused` frequency → usage frequency pattern

Any system subscribing to these signals with the purpose of recording timing data can silently build a behavioral analytics log — even without cloud upload. This violates the Anti-Pillar:

> **"NOT 云同步 / 不上传烦恼内容：玩家写的话只在本地，隐私是默认设置。"**
> — game-concept.md, Anti-Pillars

The Anti-Pillar bans cloud upload, but the spirit of the promise extends to on-device behavioral profiling without player awareness or consent. A "session history" feature or covert analytics system built by subscribing to lifecycle signals would violate this promise even if the data never leaves the device — because it builds a profile of when and how often the player uses the app.

No GDD or ADR currently prohibits this at the code level. Persistence has data-layer protections (Core Rules 4+5) against worry content and backup exposure, but these do not prevent a session analytics system from being added by a well-intentioned future contributor working on a different system.

This ADR closes the signal-subscription layer gap in the Anti-Pillar defense architecture.

### Constraints
- Solo indie project: enforcement must be lightweight (code review + one GUT test is viable)
- Must not restrict legitimate gameplay uses of Lifecycle signals
- Must not break any system interactions specified in the Lifecycle GDD Interactions table
- The Anti-Pillar is a **design pillar** with emotional weight — violations damage the game's promise, not just a compliance checklist item

### Requirements
- Clear, auditable boundary between permitted (gameplay) and forbidden (analytics) signal subscriptions
- Registered Forbidden Pattern in `docs/registry/architecture.yaml` for cross-reference by `/story-readiness` and `/architecture-review`
- Core Rule addition to LifecycleService GDD making the prohibition explicit at the GDD level
- At least one automatable verification path (runtime test or CI script)

## Decision

### Decision 1: Permitted Subscriber Doctrine

Subscriptions to LifecycleService signals are governed by a **Permitted Purpose** rule:

> **A system may subscribe to a LifecycleService signal if and only if the subscription's purpose is to change gameplay, UI, visual, audio, or haptic state in direct response to the lifecycle event.**
>
> **Subscribing to any Lifecycle signal for the purpose of recording timing data, computing session duration, counting session frequency, or building any behavioral usage log — on-device or off-device — is a Forbidden Pattern.**

**Permitted subscribers (current, provisional):**

| Signal | Permitted Subscriber | Permitted Purpose |
|--------|---------------------|------------------|
| `app_ready` | Scene Composition (#15) | Present main scene (gameplay state change) |
| `app_ready` | Onboarding (#14) | Check `first_run_complete` flag (gameplay gate) |
| `app_ready` | Mochi Character (#6) | Start first-frame idle animation (visual state change) |
| `app_paused` | Mochi Character (#6) | Pause idle/blink animation (visual state change) |
| `app_resumed` | Mochi Character (#6) | Resume idle/blink animation (visual state change) |
| `app_resumed` | Text Input (#7) | Decide whether to request IME focus (gameplay state change) |
| `app_resumed` | Scene Composition (#15) | Optional re-validate UI integrity (visual state change) |

This table is **provisional** — it will be filled out as Wave 2 GDDs are authored. A subscriber not in this table that wishes to subscribe must first add itself here via a GDD update + ADR amendment + `/architecture-review` pass.

### Decision 2: Forbidden Pattern — `lifecycle_signal_analytics_subscription`

The following is a Forbidden Pattern, registered in `docs/registry/architecture.yaml`:

**Forbidden**: Subscribing to `LifecycleService.app_ready`, `app_paused`, or `app_resumed` with any of the following intents:
- Recording the timestamp when the signal fires
- Computing or storing session duration (time between `app_ready` and `app_paused`, or between `app_resumed` and `app_paused`)
- Counting session frequency ("how many times has the user opened the app")
- Building any log of "when / how often the player used the app"
- Passing lifecycle timing data to PersistenceService (directly or indirectly)

**Applies regardless of whether data is uploaded.** On-device session profiling violates the Anti-Pillar even if it never leaves the device.

### Decision 3: LifecycleService Core Rule 11 — Anti-Pillar Signal Guard

A new Core Rule is added to `design/gdd/mobile-app-lifecycle.md`:

> **Core Rule 11 — Anti-Pillar Signal Guard (ADR-0002)**: Subscriptions to `app_ready`, `app_paused`, and `app_resumed` MUST be for gameplay, UI, visual, audio, or haptic state changes only. Subscribing to record timing data, compute session duration, count session frequency, or build any behavioral usage log is a Forbidden Pattern (per ADR-0002, registered in `docs/registry/architecture.yaml`). Any new subscriber must appear in the ADR-0002 Permitted Subscriber table before the subscription is implemented.

### Decision 4: Lifecycle Signal Annotation Convention

All three restricted signals in `LifecycleService.gd` MUST carry a `[RESTRICTED]` doc comment line:

```gdscript
## [RESTRICTED — ADR-0002] Permitted for gameplay/UI/visual/audio/haptic state changes only.
## Analytics subscriptions (timing, duration, frequency) are a Forbidden Pattern.
## New subscribers must be added to docs/architecture/adr-0002-anti-pillar-structural-guards.md.
signal app_ready()

## [RESTRICTED — ADR-0002] See above.
signal app_paused()

## [RESTRICTED — ADR-0002] See above.
signal app_resumed()
```

This is a project-internal convention; Godot has no native signal access control. The annotation makes the restriction visible at the point of declaration — the most effective time to inform a new contributor.

### Decision 5: Automated Verification via `get_signal_connection_list()`

A GUT integration test MUST verify that no unauthorized subscribers are connected to Lifecycle signals after scene initialization. Implementation pattern:

```gdscript
func test_lifecycle_signals_have_no_analytics_subscribers() -> void:
    var lifecycle := get_tree().root.get_node("LifecycleService")
    for signal_name in [&"app_ready", &"app_paused", &"app_resumed"]:
        var connections: Array = lifecycle.get_signal_connection_list(signal_name)
        for connection in connections:
            var obj: Object = connection["callable"].get_object()
            # Each connected object must be in the permitted subscriber list
            assert_true(
                obj is MochiCharacter or obj is TextInput or
                obj is SceneComposition or obj is Onboarding,
                "Unauthorized subscriber to %s: %s" % [signal_name, obj.get_class()]
            )
```

This test is non-exhaustive (it checks at a single point in time, not all possible connections) but catches accidental additions in the main game scene. It must be updated when new permitted subscribers are added to Decision 1.

### Architecture Diagram

```
Anti-Pillar defense layers (complementary, each closes a different gap):

[Layer 1] Data content guard (Persistence Core Rules 4+5):
          → Prevents worry text and precise timestamps in save.json
          → `_written_at_day` rounded to day — no second-precision session timing

[Layer 2] Backup / cloud guard (Persistence Core Rule 5):
          → save.json excluded from iCloud backup (NSURLIsExcludedFromBackupKey)

[Layer 3] Signal subscription guard (THIS ADR):
          → Lifecycle signals restricted to gameplay purposes
          → Enforced by: Forbidden Pattern registry + Core Rule 11 + [RESTRICTED] annotation
          → Verified by: GUT test (get_signal_connection_list) + CI grep/rg scan

[Layer 4] Network I/O prohibition (Anti-Pillar, game-concept.md):
          → No network calls in Foundation Autoloads (design intent)
          → Not yet formalized as ADR — candidate for ADR-0003 if needed
```

### Key Interfaces

This ADR restricts usage of existing interfaces, not new ones.

```gdscript
# ─── Permitted connection patterns ────────────────────────────────────────────
# GAMEPLAY use: change visual/animation/audio/haptic state
LifecycleService.app_paused.connect(_pause_mochi_animation)      # ✅ Mochi Character
LifecycleService.app_resumed.connect(_restore_ime_if_needed)     # ✅ Text Input
LifecycleService.app_ready.connect(_present_main_scene)          # ✅ Scene Composition

# ─── Forbidden connection patterns ────────────────────────────────────────────
# FORBIDDEN: timestamp recording
# LifecycleService.app_ready.connect(func(): _session_start = Time.get_ticks_msec())

# FORBIDDEN: session counting
# LifecycleService.app_paused.connect(func(): _total_sessions += 1; Persistence.set_slice(...))

# FORBIDDEN: duration computation
# LifecycleService.app_resumed.connect(func(): _last_resume_time = Time.get_ticks_msec())
# LifecycleService.app_paused.connect(func():
#     var dur = Time.get_ticks_msec() - _last_resume_time
#     _total_playtime_ms += dur)
```

## Alternatives Considered

### Alternative A: Purpose-tagged signal parameters
- **Description**: Signals carry a `SignalPurpose` enum; subscribers must declare `GAMEPLAY` or `ANALYTICS`
- **Pros**: Analytics use becomes code-visible; toolable with lint rules
- **Cons**: Modifies signal signatures established in ADR-0001; protection is trivially circumvented (pass `GAMEPLAY` to avoid the guard); adds boilerplate to every subscriber
- **Rejection Reason**: A guard that's trivially bypassed provides false security. Code review + runtime test achieves comparable protection without API complexity.

### Alternative B: AnalyticsBus isolation layer
- **Description**: Session-timing data must route through a `SessionMonitor` Autoload explicitly forbidden from network I/O
- **Pros**: Clear "analytics-safe zone"; any analytics system becomes architecturally visible
- **Cons**: Doesn't prevent original violation (Lifecycle signals can still be subscribed for analytics outside SessionMonitor); "safe analytics" framing contradicts the Anti-Pillar which bans on-device behavioral profiling entirely
- **Rejection Reason**: Mochi's Anti-Pillar bans session profiling regardless of destination. A "safe analytics container" is the wrong framing for this game's values.

## Consequences

### Positive
- Anti-Pillar is now defended at three independent architectural layers
- Wave 2 GDDs have a clear compliance template: subscribe to Lifecycle signals only for gameplay purposes, appear in Permitted Subscriber table
- Future contributors encounter `[RESTRICTED]` annotation and Forbidden Pattern before adding analytics — no accidental violations
- One automatable GUT test catches the most likely violation vector (unexpected subscriber added to main scene)
- The emotional promise "your data stays private" is structurally backed, not just aspirationally stated

### Negative
- New legitimate Lifecycle signal subscribers require ADR amendment — minor process overhead
- Code review remains primary enforcement for new subscriptions added outside the main scene test fixture

### Risks
- **Permitted list is provisional**: Wave 2 GDDs may reveal subscribers not yet listed. Mitigation: Decision 1 specifies the amendment process; the provisional label is explicit.
- **Boundary ambiguity for future features**: A "show the player their own session stats" feature (e.g., "you've used Mochi 47 times") would require explicit ADR exception with player consent mechanism. This friction is intentional — that feature should be a deliberate decision, not an accident.
- **GUT test is point-in-time**: `get_signal_connection_list()` catches subscribers connected at scene init but not dynamic connections added later. Mitigation: CI grep scan covers static `connect()` calls in source code regardless of timing.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `game-concept.md` | Anti-Pillar: "不上传烦恼内容 / 隐私是默认设置" | Extends Anti-Pillar from design-concept declaration to architectural signal-layer enforcement with Forbidden Pattern |
| `mobile-app-lifecycle.md` | Lifecycle signals carry implicit session timing metadata with no subscriber restriction | Adds Core Rule 11 prohibiting analytics subscriptions; formalizes provisional Permitted Subscriber table |
| `persistence-system.md` | Core Rules 4+5 protect data content and iCloud backup | Acknowledges existing Layer 1+2 protections; this ADR adds complementary Layer 3 (signal guard) |

## Performance Implications
- **CPU**: None — policy decision; one GUT test adds negligible test-only overhead
- **Memory**: None
- **Load Time**: None
- **Network**: None — this ADR specifically prevents network-adjacent behavior from being introduced

## Migration Plan
1. This ADR Accepted → LifecycleService GDD gains Core Rule 11
2. `docs/registry/architecture.yaml` gains `lifecycle_signal_analytics_subscription` Forbidden Pattern
3. LifecycleService implementation file gains `[RESTRICTED]` annotations on all three signals
4. GUT test added to `tests/integration/lifecycle/` verifying permitted subscribers only
5. CI script added scanning for new `app_paused/resumed/ready` connect calls (grep/rg)
6. Wave 2 GDDs (Mochi Character, Text Input, Scene Composition, Onboarding) added to Permitted Subscriber table as they are authored

## Validation Criteria
- `mobile-app-lifecycle.md` contains Core Rule 11 with explicit analytics subscription prohibition
- `docs/registry/architecture.yaml` contains `lifecycle_signal_analytics_subscription` Forbidden Pattern
- GUT test in `tests/integration/lifecycle/` passes: `get_signal_connection_list()` returns only permitted subscribers for all three Lifecycle signals
- CI grep/rg scan finds zero `app_paused.connect(` / `app_resumed.connect(` / `app_ready.connect(` calls outside the files listed in the Permitted Subscriber table
- `/architecture-review` confirms no prohibited subscriptions across all GDDs

## Related Decisions
- ADR-0001: Foundation Autoload Interface Contract — defines the Lifecycle signals this ADR governs
- `design/gdd/mobile-app-lifecycle.md` — Core Rule 11 addition required
- `design/gdd/game-concept.md` — source of Anti-Pillar definition (no changes needed)
- `design/gdd/persistence-system.md` — existing Layer 1+2 guards (no changes needed)
- ADR-0003 (potential future): Network I/O prohibition for Foundation Autoloads — Layer 4 guard
