# Persistence System

> **Status**: Revised (pending re-review)
> **Author**: game-designer (main) + godot-gdscript-specialist (engine integration)
> **Last Updated**: 2026-05-21 (post `/design-review` revision — 6 blockers + 12 recommended addressed)
> **Last Verified**: 2026-05-21
> **Implements Pillar**: Pillar 3 (Collection Without Pressure) + Pillar 5 (Unlimited But Meaningful) + Anti-Pillar (no cloud sync, no upload — enforced by Core Rules 4 + 5)

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
     "_written_at_day": <unix_ts_rounded_to_day>,
     "collection":     { ... },
     "worry_history":  { ... },
     "flags":          { ... },
     "preferences":    {           // MVP: AudioSystem-owned volume preferences (ADR-0001 Decision 3)
      "sfx_volume": 1.0,          // float [0.0, 1.0], default 1.0 — owned by AudioSystem
      "music_volume": 1.0         // float [0.0, 1.0], default 1.0 — owned by AudioSystem
    },
    "settings":       {           // MVP: HapticService-owned user toggles (ADR-0001 Decision 5)
      "haptic_enabled": true      // bool, default true — owned by HapticService
    }
   }
   ```
   *Format rationale*: JSON chosen over `Resource`/`.tres` for inspectability (debug, post-mortem), cross-version safety (no GDScript-class binding in the file), and migration ergonomics (pure data transforms). `ConfigFile` rejected: poor fit for nested arrays. Switching format is an ADR-level decision, not a knob.
   *Privacy*: `_written_at` is rounded to the nearest day (`ts - (ts % 86400)`) to avoid building a precise emotional-activity log on disk. Second-precision is not required by any system and would leak more than necessary (see Privacy notes).
3. **Slice contract**: Persistence reads/writes only top-level slice keys. Each slice's internal shape is owned by the domain system that writes it — Persistence does not validate slice content.
4. **No plaintext worry content — ever** *(privacy hard rule)*: No slice may store raw worry text in any form. `worry_history` and any future slice that derives from player text MUST store a one-way hash plus timestamp only. Plaintext on disk is an architectural violation. Enforced by code review and by the grep-based test in Rule 12.
5. **iOS save file is excluded from iCloud Backup** *(privacy hard rule)*: `save.json` (and all backup variants `.corrupted.*`, `.pre_migration.*`, `.tmp`) MUST be marked with `NSURLIsExcludedFromBackupKey` on iOS. Godot 4.6 has no native API; this is implemented via a small GDExtension wrap (see `docs/architecture/` — future ADR). Default state honors the Anti-Pillar "隐私是默认设置" — privacy must not require the player to flip OS-level switches. *(Android backup policy deferred — see Open Questions.)*
6. **Atomic writes** — every save runs this exact sequence:
   1. `FileAccess.open("user://save.json.tmp", WRITE)` — check non-null.
   2. `store_string(json)` — **check bool return**; on `false`, emit `save_failed`, do not proceed.
   3. `flush()` — **check bool return**; on `false`, emit `save_failed`, do not proceed.
   4. `close()` (or let it go out of scope in 4.6 RAII semantics).
   5. `DirAccess.rename_absolute(ProjectSettings.globalize_path("user://save.json.tmp"), ProjectSettings.globalize_path("user://save.json"))` — **check bool return**. `rename_absolute` requires absolute filesystem paths, NOT `user://` URIs; `globalize_path()` is mandatory.

   On any step failure: emit `save_failed(slice_or_"all", reason)`, leave `save.json` untouched (atomic-rename guarantee), and do NOT continue to the next step. **Never silently swallow.** Godot 4.4+ changed `FileAccess.store_*` from `void` to `bool`; missed bool checks become silent data-loss bugs in production.
7. **Save timing — two distinct triggers, two distinct API methods**:
   - **`save_now()`** — synchronous, blocking, used **only** by Persistence's own lifecycle handlers (`NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_WM_GO_BACK_REQUEST`). Caller has at least 5 s of OS-granted background time; up to 150 ms latency is acceptable here. Domain systems MUST NOT call `save_now()` directly.
   - **`save_when_idle()`** — deferred via `call_deferred` to the next idle frame, used by **all domain-system event triggers** (product collected, worry recorded, onboarding completed). Coalesces multiple invocations within the same frame into a single write. Target: ≤ 16 ms wall-clock so the save lands in a single frame without dropping the in-progress animation (Reveal / Shred).
   - **No periodic save loop.** Mochi's write frequency is inherently low; periodic saves only add wear.
   - **Atomic-rename guarantee is the primary line of defense; lifecycle save is the secondary belt.** iOS may SIGKILL the app on memory pressure without firing `NOTIFICATION_APPLICATION_PAUSED`. The Core Rule 6 atomic write is what makes data-loss impossible in that scenario, not the lifecycle hook.
8. **Load policy** (on Autoload `_ready()`):
   - File missing → treat as fresh install; in-memory cache is `{}`; do not write to disk until first event-triggered save.
   - File present but `JSON.parse_string()` returns `null` → back up corrupted file to `user://save.json.corrupted.<unix_ts>`, set `flags._corrupted_pending_notice = true` on the in-memory cache (consumed once by Scene Composition on next launch — see UI Requirements), treat as fresh install. **Never automatically delete a corrupted file.**
   - Orphan `user://save.json.tmp` left from a killed mid-write → delete on `_ready()` before any other I/O.
   - `_version` missing → reject (defensive against legacy/foreign schema collision); treat as fresh install with corruption notice.
   - `_version` newer than current → log warning, best-effort read of known keys; preserve unknown keys verbatim in cache (round-tripped on next save); do not destroy data.
   - `_version` older → run migration chain (see Edge Cases). Per-step migration budget: 100 ms on reference device. If chain total exceeds 500 ms, log warning (visible on first launch only).
