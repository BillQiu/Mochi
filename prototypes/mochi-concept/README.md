# Mochi — Concept Prototype

> **PROTOTYPE - NOT FOR PRODUCTION**
> Throwaway code testing one question. Do not import any of this into the production tree.
> *Mochi is the project name, the upcoming game's title, and the name of the machine character (a fluffy mechanical worry-eater).*

**Created:** 2026-05-20
**Engine:** Godot 4.6 (desktop run; iOS Haptic validation is a separate future prototype)
**Concept doc:** `design/gdd/game-concept.md`
**Session state:** `production/session-state/active.md`

---

## The Question (Falsifiable Hypothesis)

> **If** the player completes one full micro-loop — pull lever → crush → silhouette → tap reveal (≈ 30 seconds), **they will feel a small-theatre satisfaction.**
> **Confirmed if:** 3+ first-time testers spontaneously pull the lever again within **10 seconds** of the first reveal, with no prompting.

The riskiest assumption: the lever-pull → shake → reveal micro-theatre must feel intrinsically satisfying with **placeholder visuals + synthesized SFX alone**. If it does not, no amount of iOS Haptic tuning later will save the concept.

---

## How to Run

### Option A — Godot Editor

1. Open Godot 4.6
2. **Project → Import...** → select `prototypes/mochi-concept/project.godot`
3. Click **Import & Edit**
4. Press **F5** (or click the play button)
5. Window opens at 540×960 (mobile portrait simulated). Drag the orange handle on the right downward.

### Option B — Command Line

```bash
cd /Users/billqiu/workspace/my-game
godot --path prototypes/mochi-concept/
```

(Adjust `godot` to your install path — e.g. `/Applications/Godot.app/Contents/MacOS/Godot` on macOS.)

---

## How to Play

1. **IDLE** state — drag the **orange handle** (right side) downward
2. Pull at least 80% of the way down to **trigger crush**; release short and it springs back (test the resistance feel)
3. **CRUSHING** — machine shakes 1.4 s, debris tumbles, inner flashes, low rumble + thunk SFX
4. **REVEALING** — black silhouette pops out of the bottom tray with a "ding"
5. **Tap the silhouette** — bounces and fills with random color
6. After ~1.4 s, returns to IDLE. Pull again.

**The status label shows the current state and the cumulative pull count.**
**Console prints `[METRIC] seconds_to_next_pull=X.X`** every time you pull again after a reveal — this is the hypothesis signal.

---

## What This Prototype Validates

✓ Lever-pull physics feel (mouse drag + spring-back)
✓ Crush animation rhythm (shake amplitude, duration, debris)
✓ Silhouette → tap → fill reveal micro-theatre
✓ Audio support (synthesized click / thunk / rumble / ding — no real SFX assets needed)
✓ "Do I want to pull again?" — the core retention signal

## What This Prototype Does NOT Validate

✗ iOS Haptic feedback — desktop has no Taptic Engine. **Separate prototype 2** required.
✗ Text input UX — deferred (does not affect the theatre hypothesis)
✗ Shelf / collection — deferred (long-term retention, not micro-loop)
✗ Real art (debug rectangles only)
✗ Real audio (synthesized placeholder tones; final SFX needs professional design per game-concept.md)

---

## Tuning Knobs (try these if feel is off)

In `main.gd`:

| Constant | Default | Effect |
|---------|--------|--------|
| `LEVER_TRIGGER_Y` | 180.0 | How far the lever must be pulled to trigger crush. Lower = easier trigger (less commitment). |
| `LEVER_PULL_MAX` | 220.0 | Max pull distance. |
| `_shake_machine` `amp` | 8.0 | Shake amplitude (pixels). Higher = more violent. |
| `_shake_machine` `freq` | 28.0 | Shake frequency (per second). |
| `_shake_machine` `dur` | 1.2 | Shake duration (sec). |
| `_enter_crushing` timer | 1.4 | Total crush duration before reveal. |
| `_enter_complete` timer | 1.4 | How long the product stays before reset. |
| `_make_tone "thunk"` freq | 180.0 | Low-frequency impact when lever fully pulled. Try 120–240. |
| `PRODUCT_COLORS` / `PRODUCT_SHAPES` | — | Add or change variants. |

**Theatre rhythm check:** Total micro-loop time should be **22–30 s** per game-concept.md. Currently the *machine* portion is ~3.0 s (crush 1.4 + reveal pop 0.45 + your tap → 1.4 hold). Add ~5-15 s of human "writing the worry" in the real game.

---

## Playtest Protocol

Hand this prototype to someone (or yourself after a fresh break of 2+ days):

1. **Brief once:** "Drag the orange handle on the right downward." Nothing else.
2. **Step back. Do not narrate. Do not help.**
3. **Watch silently.** Note every hesitation, re-read, confused moment.
4. After they stop or hit the 5-pull mark, ask **one question only**:
   > "What was confusing or unsatisfying about it?"
5. Note whether they pulled the lever a second time **without prompting** — and how many seconds elapsed between first reveal and second pull.

> The hypothesis is confirmed only if **3+ first-time testers** spontaneously pull again within 10 s. Three is not many — find three people.

---

## When You Come Back

Run `/prototype` again to continue from Phase 6 (Playtest Debrief). Or directly tell the next session:

> "Continue the Mochi concept prototype from Phase 6 — playtest debrief."

The session state is in `production/session-state/active.md`.
