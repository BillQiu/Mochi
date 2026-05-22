# Juice Cookbook — Review Log

> 评审历史。最新评审在最上方。

---

## Revision Pass A — 2026-05-22 (Pass 1 修订收口；Pass 2 之前完成)

**Driver**: User decision "B1 → B2 → B5 → R11 → R12 → 其余 BLOCKING"（仅覆盖 Pass 1 项）
**Mode**: Direct GDD edit（修订范围严格限定在 Pass 1 findings，未触 Pass 2 新增 B13-B17）
**Files modified**: design/gdd/juice-cookbook.md (header changelog + Player Fantasy 内在张力 + Section C Required Minimum + F-1 重写 + States and Transitions + F-3/F-4/F-7 + Edge Cases + Dependencies + AC + Open Questions)

### Pass 1 - 12 BLOCKING + 2 Recommended 落地状态

| ID | 项 | 状态 | 落点 |
|---|---|---|---|
| B1 | F-1 锚点定义 (t_emit) + platform_latency 表 | ✅ Done | F-1 重写；新增表 5 行（iOS/Android × speaker/BT） |
| B2 | F-3 Impact = T1 压缩帧（overshoot 归 Follow-through） | ✅ Done | States and Transitions 表 + F-3 同步窗口对齐子节 |
| B3 | AC-01 拆分 a (speaker) / b (BT) | ✅ Done | AC-01a BLOCKING + AC-01b ADVISORY |
| B4 | F-4 overlap_factor 公式 | ✅ Done | `floor(lifetime/interval) + 1`；JC-R4 = 2 ✅ |
| B5 | JC-R4 实现路径 + Forbidden 矛盾 | ✅ Done | CPUParticles2D 节点池 5 节点 × amount=4；删除 emit_one_shot |
| B6 | 粒子上限 SSOT (32/48/>48) | ✅ Done | Core Rule 7 + JC-R3 Forbidden + AC-11 全部对齐 F-4 表 |
| B7 | 48 + blend mode 约束 | ✅ Done | F-4 表注：blend_add → 50% 上限；Production Sprint 0 profile flag |
| B8 | Mobile renderer Forbidden 条件式 | ✅ Done | JC-R3/R4/R6 Forbidden 加 "如最终选 Mobile renderer" 前置条件 |
| B9 | AC-13 升 BLOCKING + GUT injection | ✅ Done | injection mock + grep + manual 三路径 |
| B10 | F-7 Output Range [0.5, 1.8] | ✅ Done | 下限 0.1 → 0.5（防 sub-pixel snap） |
| B11 | Core Rule + Tween.set_parallel(true) | ✅ Done | 新增 Core Rule 8 |
| B12 | OQ-1 spike 时机提前 | ✅ Done | Production Sprint 1 → Wave 3 启动前 1-2 天 |
| R11 | Player Fantasy 内在张力 + Required Minimum 对称清单 | ✅ Done | "内在张力（Pillar Tension）" 小节 + Section C 七配方 Required Minimum 子项 + AC-14 |
| R12 | Onboarding 前 3 次 shelf_add enhanced JC-R7 | ✅ Done | Interactions 表 + Edge Case + Dependencies 表 + `first_run_shelf_add_count` 持久化合同 |

### AC 数量变化

- 第一次评审时：13 条（8 BLOCKING / 5 ADVISORY）
- 修订后：**15 条**（11 BLOCKING / 4 ADVISORY）
- 新增：AC-01a/01b（拆分自 AC-01）、AC-14（Required Minimum 存在性）
- 升级：AC-13 ADVISORY → BLOCKING（B9）

### 未触及（Pass A 范围外）

- Pass 1 R1–R10（除 R11/R12）：用户优先级未覆盖
- Pass 1 4 Defer / 3 Rejected：按评审原意处理（不动）
- **Pass 2 新增 B13–B17 + R13/R14**：Pass A 完成时 Pass 2 评审已并行写入 review-log，但 Pass A 编辑窗口已锁定 Pass 1 scope。**移交用户决策是否启动 Revision Pass B**。

### Revision Pass A 后状态

