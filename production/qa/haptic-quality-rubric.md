# Haptic Quality Rubric

> 触觉品质主观评分量表。被 `design/gdd/haptic-system.md` AC-Q-1 ~ AC-Q-5 引用。
> Pillar 1 (Tactile First) 强制验证工具——自动化测试不能替代真机感受，但感受需要被结构化记录以便对比与归档。

## 使用说明

- **何时使用**：每次有触觉相关 commit 进入主干前，触觉变更对应的 AC-Q 必须用本量表评分。
- **谁评分**：开发者本人（必填）+ 至少 1 名外部测试者（AC-Q-1/2/3/5）/ ≥ 3 名外部测试者（AC-Q-4 闭眼识别）。
- **设备矩阵**：iPhone XS（A12，Taptic Engine 2，最低支持）+ iPhone 13/14/15 之一（最新代）；如有可能加 iPad Pro 11" 第三代。
- **评分尺度**：1（差）— 2（不及格）— 3（及格但不出彩）— 4（达标）— 5（出彩）。**单条 AC-Q 通过的最低门槛 = 平均分 ≥ 4.0**。
- **记录归档**：每次评分写入 `production/qa/evidence/haptic-quality-[YYYY-MM-DD]-[device-model].md`，commit 引用该 evidence 文件路径。

## 评分维度（每个事件键）

每个触觉事件按以下 5 个维度独立评分：

| 维度 | 1 分 | 3 分 | 5 分 |
|---|---|---|---|
| **物理真实感** | 软绵无力，"手机在抖"感 | 离散冲击但偏中性 | "金属/木头碰撞"明确，类比真实物件 |
| **节奏感** | 时机错位 / 抢拍 / 慢半拍 | 时机大致对，但有 50–100 ms 拖延感 | 完美卡点，与视觉/音频感知同时 |
| **强度恰当** | 过强（手抖痛感）/ 过弱（疑似无响应） | 强度可接受但与场景不完全匹配 | 强度完美匹配场景（按 Player Fantasy 表锚定） |
| **可分辨性** | 与其他事件触觉无法区分 | 仔细感受可区分 | 闭眼能立刻识别是哪个事件 |
| **疲劳度** | 30 秒后明显不适，想关 | 长时间游玩略疲劳 | 持续游玩仍舒适，不想关闭 |

## 事件锚定（5 维评分时的参考）

| 事件 | 物理类比（5 分锚） | Player Fantasy 期望 |
|---|---|---|
| `lever_pull_start` | 手指按下机械按钮的轻触 | 启动确认 |
| `lever_pull_progress` | 拨杆经过卡点 | 进度感知 |
| `lever_lock` | 金属杠杆触底卡死 | **Pillar 1 核心瞬间** |
| `shred_start` | 机器启动的手心一震 | 仪式感 |
| `shred_pulse` | 工业机械低频运转 | 持续工作 |
| `shred_end` | 机器停下的余震 | 完成确认 |
| `reveal_pop` | 礼物盒弹簧打开的清脆 | 揭晓惊喜 |
| `product_land` | 物件落到木桌 | 落地确认 |
| `shelf_add` | 物件被柔和放到架上 | 收纳确认 |
| `mochi_blink` | 眨眼的极轻提示 | 角色反应 |

## 反面参考（自动 = 1 分）

如果触觉感受符合以下任一描述，**自动判为 1 分**，不论其他维度：

- ❌ 廉价 Android 手机连续振动质感
- ❌ < 100 ms 内多次冲击致疲劳
- ❌ 持续震动（> 100 ms 不间断 + UIImpactFeedbackGenerator 哲学违反）
- ❌ 与音频明显不同步（先听后摸 > 50 ms，或反向 > 100 ms）
- ❌ 设备过热 / 电池快速消耗（参照 idle 基线 30 分钟测试）

## 评分记录模板

复制此模板到 `production/qa/evidence/haptic-quality-[date]-[device].md`：

```markdown
# Haptic Quality Evidence — [YYYY-MM-DD] — [Device Model]

- **Build**: [git short SHA]
- **Tester**: [name + role: developer / external]
- **Device**: [exact model + iOS version]
- **Conditions**: [headphones / silent switch / battery %]

| 事件键 | 物理真实感 | 节奏感 | 强度恰当 | 可分辨性 | 疲劳度 | 平均 | 备注 |
|---|---|---|---|---|---|---|---|
| lever_lock | 5 | 5 | 4 | 5 | 4 | 4.6 | "金属顶住"感强 |
| reveal_pop | ... | ... | ... | ... | ... | ... | ... |

## 闭眼识别测试（AC-Q-4 专用）

执行一次完整核心循环（30 秒），仅凭触觉识别下列节点：
- [ ] 摇杆到底（`lever_lock`）—— [识别成功 / 失败]
- [ ] 揭晓（`reveal_pop`）—— [识别成功 / 失败]
- [ ] 入货架（`shelf_add`）—— [识别成功 / 失败]

3/3 成功 = AC-Q-4 通过。
```

## Q-1 Prototype Gate 评分（AC-Q-6 专用）

Q-1（"摇杆 3 秒触感是否需要 CoreHaptics 自定义波形"）的盲测使用此扩展量表：

- 同一拉杆动作，两个 build：
  - Build A：5 预设方案（MVP 默认）
  - Build B：CoreHaptics 自定义波形草稿
- ≥ 3 名外部测试者盲测，强制偏好选择 + 自由评论
- 通过条件：Build A 在"物理真实感"维度 ≥ 3.5 平均分 → 维持 MVP 方案；否则启动 CoreHaptics 工作量

## 版本

- v1.0 — 2026-05-21 — 初版，配合 haptic-system.md 修订
