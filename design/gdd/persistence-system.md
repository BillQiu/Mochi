# Persistence System

> **Status**: In Design
> **Author**: game-designer (main) + godot-gdscript-specialist (engine integration)
> **Last Updated**: 2026-05-21
> **Last Verified**: 2026-05-21
> **Implements Pillar**: Pillar 5 (Unlimited But Meaningful) + Anti-Pillar (no cloud sync, no upload)

## Summary

The Persistence System is Mochi's local data layer — a single Godot service responsible for reading and writing all player state to the device's `user://` directory. It owns the save schema, version field, and atomic-write contracts that every gameplay system uses to remember anything across sessions: collected products, worry-input history (for 24h dedup), the first-run flag, and future preferences. It exists because Mochi is offline-only by anti-pillar (never upload), and because mobile apps can be killed mid-write — making save reliability a structural concern, not polish.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (zero upstream)`

## Overview

Persistence is a thin Godot service — likely a single Autoload singleton — that owns the contract between every gameplay system and the device's local file system. It exposes a small, typed API for reading and writing well-defined save slices (collection, worry history, first-run flag, future preferences) and is the only place in the project where `FileAccess` or `JSON.stringify` is called directly. The system enforces three structural guarantees: writes are atomic (no partial files left if the app is killed mid-save), the on-disk format carries an explicit version field from day one (so v1.0+ migrations don't break v1.0 saves), and write failures are surfaced rather than silently swallowed — because Godot 4.4+ changed `FileAccess.store_*` to return `bool`, and ignoring that return is how data-loss bugs slip into production. Persistence has no UI of its own; players see only its effects (the shelf remembers their products, their worries don't repeat, the app starts where they left off).

## Player Fantasy

Persistence is invisible infrastructure — players never see or interact with it directly. There is no fantasy attached to "saving" itself: nobody opens Mochi because they enjoy save files. Instead, this system **enables** the fantasies of every gameplay system that depends on it.

Two pillar obligations Persistence carries on behalf of other systems:

- **Pillar 3 (Collection Without Pressure)** — the shelf must feel like *the player's personal archive* that quietly accumulates over months and years. That archive is durable, "theirs," and trustworthy only because Persistence makes the save bulletproof. Lose one shelf entry mid-save because the app got killed → the fantasy of "everything I put in is mine forever" collapses. The shelf's emotional weight is borrowed from Persistence's reliability.

- **Pillar 5 + Anti-Pillar (Unlimited But Meaningful / Never Upload)** — Mochi promises that the worries players write *stay private*. This promise is structural, not behavioural: it is satisfied by Persistence writing to the local sandbox only and *never* shipping data off-device. Players don't think about this — but the moment a single feature violates it (analytics that capture text, cloud sync, "share your shelf"), the entire game's emotional contract breaks. Persistence is the structural guardian of that promise.

What players feel: nothing, directly. What they *don't* feel — and shouldn't have to think about — is that their data could disappear or leak. **The success criterion for this fantasy is the absence of doubt.**

## Detailed Design

### Core Rules

1. **Single save path**: `user://save.json`. Mochi writes no other persistent files outside this directory.
2. **File schema** — top-level JSON object with reserved keys:
   ```json
   {
     "_version": 1,
     "_written_at": <unix_ts>,
     "collection":     { ... },
     "worry_history":  { ... },
     "flags":          { ... },
     "preferences":    { ... }   // reserved for v1.0+
   }
   ```
3. **Slice contract**: Persistence reads/writes only top-level slice keys. Each slice's internal shape is owned by the domain system that writes it — Persistence does not validate slice content.
4. **Atomic writes**: every save writes to `user://save.json.tmp`, calls `flush()`, then `DirAccess.rename_absolute()` to `save.json`. The rename is atomic at the OS level on iOS and Android.
5. **Write-failure detection (HIGH RISK)**: every `FileAccess.store_*` and every rename call MUST check its `bool` return value. On failure, emit `save_failed(slice, reason)` — **never silently swallow**. Godot 4.4+ changed `FileAccess.store_*` from `void` to `bool`; missed checks become silent data-loss bugs in production.
6. **Save timing**:
   - **Event-triggered**: domain systems call `Persistence.save_now()` after any user-visible state change (product collected, worry recorded, onboarding completed).
   - **Lifecycle-triggered**: Persistence subscribes to `NOTIFICATION_APPLICATION_PAUSED` and `NOTIFICATION_WM_GO_BACK_REQUEST`; both invoke `save_now()` as belt-and-suspenders against the OS killing the app.
   - **No periodic save loop**: Mochi's write frequency is inherently low; periodic saves only add wear.
