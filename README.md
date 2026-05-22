# Mochi

> Mobile 2D 解压玩具：打字 → 拉摇杆 → 粉碎烦恼 → 揭晓产物 → 收藏。
> 22-30 秒核心循环，单机离线，iOS 优先。4 周 MVP。

## Status

| 阶段 | 状态 |
|---|---|
| Concept | ✓ (`design/concept.md`) |
| Prototype validated | ✓ (前一次项目已 PROCEED) |
| Project init | ✓ 2026-05-22 |
| **Current** | **Week 1 — Crush Loop 真机 spike** |
| MVP ship | Week 4 目标 |

## Structure

```
godot/      — Godot 4.6 工程（cd 进来打开 project.godot）
design/     — concept + ad-hoc 设计笔记
playtests/  — 真机 playtest 报告（一等公民）
reference/  — 外部参考（空，按需放）
.claude/    — AI 工作流（轻量版）
BUILD_PLAN.md — 单一信源："我这 4 周要做什么"
```

## Previous Attempt

前一次走 heavy-process 路线的尝试保留在 `../Mochi-backup`（git history 完整）。
失败的关键学习：17 GDD × 8 章节模板的产出对 solo 4 周 MVP 是 30× 超载。
当前项目刻意走轻量路线，**不重复 GDD 内卷**。

## Quick Start

1. 打开 Godot 4.6 → Import → 选 `godot/project.godot`
2. 真机测试前确认 iOS export template 已配置
3. 任何"想加个东西"的冲动先回到 `BUILD_PLAN.md` 对照范围
