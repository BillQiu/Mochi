# Juice Cookbook

> **Status**: Revised (2026-05-22 — 12 BLOCKING + R11 + R12 全部修订完成；pending 第二次 /design-review since-last-review)
> **Author**: user (Bill Qiu) + game-designer + art-director + audio-director + technical-artist (lean mode — only D/H specialists active) + creative-director (R11/R12 终审依据)
> **Last Updated**: 2026-05-22 (revision pass after MAJOR REVISION verdict)
> **Implements Pillar**: Pillar 1 (Tactile First) + Pillar 2 (Every Pull Is a Theatre); guards against "寡淡" (prototype carry-forward constraint)
> **Wave**: 2 (Juice Legislation) — gates Wave 3-6 Core gameplay GDDs
> **Type**: Full 8-section GDD (upgraded from "cookbook" per 2026-05-22 user decision; systems-index to be synced in Phase 5)
>
> **Revision changelog (2026-05-22)**:
> - B1 ✅ F-1 锚点 → `t_emit`；新增 `platform_audio_output_latency_ms` 表
> - B2 ✅ Impact = T1 压缩帧（非 overshoot）；overshoot 归 Follow-through 相位
> - B3 ✅ AC-01 拆分 AC-01a（speaker BLOCKING）+ AC-01b（BT ADVISORY）
> - B4 ✅ F-4 `overlap_factor = floor(lifetime/interval) + 1`
> - B5 ✅ JC-R4 改 CPUParticles2D 节点池 + restart()；删除 emit_one_shot 引用
> - B6 ✅ 粒子上限 SSOT 统一到 F-4 表
> - B7 ✅ F-4 表加 blend mode 约束（blend_add → 50% 上限）
> - B8 ✅ Mobile renderer Forbidden 条件式化（依赖 ADR-R）
> - B9 ✅ AC-13 升 BLOCKING + GUT injection test
> - B10 ✅ F-7 Output Range [0.5, 1.8]
> - B11 ✅ Core Rule 8: `Tween.set_parallel(true)` 强制
> - B12 ✅ OQ-1 spike 提前到 Wave 3 启动前 1-2 天
> - R11 ✅ Player Fantasy 加内在张力小节 + Section C 七配方 Required Minimum 对称清单 + AC-14
> - R12 ✅ Onboarding 前 3 次 shelf_add 走 JC-R7 enhanced 变体

## Overview

Juice Cookbook 是 Mochi 项目的 **game feel 参照集**：它给出一组带名字的"配方"
（squash & stretch、anticipation、follow-through、screen shake、time-scaling、
color flash、layered audio、particles），并把每个配方绑定到 7 个核心 hook
signal 之一——`lever_pull_start`、`lever_lock`、`shred_start`、`shred_pulse`、
`reveal_pop`、`product_land`、`shelf_add`。Wave 3-6 的每一份 GDD（Lever
Interaction、Shred Process、Silhouette Reveal、Shelf Collection、Mochi
Character、Onboarding、Accessibility）**必须**在 Tuning Knobs 里为它发出的每个
hook signal 引用一条 Cookbook 配方；此约束在 code review 阶段由
`godot-gdscript-specialist` agent 强制执行。

Cookbook 之所以存在，是因为 2026-05-21 的 concept prototype 验证了 22-30 秒核心
循环的逻辑成立，但暴露了一个结构性风险——用户对视觉/交互层的判定是 **"寡淡"**。
因此 Game Feel 从"收尾打磨"被提升为一级系统，作为 Wave 2 的准入门禁前置于所有
Wave 3-6 Core gameplay GDD 的撰写。在功能层面，Cookbook 是一份 **合同**：让
"摇杆有重量""揭晓像一场小剧场"这种话在所有下游 GDD 作者和 reviewer 心里指向
同一组具体效果。

对玩家而言，Cookbook 是 Pillar 1 **触感先行** 和 Pillar 2 **每一次都是一场
小剧场** 的执行机构：每条配方都要保证它的视觉峰值与音频起始、触觉打击在
`audio_haptic_sync_window_ms = 30 ms` 窗口内共振；并且第 100 次拉杆要和第 1 次
一样有承诺过的物理力度。Cookbook 不引入任何新机制，它只规定 **已有机制如何以
概念承诺过的强度把自己呈现出来**。

## Player Fantasy

> **Review mode 备注**：`lean` 模式下 Section B 不在 D/H 高风险闸门内，未 spawn
> `creative-director`。语气与措辞建议在 /vertical-slice 前再次校准。

Juice Cookbook 有 **两类读者和一位玩家**——而真正的 fantasy 活在他们之间的缝隙里。

**读者一：设计师、程序员、reviewer**。他们打开 Cookbook 的方式就像主厨翻开
菜谱本——不是寻找灵感，而是寻找 **统一词汇表**。当 reviewer 在 Lever
Interaction GDD 的 Tuning Knobs 里读到 "lever_lock 配方：anticipation 80 ms +
squash 0.92 → 1.05 → 1.0 + screen shake 4 px / 120 ms + sub-bass 1-frame
thump"，他必须立刻知道 Lever 给玩家承诺了什么样的反馈，不需要再二次确认。
在这一层 Cookbook 是 **infrastructure**——团队之外没人会读到它。

**玩家**永远看不到 Cookbook，但 Cookbook 里每一条配方在他手机上都会变成一次
真实的物理满足感。第 100 次拉杆必须和第 1 次一样有那种敲实、卡顿、回弹的
*thunk*-and-snap；剪影必须每次都"砰"一下从机器底部冒出来、等待被点击。这就是
Cookbook 服务的 Pillar 1 **触感先行**（"粉碎机的物理反馈是这款游戏的灵魂"）
和 Pillar 2 **每一次都是一场小剧场**（"玩家就算粉碎第 100 次同一个产物，
从摇杆 → 剪影 → 揭晓的微戏剧都必须完整"）。Cookbook 跑通时，玩家不会怀疑
"我在玩一个工具"，而是感觉 **自己在操作一台被认真对待的、做工扎实的小机器**。

### "反寡淡"的具体体感——这是 bar

2026-05-21 prototype 玩测留下的失败模式很清晰：核心循环 **机械上正确，但视觉
上没有承担**。Cookbook 的目标恰好是反过来——每个 hook signal 必须以足够的
视觉/音频/触觉重量"落地"，让首次玩家在十秒内 **不需要任何提示** 就产生
"我想再来一次"的反射动作。这与 prototype 的假设验证标准完全一致，也让
Cookbook 有了一根锐利的指针：**如果一条配方不能在真机上把 "seconds-to-next-pull"
指标拉低，这条配方就失败了。**

### 内在张力（Pillar Tension）— R11 修订

Cookbook 同时背负 **两个相反方向的设计承诺**，必须在文档里显式承认而非假装它们一致。

- **承诺 A（防过度刺激 / 过度 juicing）**：Pillar 4 *Cute But Weighted* 约束 squash ≤ 1.25、
  shake ≤ 8 px、F-5 总时长 ≤ 1500 ms；这是"克制法典"。Vlambeer juice 强度的 cozy 版降级。
- **承诺 B（防 prototype 寡淡 / 过度 under-juicing）**：2026-05-21 真机测试证明，机械循环
  正确不够；每个 hook 必须"砸地"才能撑住 Pillar 1 触感先行与 Pillar 2 剧场感。

**张力点**：旧 Cookbook 草稿只有 **Forbidden 清单**（防过度），没有任何机制保证"足够丰盈"。
一份完美遵守 Forbidden 的下游 GDD 仍可能在真机上重现 prototype 寡淡——因为
Cookbook 没有定义"足够亮"的下限。这是 creative-director 评审时点出的最严重单一缺陷。

**Cookbook 的对称约束解决方案**：

每条配方都同时拥有 **两份清单**——

1. **Forbidden 子项**（防过度）：写在 Section C 七配方表每条 Forbidden 块中
2. **Required Minimum 子项**（防不足，R11 新增）：写在 Section C 七配方表 Forbidden 块下方

二者 **必须同时满足** 才算合格配方。任一漏掉 → 配方失败：
- 违反 Forbidden → "Vlambeer 暴力"或"塑料弹性感"（过度方向失败）
- 违反 Required Minimum → "寡淡"（prototype 失败模式复现）

**设计意图**：克制 ≠ 削减。Cookbook 立场 = "该亮的地方必须亮，不该亮的地方一定不亮"。
它是 Vlambeer juice 词汇表的 cozy 版本，不是 Florence 的 minimalism；
是工匠的"做好的活儿"，不是僧侣的"够用就好"。下游 GDD 实现者与 reviewer
**两份清单都必须逐条核查**，code review 与 /design-review 各自拥有否决权。

### 参考坐标

| 参考 | 我们拿走什么 | 我们刻意不要什么 |
|---|---|---|
| **Nuclear Throne / Vlambeer 系列** | 七元素 juice 词汇表（anticipation、impact frame、screen shake、particles、freeze frame、color flash、audio layering）——Vlambeer 是现代 "juice" 概念的奠基者。 | 攻击性与战斗暴力。Mochi 的配方往**下**调——screen shake 振幅 2-6 px，不是 20+ px。借走词汇表，不借强度。 |
| **Yoshi's Crafted World / 安勒姆手工系列** | "手工质感"的 squash & stretch——纸、毛线、软纸板的物理感。视觉质量 + 温暖色板 + 永远可读的动作。 | 平台跳跃节奏。Mochi 是静态的；squash 必须一拍读完，不能跨多个跳跃帧展开。 |
| **Untitled Goose Game**（concept doc 已列入参考） | 极简背景、慷慨留白、动作在负空间里"活"起来。强化 Cozy Mechanical 视觉锚点。 | 恶作剧基调。Mochi 的 juice 永远没有"恶搞"那一拍——它即便可爱也是真诚的。 |
| **Florence / Apple Arcade 极简作品** | 克制。juice 只在配得上的关键时刻发射；其余时间画面是静止的。Mochi 会把同一个 loop 重复几百次，必须永远不显得杂乱。 | 一次性叙事弧。我们的配方必须经得起第 100 次重复，Florence 的配方为单次通玩设计。 |

### 为什么这不是"polish"

Cookbook 不是收尾打磨；恰恰相反，它是一个 **前置条件**。任何不挂 Cookbook 就
出厂的 Wave 3-6 GDD，都是会在 pre-production 后期需要昂贵手术的 GDD。所以这里
的 fantasy 还有一半是 **设计师 fantasy**——"我不会在 vertical-slice 前五天因为
摇杆手感不对而重写 Lever Interaction"。这给了一个元文档少见的情感重量：
Cookbook 是团队对自己的承诺，承诺 prototype 那次"寡淡"的失败模式 **不会再回来**。

## Detailed Design

### Core Rules

1. **Cookbook 是文档，不是 Autoload。** Cookbook 没有运行时单例，没有 `JuiceService`。
   它是一份引用合同：下游 GDD（Wave 3-6）在自己的 Tuning Knobs 里 cite 一条配方
   ID（例如 `JC-R2-lever_lock`），随后由各自的 gameplay 代码实现该配方。
   *Cookbook → 下游 GDD → 实现代码*，这是单向流动。

2. **每个 hook signal 只对应一条主配方。** 配方编号 `JC-R1` 至 `JC-R7`，与 hook
   signal 一一映射，不允许同一 hook 出现两份冲突配方。配方需要随 v1.0/v1.5
   演化时，新配方走 ADR amend 流程，不在 GDD 里"叠加"。

3. **配方的视觉峰值必须对位 Audio onset + Haptic strike。** 三方按 `Audio →
   await audio_lead_ms (35 ms) → Haptic` 顺序发射；视觉效果的 *Impact 相位*
   起点 = Audio onset 时刻 ± `audio_haptic_sync_window_ms / 2` (= ±15 ms)。
   这一规则把"机器有重量"从主观感受变成可测量的同步约束。

4. **任何 Juice 配方不订阅 Lifecycle 信号。** Cookbook 配方触发 100% 由
   gameplay 信号驱动（`lever_lock` 等）。禁止 Cookbook 因为 `app_resumed` 触发
   "欢迎回来"动画——这是 ADR-0002 反支柱结构守护的明示场景。

5. **每条配方有四相位 + 静默尾**：Anticipation → Action → Impact → Follow-through
   → Silence（最少 100 ms 安静尾，让玩家感知"这一拍结束了"，防止配方之间黏在
   一起）。Silence 是配方完整性的保证，不是空闲时间。

6. **配方词汇表（CTL = Cookbook Term Library）锁定**：
   `anticipation` · `squash & stretch` · `follow-through` · `screen shake` ·
   `time-scaling (freeze frame / slow motion)` · `color flash` · `particles` ·
   `layered audio`。下游 GDD 必须使用这 8 个术语；提出第 9 个术语必须走 ADR。

