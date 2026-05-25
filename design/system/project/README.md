# Mochi Design System

> **Mochi (摸吃 / もち)** — a cozy iOS mood-toy game. You write down a worry, feed it to a cute cartoon shredder machine named Mochi, pull a lever, and watch it transform into a small collectible treasure to be displayed on a shelf.

This is the visual + interaction system for the Mochi MVP. Solo-indie, 4-week build, iOS-first portrait-only, light-mode-only, Chinese (Simplified) UI copy.

---

## Sources

Everything in this design system was derived from the brief in the user's local `design/` mount:

- `design/concept.md` — full Game Concept doc (elevator pitch, MDA framework, core loop, pillars, MVP scope). The product philosophy and anti-pillars below come from this file.
- `design/notes/visual_direction.md` — `Visual Direction — Mochi` (palette v0, Donut County reference, character spec for image-gen handoff).
- `design/notes/cats_spec.md` — visual spec for the two companion cats (Lucky 美短 + 蓝胖 英短). Same painted plush language as Mochi.

> The reader is not assumed to have access to those files. Everything material has been lifted into this README, the `colors_and_type.css` token file, the UI kit, and the preview cards.

No Figma file, no slide template, no codebase to mirror — Mochi is pre-production, and this design system **is** the visual bible the rest of the project will build against.

---

## At a glance

| | |
|---|---|
| **Genre** | Casual / 解压工具 / 收集型 mood toy |
| **Platform** | iOS 390×844 portrait only (MVP) |
| **Theme mode** | Light only (dark is v1.1+) |
| **UI language** | 简体中文 (Simplified Chinese), system font |
| **Session length** | 1–3 min / opening |
| **Core loop** | 22–30s · 打字 → 拉杆 → 粉碎 → 剪影 → 揭晓 → 收藏 |
| **Anti-features** | No social, no sharing, no streaks, no badges, no notifications, no IAP, no ads, no accounts, no cloud sync |
| **Visual anchor** | *Cozy Mechanical* — a Donut-County-warm, plush-tactile, slightly 3D-stylized 2D world |

---

## Visual anchor — one sentence

> **"一台会眨眼的工业级粉碎机，立在一片乳白色的留白里。"**
> *A blinking, industrial-grade shredder standing in a wide cream-coloured stillness.*

The machine (Mochi the character) is **heavy, plush, tactile, magnetic**. The environment around it is **empty, cream, weightless**. The shelf, lever, input field, and shelf cells all defer to Mochi in visual weight — they are interactive *furniture* arranged on a stage.

Donut County is the reference. **Not** flat vector, **not** isometric, **not** cyberpunk, **not** dark, **not** material design. The system feels like felt, clay, painted wood, soft plastic.

---

## CONTENT FUNDAMENTALS

All UI copy is Simplified Chinese. The voice is **a calm, slightly off-beat shopkeeper** — Mochi is an earnest small craftsman and the UI inherits that tone. Never bubbly, never corporate, never therapy-app-warm-and-fuzzy.

### Voice rules

- **Second person, but soft.** "你" is fine; never "您" (too formal). Imperatives are gentle: "把今天的烦恼写下来…", not "请输入烦恼".
- **No exclamation marks** outside the celebration moment. Even there, prefer "✨" over "！". The product is bedtime energy.
- **No streak / progress / badge language.** Never "继续加油"、"已连续 N 天"、"再来一次解锁". The product philosophy is *intentional minimalism* and that has to show in copy.
- **Lowercase, half-width punctuation for English/wordmark.** "mochi", not "Mochi" or "MOCHI", when used as the brand mark in-app. The character is always referred to in body copy as "Mochi" (proper noun).
- **Ellipsis as breathing room.** Placeholder microcopy ends in "…" to suggest invitation, not instruction: "把今天的烦恼写下来…"
- **Numbers and dates use half-width Arabic.** "5 月 24 日", not "五月二十四日"; "12:34", not "十二点三十四".
- **Emoji are reserved**. The system uses **zero emoji in UI chrome**. Acceptable only inside user-typed worry text (private content). Brand iconography fills the role emoji would.
- **Silhouette / reveal copy is event-driven, not gamified.** "叮——" or "出来了" feels right; "恭喜获得！" does not.