7. **Load policy** (on Autoload `_ready()`):
   - File missing → treat as fresh install; in-memory cache is `{}`; do not write to disk until first event-triggered save.
   - File present but `JSON.parse_string()` fails → back up corrupted file to `user://save.json.corrupted.<unix_ts>`; treat as fresh install. **Never automatically delete a corrupted file.**
   - `_version` missing → reject (defensive against legacy/foreign schema collision).
   - `_version` newer than current → log warning, best-effort read of known keys; do not destroy data.
   - `_version` older → run migration chain (see Edge Cases).
8. **API surface** — single Autoload singleton:
   ```gdscript
   class_name PersistenceService extends Node

   signal save_failed(slice_name: String, reason: String)
   signal save_succeeded(slice_name: String)

   ## Read a slice. Returns deep copy. Returns `default` if slice missing.
   func get_slice(slice_name: String, default: Variant = {}) -> Variant

   ## Write a slice. Updates in-memory cache only — does NOT write to disk.
   func set_slice(slice_name: String, data: Variant) -> void

   ## Flush all in-memory slices to disk atomically. Returns true on success.
   func save_now() -> bool

   ## Was there a save file on disk before this session started?
   func has_existing_save() -> bool
   ```
9. **Domain-agnostic**: Persistence source code MUST NOT contain business strings like `"products"`, `"worries"`, `"flags"`. Slice names are passed in by callers. Enforced by a grep-based test.
10. **Thin wrapper convention**: every domain system (e.g., `WorryHistory`, `ProductInventory`, `FirstRunFlag`) owns its own thin wrapper that calls `Persistence.get_slice(...)` / `set_slice(...)`. Wrappers live in the domain system's directory, NOT in Persistence's. Persistence does not import them.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|----------------|----------|
| `UNINITIALIZED` | Autoload constructed, `_ready()` not yet run | `_ready()` completes | API calls return defaults; `save_now()` is no-op + warning log |
| `READY_FRESH` | `_ready()` ran, no save file found | First `save_now()` call | In-memory cache is `{}`; `has_existing_save() = false` |
| `READY_LOADED` | `_ready()` ran, save file parsed OK | App quit | In-memory cache mirrors disk; `has_existing_save() = true` |
| `READY_CORRUPTED` | `_ready()` ran, file present but unparseable | First `save_now()` call | Corrupted file backed up; cache is `{}`; emits `save_failed` once on entry |
| `SAVING` | `save_now()` invoked | Disk write completes (success or failure) | Reentrant calls block until current write finishes (queue depth: 1) |

**Transitions**: `UNINITIALIZED` → one of `READY_FRESH | READY_LOADED | READY_CORRUPTED`. Any `READY_*` → `SAVING` via `save_now()`. `SAVING` → `READY_LOADED` on both success and failure (cache stays valid in memory even if disk write failed; `save_failed` emitted on failure).

### Interactions with Other Systems

Persistence is the **sole owner** of `user://save.json`. Every other system interacts through the typed slice contract, never via direct file access.

| System | Interaction | Slice Name |
|--------|-------------|------------|
| **Text Input** | `get_slice("worry_history", [])` for dedup check; `set_slice("worry_history", updated)` + `save_now()` after recording | `worry_history` (owns) |
| **Product System** | `get_slice("collection", [])`; `set_slice("collection", updated)` + `save_now()` after roll | `collection` (owns) |
| **Shelf Collection** | Reads `get_slice("collection", [])` only; does not write | `collection` (reads) |
| **Onboarding** | `get_slice("flags", {}).get("first_run_complete", false)` gate; `set_slice("flags", {...})` + `save_now()` on completion | `flags` (owns `first_run_complete`) |
| **Scene Composition** | OPTIONAL: `get_slice("flags", {}).get("last_scene", "main")`; `set_slice` on scene transition | `flags` (owns `last_scene`) |
| **Mobile App Lifecycle** | Persistence internally subscribes to its `app_paused` / `app_back_requested` signals and calls `save_now()` automatically | (Persistence is the consumer) |

