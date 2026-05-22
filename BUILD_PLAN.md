# Mochi BUILD_PLAN

> 单一信源。替代 17 GDD + systems-index + ADR 全套。
> Last updated: 2026-05-22

---

## What I'm Building

22-30s 核心循环：**打字 → 拉摇杆 → Mochi 粉碎 → 剪影揭晓 → 货架收藏**。
Mobile 2D, iOS first → Android follow-up. 4 周到 TestFlight。

## Screens (2)

- **Main**: Mochi 居中 + 摇杆 + 上方输入区 + 货架入口图标
- **Shelf**: 时间倒序网格 + 单项详情面板

## Data Model (single JSON in `user://`)

```
{
  "shelf": [
    {"product_id": "P01", "obtained_at": <unix>, "source_worry_hash": "<sha>"}
  ],
  "text_history_hashes": ["<sha>", ...],   // last 24h, dedup only
  "first_run_done": true,
  "prefs": {"sfx_vol": 1.0, "music_vol": 1.0, "haptic_on": true}
}
```

## Products (MVP: 8, 80/20 rarity)

待 `design/notes/products.md` 填入名称 + 类别 + sprite spec（W2 开始前）。

## Weekly Goals

| Week | Goal | Done = |
|---|---|---|
| **W1** | Crush Loop 端到端代码，ugly assets, real-device playable | 真机能完成 1 次完整 22 秒循环 |
| **W2** | Mochi 角色 + 8 产物 + 货架接通 | 货架能保存并展示历史产物 |
| **W3** | Juice pass — haptic / audio / squash / shake | 每个 beat 上手感能让自己想再拉一次 |
| **W4** | Real-device playtest + bug fix + TestFlight | 朋友拿到 build 能玩 5 分钟不崩 |

## Hard Problems (need attention early)

1. **iOS Haptic in Godot 4.6** — 无 built-in。W1 Day 2 spike：测 `kyoz/godot-haptics` plugin，若不稳就 GDExtension wrap CoreHaptics。
2. **摇杆爽感** — drag 物理 + 释放时机 + haptic 同步。**只能真机迭代，文档解决不了**。
3. **粉碎仪式时间锚** — 摇杆释放 → SFX 起音 → 视觉抖动 起点对齐。±25ms 是经验合理目标。

## Out of MVP

- ✗ 颜色变体 / 5% 稀有层 → v1.0
- ✗ 设置页 / 偏好 UI → v1.0
- ✗ 云同步 / 账户 / 社交 → 永不
- ✗ 付费 / 广告 → 永不

## Anti-goals (process discipline)

学自前一次的失败：

- ✗ 不写"如何避免 race condition 的状态机"
- ✗ 不写"幂等性保证"等防御性条款
- ✗ 不写 "per ADR-XXX Decision Y" 引用
- ✗ 不在 spec 里规定别的 spec 的行为
- ✗ 不在 consumer 不存在时设计 producer 接口
- ✗ 不为系统建 `Visual/Audio Requirements` 空章节
- ✗ 不让 review 反馈持续累加规则（**Fix / Delete / Park 三选一，禁 Add**）

## Reference

- `design/concept.md` — 产品定义（值得保留）
- `../Mochi-backup` — 前一次 heavy-process 尝试，需要查参考时 `git show main:<path>` 即可