GDD 顶部 status: "Revised (2026-05-22 — 12 BLOCKING + R11 + R12 全部修订完成)"
**Pass 2 verdict 仍未解除**（B13-B17 + R13/R14 未处理）；Wave 3 解锁条件取决于 Pass 2 是否走 Revision Pass B。

---

## Review — 2026-05-22 (Pass 2, cross-review extension) — Verdict: MAJOR REVISION NEEDED (confirmed + extended)

**Scope signal**: XL（升级自 Pass 1 的 L —— 因 Pass 2 新增 Cookbook 拆分 Layer 1/2 提议 + WCAG Level A 合规阻塞）
**Mode**: Full (Phase 3b 平行 spawn **8 specialists** + creative-director 终审)
**Specialists**: game-designer / systems-designer / qa-lead / **gameplay-programmer**（新增）/ audio-director / performance-analyst / godot-specialist / **accessibility-specialist**（新增）/ creative-director
**Specialists 新增**: 相对 Pass 1 增加 gameplay-programmer + accessibility-specialist 两名 — 这两位贡献了本轮全部 net 新发现
**Findings 数量**: 5 顶部 BLOCKING（与 Pass 1 重叠 + 扩展）+ ~10 Recommended
**Prior verdict resolved**: No — Pass 1 verdict (MAJOR REVISION NEEDED, 12 BLOCKING) 仍未修复；Pass 2 在此基础上补充

### 与 Pass 1 重叠的关键发现（确认 Pass 1 结论仍站得住）
- F-1 audio_onset 锚点未定义 = Pass 1 B1（systems-designer M-4 + audio-director H-2 再次提出）
- F-4 ceil() 边界数学错误 = Pass 1 B4（systems-designer H-1 再次给出 floor()+1 修正）
- F-4 48 颗"猜的"无 profile 数据 = Pass 1 B7（performance-analyst H-1 + L-1 量化返工成本 2-3 设计周期）
- F-7 sub-pixel 不可见 = Pass 1 B10（systems-designer H-2 进一步指出与已写配方 4 px 自相矛盾）
- AC 不可执行（约 6 条） = Pass 1 部分（qa-lead 系统性指出 13/13 中 6 条 + AC-12 时序错位 + AC-13 反向断言）

### Pass 2 Net 新发现（Pass 1 未捕获，需追加 BLOCKING/Recommended）

**新 BLOCKING — B13** [accessibility-specialist H-1]：**WCAG 2.1 Level A 法律风险**
JC-R3 +40% 亮度 + JC-R5 color flash **完全没有 SC 2.3.1 Three Flashes 阈值豁免计算**。Cookbook 整篇无光敏安全声明。Apple App Store 审查潜在拒绝。Pass 1 未覆盖此风险。

**新 BLOCKING — B14** [accessibility-specialist H-2/H-3]：**iOS reduce motion 接入路径在 MVP 缺失**
F-6 接口存在但 iOS `prefers-reduced-motion` bool **无人消费**——前庭功能障碍用户在 MVP 阶段无任何方式关闭 shake/squash。Pass 1 OQ-7 把此问题整体推给 v1.0，Pass 2 认为 MVP BLOCKING（系统 bool → factor 硬映射不需等 v1.0 GDD）。

**新 BLOCKING — B15** [godot-specialist H-2 + gameplay-programmer + performance-analyst 三方一致]：**AnimationPlayer.speed_scale=0 freeze 在 Godot 4.6 技术上无效**
`speed_scale = 0.0` 只冻该 AnimationPlayer 轨道，**Tween 完全不受影响**。JC-R5 freeze frame 在 Core Rule 7 当前措辞下必然失败。正确实现：`tween.pause() + create_timer() + tween.play()`。Pass 1 godot-specialist 未单独 spawn，所以漏掉这个技术错误。**OQ-3 立即修改 Cookbook 措辞**，不可推迟。

**新 BLOCKING — B16** [game-designer X-1]：**七配方覆盖度 vs §B 承诺错位**
Cookbook 仅覆盖 22-30 秒循环中 ~5-6%（7 个 hook 钉点 ~1260 ms）；剩余 ~94% 空白时间（idle / drag / hover / 等待）由谁负责未声明。§B "反寡淡" 是 100% 时间承诺，Cookbook 是 5% 系统。Pass 1 R5 提议新增 JC-R0 中止拉杆 + R11 Pillar Tension 承认 → Pass 2 升级为根本性结构问题，建议在 §B 加 Out-of-Scope 显式声明（Cookbook 仅覆盖 hook 时刻，其余由 Wave 1 idle/hover 系统对应 GDD）。

