# Mochi — SFX 选型规格（Spec 层）

**Owner**: sound-designer
**Status**: Complete（§1–§6 全量完成 · 2026-05-22）
**Cross-refs**: design/gdd/audio-system.md · design/gdd/haptic-system.md · design/gdd/juice-cookbook.md · design/registry/entities.yaml

---

## §1 SFX 事件概览

### §1.1 事件总表（按优先级排序）

| 优先级 | 事件 ID | 触发系统 | 循环 | Haptic 对位 | Juice Cookbook 配方 | Pillar | entities.yaml 状态 |
|---|---|---|---|---|---|---|---|
| P1 ★ | `lever_pull` | Lever Interaction | 否 | `lever_lock`（heavy） | JC-R2 | P1 核心 | ✅ 已登记 |
| P1 ★ | `reveal_pop` | Silhouette Reveal | 否 | `reveal_pop`（selection） | JC-R5 | P2 核心 | ✅ 已登记 |
| P2 | `shred_loop` | Shred Process | **是** | `shred_pulse`（light，节奏驱动） | JC-R4 | P2 | ✅ 已登记 |
| P2 | `shred_start` | Shred Process | 否 | `shred_start`（medium） | JC-R3 | P2 | ✅ 已登记 |
| P2 | `shred_end` | Shred Process | 否 | `shred_end`（light） | — | P2 | ✅ 已登记 |
| P3 | `product_land` | Silhouette Reveal | 否 | `product_land`（light） | JC-R6 | P1+P4 | ✅ 已登记 |
| P3 | `lever_drag` | Lever Interaction | **是** | 无（拖拽阶段无触觉配对） | JC-R1 配套 | P1 | ⚠️ **需补登记** |
| P4 | `shelf_add` | Shelf Collection | 否 | `shelf_add`（light） | JC-R7 | P3 | ✅ 已登记 |
| P5 | `BGM_main_loop` | AudioSystem 自管理 | **是** | 无 | — | 氛围层 | ✅ 已登记 |

### §1.2 优先级定义

- **P1**：直接影响 Pillar 1 触感先行核心感受，声音缺失会让玩家本能感到"坏了"
- **P2**：粉碎仪式序列，三件事构成连续叙事弧，缺一显残
- **P3**：揭晓后半段落地感；`lever_drag` 是 P3 而非 P2 因为它是"过程音"而非"打击点"
- **P4**：货架收纳，节拍感收尾
- **P5**：环境氛围层，玩家不主动感知但去掉会觉得空洞

### §1.3 待办登记项

- `lever_drag` 当前仅作为 `_valid_loop_keys` 白名单成员隐式存在（audio-system.md 第 97-99 行），需在 spec 完成后向 entities.yaml 提议补一条 `sfx_lever_drag` 常量。

### §1.4 与 BGM 层级关系（参考 audio-system.md F-2）

所有 SFX 走 SFX 总线（`0 dB` 参考基准，v=1.0），BGM 走 Music 总线（`-12 dB` 相对偏移，`audio_bgm_offset_db` registry 常量）。`lever_pull`、`reveal_pop`、`shred_loop` 三件事是听感层次的骨架：粉碎期间 `shred_loop` 的中低频连续音不得与 BGM 的 200-400 Hz 齿轮质感段频段冲突——频段分配见 §4 冲突矩阵。

### §1.5 未立项事件说明

任务书提到的候选词与实际立项的对应：

| 候选词 | 状态 | 后续 |
|---|---|---|
| `worry_text_commit` | 未立项（Text Input System GDD 未启动） | 留待 Wave 2/3 GDD 阶段 |
| `ui_tap` | 未立项（audio-system.md 第 66 行声明 MVP 中无 UI 音效） | v1.0 加入 |
| `shelf_browse` | 未立项 | v1.0 加入 |
| `empty_state_chime` | 未立项 | v1.0 加入 |

---

## §2 全局 spec 约定

### §2.1 文件格式与技术规格

| 参数 | 规格 | 备注 |
|---|---|---|
| 采样率 | 44100 Hz | Godot iOS 导出推荐标准；避免 48000 Hz（某些 iOS 设备需重采样，引入微量延迟） |
| 位深 | 16-bit PCM（导出交付）；24-bit（录制 / 合成工作文件） | 16-bit 是 Godot `AudioStream` import 默认；工作文件 24-bit 保留动态余量 |
| 编码格式 | OGG Vorbis（循环音）；WAV PCM（短暂一次性 SFX） | OGG 循环点精度更稳定；WAV 在 8 节点对象池中加载延迟更低 |
| 单声道 / 立体声 | 单声道（所有 SFX）；立体声（`BGM_main_loop`） | 手机扬声器通常单声道输出；单声道 SFX 避免 iOS AudioSession 路由差异导致的相位问题；Godot `AudioStreamPlayer`（非 2D）无空间化，立体声浪费带宽 |
| 响度归一化目标 | **-18 dBFS RMS**（非循环 SFX）；**-23 dBFS LUFS 集成响度**（循环音 `shred_loop`、`lever_drag`、`BGM_main_loop`） | -18 dBFS RMS 为 SFX bus 参考电平；各事件电平见 §3；正式校准在 mix 阶段 |
| 峰值上限 | -3 dBFS（真峰值 True Peak） | 防止 iOS 音频输出级削波 |
| 最大文件时长 | 非循环 SFX ≤ 1000 ms；循环 SFX 工作段 ≥ 1000 ms；BGM ≥ 30 s | 对象池节点加载预算；循环点过短会让 CPU 频繁读取循环头 |

### §2.2 命名规范

所有交付文件命名格式：`sfx_[event_id]_v[变体编号].wav` / `sfx_[event_id]_loop.ogg`

示例：
- `sfx_lever_pull_v1.wav`、`sfx_lever_pull_v2.wav`、`sfx_lever_pull_v3.wav`
- `sfx_shred_loop.ogg`
- `sfx_bgm_main_loop.ogg`

循环 SFX（`lever_drag`、`shred_loop`、`BGM_main_loop`）使用 `.ogg` 后缀，在 Godot import 设置中标记 `loop: true` 并手动校准循环点。非循环 SFX 使用 `.wav`，`loop: false`。

### §2.3 变体策略（防重复听感疲劳）

| 事件 ID | 变体数量 | 播放策略 | pitch 随机范围 |
|---|---|---|---|
| `lever_pull` | 3 | Round-robin 轮转 | ±3 semitones（约 ±17%，不破坏音调感） |
| `reveal_pop` | 3 | Round-robin | ±2 semitones |
| `shred_start` | 2 | Random | ±2 semitones |
| `shred_end` | 2 | Random | ±2 semitones |
| `product_land` | 3 | Random | ±4 semitones |
| `shelf_add` | 2 | Round-robin | ±3 semitones |
| `lever_drag` | 1 | 循环，无变体 | N/A |
| `shred_loop` | 1 | 循环，无变体 | N/A |
| `BGM_main_loop` | 1 | 循环，无变体 | N/A |

### §2.4 音触同步约束（与 haptic-system.md F-1 / audio-system.md Core Rule 9 对位）

SFX 文件的**起音时间（Attack time）** 是 Haptic 同步的基准：

- `audio_lead_ms = 35 ms`（registry 常量，`haptic_pipeline_latency_ms` 的补偿量）
- `audio_haptic_sync_window_ms = 30 ms`（人类听觉同步察觉阈值）
- **硬约束**：有 Haptic 对位的 SFX（`lever_pull`、`shred_start`、`shred_end`、`reveal_pop`、`product_land`、`shelf_add`），其音频文件的有效起音（感知响度达到 -30 dBFS 的时刻）必须落在文件开头 **≤ 10 ms** 处。起音过慢（>10 ms 软起音）会让 Haptic 打击先于声音被玩家感知，导致"先摸后听"。
- **例外**：`lever_drag`（拖拽连续音）无 Haptic 对位，起音约束放宽至 ≤ 50 ms（允许轻微淡入以避免起始 click）；`BGM_main_loop` 无同步约束。

### §2.5 Reduce Motion 全局开关联动

`reduce_motion_factor`（三档：0.0 / 0.5 / 1.0，由 Accessibility System GDD 拥有，Juice Cookbook F-6 定义公式）对音频层的影响：

- **factor = 1.0（默认，Reduce Motion 关）**：所有 SFX 全层级播放，无修改
- **factor = 0.5（中档）**：多层叠加 SFX（`lever_pull`、`reveal_pop`）降至单层；`shred_loop` 维持；体积感适度降低
- **factor = 0.0（全开）**：所有 SFX 保留 transient 层（保证反馈存在感），去除 body 层和 tail 层；`shred_loop` 音量降低 -6 dB；BGM 不受影响

各事件的具体降级矩阵见 §3 逐事件 spec 的"Reduce Motion 联动"字段，以及 §6 下游契约汇总。

---

## §3 逐事件 SFX Spec

---

### §3.1 `lever_pull`

**① 事件 ID**

`lever_pull`（runtime key）/ `sfx_lever_pull`（registry 常量名）

**② 触发上下文**

- 触发系统：Lever Interaction System
- 触发时机：摇杆越过触发阈值（拉下到底锁定瞬间），对应 `drag_ended` 后的越阈值分支
- Juice Cookbook 锚点：**JC-R2** `lever_lock`——"金属顶住了，唯一一次有真实物理重量的冲撞"
- Audio System 锚点：audio-system.md Core Rule 2 事件目录，Sound Design Brief 第一行
- Haptic 对位：`haptic_lever_lock`（`heavy` 预设）；调用方须在同帧先 `AudioSystem.play(&"lever_pull")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"lever_lock")`

**③ 音色描述**

目标情感：**决定性一击**——"金属齿块顶到硬挡板，机器完成了这一次收力"。不是轻飘飘的"叮"，是有厚度和质量感的"咔嚓-嗡"。

具体形容词链：**短促**（< 150 ms 总长）· **底部沉实**（sub-bass 冲击层）· **金属机械感**（中频碰撞层）· **干净收尾**（无多余尾音拖泥带水）

参考物：
- 老式四孔打孔机用力下压到底的那一声（纸张穿透 + 金属底座共鸣）
- 工业级机械键盘（Cherry MX Black / 白轴）底触感——非点击音，而是底部"顶实"时的低沉敲击
- 重型钳子夹合到位的金属碰撞声（五金店背景音，非工具声）

反参考：弹簧弹起的"嘣"声（太轻）、钟声（太悠长）、手机 UI 点击音（太塑料）

**④ 长度约束**

| 层 | Attack | Sustain | Release | 备注 |
|---|---|---|---|---|
| sub-bass transient | ≤ 8 ms | 20–30 ms | 30–40 ms | 总长 ~80 ms；JC-R2 要求 1 帧 thump，即声音主体在 ~16 ms 内达到峰值 |
| 金属碰撞 body | ≤ 10 ms | 30–40 ms | 20–30 ms | 与 sub-bass 层错开 5–8 ms 叠加，总长 ~100 ms |
| 整体文件 | ≤ 10 ms（有效起音） | — | — | **硬约束**：有效起音（感知响度 -30 dBFS 时刻）≤ 10 ms（§2.4 音触同步约束）|

循环属性：**否（`loop: false`）**

Haptic 对位窗口：音频文件头部 ≤ 10 ms 起音，配合 `audio_lead_ms = 35 ms` 延迟发射，保证感知到达时刻差 ≤ 5 ms（远小于 `audio_haptic_sync_window_ms = 30 ms`）