### Tone in the trickiest moment

When a user types something heavy ("我妈妈病重", "我想离婚"), Mochi does **not** jump to a cute reaction face, and does **not** put on a sympathetic mask. It behaves like a careful craftsman who has read the slip and is now doing the work properly. UI copy in this moment stays exactly the same — *the consistency itself is the respect*.

### Sample copy library

| Slot | Copy |
|---|---|
| First-run greeting | `你好，我是 Mochi。` |
| First-run subtitle | `把烦恼交给我，我会替你处理好。` |
| Privacy callout | `你写的字只留在这台手机里，不上传，不联网。` |
| Input placeholder | `把今天的烦恼写下来…` |
| Input min-length hint | `再多写一点点（至少 5 个字）` |
| Lever idle tooltip | `往下拉一拉` |
| Shred process line | `咔嚓、咔嚓…` |
| Reveal moment | `叮——` |
| Reveal CTA | `轻轻一点，揭开它` |
| Shelf empty state | `这里还空着，没关系。` |
| Shelf detail — when | `2026 年 5 月 24 日 · 晚上` |
| Shelf detail — original | `当时你写的：` *(toggleable, default hidden)* |
| Settings header | `小设置` |
| Settings — privacy | `本地保存，永远不上传` |
| About | `Mochi 是一台很小的机器，做一件很小的事。` |

---

## VISUAL FOUNDATIONS

### Colors

Five-color palette, locked. Everything else (50/700 tints, surfaces, scrims) is derived. See `colors_and_type.css` for the full set.

| Role | Hex | Where |
|---|---|---|
| Cream `#F5E6D3` | background — `--bg-app` | the stage, the negative space, the "weightless environment" |
| Peach `#E8A598` | primary — `--c-peach` | Mochi body hint, key chips, soft tags |
| Caramel `#D17A52` | accent — `--c-caramel` | CTAs, the lever ball, joystick grip, the one orange thing |
| Ink `#2D3B4F` | text + outlines — `--c-ink` | all primary text, hard shadows, character outlines |
| Mint `#9DCDB5` | pop — `--c-mint` | reveal moment, mint pop chips, rare highlights |
| Gold `#E8B86E` | rare-reveal only — `--c-gold` | reserved for the 5% rare drop (v1.0+) |

**Never** pure black, **never** pure white, **never** cool gray. Anything that wants to be gray is tinted with `--c-ink` at low opacity instead.

### Typography

- **Body / UI**: iOS system stack (`-apple-system, "PingFang SC", "Hiragino Sans GB", "Noto Sans SC"…`). Per the brief, no custom Chinese font.
- **Display (English accents only)**: **Fredoka** — rounded, plush, friendly. Used for the `mochi` wordmark, large numbers (shelf count), and the first-run hero. Loaded via Google Fonts CDN. ⚠️ **Substitution flag**: we'd usually ship a self-hosted woff2; please confirm we may use Fredoka and we'll bundle the font file.
- **Numbers** are tabular (`font-variant-numeric: tabular-nums`) so the shelf count doesn't jitter.

Type scale lives in tokens (`--fs-body` 16px through `--fs-display-xl` 44px). All copy on a 390pt canvas reads at body=16, callouts=15, footnotes=13, captions=11. Display scales (24/32/44) are reserved for onboarding and the wordmark — sparing.

### Spacing

4pt rhythm. `--s-1` 4, `--s-2` 8, `--s-3` 12, `--s-4` 16, `--s-5` 20, `--s-6` 24, `--s-7` 32, `--s-8` 40, `--s-9` 48, `--s-10` 64. Horizontal gutter is `--s-5` (20px). Stack rhythm is mostly `--s-4` between rows, `--s-6` between groups.

