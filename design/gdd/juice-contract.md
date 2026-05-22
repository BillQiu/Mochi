# Juice Contract — Layer 1

> **Status**: Skeleton (2026-05-22) — Pass A re-review verdict MAJOR REVISION NEEDED 后用户采纳 Layer 1/Layer 2 拆分路径；本文件是 Layer 1 起草中
> **Author**: user (Bill Qiu) — 与 Pass A re-review 4 specialists 设计决策对齐
> **Layer 1 范围**: 跨配方不变量 + Required Minimum / Forbidden 对称强制条款 + F-1 同步契约 + F-6 Reduce Motion 接口 + F-7 范围验证器 + 跨配方 AC（全自动化）
> **Layer 2 范围（separate file: juice-recipes.md）**: 7 个配方 JC-R1..R7 完整章节 + F-2/F-3/F-4/F-5 公式 + Visual/Audio Requirements + recipe 级 AC
> **Wave**: 2（Juice Legislation）— gates Wave 3-6 Core gameplay GDDs
> **Type**: 8-section GDD（短而严谨；AC 全部可由 GUT + 精确 grep 验证，不依赖 Wave 3 未存在的类）
> **Sibling**: design/gdd/juice-recipes.md（Layer 2）
> **Predecessor**: design/gdd/juice-cookbook.md（commit ba160fd, 拆分后转 DEPRECATED stub 留 JC-R1..R7 ID 重定向）

## Overview

Juice Contract（Layer 1）是 Mochi 项目"反寡淡"的 **跨配方不变量合同**。它只规定：
(a) 7 个 hook signal 时刻共享的 **同步契约**（视觉/音频/触觉对位窗口）；
(b) 所有配方 **必须遵守的不变量**（Required Minimum / Forbidden 对称约束、Reduce Motion 接口、Pillar 2 戏剧弧线层级、CTL 词汇表锁定）；
(c) 所有配方 **跨配方资源预算上限**（粒子总和、总时长、Hook 抢占优先级）。

Layer 1 **不规定单个配方的具体编排**——某条配方的 squash 关键帧时长、shake 衰减包络、粒子 burst 数量都在 Layer 2（`juice-recipes.md`）的对应 recipe 章节中定义。

Layer 1 的存在原因来自 Pass A re-review 的诊断：原 `juice-cookbook.md` 试图同时承担"跨配方合同"和"单配方手册"两种文档角色，但二者在 **抽象层级 / 验收方式 / 读者画像 / 修改频率** 上都不兼容，导致 5 个 BLOCKING 出现"形式修复但实质未解决"的失败模式。拆分后：**Layer 1 短而严谨**（500-800 行，AC 全部 GUT + 精确 grep 自动化），**Layer 2 可按 recipe 演进**（每 recipe 独立审、独立迭代）。

Layer 1 是 **下游 Wave 3-6 所有 gameplay GDD 的硬合同**：每份 Wave 3-6 GDD 的 Tuning Knobs 必须 cite 对应 Layer 2 recipe ID（`JC-R1..R7`）+ 自动继承 Layer 1 全部不变量约束。godot-gdscript-specialist 在 code review 阶段强制核查 Layer 1 + Layer 2 合规。Layer 1 的修改频率低——任何变更走 ADR amend 流程，因为 Layer 1 改动牵动 Wave 3-6 全部下游。

> **Pass A 教训封装为本层 Core Rule 8（Required Minimum / Forbidden 对称强制）**：
> 任何配方修订必须 **同时** 改 Forbidden（防过度）+ Required Minimum（防不足）+ 影响范围的 AC（防 grep 漏验）+ 输入/输出 ranges（防 formula 内部不一致）。
> 单边修订（"形式修复"）即视为违反 Layer 1 Core Rule。

## Player Fantasy

> **Layer 1 fantasy 是合同性的，不是体验性的**：Layer 2 才描绘玩家在每个 hook 时刻应该感受到什么；Layer 1 只规定"跨配方一致性承诺"——即如果 Layer 2 配方按合同实现，玩家会得到一组什么样的 **可预期的、跨次重复保持一致的体验保证**。

### 三层承诺

Layer 1 对玩家做出 **三层可验证的承诺**：

1. **同步承诺**：每个 hook 时刻的视觉峰值 / 音频 onset / 触觉 strike **永不漂移超过 ±25 ms**（F-1 锁定）。第 100 次拉杆与第 1 次拉杆在同步精度上 **完全一致**。
2. **戏剧弧线承诺 (R4 修复)**：核心循环的情感强度曲线是 *lever_lock（冲撞）→ shred（工作）→ reveal_pop（揭晓高潮）→ product_land + shelf_add（归属收束）*。其中 **reveal_pop 必须是峰值最高的时刻**——`JC-R5 总强度 ≥ JC-R2 总强度 × 1.5`（Core Rule 量化不变量，见 §3）。任何下游 GDD 不得让冲撞感超过揭晓感。
3. **可降级承诺**：所有视觉振幅可由 `reduce_motion_factor ∈ {0.0, 0.5, 1.0}` 全局缩放（F-6）。Reduce Motion = 0 时音频与触觉仍正常发射；前庭功能障碍玩家得到的不是"删除版"而是"等效感官替代版"（同步窗口与戏剧弧线层级不变）。

### Out-of-Scope（修 Pass 2 B16 + game-designer #3）

Layer 1 + Layer 2 **明确只覆盖 7 个 hook signal 时刻**（约 22-30 秒循环中的 ~5-6% 时间，~1260 ms juice 动画 + ~700 ms Silence 尾，跨 ~3.5 秒总 juice 时间窗口）。

**Layer 1 不承诺 94% 的非 hook 时间** 的视觉/音频反馈。具体不在合同范围的时间段：