**⑤ 层级建议**

三层叠加结构（factor = 1.0 全层播放）：

```
Layer A — sub-bass transient（低频冲击核心）
  频段：40–120 Hz，主峰在 80 Hz
  角色：给打击感"分量"；让玩家手心感到机器有重量

Layer B — 金属碰撞 body（中频机械感）
  频段：800 Hz–3 kHz，主峰在 1.2–1.8 kHz
  角色：提供"咔嚓"的清晰辨识度；与 Layer A 错开 5–8 ms 起音

Layer C — 金属余震 tail（可选，Reduce Motion 降级首先去除）
  频段：2–6 kHz，高频空气感
  持续：50–80 ms 快速衰减
  角色：给打击感加"真实材质"收尾；无此层也可接受
```

**⑥ 参考链接**

- 搜索关键词一：**"punch machine impact sfx foley"**，Freesound.org / YouTube 搜索，筛选时长 < 300 ms、含明显 sub-bass 瞬态的素材作为音色参照
- 搜索关键词二：**"mechanical lever latch click heavy impact"**，关注有金属底座共鸣的工业设备锁定音
- 方向描述：参考 Vlambeer/Nuclear Throne 的近战打击音设计文章（作者 Jan Willem Nijman）——他们的原则是"low frequency + midrange snap + short decay"，与本事件目标高度吻合；不需要游戏版权素材，方向参照即可

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（推荐）：
- 材料：厚硬纸盒抽屉滑轨 + 1 个 ABS 塑料文具盒盖（作为底座共鸣腔）
- 动作：单手用力将抽屉推到底，让滑轨金属卡扣接触到盒体时发出的"嗒-嗡"声
- 麦克风摆放：接触式麦克风（接触录音）贴在塑料盒侧面采集低频共鸣，同时用电容麦在 20–30 cm 处采集中高频碰撞——两轨分开后期叠加即是 Layer A + Layer B 的原始素材
- 关键点：**滑轨金属部分**是 Layer B 金属感来源；**塑料腔体共鸣**是 Layer A sub-bass 来源

录音方案 B（备用）：
- 材料：金属订书机用力一压到底（订书钉不装，只采集机构打击声）
- 接触麦贴底座，配合 30 cm 电容麦
- 比方案 A 更快、更金属，但低频弱一些；需后期 EQ 加低频

**后期合成补充：**
- Layer A 的 sub-bass 可用合成器（白噪声 + 12dB/oct 低通 @ 120 Hz + 极速 attack/release 包络）补足，使 80 Hz 冲击感更扎实
- 整体 pitch down 1–2 semitones 可增加质量感
- 避免过度压缩——打击感来自快速 transient，限制器门限设在 -6 dBFS 以下会压死冲击感

**商业库优先级（备用）：**
- 优先：Sonniss GDC Audio Bundle（历年免费包，含大量机械打击 foley）
- 次选：Freesound.org 搜索 CC0 授权，tag: `mechanical impact`、`metal hit heavy`
- 最低优先级：手游通用 SFX 包（质感不符，倾向于轻飘飘的 UI 打击）

**⑧ 频段占位**

主导频段：**80 Hz（sub-bass 峰值）+ 1.2–1.8 kHz（金属碰撞峰值）**

频段分布参考：
- 20–80 Hz：sub-bass 主体（Layer A）
- 80–300 Hz：低中频身体感（Layer A 尾部）
- 300–800 Hz：中频过渡（刻意保持较低，避免与 `shred_loop` 的 200-400 Hz 齿轮段冲突）
- 800 Hz–3 kHz：金属碰撞主体（Layer B）
- 3–8 kHz：金属余震（Layer C，Reduce Motion 首先去除）
- 8 kHz 以上：空气感（可适当 HPF 清理以节省空间）

注：300–800 Hz 刻意留低是为了避免与 `shred_loop`（中低频连续研磨，§3.3）频段堆叠——详见 §4 冲突矩阵。

**⑨ 音量基准**

- 目标响度：**-14 dBFS RMS**（相对 §2.1 -18 dBFS 参考基准，+4 dB——P1 核心打击事件优先级最高，需要在 BGM 和其他 SFX 中清晰突出）
- 真峰值：≤ -3 dBFS True Peak（§2.1 全局约束）
- SFX bus 内相对关系：`lever_pull` (-14) > `reveal_pop` (-16) > `shred_start` (-16) > `product_land` (-18) = `shelf_add` (-20) > `shred_end` (-18)
- 调整时机：响度相对值在 mix 阶段校准；此处数值是生产目标，不是硬性写死值

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认，关闭 Reduce Motion） | Layer A + B + C 全层播放，无修改 |
| 0.5（中档） | Layer C（金属余震 tail）去除；Layer A + B 正常播放；音量不变 |
| 0.0（全开 Reduce Motion） | 仅保留 Layer A（sub-bass transient，保证反馈存在感）；Layer B 和 C 去除；参照 §2.5 全局约定 |

实现方式：下游 Lever Interaction GDD 在触发音效时根据 `reduce_motion_factor` 档位选择播放哪个预混变体文件，或由 AudioSystem 播放分层资产——具体方案由 godot-specialist 在 Lever Interaction GDD 实现阶段决定；本 spec 锁定降级语义。

---

### §3.2 `reveal_pop`

**① 事件 ID**

`reveal_pop`（runtime key）/ `sfx_reveal_pop`（registry 常量名）

**② 触发上下文**

- 触发系统：Silhouette Reveal System
- 触发时机：剪影弹出并填色的瞬间（揭晓动画帧点）
- Juice Cookbook 锚点：**JC-R5** `reveal_pop`——"有东西真的从机器里弹出来了，空间上的惊喜"（Cookbook 视觉振幅最高配方，squash 0.6 → 1.2，color flash 亮黄/白 1 帧）
- Audio System 锚点：audio-system.md Core Rule 2 事件目录，Silhouette Reveal 行
- Haptic 对位：`haptic_reveal_pop`（`selection` 预设）；调用方须在同帧先 `AudioSystem.play(&"reveal_pop")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"reveal_pop")`

**③ 音色描述**

目标情感：**小礼物被打开的瞬间**——清脆、明亮、带一点儿共鸣尾巴，像精心制作的东西从包装里弹出来。不是急促的报警"叮"，是悠然的、有余韵的清脆单音。

具体形容词链：**中高频主导**· **清脆**（fast attack，无前置噪声）· **明亮不刺耳**（能量集中在 1–4 kHz，避免 6 kHz 以上的齿音）· **短促但有尾**（核心 < 200 ms，混响尾衰减至 300 ms）

参考物：
- 精钢餐具（筷子架、勺子）轻敲瓷碗边缘的单音——不是"叮叮"连击，是单次轻敲
- 手工玻璃风铃被微风触碰时的单音（有空气感共鸣）
- 高品质木琴/马林巴最高音区的单音敲击（温暖中高频，无合成感）

反参考：电子合成的"叮"或"哔"（无物理材质感）；游戏"获得金币"音效（过于欢庆，基调不符）

**④ 长度约束**

| 层 | Attack | Sustain | Release（含混响尾） | 备注 |
|---|---|---|---|---|
| transient（冲击核心） | ≤ 5 ms | 10–20 ms | 60–80 ms | 主体感知长度 ~100 ms |
| body（材质共鸣） | ≤ 8 ms | 30–50 ms | 80–120 ms | 与 transient 同步起音，"叮"的本体 |
| tail（混响/空间感） | — | — | ~200–250 ms 自然衰减至 -60 dBFS | 使整体文件约 300–350 ms；§2.1 要求非循环 SFX ≤ 1000 ms，满足 |
| **整体文件** | **≤ 5 ms（有效起音）** | — | — | 硬约束：有效起音 ≤ 10 ms（§2.4），此事件应尽量压缩至 ≤ 5 ms |

循环属性：**否（`loop: false`）**

Haptic 对位窗口：起音 ≤ 5 ms，`selection` 预设延迟约 5 ms，配合 `audio_lead_ms = 35 ms` 补偿，感知到达时刻差 ≤ 5 ms

**⑤ 层级建议**

三层结构：

```
Layer A — transient（起始冲击，"叮"的瞬态）
  频段：2–6 kHz，主峰在 3–4 kHz
  角色：建立"清脆"感知；与 Haptic selection 对位的主感知层

Layer B — body（材质共鸣，"叮"的本体音调）
  频段：800 Hz–3 kHz，具备可感知音高（建议调为 C5–G5 音区，即 523–784 Hz 的泛音列中心）
  角色：给事件"乐器感"和材质真实感；Reduce Motion 0.5 时保留此层

Layer C — tail（混响/空间尾音）
  频段：1–4 kHz，随自然共鸣衰减
  持续：200–250 ms 自然衰减
  角色：提供"开阔小空间"的空间感；模仿工坊木质腔体反射；Reduce Motion 0.5 时去除
```

**⑥ 参考链接**

- 搜索关键词一：**"ceramic bowl tap sfx single hit"**，Freesound.org 搜索，筛选有清脆起音 + 自然衰减尾的单音录音
- 搜索关键词二：**"tubular bell single note foley"** 或 **"xylophone high note dry recording"**——寻找音高在 C5–A5 区间（约 523–880 Hz 基频，泛音在 1–4 kHz）的干录素材
- 方向描述：参考 Florence（游戏）的 UI 交互音设计——该作品的每个交互节点都有精心制作的乐器感单音，音调不过分欢庆但有音乐性；关注其"完成感"而非"成就感"的情感基调

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（强烈推荐）：
- 材料：精细玻璃杯（薄壁高脚杯）或日式茶碗（较厚实）
- 动作：用一根细金属棒（如铁签、钢尺角）轻触杯口边缘，力度以能听到清脆单音而不产生"叮叮"双击为准
- 麦克风摆放：电容麦置于杯口侧方 10–15 cm，略高于杯缘，以捕捉气柱共鸣；同时架设第二支麦在 30–40 cm 外捕捉空间感——两轨后期分别对应 Layer A+B 和 Layer C
- 关键点：房间要安静且有轻微自然混响（浴室或小书房比消声室更好）；录 10–15 次取最干净的 3 次；每次录音后等待 3 秒以上以确保尾音完全消失

录音方案 B（快速备用）：
- 材料：金属汤匙背面轻敲厚玻璃碗边缘
- 比方案 A 更低沉饱满，适合想要稍微"温暖"一些的音色版本；与方案 A 可叠加混合

**后期合成补充：**
- Layer C 的混响尾可在后期添加：使用极短的房间混响（pre-delay 5 ms，RT60 约 0.3–0.5 s，房间大小"小工坊"）；避免大厅或金属混响预设
- 若录音音调感不足，可在后期轻微添加高次谐波（饱和/谐波激励器，非失真），增强乐器感
- 禁止添加合成"叮"音替代——物理录音的不规则泛音是"真实感"的来源

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle / UI & SFX packs，搜索 `chime single` / `bell tap` / `ceramic hit`
- 次选：Zapsplat.com（注册免费），tag: `ceramic tap`、`glass ting`
- 注意排除：合成电子叮声、游戏金币音效类素材——即使标注"cozy"也往往过于合成感

**⑧ 频段占位**

主导频段：**800 Hz–4 kHz（材质共鸣 + 冲击核心）**