**新 BLOCKING — B17** [audio-director H-3]：**audio specs ↔ Cookbook 跨文档实质裂缝**
- VA-6 "EQ sidechain fallback" 与 BGM direction §4 "BGM 零动态" 实质矛盾（sidechain 即动态 EQ）
- JC-R3 两轨 onset 错开 30 ms 但 F-1 audio_onset_t_ms 参照哪一轨未指定
- 此前声称的 "audio specs ↔ Cookbook §3.4/§4 五项对齐通过" **部分不真实**（2 项形式对齐 + 1 项实质裂缝）
- Pass 1 未做跨文档 audio specs ↔ Cookbook 一致性审核（因 audio specs 当时尚未起草）

**新 Recommended — R13** [gameplay-programmer M-1]：**Core Rule 1 "no helper" 应松动**
允许 `static func juice_utils.gd` 纯函数（不是 Autoload）。论证：7 倍 Tween 链复制 = 7 倍 bug 表面积；纯洁性服务于"无隐藏行为"，static func 是显式无状态。Pass 1 未触及此架构层张力。

**新 Recommended — R14** [game-designer + gameplay-programmer + accessibility 三方反对]：**删除 Onboarding JC-R5 medium→large 偏离**
违反 Pillar 2 一致性（"第一次特殊"= 反 pillar）+ 调用路径无解 + reduce motion 用户等效补偿缺失。三个 specialist 独立得出反对结论。

### Creative Director Pass 2 最终诊断（结构性反思）

> Pass 1 把 Cookbook 当合同审，Pass 2 在审中发现 **Cookbook 想同时扮演"配方书"和"质量合同"两种角色，但抽象层级不兼容**：
> - 作为配方书太严格（Core Rule 1 / F-4 硬 48 / Engine.time_scale 全禁）→ 工程师绕路
> - 作为合同太软（F-4 猜的 / F-7 自相矛盾 / AC 不可测）→ 评审无法裁决
>
> **建议拆为 Layer 1（合同 ~200 行：§B 承诺 / Core Rules / F-1 时序 / 跨 GDD AC / WCAG 合规）+ Layer 2（配方 ~600 行：R1-R7 / F-3..F-7 / Tuning Knobs / VA-1..VA-7）**。
>
> Pass 1 Convergence Point #7 已经接近这个洞察（"Cookbook 回答了错误的问题，只有 Forbidden 列表没有 Required Minimum"）—— Pass 2 把结构性提议形式化。
>
> **Pass 1 + Pass 2 单一最致命 Blocker = B15（freeze 技术错误）**：先于 B1（audio_onset 锚点）—— 因为 freeze 是当前 Cookbook 措辞下必然失败的 API 调用，而 B1 是定义模糊；前者必修，后者补义。

### Pass 2 Verdict 维持 MAJOR REVISION NEEDED；修复需要顺序

1. **B13/B14（WCAG + iOS reduce motion）**——MVP BLOCKING，无商量，先做
2. **B15（freeze 技术错误）**——立即改 Cookbook 措辞
3. **B16/B17（覆盖度 + 跨文档裂缝）**——结构性变更，与拆 Layer 1/Layer 2 同步推进
4. **Pass 1 B1-B12**——按 Pass 1 原优先级执行
5. **R13/R14 + Pass 1 R1-R12**——并行处理

### 文件链接

- 评审对象: design/gdd/juice-cookbook.md（851 行）
- 评审报告: 本文件
- 跨文档对照: design/audio/sfx-selection-spec.md / design/audio/bgm-direction.md（Pass 2 期间已起草，触发 B17 跨文档检查）
- 上一轮报告位置: 本文件 ↓（Pass 1 块在下方）

---

## Review — 2026-05-22 (Pass 1) — Verdict: MAJOR REVISION NEEDED

