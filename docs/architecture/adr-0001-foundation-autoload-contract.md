# ADR-0001: Foundation Autoload Interface Contract

## Status
Proposed

## Date
2026-05-22

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Autoload / Service Initialization) |
| **Knowledge Risk** | HIGH — Godot 4.6 released January 2026, post-LLM training cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `call_deferred` (stable across all 4.x); `is_node_ready()` (available since 4.1, stable); no new post-cutoff APIs required |
| **Verification Required** | (1) Confirm `kyoz/godot-haptics` plugin availability check is synchronous in `_ready()` — if async, HapticService needs a `haptic_initialized` signal and this ADR must be amended; (2) cold start profiling on iPhone SE 2nd gen to confirm `app_ready` fires within 3 s budget |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — first ADR |
| **Enables** | ADR-0002 (Anti-Pillar Structural Guards); all Wave 2 GDD authoring |
| **Blocks** | Wave 2 GDD authoring should not begin until this ADR is Accepted |
| **Ordering Note** | GDD revisions for PersistenceService, HapticService, InputService (MAJOR REVISION already planned), and LifecycleService must complete after this ADR is Accepted but before Wave 2 GDD authoring begins |

## Context

### Problem Statement

Four Foundation Autoloads (PersistenceService, InputService, AudioSystem, HapticService) each define internal APIs, but no shared readiness-interface contract exists across them. Two BLOCKING cross-document breaks were discovered in Wave 1 GDD review:

**Break 1 — Missing readiness API**: LifecycleService Core Rule 2 specifies that its App Ready check queries `AudioSystem.is_ready()` and the `READY_*` state of PersistenceService. `AudioSystem.is_ready()` exists as a "consistency-check 回填" placeholder in Audio GDD Core Rule 10. `PersistenceService` has no `is_ready()` or equivalent state-query method in its API surface. HapticService is not part of the current App Ready check at all. Result: Lifecycle's App Ready formula references a mix of defined and undefined methods — Wave 2 GDDs cannot safely rely on Foundation APIs that are not fully specified.

**Break 2 — `preferences` slice timeline contradiction**: AudioSystem Core Rule 7 specifies that MVP audio volume is persisted in Persistence's `preferences` slice. Persistence schema marks `preferences` as `// reserved for v1.0+`. Result: audio volume resets to default on every cold start in MVP builds, breaking the "seamless toy" experience and violating Audio Core Rule 7.

### Constraints
- Single-developer indie project: minimize architectural surface area
- Mobile iOS primary: cold start must be < 3 s; readiness polling must complete quickly
- Godot 4.6 Autoload `_ready()` is strictly sequential by `project.godot [autoload]` declaration order (engine-verified by `godot-specialist`: no parallel/async Autoload initialization in 4.4/4.5/4.6)
- Foundation Autoloads must not import each other's class names (no circular dependencies)

### Requirements
- A well-typed, GDD-documented readiness query method for LifecycleService to check all Foundation peers
- Resolve the `preferences` slice MVP/v1.0+ contradiction before Wave 2 GDD authoring
- No circular imports between Foundation Autoloads
- No per-frame polling — readiness queried once per cold start only

## Decision

### Decision 1: Universal `is_ready() -> bool` Contract

Every Foundation Autoload MUST expose `is_ready() -> bool` as a public method.

**Semantics**: returns `true` once `_ready()` AND any internal deferred initialization have completed and the service has settled into its operational state. Returns `false` only while the service is in `UNINITIALIZED` (before `_ready()` completes or while internal async work is pending).

**Key nuance on polling**: Because Godot 4.6 Autoload initialization is strictly sequential, all four Foundation peers complete their `_ready()` calls before LifecycleService's `_ready()` runs. The `call_deferred` polling pattern in LifecycleService exists to handle peers that use `call_deferred` internally for async work (e.g., file I/O) after `_ready()` returns — not to wait for `_ready()` itself to be called.

| Autoload | `is_ready() == true` when | GDD update needed |
|----------|---------------------------|-------------------|
| `PersistenceService` | State is any `READY_*` (FRESH / LOADED / CORRUPTED) — not `UNINITIALIZED` | YES — method missing from API |
| `InputService` | State is `GESTURE_MODE` (initial post-`_ready()` state) | YES — add in MAJOR REVISION |
| `AudioSystem` | `_ready()` complete and BGM started (per Core Rule 10) | Formalize placeholder; already partially specified |
| `HapticService` | Plugin capability check complete — both `AVAILABLE` and `UNAVAILABLE` return `true` | YES — method missing from API |
| `LifecycleService` | `app_ready` has been emitted (already in existing API) | No change |