频段分布参考：
- 20–200 Hz：极低能量（此事件无需低频成分，可在后期 HPF @ 200 Hz 清理）
- 200–800 Hz：低中频（建议适当削减 -3–-6 dB，为 `lever_pull` 的 body 层让路）
- 800 Hz–4 kHz：主体能量区（Layer A + Layer B，清脆感与材质感所在）
- 4–8 kHz：适量空气感（Layer C 的中高频延伸）
- 8 kHz 以上：轻微保留（玻璃/金属的高次泛音，过多会刺耳，保留 -12 dB 以下即可）

注：`reveal_pop` 主导频段（800 Hz–4 kHz）与 `lever_pull` 的 Layer B（800 Hz–3 kHz）有重叠，但时间上不会同时播放（`lever_pull` 后需等待整个粉碎序列才触发 `reveal_pop`），无遮蔽风险。

**⑨ 音量基准**

- 目标响度：**-16 dBFS RMS**（相对 §2.1 参考基准，-16 dBFS；P1 核心事件，比 `product_land` 略高但低于 `lever_pull`）
- 真峰值：≤ -3 dBFS True Peak
- 变体间一致性：3 个变体（§2.3）RMS 差异 ≤ 1 dB，确保轮转时无音量跳变

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | Layer A + B + C 全层播放，含完整混响尾（~300 ms 总长）|
| 0.5（中档） | Layer C（混响尾）去除，仅保留 Layer A + B（~100–120 ms 总长）；音调感保留，"礼物打开"感知减弱但仍存在 |
| 0.0（全开 Reduce Motion） | 仅保留 Layer A（transient 冲击，保证反馈存在感）；Layer B + C 去除；玩家仍能感知"事件发生了"，但无材质感与空间感；参照 §2.5 |

---

### §3.3 `shred_loop`

**① 事件 ID**

`shred_loop`（runtime key）/ `sfx_shred_loop`（registry 常量名）

**② 触发上下文**

- 触发系统：Shred Process System
- 触发时机：粉碎机器启动后进入持续循环，`play_loop(&"shred_loop")` 持续至 `stop_loop(&"shred_loop")` 后接 `shred_end`
- Juice Cookbook 锚点：**JC-R4** `shred_pulse`——"机器还在工作，有节奏，不是等待"；`shred_loop` 是 JC-R4 的音频基底，每 `shred_pulse_interval_s = 0.4 s` 插入 +3 dB / 30 ms 的音量 bump
- Audio System 锚点：audio-system.md Core Rule 2（专用循环节点，不占 8 节点 SFX 池），Sound Design Brief 第四行（"有纹理节奏感，非单调白噪声"）
- Haptic 对位：无直接对位（intra-loop `shred_pulse` 由 Shred Process System 按 F-2 节奏调度，不由 `shred_loop` 本身触发）；`shred_loop` 是声音基底，`shred_pulse` 是 Haptic 节奏节拍

**③ 音色描述**

目标情感：**ASMR 满足感——机器在认真工作，过程即享受**。不是白噪声循环，是有呼吸感的"机器低语"，像站在一台运转中的精密机器旁边：能听到材料被处理的质感，能感受到周期性的节奏律动。

具体形容词链：**中低频主导**· **连续但有纹理**（每 0.3–0.5 s 有一次轻微强调点，对应 `shred_pulse_interval_s = 0.4 s`）· **哑光磨砂质感**（非金属刮擦，而是软硬纸张/材料被研磨）· **稳定不疲倦**（可循环听 30–60 s 无厌倦感）

参考物：
- 高质量办公碎纸机持续工作音（非启停音，是 10–15 秒连续进纸粉碎时的连续声）——注意要找**旧式/机械感强**的碎纸机录音，而非安静的现代静音款
- 石磨研磨杂粮时的低频连续摩擦音（有明显粒状纹理，周期性强调点）
- 中世纪/工业风手摇研磨机的连续工作音（如旧式手动咖啡磨豆机的金属研磨板）

反参考：循环白噪声（无纹理）；洗衣机脱水音（太高频嗡嗡）；现代静音碎纸机（太干净，无质感）

**④ 长度约束**

| 属性 | 规格 | 备注 |
|---|---|---|
| 循环工作段长度 | **≥ 1500 ms**（建议 2000–2500 ms） | 循环段必须足够长，确保 CPU 不频繁读取循环头；§2.1 要求 ≥ 1000 ms，此事件因有周期性强调点要求更长 |
| 循环点精度 | 误差 ≤ 2 ms | OGG 格式在 Godot import 中手动校准 loop point；相位连续，无 click 或 pop |
| 循环点位置 | 强调点结束后的稳定段（避免在强调峰值处截断） | 循环应从"一轮研磨节拍结束、下一轮开始前的稳定过渡段"切割，保证无缝衔接 |
| 周期性强调点间隔 | 循环内每 **400 ms ± 20 ms** 一次轻微强调 | 与 `shred_pulse_interval_s = 0.4 s` 对齐，强调点相当于 +2–3 dB 的自然幅度起伏，**不是后期添加的 bump**——素材本身要有此节奏，让 JC-R4 的 +3 dB 外部 bump 落在这个天然律动上 |
| Attack（淡入） | 50–80 ms 渐入（`play_loop` 时淡入） | 避免起始 click；§2.4 例外条款允许循环 SFX 淡入 ≤ 50 ms，此处建议 50–80 ms 以匹配粉碎启动后的音效平滑衔接 |
| Release | 由 `shred_end`（§3.5）接替，循环停止后 `shred_end` 立即发射 | `shred_loop` 本身无淡出；stop 时切断，由 `shred_end` 的减速音效提供听感收尾 |

循环属性：**是（`loop: true`，OGG 格式）**

Haptic 对位窗口：无直接对位，`shred_pulse` 节奏由 Shred Process System 独立调度（haptic-system.md F-2）

**⑤ 层级建议**

三层叠加结构（全层合并为单一循环工作文件交付，区别于 §3.1/§3.2 的分层设计——循环 SFX 不分层切换）：

```
Layer A — 中频研磨基底（循环主体）
  频段：200–800 Hz
  角色："机器在运转"的核心质感；带有哑光粗糙感而非金属光泽感
  注意：200–400 Hz 区域是 BGM（工坊环境音/齿轮质感）的重叠区域——素材在此段应有差异化特征（节奏纹理）而非平铺持续音

Layer B — 高频纸张撕裂质感（循环细节层）
  频段：1.5–5 kHz
  角色：ASMR 质感的来源；材料被"处理"的真实感；
  注意：不应有金属刮擦的刺耳齿音，是"软材料被研磨"的沙沙感

Layer C — 低频机器运转基底（机器存在感）
  频段：80–200 Hz
  角色：让玩家感知"机器有重量"；与 BGM 的 200 Hz 以上不冲突
  注意：80 Hz 以下可保留少量（< -6 dB），但不应有明显的低频轰鸣
```

所有三层在生产时混合为**单一循环工作文件**；Reduce Motion 通过整体音量而非分层切换处理（见下方 §3.3 ⑩）。

**⑥ 参考链接**

- 搜索关键词一：**"paper shredder continuous loop foley"**，Freesound.org 搜索；优先选择 5–15 秒以上的连续录音（非启停短片段）；CC0 授权
- 搜索关键词二：**"grinding loop mechanical texture ASMR"**，YouTube 搜索音色参照（不需下载，只需确认目标音色方向）——找带有周期性节奏细节的版本
- 方向描述：参考 Old-school 碎纸机 ASMR 视频（搜索"老式碎纸机 ASMR"），区分"单调白噪声型"（不要）和"有纹理研磨型"（目标）——目标音色是能让人静静听 30 秒的那种；Wall-E 影片中垃圾压缩机的持续运转音也是优秀参照（金属感恰好，节奏感明显）

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（核心方案）：
- 材料：旧式机械碎纸机（非静音款）+ 废纸若干张（稍厚的 80–100g 打印纸，A4 尺寸，连续送入）
- 动作：以 2–3 秒一张的节奏连续送入，维持 20–30 秒的不间断录音；录制过程中保持进纸节奏的轻微不规则性（±0.1–0.2 秒的随机性）以获得自然节奏感
- 麦克风摆放：动圈麦（如 SM7B 或 SM57）距碎纸口 15 cm 正面，用于捕捉研磨中频；同时在侧方 40 cm 架设电容麦捕捉腔体共鸣低频——两轨对应 Layer B 和 Layer A+C 的原始素材
- 关键点：选取录音中**节奏最稳定、纹理最清晰的 2000–2500 ms 片段**作为循环工作段；循环点在两次进纸间的研磨稳定段切割（避开进纸"咔嗒"声）

录音方案 B（质感变化版）：
- 材料：手动金属厨房研磨器（蒜泥器/胡椒研磨器）+ 粗盐或细砂
- 动作：稳定旋转研磨 30 秒，保持转速均匀
- 特点：比方案 A 更"饱满"的磨砂纹理，较少纸张感；适合作为 Layer A 的备用低频研磨底
- 两方案可在后期叠加：碎纸机的中高频纸张感 + 研磨器的低频砂砾感 = 更丰富的中低频综合研磨体验

**后期处理关键步骤：**
- 循环点剪辑：在 DAW（Audacity 或 Reaper）中找到波形相似的两处过零点作为循环点，A/B 对比测试无缝衔接
- 纹理强调：对自然的周期性能量起伏（约 400 ms 周期）轻微 EQ 强调（+1–2 dB @ 800 Hz–2 kHz），让 JC-R4 的外部 +3 dB bump 有"推着走"的听感基础
- BGM 频段清理：对 200–400 Hz 区间做轻微 EQ 剪裁（-2 dB @ 300 Hz，Q=1.5），为 BGM 的齿轮质感让路（详见 §4 冲突矩阵）
- 响度：标准化至 -23 dBFS LUFS（循环音规格，§2.1）

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle `mechanical loops` 类目
- 次选：Soundsnap.com `machine loop` / `grinding loop`（注册后可下载有限数量）
- 注意：商业库的碎纸机 loop 往往过于干净，需在后期添加轻微谐波饱和以增加纹理感；若无明显 400 ms 周期强调点，需在后期 automation 添加轻微音量律动（不超过 ±1.5 dB）

**⑧ 频段占位**

主导频段：**200–800 Hz（研磨中频主体）+ 1.5–4 kHz（纸张/材料处理高频纹理）**

频段分布参考：
- 20–80 Hz：极低能量（< -12 dB），避免低频轰鸣掩盖触觉层
- 80–200 Hz：机器存在感低频（Layer C，适量保留，约 -6 dB 相对中频峰值）
- 200–800 Hz：研磨主体（Layer A，主导频段；200–400 Hz 与 BGM 重叠区需 -2 dB EQ 修剪）
- 800 Hz–1.5 kHz：中高频过渡（保持自然，不刻意强调）
- 1.5–5 kHz：纸张/材料纹理（Layer B，ASMR 质感来源）
- 5–8 kHz：轻微高频气感（保留，增加"运转中"的真实感，但不得有齿音）
- 8 kHz 以上：可 LPF 清理

BGM 冲突注意（§4 前置说明）：BGM（`BGM_main_loop`）的工坊齿轮纹理集中在 200–400 Hz；`shred_loop` 在此区间需做 -2 dB 的 EQ 剪裁以防频段堆叠导致"泥状中频"，详见 §4。

**⑨ 音量基准**