> ⚠️ **Provisional Contract**: the 5 downstream GDDs (Text Input, Product, Shelf, Onboarding, Scene Composition) are not yet written. When designed, they MUST conform to the slice names and contract shapes above. Any deviation requires updating this GDD via `/consistency-check`.

## Formulas

> Persistence's "formulas" are engineering budgets and projections, not gameplay
> math. **Lean mode**: `systems-designer` not spawned because the expertise
> domain is engine-perf, not balance design. **`godot-specialist` sign-off
> required pre-implementation** for Formula 1 base_overhead measurement and
> Formula 3 latency budgets on iPhone SE (2nd gen) reference hardware.

### Formula 1 — Save File Size Projection

```
estimated_bytes = base_overhead
                + (avg_product_bytes  × collection_count)
                + (avg_worry_entry_bytes × worry_history_count)
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_overhead` | b₀ | int | 80-150 | JSON schema overhead: top-level keys, `_version`, `_written_at`, brackets |
| `avg_product_bytes` | b_p | int | 80-200 | Serialized bytes per product entry (id, time, rarity, colour) |
| `collection_count` | n_c | int | 0-1000+ | Entries in `collection` slice |
| `avg_worry_entry_bytes` | b_w | int | 60-100 | Bytes per `{hash, timestamp_unix}` worry-history entry |
| `worry_history_count` | n_w | int | 0-1500 | Active worry hashes (bounded above by Formula 2 pruning) |

**Output Range**:
- Fresh install: ~150 B
- Typical week-1 user: 1-3 KB
- Typical month-1 user: 5-10 KB
- Heavy use 1 year: ~30-50 KB
- **Re-design threshold: 500 KB** — triggers migration to multi-slice files (this GDD must be revised).

**Example**: 50 products (80 B each) + 200 worry hashes (60 B each) + 100 B overhead = **16,100 B ≈ 16 KB** ✓ well under threshold.

### Formula 2 — Worry History Pruning Predicate

```
should_keep(entry, now) = (now - entry.timestamp_unix) ≤ PRUNE_THRESHOLD_SECONDS
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `entry.timestamp_unix` | int | Unix epoch | When worry was recorded |
| `now` | int | Unix epoch | Current Unix time |
| `PRUNE_THRESHOLD_SECONDS` | int | constant **90,000** | 25 hours = 24h dedup requirement + 1h safety buffer |

**Output**: boolean. Pruning runs on every `save_now()` invocation; cost is negligible since `worry_history_count ≤ ~1500`.

**Edge Case**: If the device clock moves backward (DST, manual change), some entries may persist longer than 25 h. **Acceptable** — pruning is opportunistic; strict dedup is enforced in real time by the Text Input system, not Persistence.

**Example**: entry at `1717000000`, now = `1717090000` → diff = 90,000 ≤ 90,000 → keep. One second later → prune.

### Formula 3 — `save_now()` Latency Budget

Tiered budget on iPhone SE (2nd gen) reference hardware:

| Save File Size | Target Latency | Action if Exceeded |
|----------------|----------------|--------------------|
| < 10 KB | < 30 ms | Normal sync save |
| 10-50 KB | < 60 ms | Normal sync save |
| 50-200 KB | < 100 ms | Normal sync save |
| 200-500 KB | < 150 ms | Evaluate async / threaded save |
| > 500 KB | — | **Re-design** — Formula 1 threshold reached; migrate to multi-slice files |

**Variables**:
- `save_file_bytes`: bytes written to disk in current `save.json` (estimated from Formula 1)
- `target_latency_ms`: maximum allowed `save_now()` wall-clock time on reference device

**Edge Case**: If the device has not warmed up FileAccess, the first cold write may double its budget. **Mitigation**: in Persistence `_ready()`, write a `user://.warmup` empty file and immediately delete it, priming FileAccess's internal paths before any real save.

