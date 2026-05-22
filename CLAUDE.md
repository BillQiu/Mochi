# Mochi

Solo indie mobile 2D toy. 4-week MVP. Godot 4.6 + GDScript.

## What this game is

22-30s 核心循环：打字烦恼 → 拉摇杆 → Mochi 粉碎 → 剪影揭晓 → 货架收藏。
Pillar 1 = 触感（Haptic + Audio 是核心，不是 polish）。
单机离线、无云、无社交、无内购。

## Tech

- Engine: Godot 4.6 (pinned)
- Language: GDScript with static typing (`: type` everywhere)
- Platform: iOS first, Android follow-up
- Storage: local JSON only, no cloud

## Coding conventions

- snake_case for vars / funcs / signals (past tense for signals: `worry_crushed`)
- PascalCase for classes / scenes
- Always static typing — `var x: int = 0`, `func foo() -> bool:`
- No singletons except Godot Autoload services
- Public APIs get doc comments; private logic doesn't

## How to help me

- I'm solo. **Don't simulate a studio team or spawn 49 agents.**
- When I ask for design help, **hard-cap output at 1 page**.
- For code: write minimal first, refactor when reused 3rd time.
- For features: "build it ugly first, then polish" — not "design perfectly upfront".
- **Reply in 中文**（全局约定，详见用户 global memory）。

## What NOT to do (learned the hard way)

- ❌ 不要套 `/design-system` `/design-review` `/architecture-decision` `/architecture-review` `/gate-check` `/review-all-gdds` 之类 heavy-process skill——它们对 solo 4 周项目是负 ROI
- ❌ 不要生成 8 章节 GDD 模板。设计需要时写 1 页 `design/notes/<topic>.md`
- ❌ 不要为没有视觉的系统建 `Visual/Audio Requirements` 章节
- ❌ 不要 backfill Open Questions（已决议的条目不留在那里当装饰）
- ❌ 不要在 spec A 里规定 spec B 的行为（跨边界规约污染）
- ❌ 不要在 consumer 不存在时为 producer 设计 interface（预约式契约）
- ❌ 不要把 idempotency / race-condition guard 写进 spec（那是测试用例，不是设计）

## Active workstream

见 `BUILD_PLAN.md`——当前 week 的焦点。

## Specialists I'll call manually when needed

- `godot-gdscript-specialist` — 写完 .gd 文件后做 code review
- `general-purpose` — 跨文件搜索 / 调研
- `qa-tester` — 写 GUT test 用例

不要预先 spawn 这些，等我具体说。