| 时间段 | 谁负责 | 引用 GDD |
|---|---|---|
| Idle（机器静止等待玩家输入）| Mochi Character System (#6) | design/gdd/mochi-character.md（Not Started）|
| Drag（玩家按住拉杆但未达 trigger 阈值）| Lever Interaction System (#8) | design/gdd/lever-interaction.md（Not Started）|
| Pulse 间隔（JC-R4 各脉冲之间 400 ms × 4 = 1600 ms）| Shred Process System (#9) — 决定是否填空或刻意静默 | design/gdd/shred-process.md（Not Started）|
| Hover / 等待确认 | Scene Composition / Navigation (#15) | design/gdd/scene-composition.md（Not Started）|
| 冷启动 / app resume / IME 弹起 | Mobile App Lifecycle (#5, Reviewed) + 各自 GDD | design/gdd/mobile-app-lifecycle.md（已 Reviewed）|

**Wave 3 启动前置依赖**：上表中标 "Not Started" 的 GDD 必须在 Wave 3 期间完成各自反馈承诺；Layer 1 不负责协调，但 systems-index 与 `/consistency-check` 强制跨 GDD bidirectional 引用。**Cookbook（Layer 1+2）单独无法兑现 §B 整 10 秒"反射动作"承诺**——这是结构性事实，不是缺陷。

### Pillar Tension（继承 Pass A R11，简化版）

Layer 1 同时背负两个相反承诺：

- **承诺 A（防过度）**：Pillar 4 *Cute But Weighted* 约束 squash ≤ 1.25 / shake ≤ 8 px / 总 juice ≤ 1500 ms
- **承诺 B（防寡淡）**：prototype 寡淡失败模式不得复现——每 hook 必"砸地"

**调和方法**：Required Minimum / Forbidden 对称强制（§3 Core Rule 8）。两份清单 **都必须验证通过** 才算配方合规。单清单合规（Pass A 的失败模式）= 违反 Layer 1。

### 不是 fantasy 的部分

Layer 1 **不规定**：
- 单配方的视觉编排美学（squash 帧数 / shake 包络 / 色相） → Layer 2
- "feel good" 主观验收 → Layer 2 主观 AC + Wave 3 playtest
- 机器外观 / 产物造型 / UI 色板 → Art Bible（未启动）
- 音色具体频段 / 音效素材选型 → audio-system.md（Reviewed）+ design/audio/（已起草）

> Layer 1 是"质量底线 + 跨配方一致性"的工程合同，**不是体验文档**。如果玩家"感受到了 fantasy"，那是 Layer 2 配方正确实现 + Layer 1 不变量未被违反 + 非 hook 时间各 GDD 正确填充 三者共同作用的结果。Layer 1 单独不创造体验，只保证不变量。

## Detailed Rules

### Core Invariants（10 条不变量，全局锁定）

下列 10 条 Core Rule 在 Layer 1 锁定。任何下游 GDD（Wave 3-6）或 Layer 2 recipe **不得违反或重新定义**。变更走 ADR amend 流程。godot-gdscript-specialist 在 code review 阶段强制核查。

**Core Rule 1 — Cookbook 是文档，不是 Autoload。**
Layer 1 + Layer 2 无运行时单例、无 `JuiceService`、无 `JuiceManager`。每条配方由下游 gameplay GDD（Wave 3-6）在自己的代码中实现，Cookbook 只提供合同与配方手册。*Cookbook → 下游 GDD → 实现代码*，单向流动。

**Core Rule 2 — 每个 hook signal 只对应一条主配方。**
配方编号 `JC-R1..JC-R7` 与 hook signal 一一映射（`lever_pull_start / lever_lock / shred_start / shred_pulse / reveal_pop / product_land / shelf_add`），不允许同一 hook 出现两份冲突配方。配方需要随 v1.0/v1.5 演化时，新配方走 ADR amend 流程，不在 GDD 里"叠加"。

**Core Rule 3 — 三方同步契约。**
配方的视觉峰值 / 音频 onset / 触觉 strike 严格按 F-1 公式对位（§4 详述）。三方按 `Audio.play() → await timer(audio_lead_ms / 1000.0) → Haptic.play()` 顺序发射；视觉 **T1 压缩关键帧（impact frame）** 必须落在 `t_emit + audio_lead_ms ± 25 ms` 窗口（含测量噪声）。

**Core Rule 4 — 任何 Juice 配方不订阅 Lifecycle 信号。**
配方触发 100% 由 gameplay 信号驱动（`lever_lock` 等）。禁止 Cookbook 因为 `app_resumed / app_paused` 触发任何动画——这是 ADR-0002 反支柱结构守护的明示场景。Lifecycle 中断由 Godot Scene Tree pause 状态自动处置（Edge Cases §5 详述）。

**Core Rule 5 — 五相位 + Silence 尾结构。**
每条配方依序经历 Anticipation → Action → Impact → Follow-through → Silence 五阶段，**任何相位不得跳过、不得乱序**。Silence 尾 ≥ 100 ms（配方间物理隔离时间，不计入 F-5 总时长）。**Impact = F-3 T1 压缩关键帧**（非 overshoot）；overshoot（T1+T2 关键帧）归 Follow-through 相位的视觉表达，不参与 F-1 同步窗口。

**Core Rule 6 — CTL 词汇表锁定 8 个术语。**
配方词汇表（CTL = Cookbook Term Library）锁定为：
`anticipation` · `squash & stretch` · `follow-through` · `screen shake` · `time-scaling` · `color flash` · `particles` · `layered audio`
下游 GDD 必须使用这 8 个术语描述视觉/音频/触觉行为；提出第 9 个术语必须走 ADR amend。术语之外的修辞性描述（"满足感"、"重量感"）只能出现在 Player Fantasy 段落，不得出现在 Detailed Rules / Formulas / AC。

**Core Rule 7 — Cookbook 配方的实现路径锁定 Godot 4.6 API。**
允许：`Tween`（scale / modulate / position） · `CPUParticles2D` · `Camera2D.offset` · `AudioStreamPlayer2D` · `tween.pause() + create_timer() + tween.play()`（freeze 实现路径）。
**条件式 Forbidden（依赖 ADR-R Renderer 决议）**：若最终选 Mobile renderer，禁用 Environment Glow / 多 pass shader（`render_mode blend_add`）。
**全局 Forbidden（与 renderer 无关）**：`Engine.time_scale`（破坏全局时钟与音频对齐）；`AnimationPlayer.speed_scale = 0.0` 用作 freeze（Godot 4.6 不影响 Tween，技术上无效）；`GPUParticles2D` 在 sub-bass 配方（>24 颗）期间使用（调用积累风险）。

**Core Rule 8 — Required Minimum / Forbidden 对称强制（NEW，Pass A re-review 教训封装）。**
每条 Layer 2 recipe **必须同时具备**：
- **Forbidden 子项**（设计 + 技术两类，防过度）
- **Required Minimum 子项**（具体可验证的下限，防不足）
- **AC 覆盖两份清单**（AC-recipe-X 同时验证 Forbidden grep + Required Minimum GUT 常量断言）
任何 recipe 修订必须 **同时** 触及四个维度：Forbidden + Required Minimum + AC + 输入/输出 ranges。**单边修订（"形式修复 / patching to silence the audit"）视为违反 Core Rule 8**。code review 阶段 godot-gdscript-specialist 强制检查 PR diff 是否包含全部四类变更（缺一即拒绝合并）。

**Core Rule 9 — 多属性 Tween 必须 `set_parallel(true)`。**
Godot 4 Tween 默认 serial（属性串联）。F-1 同步窗口要求 scale / modulate / position 等多属性 **同步开始**，因此所有 Layer 2 recipe 实现 **必须** 在 Tween 创建后立即 `tween.set_parallel(true)`。godot-gdscript-specialist 在 code review 阶段强制 grep 检查（AC-11 + AC-14 联合验证）。

**Core Rule 10 — Pillar 2 戏剧弧线层级（NEW，R4 修复，用户裁决量化锁定）。**
核心循环情感强度曲线必须遵循 *lever_lock → shred → reveal_pop → product_land → shelf_add* 的升降序，其中 **reveal_pop 是峰值最高的时刻**。量化锁定：
`strength(JC-R5) ≥ strength(JC-R2) × 1.5`（strength 计算公式见 §4 F-strength）
JC-R2 允许 **单帧低饱和 modulate flash**（Pass 1 R4 解禁）以解决"戏剧弧线倒置"；但 JC-R2 的 flash 强度必须明显低于 JC-R5（具体阈值由 strength 公式约束，自动满足 1.5x 比例）。

### Required Minimum / Forbidden 对称强制条款（Core Rule 8 详述）

> Pass A re-review 暴露的根本失败模式是 **单边修订**：作者修了 output range 但没改 input range（B10）、加了 grep 但 grep 无法验语义（AC-13/14）、拆了 AC 但语义重复（AC-01）、加了音量地板但没改峰值关系（R4）。Core Rule 8 是 Layer 1 对 Layer 2 撰写过程的 **元约束**——它不是某条 recipe 的具体规则，是 *recipe 必须如何被设计、修订、审计* 的契约。

#### 对称四维度

每条 Layer 2 recipe **必须**同时维护以下 4 个维度的内容，且任何修订必须同时考虑全部 4 个：

| 维度 | 内容 | 验证方式 |
|---|---|---|
| **Forbidden 子项** | 设计 *forbid*（哪些视觉/音频/触觉选择违反 Pillar / cozy 调性）+ 技术 *forbid*（哪些 Godot 4.6 API / 实现路径会破坏同步、性能、可维护性）| AC-recipe-X *forbidden grep*（精确字符串 grep，模式定义在 AC 中） |
| **Required Minimum 子项** | 视觉 *最低* + 音频 *最低* + 触觉 *最低* 三类硬下限。每条下限必须是 **可由 GUT 常量断言或精确 grep 验证** 的数值/字符串（不允许"目测""明显""感觉对"等主观表述）| AC-recipe-X *minimum* GUT 常量断言（数值不等式由 GUT 验证，存在性由精确 grep 验证） |
| **AC 双覆盖** | 同一 AC-recipe-X 必须 **同时** 验证 Forbidden grep + Required Minimum 常量值。AC 测试路径必须包含 GUT 自动化测试，不允许全部依赖 manual real-device test | 在 Layer 1 §8 AC 区与 Layer 2 recipe AC 中双重核查；AC 验证脚本 PR 同步提交 |
| **输入/输出 ranges 一致性** | 任何 recipe 引用的公式（F-2/F-3/F-4/F-5/F-7）的 input variable ranges 与 output range 必须数学一致：输入最小值代入公式 → 输出 ≥ 声明的 output minimum；输入最大值代入公式 → 输出 ≤ 声明的 output maximum。**单边调整任一端必须同步验证另一端**| Layer 2 各公式说明区显式列"边界代入验证"表 |

#### 单边修订禁止清单

下列模式是 **Pass A re-review 实际出现的失败案例**，Core Rule 8 明示禁止，code review 阶段强制检查：

1. **改 output range 不改 input range**（Pass A B10 fail mode）：例 `Output: [0.1, 1.8] → [0.5, 1.8]` 但 `input_min × ratio_min` 仍 < 新 output_min
2. **重定义公式锚点不验证测量精度**（Pass A B1 fail mode）：例 `audio_onset_t_ms → t_emit` 但未声明 t_emit 测量方法的实际抖动范围
3. **拆 AC 但语义重复**（Pass A AC-01 fail mode）：例 AC-A 拆为 AC-A1 + AC-A2，但两者测同一件事
4. **加 grep 但 grep 无法验语义**（Pass A AC-13/14 fail mode）：例"检查 `heavy_content` 关键字"，但实现者用别名 `is_heavy` 或中文变量名绕过
5. **加 Required Minimum 但未改 Forbidden**（Pass A R4 fail mode）：例加"必须三方共振齐发"音量地板，但 Forbidden 没改"禁止 color flash"，导致 JC-R2 峰值仍低于 JC-R5（核心问题未解决）

#### Pass A 修订流程作为 Core Rule 8 验证锚点

任何后续 Layer 2 recipe 修订 PR **必须** 在 PR description 中包含一张"四维度变更影响矩阵"：

| 维度 | 本次 PR 是否触及 | 如未触及，理由 |
|---|---|---|
| Forbidden | ☐ Yes ☐ No | |
| Required Minimum | ☐ Yes ☐ No | |
| AC 覆盖 | ☐ Yes ☐ No | |
| 输入/输出 ranges | ☐ Yes ☐ No | |

godot-gdscript-specialist 在 review 时核查矩阵：4 个维度任一未触及但理由空白 → 拒绝合并。**Layer 1 Core Rule 8 是 Layer 2 PR 模板的法定字段**。

### Hook Signal 优先级（同帧冲突抢占规则）

同帧 emit 两个不同 hook signal（理论不应发生但要兜底）时按以下优先级决定 sound channel 抢占与视觉效果叠加：

`lever_lock > reveal_pop > shred_start > shred_pulse > product_land > shelf_add > lever_pull_start`

**抢占规则**：
- **Audio**：高优先级 hook 抢占 audio bus 通道（Audio System Core Rule 5）
- **Visual**：所有配方视觉效果不互斥，可同帧执行（性能由 F-4 跨配方粒子上限保证）
- **Haptic**：高优先级 hook 抢占触觉通道（HapticSystem 内部 gate）

**重叠抢占的根本约束**：下游 gameplay GDD（如 Lever Interaction）的状态机必须 gate 不应共存的 hook signal——例 IDLE → PULLING 必须等待 REVEAL_DONE 状态。Layer 1 不在 runtime 拦截重叠，但 godot-gdscript-specialist code review 强制检查状态机闭合。AC-10 验证。

## Formulas

> Layer 1 仅承载 **跨配方** 公式（F-1 同步契约 / F-6 Reduce Motion 接口 / F-7 anticipation 范围验证器 / F-strength 戏剧弧线量化）。**单配方公式** F-2 (shake decay) / F-3 (squash keyframes) / F-4 (cross-recipe particle budget) / F-5 (total juice 时长预算) 归 Layer 2 `juice-recipes.md`。
>
> 全局假设：渲染帧率锁定 60 FPS（technical-preferences.md MVP 约束）。1 frame = 16.667 ms。所有 ms 参数注释 = N 帧 @ 60 FPS 等价。

### F-1：同步对位契约（跨配方）

> **B1 修订 + Pass A re-review systems-designer 修订**：F-1 之前版本 `audio_onset_t_ms` 模糊覆盖三个不同时间（t_call / t_emit / t_perceive）。Pass A 锚定 t_emit 但容差 ±15 ms 单独被 `AudioServer.get_time_to_next_mix()` 实测 ±10-20 ms 抖动吃光。本版按用户裁决：**保持 t_emit 锚点 + 放宽容差到 ±25 ms**（含测量噪声）+ 列入 OQ-1 spike 强制校准条款。

#### 公式

`impact_anchor_t_ms = t_emit + audio_lead_ms`
= `t_emit + 35`

#### Variables

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `t_call` | — | float | [0, ∞) | gameplay 代码调用 `AudioSystem.play(sfx_key)` 的栈帧时刻。**不是 F-1 锚点**（栈深度抖动 1-3 ms 不可控）。仅用于 log 调试。|
| `t_emit` | t_e | float | [0, ∞) | `AudioStreamPlayer2D` 真正调度采样进入混音器输出 buffer 的时刻（毫秒，自 hook signal `emit()` 起计）。**F-1 唯一锚点**。测量方法见下方"测量精度声明"。|
| `t_perceive` | t_p | float | [t_e, t_e + 65] | 玩家在外设上感知到 audio onset 的时刻 = `t_emit + platform_audio_output_latency_ms`（见下表）。**F-1 不直接约束 t_perceive**。AC-01a 校准扬声器路径，AC-01b 单独测主观 BT 体验阈值（不是 t_emit 重复验证 — 修 Pass A re-review qa-lead #2）。|
| `audio_lead_ms` | — | int (registry) | =35（locked, haptic-system.md owns） | Haptic 相对 Audio 的延迟发射量 |
| `impact_anchor_t_ms` | t_i | float | [35, ∞) | 视觉 Impact 相位 **T1 压缩关键帧**（squash 极值帧）的目标时刻 |

#### 同步窗口

视觉 T1 压缩关键帧渲染时刻 `t_render` 必须满足：

`|t_render - impact_anchor_t_ms| ≤ 25 ms`

**容差 25 ms 的组成**（**OQ-1 spike 强制验证三项独立 < 容差预算**）：

| 组件 | 预算 | 来源 |
|---|---|---|
| 人类听觉同步阈值（Spence 2007 + Apple HIG）| ±15 ms | 心理声学常量 |
| `t_emit` 测量噪声 σ（混音 buffer 块抖动）| ±5 ms | OQ-1 spike 实测，**严禁 > 10 ms** |
| 帧调度抖动（60 FPS 下 ±0.5 frame）| ±5 ms | Godot 渲染管线 |
| **总和（线性最坏情况）** | **±25 ms** | F-1 锁定容差 |

**关键约束**：测量噪声 σ > 10 ms 时 F-1 公式失效，须回到 Layer 1 重谈锚点（替代方案 = `AudioServer.get_output_latency()` + frame timestamp 双时钟）。OQ-1 spike（Wave 3 启动前 1-2 天）的硬产出 = 实测 σ 数字，σ ≤ 10 ms 才算解锁 Wave 3。

#### 测量精度声明

`t_emit` 推算方法（Godot 4.6）：

```
t_emit_estimated_ms = current_frame_start_ms 
                    + AudioServer.get_output_latency() * 1000.0
```

`get_output_latency()` 返回当前混音器到外设输出的整体 pipeline 延迟（秒）；返回值在同一设备同一会话内稳定（首次启动后 ~1 秒收敛）。注意：**该函数返回的是 pipeline 估算值而非实际 sample 调度时刻**，因此 t_emit 估算误差与混音 buffer 块大小相关（Godot 默认 ~10-20 ms 块 → σ ≈ ±5-10 ms）。

**OQ-1 spike 硬产出（强制）**：
1. iPhone XS / iPhone SE 2nd gen 真机 100 次 hook trigger 测量 `t_emit` 与 audio output onset 实际偏差 σ
2. σ ≤ 10 ms → F-1 容差预算 ±25 ms 成立，AC-01a 可执行
3. σ > 10 ms → Layer 1 公式回炉，user + technical-director 重决锚点（不解锁 Wave 3）

#### `platform_audio_output_latency_ms` 平台路径补偿表

t_emit → t_perceive 的典型偏移（毫秒）。**仅信息性，不参与 F-1 锚点判定**。

| 平台路径 | 估算 latency_ms | 数据来源 | 处置 |
|---|---|---|---|
| iOS 内置扬声器 | 12-22 ms | Apple WWDC '23 audio session | AC-01a 默认路径 |
| iOS AirPods Classic (BT) | 35-55 ms | CoreAudio AVAudioSession latency 实测 | AC-01b 主观 ≥3.5/5 阈值（不重复 t_emit 验证）|
| iOS AirPods Pro/Max (低延迟) | 18-30 ms | Apple "MV-HEVC"-class latency mode | 按扬声器路径处理 |
| Android 内置扬声器 | 20-40 ms | Android Pro Audio class device 中位数 | Follow-up Android port 期校准 |
| Android BT 经典 | 50-65 ms | AOSP audio HAL 文档 | Production v1.5 决定补偿策略 |

**Cookbook 立场**：默认走 iOS 扬声器路径锁定 `t_emit + 35 ms` 视觉对齐；BT 路径走 AC-01b 主观体验阈值；具体补偿表 owner = `audio-system.md`（职权边界）。

---

### F-6：Reduce Motion 振幅降级接口

> Layer 1 只声明接口结构 + 作用域；具体三档阈值映射与启用条件由 `accessibility-system.md` (Not Started, v1.0) 拥有。

#### 公式

对 F-2 / F-3 / F-7 的振幅参数统一缩放：

`effective_amplitude = base_amplitude × reduce_motion_factor`

对 F-3 squash 偏差量（保持 1.0 中心）：

`effective_s_compressed = 1.0 - (1.0 - base_s_compressed) × reduce_motion_factor`
`effective_s_overshoot = 1.0 + (base_s_overshoot - 1.0) × reduce_motion_factor`

#### Variables

| Variable | Type | Range | Description |
|---|---|---|---|
| `reduce_motion_factor` | float | {0.0, 0.5, 1.0}（离散三档） | Accessibility GDD 拥有阈值映射权 |
| `base_amplitude` | float | per F-2 / F-3 / F-7 各自范围 | 配方原始振幅参数 |
| `effective_amplitude` | float | [0, base] | 缩放后实际振幅 |

#### 作用域约束（不变量）

- F-6 **只作用于振幅**——时长（F-3 T1/T2/T3、F-2 HOLD/DECAY、F-5 total_juice）**不被** F-6 修改。理由：Apple HIG `prefers-reduced-motion` 默认不缩时长，仅停动画或换静态过渡。
- F-6 **不直接作用于 F-4 particle counts**——粒子是否禁用由 Accessibility GDD 决定（例 Reduce Motion = 0.0 时关闭所有 `CPUParticles2D`）。
- F-6 **不作用于 Audio / Haptic**——音频与触觉是 Reduce Motion 关动作时的等效感官替代（§2 三层承诺 #3）。
- factor = 0.0 时所有视觉运动归零，但 Core Rule 3 同步契约仍生效（Audio/Haptic 按 t_emit 正常发射，玩家仍感知节奏）。

#### iOS reduce-motion 接入路径（修 Pass 2 B14）

> Pass 2 accessibility-specialist 指出：F-6 接口存在但 iOS `prefers-reduced-motion` bool **无人消费**——前庭功能障碍用户在 MVP 阶段无任何方式关闭 shake/squash。

Layer 1 立法：MVP 阶段下游 GDD（具体 owner = `lever-interaction.md` 等使用 F-6 的 GDD）**必须** 在每次配方触发前读取 iOS 系统 `prefers-reduced-motion` bool（Godot 4.6 通过 `DisplayServer.is_window_per_pixel_transparency_enabled()` 等系统调用 + iOS 平台桥接），并按 **bool → factor 硬映射**：

| iOS prefers-reduced-motion | factor |
|---|---|
| `false` | 1.0（默认，全振幅）|
| `true` | 0.0（全振幅归零）|

中间档 0.5 仅在 `accessibility-system.md` v1.0 GDD 设计期决定何时启用（不进 MVP）。**这一硬映射不依赖 Accessibility GDD 完成，可在 MVP 阶段独立实施**——AC-iOS-reduce-motion（§8）验证。

---

### F-7：Anticipation 反向预备范围验证器

> **B10 修订 + Pass A re-review systems-designer #4 修订**：Pass A 把 Output Range 从 [0.1, 1.8] 抬到 [0.5, 1.8] 但 input ranges 不变，导致 `action_amplitude_min × ratio_min = 2 × 0.05 = 0.10 px < 0.5 px` 内部矛盾。本版按 Core Rule 8 对称强制：**同步调整 input + 加 clamp 双保险**。

#### 公式

`anticipation_offset_px = max(action_amplitude × anticipation_ratio, MIN_VISIBLE_OFFSET_PX)`

#### Variables

| Variable | Type | Range | Description |
|---|---|---|---|
| `action_amplitude` | float | **[10, 12] px**（B10 修订下限 2→10，与 output_min=0.5 数学一致）| 主动作的视觉运动幅度 |
| `anticipation_ratio` | float | [0.05, 0.15] | 反向预备相对主动作的比例（不变） |
| `MIN_VISIBLE_OFFSET_PX` | const | = 0.5 | retina mobile 显示器 sub-pixel snap 防御常量。**Layer 1 锁定** |
| `anticipation_offset_px` | float | [0.5, 1.8] px | 反向预备的实际像素位移（已 clamp） |

#### 边界代入验证（Core Rule 8 强制核查 4 项）

| 输入组合 | 计算 | 输出 | 范围检查 |
|---|---|---|---|
| 最小 × 最小: 10 × 0.05 | = 0.5 | 0.5 px | ✅ 等于下限 |
| 最大 × 最大: 12 × 0.15 | = 1.8 | 1.8 px | ✅ 等于上限 |
| 最小 × 最大: 10 × 0.15 | = 1.5 | 1.5 px | ✅ 在范围 |
| 最大 × 最小: 12 × 0.05 | = 0.6 | 0.6 px | ✅ 在范围 |

**结果**：input ranges + output range + clamp 三者数学一致。AC-F7-bound（§8）GUT 验证。

#### 与 F-6 叠加

`effective_offset = anticipation_offset_px × reduce_motion_factor`

注：reduce_motion_factor = 0 时 effective_offset = 0（视觉无 anticipation），与"Reduce Motion 关动作不关反馈"一致。

#### 使用语义

F-7 主要作为 **v1.0+ 新配方派生工具 + 范围验证器**——验证 Layer 2 recipe 已写的 anticipation 位移值是否落在 [0.5, 1.8] 区间。超出该范围属"过度蓄力"违规（> 1.8）或"不可见"违规（< 0.5，被 clamp 兜底但应纠正 input 值）。

---

### F-strength：戏剧弧线强度量化（Core Rule 10 验证锚点）

> **NEW，R4 修复实现机制**：Core Rule 10 要求 `strength(JC-R5) ≥ strength(JC-R2) × 1.5`，但 Pass A "strength" 没有定义。本节锁定可量化、可 GUT 验证的 strength 计算公式。

#### 公式

`strength(recipe) = visual_score(recipe) + audio_score(recipe)`

#### Visual score（视觉强度分量）

```
visual_score(r) = squash_score(r) + shake_score(r) + flash_score(r) + particle_score(r)

squash_score(r)   = max(|s_compressed - 1.0|, |s_overshoot - 1.0|) × 20
shake_score(r)   = base_amp_px  // F-2 范围 [0, 8]
flash_score(r)   = brightness_delta_pct / 10  // 范围 [0, 10]，1 帧 100% flash → 10
particle_score(r) = burst_count / 4  // 范围 [0, 12]，48 颗 → 12
```

每个子项的范围约为 [0, 10-12]，4 项累计 visual_score ≈ [0, 40]。

#### Audio score（音频强度分量）

```
audio_score(r) = layer_count_score(r) + peak_loudness_score(r)

layer_count_score(r) = audio_layer_count × 2  // 1 轨=2, 2 轨=4, 3 轨=6
peak_loudness_score(r) = max(peak_db_above_master, 0)  // 不允许负数
```

audio_score 范围约为 [0, 18]（最多 3 轨 + 12 dB peak）。

#### JC-R2 vs JC-R5 strength 验证（Core Rule 10 数学验证）

> 注：本节使用 Layer 2 recipe 草拟值作为示例，具体值在 `juice-recipes.md` 落地后以 Layer 2 值为准。

**JC-R2 lever_lock（草拟值）**：
- squash 0.92 → 1.05: max(0.08, 0.05) × 20 = **1.6**
- shake amp = 4 px: **4**
- flash（R4 解禁单帧低饱和 modulate, brightness +10%）: 10/10 = **1**
- particle 0（Forbidden）: **0**
- visual_score = 1.6 + 4 + 1 + 0 = **6.6**
- audio layers = 2（sub-bass + metal）: **4**
- audio peak = 0 dB above master（不额外 duck）: **0**
- audio_score = 4 + 0 = **4**
- **strength(JC-R2) = 6.6 + 4 = 10.6**

**JC-R5 reveal_pop（草拟值，MVP 路径）**：
- squash 0.6 → 1.2: max(0.4, 0.2) × 20 = **8**
- shake 0（Forbidden）: **0**
- flash（1 帧亮黄白 100%）: 100/10 = **10**
- particle 0（MVP，无 rare shimmer）: **0**
- visual_score = 8 + 0 + 10 + 0 = **18**
- audio layers = 2（attack transient + sustained body）: **4**
- audio peak = +6 dB above master（揭晓时刻响度差异）: **6**
- audio_score = 4 + 6 = **10**
- **strength(JC-R5) = 18 + 10 = 28**

**Ratio = strength(JC-R5) / strength(JC-R2) = 28 / 10.6 ≈ 2.64**

`2.64 ≥ 1.5` ✅ Core Rule 10 满足。安全余量 = 2.64 / 1.5 = 1.76×（约 76% buffer，允许 Layer 2 微调 JC-R2 参数而不破坏戏剧弧线）。

#### 不变量

- `strength(JC-R5) ≥ strength(JC-R2) × 1.5`（Core Rule 10 量化锁定，AC-strength-ratio §8 GUT 验证）
- `strength(JC-R5)` 必须是 JC-R1..R7 中的全局最大值（次最大允许 JC-R2 / JC-R6 / JC-R7 任一）
- 任何 Layer 2 recipe 修订触及 squash / shake / flash / particle / audio 参数 → **必须重新计算 strength + AC-strength-ratio 重跑**（Core Rule 8 对称强制）

#### Open Question

OQ-strength-formula: F-strength 公式权重 [×20 / 直接值 / ÷10 / ÷4] 是首次定义，**未经真机校准**。Wave 3 启动前 OQ-1 spike 期间附带 5-10 人小范围主观验证：让 tester 对 7 个配方打 1-5 分体验"轰击感"分数，验证 strength 排序与主观排序一致。不一致 → 公式权重调整，**走 ADR amend**（不阻塞 MVP 但 Wave 3 前应校准）。

## Edge Cases

> Layer 1 只处理 **跨配方边界场景**（同步降级、Lifecycle 中断、Hook 抢占、跨配方资源越限、Pillar 冲突、Accessibility 优先级）。单配方内部 Edge Cases（如 JC-R5 large 偏离）归 Layer 2 各 recipe 章节。

### 同步与降级类（F-1 + F-6 接口）

- **Reduce Motion = 0.0 时任何配方触发**：所有视觉振幅归零（squash = 1.0、shake = 0、anticipation = 0），但 Audio + Haptic 仍按 t_emit + audio_lead_ms 正常发射。玩家依然听到声音和触觉，只是没有视觉运动。这是预期行为（Apple HIG 明确"Reduce Motion 是关动作不是关反馈"），不是 bug。
- **`AudioServer.get_output_latency()` 返回 0 或异常值**（设备启动 ~1 秒内可能发生）：fallback 使用静态 audio_lead_ms = 35 ms 不做平台补偿。视觉与音频可能漂移最多 ±30 ms，仍在 Pillar 1 触感容差内。下游 GDD **不得** 在 latency 收敛前 fail-fast；用 stale value 是合规处置。
- **`settings.haptic_enabled = false` 但 Audio 正常发射**：HapticSystem 内部 gate 自然跳过，Cookbook 配方不改变调用顺序——仍 await `audio_lead_ms` 再尝试 `Haptic.play()`，HapticSystem 内部判断 enabled=false 后 silently no-op。Cookbook 不需要知道这个状态。
- **SFX volume = 0（静音）但触觉开**：F-1 同步计算依然基于 `t_emit`（调用时刻，不管音频是否发声），impact_anchor 仍按 t_emit + 35 ms 计算。视觉峰值仍与触觉对齐，避免"静音模式下视觉漂移"。
- **OQ-1 spike 报告 σ > 10 ms 但 MVP 已发布**：F-1 公式失效，Wave 3 GDD 启动条件已破。处置：紧急 ADR amend 替换锚点为 `get_output_latency()` + frame timestamp 双时钟方案；MVP 已发布的版本接受 ±35 ms 实际窗口（含失败的 σ）。**这是 Wave 3 启动前 spike 的存在意义——失败必须在 Wave 3 之前发现**。

### Lifecycle 中断类（Core Rule 4 守护）

- **配方动画进行中 app 转入后台**（OS `application_paused`）：所有 Tween 和 `CPUParticles2D` 由 Godot Scene Tree pause 状态自动暂停（前提：Layer 2 recipe 实现节点的 `process_mode != PROCESS_MODE_ALWAYS`）。Audio + Haptic 由各自 Foundation 系统的 pause 行为处理。**Cookbook 不主动监听 `app_paused`**（Core Rule 4，ADR-0002 守护）。
- **app 从后台回前台**（`application_resumed`）：所有 Tween 从暂停帧继续，Particles 复活。但 F-1 同步窗口已经被中断；剩余动画不再保证 Impact 帧与 Audio onset 对齐。**处置**：被中断的配方播完剩余动画即可，不重新发射 Audio/Haptic 也不重置进度（玩家已经看过一半，重播会很怪）。下一次新的 hook signal 才走完整 F-1 同步。
- **IME 弹起打断配方中段**（Text Input GDD LONG_PRESSING + PAUSED 路径）：IME 弹起触发 `application_paused`，进入上一条处置。预期玩家此时已经按下摇杆但还没拉到 trigger 阈值——拉杆动画播完即可，不强制 trigger（Lever Interaction GDD 的状态机控制）。

### Hook Signal 重叠/抢占类（Core Rule 5 + Hook 优先级表）

- **配方 Silence 尾未结束（< 100 ms）时新 hook signal 到达**：违反 Core Rule 5。**处置**：下游 gameplay GDD 的状态机必须 gate 此种重叠（如 Lever Interaction GDD: IDLE → PULLING 只能在 REVEAL_DONE 后进入）。Cookbook 不在 runtime 拦截，但 godot-gdscript-specialist code review 强制检查状态机闭合。**如果运行时仍发生**（如调试场景）：旧配方继续播放，新配方按优先级表抢占 Audio + Haptic 通道，视觉可同帧叠加（性能由 F-4 保证）。
- **同帧 emit 两个不同 hook signal**：按 Hook Signal 优先级表（§3）决定抢占。Audio + Haptic 单通道，视觉可叠加。
- **JC-R4 脉冲发射时距 JC-R3 启动 < 100 ms**：意味着 Shred Process GDD 把首次脉冲 offset 设得太短。**处置**：Cookbook 不在 runtime 拦截；Shred Process GDD 的 Tuning Knobs 必须 cite `JC-R4.first_pulse_offset ≥ 300 ms`（与 haptic-system.md F-2 派生一致）。code review 强制检查。

### 跨配方资源越限类（F-4 + F-5 守护）

- **v1.0 稀有产物揭晓 (rare JC-R5) 与 shred_start 余粒子同帧叠加**：F-4 表计算 12 + 8 + 16 = 36 < 48 ✅。但 v1.5+ 新增粒子源（季节限定特效）可能超过 48。**处置**：v1.0+ 任何新增粒子源必须重新计算 F-4 表，超 48 则 Cookbook ADR amend 提升上限或砍其他源。MVP 阶段 F-4 表锁定。
- **device 实际帧率 < 60 FPS**（如 iPhone XS 满电烫机降频到 45 FPS）：所有 F-3 / F-5 的 ms 时长保持不变，但实际显示帧数变少（如 T1=33 ms 在 45 FPS 下只显示 1.5 帧）。**处置**：MVP 接受此降级（玩家会感觉动画"略卡"但不破坏 sync）；Production Sprint 1 真机测试若 P95 帧率长期 < 55 FPS，触发 Tech Debt 任务讨论是否帧率自适应。**绝不通过降低 ms 时长来掩盖性能问题**——这会改变 juice 的节奏感。
- **`CPUParticles2D` 池满（`amount` 上限达到）**：Godot 自动覆盖最老粒子。视觉上"碎屑突然消失"但不会崩溃。**处置**：F-4 表已为 MVP 留 48 上限 vs 20 实际占用的 28 粒子安全余量，不会触发。

### Pillar 冲突类（反 attention-manipulation 立场）

- **玩家正在写"重内容"**（Text Input GDD 标记的 Pillar 4 heavy mode）：JC-R6 `product_land` 仍按标准配方播放（s_compressed=0.92, s_overshoot=1.0）。**禁止任何 Pillar 4 检测分支去改变 JC-R6 振幅**（Core Rule 7 实现路径锁定）——Mochi 的工匠姿态体现在"同样的动作对待轻重一致"，不是"重内容时变悲伤"或"轻内容时变欢乐"。**这是 Cookbook 反 attention-manipulation 设计**，AC-pillar4-invariance（§8）GUT injection 验证。
- **连续 30 秒无 hook signal 触发**（玩家发呆）：Cookbook 不主动启动任何 idle juice。`mochi_blink` 由 Mochi Character (#6) 决定（角色系统职责，归 Out-of-Scope 94% 时间）。Cookbook 在静默期完全无动作——这是 Pillar 5 Unlimited But Meaningful 的视觉表达。

### Accessibility 优先级冲突

- **任何 Onboarding 偏离遇 Reduce Motion ≠ 1.0**：以 Reduce Motion 为准——effective_amplitude 按 factor 缩放。理由：无障碍优先级 > onboarding 强调。具体 case 见 Layer 2 各 recipe Onboarding 偏离章节。
- **iOS prefers-reduced-motion = true 与下游 GDD 自定义 reduce_motion_factor 设置冲突**：以 iOS 系统设置为准（F-6 iOS 接入路径硬映射 → factor = 0.0）。下游 GDD 不得 override 系统设置——这是 Apple HIG 强制要求。
- **`prefers-reduced-motion` 检测失败**（iOS 平台桥接异常）：fallback 使用 factor = 1.0（默认全振幅）。**不 fail-close**——不能因为检测失败就关闭所有动画（这会让 99% 玩家失去 feel），但要在 production log 记录失败事件。Wave 3 测试期 production-log 显示 fallback rate > 0.1% 触发紧急修复。

## Dependencies

### Upstream（Layer 1 依赖的系统）

| System | Type | 数据流 | Layer 1 引用的具体接口 | bidirectional 义务 |
|---|---|---|---|---|
| **Audio System** (#3, Reviewed) | Hard | Layer 1 → Audio | `AudioSystem.play(sfx_key)` · `AudioSystem.play_loop(sfx_key)` · `AudioSystem.stop_loop(sfx_key)` · `AudioServer.get_output_latency()`（F-1 测量）；sfx_key ∈ registry sfx_* 常量集 | Audio System GDD 需补 "Referenced by: juice-contract.md (Layer 1) + juice-recipes.md (Layer 2)" |
| **Haptic System** (#4, Reviewed) | Hard | Layer 1 → Haptic | `Haptic.play(StringName)`；key ∈ registry haptic_* 常量集；不读 `settings.haptic_enabled`（HapticSystem 内部 gate） | Haptic System GDD 需补 "Referenced by: juice-contract.md + juice-recipes.md" |
| **Mobile App Lifecycle** (#5, Reviewed) | Soft | Lifecycle → Layer 1（**被动接收**） | Core Rule 4 明示 Cookbook 不订阅；Godot Scene Tree pause 状态自动处置 Tween/Particles 暂停。Layer 1 仅在 Edge Cases 引用 OS `application_paused/resumed` 行为约定 | Lifecycle GDD 已 Reviewed；Layer 1 不需新增主动订阅 |
| **registry/entities.yaml** | Hard | Layer 1 ← registry | 引用：`audio_haptic_sync_window_ms`（旧 30 ms，**B1 改名 + 升级为 audio_sync_window_total_ms = 50 ms**，含测量噪声）、`audio_lead_ms = 35`、`audio_bgm_offset_db = -12dB`、`MIN_VISIBLE_OFFSET_PX = 0.5`（新）；所有 sfx_* 与 haptic_* 常量名 | Phase 5 registry 注册：(a) `audio_sync_window_total_ms = 50` 新增；(b) `MIN_VISIBLE_OFFSET_PX = 0.5` 新增；(c) `juice_strength_ratio_min = 1.5`（Core Rule 10）；(d) 旧 `audio_haptic_sync_window_ms = 30` 标记 DEPRECATED，referenced_by 转 juice-contract.md |
| **ADR-R Renderer Choice**（待起草）| Hard | ADR → Layer 1 | Core Rule 7 条件式 Forbidden 依赖 ADR-R 决议。Mobile renderer = Glow / blend_add Forbidden；Forward+ = 部分放宽 | ADR-R 起草 owner = technical-director；Wave 3 启动前必须有决议（否则 Core Rule 7 条件式条款无 grounding）|

### Downstream（被 Layer 1 约束的系统）

| System | Type | 引用强度 | Layer 1 提供的契约 | bidirectional 义务 |
|---|---|---|---|---|
| **Layer 2 (juice-recipes.md)** | Hard | 全条款继承 | 全部 10 Core Rules + F-1/F-6/F-7/F-strength；Layer 2 每条 recipe 必须满足 Core Rule 8 对称四维度 | Layer 2 起草时必须显式 cite "继承自 juice-contract.md Core Rule X" |
| **Lever Interaction System** (#8, Not Started) | Hard | 硬引用 | JC-R1 + JC-R2 配方契约；Lever 状态机必须 gate hook signal 重叠（Edge Case Hook 类） | Lever GDD Tuning Knobs 必须显式 cite `JC-R1` / `JC-R2`；code review BLOCKING |
| **Shred Process System** (#9, Not Started) | Hard | 硬引用 | JC-R3 + JC-R4 配方契约；`n_pulses` 上下限；`first_pulse_offset ≥ 300 ms` | Shred GDD Tuning Knobs cite `JC-R3` / `JC-R4`；首次脉冲 offset 与 haptic-system.md F-2 一致 |
| **Silhouette Reveal System** (#11, Not Started) | Hard | 硬引用 | JC-R5 + JC-R6 配方契约；JC-R5 strength 必须满足 Core Rule 10（≥ JC-R2 × 1.5）| Silhouette GDD Tuning Knobs cite `JC-R5` / `JC-R6` |
| **Shelf Collection System** (#12, Not Started) | Hard | 硬引用 | JC-R7 配方契约；anti-completionism Forbidden（无金粉/烟火） | Shelf GDD Tuning Knobs cite `JC-R7`；视觉无任何成就感信号 |
| **Mochi Character System** (#6, Not Started) | Soft | 软引用 | Layer 1 不提供 mochi_blink 配方；提供 CTL 词汇表作为可选词典；表情类配方归 Mochi Character GDD | Mochi GDD 自定义角色动画；如使用 squash/screen shake 等术语必须遵循 CTL 锁定列表 |
| **Onboarding / First-Run System** (#15, Not Started) | Hard | 硬引用 + 受控偏离 | 全套 JC-R1-R7；**唯一允许偏离**（Pass A re-review 4 specialist 终审）：前 3 次 shelf_add 走 JC-R7 enhanced 变体（具体参数 Layer 2 JC-R7 章节定义）；`first_run_shelf_add_count` 持久化合同 | Onboarding GDD 必须显式声明 enhanced 偏离 + 持久化计数；**JC-R5 medium→large 偏离已删除**（Pillar 2 一致性 + 调用路径未解决 + accessibility 反向歧视，4 specialist 独立一致裁决）|
| **Accessibility System** (#16, Not Started, v1.0) | Hard | 反向控制 | Layer 1 提供 F-6 reduce_motion_factor 接口 + iOS bool → factor 硬映射（MVP）；Accessibility v1.0 GDD 拥有阈值映射（0.0/0.5/1.0 三档何时启用）+ particle 禁用规则 | Accessibility v1.0 GDD 拥有 `reduce_motion_factor` 三档定义权；Layer 1 不预设三档启用条件，但 MVP iOS bool → factor 硬映射不依赖 Accessibility GDD |

### Out-of-Scope 系统（参见 §2 Player Fantasy Out-of-Scope 表）

| System | 为什么不在 Layer 1 依赖 |
|---|---|
| **Persistence System** (#1) | Layer 1 是文档无运行时状态。`first_run_shelf_add_count` 由 Onboarding GDD 通过 Persistence 持久化，Layer 1 不直接读 |
| **Input System** (#2) | Layer 1 不订阅 touch events；hook signal 由下游 gameplay GDD 转发 |
| **Product System** (#10) | Layer 1 不知道产物种类/稀有度；产物的视觉揭晓 (JC-R5/R6) 由 Silhouette Reveal GDD 调用 |
| **Text Input System** (#7) | Layer 1 不知道输入内容；Pillar 4 重内容不改变 JC-R6 振幅（Edge Cases 反 attention-manipulation 规则） |
| **Scene Composition / Navigation** (#14) | Layer 1 不参与场景切换 juice；场景过渡若有动画由 Scene Composition GDD 自己定义 |

### Interface 接口契约总览

Layer 1 的依赖关系全部走 **单向调用 + registry 常量** 两种通道，**不订阅任何信号**：

```
[Layer 2 recipe 实现代码 (在下游 GDD 的 .gd 中)]
  ├─ 调用→ AudioSystem.play(sfx_key)              (registry sfx_* keys)
  ├─ 查询→ AudioServer.get_output_latency()       (F-1 测量)
  ├─ 查询→ iOS prefers-reduced-motion 系统 bool   (F-6 接入)
  ├─ await timer(audio_lead_ms / 1000.0)           (registry constant 35 ms)
  ├─ 调用→ Haptic.play(haptic_key)                (registry haptic_* keys)
  └─ 启动→ 视觉 Tween / CPUParticles2D / Camera2D.offset  (Godot API)
```

无回调，无信号订阅，无运行时单例。

### bidirectional 一致性义务清单（Layer 1 落地后 Phase 5 检查项）

1. **Audio System GDD** Cross-References 段补 "Referenced by: juice-contract.md + juice-recipes.md"
2. **Haptic System GDD** Cross-References 段补 "Referenced by: juice-contract.md + juice-recipes.md"
3. **registry/entities.yaml** 注册：(a) `audio_sync_window_total_ms = 50`；(b) `MIN_VISIBLE_OFFSET_PX = 0.5`；(c) `juice_strength_ratio_min = 1.5`；现有 `audio_haptic_sync_window_ms = 30` 标 DEPRECATED 转 juice-contract.md
4. **systems-index.md** 更新 #13 为"拆为 juice-contract.md (Layer 1) + juice-recipes.md (Layer 2)"双行结构；状态 Layer 1 Reviewed pending、Layer 2 In Design
5. **`consistency-failures.md`** 若 Phase 5 跑 `/consistency-check` 时发现 bidirectional 漏洞，按格式追加

## Tuning Knobs

> Layer 1 仅承载 **Cookbook-locked invariants**（下游不得覆盖；变更走 ADR amend）。Range-locked knobs（下游设值、Cookbook 限边界）归 Layer 2 各 recipe Tuning Knobs。

### Cookbook-locked invariants

| Invariant | 锁定值 | 锁定原因 | 强制方式 |
|---|---|---|---|
| `audio_lead_ms` | **35 ms** | 三方同步契约，跨 5+ 系统共用 | registry constant + Core Rule 3 |
| `audio_sync_window_total_ms` | **50 ms**（±25 ms）| 含人类听觉同步阈值 ±15 + 测量噪声 ±5 + 帧抖动 ±5；OQ-1 spike 实测 σ ≤ 10 ms 才算成立 | F-1 + AC-01a |
| Silence ≥ 100 ms（Core Rule 5）| **100 ms** | 配方间物理隔离，节奏感保证 | Core Rule 5 + 五相位结构 |
| F-4 active_particles_total 上限 | **48**（blend_mix 路径，条件式依赖 ADR-R）| Mobile renderer iOS 安全上限 | Layer 2 F-4 表 + AC-05 |
| F-5 total_juice_ms 上限 | **1500 ms** | anti-bloat 平衡值；超出挤压玩家呼吸 | Layer 2 F-5 + AC-06 |
| CTL 词汇表 8 个术语 | **anticipation / squash & stretch / follow-through / screen shake / time-scaling / color flash / particles / layered audio** | Cookbook 共同语言；新增术语走 ADR | Core Rule 6 |
| 配方 ID 命名 `JC-R1..R7` | 锁定（顺号扩展 JC-R8..）| 下游 cite 锚点稳定性 | Core Rule 2 + AC-12 |
| Hook signal 顺序优先级 | `lever_lock > reveal_pop > shred_start > shred_pulse > product_land > shelf_add > lever_pull_start` | 同帧冲突时混音抢占 | §3 Hook 优先级表 |
| `juice_strength_ratio_min` | **1.5** | Core Rule 10 戏剧弧线层级量化（JC-R5 / JC-R2）| Core Rule 10 + F-strength + AC-strength-ratio |
| `MIN_VISIBLE_OFFSET_PX` | **0.5 px** | retina mobile sub-pixel snap 防御 | F-7 clamp + AC-F7-bound |
| Pillar 4 重内容 → JC-R6 振幅 | **不变**（不分支） | 反 attention-manipulation 设计 | Core Rule + AC-pillar4-invariance |
| F-6 reduce_motion_factor 作用域 | **只振幅，不时长** | Apple HIG 一致 | F-6 接口 + AC-reduce-motion-scope |
| iOS prefers-reduced-motion bool → factor | **true → 0.0, false → 1.0**（MVP 硬映射）| 前庭功能障碍 MVP 无障碍承诺 | F-6 iOS 接入 + AC-iOS-reduce-motion |
| Cookbook 不订阅 Lifecycle 信号 | 锁定（Core Rule 4）| ADR-0002 反支柱结构守护 | Core Rule 4 + AC-no-lifecycle-subscribe |
| Required Minimum / Forbidden 对称 | 锁定（Core Rule 8）| 防 Pass A "形式修复" 模式复发 | Core Rule 8 + AC-symmetric-completeness（每 Layer 2 PR）|

### 全局开关（Accessibility GDD 拥有）

| Toggle | 类型 | 默认 | 谁拥有 |
|---|---|---|---|
| `reduce_motion_factor` | enum {0.0, 0.5, 1.0} | 1.0 | Accessibility System GDD (#16, v1.0) — 三档启用条件；MVP 阶段 iOS bool 硬映射 |
| `disable_all_particles` | bool | false | Accessibility System GDD (#16, v1.0) |
| `mute_haptic`（settings.haptic_enabled 反值）| bool | false | HapticSystem (settings slice owner) |

Layer 1 在运行时通过 F-6 公式响应这些 toggle，但 **不主动检测它们**——降级由调用方（Layer 2 recipe 或 Accessibility System）在每次配方触发前传入参数。MVP iOS bool 硬映射例外（F-6 接入条款）。

### Range-locked knobs（仅指向 Layer 2，本节不展开）

具体 range-locked knobs（s_compressed / s_overshoot / T1/T2/T3 / base_amp_px / HOLD_MS / DECAY_MS / n_pulses / burst_count / lifetime_ms / anticipation_ratio）归 Layer 2 `juice-recipes.md` 各 recipe Tuning Knobs。Layer 1 不重复列举，避免双 SSOT 漂移风险。

## Acceptance Criteria

> Layer 1 AC 设计原则（修 Pass A re-review qa-lead 所有 BLOCKING）：
> - **AC 全部 GUT + 精确 grep + manual real-device 三路径，每 AC 至少一项自动化**
> - **数值不等式由 GUT 常量断言验证**，不依赖 grep（grep 不能验 N ≥ 8）
> - **存在性 grep 必须给出精确正则模式**（不依赖 "审查者直觉"）
> - **不依赖 Wave 3 未存在的类**——所有 Layer 1 AC 在 Wave 2 即可执行
> - **同一现象只测一次**——AC-01a / AC-01b 各测不同语义（speaker t_emit 对齐 vs BT 主观体验阈值），不重复

---

### AC-01a：F-1 同步契约 — 扬声器路径

**GIVEN** iOS 真机使用 **内置扬声器** 输出，OQ-1 spike 已落地（`AudioServer.get_output_latency()` σ ≤ 10 ms 验证通过），下游 GDD 实现代码调用 `AudioSystem.play(sfx_key)` 并按公式记录 t_emit
**WHEN** 视觉 **T1 压缩关键帧**（squash 极值帧）渲染时刻 `t_render` 被测量
**THEN** `|t_render - (t_emit + 35)| ≤ 25 ms` 对所有有 T1 压缩帧的配方均成立（**适用范围**：JC-R2 / JC-R3 / JC-R5 / JC-R6 / JC-R7；**JC-R1 不适用** — Forbidden 禁用 squash 故无 T1 帧；**JC-R4 不适用** — 脉冲配方无主体 squash）

- **执行路径**：Manual real-device test（iOS 真机内置扬声器 + Xcode Instruments GPU Frame Capture 记录 t_render + Godot `AudioServer.get_output_latency()` 推算 t_emit）；须由熟悉 iOS audio pipeline 的工程师执行
- **Gate Level**：**BLOCKING**
- **来源**：F-1 · Core Rule 3 + 5 · OQ-1 spike 前置依赖
- **备注**：本 AC 锚定 t_emit；t_emit → 扬声器 12-22 ms 路径延迟由 `platform_audio_output_latency_ms` 表覆盖（仅信息性）

### AC-01b：BT 路径主观体验阈值（**重写**，修 Pass A re-review qa-lead #2）

**GIVEN** iOS 真机接 AirPods Classic 或 AOSP BT 经典输出，玩家正常游玩核心循环（不使用测量工具）
**WHEN** 完整执行 JC-R2 lever_lock → JC-R5 reveal_pop 各 10 次
**THEN** 主观打分（1-5 分量表）："视觉与声音感觉同步" ≥ **3.5 分**（可接受阈值）

- **执行路径**：Manual real-device test（戴 BT 耳机 + tester 打分 + 结果记录在 `production/qa/evidence/`）
- **Gate Level**：**ADVISORY**（不阻塞 MVP 发布；< 3.5 分触发 Audio System v1.0 BT 补偿路径评估）
- **来源**：F-1 platform_latency 表 · AC-01a 互补（**测主观体验阈值，不重复 t_emit 验证**）
- **备注**：本 AC 不测 t_emit（与 AC-01a 重复无意义）；测的是 t_perceive 主观可接受性

---

### AC-strength-ratio：Core Rule 10 戏剧弧线层级量化

**GIVEN** Layer 2 recipe JC-R2 与 JC-R5 的参数常量已在 `juice-recipes.md` 落地
**WHEN** GUT 测试代入 F-strength 公式计算
**THEN** `F_strength(JC-R5) / F_strength(JC-R2) ≥ 1.5`（断言精度 0.001）；JC-R5 strength 必须 ≥ JC-R1..R7 中其余六者 strength

- **执行路径**：**Automated unit test (GUT)** — 直接代入 Layer 2 配方常量执行 F-strength 公式断言
- **Gate Level**：**BLOCKING**
- **来源**：Core Rule 10 · F-strength
- **备注**：Layer 2 任何 recipe 参数修订 PR 必须重跑本 AC（Core Rule 8 对称强制）

---

### AC-02：五相位完整性 — 跨配方

**GIVEN** 每条 Layer 2 配方对应的 hook signal 被 emit
**WHEN** QA tester 在 Godot 编辑器调试场景中逐一触发 7 个 hook signal
**THEN** 每条配方均依序经历 Anticipation → Action → Impact → Follow-through → Silence 五阶段，**任何相位均不跳过、不乱序**，Silence 尾 ≥ 100 ms（动画帧计数验证）

- **执行路径**：Manual real-device test + Code review check（实现代码确认五相位 Tween 链完整）
- **Gate Level**：**BLOCKING**
- **来源**：Core Rule 5 · §3 五相位结构

---

### AC-05：跨配方粒子同帧上限 (F-4)

**GIVEN** MVP 最坏场景：JC-R3 (burst 12) 与 JC-R4 (节点池 2 批重叠 = 8) 同帧活跃
**WHEN** QA tester 在 Godot 调试场景同时触发 `shred_start` + `shred_pulse`，读取 `CPUParticles2D` 活跃粒子数
**THEN** 任意单帧 `active_particles_total ≤ 48`（blend_mix 路径）；blend_add 路径单源 ≤ 50% 上限

- **执行路径**：**Automated unit test (GUT)**（mock particle count 在极端场景下验证 F-4 公式不越限）+ Manual real-device test（iPhone 真机 Profiler 确认无粒子池溢出）
- **Gate Level**：**BLOCKING**
- **来源**：Layer 2 F-4 表 · Cookbook-locked invariant active_particles_total ≤ 48

---

### AC-06：单循环 Juice 总时长上限 (F-5)

**GIVEN** 完整一次核心循环（JC-R1 → R2 → R3 → R4×5 → R5 → R6 → R7）被触发
**WHEN** GUT 测试代入 Layer 2 配方时长常量累加
**THEN** `total_juice_ms ≤ 1500 ms`；default 参数下计算结果 ≈ 1260 ms（Silence 尾不计入）

- **执行路径**：**Automated unit test (GUT)**（直接代入 Layer 2 配方常量执行 F-5 公式断言）
- **Gate Level**：**BLOCKING**
- **来源**：Layer 2 F-5 · Cookbook-locked invariant total_juice_ms ≤ 1500

---

### AC-10：Hook Signal 重叠时下游状态机正确 Gate

**GIVEN** 任一配方 Silence 尾尚未结束（< 100 ms）
**WHEN** 下游 GDD 状态机收到新的优先级 ≤ 当前配方的 hook signal
**THEN** 状态机保持当前状态，新 hook signal **不触发**新配方；状态机 gate 逻辑在 godot-gdscript-specialist code review 时可验证（状态转换条件显式检查上一配方 DONE 状态）

- **执行路径**：Code review check + Manual real-device test（快速连续操作验证无视觉叠加混乱）
- **Gate Level**：**BLOCKING**
- **来源**：Edge Case Hook 类 · Core Rule 5 + Hook 优先级表
- **备注**：Wave 3 各下游 GDD 落地后 per-GDD 分批执行

---

### AC-pillar4-invariance：反 attention-manipulation 不变性 (Core Rule + 升 BLOCKING)

**GIVEN** Layer 2 JC-R6 (`product_land`) 实现代码已落地
**WHEN** **GUT injection mock**：构造测试 fixture 模拟 Pillar 4 heavy / light 两种状态（不依赖 Text Input GDD 类——使用项目级 fixture `pillar4_content_state.gd`，Layer 1 提供占位接口约定）
**THEN**：
1. 两种状态下 JC-R6 Tween 的 `scale` 最终值完全相等（断言精度 0.0001）
2. 两种状态下 `Camera2D.offset` 写入序列完全相同
3. 实现文件 **静态 grep** 扫描：无任何与"重内容判定"相关的条件分支模式：
   - 模式 1: `if .*(heavy|重内容|pillar.*4|content_weight|intensity_level).*:`（含中文）
   - 模式 2: `match .*pillar`
   - 模式 3: `assert.*heavy`（用于排除测试代码假设）
   - **任一模式 grep 命中 → BLOCKING fail**

- **执行路径**：**Automated unit test (GUT)** + **CI grep static check** + Manual real-device test
- **Gate Level**：**BLOCKING**（B9 升 BLOCKING）
- **来源**：Edge Case Pillar 冲突类 · Cookbook-locked invariant "Pillar 4 → JC-R6 振幅不变" · Layer 1 反 attention-manipulation 立场
- **前置约束**：Layer 1 提供占位接口 `pillar4_content_state.gd`（mock 接口契约）；Text Input GDD 落地后接入实际 state

---

### AC-iOS-reduce-motion：iOS prefers-reduced-motion 接入路径

**GIVEN** iOS 真机
**WHEN** GUT injection mock `iOS_prefers_reduced_motion = true / false` 两态
**THEN**：
- `true` → 任一配方触发后所有 visual amplitude 实际值 = 0（squash = 1.0 / shake = 0 / anticipation = 0）
- `false` → 任一配方触发后 visual amplitude = base value（无缩放）
- 两态下 Audio `AudioSystem.play()` 调用次数 + 时序完全相同（reduce motion 不关音频/触觉，§2 三层承诺 #3）

- **执行路径**：**Automated unit test (GUT) injection** + Manual real-device test（iOS 真机系统设置开关）
- **Gate Level**：**BLOCKING**（修 Pass 2 B14）
- **来源**：F-6 iOS 接入路径 · Edge Case Accessibility 类 · Apple HIG

---

### AC-reduce-motion-scope：F-6 作用域不变量

**GIVEN** `reduce_motion_factor = 0.5` 任一配方触发
**WHEN** GUT 测量 Tween 时长与振幅
**THEN**：
- 视觉振幅各项 = base × 0.5（验证范围内）
- Tween 时长 (T1 / T2 / T3 / HOLD_MS / DECAY_MS) **完全不变**（断言精度 1 ms）
- F-5 total_juice_ms **完全不变**

- **执行路径**：**Automated unit test (GUT)**
- **Gate Level**：**BLOCKING**
- **来源**：F-6 作用域约束 · Apple HIG `prefers-reduced-motion` 默认不缩时长

---

### AC-no-lifecycle-subscribe：Core Rule 4 守护

**GIVEN** Layer 2 任一 recipe 实现文件提交 code review
**WHEN** godot-gdscript-specialist 审查实现文件
**THEN** 实现代码 **不包含** 以下任一模式（精确 grep）：
- `application_paused` 字符串引用
- `application_resumed` 字符串引用
- `_notification(NOTIFICATION_APPLICATION_PAUSED)` 或 `NOTIFICATION_APPLICATION_RESUMED`
- `Lifecycle.connect(`（订阅 Lifecycle Autoload 信号）

- **执行路径**：**CI grep static check**
- **Gate Level**：**BLOCKING**
- **来源**：Core Rule 4 · ADR-0002 反支柱结构守护

---

### AC-F7-bound：F-7 公式范围一致性 (Core Rule 8 验证)

**GIVEN** F-7 公式
**WHEN** GUT 测试代入 4 个边界组合（最小×最小、最大×最大、最小×最大、最大×最小）
**THEN** 所有 4 个输出 ∈ [0.5, 1.8]；MIN_VISIBLE_OFFSET_PX clamp 在 input × ratio < 0.5 时生效

- **执行路径**：**Automated unit test (GUT)**
- **Gate Level**：**BLOCKING**
- **来源**：F-7 边界代入验证表 · Core Rule 8 四维度对称强制

---

### AC-symmetric-completeness：Core Rule 8 PR 检查（每 Layer 2 PR 强制）

**GIVEN** Layer 2 `juice-recipes.md` 任一 recipe 修订 PR
**WHEN** PR description 提交
**THEN** PR description **必须包含** 四维度变更影响矩阵：

```markdown
| 维度 | 本次 PR 是否触及 | 如未触及，理由 |
|---|---|---|
| Forbidden | ☐ Yes ☐ No | |
| Required Minimum | ☐ Yes ☐ No | |
| AC 覆盖 | ☐ Yes ☐ No | |
| 输入/输出 ranges | ☐ Yes ☐ No | |
```

任一维度 No 但理由空白 → PR 拒绝合并

- **执行路径**：PR template + GitHub Actions 校验 PR body（regex 检查矩阵存在 + 4 行非空）
- **Gate Level**：**BLOCKING**
- **来源**：Core Rule 8 元约束（防 Pass A "形式修复" 模式复发）

---

### AC-12：下游 GDD Tuning Knobs 含 JC-R 引用 ID（Wave 3 per-GDD 分批执行）

**GIVEN** Lever Interaction (#8) / Shred Process (#9) / Silhouette Reveal (#11) / Shelf Collection (#12) / Onboarding (#15) 各自 GDD **完成初稿**
**WHEN** Design review 审查各 GDD 的 Tuning Knobs 章节
**THEN** 每份 GDD 在 Tuning Knobs 中明确 cite 其对应配方 ID（Lever cite `JC-R1` + `JC-R2`；Shred cite `JC-R3` + `JC-R4`；Silhouette cite `JC-R5` + `JC-R6`；Shelf cite `JC-R7`；Onboarding cite `JC-R1..R7` 并声明 JC-R7 enhanced 偏离）

- **执行路径**：Design review check（Wave 3-6 GDD 完成时逐份核查）+ Code review check（godot-gdscript-specialist 在 PR 内确认 cite 存在）
- **Gate Level**：**BLOCKING（DEFERRED — Wave 3 per-GDD 关口生效；Wave 2 不阻塞 Layer 1 story 关闭）** — 修 Pass A re-review qa-lead #6 时序幻觉问题
- **来源**：Core Rule 2 · Core Rule 6 · Dependencies 下游 GDD 表

---

### 覆盖度汇总

| 要求类别 | 覆盖 AC | Gate |
|---|---|---|
| 同步契约 F-1 / speaker | AC-01a | BLOCKING |
| 同步契约 F-1 / BT 主观 | AC-01b | ADVISORY |
| 戏剧弧线层级 (Core Rule 10) | AC-strength-ratio | BLOCKING |
| 五相位完整性 (Core Rule 5) | AC-02 | BLOCKING |
| 跨配方粒子上限 (Layer 2 F-4) | AC-05 | BLOCKING |
| 单循环总时长 (Layer 2 F-5) | AC-06 | BLOCKING |
| Hook 重叠抢占 | AC-10 | BLOCKING |
| Pillar 4 反 attention-manipulation | AC-pillar4-invariance | BLOCKING |
| iOS Reduce Motion 接入 | AC-iOS-reduce-motion | BLOCKING |
| F-6 作用域 (振幅 only) | AC-reduce-motion-scope | BLOCKING |
| Lifecycle 不订阅 (Core Rule 4) | AC-no-lifecycle-subscribe | BLOCKING |
| F-7 范围一致性 | AC-F7-bound | BLOCKING |
| Core Rule 8 PR 强制 | AC-symmetric-completeness | BLOCKING |
| 下游 cite 强制 (Wave 3 DEFERRED) | AC-12 | BLOCKING (DEFERRED) |

**共 14 条 Layer 1 AC**：13 BLOCKING + 1 ADVISORY；其中 1 条 DEFERRED 至 Wave 3 per-GDD 关口。

### QA 执行路径分布

| 执行路径 | 适用 AC |
|---|---|
| **Automated unit test (GUT)**（含 injection mock）| AC-strength-ratio, AC-05, AC-06, AC-pillar4-invariance, AC-iOS-reduce-motion, AC-reduce-motion-scope, AC-F7-bound |
| **CI grep static check** | AC-pillar4-invariance, AC-no-lifecycle-subscribe |
| **PR description regex check (GitHub Actions)** | AC-symmetric-completeness |
| Manual real-device test | AC-01a, AC-01b, AC-02, AC-10, AC-iOS-reduce-motion, AC-pillar4-invariance |
| Code review check | AC-02, AC-10, AC-no-lifecycle-subscribe, AC-12 |
| Design review check | AC-12 (Wave 3 per-GDD) |

**所有 13 BLOCKING AC 中 12 条含自动化路径（GUT 或 grep 或 PR regex），仅 AC-12 全手动（且 DEFERRED）。修 Pass A re-review qa-lead 所有自动化不足 BLOCKING**。

## Open Questions

> Layer 1 范围内 Open Questions。Layer 2 各 recipe 内部 OQ 归 `juice-recipes.md`。

| ID | 问题 | 归属 | 目标解决期 | 阻塞性 |
|---|---|---|---|---|
| **OQ-1** | `AudioServer.get_output_latency()` 推算 t_emit 的实测抖动 σ 在 iPhone XS / iPhone SE 2nd gen 上的真实值。**σ ≤ 10 ms** 才算 F-1 公式成立。同时校准 audio_lead_ms 中位数（当前估算 35 ms，可能在 25-45 ms 真实区间）。| Owner: technical-director；executors: gameplay-programmer + godot-specialist | **Wave 3 启动前 1-2 天 spike**（**硬阻塞**）| ✅ BLOCKING — σ > 10 ms 触发 Layer 1 锚点回炉 |
| **OQ-strength-formula** | F-strength 权重 [×20 / 直接值 / ÷10 / ÷4] 首次定义，未经真机校准。Wave 3 启动前 OQ-1 spike 期间附带 5-10 人小规模主观验证：tester 对 7 个配方打 1-5 分"轰击感"分数，验证 strength 排序 = 主观排序。 | Owner: game-designer；executor: qa-lead + 5-10 tester | Wave 3 启动前 spike 期间（与 OQ-1 合并执行）| 不阻塞 MVP，**Wave 3 启动前应校准**；不一致 → ADR amend 调整公式权重 |
| OQ-renderer | Mobile renderer vs Forward+ 决议（ADR-R）。影响 Core Rule 7 条件式 Forbidden 条款的具体含义（Glow / blend_add 是否解禁）。 | Owner: technical-director | **Wave 3 启动前**（**硬阻塞**）| ✅ BLOCKING — Layer 1 Core Rule 7 条件式条款无 grounding 直到 ADR-R 落地 |
| OQ-pillar4-fixture | Layer 1 AC-pillar4-invariance 引用占位 fixture `pillar4_content_state.gd`。需在 Wave 2 期间创建该 fixture（占位接口契约），供 Wave 3 Text Input GDD 落地后接入实际 state。fixture 内容应包含什么？ | Owner: qa-lead | Wave 2 内（Layer 1 收口前）| 不阻塞 Layer 1 design review，阻塞 AC-pillar4-invariance 自动化执行 |
| OQ-iOS-bridge | Godot 4.6 读取 iOS `prefers-reduced-motion` bool 的具体接入路径——通过 `Engine.has_singleton("iOS")` + 自定义 GDExtension 桥接，还是用社区 plugin？影响 AC-iOS-reduce-motion 执行。 | Owner: godot-gdextension-specialist + technical-director | Wave 3 启动前（与 OQ-1 spike 合并）| 不阻塞 Layer 1 design review，阻塞 AC-iOS-reduce-motion 自动化执行 |
| OQ-deprecate-cookbook | `juice-cookbook.md` 转 DEPRECATED stub 时机：Layer 1 落地后立即转？还是等 Layer 2 落地后双拆完成再转？ | Owner: user | Layer 2 起草启动时决定 | 不阻塞，文件管理决策 |

**关键 OQ 分组**：

- **Wave 3 硬阻塞**：OQ-1（F-1 测量精度 spike）+ OQ-renderer（ADR-R 决议）。两者任一未解决 → Wave 3 不可启动。
- **Wave 3 前应校准（不硬阻塞）**：OQ-strength-formula（F-strength 主观验证）+ OQ-iOS-bridge（接入路径）。
- **Layer 1 内部**：OQ-pillar4-fixture（占位接口）+ OQ-deprecate-cookbook（文件管理）。

### Wave 3 启动 gate（Layer 1 + Layer 2 联合）

Layer 1 落地不等于 Wave 3 解锁。Wave 3 启动前必须 **全部** 满足：

1. ✅ Layer 1 `/design-review` PASS
2. ✅ Layer 2 `/design-review` PASS
3. ✅ OQ-1 spike σ ≤ 10 ms
4. ✅ ADR-R Renderer 决议（OQ-renderer）
5. ✅ OQ-strength-formula 真机主观验证一致（或经 ADR amend 调整后一致）

任一项 fail → Wave 3 不解锁。本节是 Wave 3 解锁 hard gate 的 SSOT。