- 目标响度：**-23 dBFS LUFS 集成响度**（循环 SFX 规格，§2.1）
- 真峰值：≤ -3 dBFS True Peak
- 运行时相对关系：`shred_loop` 在 Reduce Motion factor = 0.0 时降低 -6 dB（参照 §2.5 全局约定）
- 与 BGM 的音量关系：`shred_loop` 在 SFX 总线播放（0 dB 参考），BGM 在 Music 总线（`audio_bgm_offset_db = -12 dB` 偏移），粉碎期间两者同时发声时 `shred_loop` 天然比 BGM 响约 12 dB，这是设计意图——粉碎期间玩家的注意力应在"机器工作"上

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | 全音量循环播放；JC-R4 音量 bump（+3 dB / 30 ms，由 Shred Process System 控制）正常触发 |
| 0.5（中档） | `shred_loop` 维持全音量（§2.5：0.5 档 `shred_loop` 维持，体积感适度降低）；JC-R4 外部 bump 由 Shred Process System 决定是否缩减 |
| 0.0（全开 Reduce Motion） | `shred_loop` 音量降低 -6 dB（§2.5 全局约定）；循环仍然播放（不停止），让玩家知道机器还在工作；JC-R4 外部 bump 由 Shred Process System 按比例缩减 |

---

### §3.4 `shred_start`

**① 事件 ID**

`shred_start`（runtime key）/ `sfx_shred_start`（registry 常量名）

**② 触发上下文**

- 触发系统：Shred Process System
- 触发时机：摇杆越阈值锁定后，粉碎机器在 `shred_loop` 开始循环之前的启动瞬间；时序：`shred_start` 播放后紧接 `play_loop(&"shred_loop")`
- Juice Cookbook 锚点：**JC-R3** `shred_start`——"机器真的启动了，腔体里有东西在运转"；齿轮启动低频先行，纸张撕裂高频延后 30 ms
- Audio System 锚点：audio-system.md Core Rule 2 事件目录，Shred Process 行
- Haptic 对位：`haptic_shred_start`（`medium` 预设）；调用方须在同帧先 `AudioSystem.play(&"shred_start")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"shred_start")`

**③ 音色描述**

目标情感：**机器苏醒的第一口气**——从沉默到运转的过渡，有明确的"从无到有"的加速感。不是突然爆发，是一个短促但明确的"启动序列"。

具体形容词链：**短促启动弧**（300–500 ms 总长）· **低频先行**（电机启动感）· **中高频跟进**（材料咬入感）· **向 `shred_loop` 自然衔接**（结尾频率特征与循环开头匹配）

参考物：
- 旧式搅拌机通电启动的 "嗡——哗啦" 声（先有电机转动，后有搅拌叶片碰触食材）
- 老式收音机电子管加热时的低频嗡鸣（缓慢从无到有）
- 旧式自动铅笔削笔机插入铅笔时的启动音（机构咬合的刹那感）

反参考：爆炸式启动音（太突然）；合成器扫频 sweep（太科幻）；现代电器的安静启动提示音（无质感）

**④ 长度约束**

| 层 | Attack | Sustain | Release | 备注 |
|---|---|---|---|---|
| 低频电机启动层 | ≤ 10 ms | 150–200 ms 上升弧 | 30–50 ms | 主体：80–400 Hz 从低到中频扫升；JC-R3 要求此层先行 |
| 高频材料咬入层 | 延后 30 ms 起音（JC-R3 约束） | 100–150 ms | 50–80 ms 过渡到 `shred_loop` | 800 Hz–3 kHz，纸张/材料被机器"咬住"的感觉 |
| **整体文件** | **≤ 10 ms（有效起音）** | — | — | 硬约束：有效起音 ≤ 10 ms（§2.4 音触同步约束） |

总时长目标：**300–500 ms**（audio-system.md Sound Design Brief 规格）

循环属性：**否（`loop: false`）**

Haptic 对位窗口：起音 ≤ 10 ms，`medium` 预设延迟约 5 ms，配合 `audio_lead_ms = 35 ms` 补偿，感知到达时刻差 ≤ 5 ms

**⑤ 层级建议**

双层结构（JC-R3 规定两层 onset 错开）：

```
Layer A — 低频电机启动（先行层）
  频段：80–400 Hz，能量从 80 Hz 扫升至 300–400 Hz
  角色：给玩家"机器开始运转"的低频质量感；JC-R3 的"齿轮启动低频"
  时序：文件 t=0 起音

Layer B — 中高频材料咬入（跟进层）
  频段：800 Hz–3 kHz，中心在 1.5–2 kHz
  角色：模拟材料被机器咬合的质感过渡；JC-R3 的"纸张撕裂高频"
  时序：延后 30 ms 起音（JC-R3 硬约束：模拟"机器先转，再咬入"因果顺序）
```

**⑥ 参考链接**

- 搜索关键词一：**"machine startup sfx foley mechanical"**，Freesound.org，筛选 300–600 ms 范围内从静到动的启动音
- 搜索关键词二：**"blender startup old motor"** / **"appliance motor start whir"**，关注有明确加速弧的电机启动素材
- 方向描述：目标是 JC-R3 描述的"腔体内部有东西在运转"感——声音要有因果叙事（先电机、后咬合），而不是瞬间全功率噪声

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（推荐）：
- 材料：旧式台式电扇（或小型直流电机玩具）通电启动瞬间
- 动作：录制通电启动到稳定运转前约 0.5 秒的过渡段；麦克风距 15 cm 正侧方
- 后期：Layer A 取电机启动低频段；Layer B 用手动碎纸机"咬入"纸张的第一声作为叠加素材

录音方案 B（快速备用）：
- 材料：手动咖啡磨豆机快速启动旋转（从静止到稳速的 0.3 秒）
- 取中频研磨咬合的那一刻作为 Layer B 原始素材

**后期关键步骤：**
- Layer B 在 DAW 中整体向后位移 30 ms（JC-R3 约束）
- 整体结尾需平滑过渡到 `shred_loop` 的频率特征，避免音色断层（可在后期对比 `shred_loop` 素材调整 EQ 尾段）
- 响度归一化至 -18 dBFS RMS（非循环 SFX 规格，§2.1）

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle `machine startup` / `motor start` 类目
- 注意：确认素材有"从弱到强"的动态弧；flat 启动音不符合需求

**⑧ 频段占位**

主导频段：**80–400 Hz（电机启动）+ 800 Hz–3 kHz（材料咬入）**

频段分布参考：
- 20–80 Hz：少量低频存在感（不需要强调，保留自然感）
- 80–400 Hz：Layer A 主体（启动弧，扫升特征）
- 400–800 Hz：中频过渡（Layer A 上行尾与 Layer B 下行头的交叉区）
- 800 Hz–3 kHz：Layer B 主体（材料咬合感，延后 30 ms 起音）
- 3 kHz 以上：少量空气感（保留真实感，避免过多齿音）

**⑨ 音量基准**

- 目标响度：**-16 dBFS RMS**（P2 事件；与 `reveal_pop` 同级，低于 `lever_pull`）
- 真峰值：≤ -3 dBFS True Peak
- 2 个变体（§2.3）RMS 差异 ≤ 1 dB

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | Layer A + B 双层完整播放；Layer B 延后 30 ms 起音正常实施 |
| 0.5（中档） | Layer B（中高频咬入）去除；仅保留 Layer A（低频电机启动）；音调感降低但启动感知保留 |
| 0.0（全开 Reduce Motion） | 仅保留 Layer A transient 最强点（≤ 100 ms 截短版）；保证反馈存在感；参照 §2.5 |

---

### §3.5 `shred_end`

**① 事件 ID**

`shred_end`（runtime key）/ `sfx_shred_end`（registry 常量名）

**② 触发上下文**

- 触发系统：Shred Process System
- 触发时机：`stop_loop(&"shred_loop")` 后立即播放；为 `shred_loop` 停止提供听感收尾，代替循环硬切断
- Juice Cookbook 锚点：无直接配方（粉碎结束是叙事弧的"收笔"，不需要独立配方支撑）；但构成 JC-R3→JC-R4 序列的闭合音
- Audio System 锚点：audio-system.md Core Rule 2 事件目录，Shred Process 行；audio-system.md 描述"低频电机减速消失 + 轻微金属余震"
- Haptic 对位：`haptic_shred_end`（`light` 预设）；调用方须在同帧先 `AudioSystem.play(&"shred_end")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"shred_end")`

**③ 音色描述**

目标情感：**机器可以歇息了**——不是突然停止，是有尊严的收工。电机减速后的惯性转动尾声，机器把最后一口气呼出来。

具体形容词链：**减速弧**（从运转频率向下扫降）· **中低频主导**（惯性转动的余量感）· **轻微金属余震**（机器停止时的细微振动）· **干净收尾**（无拖泥带水的尾音）

参考物：
- 搅拌机断电后叶片惯性减速的那 0.5–1 秒（不是硬停，是摩擦渐减）
- 风扇断电后转速从高到低的那种"嗡……嗡……"减频音
- 旧式录音机卷轴停止转动时的轻微机构摩擦声

反参考：突然切断的无声停止（太生硬）；长达数秒的余音（超出 §2.1 约束）；有旋律感的"完成音调"（那是 `product_land` 的角色）

**④ 长度约束**

| 层 | Attack | Sustain | Release | 备注 |
|---|---|---|---|---|
| 减速主体层 | ≤ 10 ms | 200–300 ms 减速弧（音调从运转频率下扫） | — | 频率扫降特征是核心；对位 `shred_loop` 循环停止后的听感连贯 |
| 金属余震层 | 跟减速尾部叠入（约 150 ms 时） | — | 150–200 ms 自然衰减 | 轻微高频余震（1–4 kHz）；Reduce Motion 0.5 时首先去除 |
| **整体文件** | **≤ 10 ms（有效起音）** | — | — | 硬约束：有效起音 ≤ 10 ms（§2.4 音触同步约束） |

总时长目标：**400–600 ms**（audio-system.md Sound Design Brief 规格）

循环属性：**否（`loop: false`）**

**⑤ 层级建议**

双层结构：

```
Layer A — 减速主体（核心层）
  频段：100–600 Hz，能量随时间从运转频率（200–600 Hz 区间）向下扫降
  角色："机器在减速，还有惯性"；提供叙事闭合感

Layer B — 金属余震（可选层）
  频段：1–4 kHz，轻微瞬态感
  持续：150–200 ms 自然衰减
  角色：给停止时刻的"机器质感"；Reduce Motion 0.5 时首先去除
```

**⑥ 参考链接**

- 搜索关键词：**"motor spindown sfx"** / **"blender stop deceleration foley"**，Freesound.org
- 方向描述：需要找有明确减速动态弧（音调从高到低）的电机停止录音，而非突然硬切的静音

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（推荐）：
- 材料：小型直流电机（玩具车马达、台式电扇）断电后的惯性减速段
- 动作：录制断电后整个减速过程（约 1–2 秒），后期截取前 400–600 ms 最有质感的段落
- Layer B 可从旧式碎纸机停止后机构摩擦的高频成分截取叠加

**后期关键步骤：**
- 响度归一化至 -18 dBFS RMS（§2.1）；此事件的 RMS 可以比 `shred_start` 略低（-18 vs -16），体现"结束比开始更轻"的叙事感

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle `machine stop` / `motor spindown` 类目

**⑧ 频段占位**

