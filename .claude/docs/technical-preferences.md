# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward+ (default for Godot 4.6 desktop; may switch to Mobile renderer for iOS/Android — decide during prototype on real device)
- **Physics**: Godot Physics (2D) — Jolt is 3D-only; not relevant for this 2D project

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (iOS primary → Android follow-up)
- **Input Methods**: Touch (tap, drag, long-press) + on-screen text input (system IME)
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**:
  - iOS Haptic Engine (CoreHaptics / UIImpactFeedbackGenerator) is the primary tactile channel — quality of feel is a game pillar, not a polish item.
  - Android Vibrator API is a degraded fallback — accept lower fidelity, do not let it block iOS feel work.
  - All interactions must be reachable single-handed (thumb-zone aware UI).
  - No hover states; no right-click; no keyboard shortcuts beyond system IME.
  - System back gesture (iOS swipe / Android nav) must never destroy player input mid-text-entry without confirmation.

## Naming Conventions

GDScript conventions (per the Godot 4 official style guide):

- **Classes**: PascalCase (e.g., `PlayerController`, `WorryCrusher`)
- **Variables**: snake_case (e.g., `move_speed`, `current_health`)
- **Functions**: snake_case (e.g., `take_damage`, `pull_lever`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `worry_crushed`, `product_revealed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`, `worry_crusher.gd`)
- **Scenes**: PascalCase matching root node (e.g., `WorryCrusher.tscn`, `Shelf.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `MIN_WORRY_LENGTH`)
- **Enums**: PascalCase type, UPPER_SNAKE_CASE values (e.g., `enum Rarity { COMMON, UNCOMMON, RARE }`)
- **Node names in scenes**: PascalCase (e.g., `LeverArm`, `OutputTray`)

Always use static typing — `:` annotations on variables, return-type arrows on functions. The `godot-gdscript-specialist` enforces this in code review.

## Performance Budgets

Defaults for mobile 2D — safe targets for iOS mid-range hardware (iPhone XS / iPhone SE 2nd gen and newer). Validate on real device during prototype; adjust here when you have empirical numbers.

- **Target Framerate**: 60 FPS sustained
- **Frame Budget**: 16.6 ms / frame
- **Draw Calls**: < 100 / frame (2D mobile; Godot batches sprites automatically when materials match)
- **Memory Ceiling**: < 500 MB resident on iOS (App Store-friendly install size)
- **Cold Start**: < 3 s from launch to interactive home screen
- **Idle Battery Drain**: < 5% / 30 min session (no animations when app is backgrounded)

## Testing

- **Framework**: GUT (Godot Unit Testing) — community standard for Godot 4
- **Minimum Coverage**: Not enforced as a percentage; instead enforce by category — see Coding Standards `tests/` table
- **Required Tests**:
  - Rarity weight roll (`worry_crusher.gd::roll_product()`) — determinism + distribution
  - Worry input validation (min length, repeated symbols, 24-hour dedup) — boundary tests
  - Local save / load round-trip — no data loss across app kill
  - Touch input — gesture recognition does not misfire on text-entry mode
- **Visual / haptic tests**: Manual only — automated tests cannot validate feel.

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here. Do NOT pre-populate speculatively. -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (only if a native C++ plugin becomes necessary — e.g., bespoke iOS Haptic bridge)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved — likely candidate is iOS Haptic API wrapping if community plugins prove insufficient.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