### Backgrounds

The system has **one** background — cream. No hero gradients, no patterns, no textures, no full-bleed photography. The stage stays empty so Mochi has gravity. Surfaces on top of the stage are *barely* lifted: `--bg-surface` (`#FBF4E8`) is +3 LRV from the cream, just enough to read as a card. The shelf board uses a warmer wood tone (`--bg-shelf` `#ECD6B7`).

Gradients are **never** used as a hero treatment. The only gradient in the system is the gold/mint reveal glow — a soft radial behind the silhouette during the celebration moment.

### Borders, dividers, outlines

- Hairlines are `rgba(45,59,79,0.08)` — `--stroke-soft`. They live in dividers between settings rows and the rim of the input field.
- Component edges generally do **not** use a stroke. Plush surfaces lift via shadow only — a stroke would flatten them.
- Mochi the character and the lever ball both get a 1.5–2pt **ink outline** in their asset. UI surfaces (cards, sheets) do not.

### Shadows — the plush stack

Every interactive surface uses a **two-layer** shadow: a tight contact shadow + a diffuse ambient blur. Colors are tinted with the ink hue, never flat black, never pure gray.

```css
--shadow-2:
  0 2px 0 rgba(45,59,79,0.06),       /* contact */
  0 6px 14px -4px rgba(45,59,79,0.14); /* ambient */
```

Four steps: `--shadow-1` (chip), `--shadow-2` (default card), `--shadow-3` (lifted, e.g. lever knob, modal), `--shadow-4` (sheet over scrim). Inputs get a soft *inner* shadow — they're pockets, not lifted cards. The reveal moment adds a **glow** (`--glow-mint` or `--glow-gold`) and *that's the only time the system emits light*.

### Corner radii

Clay/plush — never sharp. `--r-sm` 10 (small button), `--r-md` 14 (input), `--r-lg` 20 (card), `--r-xl` 28 (sheet), `--r-2xl` 36 (full-bleed onboarding). Pills `--r-pill` for tags and the lever-pull affordance handle.

### Transparency, blur

