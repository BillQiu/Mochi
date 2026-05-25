# CODING AGENTS: READ THIS FIRST

This is a **handoff bundle** from Claude Design (claude.ai/design).

A user mocked up designs in HTML/CSS/JS using an AI design tool, then exported this bundle so a coding agent can implement the designs for real.

## What you should do — IMPORTANT

**Read `project/README.md` top to bottom first.** It is the canonical design-system doc (visual foundations, content voice, iconography rules, microcopy library). Then read `project/colors_and_type.css` — the single source of truth for all design tokens.

**If anything is ambiguous, ask the user to confirm before you start implementing.** It's much cheaper to clarify scope up front than to build the wrong thing.

## About the design files

The design medium is **HTML/CSS/JS** — these are prototypes, not production code. Your job is to **recreate them pixel-perfectly** in whatever technology makes sense for the target codebase (React, Vue, native, whatever fits). Match the visual output; don't copy the prototype's internal structure unless it happens to fit.

**Don't render these files in a browser or take screenshots unless the user asks you to.** Everything you need — dimensions, colors, layout rules — is spelled out in the source. Read the HTML and CSS directly; a screenshot won't tell you anything they don't.

## Bundle contents (as kept in this repo)

- `README.md` — this file
- `USAGE_IN_GODOT.md` — bridge doc: how the Godot side consumes this design system
- `project/README.md` — **canonical design system doc** (visual foundations, content voice, iconography, microcopy library)
- `project/SKILL.md` — Agent Skill manifest (portable design skill)
- `project/colors_and_type.css` — **single source of truth** for all design tokens
- `project/assets/` — SVG icons + wordmark

The original Claude Design export also included `project/preview/` (HTML specimen cards), `project/ui_kits/mochi-ios/` (a five-screen React UI kit) and `project/scratch/` (PNG mockups). They were intentionally removed — Mochi keeps only the design-system foundations, not page-level UI artifacts. Re-run Claude Design if you need them back.