**Scope signal**: L (1.5–2.5 工作日)
**Mode**: Full (Phase 3b 平行 spawn 6 specialists + creative-director 终审)
**Specialists**: game-designer / systems-designer / qa-lead / audio-director / performance-analyst / godot-specialist / creative-director
**Findings**: 97 条（13+14+20+13+10+15+12，creative-director 终审收拢）
**Blocking items**: 12 | **Recommended**: 12 | **Defer**: 4 | **Rejected**: 3
**Prior verdict resolved**: First review

### 7 大跨域 Convergence Points

1. **F-1 同步契约根本性破裂（CRITICAL）**: t_call vs t_emit vs t_perceive 三个时间未区分 → 视觉峰值与音频/触觉对齐定义不清。同时 F-3 keyframe 布局让 JC-R5 拉伸峰值在 t=83 ms，超出 F-1 [20,50] ms 窗口 33-63 ms。AirPods 路径 + 45 FPS 降频使 AC-01 ±15 ms 物理不可达。Tween 默认 serial 无 set_parallel(true) 文档化。
2. **F-4 粒子契约数字与 API 不可信**: overlap_factor 公式与"实际 2"数学矛盾。48 颗上限无 profile 数据。Core Rule 7 / F-4 / JC-R3 Forbidden 三处数字不一致（≤32 / ≤48 / >48 flag）。JC-R4 引用了不存在的 `emit_one_shot()` API + 同时禁止"新增 burst" — Cookbook 自身不可实现。
3. **Mobile vs Forward+ 渲染器假设错位**: Cookbook 假设 Mobile renderer 但 technical-preferences.md 默认 Forward+ 且渲染器决策推迟到 prototype。Glow / blend_add 的 Forbidden 在 Forward+ 下不成立。
4. **实现模式未指定**: 五相位实现范式（await/Tween/state machine）、CPUParticles2D burst 机制、ease/trans 配对、position_smoothing 关闭 — 三下游 GDD 三种实现，code review 无标准。
5. **OQ-1 audio_lead_ms 校准时机过晚**: 推迟到 Production Sprint 1 → Wave 3-6 全部 GDD 建立在估算上 = 地基松动。建议提前到 Wave 3 启动前 spike。
6. **AC 可测试性问题**: AC-01/07/13 用"目测""明显"违反 GDD 自身原则。AC-13 应升 BLOCKING。AC-11 Forbidden checklist 全靠人工 review 无 CI grep。VA-1..VA-6 + Onboarding flag + OQ-1 校准均无 AC 覆盖。
7. **Player Fantasy 隐性张力（creative-director 独家最严肃发现）**: Cookbook 是"防止过度刺激"的克制法典，但 prototype "寡淡" 证明问题恰恰是刺激不足。Cookbook 回答了错误的问题 — 只有 Forbidden 列表（防 over-juicing），没有 Required Minimum 列表（防 under-juicing）。JC-R2 color flash 禁令让"第一次物理重量感"比揭晓还克制（戏剧弧线倒置）。1500 ms juice + 7×100 ms Silence ≥2 秒强制感知未被分析。JC-R0 中止拉杆 / 输入拒绝 / 冷启动 / pulse 间隔视觉连续性等正常路径反馈空白。

### 12 BLOCKING（Wave 3 启动前必修，按修复优先级排序）