7. **Cookbook 配方的实现路径已锁定到 Godot 4.6 API**：`Tween` (scale/modulate/
   offset) · `CPUParticles2D`（**单条配方 amount 上限由 F-4 表逐配方约束；全部活跃粒子总和 ≤ 48 — 这是 SSOT**）· `Camera2D.offset` (shake) ·
   `AudioStreamPlayer2D` · `AnimationPlayer.speed_scale` (局部 freeze)。
   **Mobile renderer 下禁止** Environment Glow / 多 pass shader / `Engine.time_scale`
   （条件式，依赖 ADR-R Renderer 决议；若最终选 Forward+ 则部分约束放宽——见 B8）。
   详细 Forbidden 技术列表见每条配方下方 Forbidden 子项；粒子总数与 blend mode 约束以 **F-4 表为 SSOT**。

8. **多属性 Tween 必须 `set_parallel(true)`**（B11 新增，Godot 4 默认 serial）。
   F-1 同步窗口要求 scale / modulate / position 等多属性 **同步开始**——若忘记
   `set_parallel(true)`，Godot 4 默认串联执行会让 modulate Tween 在 scale Tween 完成后才开始，
   破坏 T1 压缩帧对齐。godot-gdscript-specialist code review 强制检查（AC-11 grep）。

### 七配方表（Recipe Catalog）

每条配方有 5 列字段。**配方 ID** 是下游 GDD 必须引用的 cite 锚点。

| ID | Hook signal · 意图 (1 句) | 配方详述（CTL 词汇组合 + 幅度） | 总时长 | Pillar |
|---|---|---|---|---|
| **JC-R1** | `lever_pull_start` · 让玩家感受到"摇杆有阻力，这个动作是真实的" | anticipation (small)：摇杆图形按下瞬间向上微蓄力 4 px / 60 ms + layered audio (micro)：低沉机械"咔"起始音，音量为 JC-R2 的 60% | 60–80 ms | P1 |
| **JC-R2** ⭐ | `lever_lock` · 让玩家感受到"金属顶住了——唯一一次有真实物理重量的冲撞" | squash & stretch (small)：摇杆 0.92 → 1.05 → 1.0 (2/3/3 帧) + screen shake (small)：纵 4 px / 横 1 px / 120 ms 衰减包络（前 40 ms 全幅，后 80 ms 线性归零）+ layered audio (medium)：sub-bass 1 帧 thump + 金属碰撞中高频两轨叠加 | 120–160 ms | **P1** + P2 |
| **JC-R3** | `shred_start` · 让玩家感受到"机器真的启动了，腔体里有东西在运转" | color flash (micro)：腔体内部亮度 +40% / 1 帧 → 衰减至 +15% 维持粉碎期 + particles (small)：腔体内 8–12 颗 `CPUParticles2D` 碎屑（lifetime 0.6 s，速度限制不超出机器边框）+ layered audio (small)：齿轮启动低频 + 纸张撕裂高频，onset 错开 30 ms | 80–120 ms | P2 |
| **JC-R4** | `shred_pulse` · 让玩家感受到"机器还在工作，有节奏，不是等待" | particles (micro)：从预实例化的 **CPUParticles2D 节点池**（5 个独立节点，预备于场景实例化时）每脉冲选取下一个空闲节点，调用 `restart()` 触发该节点 amount=4 颗碎屑（方向偏腔体底部，lifetime=0.4 s）+ layered audio (micro)：粉碎 loop 音每 `shred_pulse_interval_s` (=0.4 s) 插入 +3 dB / 30 ms 的音量 bump | 40 ms / 脉冲，间隔 400 ms，共 3–5 次 | P2 |
| **JC-R5** ⭐ | `reveal_pop` · 让玩家感受到"有东西真的从机器里弹出来了——空间上的惊喜" | squash & stretch (medium)：剪影 0.6 → 1.2 → 1.0 (2/3/4 帧) + anticipation (small)：出现前 60 ms 出口区域轻微收缩阴影 + follow-through (small)：尾部 2-3 帧 ±2 px 垂直惯性晃动 + color flash (micro)：亮黄/白 1 帧 → 原色 | 200–260 ms | **P2** |
| **JC-R6** | `product_land` · 让玩家感受到"这个小东西有重量，落实了" | squash & stretch (small)：产物填色帧 0.92 → 1.0 (2 帧) + follow-through (micro)：颜色饱和度 120% → 100% / 3 帧 + layered audio (small)：柔和落地声 + 短促"完成"音调 | 160–200 ms | P1 + P4 |
| **JC-R7** | `shelf_add` · 让玩家感受到"它有了一个家，收藏完成"——归属感而不是"流程结束" | anticipation (micro)：飞入弧线起始帧产物反向位移 4 px + Tween `TRANS_QUART/EASE_OUT` 弧线飞行 + follow-through (small)：落架后 2-3 帧 ±3 px 微弹跳 + layered audio (micro)：木头/布料轻触感落地音（非金属） | 180–240 ms | **P3** |

**每条配方的 Forbidden 子项**：

- **JC-R1 Forbidden**：
  - *设计*：禁止 squash 或 screen shake——视觉重量必须留给 JC-R2 的对比爆发位
  - *技术*：禁止用 `AnimationPlayer` 播放单次 scale 动画——`Tween` 更轻量

- **JC-R2 Forbidden** ⭐：
  - *设计*：禁止 color flash——色彩闪光是剧场高潮、专属 JC-R5 揭晓时刻
  - *技术*：禁止用 `Engine.time_scale = 0.0` 做 freeze frame——全局冻结破坏 sync 窗口与音频时钟；
    禁止 `GPUParticles2D` 粒子数 > 24——此时刻每次循环必发，调用积累风险高

- **JC-R3 Forbidden** (B6/B8 修订)：
  - *设计*：color flash 颜色禁止金色或高饱和彩色——这两种专属稀有产物揭晓 (v1.0+)；
    此处只用白/暖白亮度变化
  - *技术*：
    - 禁止 Environment Glow 模拟"内部光"（条件式：**如最终选 Mobile renderer 则 Forbidden**；
      Forward+ 路径 Glow 可用但需 ADR-R 决议后开放——B8 修订）
    - 禁止 `CPUParticles2D.amount > 12`（JC-R3 单节点 burst 上限，按 F-4 表 JC-R3 budget；
      之前文档写 ">48" 是与 F-4 总上限混淆，B6 SSOT 修订）
    - 全部活跃粒子总和约束以 F-4 表为 SSOT

- **JC-R4 Forbidden** (B5 修订)：
  - *设计*：禁止同时触发 screen shake——规律化抖动会被误读为 bug 而非节奏；
    shake 的"意外性"是其力量来源
  - *技术*：
    - 禁止 shader uniform 动画（每帧修改 `ShaderMaterial` 参数）——如最终选 Mobile renderer
      则 material rebind 累计成本不可预测，改用 `CanvasItem.modulate` Tween（条件式：依赖 ADR-R Renderer 决议）
    - 禁止假设存在 `CPUParticles2D.emit_one_shot()` 方法（Godot 4.6 无此 API）；必须用
      预实例化节点池 + `restart()` 实现（详见配方表 JC-R4 实现路径）
    - 禁止对 JC-R3 主粒子节点调用 `restart()`——会清空粉碎期已存在的活跃粒子，与
      F-4 表 "JC-R4 两批重叠 = 8" 数学相矛盾。JC-R4 只能操作自己的节点池
    - 节点池容量上限 = 5 节点（足以覆盖 `n_pulses` 最大值 5）；超出走 ADR amend

- **JC-R5 Forbidden** ⭐：
  - *设计*：禁止 screen shake——剪影本身 squash 振幅已为 Cookbook 最高，叠加 shake 触发"太多了"
    的反面案例
  - *技术*：禁止用 `Engine.time_scale` 做 freeze frame；用 `AnimationPlayer.speed_scale = 0.0`
    实现局部 freeze（属 Section G Tuning Knob 可选）

- **JC-R6 Forbidden** (B8 修订)：
  - *设计*：Pillar 4 重内容场景下禁止任何夸张 squash 或欢庆粒子——"轻重得当"的实现方式是
    **不区分**，而不是增加悼念感
  - *技术*：禁止填色 shader 多 pass（`render_mode blend_add`）——条件式：**如最终选 Mobile renderer**
    则 overdraw 惩罚严重 → Forbidden；若选 Forward+ 则可用但需 ADR-R 决议后开放。
    保守 MVP 立场：blend_add 全局禁用直到 ADR-R 决议

- **JC-R7 Forbidden**：
  - *设计*：禁止任何"成就感"视觉信号（金粉、光晕、烟火粒子）——直接违反 Pillar 3 收藏不焦虑
  - *技术*：禁止为飞行路径用 `Path2D + PathFollow2D`——单次短动画过重，用 Tween 弧线 easing

### Required Minimum（R11 新增 — 对称防"寡淡"复发）

每条配方必须同时满足下列下限。任一缺失 → 配方失败（违反 Player Fantasy "反寡淡"承诺）。
code review 与 /design-review 在 Forbidden 之外强制核查本清单。

- **JC-R1 Required Minimum**：
  - layered audio ≥ 1 轨（机械低频 transient）**不得省略**——lever_pull_start 是循环起点，
    无 audio 反馈玩家会误判为输入丢失
  - 视觉上允许 anticipation 缺省（让 JC-R2 承担对比爆发位）

- **JC-R2 Required Minimum** ⭐：
  - 必须 **三方共振齐发**：squash + screen shake + audio sub-bass thump，**缺一不可**
  - `shake_amplitude` ≥ 3 px（下限保证"撞上感"——JC-R2 是 Cookbook 唯一允许 shake ≥ 3 的时刻）
  - audio sub-bass thump 必须有可感的 1-frame transient（不可只用 reverb tail）

- **JC-R3 Required Minimum**：
  - 三要素齐备：color flash ≥ +30% brightness + particle burst ≥ 8 颗 + audio 双轨（机械低频 + 纸张高频）
  - 三选三才合格；任一缺失则机器看起来"没在工作"

- **JC-R4 Required Minimum**：
  - 每脉冲至少 **3 颗新增碎屑**（按 F-4 表节点池实现）
  - audio +3 dB / 30 ms bump 必须发生（不可省略——视觉粒子单独无法承担节奏感）

- **JC-R5 Required Minimum** ⭐：
  - squash overshoot ≥ 1.15（Cookbook 揭晓时刻必须是 squash 最大配方）
  - 1 帧 color flash 必须发生（亮黄白系，VA-1 范围内）
  - layered audio **必须双层**：attack transient + sustained body；不允许只用一轨"弹出音"
  - 这是 Pillar 2 剧场高潮，Required Minimum 最严格

- **JC-R6 Required Minimum**：
  - squash 必须发生（即使 s_compressed=0.92 接近无）
  - layered audio **双轨齐发**：柔和落地音 + 短促"完成"音调；缺任一则失去"实物落定"感

- **JC-R7 Required Minimum**：
  - 四元素 **全部齐备**：anticipation (反向位移 4 px) + Tween 弧线飞行 + follow-through 弹跳 (≥ 2 帧) + 落架音
  - 缺任一 → 退化为"流水账动画"而非"归属感时刻"
  - **Onboarding 偏离**：前 3 次 shelf_add 走 enhanced 变体（R12，见 Dependencies 表）

> **核查方式**：godot-gdscript-specialist 在 code review 阶段同时跑 Forbidden grep
> 与 Required Minimum 存在性 grep；缺任一即 BLOCKING。AC-11 覆盖 Forbidden grep，
> AC-02 + 新增 AC-14（见 Acceptance Criteria）覆盖 Required Minimum 存在性。

### States and Transitions

每条配方都遵循同一个相位状态机。下游 GDD 实现时必须按此次序触发，不允许跳相。

| 相位 | 触发 | 持续 | 典型工作 |
|---|---|---|---|
| **Anticipation** | hook signal `emit()` | 60–100 ms（Cookbook 单条配方最长 100 ms） | 反向预备：反向 scale、反向位移、出口收缩阴影 |
| **Action** | Anticipation 结束 | 40–120 ms | 主体动作（向 Impact 加速）：拉杆按下、剪影上升、产物飞出 |
| **Impact** ⭐ | F-3 **T1 压缩关键帧** 渲染时刻 = `t_emit + audio_lead_ms` ± 15 ms（同 F-1 `impact_anchor_t_ms` 窗口）= Haptic strike ± 15 ms | 1–3 帧（T1 关键帧本身） | **T1 压缩极值帧**——squash 最大压缩、视觉"砸地"瞬间。这是 Cookbook 同步窗口的中心。|
| **Follow-through** | Impact 结束 | 60–180 ms（含 F-3 T2 overshoot + T3 回弹两子阶段） | 弹性回弹：T2 段拉伸 overshoot（如有）→ T3 段回到静止；shake decay 衰减；颜色回归 |
| **Silence** | Follow-through 结束 | ≥ 100 ms（Core Rule 5） | 空白尾——下一个配方不允许在此期间发射 |