**HapticService UNAVAILABLE special case**: Graceful degradation (no Taptic Engine, plugin not found) is a valid settled state. `is_ready() == true` means "initialization is complete," not "haptic output will fire." This ensures the App Ready check is not permanently blocked on devices without haptic support.

### Decision 2: LifecycleService App Ready Check Extended to All Four Foundation Peers

LifecycleService Core Rule 2 is updated to query `is_ready()` on all four Foundation peers:

```
App Ready condition (polled via call_deferred from LifecycleService._ready()):
  PersistenceService.is_ready() == true
  AND InputService.is_ready() == true
  AND AudioSystem.is_ready() == true
  AND HapticService.is_ready() == true
  → emit app_ready (once, lifetime)
```

No retry loop is needed: all four Autoloads initialize synchronously before LifecycleService. The `call_deferred` handles peers that complete internal async work after `_ready()` returns.

### Decision 3: `preferences` Slice Promoted to MVP Scope

The `preferences` slice in PersistenceService schema is promoted from `// reserved for v1.0+` to MVP-owned with the following locked shape:

```json
"preferences": {
  "sfx_volume": 1.0,
  "music_volume": 1.0
}
```

**Key type constraint — BLOCKING**: Preference key constants MUST be defined as `String` (not `StringName`). `JSON.parse_string()` returns Dictionaries with `String` keys; querying with `StringName` literals (`&"sfx_volume"`) returns `null` in GDScript.

```gdscript
const PREFS_SFX_VOLUME   := "sfx_volume"    # String — NOT &"sfx_volume"
const PREFS_MUSIC_VOLUME := "music_volume"   # String — NOT &"music_volume"
```

- `sfx_volume`: float `[0.0, 1.0]`, default `1.0`. Owned by AudioSystem.
- `music_volume`: float `[0.0, 1.0]`, default `1.0`. Owned by AudioSystem.
- All other `preferences` subkeys remain reserved for v1.0+.

AudioSystem reads preferences via `call_deferred` after `_ready()` (consistent with Persistence Core Rule 10 guidance):

```gdscript
func _ready() -> void:
    # ... bus setup, BGM start ...
    call_deferred("_load_volume_prefs")

func _load_volume_prefs() -> void:
    var prefs: Dictionary = PersistenceService.get_slice("preferences", {})
    _apply_sfx_volume(prefs.get(PREFS_SFX_VOLUME, 1.0))
    _apply_music_volume(prefs.get(PREFS_MUSIC_VOLUME, 1.0))
```

### Decision 4: Canonical Foundation Autoload Registration Order

```
PersistenceService → InputService → AudioSystem → HapticService → LifecycleService
```

Extends and supersedes partial specifications in:
- Persistence Core Rule 10 (PersistenceService first, others unspecified)
- Lifecycle Core Rule 1 (missing HapticService between AudioSystem and LifecycleService)

HapticService is placed before LifecycleService because LifecycleService must poll `HapticService.is_ready()` in its App Ready check (Decision 2).

### Architecture Diagram

```
project.godot [autoload] — strictly sequential in Godot 4.6:

[1] PersistenceService._ready()  →  state: READY_FRESH | READY_LOADED | READY_CORRUPTED
                                      is_ready() == true (any READY_* state)
[2] InputService._ready()        →  state: GESTURE_MODE
                                      is_ready() == true
[3] AudioSystem._ready()         →  buses configured; BGM started
                                      call_deferred → _load_volume_prefs()
                                      is_ready() == true
[4] HapticService._ready()       →  plugin check complete (AVAILABLE | UNAVAILABLE)
                                      is_ready() == true (both states are settled)
[5] LifecycleService._ready()    →  call_deferred: poll all 4 × is_ready()
                                      all true → emit app_ready (once, lifetime)

No class imports between [1]–[4].
Peers referenced by Autoload global name only (PersistenceService, AudioSystem, etc.).
```

### Key Interfaces