主导频段：**100–600 Hz（减速主体）+ 1–4 kHz（轻微余震）**

频段分布：
- 20–100 Hz：少量存在感（不需要强调）
- 100–600 Hz：Layer A 扫降主体（减速特征的核心频段）
- 600 Hz–1 kHz：中频过渡
- 1–4 kHz：Layer B 金属余震（轻量，不突出）
- 4 kHz 以上：可 HPF 清理或极低电平保留

**⑨ 音量基准**

- 目标响度：**-18 dBFS RMS**（§2.1 参考基准；P2 事件，比 `shred_start` 略低以体现叙事"消音"感）
- 真峰值：≤ -3 dBFS True Peak
- 2 个变体（§2.3）RMS 差异 ≤ 1 dB

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | Layer A + B 完整播放（400–600 ms 总长） |
| 0.5（中档） | Layer B（金属余震）去除；仅保留 Layer A 减速主体 |
| 0.0（全开 Reduce Motion） | 仅保留 Layer A 最强段（约前 150 ms），保证"机器已停"感知存在；参照 §2.5 |

---

### §3.6 `product_land`

**① 事件 ID**

`product_land`（runtime key）/ `sfx_product_land`（registry 常量名）

**② 触发上下文**

- 触发系统：Silhouette Reveal System
- 触发时机：剪影揭晓并填色后，产物视觉上"落入托盘"的动画帧点；紧接 `reveal_pop` 之后，是揭晓序列的第二声
- Juice Cookbook 锚点：**JC-R6** `product_land`——"这个小东西有重量，落实了"；柔和落地声 + 短促"完成"音调；音色属于 VA-5 "完成音调（Resolution Tone）"轨道（400 Hz–1.5 kHz，温暖满足）
- Audio System 锚点：audio-system.md Sound Design Brief"中低频实体碰撞感，圆润而不刺耳"
- Haptic 对位：`haptic_product_land`（`light` 预设）；调用方须在同帧先 `AudioSystem.play(&"product_land")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"product_land")`

**③ 音色描述**

目标情感：**产物真实存在——有重量，落实了**。不是庆祝，是确认。小木块轻落桌面的那种实体感：没有弹跳，没有回响，就是"到了"。

具体形容词链：**圆润中低频**（无硬边金属感）· **有重量但不沉重**（轻盈与实体感的平衡）· **短促带温暖尾**（完成音调 Resolution Tone）· **不华丽不庆祝**（Pillar 3 收藏不焦虑）

参考物：
- 小木块轻落木质桌面（非硬地板，有一点桌面共鸣）
- 豆沙包落入瓷盘——软落地的质感，有实体但无金属感
- 小石子投入装了一点水的碗中——有"到了"的感知，但不激烈

反参考：金属碰撞的"当"声（太硬）；轻飘飘无质量感的"啪"声（太空）；乐器和弦（太华丽，违反 Pillar 3）；游戏"获得物品"通用音（太欢庆）

**④ 长度约束**

| 层 | Attack | Sustain | Release | 备注 |
|---|---|---|---|---|
| 碰撞 transient | ≤ 8 ms | 10–20 ms | 40–60 ms | 落地"点"的感知核心 |
| 材质共鸣体 | ≤ 10 ms | 20–40 ms | 60–100 ms | 赋予材质感（木/织物感）的中低频共鸣 |
| 完成音调（Resolution Tone） | ≤ 5 ms | 15–30 ms | 60–80 ms 衰减 | JC-R6 "短促完成音调"；400 Hz–1.5 kHz；禁止多音和弦（VA-5 约束） |
| **整体文件** | **≤ 8 ms（有效起音）** | — | — | 硬约束：有效起音 ≤ 10 ms（§2.4 音触同步约束） |

总时长目标：**100–200 ms**（audio-system.md Sound Design Brief 规格）

循环属性：**否（`loop: false`）**

**⑤ 层级建议**

三层叠加结构：

```
Layer A — 碰撞 transient（落地感知核心）
  频段：300–1200 Hz，有机材质的中低频碰撞
  角色：建立"产物真实存在"的即时感知

Layer B — 材质共鸣体（实体质感）
  频段：200–600 Hz，木质/织物共鸣特征
  角色：让声音有"这是个有温度的物件"的材质感，而非塑料或金属

Layer C — 完成音调（Resolution Tone）
  频段：400 Hz–1.5 kHz，短促单音（禁止和弦）
  角色：JC-R6 的"完成信号"；给序列一个清晰的感知终止点
  注意：VA-5 约束禁止多音和弦，禁止混响拖尾 > 500 ms
```

**⑥ 参考链接**

- 搜索关键词一：**"wooden object drop foley small"**，Freesound.org，筛选圆润、有中低频共鸣、无金属感的素材
- 搜索关键词二：**"xylophone low note single dry"** / **"marimba tap warm soft"**——寻找 Resolution Tone 的乐器感单音（400 Hz–1.5 kHz 基频区）
- 方向描述：参考 Yoshi's Crafted World 的物件落地音设计——纸板/毛线的有机落地感，温暖扎实但不沉重

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（推荐）：
- 材料：小橡皮（文具店常见的方块橡皮）+ 木质书桌桌面
- 动作：从 5–10 cm 高度轻落，录取落地瞬间；Layer C 用另外单独录制的木琴/音叉单音叠加
- 麦克风摆放：电容麦距落点 10–15 cm，略俯仰角，以捕捉桌面共鸣

录音方案 B（备用）：
- 材料：豆袋玩具（沙包）轻落木质托盘边缘
- 特点：更"软"更"包裹"的落地感，适合"豆包入盘"目标音色

**后期关键步骤：**
- Layer C 的 Resolution Tone 需在后期轻微添加——如果 Foley 落地音本身已有中低频基音感，可在 DAW 中找到自然谐波峰值用窄带 EQ +2–3 dB 轻微强调，无需单独添加合成音调
- 禁止后期添加混响拖尾 > 500 ms（VA-5 约束）
- 响度归一化至 -18 dBFS RMS（§2.1）

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle `organic impact` / `soft landing` 类目；Freesound.org CC0，tag: `wood tap`、`small object drop`

**⑧ 频段占位**

主导频段：**300–1500 Hz（有机碰撞 + 完成音调）**

频段分布：
- 20–200 Hz：极低能量（可 HPF @ 150 Hz 清理，此事件不需要低频冲击）
- 200–600 Hz：Layer B 材质共鸣（木质 / 织物有机感）
- 300–1500 Hz：Layer A + C 主体（碰撞 transient + Resolution Tone 叠合区）
- 1.5–4 kHz：少量中高频细节（自然衰减）
- 4 kHz 以上：可 HPF 清理或极低保留

BGM 冲突说明：`product_land` 出现时 `shred_loop` 已停止，BGM 进入安静段（§3.4 规避方案），300–1500 Hz 频段 BGM 能量很低，无明显遮蔽风险。

**⑨ 音量基准**

- 目标响度：**-18 dBFS RMS**（§2.1 参考基准；P3 事件）
- 真峰值：≤ -3 dBFS True Peak
- 3 个变体（§2.3）RMS 差异 ≤ 1 dB

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | Layer A + B + C 完整播放（100–200 ms 总长） |
| 0.5（中档） | Layer C（Resolution Tone 完成音调）去除；Layer A + B 保留材质落地感；"完成感"减弱但存在感保留 |
| 0.0（全开 Reduce Motion） | 仅保留 Layer A transient（碰撞核心，保证"产物已落"感知）；Layer B + C 去除；参照 §2.5 |

---

### §3.7 `lever_drag`

**① 事件 ID**

`lever_drag`（runtime key）/ `sfx_lever_drag`（registry 常量名，**⚠️ 需补登记，详见 §1.3 + §6 下游契约**）

**② 触发上下文**

- 触发系统：Lever Interaction System
- 触发时机：`drag_started` 信号触发时 `play_loop(&"lever_drag")`，`drag_ended` 或越阈值触发时 `stop_loop(&"lever_drag")`（后者紧接 `lever_pull`）
- Juice Cookbook 锚点：**JC-R1** `lever_pull_start` 配套——"摇杆有阻力，这个动作是真实的"；`lever_drag` 是 JC-R1 的音频基底，全程伴随摇杆拖拽过程
- Audio System 锚点：audio-system.md Core Rule 2（专用循环节点，不参与 8 节点 SFX 池）；Core Rule 5 `_valid_loop_keys` 白名单成员
- Haptic 对位：**无**（audio-system.md 明确：连续音阶段离散冲击会与拖拽 fantasy 冲突；`lever_drag` 无 Haptic 对位配对）

**③ 音色描述**

目标情感：**张力渐增——这台机器在抵抗，但在屈服**。不是机器发出的嘈杂声，是材料与机构之间"正在施力"的摩擦物理感。全程应当让玩家的手感到"我在用力拉一个有重量的东西"。

具体形容词链：**低-中频主导**· **持续摩擦感**（有机械质感，非电子噪声）· **哑光磨砂**（非金属光泽，是"拉动"的阻力感）· **可无缝循环**（0.5–2 秒拖拽全程均匀）

参考物：
- 慢速拉开木制抽屉的摩擦声（木对木的阻力感，均匀持续）
- 旧式木门铰链缓慢开启的摩擦音（有阻力但不刺耳）
- 紧实编织布料被缓慢拉伸的"丝——"感（有机纤维的受力音）

反参考：金属刮擦（太刺耳）；循环白噪声（无质感）；单调嗡鸣（无摩擦感）

**④ 长度约束**

| 属性 | 规格 | 备注 |
|---|---|---|
| 循环工作段长度 | **≥ 1000 ms**（建议 1500–2000 ms） | §2.1 循环 SFX 要求 ≥ 1000 ms；`lever_drag` 持续时间 0.5–2 s，工作段需覆盖拖拽全程 |
| 循环点精度 | 误差 ≤ 2 ms | OGG 格式在 Godot import 中手动校准；相位连续，无 click |
| Attack（淡入） | ≤ **50 ms**（§2.4 例外：无 Haptic 对位，起音约束放宽） | 建议 30–50 ms 轻淡入以避免起始 click；不需要急速起音 |
| Release | 由 `stop_loop` 硬切，或后续 `lever_pull`（§3.1）自然覆盖 | `lever_drag` 的"停止感"由 `lever_pull` 的打击音覆盖，无需淡出 |

循环属性：**是（`loop: true`，OGG 格式）**

Haptic 对位窗口：**无**

**⑤ 层级建议**

单层混合结构（循环 SFX，交付为单一工作文件）：

```
合并层 — 低-中频摩擦质感（循环主体）
  频段：150–2000 Hz，主峰在 300–800 Hz
  角色：拖拽过程的全程摩擦感基底；"机器有阻力"的持续物理证据
  注意：避免 200–400 Hz 过于密集（与 BGM 冲突区重叠，需 EQ -2 dB @ 300 Hz 修剪，详见 §4）
  注意：高频成分（> 2 kHz）保持低电平，防止与 lever_pull 的金属层（800 Hz–3 kHz）形成频率堆叠
```

**⑥ 参考链接**