**关键约束（B1/B2 修订）**：
- Impact 相位 = F-3 的 **T1 压缩关键帧**（compression frame），**不是** T1+T2 的 overshoot 拉伸帧。原始审查发现：JC-R2 T1=33 ms ≈ audio_lead_ms 35 ms ✅；若按 T1+T2=83 ms 解读则严重超窗。
- Overshoot (T1+T2 关键帧) 在 squash & stretch 动画语义中是 **弹性回弹**，物理上代表"被压缩物体的反向超调"——它属于 Follow-through 相位的视觉表达，**不参与 F-1 同步窗口**。
- 视觉 T1 压缩帧若过早（早于 t_emit + audio_lead_ms - 15 ms = `[t_i - 15]`），表现为"先看到打击再听到声音"，玩家潜意识识别为"不真实"；若过晚（晚于 [t_i + 15]），表现为"声音空响"。

### Interactions with Other Systems

#### 与 Audio System（上游契约消费方）

| 数据流 | 接口 | 所有者 |
|---|---|---|
| Cookbook → AudioSystem | 配方调用 `AudioSystem.play(sfx_key)`，sfx_key ∈ registry sfx_* 常量（locked） | AudioSystem 拥有 key 表 |
| 共享时序常量 | `audio_haptic_sync_window_ms = 30`、`audio_lead_ms = 35`、`audio_bgm_offset_db = -12 dB` | registry（haptic-system.md / audio-system.md 共有） |
| 同帧调用顺序 | `Audio.play()` → `await timer(audio_lead_ms / 1000.0)` → `Haptic.play()` | Audio System Core Rule 9 |

#### 与 Haptic System（上游契约消费方）

| 数据流 | 接口 | 所有者 |
|---|---|---|
| Cookbook → HapticSystem | 配方调用 `Haptic.play(StringName)`，key ∈ registry haptic_* 常量（locked） | HapticSystem 拥有 key 表 |
| 触觉预设映射 | MVP 预设 = `selection / light / medium / heavy`，配方不暴露自定义波形 | HapticSystem Event Catalog |
| 用户开关 | Cookbook 不读取 `settings.haptic_enabled`；触觉是否发射由 HapticSystem 内部 gate 决定，Cookbook 视为"调用即可" | HapticSystem |

#### 与下游 GDD（7 个引用方）