```gdscript
# ─── Universal contract — all Foundation Autoloads MUST implement ──────────────
## Returns true once _ready() and any internal deferred initialization are complete.
## Never blocks. Called once by LifecycleService during cold start App Ready check.
func is_ready() -> bool

# ─── PersistenceService: concrete implementation ─────────────────────────────
## Returns true when state is READY_FRESH, READY_LOADED, or READY_CORRUPTED.
## Returns false only during UNINITIALIZED (before _ready() completes).
func is_ready() -> bool:
    return _state in [State.READY_FRESH, State.READY_LOADED, State.READY_CORRUPTED]

# ─── HapticService: concrete implementation ──────────────────────────────────
## Returns true when _ready() is complete and capability check has settled.
## True for both AVAILABLE and UNAVAILABLE — settled state, not output guarantee.
func is_ready() -> bool:
    return is_node_ready()  # _ready() is fully synchronous; is_node_ready() is sufficient

# ─── AudioSystem: formalized from Core Rule 10 placeholder ───────────────────
## Returns true when _ready() is complete and BGM has started.
func is_ready() -> bool:
    return _is_ready  # private bool, set true at end of _ready()

# ─── Preference key constants (AudioSystem) — String type, NOT StringName ────
const PREFS_SFX_VOLUME   := "sfx_volume"    # float [0.0, 1.0], default 1.0
const PREFS_MUSIC_VOLUME := "music_volume"   # float [0.0, 1.0], default 1.0
```

## Alternatives Considered

### Alternative A: Signal-based readiness (`service_ready` signal per Autoload)
- **Description**: Each Foundation Autoload emits `service_ready()` at end of `_ready()`. LifecycleService connects to all four signals and emits `app_ready` when all four fire.
- **Pros**: Fully event-driven; follows Godot signal idioms
- **Cons**: Since Godot 4.6 Autoload initialization is strictly sequential, all four `_ready()` methods complete — and signals are emitted — before LifecycleService's `_ready()` even starts. All signals would be missed unconditionally. `is_ready()` would be required as a "catch already-fired" fallback anyway, negating the approach's benefit entirely.
- **Rejection Reason**: Signal approach structurally cannot work under Godot's synchronous Autoload initialization. The decoupling benefit does not apply here.

### Alternative B: FoundationBus / ServiceLocator pattern
- **Description**: A sixth Autoload (FoundationBus) mediates readiness — each service registers on startup; FoundationBus emits `all_services_ready` when all four register.
- **Pros**: More extensible; services don't know about each other
- **Cons**: Bootstrapping problem (FoundationBus must load before all services but services register during their own `_ready()`); adds a new framework to maintain on a 1-developer project; overkill for 4 stable services
- **Rejection Reason**: Complexity far exceeds benefit for this project's scale and team size.

### Alternative C: Accept volume reset in MVP (`preferences` stays v1.0+)
- **Description**: AudioSystem stores volume in-memory only in MVP or uses an ad-hoc `audio_prefs` slice.
- **Pros**: No Persistence schema change
- **Cons**: Forces volume re-adjustment every session (breaks "seamless toy" promise); Audio Core Rule 7 explicitly requires MVP persistence; ad-hoc slice creates schema sprawl precedent
- **Rejection Reason**: Unacceptable player experience regression. The correct fix is the schema scope, not a workaround.

## Consequences

### Positive
- Wave 2 GDDs can reference Foundation APIs with confidence — all `is_ready()` methods are defined in their source GDDs
- Audio volume persists from MVP day 1 — no volume reset on cold start
- LifecycleService App Ready check is fully verifiable: all four queried methods exist
- `is_ready()` pattern is reusable for any future Foundation Autoload
- AudioSystem preference load via `call_deferred` follows Persistence Core Rule 10 — no new exception to the rule

### Negative
- Four GDD revisions required before re-review: PersistenceService, HapticService, LifecycleService, and AudioSystem
- InputService MAJOR REVISION (already planned) must also include `is_ready()`
- Implementors must remember `String` vs `StringName` distinction for preference key constants — violating this produces a silent Dictionary lookup failure with no runtime error