- 搜索关键词一：**"wood drawer slide friction loop"** / **"mechanical friction loop continuous"**，Freesound.org
- 搜索关键词二：**"rope tension creak loop"**——关注有持续阻力感、可无缝循环的素材
- 方向描述：重点在"受力感"而不是"运动感"——声音要传递"摇杆在被拉，有东西在阻力"，而不是"滑动顺畅"

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（推荐）：
- 材料：旧式木制文件柜抽屉（带金属滑轨）慢速拉开过程
- 动作：以 2–3 秒匀速拉开，维持稳定摩擦力；录制过程中故意保持轻微的力道起伏（± 0.1 秒节奏）以获得自然纹理
- 麦克风摆放：接触式麦克风贴在抽屉侧面（捕捉低频振动），配合距 20 cm 电容麦（中频摩擦质感）——两轨混合

录音方案 B（备用）：
- 材料：厚棉布或粗帆布缓慢受力拉伸（双手持布两端向外慢拉）
- 特点：更有机的织物阻力感；可与方案 A 叠加以增加"有机温度"

**后期关键步骤：**
- 循环点剪辑：在摩擦质感最均匀、无明显强调点的段落切割；A/B 对比确认无缝
- BGM 频段修剪：对 200–400 Hz 做 -2 dB @ 300 Hz EQ（Q=1.5），为 BGM 让路（§4 冲突矩阵）
- 响度归一化至 -23 dBFS LUFS 集成响度（循环音规格，§2.1）

**商业库优先级（备用）：**
- 优先：Sonniss GDC Bundle `friction loop` / `wood creak loop`
- 次选：Freesound.org CC0，tag: `friction loop`、`drawer slide`

**⑧ 频段占位**

主导频段：**150–2000 Hz（摩擦质感主体，中心 300–800 Hz）**

频段分布：
- 20–150 Hz：极低能量（可 HPF @ 120 Hz 清理）
- 150–400 Hz：摩擦中低频主体（200–400 Hz 段需 EQ -2 dB 为 BGM 让路）
- 400–800 Hz：阻力感核心频段（主峰位置，保持充足）
- 800–2000 Hz：中高频摩擦细节（保持自然，不刻意强调）
- 2 kHz 以上：低电平保留（< -12 dB 相对主峰，防止与 `lever_pull` Layer B 堆叠）

与 `lever_pull` 的关系：`lever_drag` 持续，`lever_pull` 打击；两者虽共享 800 Hz–2 kHz 区域，但时序上 `lever_drag` 在越阈值时立即停止（`stop_loop`），`lever_pull` 紧接发出，不形成同时堆叠。

**⑨ 音量基准**

- 目标响度：**-23 dBFS LUFS 集成响度**（循环 SFX 规格，§2.1）
- 真峰值：≤ -3 dBFS True Peak
- 无变体（§2.3），单一循环工作文件

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | 全音量循环播放（-23 dBFS LUFS） |
| 0.5（中档） | 维持全音量（`lever_drag` 是过程基底，减半会让拖拽过程感知空洞） |
| 0.0（全开 Reduce Motion） | 音量降低 -6 dB（-29 dBFS LUFS）；循环仍然播放，让玩家感知"摇杆有阻力"；参照 §2.5 shred_loop 同档处理逻辑 |

---

### §3.8 `shelf_add`

**① 事件 ID**

`shelf_add`（runtime key）/ `sfx_shelf_add`（registry 常量名）

**② 触发上下文**

- 触发系统：Shelf Collection System
- 触发时机：产物飞入货架动画的起点帧（JC-R7 `shelf_add` 配方的 Anticipation 相位起点）
- Juice Cookbook 锚点：**JC-R7** `shelf_add`——"它有了一个家，收藏完成——归属感而不是流程结束"；VA-5"材料质感（Material Texture）"轨道，木头/布料轻触感，明确禁止金属感
- Audio System 锚点：audio-system.md Sound Design Brief"轻柔中频'嗒'，比 product_land 更轻"
- Haptic 对位：`haptic_shelf_add`（`light` 预设）；调用方须在同帧先 `AudioSystem.play(&"shelf_add")`，延迟 `audio_lead_ms = 35 ms` 后再 `Haptic.play(&"shelf_add")`

**③ 音色描述**

目标情感：**收纳满足感——整齐地放好了**。比 `product_land` 更轻，更温柔，是"归位"而不是"落地"。像把一本书插回书架时那种轻微的"嗒"——有位置感，有归属感，不张扬。

具体形容词链：**轻柔中频**（比 `product_land` 更轻、更短）· **木质/织物质感**（有机材质，禁止金属感）· **短促干净**（80–150 ms 总长，无多余尾音）· **有位置感**（让玩家感觉"东西滑入了槽里"）

参考物：
- 精装书插入书架的轻微"嗒"声（纸张接触木质的刹那）
- 卡带游戏（Game Boy 卡带、DS 卡）插入机器槽位的"咔"声（有槽位感但不重）
- 积木搭在另一块积木上的轻碰声（平稳落位，无冲击）

反参考：金属碰撞感（VA-5 明确禁止）；华丽的"成就感"音效（Pillar 3 禁止）；与 `product_land` 相同的音色（两者须有明确区分）

**④ 长度约束**

| 层 | Attack | Sustain | Release | 备注 |
|---|---|---|---|---|
| 归位 transient | ≤ 8 ms | 15–25 ms | 30–50 ms | 核心"嗒"感；木/布材质的中频碰触 |
| 空间共鸣尾 | — | — | 30–60 ms 自然衰减 | 轻微的货架/木质腔体共鸣；Reduce Motion 0.5 首先去除 |
| **整体文件** | **≤ 8 ms（有效起音）** | — | — | 硬约束：有效起音 ≤ 10 ms（§2.4 音触同步约束） |

总时长目标：**80–150 ms**（audio-system.md Sound Design Brief 规格）

循环属性：**否（`loop: false`）**

**⑤ 层级建议**

双层结构（轻量）：

```
Layer A — 归位 transient（核心）
  频段：500 Hz–3 kHz，中心在 800 Hz–1.5 kHz
  角色："嗒"的核心感知；比 product_land 的中低频更偏高，体现"更轻"的重量感

Layer B — 空间共鸣（轻量）
  频段：300–1000 Hz，轻微木质腔体共鸣
  持续：30–60 ms 快速自然衰减
  角色：给"归位"感提供一点"这里有个槽位"的空间暗示
```

**⑥ 参考链接**

- 搜索关键词一：**"book shelf insert click foley"** / **"cartridge slot sfx"**，Freesound.org
- 搜索关键词二：**"wooden tap light dry"** / **"cloth surface gentle hit"**
- 方向描述：目标是比 `product_land` 更轻、更精确的"入位感"。Florence 的收藏 UI 音效是很好的方向参照——那种克制的满足感。

**⑦ 采集来源建议**

**Foley 一线录制（优先）：**

录音方案 A（强烈推荐）：
- 材料：精装书轻轻插入书架；麦克风 10 cm 距离，正侧方
- 取书脊接触书架横板的那一刻（"嗒"），前后各截 30 ms 以上
- 确保无摩擦感拖尾——如果有摩擦，重录（应该是干净的单点接触）

录音方案 B（备用）：
- 材料：小木块（2×2×4 cm）轻轻放入木制抽屉，从 1–2 cm 高度
- 更强的木质共鸣感，适合想要稍微"实一点"的音色版本

**后期关键步骤：**
- 严格禁止后期添加金属感 EQ 或金属混响预设（VA-5 禁止）
- 禁止添加任何"成就感"音调（多音和弦、音阶上行）
- 响度归一化至 -20 dBFS RMS（略低于 `product_land` 的 -18，体现"更轻"的层次）

**商业库优先级（备用）：**
- 优先：Zapsplat.com tag: `wood tap light`、`book shelf`；Freesound.org CC0，tag: `tap wood`

**⑧ 频段占位**

主导频段：**500 Hz–3 kHz（轻柔中频归位感）**

频段分布：
- 20–200 Hz：可 HPF @ 200 Hz 清理（此事件无需低频）
- 200–500 Hz：少量木质低端（Layer B 下限，保留自然感）
- 500 Hz–3 kHz：Layer A + B 主体（归位感核心区）
- 3–8 kHz：少量空气细节（极低电平，保持自然）
- 8 kHz 以上：可 HPF 清理

BGM 冲突说明：`shelf_add` 是全套事件中最轻的，`audio_bgm_offset_db = -12 dB` 已充分让路（bgm-direction.md §3.4 频段规避总结表明确：shelf_add 最弱，BGM -12 dB 偏移已充分让路）。

**⑨ 音量基准**

- 目标响度：**-20 dBFS RMS**（§2.1 参考基准之下 -2 dB；P4 事件，整套序列最轻的一声）
- 真峰值：≤ -3 dBFS True Peak
- 2 个变体（§2.3）RMS 差异 ≤ 1 dB

**⑩ Reduce Motion 联动**

| `reduce_motion_factor` | 降级行为 |
|---|---|
| 1.0（默认） | Layer A + B 完整播放（80–150 ms 总长） |
| 0.5（中档） | Layer B（空间共鸣尾）去除；仅 Layer A transient（更干、更短，约 50–80 ms） |
| 0.0（全开 Reduce Motion） | 仅 Layer A 最强点（< 50 ms 截短版），保证入位感知；参照 §2.5 |

---

### §3.9 `BGM_main_loop`

**① 事件 ID**

`BGM_main_loop`（runtime key）/ `sfx_bgm_main_loop`（registry 常量名）

**② 触发上下文**

- 触发系统：AudioSystem 自管理（`_ready()` 时自动启动，永不停止直至 App 强杀）
- Juice Cookbook 锚点：N/A — BGM 不属于 7 条配方序列
- 音色定位：N/A — 详见 `design/audio/bgm-direction.md`（音色调性、参考曲目、乐器编制、情感锚点、BGM×SFX 场景配合规则完整定义于该文档）

**③ 音色描述**

N/A — 详见 `design/audio/bgm-direction.md` §2 音色调性与乐器编制

**④ 长度约束**

| 属性 | 规格 | 备注 |
|---|---|---|
| 循环段总时长 | ≥ 30 s（建议 60–120 s） | §2.1 BGM 约束；循环段过短会让玩家感知"循环"感 |
| 循环点精度 | 误差 ≤ 5 ms | OGG 格式；Godot import 手动校准；BGM 有足够自然和声，循环点精度要求比 SFX 略松 |
| 文件格式 | OGG Vorbis，立体声 | §2.1 约束；BGM 是唯一立体声文件 |

N/A — 其余技术细节详见 `design/audio/bgm-direction.md`

**⑤–⑦ 层级建议 / 参考链接 / 采集来源**

N/A — 详见 `design/audio/bgm-direction.md` §2–§3

**⑧ 频段占位**

N/A — 详见 `design/audio/bgm-direction.md` §3.4 频段冲突规避（BGM 视角）；本文档 §4 频段冲突矩阵（SFX 视角）对齐 bgm-direction.md §3.4 结论

**⑨ 音量基准**

- BGM 总线相对 SFX 总线偏移：**-12 dB**（`audio_bgm_offset_db`，entities.yaml 常量，由 audio-system.md F-2 控制）
- 集成响度：**-23 dBFS LUFS**（循环音规格，§2.1）
- 真峰值：≤ -3 dBFS True Peak

**⑩ Reduce Motion 联动**

N/A — BGM 不受 `reduce_motion_factor` 影响（§2.5 全局约定：BGM 不受影响）

---

## §4 频段冲突矩阵

### §4.1 矩阵说明