| 下游 GDD | 引用方式 | 引用强度 |
|---|---|---|
| Lever Interaction (#8) | Tuning Knobs cite `JC-R1` + `JC-R2`；godot-gdscript-specialist code review 强制检查 | 硬引用 |
| Shred Process (#9) | Tuning Knobs cite `JC-R3` + `JC-R4` | 硬引用 |
| Silhouette Reveal (#11) | Tuning Knobs cite `JC-R5` + `JC-R6` | 硬引用 |
| Shelf Collection (#12) | Tuning Knobs cite `JC-R7` | 硬引用 |
| Mochi Character (#6) | Cookbook 不提供 `mochi_blink` 配方（Mochi 角色情绪反应属角色系统职责）；Cookbook 提供 CTL 词汇作为可选词典 | 软引用 |
| Onboarding (#15) | 复用 JC-R1-R7 的全套配方；**两处受控偏离 (R12 修订)**：(a) 首次产物 reveal 时 JC-R5 medium → **large** 临时升级；(b) 前 3 次 shelf_add 走 **JC-R7 enhanced 变体**——anticipation 4 → **6 px**、follow-through 弹跳 ±3 px / 3f → **±4 px / 4f**、落地音 +**2 dB**、新增 1 帧暖白亮度 flash (+20% brightness，VA-1 允许的暖白色相)；Onboarding GDD 必须显式声明两处偏离，并由 `first_run_shelf_add_count` 持久化计数（≤ 3 后回归标准 JC-R7）| 受控偏离 |
| Accessibility System (#16) | Reduce Motion = ON 时所有配方的 screen shake / squash 幅度乘以 0.0–0.5；具体降级矩阵由 Accessibility GDD 定义；Cookbook 提供"允许降级"接口契约 | 反向控制 |

## Formulas

> Cookbook 是 Wave 3-6 GDD 引用的合同，因此本节公式比平衡数学更接近"工程契约"：
> 时序对位、振幅约束、跨配方资源预算。所有常量 ≥ 单系统使用的均已 registry-locked。
>
> 全局假设：渲染帧率锁定 60 FPS（`technical-preferences.md` MVP 约束）。
> 1 frame = 16.667 ms。所有 ms 参数注释 = N 帧 @ 60 FPS 等价。

### F-1：同步对位公式（Impact 相位 T1 压缩帧对齐时刻）

> **B1 锚点定义（reviewer 修订）**：F-1 之前的版本 `audio_onset_t_ms` 模糊覆盖了三个不同时间——
> 调用时刻（t_call）、混音器接收时刻（t_emit）、扬声器/耳机输出时刻（t_perceive）。
> Cookbook 的工程契约 **锚定 t_emit**（混音器调度时刻，可在 Godot 内确定性测量），
> 不锚定 t_perceive（依赖 OS audio pipeline 与外设路径，跨设备波动 25-65 ms）。
> 平台路径差异由独立的 `platform_latency_compensation` 表表达，下游可选择编译时补偿或
> 进入"BT 大窗口"降级模式（AC-01b ADVISORY 路径）。

`impact_anchor_t_ms = t_emit + audio_lead_ms`
= `t_emit + 35`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `t_call` | — | float | [0, ∞) | gameplay 代码调用 `AudioSystem.play(sfx_key)` 的栈帧时刻。**不是 F-1 锚点**（栈深度抖动 1-3 ms 不可控）。仅用于 log 调试。|
| `t_emit` | t_e | float | [0, ∞) | `AudioStreamPlayer2D` 真正调度采样进入混音器输出 buffer 的时刻（毫秒，自 hook signal `emit()` 起计；Godot 内可由 `AudioServer.get_time_to_next_mix()` 推算）。**F-1 唯一锚点**。|
| `t_perceive` | t_p | float | [t_e, t_e + 65] | 玩家在外设上感知到 audio onset 的时刻 = `t_emit + platform_audio_output_latency_ms`（见下表）。**F-1 不直接约束 t_perceive**，但 AC-01a/01b 分别校准扬声器与 BT 路径下的 t_perceive 偏移。|
| `audio_lead_ms` | — | int (registry) | =35（locked, haptic-system.md owns） | Haptic 相对 Audio 的延迟发射量 |
| `impact_anchor_t_ms` | t_i | float | [35, ∞) | 视觉 Impact 相位 **T1 压缩关键帧**（squash 极值帧）的目标时刻 — 见 B2 / F-3 备注 |

**Output Range:** [35, ∞) ms（典型 hook 内 35-1500 ms）
**约束：** 视觉 T1 压缩关键帧渲染时刻必须落在 `[t_i - 15, t_i + 15]` 窗口内（half of `audio_haptic_sync_window_ms = 30`）。
**Example:** `lever_lock` hook 在 t=0 emit，AudioSystem 在 t_emit=2 ms 调度采样，则视觉 T1 压缩帧目标时刻 = 37 ms，允许窗口 [22, 52] ms。
**注意：**
- 此公式只规范视觉时序与 t_emit 的对齐；Haptic 时序由调用方保证 `await timer(audio_lead_ms / 1000.0)` 后再 `Haptic.play()`，F-1 不直接控制触觉。
- "Impact 视觉峰值"在 F-3 squash & stretch 语义中 **= T1 压缩关键帧（impact frame）**，**不是** T1+T2 的 overshoot 关键帧。Overshoot 是"弹性回弹"，归入 Follow-through 相位（见 States and Transitions 表更新）。

#### `platform_audio_output_latency_ms` 平台路径补偿表

下表为 t_emit → t_perceive 的典型偏移（毫秒）。**OQ-1 spike**（Wave 3 启动前 1-2 天，B12 移交项）必须用真机校准本表。

| 平台路径 | 估算 latency_ms | 数据来源 | 玩家感知漂移 | 处置方案 |
|---|---|---|---|---|
| iOS 内置扬声器 | 12-22 ms | Apple WWDC '23 audio session | 在 30 ms 同步窗口内 | AC-01a 默认路径 |
| iOS AirPods (BT classic) | 35-55 ms | CoreAudio AVAudioSession latency 实测 | 超出窗口 → t_perceive 偏移 → "声音迟到" | AC-01b ADVISORY；Audio System v1.0 可选 BT 检测后整体 audio_lead_ms +20 ms 补偿 |
| iOS AirPods Pro/Max (低延迟) | 18-30 ms | Apple "MV-HEVC"-class latency mode | 临界窗口 | 默认按扬声器路径 |
| Android 内置扬声器 | 20-40 ms | Android Pro Audio class device 中位数 | 临界窗口 | follow-up Android port 期校准 |
| Android BT 经典 | 50-65 ms | AOSP audio HAL 文档 | 严重超窗 | Production v1.5 决定补偿策略 |

**Cookbook 立场：** 默认走 iOS 扬声器路径锁定 `t_emit + 35 ms` 视觉对齐；BT 路径靠 AC-01b advisory 校验；具体补偿表写入 Audio System GDD 而非 Cookbook（职权边界）。

### F-2：Screen shake 衰减包络

`shake_amplitude(t) = base_amp_px * decay_factor(t)`，其中：

```
decay_factor(t) =
  1.0                                    if t < HOLD_MS
  max(0, 1 - (t - HOLD_MS) / DECAY_MS)   if HOLD_MS ≤ t < HOLD_MS + DECAY_MS
  0                                      otherwise
```

`shake_offset(t) = shake_amplitude(t) * shake_direction_vec2 * sign_alternator(frame)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `t` | t | float | [0, HOLD + DECAY] ms | **以 Impact 相位起点（t = `impact_center_t_ms`）为 0 计时**（不是 hook emit 时刻）|
| `base_amp_px` | A | float | [0, 8] px | shake 最大幅度。上限 8 px 由 Pillar 4 Cute But Weighted 约束 |
| `HOLD_MS` | H | int | [0, 60] ms | 全幅持续时间 |
| `DECAY_MS` | D | int | [40, 200] ms | 线性衰减到 0 的持续时间 |
| `shake_direction_vec2` | v⃗ | Vector2 | unit-vec | 抖动方向单位向量，配方各自指定（JC-R2: (0.23, 0.97) 纵向为主；JC-R7: (1.0, 0) 横向） |
| `sign_alternator` | s | int | {-1, +1} | 帧间反向，制造抖动效果。Godot `Camera2D.offset = shake_offset(t)` 每帧赋值 |

**Output Range:** `shake_offset` ∈ Vector2[-8, 8] px
**Examples:**
- JC-R2: A=4, H=40, D=80, v⃗=(0.23, 0.97)（纵 4 / 横 1 px 比例）
- JC-R7: A=2, H=20, D=60, v⃗=(1.0, 0)
**Example calc (JC-R2)**: `shake_amplitude(0) = 4 * 1.0 = 4 px`; `shake_amplitude(60) = 4 * (1 - 20/80) = 3 px`; `shake_amplitude(120) = 0`.

### F-3：Squash & stretch 三关键帧 Tween

```
scale(t) = lerp_keyframes([
  (0,             1.0),                # 静止
  (T1,            s_compressed),       # 压缩极值
  (T1 + T2,       s_overshoot),        # 拉伸极值（可选，T2=0 时跳过）
  (T1 + T2 + T3,  1.0)                 # 回到静止
], t, ease=EASE_IN_OUT)
```

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `t` | float | [0, T1+T2+T3] ms | 以 hook signal `emit()` 起计（不是 Impact 起点；T1 段是 Anticipation 相位）|
| `s_compressed` | float | [0.5, 0.95] | 压缩极值。Cookbook 下限 0.5（再低显得"塌"违反 Pillar 4）|
| `s_overshoot` | float | [1.0, 1.25] | 拉伸极值。Cookbook 上限 1.25（再高显得橡皮泥违反 Pillar 4 Cute But Weighted）|
| `T1` | int | [16, 100] ms | 压缩相位，1-6 帧 @ 60 FPS |
| `T2` | int | [0, 100] ms | 拉伸相位，**0 ms 时跳过 overshoot keyframe**（实现退化为 2 关键帧 Tween）|
| `T3` | int | [16, 100] ms | 回弹相位，1-6 帧 @ 60 FPS |

**Output Range:** [s_compressed, s_overshoot] = [0.5, 1.25]
**Examples (单位 ms / 帧)：**
- JC-R2: s_c=0.92, s_o=1.05, T1=33 (2f), T2=50 (3f), T3=50 (3f)
- JC-R5: s_c=0.6, s_o=1.2, T1=33 (2f), T2=50 (3f), T3=67 (4f) ⭐ 振幅最大
- JC-R6: s_c=0.92, s_o=1.0, T1=33 (2f), T2=0 ❗（跳过 overshoot 路径）, T3=33 (2f)

**实现注意：** `lerp_keyframes` 为伪码——Godot 4 实现用 `Tween.tween_property("scale", ...)` 链式调用，每段一个 sub-tween；`T2=0` 时跳过中间一段。

**与 F-1 同步窗口的对齐（B2 修订）：**
- 视觉 **Impact 帧 = T1 关键帧渲染时刻 = `t_emit + audio_lead_ms` ± 15 ms**（F-1 `impact_anchor_t_ms` 窗口）
- T1 关键帧表示"撞上"的压缩极值——squash & stretch 动画语义里的 *impact frame*
- T1+T2 关键帧（overshoot 拉伸极值）= 弹性回弹，**归 Follow-through 相位**，**不在 F-1 同步窗口约束内**
- 对照配方实例：JC-R2 T1=33 ms ≈ 35 ms ✅；JC-R5 T1=33 ms ≈ 35 ms ✅；JC-R6 T1=33 ms ≈ 35 ms ✅
- 此前审查发现的"JC-R5 overshoot 在 83 ms 超出 [20,50] 窗口" → 是错把 overshoot 当 impact；按本节修订后已解除矛盾

### F-4：跨配方 particle 活跃数同帧约束（最大瞬时值）

`active_particles_total(t) = sum over all recipes r of active_count_r(t)`

其中每条配方的活跃粒子瞬时数：

`active_count_r(t) = burst_count_r * overlap_factor_r`
`overlap_factor_r = floor(lifetime_ms_r / interval_ms_r) + 1`（interval = 0 或单次 burst 时取 1）

**B4 修订说明**：旧公式 `ceil(lifetime/interval)` 对 lifetime=interval 边界返回 1（不重叠），与"相邻批次刚好同帧重叠 = 实际 2"的物理事实矛盾。新公式 `floor(lifetime/interval) + 1` 对 lifetime=interval 返回 2 ✅；对 lifetime=0.5×interval 返回 1（无重叠）✅；对 lifetime=2×interval 返回 3（三批共存）✅。

**约束（硬上限，B6 SSOT）：** `max over t (active_particles_total(t)) ≤ 48`（条件式，依赖 ADR-R Renderer 决议；blend mode 进一步约束见 B7 注释）

**Per-recipe budget table:**

| 配方 | burst_count | lifetime_ms | interval_ms | overlap_factor (B4 新公式) | max active 瞬时 | 备注 |
|---|---|---|---|---|---|---|
| JC-R3 | 8-12 | 600 | (single burst) | 1 | 12 | blend_mix 默认 |
| JC-R4 | 3-4 / 脉冲 | 400 | 400 (= `shred_pulse_interval_s` × 1000) | floor(400/400)+1 = **2** ✅ | 8 | 节点池实现（5 节点 × amount=4，见 JC-R4 配方实现路径） |
| JC-R5 v1.0 (rare shimmer) | 16 | 400 | (single burst) | 1 | 16 | v1.0 限定 |
| JC-R7 | 0 | — | — | 0 | 0 | 无粒子（Forbidden 锁定） |
| **MVP 最坏（无 R5 rare）** | | | | | **20 同帧瞬时** | 充分余量 |
| **v1.0 最坏（含 R5 rare）** | | | | | **36 同帧瞬时** ✅ < 48 | |

**B7 blend mode 约束（新增）：**
- 上述 48 上限 **假设全部使用 `blend_mix`（Godot CanvasItem 默认）**
- 若任一粒子源切换 `blend_add`（加色混合）→ 因 overdraw 倍增，**该源的活跃上限降至原值的 50%**（如 R5 rare shimmer 若 blend_add 则 16 → 8）
- 此约束 **必须真机 profile 验证**（Production Sprint 0 前置 spike，B7 移交项）
- Cookbook MVP 阶段全部锁定 `blend_mix`；blend_add 仅在 v1.0+ rare shimmer 经性能验证后启用

**Output Range:** `active_particles_total ∈ [0, 48]`（blend_mix 路径），MVP 实测上限约 20、v1.0 含 rare 约 36。
**注意：** F-4 是 **最大瞬时** 约束（≠ 时间积分），因为 GPU/CPU 粒子的性能瓶颈是单帧实例数。JC-R4 的"两批重叠"通过 `overlap_factor = floor(lifetime/interval) + 1` 显式建模（B4 修订后公式）。

### F-5：单循环 juice 总时长预算

`total_juice_ms = T_JC_R1 + T_JC_R2 + T_JC_R3 + (n_pulses × T_pulse_body) + T_JC_R5 + T_JC_R6 + T_JC_R7`

**Variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `T_JC_R*` | int | 80/160/120/—/260/200/240 ms | 各配方主体时长（Anticipation + Action + Impact + Follow-through，不含 Silence 尾）|
| `n_pulses` | int | [3, 5] | JC-R4 在一次粉碎中触发的脉冲次数 |
| `T_pulse_body` | int | 40 ms | JC-R4 单次脉冲本体（不含间隔） |

**约束：** `total_juice_ms ≤ 1500 ms`（Cookbook anti-bloat 上限，反向于"反寡淡"——既不能太少也不能太多挤压玩家呼吸时间）
**Default calc:** 80 + 160 + 120 + (5 × 40) + 260 + 200 + 240 = **1260 ms ✅** 余量 240 ms
**注意：**
- **Silence 尾（Core Rule 5 的 ≥100 ms）不计入 F-5**——Silence 是配方之间的物理隔离时间，由游戏进程驱动（玩家拉杆到剪影显示之间的等待），不是 juice 占用帧预算
- `JC-R4` 间隔 400 ms × (n_pulses - 1) 也不计入 F-5——间隔期是机器静默运转期，是 player perception，不是 juice 动画
- `n_pulses` 由 Shred Process GDD 在自己的 Tuning Knobs 决定（Cookbook 提供上下限）

### F-6：Reduce Motion 振幅降级因子

`effective_amp = base_amp * reduce_motion_factor`

对 F-3 的 squash 偏差量：
`effective_s_compressed = 1.0 - (1.0 - base_s_compressed) * reduce_motion_factor`
`effective_s_overshoot = 1.0 + (base_s_overshoot - 1.0) * reduce_motion_factor`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `reduce_motion_factor` | float | {0.0, 0.5, 1.0} | 离散三档（Mochi 设计决策）。**Accessibility GDD (#16) 是定义方**，Cookbook 只提供公式结构；阈值映射由 Accessibility GDD 完成 |
| `base_amp` | float | F-2 / F-7 各自范围 | 原始振幅 |
| `base_s_compressed` / `base_s_overshoot` | float | F-3 范围 | 原始 squash/stretch 极值 |

**Output:**
- factor=1.0 → 全振幅（默认）
- factor=0.5 → 振幅减半，squash/stretch 偏差量减半
- factor=0.0 → 振幅归零，squash/stretch 恒为 1.0（scale 不变）

**约束与作用域：**
- F-6 **只作用于振幅** —— 时长（T1/T2/T3、HOLD_MS/DECAY_MS、total_juice_ms）**不被** F-6 修改。时长是否降级由 Accessibility GDD 决定（Apple HIG `prefers-reduced-motion` 默认不缩时长，仅停动画或换静态过渡）
- JC-R6 边界：`base_s_overshoot = 1.0`（无 overshoot），偏差量 = 0，F-6 对其无效——这是预期行为（JC-R6 本就无 overshoot），不是公式 bug
- F-6 **不作用于** F-4 的 particle counts（粒子是否禁用由 Accessibility GDD 决定，例如 Reduce Motion 关闭所有 `CPUParticles2D`）

### F-7：Anticipation 反向预备位移

`anticipation_offset_px = action_amplitude * anticipation_ratio`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `action_amplitude` | float | [2, 12] px | 主动作的视觉运动幅度（如 JC-R7 飞行起步、JC-R1 摇杆位移）|
| `anticipation_ratio` | float | [0.05, 0.15] | 反向预备相对主动作的比例（Cookbook 锁定范围；超出该范围属于"过度蓄力"）|
| `anticipation_offset_px` | float | [0.5, 1.8] px | 反向预备的位移幅度（B10 修订：下限 0.1 → 0.5 防 sub-pixel snap 失真——Godot 2D 默认 `texture_filter` + 移动设备像素密度下，< 0.5 px 的位移在 retina 屏会被 snap 到 0 px，等同无动画）|

**Output Range:** [0.5, 1.8] px
**使用语义（避免量纲歧义）**：
当配方表已写明"反向位移 N px"时，N **即** F-7 输出 `anticipation_offset_px`，无需再乘 ratio。F-7 主要作为 **v1.0+ 新配方的派生工具** 与 **范围验证器**——验证已写值是否落在 [0.1, 1.8] 区间，超出则属"过度蓄力"违规。

**F-7 与 F-6 叠加：** `effective_offset = anticipation_offset_px * reduce_motion_factor`

## Edge Cases

### 同步与降级类

- **如果 Reduce Motion = 0.0 时玩家触发 JC-R2 (lever_lock)**：scale Tween 退化为 `scale = 1.0` 恒值；shake `base_amp_px * 0 = 0` 无抖动；Audio + Haptic 仍按 audio_lead_ms 正常发射——玩家依然听到"金属顶住"的声音和触觉，只是没有屏幕震动与压缩。这是预期行为，不是 bug。理由：Apple HIG 明确"Reduce Motion 是关动作不是关反馈"。
- **如果 Reduce Motion = 0.5 时 JC-R5 的 s_compressed = 0.6**：effective_s_compressed = 1.0 - (1.0 - 0.6) * 0.5 = 0.8。剪影压缩从 0.6 升到 0.8，过冲从 1.2 降到 1.1。视觉幅度对半。Tween 时长 T1/T2/T3 不变（F-6 不动时长）。
- **如果 settings.haptic_enabled = false 但 Audio 正常发射**：HapticSystem 内部 gate 自然跳过，Cookbook 配方不改变调用顺序——仍 await `audio_lead_ms` 再尝试 Haptic.play()，HapticSystem 内部判断 enabled=false 后 silently no-op。Cookbook 不需要知道这个状态。
- **如果 SFX volume = 0 (静音) 但触觉开**：F-1 同步计算依然基于 `audio_onset_t_ms`（即调用时刻，不管音频是否发声），impact_center 仍按 t_a + 35 ms 计算。视觉峰值仍与触觉对齐，避免"静音模式下视觉漂移"。

### Lifecycle 中断类

- **如果配方动画进行中 app 转入后台**（OS `application_paused` 通知到达）：所有 Tween 和 CPUParticles2D 由 Godot Scene Tree pause 状态自动暂停（前提：Cookbook 配方所在节点 `process_mode != PROCESS_MODE_ALWAYS`）。Audio + Haptic 由各自 Foundation 系统的 pause 行为处理。**Cookbook 不主动监听 `app_paused`**（Core Rule 4）。
- **如果 app 从后台回前台 (`application_resumed`)**：所有 Tween 从暂停帧继续，Particles 复活。但 sync 窗口 audio_haptic_sync_window_ms 已经被打断；剩余动画不再保证 Impact 帧与 Audio onset 对齐。**处置**：被中断的配方播完剩余动画即可，不重新发射 Audio/Haptic 也不重置进度（玩家已经看过一半，重播会很怪）。下一次新的 hook signal 才走完整 F-1 同步。
- **如果 IME 弹起打断 JC-R2 中段** (Text Input GDD 的 LONG_PRESSING+PAUSED 路径)：IME 弹起触发 `application_paused`，进入上一条处置。预期玩家此时已经按下摇杆但还没拉到 trigger 阈值——拉杆动画播完即可，不强制 trigger（Lever Interaction GDD 的状态机控制）。

### Hook signal 重叠/抢占类

- **如果玩家在 JC-R5 (`reveal_pop`) 完成前再次拉杆触发 JC-R2**：违反 Cookbook Core Rule 5 (Silence ≥ 100 ms)。**处置**：Lever Interaction GDD 自己的状态机必须 gate 此种重叠（IDLE→PULLING 只能在 REVEAL_DONE 后进入）；Cookbook 不在 runtime 拦截，但 godot-gdscript-specialist code review 强制检查 Lever GDD 的状态机闭合。**如果运行时仍发生**（如调试场景）：旧 JC-R5 Tween 继续播放，新 JC-R2 同时启动；后果是视觉混乱但不崩溃。
- **如果同一帧 emit 两个不同 hook signal**（理论不应发生但要兜底）：按 hook signal 优先级 `lever_lock > reveal_pop > shred_start > shred_pulse > product_land > shelf_add > lever_pull_start` 决定 sound channel 抢占——Audio System 自己的混音规则处理。Cookbook 视觉效果不互斥，可同帧执行（性能由 F-4 + F-5 保证）。
- **如果 JC-R4 第 N 次脉冲发射时距 JC-R3 启动 < 100 ms**：意味着 Shred Process GDD 把首次脉冲 offset 设得太短。**处置**：Cookbook 不在 runtime 拦截；Shred Process GDD 的 Tuning Knobs 必须 cite `JC-R4.first_pulse_offset >= 300 ms`（与 haptic-system.md F-2 派生一致）。code review 强制检查。

### Performance budget 越限类

- **如果 v1.0 加入稀有产物揭晓 (rare JC-R5) 与 shred_start 余粒子同帧叠加**：F-4 计算 12 + 8 + 16 = 36 < 48 ✅。但如果未来 v1.5 再加新粒子源（季节限定特效），可能超过 48。**处置**：v1.0+ 任何新增粒子源必须重新计算 F-4 表，超 48 则 Cookbook ADR amend 提升上限或砍其他源。MVP 阶段 F-4 表锁定。
- **如果 device 实际帧率 < 60 FPS（如 iPhone XS 满电烫机降频到 45 FPS）**：所有 F-3 / F-5 的 ms 时长保持不变，但实际显示帧数变少（如 T1=33 ms 在 45 FPS 下只显示 1.5 帧）。**处置**：MVP 接受此降级（玩家会感觉动画"略卡"但不破坏 sync）；Production Sprint 1 真机测试若 P95 帧率长期低于 55 FPS，触发 Tech Debt 任务讨论是否帧率自适应。**绝不通过降低 ms 时长来掩盖性能问题**——这会改变 juice 的节奏感。
- **如果 CPUParticles2D 池满 (`amount` 上限达到)**：Godot 自动覆盖最老粒子。视觉上"碎屑突然消失"但不会崩溃。**处置**：F-4 表已为 MVP 留 48 上限 vs 20 实际占用的 28 粒子安全余量，不会触发。

### Pillar 冲突类

- **如果玩家正在写"重内容"** (Text Input GDD 标记的 Pillar 4 heavy mode)：JC-R6 `product_land` 仍按标准配方播放（s_compressed=0.92, s_overshoot=1.0）。**禁止任何 Pillar 4 检测分支去改变 JC-R6 振幅**（Core Rule 7 实现路径锁定）——Mochi 的工匠姿态体现在"同样的动作对待轻重一致"，不是"重内容时变悲伤"或"轻内容时变欢乐"。这是 Cookbook 反 attention-manipulation 设计。
- **如果连续 30 秒无 hook signal 触发**（玩家发呆）：Cookbook 不主动启动任何 idle juice。`mochi_blink` 由 Mochi Character (#6) 决定（角色系统职责，不是 Cookbook 职责）。Cookbook 在静默期完全无动作——这是 Pillar 5 Unlimited But Meaningful 的视觉表达。

### Onboarding 偏离冲突

- **如果 Onboarding 模式下 JC-R5 升级到 large 但 Reduce Motion = ON**：以 Reduce Motion 为准——effective_s_overshoot 按 factor 缩放。理由：无障碍优先级 > onboarding 强调；首次玩家若需要 Reduce Motion，不应被 onboarding 的"large 升级"忽略。
- **如果 Onboarding 已结束但 first-run flag 未持久化**（Persistence 写入失败）：下次启动仍走 Onboarding，JC-R5 会再次升级 large。**处置**：Cookbook 不知道 first-run flag，Onboarding GDD (#15) 的状态机问题；Cookbook 接受重复 large 配方但不主动去重。
- **如果 Onboarding 前 3 次 shelf_add enhanced 变体 (R12) 遇 Reduce Motion = 0.5**：以 Reduce Motion 优先——JC-R7 enhanced 各项振幅按 factor 缩放后仍属 enhanced 变体（即 anticipation 6 × 0.5 = 3 px，弹跳 4 × 0.5 = 2 px / 4 帧）。Onboarding GDD 不另设 enhanced × reduce 双重表；color flash 亮度 +20% × 0.5 = +10%（保留但减半）。理由与 JC-R5 large 一致：Accessibility 优先级 > Onboarding 强化。
- **如果 `first_run_shelf_add_count` 持久化失败累积超过 3**：Cookbook 不在 runtime 拦截；下次启动 Onboarding GDD 重读 count 时若 ≥ 3 则直接回归标准 JC-R7。计数容错由 Persistence 与 Onboarding GDD 共同处置（计数 +1 时即 save_when_idle()，Persistence GDD 已 Reviewed）。

## Dependencies

### Upstream（Cookbook 依赖的系统）

| System | Type | 数据流 | Cookbook 引用的具体接口 | bidirectional 义务 |
|---|---|---|---|---|
| **Audio System** (#3, Reviewed) | Hard | Cookbook → Audio | `AudioSystem.play(sfx_key)` · `AudioSystem.play_loop(sfx_key)` · `AudioSystem.stop_loop(sfx_key)`；sfx_key ∈ registry sfx_* 常量集 | ❗ Audio System GDD 需补一行 "referenced_by: design/gdd/juice-cookbook.md" 在 Cross-References；Phase 5 一并处理 |
| **Haptic System** (#4, Reviewed) | Hard | Cookbook → Haptic | `Haptic.play(StringName)`；key ∈ registry haptic_* 常量集；不读 `settings.haptic_enabled`（HapticSystem 内部 gate） | ❗ Haptic System GDD 需补一行 "referenced_by: design/gdd/juice-cookbook.md" 在 Cross-References；Phase 5 一并处理 |
| **registry/entities.yaml** | Hard | Cookbook ← registry | 引用：`audio_haptic_sync_window_ms=30`、`audio_lead_ms=35`、`audio_bgm_offset_db=-12dB`、`shred_pulse_interval_s=0.4`、所有 sfx_* 与 haptic_* 常量名 | Phase 5 在 registry 注册 Cookbook 派生公式 F-1/F-5/F-7 + Cookbook 配方 ID JC-R1..R7 |

### Downstream（被 Cookbook 约束的系统）

| System | Type | 引用强度 | Cookbook 提供的契约 | bidirectional 义务 |
|---|---|---|---|---|
| **Lever Interaction System** (#8, Not Started) | Hard | 硬引用 | JC-R1 + JC-R2 配方；Lever 状态机必须 gate hook signal 重叠（Edge Case 第 3 类） | Lever GDD 的 Tuning Knobs 必须显式 cite `JC-R1` / `JC-R2`；code review BLOCKING |
| **Shred Process System** (#9, Not Started) | Hard | 硬引用 | JC-R3 + JC-R4 配方；`n_pulses` 上下限；`first_pulse_offset ≥ 300 ms` | Shred GDD Tuning Knobs cite `JC-R3` / `JC-R4`；首次脉冲 offset 与 haptic-system.md F-2 一致 |
| **Silhouette Reveal System** (#11, Not Started) | Hard | 硬引用 | JC-R5 + JC-R6 配方；JC-R5 的振幅是 Cookbook 最高（s_overshoot=1.2） | Silhouette GDD Tuning Knobs cite `JC-R5` / `JC-R6` |
| **Shelf Collection System** (#12, Not Started) | Hard | 硬引用 | JC-R7 配方；anti-completionism Forbidden（无金粉/烟火） | Shelf GDD Tuning Knobs cite `JC-R7`；视觉无任何成就感信号 |
| **Mochi Character System** (#6, Not Started) | Soft | 软引用 | Cookbook 不提供 mochi_blink 配方；提供 CTL 词汇表作为可选词典 | Mochi GDD 自定义角色动画；如使用 squash/screen shake 等术语必须遵循 CTL 锁定列表 |
| **Onboarding / First-Run System** (#15, Not Started) | Hard | 硬引用 + **两处受控偏离 (R12)** | 全套 JC-R1-R7；两处允许偏离：(a) 首产物 reveal 时 JC-R5 medium→large（s_overshoot 1.2→1.25 上限）；(b) 前 3 次 shelf_add JC-R7 → **enhanced 变体**（anticipation 4→6 px / 弹跳 ±3→±4 px / 落地音 +2 dB / 1 帧暖白 +20% flash），第 4 次起回归标准 JC-R7 | Onboarding GDD 必须显式声明两处偏离 + `first_run_shelf_add_count` 持久化计数；Reduce Motion 优先级 > 两处偏离（Edge Case） |
| **Accessibility System** (#16, Not Started, v1.0) | Hard | 反向控制 | Cookbook 提供 F-6 reduce_motion_factor 接口；Accessibility 定义阈值映射与 particle 禁用规则 | Accessibility GDD 拥有 `reduce_motion_factor` 三档定义权；Cookbook 不预设阈值 |

### 不依赖的系统（显式排除）

| System | 为什么不在依赖列表 |
|---|---|
| **Persistence System** (#1) | Cookbook 是文档无运行时状态，不需要持久化任何东西。`settings.haptic_enabled` 由 HapticSystem 拥有，Cookbook 不直接读 |
| **Input System** (#2) | Cookbook 不订阅 touch events；hook signal 由下游 gameplay GDD 转发 |
| **Mobile App Lifecycle** (#5) | **明确禁止订阅**（Core Rule 4 + ADR-0002 反支柱守护）；前后台中断由 Edge Case 处置规则而非主动订阅 |
| **Product System** (#10) | Cookbook 不知道产物种类/稀有度；产物的视觉揭晓 (JC-R5/R6) 由 Silhouette Reveal GDD 调用 |
| **Text Input System** (#7) | Cookbook 不知道输入内容；Pillar 4 重内容不改变 JC-R6 振幅（Edge Case 反 attention-manipulation 规则）|
| **Scene Composition / Navigation** (#14) | Cookbook 不参与场景切换 juice；场景过渡若有动画由 Scene Composition GDD 自己定义 |

### Interface 接口契约总览

Cookbook 的依赖关系全部走 **单向调用 + registry 常量** 两种通道，**不订阅任何信号**：

```
[Cookbook 配方实现代码 (在下游 GDD 的 .gd 中)]
  ├─ 调用→ AudioSystem.play(sfx_key)            (registry sfx_* keys)
  ├─ await timer(audio_lead_ms / 1000.0)        (registry constant 35 ms)
  ├─ 调用→ Haptic.play(haptic_key)              (registry haptic_* keys)
  └─ 启动→ 视觉 Tween / CPUParticles2D / Camera2D.offset  (Godot API)
```

无回调，无信号订阅，无运行时单例。

### bidirectional 一致性义务清单（Phase 5 检查项）

1. **Audio System GDD** Cross-References 段加 "Referenced by: design/gdd/juice-cookbook.md"
2. **Haptic System GDD** Cross-References 段加 "Referenced by: design/gdd/juice-cookbook.md"
3. **registry/entities.yaml** 注册 Cookbook 派生公式 F-1 / F-5 / F-7 与配方 ID JC-R1..R7（如适用）；现有 `audio_lead_ms` / `audio_haptic_sync_window_ms` 等 const 的 referenced_by 列追加 `design/gdd/juice-cookbook.md`
4. **systems-index.md** 移除 Juice Cookbook 行末的 "(type: cookbook, not GDD)" 与 "NOT a full GDD" 注释（升级决策已落地）；状态 Not Started → Designed
5. **`consistency-failures.md`** 若 Phase 5 跑 `/consistency-check` 时发现 bidirectional 漏洞，按 4 条已记录格式追加一行

## Tuning Knobs

### 归属说明（重要）

Cookbook tuning knobs 分两类：
- **Range-locked knobs**：Cookbook 规定范围与单位，**具体值由下游 GDD 决定** 并在其 Tuning Knobs cite。下游可在 Cookbook 范围内自由调整。
- **Cookbook-locked invariants**：Cookbook 直接锁定值，下游 GDD **不允许覆盖**。变更需走 ADR amend。

### Range-locked knobs（下游设值，Cookbook 限边界）

| Knob | 单位 | Cookbook 范围 | 下游 GDD 设值时的注意 | 过高 → | 过低 → |
|---|---|---|---|---|---|
| `s_compressed` (F-3) | scalar | [0.5, 0.95] | 下限 0.5 是 Pillar 4 Cute But Weighted 防"塌"；JC-R6 通常用 0.92 不靠近下限 | 接近 0.95 → squash 几乎不可见，"寡淡"复发 | 低于 0.5 → 视觉上像"压碎了"，违反 cozy 基调 |
| `s_overshoot` (F-3) | scalar | [1.0, 1.25] | 上限 1.25 是 Pillar 4 防"橡皮泥"；JC-R5 用 1.2 接近上限 | 接近 1.25 → 卡通过度、失去机器质感 | 接近 1.0 → 失去弹性感、变平 |
| `T1` / `T3` (F-3 timing) | ms | [16, 100] | 1-6 帧 @ 60 FPS 范围；Anticipation/Follow-through 单独 phase | > 100 ms → Anticipation 拖沓，玩家感觉"机器卡了" | < 16 ms → 不足 1 帧、Tween 内插失败 |
| `T2` (F-3 stretch phase) | ms | [0, 100]（0=跳过 overshoot） | JC-R6 用 0 跳过 | > 100 ms → 拉伸太久、违反节奏感 | 同上 |
| `base_amp_px` (F-2 shake) | px | [0, 8] | JC-R2 用 4，JC-R7 用 2；上限 8 是 Pillar 4 约束 | > 8 → Vlambeer 暴力感，违反 cozy | 0 → 等价于关闭 shake，需用 F-6 reduce_motion=0 |
| `HOLD_MS` (F-2) | ms | [0, 60] | JC-R2 用 40，JC-R7 用 20 | > 60 → 全幅持续太久 | 0 → 直接进入衰减，"短促敲打"感 |
| `DECAY_MS` (F-2) | ms | [40, 200] | JC-R2 用 80，JC-R7 用 60 | > 200 → 衰减过缓、画面长时间不稳 | < 40 → 太突兀 |
| `n_pulses` (F-5 JC-R4) | int | [3, 5] | Shred Process GDD 选 | > 5 → Pillar 5 "粉碎太久挤压玩家时间" | < 3 → 节奏感不足，玩家以为 bug |
| `JC-R3 burst_count` (F-4) | int | [8, 12] | Shred Process GDD 选 | > 12 → 接近 F-4 上限、与 JC-R4 重叠风险 | < 8 → 视觉空，"机器没东西在动" |
| `JC-R3 lifetime_ms` (F-4) | ms | [400, 800] | 600 是默认 | > 800 → 占据下个 hook 帧预算 | < 400 → 粒子来不及看清 |
| `anticipation_ratio` (F-7) | scalar | [0.05, 0.15] | 默认 0.1 | > 0.15 → 过度蓄力像"卡了" | < 0.05 → 蓄力不可见 |

### Cookbook-locked invariants（下游不得覆盖）

| Invariant | 锁定值 | 锁定原因 |
|---|---|---|
| `audio_lead_ms` | **35 ms** (registry-locked from haptic-system.md) | 三方同步契约，跨 5+ 系统共用 |
| `audio_haptic_sync_window_ms` | **30 ms** (registry-locked) | Spence 2007 + Apple HIG 人类听觉同步阈值 |
| Silence ≥ 100 ms (Core Rule 5) | **100 ms** | 配方间物理隔离，节奏感保证 |
| F-4 active_particles_total 上限 | **48** | Mobile renderer iOS 安全上限 |
| F-5 total_juice_ms 上限 | **1500 ms** | anti-bloat 平衡值；超出挤压玩家呼吸 |
| CTL 词汇表 8 个术语 | **anticipation / squash & stretch / follow-through / screen shake / time-scaling / color flash / particles / layered audio** | Cookbook 共同语言；新增术语走 ADR |
| 配方 ID 命名 `JC-R1..R7` | 锁定 | 下游 cite 锚点稳定性 |
| Hook signal 顺序优先级（Edge Case） | `lever_lock > reveal_pop > shred_start > shred_pulse > product_land > shelf_add > lever_pull_start` | 同帧冲突时混音抢占 |
| Pillar 4 重内容 → JC-R6 振幅 | **不变**（不分支） | 反 attention-manipulation 设计 |
| F-6 reduce_motion_factor 作用域 | **只振幅，不时长** | Apple HIG 一致 |
| Cookbook 不订阅 Lifecycle 信号 | 锁定（Core Rule 4） | ADR-0002 反支柱结构守护 |

### 全局开关（Accessibility GDD 拥有）

| Toggle | 类型 | 默认 | 谁拥有 |
|---|---|---|---|
| `reduce_motion_factor` | enum {0.0, 0.5, 1.0} | 1.0 (off) | Accessibility System GDD (#16) |
| `disable_all_particles` | bool | false | Accessibility System GDD (#16) |
| `mute_haptic`（settings.haptic_enabled inversed） | bool | false | HapticSystem (settings slice owner) |

Cookbook 在运行时通过 F-6 公式响应这些 toggle，但 **不主动检测它们**——降级由调用方（下游 GDD 或 Accessibility System）在每次配方触发前传入 `reduce_motion_factor` 参数。

### Knob 间相互作用

- `s_overshoot` × `T2` 互锁：T2=0 时 s_overshoot 无效（F-3 降级）。不要单独调一个不调另一个。
- `JC-R4.n_pulses` × `JC-R3 lifetime_ms` 总和：合并影响 F-4 表，n_pulses=5 + lifetime=600 不超 F-4，但 v1.5+ 若加新粒子源需重算。
- `base_amp_px` × `reduce_motion_factor`：F-6 应用后实际 shake 幅度 = base × factor，downstream GDD 调 base 时应假设 factor=1.0。

## Visual/Audio Requirements

> 本节是 Cookbook 七条配方（JC-R1-R7）的**视觉与音频边界合同**。它不定义机器外观或产物造型（那是 Art Bible 职权），只锁定 juice 时刻允许和禁止的视觉/音频参数。下游 GDD 实现者与 reviewer 以本节为判定基准。
>
> 注：Mochi 项目 `/art-bible` 尚未启动；本节是 Art Bible 的种子预约束，VA-7 列出未来 Art Bible 需引用的章节。

### VA-1：Color Flash 颜色边界

| 使用场合 | 允许颜色 | 禁止颜色 | 原因 |
|---|---|---|---|
| JC-R3 `shred_start`（腔体内亮度变化） | 白 / 暖白（色温 3000–5500 K 等价）仅亮度通道 +40% → +15%；**不改变色相** | 金色、金粉色、任何高饱和彩色（S > 50%）| 金色专属稀有揭晓信号；此处混入则稀有时刻失去识别度 |
| JC-R5 `reveal_pop`（1 帧 color flash） | 亮黄白（HSB: H≈50°, S≈20-30%, B=100%）或纯白（S=0）| 金粉色（S>60%, 带 metallic shimmer）、红色、青色等高饱和纯色 | 1 帧 flash 的语义是"惊喜感"，不是稀有感；金粉是 v1.0 rare reveal 专属视觉语言，MVP 阶段严禁触碰 |
| v1.0 稀有揭晓 JC-R5（large 变体） | 金粉色（HSB: H≈40°, S=70-80%, B=90%）+ `CPUParticles2D` shimmer 颗粒 | 所有其他配方——包括 MVP 阶段 JC-R5 的普通版 | **稀有揭晓是全游戏唯一一次使用金粉+闪光颗粒的时刻**；Art Bible 正式起草前，此项作为种子约束预占 |
| JC-R2、JC-R6、JC-R7（所有其余配方） | 无 color flash；调色限 `modulate` 亮度/饱和度通道，不引入新色相 | 任何色相变化 | screen shake 和 squash 已承担该时刻的视觉重量，色彩介入会破坏层次感 |

**全局颜色禁区（Juice 层）**：背景乳白/牛奶白（`#F5F0E8` 近似）在任何 juice 时刻**不得被 color flash 染色**——背景是视觉留白契约，任何颜色进入背景等于破坏 Cozy Mechanical 视觉锚点的负空间原则。

### VA-2：Particle 形态约束

**碎屑几何形态**：`CPUParticles2D` 碎屑粒子采用**矩形小片（2-4 px 短边，4-8 px 长边）**，带 ±15° 随机旋转，非圆形、非星形、非手绘风有机形。理由：矩形碎片对应"纸张被碎纸机切割"的工业语义，与机器的扭蛋机/办公设备质感一致。

**碎屑颜色来源**：颜色从**机器主色色板**（奶油/黄绿/浅原色）随机抽取一种，不使用当前产物颜色——产物颜色只在 JC-R5/R6 揭晓时出现。这样确保粉碎过程视觉与产物揭晓视觉有明确色彩分界。

**飞散范围**：所有碎屑粒子的运动向量必须**收敛于机器腔体边界内**（lifetime 内不超出机器 sprite 的 bounding box）。JC-R4 脉冲追加的粒子方向偏腔体底部，形成"碎屑积累下落"的重力暗示。

**稀有揭晓 shimmer 颗粒**（v1.0 JC-R5 large）：颗粒形状切换为**圆形小点（2-3 px 直径）**，颜色固定为金粉色系，从出口位置向外扩散——这是全游戏唯一一次粒子逃出机器边界的时刻，视觉上强调"突破"感。

### VA-3：机器表情在 Juice 时刻的克制约束

机器 Mochi 在 juice 时刻遵循 **"工匠专注"**原则：表情变化是状态切换，不是情感表演。具体约束：

| Juice 时刻 | 允许的表情变化 | 禁止的表情 | 原因 |
|---|---|---|---|
| `lever_lock`（JC-R2）| 眉毛轻压（"在用力"）；眼睛微眯 | 惊讶大眼、龇牙、笑容 | 摇杆锁住是"重活"，机器是工匠在出力，不是在表演 |
| `reveal_pop`（JC-R5）| 眼睛轻展（"好奇"或"看一眼结果"）；眉毛微扬一帧 | 夸张大眼配合产物弹出、烟花表情 | 剧场感来自 squash 动画，不依赖表情放大。机器应该像"看过一百次的熟练工匠"，不像第一次见到产物 |
| `shred_start`/`shred_pulse`（JC-R3/R4）| 无新表情变化，维持 JC-R2 进入时的专注表情 | 任何在粉碎过程中增加新表情帧 | 粉碎是机器的工作状态，专注即是表情 |
| `product_land`（JC-R6）| 表情可回归轻微满足（嘴角微上、眼睛回到正常）| 庆祝感、竖大拇指、开心跳动 | Pillar 4：重内容玩家需要看到"工匠靠谱完成了工作"，不是"工匠在为你庆祝" |

**Cookbook 与 Mochi Character System（#6）的边界**：表情具体帧数、眉毛曲线形状、眼睛大小由 Mochi Character GDD 定义——Cookbook 只约束**哪类情感语义允许/禁止在哪个 juice 时刻出现**。

### VA-4：金粉色 + 闪光颗粒的使用边界

**MVP 阶段**：金粉色与闪光颗粒**完全禁用**。MVP 的 JC-R5 `reveal_pop` 使用亮黄白 1 帧 color flash，不使用金粉系。

**v1.0+ 稀有揭晓**：金粉色与 shimmer 颗粒仅在**稀有产物揭晓（5% 概率档）的 JC-R5 large 变体**中启用。这是全游戏仅有的一次金粉使用场合，其他任何系统（Shelf Collection、Onboarding、UI 按钮高亮）均不得复用。

**设计理由**：金粉色的稀缺性是其意义的来源。一旦在 Shelf Add 动画或常规 UI 中出现，稀有揭晓时刻就失去了"唯一性"，Pillar 3（收藏不焦虑）的情感承诺随之失效。

### VA-5：Audio Palette 四轨边界

Cookbook 七条配方使用四种音色轨道，边界如下：

| 音轨 | 频率特征 | 音色风格 | 配方归属 | 禁止混入 |
|---|---|---|---|---|
| **机械低频（Mechanical Bass）** | 20–120 Hz，sub-bass + 低中频 | 厚重、工业、有体积感；参考：老式碎纸机启动声、厚钢板弹击 | JC-R2 sub-bass thump、JC-R3 齿轮启动低频 | 不允许有旋律感、不允许混响尾过长（>200 ms reverb tail 破坏"金属直击感"）|
| **机械高频（Metal Strike）** | 2 kHz–8 kHz，金属碰撞 transient + 快速衰减 | 清脆、短促、有实体感；参考：钥匙串碰撞、铁制工具箱扣锁 | JC-R2 金属碰撞中高频 | 不允许谐波过多（防止"铃声感"）；decay 必须 < 300 ms，否则变成"叮"而不是"咔" |
| **材料质感（Material Texture）** | 200 Hz–4 kHz，中频宽带 | 纸张/布料/木头的有机质感；非工业感 | JC-R3 纸张撕裂高频、JC-R7 木头/布料落地音 | 纸张轨禁止金属感混入；JC-R7 落地音必须柔和——**明确禁止任何金属碰撞感**（理由：货架是温暖的家，不是机器内部）|
| **完成音调（Resolution Tone）** | 400 Hz–1.5 kHz，短促和声 | 温暖、满足、不华丽；参考：木琴单音、钢琴软踏板单音 | JC-R6 "完成"音调 | 禁止多音和弦（防止"达成成就"感，违反 Pillar 3）；禁止混响拖尾 > 500 ms |

**JC-R2 两轨叠加的具体约束**：sub-bass thump（20–80 Hz 主体，decay 50 ms）与金属高频（3–6 kHz transient，decay 150 ms）的 onset 必须**同帧发射**，共同构成"撞上了"的立体物理感。两轨 pan 均居中；sub-bass 电平比高频低 6 dB（防止低频在手机小喇叭上糊掉高频 transient）。

**JC-R3 两轨 onset 错开**：齿轮启动低频先行，纸张撕裂高频延后 30 ms——模拟"机器先转动，然后开始咬入材料"的因果顺序。

### VA-6：BGM Ducking 与 SFX 层级关系

`audio_bgm_offset_db = -12 dB` 是 BGM 相对 SFX master 的**常态偏移**，意味着 BGM 在整个游戏会话中始终比 SFX 安静 12 dB。

**Juice 高潮时是否 duck BGM**：Cookbook 配方**不触发额外 ducking**。`audio_bgm_offset_db = -12 dB` 已提供足够的 headroom 使 JC-R2（lever_lock sub-bass thump）和 JC-R5（reveal_pop color flash 对应音效）在 SFX 层清晰可闻。如果实机测试发现 BGM 与 JC-R2 sub-bass 在手机喇叭上产生频率遮蔽，处置方案是在 Audio System GDD 增加 BGM EQ sidechain（砍 BGM 60-120 Hz），而不是在 Cookbook 层增加 duck 规则——这是 Audio System 的职权边界。

**Silence 尾（≥ 100 ms）期间的 BGM**：BGM 保持不变，不做淡入补偿。静默尾的静默感来自 SFX 轨的无声，不是 BGM 抬量。

### VA-7：Art Bible 种子预测

由于 `/art-bible` 尚未启动，Cookbook 已为以下章节预占约束内容：

**预测 Art Bible Section：Motion Principles（运动原则）**
Cookbook 锁定内容：squash 下限 0.5 / overshoot 上限 1.25（Pillar 4 防"橡皮泥"约束）；5 相位结构（Anticipation → Silence）；所有 juice 动画必须在 60 FPS 下可读（最短单相 1 帧）。Art Bible 在此节需引用 `JC-R1-R7` 作为运动强度基准案例。

**预测 Art Bible Section：Color Language（色彩语言）**
Cookbook 锁定内容：金粉色专属稀有揭晓语义（VA-1/VA-4）；背景乳白不可被 juice 染色（VA-1 全局禁区）；碎屑颜色来源机器色板而非产物色板（VA-2）。Art Bible 在此节需给出机器色板的具体 HSB 值，并注明"Cookbook 配方中的颜色使用必须与本节色板一致"。

**预测 Art Bible Section：Sound Identity（音响身份）**
Cookbook 锁定内容：四轨 audio palette 边界（VA-5）；金属感与有机质感的场合分割（机器内部 = 金属/机械；货架/产物 = 木头/布料/完成音调）；完成音调禁止多音和弦。Art Bible 在此节需引用 VA-5 表作为音色方向的执行约束，并为每轨提供 1-2 个具体参考音效文件或类比描述。

---

> **📌 Asset Spec** — Visual/Audio requirements 已就位。`/art-bible` 起草并 approve 后，运行 `/asset-spec system:juice-cookbook` 生成 per-asset 视觉描述、尺寸、AI 生成 prompt（粒子贴图、color flash 颜色样本、音效 reference 文件等）。

## UI Requirements

Cookbook **自身无 UI 表面**——它没有按钮、菜单、HUD 元素。下游配方的视觉效果"出现在"哪个 UI 层由各下游 GDD 决定。

### Cookbook 与 UI 系统的边界

- **Reduce Motion toggle UI** 归 Accessibility System GDD (#16) v1.0 设计；Cookbook 提供 `reduce_motion_factor` 入参接口（F-6），不规定 toggle 的 UI 形态
- **Haptic toggle UI** 归 Settings 页（v1.0）；Settings 页 GDD 尚未列入 systems-index，应在 v1.0 阶段补
- **配方效果出现的 z-order**：JC-R1..R4 配方效果在机器 sprite 同 z 层或之上；JC-R5/R6 在产物 sprite 同 z 层；JC-R7 在货架 sprite 同 z 层。screen shake 影响整个 Camera2D，不分层。这些 z-order 约束由 Scene Composition GDD (#14) 与下游 gameplay GDD 共同定义，Cookbook 不预设。
- **Cookbook 的视觉效果不参与 UI accessibility focus 流转**——它们是装饰性的，不接收焦点（v1.0 Accessibility GDD 起草时确认无障碍 focus ring 不被 juice modulate 干扰）

### 无 UI 设计 flag

本系统不触发 `/ux-design` 工作流——无需为 Cookbook 写 UX spec。

## Acceptance Criteria

每条 AC 标注：执行路径 · Gate Level · 引用来源。

---

### AC-01a：同步契约验证 — 扬声器路径（F-1，B3 拆分）

**GIVEN** iOS 真机使用 **内置扬声器** 输出，下游 GDD 实现代码调用 `AudioSystem.play(sfx_key)` 并记录 t_emit（混音器调度时刻），
**WHEN** 视觉 Impact 相位 **T1 压缩关键帧** 渲染时刻 `t_render` 被测量，
**THEN** `|t_render - (t_emit + 35)| ≤ 15 ms` 对 JC-R1 至 JC-R7 所有配方均成立。

- **执行路径**：Manual real-device test（iOS 真机内置扬声器 + Xcode Instruments 帧时间戳 + Godot `AudioServer.get_time_to_next_mix()` 推算 t_emit；simulator 不可替代）
- **Gate Level**：**BLOCKING**
- **来源**：F-1 · Core Rule 3 · States and Transitions "Impact = T1 压缩帧"
- **备注**：本 AC 锚定 t_emit（不是 t_perceive）；t_emit → 扬声器输出的 12-22 ms 路径延迟由 `platform_audio_output_latency_ms` 表覆盖

---

### AC-01b：同步契约验证 — Bluetooth 路径（F-1，ADVISORY）

**GIVEN** iOS 真机使用 **AirPods Classic 或 AOSP BT 经典** 输出，
**WHEN** 视觉 T1 压缩关键帧渲染时刻 `t_render` 与 t_emit 比较，
**THEN** `|t_render - (t_emit + 35)| ≤ 15 ms` 仍成立（Cookbook 锚定 t_emit 而非 t_perceive；BT 路径下 t_perceive 漂移 35-65 ms 走 platform table），但 **玩家主观感知"声音迟到"是预期**——视觉看起来"先于声音"。

- **执行路径**：Manual real-device test（戴 AirPods 真机跑核心循环，主观打分）
- **Gate Level**：**ADVISORY**
- **来源**：F-1 · `platform_audio_output_latency_ms` 表 · AC-01a 互补
- **处置**：若 BT 路径下主观偏差不可接受，Audio System v1.0 增 BT 检测后整体 `audio_lead_ms +20 ms` 补偿；本 AC 不阻塞 MVP 发布

---

### AC-02：七配方四相位完整性（JC-R1 至 JC-R7）

**GIVEN** 每条配方对应的 hook signal 被 emit，
**WHEN** QA tester 在 Godot 编辑器调试场景中逐一触发 `lever_pull_start / lever_lock / shred_start / shred_pulse / reveal_pop / product_land / shelf_add`，
**THEN** 每条配方均依序经历 Anticipation → Action → Impact → Follow-through → Silence 五阶段，任何一相均不跳过、不乱序，且 Silence 尾 ≥ 100 ms（可通过动画帧计数验证）。

- **执行路径**：Manual real-device test（真机逐配方触发）+ Code review check（实现代码确认五相位 Tween 链完整）
- **Gate Level**：BLOCKING
- **来源**：Core Rule 5 · States and Transitions 表 · Section C 七配方表

---

### AC-03：Squash & Stretch 振幅在 Cookbook 范围内（F-3）

**GIVEN** 实现代码按配方设定 squash/stretch Tween，
**WHEN** QA tester 在 Godot 调试场景中读取每配方的 `scale` 峰值与谷值，
**THEN** 对所有配方：`s_compressed ∈ [0.5, 0.95]`，`s_overshoot ∈ [1.0, 1.25]`，`T1 ∈ [16, 100] ms`，`T2 ∈ [0, 100] ms`，`T3 ∈ [16, 100] ms`。JC-R6 的 `T2 = 0`（无 overshoot 路径），验证 `s_overshoot` 不生效。

- **执行路径**：Automated unit test（GUT 断言配方常量值在范围内）+ Code review check（Tween 参数）
- **Gate Level**：BLOCKING
- **来源**：F-3 · Tuning Knobs "Range-locked knobs" 表

---

### AC-04：Screen Shake 幅度在 Cookbook 范围内（F-2）

**GIVEN** JC-R2 和 JC-R7 被触发，
**WHEN** QA tester 读取 `Camera2D.offset` 的每帧峰值，
**THEN** `|Camera2D.offset| ≤ 8 px`（F-2 `base_amp_px` 上限），JC-R2 `base_amp_px = 4 px / HOLD_MS = 40 ms / DECAY_MS = 80 ms`，JC-R7 `base_amp_px = 2 px / HOLD_MS = 20 ms / DECAY_MS = 60 ms`，衰减函数在 t ≥ HOLD + DECAY 时 offset 归零。

- **执行路径**：Automated unit test（GUT 验证衰减公式输出值范围）+ Code review check（Camera2D.offset 赋值逻辑）
- **Gate Level**：BLOCKING
- **来源**：F-2 · Tuning Knobs `base_amp_px / HOLD_MS / DECAY_MS` 条目

---

### AC-05：跨配方粒子同帧上限（F-4）

**GIVEN** MVP 最坏场景：JC-R3（burst 12 颗）与 JC-R4（2 批重叠 = 8 颗）同帧活跃，
**WHEN** QA tester 在 Godot 调试场景中同时触发 `shred_start` + `shred_pulse`，读取 `CPUParticles2D` 活跃粒子数，
**THEN** 任意单帧 `active_particles_total ≤ 48`；MVP 路径 ≤ 20，v1.0 含 JC-R5 rare（+16）≤ 36。

- **执行路径**：Automated unit test（GUT mock particle count 在极端场景下验证 F-4 公式不越限）+ Manual real-device test（iPhone 真机 Profiler 确认无粒子池溢出）
- **Gate Level**：BLOCKING
- **来源**：F-4 · Cookbook-locked invariant "active_particles_total ≤ 48"

---

### AC-06：单循环 Juice 总时长上限（F-5）

**GIVEN** 完整一次核心循环（JC-R1 → R2 → R3 → R4×5 → R5 → R6 → R7）被触发，
**WHEN** QA tester 或自动化测试累加各配方主体时长，
**THEN** `total_juice_ms ≤ 1500 ms`；default 参数下计算结果 = 1260 ms ≤ 1500 ms。Silence 尾（≥ 100 ms × 7）不计入。

- **执行路径**：Automated unit test（GUT 用配方常量代入 F-5 公式断言结果 ≤ 1500）
- **Gate Level**：BLOCKING
- **来源**：F-5 · Cookbook-locked invariant "F-5 total_juice_ms ≤ 1500 ms"

---

### AC-07：Reduce Motion factor=0.5 振幅减半（F-6）

**GIVEN** 设备 Accessibility 设置 `reduce_motion_factor = 0.5`，JC-R5 (`reveal_pop`) 被触发，
**WHEN** QA tester 在 iOS 真机测量 squash/stretch 的实际 scale 峰谷值，
**THEN** `effective_s_compressed = 1.0 - (1.0 - 0.6) × 0.5 = 0.8`（非 0.6），`effective_s_overshoot = 1.0 + (1.2 - 1.0) × 0.5 = 1.1`（非 1.2）；Tween 时长 T1/T2/T3 **不变**（F-6 只改振幅不改时长）。

- **执行路径**：Automated unit test（GUT 验证 F-6 公式输出值）+ Manual real-device test（目测幅度明显缩小但动画节奏不变）
- **Gate Level**：BLOCKING
- **来源**：F-6 · Edge Case "Reduce Motion = 0.5 时 JC-R5"

---

### AC-08：Reduce Motion factor=0.0 时振幅归零但音频触觉正常（F-6 + Core Rule 3）

**GIVEN** `reduce_motion_factor = 0.0`，JC-R2 (`lever_lock`) 被触发，
**WHEN** QA tester 在真机观察视觉反馈，
**THEN** `Camera2D.offset = 0`（无 shake），scale Tween 恒为 1.0（无 squash），但 Audio sfx 和 Haptic 仍正常发射；玩家感知到声音和触觉，无视觉运动。

- **执行路径**：Manual real-device test（iOS 真机开 Reduce Motion，真机触发 lever_lock）
- **Gate Level**：ADVISORY
- **来源**：F-6 · Edge Case "Reduce Motion = 0.0 时 JC-R2" · Apple HIG "reduce motion 关动作不关反馈"

---

### AC-09：App 后台回前台后视觉不重播（Lifecycle 中断 Edge Case）

**GIVEN** JC-R5 (`reveal_pop`) Tween 动画进行中（约 200-260 ms 窗口内），
**WHEN** 玩家按 Home 键将 app 转入后台，等待 ≥ 2 秒后回前台，
**THEN** 剩余动画从暂停帧继续播放至结束（不重置到第 0 帧，不重播整条配方），下一次新 hook signal 触发前 Audio/Haptic 不补发。

- **执行路径**：Manual real-device test（iOS 真机 Home 键测试）
- **Gate Level**：ADVISORY
- **来源**：Edge Case "Lifecycle 中断类 - app 从后台回前台" · Core Rule 4

---

### AC-10：Hook Signal 重叠时下游状态机正确 Gate（抢占 Edge Case）

**GIVEN** JC-R5 (`reveal_pop`) Silence 尾尚未结束（< 100 ms），
**WHEN** Lever Interaction GDD 状态机收到新的 `lever_pull_start` 信号，
**THEN** 状态机保持当前状态（REVEAL_DONE 前不允许进入 PULLING），新 hook signal **不触发** JC-R2；Lever Interaction GDD 的状态机 gate 逻辑在 godot-gdscript-specialist code review 时可验证（状态转换条件显式检查 REVEAL_DONE）。

- **执行路径**：Code review check（Lever GDD 实现代码状态机条件检查）+ Manual real-device test（快速连续拉杆验证无视觉叠加混乱）
- **Gate Level**：BLOCKING
- **来源**：Edge Case "Hook signal 重叠/抢占类" · Core Rule 5 Silence

---

### AC-11：每条配方 Forbidden 项不出现（JC-R1 至 JC-R7）

**GIVEN** 下游 GDD 实现代码提交 code review，
**WHEN** godot-gdscript-specialist 审查实现文件，
**THEN** 以下 Forbidden 项均不出现：
- JC-R1：无 `squash` scale Tween、无 `Camera2D.offset` 写入、无 `AnimationPlayer` 播放单次 scale
- JC-R2：无 `modulate` 颜色闪变、无 `Engine.time_scale = 0.0`、无 `GPUParticles2D` 粒子数 > 24
- JC-R3：无金色/高饱和彩色 modulate、无 `Environment` Glow 节点（条件式 Mobile renderer 下）、无 `CPUParticles2D.amount > 12`（按 F-4 表 SSOT；之前的 ">48" 是与全局上限混淆）
- JC-R4：无 `Camera2D.offset` 写入、无 `ShaderMaterial` 参数每帧写入、无粒子 burst（只追加）
- JC-R5：无 `Camera2D.offset` 写入、无 `Engine.time_scale`
- JC-R6：无夸张 squash（s_compressed < 0.85）或粒子庆典、无多 pass blend_add shader（条件式 Mobile renderer 下；Forward+ 路径待 ADR-R 决议）
- JC-R7：无金粉/光晕/烟火粒子、无 `Path2D + PathFollow2D` 飞行路径

- **执行路径**：Code review check（逐条 Forbidden checklist，godot-gdscript-specialist 强制执行）
- **Gate Level**：BLOCKING
- **来源**：Section C "每条配方的 Forbidden 子项" · Core Rule 7

---

### AC-12：下游 GDD Tuning Knobs 含 JC-R 引用 ID（合同验证）

**GIVEN** Lever Interaction (#8)、Shred Process (#9)、Silhouette Reveal (#11)、Shelf Collection (#12)、Onboarding (#15) 各自 GDD 完成初稿，
**WHEN** Design review check 审查各 GDD 的 Tuning Knobs 章节，
**THEN** 每份 GDD 在 Tuning Knobs 中明确 cite 其对应配方 ID（Lever cite `JC-R1` + `JC-R2`；Shred cite `JC-R3` + `JC-R4`；Silhouette cite `JC-R5` + `JC-R6`；Shelf cite `JC-R7`；Onboarding cite `JC-R1–R7` 并声明 JC-R5 large 偏离）；Mochi Character (#6) 若使用 CTL 词汇须使用 8 个锁定术语之内的词。

- **执行路径**：Design review check（Wave 3-6 GDD 撰写完成后逐份核查 Tuning Knobs）+ Code review check（godot-gdscript-specialist 在 PR 内确认 cite 存在）
- **Gate Level**：BLOCKING
- **来源**：Section C Core Rule 1 + Core Rule 6 · Dependencies "下游 GDD" 表

---

### AC-13：Pillar 4 重内容场景 JC-R6 振幅不变（反 attention-manipulation，B9 升 BLOCKING）

**GIVEN** Text Input GDD 标记当前输入为 heavy-content 模式（Pillar 4 激活），
**WHEN** 产物落地触发 `product_land` → JC-R6，
**THEN**：
1. `s_compressed = 0.92`、`s_overshoot = 1.0`、无额外粒子、无额外色彩变化——与非 heavy-content 场景 **完全相同**
2. 代码中无任何 Pillar 4 / heavy_content 条件分支改变 JC-R6 参数（grep 静态扫描验证）
3. **GUT injection test**：构造测试 mock `Lever.is_heavy_content = true` 与 `false` 两种状态，触发 JC-R6 Tween，断言 `Tween.tween_property("scale", ...)` 的 final value 在两种状态下 **完全相等**（断言精度 0.0001）

- **执行路径**：
  - **Automated unit test (GUT)**：injection mock heavy/light content 两态对比断言 `tween.tween_property` 终值一致
  - **CI grep static check**：扫描 JC-R6 实现文件无字符串 `heavy_content` / `heavy_mode` / `is_heavy` 等关键字
  - **Manual real-device test**：输入一段较重内容后观察产物落地动画与正常轻内容场景目测一致
- **Gate Level**：**BLOCKING**（从 ADVISORY 升级 — B9 修订；反 attention-manipulation 是 Mochi 道德立场而非可优化项）
- **来源**：Edge Case "Pillar 冲突类 - 玩家正在写重内容" · Cookbook-locked invariant "Pillar 4 重内容 → JC-R6 振幅不变" · Tuning Knobs JC-R6 Forbidden

---

---

### AC-14：每条配方 Required Minimum 存在性（R11 新增对称约束）

**GIVEN** 下游 GDD 实现代码提交 code review，
**WHEN** godot-gdscript-specialist 审查 JC-R1..R7 每条配方的实现文件，
**THEN** 以下 Required Minimum 项均存在（grep 静态扫描验证）：
- JC-R1：实现文件含 `AudioSystem.play(` 调用（layered audio 不可省）
- JC-R2：实现文件含 squash Tween + `Camera2D.offset` 写入 + audio sub-bass 调用；shake amplitude 常量 ≥ 3 px
- JC-R3：实现文件含 `modulate` brightness Tween + `CPUParticles2D.amount ≥ 8` + 两个 `AudioSystem.play(` 调用（双轨）
- JC-R4：每脉冲触发 ≥ 3 颗新粒子（节点池 amount ≥ 3）+ audio bump 调用
- JC-R5：squash overshoot 常量 ≥ 1.15 + `modulate` 1 帧 flash + 两个 `AudioStreamPlayer2D` 节点（attack + sustained body）
- JC-R6：squash Tween + 两个 `AudioSystem.play(` 调用
- JC-R7：anticipation 反向位移 Tween + Tween 弧线 + follow-through 弹跳（≥ 2 帧）+ `AudioSystem.play(` 落架音

- **执行路径**：Code review check（godot-gdscript-specialist 跑 Required Minimum 存在性 grep；与 AC-11 Forbidden grep 互补对称）+ Design review check（/design-review 每条配方两份清单同时核查）
- **Gate Level**：**BLOCKING**
- **来源**：Section C "Required Minimum" 子项 · Player Fantasy "内在张力（Pillar Tension）" · R11 对称防"寡淡"复发

---

### 覆盖度汇总

| 要求类别 | 覆盖 AC | Gate |
|---|---|---|
| 同步契约 F-1（speaker） | AC-01a | BLOCKING |
| 同步契约 F-1（BT 路径） | AC-01b | ADVISORY |
| 每条配方完整性 (JC-R1..R7) | AC-02 | BLOCKING |
| 公式约束 (F-2/F-3/F-7) | AC-03, AC-04 | BLOCKING |
| 跨配方资源预算 (F-4+F-5) | AC-05, AC-06 | BLOCKING |
| Reduce Motion (F-6) | AC-07, AC-08 | BLOCKING / ADVISORY |
| Lifecycle 中断 | AC-09 | ADVISORY |
| Hook signal 重叠抢占 | AC-10 | BLOCKING |
| Forbidden patterns | AC-11 | BLOCKING |
| 下游 cite 强制 | AC-12 | BLOCKING |
| Pillar 4 反 attention-manipulation | AC-13 | **BLOCKING**（B9 升级） |
| **Required Minimum 存在性 (R11)** | **AC-14** | **BLOCKING** |

共 **15 条 AC**：**11 BLOCKING / 4 ADVISORY**（B9 + R11 + B3 拆分后）。

### QA 执行路径分布

| 执行路径 | 适用 AC |
|---|---|
| Automated unit test (GUT) | AC-03, AC-04, AC-05, AC-06, AC-07 部分, **AC-13 (injection mock)** |
| Manual real-device test | AC-01a, AC-01b, AC-02, AC-07, AC-08, AC-09, AC-10, AC-13 |
| Code review check (grep) | AC-10, AC-11, AC-12, **AC-13 (heavy_content 关键字 grep)**, **AC-14 (Required Minimum grep)** |
| Design review check | AC-12, **AC-14 (两份清单对称核查)** |

## Open Questions

| ID | 问题 | 归属 | 目标解决期 |
|---|---|---|---|
| OQ-1 | `audio_lead_ms = 35 ms` 在真机实测后是否需要调整？目前是 audio_pipeline_latency_ms (40) - haptic_pipeline_latency_ms (5) 的中位数估计；扬声器 vs AirPods 路径会让 audio_pipeline_latency_ms 浮动 25-65 ms。Cookbook F-1 公式与所有下游 Wave 3-6 GDD 的 Tuning Knobs 都依赖此常量。**B12 修订：spike 时机从 Production Sprint 1 提前至 Wave 3 启动前 1-2 天**——否则 Wave 3-6 全部 GDD 建立在估算上，地基松动。 | Owner: technical-director；Source: haptic-system.md F-1 派生 | **Wave 3 启动前 1-2 天 spike**（先于 Lever Interaction GDD 撰写） |
| OQ-2 | Godot 4.6 Mobile renderer 在 iOS 上的 `CPUParticles2D` 实测上限是否真的 ≤ 48 颗？technical-artist 给的数字是估算；F-4 上限锁定基于此。 | Owner: technical-director + godot-specialist | Production Sprint 1（真机性能测试） |
| OQ-3 | Godot 4.6 `get_tree().create_timer(process_always)` 参数签名是否变更？JC-R5 freeze frame 可选实现路径用到。 | Owner: godot-specialist | 写 Lever / Silhouette Reveal GDD 之前 |
| OQ-4 | Godot 4.6 2D `.gdshader` 中 `uniform` texture 声明语法（`sampler2D` vs `texture2D`）是否变更？JC-R6 填色 shader 可能用到。 | Owner: godot-shader-specialist | 写 Silhouette Reveal GDD 之前 |
| OQ-5 | v1.0 稀有揭晓 JC-R5 large 变体是否使用 Godot 4.6 Glow rework？Mobile renderer 不支持 Glow，可能需要 Forward+ fallback 或用 shader self-emission 模拟。 | Owner: technical-director + art-director | v1.0 设计阶段（MVP 不阻塞） |
| OQ-6 | `shred_pulse_interval_s = 0.4 s` 与 Audio System `shred_loop` BGM 的 BPM 是否需要对齐？entities.yaml 中已有同名 Q-3 open question 标记此处需协同。 | Owner: audio-director | 写 Shred Process GDD 之前 |
| OQ-7 | Reduce Motion factor 阈值映射（0.0 / 0.5 / 1.0 三档）的具体触发条件？Accessibility GDD v1.0 设计期决定，Cookbook 不预设。 | Owner: accessibility-specialist | v1.0 Accessibility System GDD 设计期 |
| OQ-8 | Mochi Character GDD (#6) 的 mochi_blink 是否需要走 Cookbook CTL 词汇？目前 Section F 标"软引用"，但实际起草时可能升级为硬引用（如 mochi_blink 需要 squash 或 follow-through 词汇）。 | Owner: game-designer + narrative-director | 写 Mochi Character GDD 时 |
| OQ-9 | 配方 ID `JC-R1..R7` 命名是否在 v1.0+ 新增配方时保持单序号扩展（JC-R8, JC-R9...）还是按 hook signal 域分类（JC-Lever-R1, JC-Shred-R1...）？影响下游 cite 可读性。 | Owner: game-designer | v1.0 设计阶段 |
| OQ-10 | Cookbook 是否要在 `/architecture-decision` 走一个 ADR？目前结构性约束（不订阅 Lifecycle、CTL 词汇锁定等）跨 Core/Foundation 层，按 Wave 1 经验这种跨系统结构性约束应有 ADR 备书。 | Owner: technical-director | Wave 3 启动前 |