**Example**: 16 KB save file → expected 30-60 ms. If measured 80 ms, still in band; if > 100 ms, **investigate** — do not accept silently.

## Edge Cases

Grouped by risk class. Format: `If [condition]: [outcome]. [rationale]`.

### A. Write / Load Failures

- **If app is killed mid-write** (between `FileAccess.open` and `rename`): the partial `save.json.tmp` may remain on disk but `save.json` is unchanged (atomic-rename guarantee). On next launch, `_ready()` cleans up orphan `.tmp` files before loading. **No data loss.**
- **If `JSON.parse_string()` fails on load**: back up corrupted file to `user://save.json.corrupted.<unix_ts>`, log error, enter `READY_CORRUPTED`, emit `save_failed("load", "json_parse_error")`. Game proceeds as fresh install but **never automatically deletes** the corrupted file (preserved for user-side recovery / developer debugging).
- **If disk is full** (`FileAccess.store_*` or rename returns `false`): emit `save_failed(slice, "disk_full_or_io_error")`. In-memory cache stays valid; next `save_now()` will retry. Game does not crash. User-facing notification is owned by Scene Composition / UX, not Persistence.

### B. Version Mismatches

- **If `_version` is newer than current Persistence's known version** (e.g., user installed v1.5 then downgraded to v1.0): do **not** destroy data. Log warning, attempt best-effort read of known slice keys, ignore unknown keys. *Rationale*: forward-compat protects the shelf from being wiped on rollback.
- **If `_version` is older**: run migration chain. Migrations are pure functions registered in order (`migrate_v1_to_v2(data)`, `migrate_v2_to_v3(data)`, …). If any migration step throws, back up pre-migration file to `user://save.json.pre_migration.<unix_ts>` and treat as fresh install. **Never destroy data silently.**

### C. State / Concurrency

- **If two callers `set_slice("flags", ...)` in the same frame** with different values: last call wins for the in-memory cache. Persistence does **not** merge slice contents — merge responsibility belongs to the domain wrapper, which must read-modify-write atomically within itself. Document this in domain wrapper guidelines.
- **If `save_now()` is called during `SAVING` state**: the new call blocks until the current write completes. Queue depth is 1 — multiple `save_now()` invocations during a save **coalesce** into one additional save with the latest in-memory state.
- **If `get_slice` is called during `SAVING`**: returns current in-memory cache (which IS the data being written). No locking needed because writes happen on the main thread. *If save is ever moved to a worker thread, this rule must be revisited.*

### D. Platform / Clock

- **If device clock moves backward** (DST, manual change): Formula 2 pruning may keep worry entries longer than 25h. **Acceptable** — Text Input enforces strict dedup separately. Forward jumps (rare; GPS sync after travel) may prune earlier; same acceptable rationale.
- **If iOS user offloads the app and re-downloads**: `NSDocumentDirectory` is preserved per Apple's docs. `user://save.json` survives. No special handling.
- **If user deletes the app and reinstalls**: `user://` is wiped per iOS sandbox rules. Treat as fresh install. **If iCloud Backup is enabled at OS level**, save may restore automatically — see Open Questions for backup-exclusion policy.

### E. API Misuse

- **If a slice name is empty or contains characters outside `[a-z_][a-z0-9_]*`**: `set_slice` returns early + logs error. Enforced via `assert()` in dev builds; silent log + no-op in release builds.

## Dependencies

### Upstream — This system depends on

**NONE.** Persistence is Foundation-layer. It consumes only Godot's raw OS notifications (`NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_WM_GO_BACK_REQUEST`) directly, **not** through the Mobile App Lifecycle wrapper. This keeps Persistence zero-upstream — designable, implementable, and testable in isolation before any other system exists.

### Downstream — Depended on by