本节汇总 9 个 SFX 事件与 BGM 之间的频段占位关系，标注重叠区间，给出每对冲突的解决动作。矩阵对齐 `design/audio/bgm-direction.md` §3.4 频段规避总表（BGM 视角），本节补充 SFX 侧视角与时序说明。

**频段分组约定（本矩阵使用）：**

| 代号 | 频段范围 | 感知特征 |
|---|---|---|
| Sub | 20–80 Hz | 超低频震动感 |
| LowMid | 80–400 Hz | 低中频身体感 |
| Mid | 400–800 Hz | 中频存在感 |
| UpMid | 800–3000 Hz | 中高频辨识度 |
| High | 3–8 kHz | 高频清脆感 |
| Air | 8 kHz+ | 空气感 |

### §4.2 各事件频段占位一览

| 事件 | Sub | LowMid | Mid | UpMid | High | Air | 循环 |
|---|---|---|---|---|---|---|---|
| `BGM_main_loop` | 弱 | ●● 有空缺（200–400 Hz 主动留空） | ● 低密度和声 | ● 旋律 / 钟琴 | ● 软 transient | 弱 | 是 |
| `lever_pull` | ●●● Sub thump | ●●● 80–400 Hz 冲击 | 弱 | ●●● 800–3 kHz 金属碰撞 | ●● Layer C 余震 | 弱 | 否 |
| `reveal_pop` | 极弱 | 弱 | ● 适量 | ●●● 800 Hz–4 kHz 主体 | ●● 空气感 | 弱 | 否 |
| `shred_loop` | 弱 | ●●● 200–800 Hz 研磨主体 | ●●● 纹理核心 | ● 1.5–5 kHz 纹理 | 弱 | 弱 | 是 |
| `shred_start` | 弱 | ●●● 80–400 Hz 电机启动 | ●● 过渡 | ●● 800 Hz–3 kHz 咬入 | 弱 | 弱 | 否 |
| `shred_end` | 弱 | ●●● 100–600 Hz 减速 | ●● | 弱 | 弱 | 弱 | 否 |
| `product_land` | 极弱 | ●● 200–600 Hz 共鸣 | ●●● 400–1500 Hz 主体 | ● 1.5–4 kHz | 弱 | 极弱 | 否 |
| `lever_drag` | 极弱 | ●●● 150–400 Hz 摩擦 | ●●● 400–800 Hz 核心 | ● 800–2000 Hz | 极弱 | 极弱 | 是 |
| `shelf_add` | 无 | 弱 | ●● 500 Hz–1.5 kHz | ●● 1.5–3 kHz | 弱 | 极弱 | 否 |
| `shred_pulse`（Haptic 节奏，无独立 SFX） | — | — | — | — | — | — | — |

`●` = 低电平存在；`●●` = 中等能量；`●●●` = 主导频段

### §4.3 具体冲突区间与解决动作

#### 冲突 C1：200–400 Hz（BGM 钢琴中频 vs `shred_loop` 中低频研磨 vs `lever_drag` 摩擦）

**冲突描述：** 三者在 200–400 Hz 同时存在时（`shred_loop` 或 `lever_drag` 播放期间），BGM 的钢琴低音区与两个循环 SFX 的研磨/摩擦主体产生频率堆叠，导致"泥状中频"听感。

**时序说明：** `lever_drag` 和 `shred_loop` 不会同时播放（`lever_drag` 在摇杆拖拽时，`shred_loop` 在粉碎机运转时，两者时序互斥）。但 BGM 与两者均会同期出现。

**解决动作：**
- **BGM 让位**：bgm-direction.md §3.4 冲突 1 规避方案已规定——BGM master 轨在 200–400 Hz 做 -3 dB 轻微 EQ 凹陷（shelf 式）；BGM 钢琴左手声部避开此频段密集和声堆积。
- **`shred_loop` 配合**：`shred_loop` 在 200–400 Hz 做 -2 dB @ 300 Hz（Q=1.5）EQ 修剪（§3.3 ⑦ 后期关键步骤已规定）。
- **`lever_drag` 配合**：`lever_drag` 在 200–400 Hz 做 -2 dB @ 300 Hz EQ 修剪（§3.7 ⑦ 后期关键步骤已规定）。
- **时序自然错开**：`lever_drag` 时 `shred_loop` 未播放；`shred_loop` 时 `lever_drag` 已停止——最重要的冲突缓冲来自时序。

#### 冲突 C2：800–3000 Hz（`lever_pull` body vs `reveal_pop` body）

**冲突描述：** `lever_pull` Layer B（800 Hz–3 kHz 金属碰撞）与 `reveal_pop` Layer A+B（800 Hz–4 kHz 清脆主体）频段高度重叠。

**时序说明：** 两者**不会同时发声**——`lever_pull` 触发粉碎序列开始，`reveal_pop` 是序列结束后揭晓时的声音。两者之间隔着完整的粉碎过程（2.5–4 s 以上）。

**解决动作：** 无需 EQ 处理，时序自然隔离。但在 mix 阶段应注意两者 UpMid 频段的个体音色有明确区分——`lever_pull` 偏"金属咔嚓"（硬边），`reveal_pop` 偏"清脆材质"（圆润），通过音色特征区分而非 EQ 让位。

#### 冲突 C3：2–6 kHz（`reveal_pop` transient vs BGM 钟琴）

**冲突描述：** `reveal_pop` 的 transient 核心（3–4 kHz 主峰）与 BGM 钟琴装饰音（800 Hz–5 kHz）的高频段重叠，可能在 2–4 kHz 区间产生遮蔽。

**解决动作：**
- **BGM 让位**：bgm-direction.md §3.4 冲突 3 规避方案——BGM 钟琴使用低力度、缓攻击（soft attack）触键，transient 能量远低于 SFX；`audio_bgm_offset_db = -12 dB` 已提供足够 headroom。
- **无需额外 ducking**：与 Juice Cookbook VA-6 结论一致，-12 dB 偏移已充分让路。
- **生产提示**：如真机测试出现遮蔽，优先砍 BGM 钟琴 2–4 kHz 的 attack 速度，而不是修改 `reveal_pop` 链路（bgm-direction.md §3.4 明确规定）。

#### 冲突 C4：400–800 Hz（`shred_loop` 纹理节奏 vs BGM 和声节奏）

**冲突描述：** `shred_loop` 在 400–800 Hz 有周期性纹理强调点（每 400 ms），BGM 若在此频段有节奏性切分，两者会形成节奏干扰或倍频共鸣感。

**解决动作：**
- **BGM 节奏静态化**：bgm-direction.md §3.4 冲突 2 规避方案——BGM 在 400–800 Hz 的和声成分保持静态（长音/缓慢扫弦），不做节奏性切分；BGM 旋律 BPM（约 60–72）与 `shred_loop` 纹理节奏（约 150 BPM 等效，每 400 ms 一次）不形成 2:1 倍频关系。

#### 冲突 C5：`lever_pull`（80–400 Hz）vs `shred_start`（80–400 Hz）时序邻接

**冲突描述：** `lever_pull` 后紧接 `shred_start`（时序：lever_pull → ~0.1 s → shred_start），两者均在 80–400 Hz 有强能量。

**时序说明：** `lever_pull` 总长约 80–150 ms，`shred_start` 在其结束后约 100 ms 发出——自然间隔约 100–200 ms。由于 `lever_pull` 已进入 decay 阶段，与 `shred_start` 的 Layer A 起音时实际能量重叠轻微。

**解决动作：** 无需 EQ 处理；时序间隔已自然避开最大能量重叠。生产阶段注意 `shred_start` 的起音不要过快（≤ 10 ms 有效起音即可），让 `lever_pull` 的 decay 有足够时间。

#### 冲突 C6：全局 Ducking 策略说明

根据 audio-system.md F-2、bgm-direction.md VA-6 及 §2.1 全局约定：

- **BGM 与 SFX 总线采用固定偏移（-12 dB），不做动态 ducking**
- `shred_loop` 与 BGM 同期播放时，`shred_loop`（SFX 总线 0 dB 基准）天然比 BGM 响约 12 dB，这是设计意图
- 所有冲突的解决方案均优先通过 **时序错开** 和 **音色 EQ 区分** 处理，而非动态 ducking
- 唯一需要主动 EQ 处理的两处已锁定：BGM 200–400 Hz -3 dB（bgm-direction.md 执行）+ `shred_loop`/`lever_drag` 200–400 Hz -2 dB（本 spec §3.3/§3.7 执行）

---

## §5 生产任务清单

### §5.1 采集路线决策说明

每个 SFX 的最终采集路线基于：(A) 音色目标复杂度，(B) Foley 录制的可行性，(C) 商业库风险（通用感）。优先级：Foley 一线录制 > Foley + 合成补足 > 商业库筛选。

### §5.2 生产任务表

| # | 事件 ID | 优先级 | 采集路线 | 变体数 | 生产顺序 | 预估工时（小时） |
|---|---|---|---|---|---|---|
| 1 | `lever_pull` | P1 ★ | **Foley 一线 + 合成补足**（方案 A 滑轨录制 + 合成 sub-bass Layer A） | 3 | v1 基线优先，锁定 Layer A+B，v2–v3 再增 pitch 变化 | 4.0 |
| 2 | `reveal_pop` | P1 ★ | **Foley 一线**（精细玻璃杯/茶碗轻敲，方案 A） | 3 | v1 基线（Layer A+B），v2–v3 音色微调 + pitch 变化 | 3.0 |
| 3 | `shred_loop` | P2 | **Foley 一线 + 后期处理**（旧式碎纸机连续录音，选段循环，BGM EQ 修剪） | 1（循环） | 单一工作文件，重点在循环点剪辑与周期性纹理验证 | 3.5 |
| 4 | `shred_start` | P2 | **Foley 一线**（旧式电机启动录音，Layer A + Layer B 延后 30 ms 合并） | 2 | v1 基线（双层结构），v2 音色变体 | 2.5 |
| 5 | `shred_end` | P2 | **Foley 一线**（电机/风扇断电减速录音） | 2 | v1 基线，v2 音色变体 | 2.0 |
| 6 | `lever_drag` | P3 | **Foley 一线 + 后期处理**（木制抽屉摩擦录音，BGM EQ 修剪，循环点剪辑） | 1（循环） | 单一工作文件；重点在自然循环点 + 摩擦质感均匀性 | 2.5 |
| 7 | `product_land` | P3 | **Foley 一线 + 少量合成补足**（橡皮/豆包落桌录音，Resolution Tone 可后期 EQ 强化或单独录制音叉叠加） | 3 | v1 基线（三层结构），v2–v3 pitch 变体 | 3.0 |
| 8 | `shelf_add` | P4 | **Foley 一线**（精装书插书架录音，方案 A） | 2 | v1 基线，v2 音色变体 | 1.5 |
| 9 | `BGM_main_loop` | P5 | **N/A — 详见 bgm-direction.md**（作曲/编曲委托，不属于 SFX 录制流程） | 1（循环） | 独立生产流程 | N/A |

**总工时合计（SFX 1–8，不含 BGM）：22.0 小时**

分解：
- P1 事件（lever_pull + reveal_pop）：7.0 小时
- P2 事件（shred_loop + shred_start + shred_end）：8.0 小时
- P3–P4 事件（lever_drag + product_land + shelf_add）：7.0 小时

### §5.3 生产注意事项

