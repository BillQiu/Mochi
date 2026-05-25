---
name: mochi-design
description: Use this skill to generate well-branded interfaces and assets for Mochi, the cozy iOS mood-toy game where users feed worries to a cartoon shredder character and collect small painted treasures. Use for production code, throwaway prototypes, mocks, screenshots, slides, or any other artifact that needs to look and feel like Mochi. Contains the full visual system, content voice, and iconography.
user-invocable: true
---

# Mochi Design Skill

Read `README.md` first — it contains the canonical brand context, content voice, visual foundations, and iconography rules. Then explore:

- `colors_and_type.css` — drop-in design tokens (colors, type, spacing, radii, shadows, motion, layout). Import this and you have the whole foundation.
- `assets/` — bespoke painted icons (shelf), Lucide SVGs (settings, close, chevrons), wordmark.

> Note: this skill was originally exported with `preview/` (specimen cards) and `ui_kits/mochi-ios/` (a five-screen React UI kit). They have been removed from the Mochi project at the owner's request. The README still describes the visual system in enough detail to ship UI without them.

## How to use this skill

If creating visual artifacts (slides, mocks, throwaway prototypes), copy needed assets out of `assets/` and write static HTML files for the user to view. Import `colors_and_type.css` at the top so tokens apply.

If working on production code (e.g. SwiftUI, Godot, React Native), translate the tokens in `colors_and_type.css` to your target's theme system. For Mochi specifically the Godot translation is already done — see `../USAGE_IN_GODOT.md` and `godot/scripts/autoload/design_tokens.gd`.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask 4–8 focused questions (audience, screen, vibe, motion, mockup vs. interactive, with-or-without Mochi character), and then act as an expert designer who outputs HTML artifacts or production code.

## Critical product rules — never violate

- **All UI copy is Simplified Chinese.** Voice = calm slightly-off-beat shopkeeper. Use `你` (never `您`). No exclamation marks outside the reveal celebration. No emoji in UI chrome. Lowercase wordmark `mochi`. Half-width Arabic numerals + half-width punctuation in English/numbers contexts.
- **Light mode only** for MVP. Do not generate dark-mode variations unless asked.
- **iPhone 390×844 portrait only.** Do not design tablet or landscape.
- **No anti-features.** No social, no sharing, no streaks, no badges, no notifications, no IAP, no ads, no accounts, no cloud sync, no daily tasks, no progress bars to "complete the collection".
- **The Mochi machine character is a placeholder.** In any mock, render Mochi as a labeled placeholder rectangle (~35% screen height, centered, slightly above vertical center). The painted asset comes from **nano-banana / gpt-image-2** separately (multi-image reference input). Same rule for the two companion cats (see `design/notes/cats_spec.md`).
- **The lever (joystick) and shelf icon are the only always-visible interactive elements besides Mochi.** Treat them with disproportionate visual care.
- **Two-layer shadows always.** Tight contact + diffuse ambient, tinted with the ink hue. Never flat black, never neutral gray.
- **Motion**: `easeOutQuart` for everyday transitions, `easeOutBack`/`easeOutElastic` for celebration moments (reveal, lever snap-back, treasure landing). Spring-y but not bouncy-bouncy.
- **No emoji** in UI chrome. Allowed inside user-typed worry text (private content).

## When something is missing

If asked for an icon that isn't in `assets/icons/`, substitute the closest Lucide match (round stroke, 1.75px on a 24×24 grid) and flag the substitution in your output. If asked for the Mochi character art, use the placeholder treatment and flag the substitution — never draw your own SVG version of Mochi.