| System | Direction | Nature | Hard / Soft | Interface |
|--------|-----------|--------|-------------|-----------|
| **Text Input** | Text Input → Persistence | Data (read+write) | **Hard** — 24h dedup state must survive sessions | `get_slice("worry_history", [])` / `set_slice("worry_history", updated)` + `save_now()` |
| **Product System** | Product → Persistence | Data (read+write) | **Hard** — collection IS persistent state | `get_slice("collection", [])` / `set_slice("collection", updated)` + `save_now()` |
| **Shelf Collection** | Shelf → Persistence | Data (read-only) | **Hard** — Shelf has no other source of collection data | `get_slice("collection", [])` |
| **Onboarding** | Onboarding → Persistence | Data (read+write) | **Hard** — first-run gating relies on persistent flag | `get_slice("flags", {}).get("first_run_complete", false)` / `set_slice("flags", {...})` + `save_now()` |
| **Scene Composition** | Scene → Persistence | Data (read+write) | **Soft** — `last_scene` is a convenience for resume; default `"main"` works without it | `get_slice("flags", {}).get("last_scene", "main")` / `set_slice` |

### Cross-cutting (subscriber, not bidirectional dependency)

| System | Relationship | Description |
|--------|--------------|-------------|
| **Game Feel / Juice Cookbook** | Persistence emits signals (`save_failed`, `save_succeeded`) | UI / VFX layer MAY subscribe to provide micro-feedback on save failure (e.g., subtle toast on `save_failed`). Implementation-optional; not a contract. |

### Bidirectional Consistency — open items

All 5 downstream GDDs are currently unwritten. When designed, each must list "depends on Persistence" in its own Dependencies section and reference the slice name(s) it owns or reads. `/consistency-check` validates this.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------------|------------|--------------------|--------------------|
| `PRUNE_THRESHOLD_SECONDS` *(Formula 2 constant)* | **90,000** (25 h) | 86,400 — 172,800 | Larger `worry_history` file; longer dedup grace window | Aggressive pruning; risk losing dedup signal at window edge |
| `MAX_WORRY_HISTORY_ENTRIES` *(hard cap, defensive)* | **1,500** | 500 — 5,000 | Larger save file; longer Formula 1 projection; more memory | Smaller save file; faster ops; may evict still-relevant hashes for heavy writers |
| `WARMUP_ENABLED` *(Formula 3 Edge Case mitigation)* | **true** | true / false | `_ready()` writes throwaway `.warmup` file; first save meets latency budget | First save may exceed Formula 3 budget; cleaner `_ready()` log |
| `CORRUPTED_BACKUP_RETENTION_DAYS` | **0 (indefinite)** | 0 / 30 / 90 / 365 | Backup files kept forever; safer recovery; minor disk bloat | Auto-delete `.corrupted` files after N days; cleaner sandbox; risk losing recoverable data |
| `SAVE_FILE_SIZE_WARNING_KB` | **100** | 50 — 500 | Earlier log warning; more monitoring noise; preemptive of Formula 1 threshold | Later warning; less actionable signal |

### Cross-references

- `PRUNE_THRESHOLD_SECONDS` is the source of truth for Formula 2's constant of the same name. Formula 2 references this knob, not the literal value.
- `MAX_WORRY_HISTORY_ENTRIES` corresponds to the upper bound of Formula 1's `worry_history_count`.
- Formula 1's 500 KB re-design threshold is **not** listed as a knob — it is an architecture-decision trigger, not a daily tunable.

### Explicitly NOT knobs

- `SAVE_PATH = "user://save.json"` — iOS sandbox path is a hard constraint, not designer-tunable.
- `SAVE_FORMAT = "json"` — switching the on-disk format is an ADR-level decision (would supersede ADR-0001 if/when created), not a tuning operation.
- Save-rate throttle — queue depth 1 already coalesces; no need for an explicit rate cap.
- Encryption toggle — MVP does not encrypt local saves; if added later, the decision is an ADR, not a knob.

## Visual/Audio Requirements

Persistence is invisible infrastructure with no direct visual or audio output. It MAY emit two signals that the Game Feel / Juice layer can subscribe to for player-facing micro-feedback:

| Signal | Suggested Feedback (owned by Juice layer, not Persistence) |
|--------|-----------------------------------------------------------|
| `save_failed(slice, reason)` | Subtle bottom-of-screen toast: "Couldn't save just now. Try again in a moment." Optional haptic warning. **Never block input.** |
| `save_succeeded(slice)` | Silent — saves are expected to succeed; making the success audible would be noisy. |

Implementation of these subscriptions belongs in the Juice Cookbook or whichever Presentation system owns toast/notification rendering — not in Persistence itself.

## UI Requirements

Persistence has no UI of its own. Player-visible state lives in Shelf, Onboarding, and Text Input UIs — each of those GDDs owns its display.

## Cross-References

| This Document References | Target | Specific Element | Nature |
|--------------------------|--------|------------------|--------|
| Pillar alignment (Player Fantasy) | `design/gdd/game-concept.md` | Pillars 3, 5, and Anti-Pillars | Rule dependency |
| Layer + priority assignment | `design/gdd/systems-index.md` | Persistence row in Systems Enumeration | Index reference |
| Provisional contract for `worry_history` slice | *(future)* `design/gdd/text-input.md` | `worry_history` slice ownership | Data dependency |
| Provisional contract for `collection` slice | *(future)* `design/gdd/product-system.md` | `collection` slice ownership | Data dependency |
| Provisional contract for `collection` slice (read-only) | *(future)* `design/gdd/shelf-collection.md` | `collection` slice consumption | Data dependency |
| Provisional contract for `flags.first_run_complete` | *(future)* `design/gdd/onboarding.md` | `flags.first_run_complete` key | Data dependency |
| Provisional contract for `flags.last_scene` | *(future)* `design/gdd/scene-composition.md` | `flags.last_scene` key (optional) | Data dependency |
| Save signal subscription pattern | *(future)* `design/gdd/juice-cookbook.md` | `save_failed` → toast pattern | State trigger |

> *(future)* entries are placeholders for unwritten downstream GDDs. `/review-all-gdds` will validate as each downstream GDD comes online.

## Acceptance Criteria

> Format: GIVEN-WHEN-THEN. Each criterion is independently verifiable by a QA
> tester without reading the rest of this GDD.
>
> **Lean mode**: `qa-lead` not spawned for this section. Rationale: solo project
> where the user reviews each section in-conversation; 17 criteria below cover
> every Core Rule, every Formula, and the most failure-prone Edge Cases.
> **Recommend `qa-lead` review via `/team-qa persistence-system` before MVP
> smoke-check gate** to add fuzz-test scenarios that may have been missed.

### Functional — Core Behavior

1. **GIVEN** a fresh install with no save file, **WHEN** Persistence's `_ready()` runs, **THEN** state is `READY_FRESH`, `has_existing_save() == false`, and no file is written to disk until first `save_now()`.
2. **GIVEN** a valid save file with `_version: 1` on disk, **WHEN** Persistence's `_ready()` runs, **THEN** state is `READY_LOADED`, `has_existing_save() == true`, all slices are readable via `get_slice()`.
3. **GIVEN** a fresh install, **WHEN** `set_slice("collection", [50 entries])` is called → `save_now()` → game restart, **THEN** `get_slice("collection", [])` returns the identical 50 entries (round-trip integrity).
4. **GIVEN** the in-memory `worry_history` slice contains 100 entries (50 older than `PRUNE_THRESHOLD_SECONDS`, 50 within), **WHEN** `save_now()` runs, **THEN** the persisted slice contains exactly 50 entries (Formula 2 enforced).

### Functional — Failure Handling

5. **GIVEN** a corrupted save file (malformed JSON), **WHEN** `_ready()` runs, **THEN** the file is renamed to `save.json.corrupted.<unix_ts>`, state is `READY_CORRUPTED`, `save_failed` emits once with reason `"json_parse_error"`, `get_slice()` returns defaults.
6. **GIVEN** the disk write fails (simulated via `FileAccess` error injection or quota limit), **WHEN** `save_now()` is called, **THEN** `save_failed(slice, reason)` emits, in-memory cache is unchanged, game does not crash, subsequent `save_now()` retries.
7. **GIVEN** a save file with `_version: 2` (newer than current known version 1), **WHEN** `_ready()` runs, **THEN** known slice keys are readable via `get_slice()`, unknown keys are logged but preserved in memory, the file is **NOT** overwritten with a v1 schema until `save_now()` is explicitly called.