- **B1** [audio-director #5 + gameplay-programmer #6 + creative-director EXISTENTIAL]: F-1 `audio_onset_t_ms` 锚点未定义 — 必须明确 t_emit (perceived) + 提供 platform_latency_compensation 表 (iOS speaker / AirPods / Android)
- **B2** [gameplay-programmer #6 + systems-designer F1-02]: F-3 keyframe 视觉峰值 (JC-R5 83 ms) 与 F-1 窗口数学不一致 — 重新对齐 T1/T2/T3 或修改 F-1 窗口
- **B5** [godot-specialist FIND-02 + gameplay-programmer #4]: JC-R4 引用不存在的 `emit_one_shot()` + 自相矛盾 — 改用 restart()+amount 或解禁 GPUParticles2D 或删除 JC-R4
- **B11** [godot-specialist FIND-09]: Tween 默认 serial — 添加 Core Rule "F-1 引用的多属性 Tween 必须 set_parallel(true)"
- **B12** [audio-director #13 + systems-designer F1-02]: OQ-1 audio_lead_ms 真机校准提前到 Wave 3 启动前 spike (1-2 天)
- **B3** [audio-director #6 + systems-designer F1-02]: AC-01 拆分为 AC-01a (扬声器 ±15ms) + AC-01b (BT ±50ms advisory)
- **B4** [systems-designer F2-03 CRITICAL]: F-4 `overlap_factor` 公式与"实际 2"注释二选一修正
- **B6** [godot-specialist FIND-03]: 粒子上限 32/48/>48 三处统一到单一 SSOT
- **B7** [performance-analyst F-1 BLOCKING]: 48 颗粒子上限真机 profile 后确认 + 增加 blend mode 约束（blend_add ≤24 OR blend_mix ≤48）
- **B8** [performance-analyst F-4 + godot-specialist FIND-04/05]: Mobile renderer Forbidden 条目改写为条件式，依赖 ADR-R (Renderer Choice)
- **B9** [qa-lead F-07]: AC-13 升 BLOCKING + GUT 注入测试验证无 heavy_content 条件分支
- **B10** [systems-designer F7-12 CRITICAL]: F-7 Output Range [0.1, 1.8] 改为 [0.5, 1.8]，或公式加 `max(value, snap_threshold)`

### 12 Recommended Revisions（Approved 前修，可并行）

R1 五相位实现范式声明（Tween + tween_callback 推荐）/ R2 CPUParticles2D 节点池化策略 / R3 F-3 ease 配 TRANS_QUART 说明 / R4 JC-R2 允许单帧低饱和 modulate flash（解决戏剧弧线倒置）/ **R5 新增 JC-R0 中止拉杆配方** / R6 输入拒绝配方 / R7 AC-01/07/13 改为可量化形式 / R8 AC-11 增加 CI grep 静态扫描 / R9 VA-1..VA-6 + Onboarding flag + OQ-1 校准 AC 覆盖 / R10 JC-R5 layered audio 词汇显式声明（故意静默 vs 遗漏） / **R11 Player Fantasy 章节承认 Pillar Tension（1500ms juice vs 10秒反射）** / **R12 Onboarding 前 3 次 shelf_add 强化版**（解决 JC-R7 克制过度）

### 4 Defer to v1.0 / Sprint 1

首次触发 lazy-load hitch / Suspend 中途 await timer process_always（ADR 范畴） / v1.0 JC-R5 large 变体音频枚举 / OQ-2/4 部分（已有答案）

### 3 Rejected by Creative Director

- godot-specialist FIND-08 (position_smoothing must off) — 实现细节，转 ADR
- audio-director #8 (timer 帧抖动) — 与 B1 重复计算
- gameplay-programmer #1 (五相位范式 BLOCKING) — 降为 R1（代码 ADR 范畴）

### Specialist Disagreements 已裁决

- **JC-R2 克制是 bug 还是 feature**: 两位都对，指向不同切面 → R4 允许单帧低饱和 flash + B1/B2 修复同步
- **48 粒子上限**: B7 + B6 合并修复（真机 profile + SSOT 统一）
- **Mobile vs Forward+**: 属 technical-director 决策范畴，Cookbook Forbidden 改写为条件式

### Creative Director 最终诊断

> **单一最致命 Blocker = B1**: F-1 t 锚点定义模糊。修复这一点比修复 AC-01 数值更重要 — 先定义你在测量什么，再决定 tolerance。
>
> **Cookbook 通过文档审查但有可能再次产生"寡淡"**。需补 **Required Minimum 章节**对称 Forbidden 列表，并显式承认 Pillar Tension（R11）。否则 Cookbook 通过评审 → Wave 3-6 严格遵守 → 真机一玩还是寡淡 — 因为 Cookbook 没有定义"足够丰盈"的下限。

### 文件链接

- **评审对象**: design/gdd/juice-cookbook.md (851 行)
- **本次评审报告**: 本文件
- **依赖文档**: design/gdd/audio-system.md (Reviewed) / design/gdd/haptic-system.md (Reviewed) / design/registry/entities.yaml (8 juice_* constants 已注册)
- **Wave 3 启动前置**: 本次评审 B1 / B2 / B5 / B6 / B11 / B12 全部修复