- Modal scrim: `rgba(45,59,79,0.32)` — `--bg-overlay`. No backdrop-blur (cheap effect; doesn't fit the painted vibe).
- Sheets are **opaque** cream-50, not translucent.
- Mochi character itself is rendered on opaque cream; no transparency in the bitmap.

### Motion

Spring-y but **not** bouncy-bouncy. Two curves and one duration ladder.

| When | Curve | Token |
|---|---|---|
| Everyday transitions (sheets opening, tab swaps, input focus) | `easeOutQuart` | `--ease-out-quart` |
| Celebration moments (silhouette reveal, treasure landing on shelf, lever release snap-back) | `easeOutBack` / `easeOutElastic` | `--ease-out-back`, `--ease-out-elastic` |

Durations: `--dur-fast` 140ms (press), `--dur-base` 240ms (default), `--dur-slow` 480ms (sheets), `--dur-celebrate` 780ms (reveal fill + bounce).

### States

- **Press**: shrink to ~98%, sink shadow to `--shadow-pressed`, no color change. The squish *is* the feedback.
- **Hover**: not a thing on iOS — but for previews, raise shadow one step.
- **Disabled**: 40% opacity on fill, no shadow.
- **Focus** (input): inner stroke `--stroke-strong`, no outer ring. The cream surrounds it.

### Layout rules

- One fixed iPhone viewport: 390×844, safe-top 47, safe-bottom 34.
- Default horizontal gutter is `--s-5` (20px).
- The home/main screen has three persistent zones: **input strip** at top, **Mochi stage** in the upper-middle (35% of canvas height, centered), **lever + shelf icon** at the bottom. The lever and shelf icon are the only **always-visible interactive elements besides Mochi**, and they get disproportionate visual care.
- No tab bar. No nav rail. Returning home is always a single down-swipe or close-X on a sheet.

---

## ICONOGRAPHY

The Mochi product has very few icons — by design. The shelf icon, the settings gear, the close-X on sheets, and the toggle/back affordances make up the entire MVP icon set. Anything richer (the lever, Mochi himself, the treasures) is **bespoke painted asset**, not an icon.

### System choice

- **Library**: [Lucide](https://lucide.dev) (round-stroke, friendly, 2px stroke at 24×24). ⚠️ **Flagged substitution** — there's no custom icon library in the project yet, and Lucide's round, clean stroke pairs well with the plush surfaces without competing with Mochi's painted character. Heroicons (outline) is the runner-up. Please confirm or specify and we'll swap.
- **Delivery**: in this design system, icons are pulled from the Lucide CDN (no copy-in needed). For ship code, copy the four to five SVGs you actually use into `assets/icons/` — there's no need to bundle the whole library.
- **Stroke**: 1.75px on a 24×24 grid. Strokes are `currentColor` so they take their hue from context (almost always `--fg`, occasionally `--c-caramel` for the focus item).
- **Custom painted glyphs**: the **shelf icon** in the bottom corner and the **lever knob** are NOT Lucide icons — they're bespoke painted assets in the Mochi style. Both are documented as Brand cards and live in `assets/`.
- **Emoji**: never in UI chrome. Allowed inside the user's typed worry text (private).
- **Unicode**: not used as glyphs. The system does use `…` (ellipsis) as a punctuation device; that's typography, not iconography.

### Mochi character art

The Mochi machine itself is the centerpiece and will be **generated via nano-banana / gpt-image-2** (multi-image reference input — Mochi reference image + style anchor) per the character spec in `design/notes/visual_direction.md`. In all mockups it appears as a **placeholder rectangle labeled "Mochi (AI image gen)"** at ~35% screen height, centered horizontally, slightly above vertical center. Treasures (the 8 collected items) and the two companion cats (`design/notes/cats_spec.md`) likewise get placeholder slots — all generated the same way for style consistency.

---

## Index

- `colors_and_type.css` — all design tokens (colors, type, radii, spacing, shadows, motion, layout). Drop-in for any UI built against Mochi.
- `README.md` — this file.
- `SKILL.md` — Agent Skill manifest. Lets Claude Code / agent runs use this system as a portable skill.
- `assets/` — bespoke shelf icon, Lucide-style utility icons (settings, close, chevrons), and the wordmark SVG.

> Note: the original Claude Design bundle also shipped `preview/` (HTML specimen cards) and `ui_kits/mochi-ios/` (a five-screen React UI kit). Those have been removed at the project owner's request — Mochi only retains the design-system foundations, not page-level UI artifacts. Re-run Claude Design if you ever need them back.

---

## Caveats

Read these before iterating with the system.

1. **Fredoka is a substitution flag.** Used via Google Fonts CDN. If you want a self-hosted font (recommended for ship), confirm the choice and we'll bundle the woff2 in `fonts/`.
2. **Lucide icons are a substitution flag.** No custom icon set existed, so we picked the closest match to the Donut-County warmth. Heroicons (outline) is the next-best fit.
3. **Mochi character + 8 treasures + 2 cats are placeholders.** Per the brief, **nano-banana / gpt-image-2** generates the actual painted assets — multi-image reference input is used to lock style consistency across all 11 figures (Mochi + 8 treasures + Lucky + 蓝胖). The UI kit uses labeled rectangles ("Mochi (AI image gen)") in the exact final size & position so the bitmap can be dropped in 1:1.
4. **Sounds & haptics are out of scope here.** The brief flags audio + iOS Taptic as core to "tactile first" — that work lives outside this design system.
5. **Light mode only.** No dark-mode tokens defined. Per brief.

---