### Functional — Lifecycle & Concurrency

8. **GIVEN** Persistence is `READY_LOADED` with non-trivial state in memory, **WHEN** the app receives `NOTIFICATION_APPLICATION_PAUSED`, **THEN** `save_now()` is invoked automatically before the OS suspends the process.
9. **GIVEN** `save_now()` is in progress (`SAVING` state), **WHEN** another `save_now()` is called, **THEN** the second call blocks until the first completes; N concurrent calls coalesce into at most 1 additional save with the latest cache state.
10. **GIVEN** the device clock moves backward 6 hours mid-session, **WHEN** the next `save_now()` runs, **THEN** all worry entries are preserved (Formula 2 is opportunistic, not strict; no false-positive prune).

### Architectural — Verified by Automation

11. **GIVEN** the Persistence source files, **WHEN** a CI test greps for forbidden business strings (`"products"`, `"worries"`, `"flags"`, `"collection"`, `"shelf"`, `"onboarding"`, `"scene"`), **THEN** zero matches in Persistence source (enforces Core Rule 9 domain-agnostic constraint).
12. **GIVEN** no Mobile App Lifecycle wrapper exists yet, **WHEN** Persistence's unit tests run, **THEN** all tests pass without importing or referencing any non-Foundation module (zero-upstream enforcement).

### Performance — iPhone SE (2nd gen) reference hardware

13. **Save latency** (Formula 3): GIVEN a 16 KB save file, WHEN `save_now()` runs, THEN wall-clock latency ≤ **60 ms**.
14. **Save latency scaled** (Formula 3): GIVEN a 100 KB save file, WHEN `save_now()` runs, THEN wall-clock latency ≤ **100 ms**.
15. **Load latency**: GIVEN a 50 KB save file, WHEN `_ready()` runs, THEN total time from Autoload spawn to `READY_LOADED` ≤ **200 ms**.
16. **Memory**: GIVEN typical user data (50 products + 200 worry hashes), WHEN Persistence is `READY_LOADED`, THEN in-memory cache footprint ≤ **1 MB**.
17. **No hardcoded values**: all values from Section G Tuning Knobs are loaded from a resource file (e.g. `res://config/persistence_config.tres`), **not** hardcoded in the source. Verified by code review.

## Open Questions

| Question | Owner | Deadline | Notes |
|----------|-------|----------|-------|
| **iCloud Backup exclusion?** Should `save.json` be excluded from iCloud Backup via `NSURLIsExcludedFromBackupKey`? Pillar 5 / Anti-Pillar say "never upload" but iCloud Backup is user-authorised OS-level backup, not Mochi initiating. Decision impacts whether we need an iOS GDExtension wrap. | User + future Privacy & Local Data Boundary GDD | Before App Store submission | If excluded: GDExtension wrap needed (no Godot 4.6 native API confirmed). If accepted: document the trade-off in Privacy GDD. |
| **Async / threaded save threshold?** Formula 3 says ≥ 200 KB triggers async consideration. What's the actual cutoff on real iPhone SE (2nd gen) hardware? | godot-specialist | Pre-MVP (real-device measurement) | Affects whether Persistence needs a `Thread`. Default assumption: sync is fine for MVP. |
| **Migration force-write policy?** When a v1→v2 migration succeeds, do we immediately write the migrated file to disk, or wait for the next event-triggered `save_now()`? | User | Before v1.0 migration is first needed | Force-write reduces risk window but adds an extra startup write. |
| **Corrupted-file user notification?** Should the game show ANY UI indicator when `READY_CORRUPTED` is entered, or silently treat as fresh install? | User + ux-designer | Before MVP gate | Silent is simpler; visible reassures the user that their data isn't lost (corrupted file is preserved on disk). |
| **Save version numbering convention?** Sequential int (`1, 2, 3`) or semver (`"1.0", "1.1", "2.0"`)? | User | Before v1.0 | Sequential is what's currently spec'd; semver gives room for non-breaking changes but adds complexity. |