- **验收基线**：每个事件的 v1 变体必须通过"闭眼测试"——在无视觉的情况下，声音本身应能传递预期情感（参照 §3 各事件 ③ 音色描述的情感目标）。v1 基线通过后再生产 v2–v3 变体。
- **循环 SFX 优先验证**：`shred_loop` 和 `lever_drag` 的循环点须在 DAW 中 A/B 对比无缝后，再进入 Godot import 阶段手动校准循环点。
- **响度一致性**：所有同优先级事件在生产完成后须进行一次整体响度校准会话（对比聆听），确保 §3 各事件 ⑨ 定义的相对音量关系成立。
- **Foley 工作室要求**：录制环境须有轻微自然混响（小书房/工作室）；不建议消声室（`reveal_pop` 等需要轻微空间感）。
- **文件交付命名**：严格遵循 §2.2 规范（`sfx_[event_id]_v[n].wav` / `sfx_[event_id]_loop.ogg`）。

---

## §6 下游契约

### §6.1 音触同步窗口表（有 Haptic 对位的 6 个事件）

重申 §2.4 约束，集中汇总供下游系统实现参考。

| 事件 | Audio 起音约束 | Haptic 预设 | 发射顺序 | 感知到达差（估算） |
|---|---|---|---|---|
| `lever_pull` | ≤ 10 ms（有效起音） | `lever_lock`（heavy） | `AudioSystem.play(&"lever_pull")` → await 35 ms → `Haptic.play(&"lever_lock")` | ≈ 0–5 ms ✅ |
| `reveal_pop` | ≤ 5 ms（有效起音） | `reveal_pop`（selection） | `AudioSystem.play(&"reveal_pop")` → await 35 ms → `Haptic.play(&"reveal_pop")` | ≈ 0–5 ms ✅ |
| `shred_start` | ≤ 10 ms（有效起音） | `shred_start`（medium） | `AudioSystem.play(&"shred_start")` → await 35 ms → `Haptic.play(&"shred_start")` | ≈ 0–5 ms ✅ |
| `shred_end` | ≤ 10 ms（有效起音） | `shred_end`（light） | `AudioSystem.play(&"shred_end")` → await 35 ms → `Haptic.play(&"shred_end")` | ≈ 0–5 ms ✅ |
| `product_land` | ≤ 8 ms（有效起音） | `product_land`（light） | `AudioSystem.play(&"product_land")` → await 35 ms → `Haptic.play(&"product_land")` | ≈ 0–5 ms ✅ |
| `shelf_add` | ≤ 8 ms（有效起音） | `shelf_add`（light） | `AudioSystem.play(&"shelf_add")` → await 35 ms → `Haptic.play(&"shelf_add")` | ≈ 0–5 ms ✅ |

**常量基准（entities.yaml registry）：**
- `audio_lead_ms = 35 ms`（haptic-system.md F-1 派生）
- `audio_haptic_sync_window_ms = 30 ms`（人类听觉同步察觉阈值）
- 有效起音定义：音频文件感知响度达到 -30 dBFS 的时刻距文件头的 ms 数

**不含 Haptic 对位的 3 个事件：**
- `lever_drag`：无 Haptic 对位（audio-system.md Core Rule 2 明确：连续音阶段离散触觉冲击与拖拽 fantasy 冲突）；起音约束放宽至 ≤ 50 ms（§2.4 例外条款）
- `shred_loop`：无直接对位（`shred_pulse` 由 Shred Process System 按 haptic-system.md F-2 独立调度）；起音约束 = 50–80 ms 淡入（§3.3 ④）
- `BGM_main_loop`：无同步约束

### §6.2 AudioSystem mix 优先级表（Core Rule 4 Ducking 规则参照）

根据 audio-system.md F-2 与 §4.3 冲突矩阵，9 个事件在 SFX 总线内的相对优先级与音量层次如下：

| 优先级 | 事件 | 目标响度 | 总线 | 备注 |
|---|---|---|---|---|
| 1 | `lever_pull` | -14 dBFS RMS | SFX | P1 核心打击，最高；在 BGM 和一切 SFX 中突出 |
| 2 | `reveal_pop` | -16 dBFS RMS | SFX | P1 核心揭晓 |
| 2 | `shred_start` | -16 dBFS RMS | SFX | P2 粉碎启动，与 reveal_pop 同级 |
| 3 | `shred_loop` | -23 dBFS LUFS | SFX（专用节点） | 循环 SFX；比非循环 SFX 低（LUFS vs RMS 不同度量，参照感知） |
| 3 | `lever_drag` | -23 dBFS LUFS | SFX（专用节点） | 循环 SFX；同 shred_loop 级别 |
| 4 | `product_land` | -18 dBFS RMS | SFX | P3；低于粉碎序列主事件 |
| 4 | `shred_end` | -18 dBFS RMS | SFX | P2 收尾，与 product_land 同级 |
| 5 | `shelf_add` | -20 dBFS RMS | SFX | P4；全序列最轻 |
| 背景 | `BGM_main_loop` | -23 dBFS LUFS 目标 | Music（-12 dB 偏移） | `audio_bgm_offset_db = -12 dB`（entities.yaml）；始终低于 SFX 层 |

**Ducking 策略：** audio-system.md 不实现动态 ducking（无 compressor sidechain）。层次关系完全由音频资产的 RMS/LUFS 目标值 + BGM 的固定 -12 dB 偏移实现静态平衡。pool 耗尽时 LRU 抢占（audio-system.md Edge Cases）。

### §6.3 Reduce Motion 全局降级矩阵（汇总表）

本表汇总所有 9 个 SFX 事件在三档 `reduce_motion_factor` 下的降级行为，用于 Accessibility System GDD（#16）实现参照。各事件的详细说明见 §3.x ⑩ 字段；本表是统一视角的契约承诺。

| 事件 | factor = 1.0（默认，关闭 RM） | factor = 0.5（中档） | factor = 0.0（全开 RM） |
|---|---|---|---|
| `lever_pull` | Layer A + B + C 全层 | Layer C（金属余震 tail）去除；A + B 保留 | 仅 Layer A（sub-bass transient）；B + C 去除 |
| `reveal_pop` | Layer A + B + C 全层（含混响尾 ~300 ms） | Layer C（混响尾）去除；A + B 保留（~120 ms） | 仅 Layer A（transient 冲击）；B + C 去除 |
| `shred_loop` | 全音量循环（-23 LUFS）；JC-R4 外部 bump 正常 | 维持全音量；外部 bump 由 Shred Process 决定 | 音量降低 -6 dB（-29 LUFS）；循环仍播放；外部 bump 按比例缩减 |
| `shred_start` | Layer A + B 完整（含 30 ms 时序错开） | Layer B（中高频咬入）去除；仅 Layer A | 仅 Layer A 最强段（≤ 100 ms 截短）；保证起动感知 |
| `shred_end` | Layer A + B 完整（400–600 ms） | Layer B（金属余震）去除；仅 Layer A 减速主体 | 仅 Layer A 最强段（约前 150 ms）；保证停止感知 |
| `product_land` | Layer A + B + C 完整 | Layer C（Resolution Tone 完成音调）去除；A + B 保留 | 仅 Layer A transient（碰撞核心）；B + C 去除 |
| `lever_drag` | 全音量循环（-23 LUFS） | 维持全音量（过程基底不降，降半会导致拖拽感知空洞） | 音量降低 -6 dB（-29 LUFS）；循环仍播放 |
| `shelf_add` | Layer A + B 完整（80–150 ms） | Layer B（空间共鸣尾）去除；仅 Layer A transient（约 50–80 ms） | 仅 Layer A 最强点（< 50 ms 截短）；保证入位感知 |
| `BGM_main_loop` | 不受影响 | 不受影响 | 不受影响 |

**实现约定（下游 Accessibility GDD 参照）：**
- 降级通过播放预混变体文件（每个 factor 档各一套文件）或由 AudioSystem 在播放时根据 factor 选择资产实现；具体方案由 godot-specialist 在 Accessibility GDD 实现阶段决定。
- 本 spec 锁定降级语义（哪层去除，音量如何变化），不锁定实现路径。
- "保证感知存在"的下限：即使 factor = 0.0，每个有 Haptic 对位的事件必须仍有可感知的 transient（保证声音与触觉的共同存在感）。无 Haptic 对位的循环 SFX（`shred_loop`、`lever_drag`）降至 -6 dB 而非静音，维持过程存在感。

### §6.4 与 bgm-direction.md 的对齐项

本 SFX spec 与 `design/audio/bgm-direction.md` 的接口契约对齐清单：

| 对齐项 | SFX spec 结论 | bgm-direction.md 对应节点 | 状态 |
|---|---|---|---|
| 200–400 Hz 频段让位 | `shred_loop` / `lever_drag` 各做 -2 dB @ 300 Hz EQ 修剪 | §3.4 冲突 1：BGM -3 dB + SFX 配合 | ✅ 对齐 |
| 2–6 kHz 无额外 ducking | `reveal_pop` 不要求 BGM 额外 duck | §3.4 冲突 3：-12 dB 偏移已充分让路（引用 VA-6） | ✅ 对齐 |
| 400–800 Hz 节奏静态化 | `shred_loop` 纹理节奏 400 ms 间隔；BGM 节奏不切分此频段 | §3.4 冲突 2：BGM BPM 60–72 与 shred_loop 纹理错开 | ✅ 对齐 |
| `shelf_add` 最弱让路 | -20 dBFS RMS，BGM -12 dB 偏移充分让路 | §3.4 频段规避总结表末行 | ✅ 对齐 |
| `BGM_main_loop` 字段接交 | §3.9 简化字段，音色/生产细节完整指向 bgm-direction.md | §1–§4 完整 BGM 规格 | ✅ 接交完成 |
| `shred_loop` 纹理节奏与 BGM BPM 协商 | `shred_pulse_interval_s = 0.4 s`（entities.yaml 锁定）；BGM BPM 选择权在 audio-director | bgm-direction.md §3.1 BPM 约束；Juice Cookbook OQ-6 | ⚠️ 开放问题——由 audio-director 在 BGM 生产阶段确认 BPM 不形成 2:1 倍频关系（避免 shred_loop 150 BPM 等效与 BGM BPM 精确倍频）|

### §6.5 entities.yaml 待补登记项

**须向 producer 提议补登记的 entities.yaml 条目：**

| 常量名 | 类型 | 建议值 | 理由 | 状态 |
|---|---|---|---|---|
| `sfx_lever_drag` | constants / string_key | `"lever_drag"` | `lever_drag` 当前仅作为 `_valid_loop_keys` 白名单成员隐式存在（audio-system.md 第 97–99 行），尚无 registry 常量。下游 Lever Interaction GDD 实现时需要 `sfx_lever_drag` 常量；与其他 8 个 sfx_* 常量对称。 | **⚠️ 需补登记** |

补登记建议格式（供 producer 参考）：

```yaml
  - name: sfx_lever_drag
    status: active
    source: design/gdd/audio-system.md
    referenced_by:
      - design/gdd/audio-system.md
      - design/gdd/lever-interaction.md    # 拖拽开始/结束时调用 play_loop/stop_loop
      - design/audio/sfx-selection-spec.md # SFX spec §3.7
    value: "lever_drag"
    unit: string_key
    notes: "循环键，需用 play_loop()/stop_loop() 而非 play()。无 Haptic 对位。专用播放器节点，不占 8 节点 SFX 池。起音约束放宽至 ≤ 50 ms（§2.4 例外）。"
    added: "2026-05-22"
    revised: ""
```