### Risks
- **`is_ready()` naming similarity to `is_node_ready()`**: `Node` has `is_node_ready()` (Godot 4.1+). `is_ready()` is not a reserved method name and does not conflict. Risk: visual similarity may cause confusion in code review. Mitigation: comment each `is_ready()` implementation with ADR reference; rename to `is_service_ready()` in a future ADR if confusion materializes in practice.
- **HapticService async plugin check**: If `kyoz/godot-haptics` availability check proves to be asynchronous, `is_ready()` may return `false` on LifecycleService's first poll. Mitigation: verify synchronous behavior on real device before implementing; if async, HapticService needs a `haptic_initialized` signal and this ADR must be amended.
- **Large save file parse delay**: PersistenceService JSON parse on unusually large files could theoretically delay `is_ready()`. Mitigation: Formula 1 projects < 500 KB for typical users; JSON parse at that size is < 10 ms on iPhone SE 2nd gen. Cold start profiling required pre-ship.
- **Future preference key type confusion**: New contributors may add `StringName` preference constants and miss the JSON-key constraint. Mitigation: preference constants defined as `String` in this ADR; code review enforces no `&""` literals for preference key constants.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `mobile-app-lifecycle.md` | Core Rule 2: App Ready check calls `AudioSystem.is_ready()` and checks `PersistenceService` state — some methods undefined | Formalizes `is_ready()` on all 4 peers; extends check to include HapticService |
| `persistence-system.md` | API surface missing `is_ready()` needed by LifecycleService | Adds `is_ready() -> bool` to PersistenceService required API |
| `audio-system.md` | Core Rule 7: MVP volume stored in `preferences` slice — slice marked v1.0+ in Persistence | Promotes `preferences` to MVP; locks `sfx_volume`/`music_volume` as String keys |
| `audio-system.md` | Core Rule 10: `is_ready()` marked as "consistency-check 回填" placeholder | Formalizes and locks the contract; removes placeholder status |
| `haptic-system.md` | Not included in Lifecycle App Ready check; `is_ready()` undefined | Adds to App Ready formula (Decision 2); adds `is_ready()` to HapticService required API |
| `mobile-app-lifecycle.md` | Core Rule 1: Autoload order omits HapticService | Establishes canonical 5-entry order including HapticService |

## Performance Implications
- **CPU**: Negligible — four boolean checks, called once per cold start
- **Memory**: Zero — no new state, no new nodes
- **Load Time**: No impact — all initialization already occurs; this ADR adds only readiness query methods
- **Network**: Not applicable

## Migration Plan

1. This ADR Accepted → GDD revisions begin in parallel
2. PersistenceService GDD: add `is_ready() -> bool` to API surface; update `preferences` annotation to MVP with locked shape
3. HapticService GDD: add `is_ready() -> bool` to API surface
4. InputService MAJOR REVISION (already planned): include `is_ready() -> bool` in redesigned API
5. LifecycleService GDD: update Core Rule 1 (add HapticService to order); update Core Rule 2 (4-peer `is_ready()` pattern)
6. AudioSystem GDD: formalize Core Rule 10 (remove placeholder); update Core Rule 7 (add String key names + `call_deferred` note)
7. All GDD revisions complete → run `/consistency-check` to verify cross-document alignment
8. Implementation: each GDD implementor adds `is_ready() -> bool` to their Autoload class

## Validation Criteria
- All four Foundation GDDs (`persistence-system.md`, `audio-system.md`, `haptic-system.md`, `input-system.md`) contain `is_ready() -> bool` in their API surface section
- `persistence-system.md` schema has no `// reserved for v1.0+` annotation on `preferences`; shows `sfx_volume` and `music_volume` with explicit float defaults
- `mobile-app-lifecycle.md` Core Rule 2 calls `is_ready()` on all 4 Foundation peers (no state enum comparisons)
- Codebase grep: no `&"sfx_volume"` or `&"music_volume"` StringName literals (must be String constants)
- Cold start profiling on iPhone SE 2nd gen: `app_ready` signal fires within 3 s from launch
- `app_ready` fires exactly once in a 10-session smoke test

## Related Decisions
- ADR-0002 (planned): Anti-Pillar Structural Guards — may reference Foundation APIs defined here
- `design/gdd/persistence-system.md` — schema and API update required
- `design/gdd/audio-system.md` — Core Rules 7 and 10 become locked contracts
- `design/gdd/mobile-app-lifecycle.md` — Core Rules 1 and 2 revision required
- `design/gdd/haptic-system.md` — `is_ready()` API addition required
- `design/gdd/input-system.md` — `is_ready()` to be added as part of planned MAJOR REVISION