9. **API surface** — single Autoload singleton:
   ```gdscript
   class_name PersistenceService extends Node

   ## Emitted with reason classifier: "transient_io" (toast-worthy) or
   ## "data_loss" (bottom-sheet-worthy — file corrupt or migration failed).
   signal save_failed(slice_name: String, reason: String, severity: String)
   signal save_succeeded(slice_name: String)

   ## Read a slice. Returns DEEP COPY — callers on hot read paths (e.g.,
   ## Shelf scroll at 60 FPS) MUST cache the result; do not call per-frame.
   func get_slice(slice_name: String, default: Variant = {}) -> Variant

   ## Write a slice. Updates in-memory cache only — does NOT write to disk.
   func set_slice(slice_name: String, data: Variant) -> void

   ## Lifecycle-only flush. Synchronous; up to 150 ms tolerated. Domain
   ## systems must NOT call this directly — use save_when_idle() instead.
   func save_now() -> bool

   ## Domain-system save trigger. Schedules a flush on the next idle frame.
   ## Multiple calls within the same frame coalesce into one write.
   func save_when_idle() -> void

   ## Was there a save file on disk before this session started?
   func has_existing_save() -> bool

   ## True if the previous launch hit READY_CORRUPTED and the next session
   ## has not yet shown the one-time corruption notice. Consumed by Scene
   ## Composition on first launch after corruption; cleared on consume.
   func consume_corruption_notice() -> bool

   ## Foundation Autoload contract (ADR-0001 Decision 1).
   ## Returns true when _ready() is complete and state is any READY_*.
   ## Returns false only during UNINITIALIZED (before _ready() finishes).
   ## Called once by LifecycleService during App Ready check — do not poll per-frame.
   func is_ready() -> bool:
       return _state in [State.READY_FRESH, State.READY_LOADED, State.READY_CORRUPTED]
   ```
10. **Autoload registration order** *(silent-data-loss safeguard)*: `PersistenceService` MUST be the FIRST entry in `[autoload]` in `project.godot`. Downstream Autoloads MUST NOT call `Persistence.get_slice()` or `set_slice()` synchronously inside their own `_ready()` — defer to the next idle frame via `call_deferred` or connect to `tree_entered` signals. *Rationale*: Godot 4.6 runs Autoload `_ready()` in declaration order. If a downstream Autoload calls `get_slice()` while Persistence is still `UNINITIALIZED`, it receives the empty default and may subsequently overwrite real saved data with empty data. This is unrecoverable silent corruption.
11. **Domain-agnostic**: Persistence source code MUST NOT contain business strings like `"products"`, `"worries"`, `"flags"`, `"collection"`. Slice names are passed in by callers. Enforced by a grep-based test (AC 11).
12. **Plaintext-text guard test** *(complements Rule 4)*: a CI test scans `user://save.json` produced by an end-to-end playtest for the literal worry strings used during the test. Zero matches required. This is the architectural enforcement of the no-plaintext-worries rule.
13. **Thin wrapper convention**: every domain system (e.g., `WorryHistory`, `ProductInventory`, `FirstRunFlag`) owns its own thin wrapper that calls `Persistence.get_slice(...)` / `set_slice(...)` / `save_when_idle()`. Wrappers live in the domain system's directory, NOT in Persistence's. Persistence does not import them.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|----------------|----------|
| `UNINITIALIZED` | Autoload constructed, `_ready()` not yet run | `_ready()` completes | API calls return defaults; `save_now()`/`save_when_idle()` are no-ops + warning log. Downstream Autoloads MUST NOT call Persistence in this state (Core Rule 10). |
| `READY_FRESH` | `_ready()` ran, no save file found | First `save_when_idle()` flush | In-memory cache is `{}`; `has_existing_save() = false` |
| `READY_LOADED` | `_ready()` ran, save file parsed OK | App quit | In-memory cache mirrors disk; `has_existing_save() = true` |
| `READY_CORRUPTED` | `_ready()` ran, file present but unparseable OR missing `_version` | First `save_when_idle()` flush | Corrupted file renamed to `save.json.corrupted.<unix_ts>`; cache is `{}`; `flags._corrupted_pending_notice = true` set on in-memory cache; `save_failed("load", "json_parse_error", "data_loss")` emitted via `call_deferred` so subscribers connecting later in the same frame still receive it. |
| `SAVING` | `save_now()` OR `save_when_idle()` flush in flight | Disk write completes (success or failure) | Reentrant calls coalesce into ≤ 1 follow-up save with the latest cache (queue depth 1). |

**Transitions**: `UNINITIALIZED` → one of `READY_FRESH | READY_LOADED | READY_CORRUPTED`. Any `READY_*` → `SAVING` via `save_now()` or `save_when_idle()`. `SAVING` → previous `READY_*` state on both success and failure (cache stays valid in memory even if disk write failed; `save_failed` emitted on failure with severity `transient_io`).

**Signal severity classifier** (Core Rule 9 contract):
- `severity = "transient_io"` — disk full, IO error, write returned false. In-memory state is intact; next save will retry. UX response: subtle toast.
- `severity = "data_loss"` — file corrupted, migration failed, `_version` missing. Player's previous save is unreadable; backup preserved on disk. UX response: one-time bottom-sheet on next session (see UI Requirements). This is the only failure mode that justifies interrupting the cozy experience.

### Interactions with Other Systems

Persistence is the **sole owner** of `user://save.json`. Every other system interacts through the typed slice contract, never via direct file access.

| System | Interaction | Slice Name |
|--------|-------------|------------|
| **Text Input** | `get_slice("worry_history", [])` for dedup check; `set_slice("worry_history", updated)` + `save_when_idle()` after recording. Stores `{hash, timestamp_unix}` ONLY — never plaintext (Core Rule 4). | `worry_history` (owns) |
| **Product System** | `get_slice("collection", [])`; `set_slice("collection", updated)` + `save_when_idle()` after roll | `collection` (owns) |
| **Shelf Collection** | Reads `get_slice("collection", [])` once on scene enter and **caches the result locally** — must not call per-frame (Core Rule 9 deep-copy semantics). | `collection` (reads) |
| **Onboarding** | `get_slice("flags", {}).get("first_run_complete", false)` gate; `set_slice("flags", {...})` + `save_when_idle()` on completion | `flags` (owns `first_run_complete`) |
| **Scene Composition** | OPTIONAL: `get_slice("flags", {}).get("last_scene", "main")`; `set_slice` + `save_when_idle()` on scene transition. **Also**: calls `Persistence.consume_corruption_notice()` on first launch; if `true`, renders the one-time corruption bottom-sheet (see UI Requirements). | `flags` (owns `last_scene`, consumer of `_corrupted_pending_notice`) |
| **Haptic System** | `get_slice("settings", {}).get("haptic_enabled", true)` synchronously in `_ready()` (Persistence is Autoload #1, settled by the time Haptic #4 runs); on user toggle: `set_slice("settings", {...})` + `save_when_idle()`. Per ADR-0001 Decision 5. Keys are `String` constants, not `StringName`. | `settings` (owns `haptic_enabled`) |
| **Mobile App Lifecycle** | Persistence internally subscribes to `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_GO_BACK_REQUEST` directly and calls `save_now()` (sync, lifecycle-only). | (Persistence is the consumer) |

> ⚠️ **Provisional Contract**: the 5 downstream GDDs (Text Input, Product, Shelf, Onboarding, Scene Composition) are not yet written. When designed, they MUST conform to the slice names and contract shapes above. Any deviation requires updating this GDD via `/consistency-check`.

## Formulas

> Persistence's "formulas" are engineering budgets and projections, not gameplay
> math. Reviewed adversarially by `systems-designer` and `performance-analyst`
> on 2026-05-21 — boundary-value findings folded into the formulas below.
> **`godot-specialist` sign-off still required pre-implementation** for
> `base_overhead` measurement and Formula 3 Path B latency on iPhone SE
> (2nd gen) reference hardware.

### Formula 1 — Save File Size Projection

```
estimated_bytes = base_overhead
                + (avg_product_bytes  × collection_count)
                + (avg_worry_entry_bytes × worry_history_count)
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_overhead` | b₀ | int | 80-150 | JSON schema overhead: top-level keys, `_version`, `_written_at_day`, brackets |
| `avg_product_bytes` | b_p | int | 80-200 | Serialized bytes per product entry (id, time, rarity, colour) |
| `collection_count` | n_c | int | 0-2000 | Entries in `collection` slice. Soft warn at 1,000; hard re-design at threshold below. |
| `avg_worry_entry_bytes` | b_w | int | 60-100 | Bytes per `{hash, timestamp_unix}` worry-history entry |
| `worry_history_count` | n_w | int | 0-200 | Active worry hashes (bounded above by `MAX_WORRY_HISTORY_ENTRIES` — Formula 2 pruning + hard cap) |

**Output Range** (typical path, lower-bound widths):
- Fresh install: ~150 B
- Typical week-1 user: 1-3 KB
- Typical month-1 user: 5-10 KB
- Typical heavy use 1 year: ~30-50 KB
- **Re-design threshold: 500 KB** — triggers migration to multi-slice files (this GDD must be revised).

**Worst-case worked example** (upper-bound widths — important for threshold planning):
- 1,000 products × 200 B = 200,000 B
- 200 worries × 100 B = 20,000 B
- Overhead 150 B
- Total: **~220 KB** — well under 500 KB threshold
- At 2,000 products × 200 B = 400 KB + worry = **~420 KB**, approaching threshold

**Typical worked example**: 50 products (80 B each) + 200 worry hashes (60 B each) + 100 B overhead = **16,100 B ≈ 16 KB** ✓ well under threshold.

**Key insight**: The 500 KB threshold is genuinely reachable for a long-term user with high-byte-width products. Re-design path (multi-slice files) must be designed before it's needed, not after.

### Formula 2 — Worry History Pruning Predicate

```
should_keep(entry, now) = (now - entry.timestamp_unix) ≤ PRUNE_THRESHOLD_SECONDS
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `entry.timestamp_unix` | int | Unix epoch | When worry was recorded |
| `now` | int | Unix epoch | Current Unix time |
| `PRUNE_THRESHOLD_SECONDS` | int | constant **90,000** | 25 hours = 24h dedup requirement + 1h safety buffer |

**Output**: boolean. Pruning runs on every flush (either via `save_now()` or `save_when_idle()`); cost is negligible since `worry_history_count ≤ 200`. If `MAX_WORRY_HISTORY_ENTRIES` is ever raised above 1,000, re-profile prune cost on iPhone SE before shipping.

**Edge Cases**:
- **Clock moves backward (DST, manual change)**: `(now - timestamp)` becomes negative. The predicate `(negative) ≤ 90000` is `true` → all affected entries are kept indefinitely until the clock catches up. **Acceptable.** Strict dedup is enforced in real time by Text Input using the in-session set, not by Persistence's stored history.
- **Clock moves forward by more than 25 h** (e.g., user travels across time zones; manual clock fix after long offline period): in a single flush, the predicate evaluates `true` for every existing entry → **the entire `worry_history` is pruned at once**. This is a complete loss of the dedup window. It is acceptable for this game because (a) dedup serves Pillar 5 "meaningful use" — not security; (b) Text Input enforces dedup within the current session via an in-memory set that survives the flush. But the GDD acknowledges that *after the next app launch*, recently-recorded worries become repeatable. This is a known limitation, not a bug.

**Example**: entry at `1717000000`, now = `1717090000` → diff = 90,000 ≤ 90,000 → keep. One second later → prune.

### Formula 3 — Save Latency Budgets (two call paths)

The two save trigger methods have different budgets because they serve different contexts. **Latency, not file size, is the primary trigger for async/threaded escalation** — file size is at best a coarse proxy.

#### Path A — `save_now()` (lifecycle-only)

Invoked from `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_GO_BACK_REQUEST`. iOS grants ~5 s of background time. No animation is running.

| Save File Size | Target Latency | Action if Exceeded |
|----------------|----------------|--------------------|
| < 50 KB | < 60 ms | Normal sync save |
| 50-200 KB | < 100 ms | Normal sync save |
| 200-500 KB | < 150 ms | Acceptable; investigate if consistently exceeded |
| > 500 KB | — | **Re-design** — Formula 1 threshold reached |

#### Path B — `save_when_idle()` (event-triggered, the hot path)

Invoked from domain systems after product collection / worry recording. **Runs on the main thread, deferred to the next idle frame.** A blocked frame here causes a visible hitch in the Reveal / Shred animation — destroying Pillar 1 and Pillar 2.

| Measured Latency | Action |
|------------------|--------|
| < 16 ms | ✅ OK — fits in one frame |
| 16-33 ms | 🟡 1 dropped frame — acceptable transient; monitor frequency |
| 33-66 ms | ⚠️ 2-4 dropped frames during Reveal — **escalate to threaded save** |
| > 66 ms | 🛑 Move to worker thread immediately |

**Variables**:
- `save_file_bytes`: bytes written to disk in current `save.json` (estimated from Formula 1)
- `measured_latency_ms`: actual `save_when_idle()` flush wall-clock time on reference device

**Migration latency** (when `_version_on_disk < current_version`):
- Per-step migration budget: 100 ms on reference device
- Total migration chain budget: 500 ms (logged warning if exceeded; not a hard cap because legitimate v1→vN chains for long-installed users may run longer)
- Migration runs once during `_ready()`; AC 15 load budget (200 ms) does NOT include migration. A separate AC covers migration latency.

**Cold-start FileAccess warmup**: `WARMUP_ENABLED` is **off by default** (changed from earlier proposal). Enable only if real-device measurement on iPhone SE shows the first save of the session consistently exceeds Path B's 33 ms threshold. Default off prevents unmeasured magic from inflating cold-start cost.

**Example (Path B)**: 16 KB save file → expected 5-15 ms ✓ fits in frame. If measured 25 ms, investigate but accept; if > 33 ms, escalate.

### Formula 4 — Backup Disk Footprint Cap

```
total_backup_bytes = Σ (corrupted_backups[i].size) + Σ (pre_migration_backups[i].size)
                   ≤ MAX_BACKUP_RETENTION_BYTES
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `MAX_BACKUP_RETENTION_BYTES` | int | constant **5,242,880** (5 MB) | Hard cap on `.corrupted.*` + `.pre_migration.*` files combined |
| `CORRUPTED_BACKUP_RETENTION_DAYS` | int | knob, default **90** | Age-based eviction window |

**Cleanup policy** (runs once per `_ready()` after orphan `.tmp` cleanup):
1. Delete backup files older than `CORRUPTED_BACKUP_RETENTION_DAYS`.
2. If total backup bytes still exceeds `MAX_BACKUP_RETENTION_BYTES`, delete oldest backups until under cap. Log each eviction.

**Rationale**: indefinite retention (the old default) is a privacy footgun — `.corrupted.*` files contain hash-and-timestamp records of past emotional activity. 90 days gives meaningful self-recovery time without unbounded growth.

## Edge Cases

Grouped by risk class. Format: `If [condition]: [outcome]. [rationale]`.

### A. Write / Load Failures

- **If app is killed mid-write** (any step inside Core Rule 6): the partial `save.json.tmp` may remain on disk but `save.json` is unchanged (atomic-rename guarantee — this is the **primary** data-loss defense). On next launch, `_ready()` cleans up orphan `.tmp` files before loading. **No data loss.**
- **If `flush()` returns `false` mid-write**: do NOT continue to rename — emit `save_failed(slice, "flush_failed", "transient_io")` and exit the save sequence. Renaming a flushed-incomplete `.tmp` over `save.json` would propagate corruption. Cache stays valid; next `save_when_idle()` retries.
- **If `JSON.parse_string()` returns `null` on load**: rename corrupted file to `user://save.json.corrupted.<unix_ts>`, log error with `JSON.get_error_message()` and `get_error_line()` for debugging, enter `READY_CORRUPTED`, set `flags._corrupted_pending_notice = true`, emit `save_failed("load", "json_parse_error", "data_loss")` via `call_deferred`. Game proceeds as fresh install but **never automatically deletes** the corrupted file (preserved for user-side recovery and the Formula 4 retention sweep).
- **If disk is full** (`store_string` / `flush` / `rename_absolute` returns `false`): emit `save_failed(slice, "disk_full_or_io_error", "transient_io")`. In-memory cache stays valid; next `save_when_idle()` will retry. Game does not crash. Scene Composition / UX layer subscribes to `transient_io` failures and renders a non-blocking toast.

### B. Version Mismatches

- **If `_version` is newer than current Persistence's known version** (e.g., user installed v1.5 then downgraded to v1.0): do **not** destroy data. Log warning, attempt best-effort read of known slice keys, preserve unknown keys verbatim in the cache (round-tripped on next save). *Rationale*: forward-compat protects the shelf from being wiped on rollback.
- **If `_version` is older**: run migration chain. Migrations are pure functions registered in order (`migrate_v1_to_v2(data)`, `migrate_v2_to_v3(data)`, …). Each step's output is the next step's input. **Before** running any migration, copy the original file to `user://save.json.pre_migration.<unix_ts>`. If any migration step throws or returns an error, abort the chain (leave on-disk file unchanged from pre-migration copy), enter `READY_CORRUPTED` with `save_failed("migration", step_name, "data_loss")`, and treat as fresh install with the corruption notice. **Never destroy data silently.**
- **Migration force-write policy**: after a successful migration chain, write the migrated state to `save.json` immediately within the same `_ready()` (instead of waiting for the next event-triggered flush). This narrows the risk window where a crash leaves the pre-migration file as the active save. The pre-migration backup file is retained per Formula 4.

### C. State / Concurrency

- **If two callers `set_slice("flags", ...)` in the same frame** with different values: last call wins for the in-memory cache. Persistence does **not** merge slice contents — merge responsibility belongs to the domain wrapper, which must read-modify-write atomically within itself. Document this in domain wrapper guidelines.
- **If `save_when_idle()` is called multiple times in one frame**: all calls coalesce into a single flush at the next idle frame. Cache state at flush time is what's written.
- **If `save_now()` is called during `SAVING` state**: the new call blocks until the current write completes. Queue depth is 1 — multiple invocations during a save coalesce into one follow-up save with the latest in-memory state.
- **If a `save_failed` handler calls `save_when_idle()` reentrantly**: the new call is queued normally — it does not loop. Persistence guarantees at most one in-flight + one queued; further calls within the same frame coalesce.
- **If `get_slice` is called during `SAVING`**: returns current in-memory cache (which IS the data being written). MVP runs all I/O on the main thread, so no locking is needed.
- **If save is escalated to a worker thread** (Formula 3 Path B exceeded): the cache becomes shared state. The simple "no locks needed" assumption breaks; the threaded implementation must add a `Mutex` for the cache and convert `SAVING`'s "block" semantics to a `Semaphore`-based queue. The Open Questions section tracks this decision.

### D. Platform / Clock

- **If device clock moves backward** (DST, manual change): Formula 2 pruning keeps affected entries indefinitely until the clock catches up. **Acceptable** — Text Input enforces strict in-session dedup.
- **If device clock moves forward beyond 25 h** (long offline period, time-zone travel, manual fix): a single flush prunes the **entire** `worry_history`, completely erasing the dedup window. Acknowledged limitation — see Formula 2 Edge Cases. Game does not crash or warn the player; dedup just resets.
- **If Android predictive back gesture (Android 13+)** fires `NOTIFICATION_WM_CLOSE_REQUEST` instead of `NOTIFICATION_WM_GO_BACK_REQUEST`: lifecycle save would miss the trigger. Persistence subscribes to BOTH notifications as a defensive measure (Core Rule 7). Confirm correct behavior on real Android 13+ device — tracked in Open Questions.
- **If iOS user offloads the app and re-downloads**: `NSDocumentDirectory` is preserved per Apple's docs. `user://save.json` survives. No special handling.
- **If user deletes the app and reinstalls**: `user://` is wiped per iOS sandbox rules. Treat as fresh install. iCloud Backup is excluded by Core Rule 5, so the save will NOT auto-restore — this is intentional and aligned with the Anti-Pillar.

### E. API Misuse

- **If a slice name is empty or contains characters outside `[a-z_][a-z0-9_]*`**: `set_slice` returns early + logs error. Enforced via `assert()` in dev builds; silent log + no-op in release builds.

## Dependencies

### Upstream — This system depends on

**NONE.** Persistence is Foundation-layer. It consumes only Godot's raw OS notifications (`NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_WM_GO_BACK_REQUEST`) directly, **not** through the Mobile App Lifecycle wrapper. This keeps Persistence zero-upstream — designable, implementable, and testable in isolation before any other system exists.

### Downstream — Depended on by

| System | Direction | Nature | Hard / Soft | Interface |
|--------|-----------|--------|-------------|-----------|
| **Text Input** | Text Input → Persistence | Data (read+write) | **Hard** — 24h dedup state must survive sessions | `get_slice("worry_history", [])` / `set_slice("worry_history", updated)` + `save_when_idle()` |
| **Product System** | Product → Persistence | Data (read+write) | **Hard** — collection IS persistent state | `get_slice("collection", [])` / `set_slice("collection", updated)` + `save_when_idle()` |
| **Shelf Collection** | Shelf → Persistence | Data (read-only) | **Hard** — Shelf has no other source of collection data | `get_slice("collection", [])` |
| **Onboarding** | Onboarding → Persistence | Data (read+write) | **Hard** — first-run gating relies on persistent flag | `get_slice("flags", {}).get("first_run_complete", false)` / `set_slice("flags", {...})` + `save_when_idle()` |
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
| `MAX_WORRY_HISTORY_ENTRIES` *(hard cap, defensive)* | **200** | 100 — 500 | Larger save file; if raised above 1,000, re-profile Formula 2 prune cost | Aggressive cap; may evict still-relevant hashes for extreme writers |
| `WARMUP_ENABLED` *(Formula 3 Path B mitigation)* | **false** | true / false | `_ready()` writes throwaway `.warmup` file; first save meets Path B 33 ms threshold | First save may exceed Path B budget on cold device; cleaner `_ready()` log. **Default off — enable only after real-device measurement.** |
| `CORRUPTED_BACKUP_RETENTION_DAYS` | **90** | 7 — 365 | Longer recovery window; more disk used for backups | Faster cleanup; risk losing recoverable data |
| `MAX_BACKUP_RETENTION_BYTES` *(Formula 4 hard cap)* | **5,242,880** (5 MB) | 1 MB — 50 MB | More room for backups; less aggressive eviction | Tighter sandbox footprint; older backups deleted sooner |
| `SAVE_FILE_SIZE_WARNING_KB` | **100** | 50 — 500 | Earlier log warning; more monitoring noise; preemptive of Formula 1 threshold | Later warning; less actionable signal |

### Cross-references

- `PRUNE_THRESHOLD_SECONDS` is the source of truth for Formula 2's constant of the same name. Formula 2 references this knob, not the literal value.
- `MAX_WORRY_HISTORY_ENTRIES` corresponds to the upper bound of Formula 1's `worry_history_count`. At default 200: heaviest realistic user (50 worries/day × 25 h prune window) hits steady state ~53 entries, leaving 4× safety margin.
- `MAX_BACKUP_RETENTION_BYTES` and `CORRUPTED_BACKUP_RETENTION_DAYS` together bound the Formula 4 cleanup policy.
- Formula 1's 500 KB re-design threshold is **not** listed as a knob — it is an architecture-decision trigger, not a daily tunable.

### Explicitly NOT knobs

- `SAVE_PATH = "user://save.json"` — iOS sandbox path is a hard constraint, not designer-tunable.
- `SAVE_FORMAT = "json"` — switching the on-disk format is an ADR-level decision, not a tuning operation. Rationale recorded in Core Rule 2.
- `ICLOUD_BACKUP_EXCLUDED = true (iOS)` — privacy hard rule, fixed by Core Rule 5. Not designer-tunable; changing it requires an ADR overriding the Anti-Pillar (which would itself be a vision-level change, not a configuration change).
- `STORES_PLAINTEXT_WORRIES = false` — privacy hard rule, fixed by Core Rule 4. Not designer-tunable.
- Save-rate throttle — queue depth 1 already coalesces; no need for an explicit rate cap.
- Encryption toggle — MVP does not encrypt local saves. Decision is deliberate: the iOS sandbox + iCloud-Backup-excluded combination already protects the file at rest; encryption would add complexity without proportional defense for a single-player cozy game. Tamper resistance is explicitly out of scope (see UI Requirements / security stance).
- Anti-tamper checksums — out of scope by design. Players who edit their own save file harm only themselves; this is acceptable for a cozy single-player game with no economy, no PvP, and no shareable state.

## Visual/Audio Requirements

Persistence is invisible infrastructure with no direct visual or audio output of its own. It emits signals that two presentation systems subscribe to — the response is severity-classified to match the emotional weight of the failure.

| Signal | Severity | Owned by | Player-facing response |
|--------|----------|----------|------------------------|
| `save_failed(slice, reason, "transient_io")` | Recoverable | Juice Cookbook / Scene Composition | Subtle bottom-of-screen toast (~2 s, non-blocking): "Couldn't save just now — we'll try again." No haptic. Never blocks input. |
| `save_failed(slice, reason, "data_loss")` | Catastrophic | **Scene Composition** (mandatory, NOT optional) | One-time bottom-sheet on next launch — see UI Requirements below. **This is the only persistence failure that justifies interrupting the cozy experience.** |
| `save_succeeded(slice)` | — | (no subscribers) | Silent — saves are expected to succeed; making the success audible would be noisy. |

## UI Requirements

Persistence has no UI of its own. **Two exceptions** carry mandatory contracts that downstream systems MUST implement:

### Required — Corruption Notice Bottom-Sheet

When `Persistence.consume_corruption_notice()` returns `true` on launch, Scene Composition MUST render a one-time bottom-sheet before the player reaches the main scene. Contract:

- **Trigger**: first frame where Scene Composition is interactive, immediately after Persistence reaches `READY_FRESH` (entered from `READY_CORRUPTED` after backup rename).
- **Tone**: cozy, honest, non-alarming. The shelf disappearing without explanation is a Pillar 3 catastrophe — this sheet is the minimum acceptable acknowledgement that the player's history existed and is being respected.
- **Suggested copy** (writer + ux-designer to finalize):
  > "上次的存档我读不出来了。
  > 不用担心 —— 文件还在你的设备上，被我小心收好了。
  > 我们从今天重新开始吧。"
- **CTA**: single dismiss button ("好的"). No retry, no recovery options in MVP.
- **No-repeat invariant**: `consume_corruption_notice()` is consume-on-read; after dismiss, the notice never appears again, regardless of how many times the player relaunches.
- **Visual register**: same as Onboarding bottom-sheets (consistency); no shake, no flash, no warning iconography. Mochi character does NOT make a sad face — the "克制工匠" stance (Pillar 4) applies.

### Required — Transient-IO Toast

When `save_failed` fires with severity `transient_io`, Juice Cookbook renders a brief non-blocking toast. Contract:

- Duration ~2 s, bottom-of-screen, dismissable by tap.
- Copy: "存档稍后再试" (or equivalent).
- No haptic. No interruption to current animation.

Player-visible state for collection, worries, and onboarding lives in their respective GDDs — Shelf, Text Input, Onboarding each own their displays.

## Cross-References

| This Document References | Target | Specific Element | Nature |
|--------------------------|--------|------------------|--------|
| Pillar alignment (Player Fantasy) | `design/gdd/game-concept.md` | Pillars 3, 5, and Anti-Pillars | Rule dependency |
| Layer + priority assignment | `design/gdd/systems-index.md` | Persistence row in Systems Enumeration | Index reference |
| Privacy audit obligation | *(future)* `design/gdd/privacy-boundary.md` | Audits Persistence's Core Rules 4 + 5 + Formula 4 | Architectural audit |
| Future ADR for iCloud Backup exclusion implementation | *(future)* `docs/architecture/adr-XXXX-icloud-backup-exclusion.md` | GDExtension wrap for `NSURLIsExcludedFromBackupKey` | Implementation reference |
| Provisional contract for `worry_history` slice (hash+timestamp ONLY — Core Rule 4) | *(future)* `design/gdd/text-input.md` | `worry_history` slice ownership | Data dependency |
| Provisional contract for `collection` slice | *(future)* `design/gdd/product-system.md` | `collection` slice ownership | Data dependency |
| Provisional contract for `collection` slice (read-only, cache locally — Core Rule 9) | *(future)* `design/gdd/shelf-collection.md` | `collection` slice consumption | Data dependency |
| Provisional contract for `flags.first_run_complete` | *(future)* `design/gdd/onboarding.md` | `flags.first_run_complete` key | Data dependency |
| Provisional contract for `flags.last_scene` + **mandatory corruption-notice bottom-sheet rendering** | *(future)* `design/gdd/scene-composition.md` | `flags.last_scene` + `consume_corruption_notice()` consumer | Data + UI contract |
| Save signal subscription pattern (transient_io toast) | *(future)* `design/gdd/juice-cookbook.md` | `save_failed("...", "transient_io")` → toast pattern | State trigger |

> *(future)* entries are placeholders for unwritten downstream GDDs. `/review-all-gdds` will validate as each downstream GDD comes online.

> **Downstream privacy gate**: every downstream GDD that owns or consumes a slice MUST be reviewed against Core Rule 4 (no plaintext worries) before its implementation begins. The future Privacy & Local Data Boundary GDD is the formal audit point, but per-GDD review by `security-engineer` is the actual gate.

## Acceptance Criteria

> Format: GIVEN-WHEN-THEN. Each criterion is independently verifiable by a QA
> tester without reading the rest of this GDD. Reviewed and rewritten by
> `qa-lead` on 2026-05-21: 8 fuzzy ACs hardened, 5 new ACs added (atomic-write
> recovery, migration chain, slice isolation, iOS backup-exclusion attribute,
> corruption-notice consume-once), 3 ACs marked `[BLOCKED-HARDWARE]`.
>
> **Fixture registry**: all test fixtures referenced below are defined in
> `tests/fixtures/persistence_fixtures.gd`. A test cannot run without that file.
>
> **Hardware-gated ACs** are marked `[BLOCKED-HARDWARE]`. They require a physical
> iPhone SE 2nd gen device; the simulator does not reflect NAND write latency.
> Story sign-off can proceed without them, but they must run before MVP gate.

### Functional — Core Behavior

1. **GIVEN** a fresh install with no save file, **WHEN** Persistence's `_ready()` runs, **THEN** state is `READY_FRESH`, `has_existing_save() == false`, and no file is written to disk until the first `save_when_idle()` flush completes.

2. **GIVEN** a valid save file with `_version: 1` on disk, **WHEN** Persistence's `_ready()` runs, **THEN** state is `READY_LOADED`, `has_existing_save() == true`, all slices are readable via `get_slice()`.

3. **GIVEN** a fresh install, **WHEN** `set_slice("collection", FIXTURE_50_PRODUCTS)` is called (where `FIXTURE_50_PRODUCTS` is an Array of 50 Dicts each with `{id: String, timestamp_unix: int, rarity: String, colour: String}` defined in `persistence_fixtures.gd`) then `save_when_idle()` is invoked and the process restarts, **THEN** `get_slice("collection", [])` returns an Array deep-equal to `FIXTURE_50_PRODUCTS` with no key loss and no value mutation.

4. **GIVEN** `set_slice("worry_history", PRUNE_FIXTURE)` is called where `PRUNE_FIXTURE` is 100 `{hash: String, timestamp_unix: int}` entries — 50 at `Time.get_unix_time_from_system() - 90001` and 50 at `Time.get_unix_time_from_system() - 1` — **WHEN** a flush runs, **THEN** the persisted `worry_history` Array has exactly 50 entries and contains only entries satisfying `(now - timestamp_unix) ≤ 90000`.

### Functional — Failure Handling

5. **GIVEN** a corrupted save file (malformed JSON), **WHEN** `_ready()` runs, **THEN** (a) file is renamed to `save.json.corrupted.<unix_ts>`; (b) state is `READY_CORRUPTED`; (c) `flags._corrupted_pending_notice == true` in cache; (d) `save_failed("load", "json_parse_error", "data_loss")` emits via `call_deferred` (subscribers connecting later in the same frame still receive it); (e) `get_slice()` returns defaults.

6. **GIVEN** disk write fails (`store_string` returns `false`, simulated via `FileAccess` error injection), **WHEN** `save_when_idle()` flush runs, **THEN** `save_failed(slice, reason, "transient_io")` emits, in-memory cache is unchanged, no partial file exists on disk, game does not crash, and the next `save_when_idle()` retries.

7. **GIVEN** a save file with `_version: 2` and unknown slice `"future_data": {"x": 1}` plus known slice `"collection"`, **WHEN** `_ready()` runs, **THEN** (a) `get_slice("collection", [])` returns the stored collection; (b) `FileAccess.get_md5("user://save.json")` matches the pre-load hash until a flush is triggered; (c) the next flush writes a file that still contains `"future_data"` verbatim. **BLOCKED-ON-DECISION until OQ-5 (version numbering convention) is resolved.**

### Functional — Lifecycle & Concurrency

8. **GIVEN** Persistence is `READY_LOADED` and `set_slice("flags", {"test_key": true})` has been called but no flush has occurred, **WHEN** `_notification(NOTIFICATION_APPLICATION_PAUSED)` is dispatched to the Persistence node (via GUT `notify_message()`), **THEN** `save_succeeded` emits once AND `FileAccess.file_exists("user://save.json")` is `true` AND the file content contains `"test_key": true`.

9. **GIVEN** Persistence is `READY_LOADED`, **WHEN** `save_when_idle()` is called 5 times within the same frame (no `await get_tree().process_frame` between calls), **THEN** at most 1 flush actually executes on the next idle frame, `save_succeeded` emits at most 1 time, and the final on-disk content reflects the last `set_slice()` call before the burst.

10. **GIVEN** Persistence uses an injectable `ClockProvider` (defaults to `Time.get_unix_time_from_system()`) and a test mock returns `T` then `T - 21600` (6 h backward), AND `worry_history` contains 10 entries recorded at time `T - 1`, **WHEN** a flush runs after rollback, **THEN** all 10 entries are preserved (predicate `(T-21600) - (T-1) < 0 ≤ 90000` is `true`, so all are kept).

### Architectural — Verified by Automation

11. **GIVEN** the Persistence source files, **WHEN** a CI test greps for forbidden business strings (`"products"`, `"worries"`, `"flags"`, `"collection"`, `"shelf"`, `"onboarding"`, `"scene"`), **THEN** zero matches in Persistence source (enforces Core Rule 11 domain-agnostic constraint).

12. **GIVEN** an end-to-end playtest using known worry strings (e.g., `"qa_test_worry_DO_NOT_LEAK_42"`), **WHEN** the playtest completes and `user://save.json` is dumped, **THEN** a CI grep finds zero matches of the literal worry strings in any file under `user://` — enforces Core Rule 4 / 12 (plaintext-text guard).

13. **GIVEN** the Persistence source files, **WHEN** unit tests run, **THEN** they pass without importing or referencing any non-Foundation module (zero-upstream enforcement; Core Rule 10).

14. **GIVEN** the Tuning Knobs default values, **WHEN** a CI test scans `persistence_service.gd` for the bare literals (`90000`, `200`, `90`, `5242880`, `100`) outside string contexts, **THEN** zero matches — all knob values are read from `res://config/persistence_config.tres` (replaces former AC 17 "verified by code review" with an executable test).

### Performance — iPhone SE (2nd gen) reference hardware

15. `[BLOCKED-HARDWARE]` **Save latency (Path B — event-triggered)**: GIVEN a 16 KB save file, WHEN `save_when_idle()` flush runs, THEN wall-clock latency ≤ **16 ms** (single frame) on iPhone SE 2nd gen. Measured via `Time.get_ticks_msec()` delta in a test-instrumented build.

16. `[BLOCKED-HARDWARE]` **Save latency (Path A — lifecycle)**: GIVEN a 100 KB save file, WHEN `save_now()` runs from `NOTIFICATION_APPLICATION_PAUSED`, THEN wall-clock latency ≤ **100 ms** on iPhone SE 2nd gen.

17. `[BLOCKED-HARDWARE]` **Load latency**: GIVEN a 50 KB save file pre-written from `persistence_fixtures.gd::make_50kb_fixture()`, WHEN `_ready()` runs (start = first instruction in `_ready()`, end = state transitions to `READY_LOADED`), THEN elapsed wall-clock time on iPhone SE 2nd gen ≤ **200 ms** (excluding migration time; migration covered by AC 20).

18. **Memory (typical)**: GIVEN typical user data (50 products + 200 worry hashes), WHEN Persistence is `READY_LOADED`, THEN in-memory cache footprint ≤ **1 MB** (measured via `OS.get_static_memory_usage()` delta before/after load).

19. **Memory (max-tier)**: GIVEN upper-bound Formula 1 data (1,000 products at 200 B each + 200 worry hashes at 100 B), WHEN Persistence is `READY_LOADED`, THEN in-memory cache footprint ≤ **2 MB**.

### Functional — New ACs added in 2026-05-21 revision

20. **Atomic write recovery**: GIVEN `save_when_idle()` has opened `user://save.json.tmp` and written some bytes but not yet called `rename_absolute`, WHEN the process is killed (simulated via fault injection after the first `store_string`), THEN on next launch (a) `user://save.json` is byte-for-byte identical to its pre-write state; (b) `user://save.json.tmp` does not exist after `_ready()` completes.

21. **Migration chain v1→v2**: GIVEN a save file with `_version: 1` and a registered `migrate_v1_to_v2()` function that adds `flags.migrated = true`, WHEN `_ready()` runs, THEN (a) state is `READY_LOADED`; (b) `get_slice("flags", {}).get("migrated") == true`; (c) `user://save.json.pre_migration.<unix_ts>` exists as a backup of the original; (d) per Edge Case B, `save.json` is force-written with the migrated state before `_ready()` returns.

22. **Slice isolation**: GIVEN `set_slice("collection", [1, 2, 3])` and `set_slice("worry_history", [{"hash": "a", "timestamp_unix": 0}])`, WHEN a flush runs and the process restarts, THEN `get_slice("collection", [])` returns `[1, 2, 3]` AND `get_slice("worry_history", [])` returns `[{"hash": "a", "timestamp_unix": 0}]` — writes to one slice do not corrupt another.

23. **Privacy — iOS backup exclusion attribute set**: GIVEN the iOS build, WHEN `save.json` is written, THEN the GDExtension wrapping `NSURLIsExcludedFromBackupKey` has been invoked successfully and the file has the exclusion attribute (verified via test harness that reads the URL attribute). **Implementation pending ADR + GDExtension; AC ready for use as soon as the build is available.**

24. **Corruption notice consume-once**: GIVEN a save file is corrupted (AC 5 conditions), WHEN the app launches, Scene Composition calls `consume_corruption_notice()` (returns `true`), then the app is restarted twice more, THEN `consume_corruption_notice()` returns `false` on the second and third launches (no repeat shows).

## Open Questions

### Resolved during 2026-05-21 review

| Question | Resolution |
|----------|------------|
| ~~iCloud Backup exclusion?~~ | **RESOLVED → iOS default-exclude.** Anti-Pillar's "privacy is default" is load-bearing; user must not need to flip OS switches for privacy. Implementation requires a small GDExtension wrap for `NSURLIsExcludedFromBackupKey` (Godot 4.6 has no native API). Encoded in Core Rule 5. Future ADR will document the GDExtension implementation. |
| ~~Async/threaded save threshold?~~ | **RESOLVED → latency-driven, not size-driven.** Formula 3 Path B now defines escalation by measured wall-clock latency on reference hardware: > 33 ms (2 frames) triggers threaded save investigation; > 66 ms is a hard escalation. File size is at best a coarse proxy. |
| ~~Migration force-write policy?~~ | **RESOLVED → force-write immediately after successful migration**, within the same `_ready()`. Pre-migration backup file is retained per Formula 4. Edge Case B documents this. |
| ~~Corrupted-file user notification?~~ | **RESOLVED → mandatory one-time bottom-sheet on next session.** Encoded in UI Requirements as a required contract for Scene Composition. Silent failure was rejected because shelf-disappears-without-explanation violates Pillar 3. |

### Still open

| Question | Owner | Deadline | Notes |
|----------|-------|----------|-------|
| **Save version numbering convention?** Sequential int (`1, 2, 3`) or semver (`"1.0", "1.1", "2.0"`)? | User | Before first migration is written (post-MVP) | Sequential is currently spec'd. Recommend keeping int unless a concrete need for semver appears. Blocks AC 7. |
| **Android backup policy?** iOS is decided (exclude). Android `allowBackup="false"` is the parallel decision but Android is post-MVP. | User | Before Android port begins | Recommend follow iOS posture (exclude) for consistency with Anti-Pillar. Tracked in Edge Case D. |
| **Android predictive back gesture (Android 13+)** routing — does it fire `NOTIFICATION_WM_GO_BACK_REQUEST` or `NOTIFICATION_WM_CLOSE_REQUEST` in Godot 4.6? | godot-specialist | First Android device build | Persistence subscribes to BOTH as a defensive measure (Core Rule 7). Real-device test will confirm whether one is unused. |
| **Threaded save mutex contract** — if Path B escalation triggers worker-thread save, the cache-locking and `SAVING` "block" semantics must be redesigned (Edge Case C). | technical-director + godot-specialist | If/when latency measurement triggers escalation | Cache becomes shared state across threads. Mutex + Semaphore likely required. Out of MVP scope unless triggered. |
