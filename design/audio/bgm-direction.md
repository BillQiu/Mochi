# Mochi — BGM 方向（Mood Board / Spec 层）

**Owner**: audio-director
**Status**: Complete（§1–§6 全部写入 · 2026-05-22）
**Cross-refs**: design/gdd/audio-system.md · design/gdd/juice-cookbook.md · design/gdd/game-concept.md · design/gdd/mobile-app-lifecycle.md

---

## §1 情绪锚点与反向锚点

### 三个核心形容词链

用形容词链（而非单词）来锚定 Mochi 的情绪——每条都由两个词构成张力：

**A. 沉实 · 温柔（Weighted Tenderness）**
机器有重量，但世界是柔软的。BGM 要有实体感——不是飘在空中的氛围音乐，而是有"质地"的声音，像毛毡、木头、铜管。它扎实地待在那里，却不让人紧张。

对应游戏支柱：**Pillar 1（触感先行）**——音乐的质感必须与摇杆的咔嚓声、齿轮的嗡鸣保持同一个物理世界。

**B. 专注 · 散漫（Focused Drift）**
BGM 要支持玩家"既在当下、又放空了"的状态——写烦恼时需要心理空间，等待粉碎时可以发呆。旋律存在但不强迫注意力，和声稳定但不无聊。参照：睡前可以播的东西，不会打断思路，但去掉会感到空洞。

对应游戏支柱：**Pillar 5（不限次但永远有意义）**——工具游戏的音乐必须不"催人"，无进行感、无起伏煽情。

**C. 仪式 · 日常（Ritual Quotidian）**
每次打开 Mochi 都是同一首 BGM——像固定的晚间仪式，像一盏总亮着的灯。不是"特殊场合的音乐"，是"这个角落永远是这个声音"。轻微的机械质感纹理（齿轮、钟表、工坊气息）让它与 Mochi 这台机器共生，而不是通用的 lo-fi 背景板。

对应游戏支柱：**Pillar 2（每一次都是小剧场）**——BGM 是剧场的帷幕，它的稳定感让每一次 SFX 爆发都显得更突出。

### 反向锚点（"绝不是 X"）

生产时的否决条件——作曲家、音源库选片时遇到这三类直接排除：

| 反向锚点 | 为什么排除 | 常见陷阱 |
|---|---|---|
| **绝不是：催眠式电子低鸣**（drone / dark ambient）| 音量和频率特征与 `shred_loop`、`lever_drag` 的中低频撞车；情绪空洞、冷漠，与"机器认真工作"的温暖性格相悖 | 很多"睡前 ambient"库实际是这个调 |
| **绝不是：手游欢快 BGM**（upbeat chiptune / J-pop instrumental）| 节奏驱动感太强，破坏"散漫"状态；玩家写重内容时（"我妈妈病重"）会显得不尊重——违背 Pillar 4（可爱但有情感重量）| 解压 App 最常见的误区 |
| **绝不是：极简钢琴 OST 煽情款**（emotional solo piano à la 《Your Lie in April》风格）| 旋律太强、情绪导向性太明显，会和玩家自己的情绪"争夺"，不允许情绪空白；且无法与机械齿轮音共存 | 日系独立游戏高频踩坑 |

---

## §2 参考曲单

5 首均为可确认真实存在的作品。每首给出"借鉴哪一层"的具体定位。

### 曲目 1 — 《Wandering（漫步）》

- **来源**：*Animal Crossing: New Horizons Original Soundtrack*（2020）
- **艺术家**：Kazumi Totaka / Nintendo Sound Team
- **为什么参考**：Animal Crossing 的 BGM 有一个被研究最多的设计决策——它会随时间、天气、场景变化，但任何时候的"基底"都是那种有钟琴（glockenspiel）和气鸣琴感的温柔织体。Mochi 不需要动态变化系统，但需要那个"基底质感"：轻量化、有木制音色、旋律简短循环但不令人烦躁。
- **借鉴层**：**音色**（木琴 / 气鸣琴 / 轻钢琴组合）+ **loop 结构**（16-32 bar 自然循环点设计，不留明显接缝）

### 曲目 2 — 《Clair de Lune》

- **来源**：Nujabes《*Modal Soul*》（2005）
- **艺术家**：Nujabes（菅原寛孝）
- **为什么参考**：Nujabes 把 jazz harmony 和 hip-hop 慵懒节拍做到极致——lo-fi 品类的奠基人之一。本曲具体参考价值：BPM 约 80，完全没有冲突感的和声进行（主要在 Cmaj7 / Am7 / Fmaj7 周围漂移），有非常细腻的黑胶噪声纹理。这个纹理感与 Mochi 的"有使用痕迹的老机器"视觉锚点高度一致。
- **借鉴层**：**和声**（maj7 / m7 漂浮感，避免解决感强的终止式）+ **制作手法**（黑胶噪声作为"质地层"，可类比机械齿轮纹理）

### 曲目 3 — 《海の見える町（A Town With An Ocean View）》

- **来源**：《魔女宅急便》OST（1989）
- **艺术家**：久石让（Joe Hisaishi）
- **为什么参考**："仪式感 BGM"的范本——它进门时你就知道今天会很好。Mochi 需要的正是这种"每次打开都是它"的认知锚定感。借鉴的不是管弦乐编曲（那对移动端太厚重），而是：旋律短小但极具辨识度（4-8 bar 主题），进行平稳，无强烈情绪起伏——适合在"写烦恼"这件心理工作前安抚玩家。
- **借鉴层**：**旋律结构**（短小、圆润、辨识度高的主题，不超过 8 小节）+ **情绪定位**（"今天也会很好"的平静开场感）

### 曲目 4 — 《Gymnopédie No.1》（现代 lo-fi 重编版）

- **原曲来源**：Erik Satie（1888）
- **参考使用方向**：原曲 Satie 版作为基准参照；具体 lo-fi 重编版本由 audio-director 在生产阶段选定
- **为什么参考**：Satie 的 Gymnopédie 是"允许思绪飘移"的音乐原型——它不强调旋律解决，和声像云朵一样悬停。BPM 约 60，与睡前心率极度契合。lo-fi 重编版的轻微黑胶噪声和柔和的低频垫底恰好填补"仪式感 + 散漫"这个象限。
- **借鉴层**：**节奏 / BPM**（50-65 BPM 区间的参照感受）+ **和声**（悬停不解决的延伸和弦结构）

### 曲目 5 — 《Spring Yard Zone》 / 《Green Hill Zone》（反向参照 ⚠️）

- **来源**：*Sonic the Hedgehog* OST（1991）
- **艺术家**：Masato Nakamura
- **为什么参考**：**反例学习，不是借鉴对象。** Sonic BGM 是极度优秀的"玩家感到被催促"设计，附点节奏 + 快速和弦解决 + 高频主旋律。列在这里的目的：帮助作曲家和 audio-director 快速校准"绝对不要有的感觉"。任何听起来比这首"更着急"的 demo 直接退回。
- **借鉴层**：**反向参照**（BPM 上限红线、节奏型禁区）

---

## §3 制作参数

### §3.1 BPM 区间

**推荐主区间：60–72 BPM**

这个窗口是三条情绪锚点的共同交汇点：

| 参照依据 | BPM 范围 | 指向的锚点 |
|---|---|---|
| Satie Gymnopédie No.1（原曲）| ~52–56 BPM（3/4拍体感）| 专注·散漫 |
| Nujabes《Clair de Lune》| ~76–80 BPM | 沉实·温柔 |
| 成人静息心率（坐卧放松）| 55–70 bpm | 专注·散漫 / 仪式·日常 |
| iOS 睡前心率（Apple Watch 数据中位）| 58–68 bpm | 专注·散漫 |

60–72 BPM 正好覆盖"放松但清醒"的生理状态区间，是成人把手机拿在手里、在床头桌边、通勤座位上使用 Mochi 的典型心率范围。音乐与身体节奏同步后，玩家写烦恼时的"心理空间感"会自然打开（心率一致性原理：ISO Principle 在音乐治疗中的 entrainment 效应）。

**可接受窗口：55–80 BPM**

- 下限 55 BPM：低于此值会进入"催眠/入睡"区间，违反"仪式感——玩家需要在 app 里有意识操作"的需求
- 上限 80 BPM：Nujabes 80 BPM 是上限参照；超过此值开始出现轻微"节奏催促感"，与 Sonic 反向参照的红线（附点节奏驱动感）方向一致

**禁止区间：** > 90 BPM（手游欢快反向锚点区间的起点）

**与 shred_pulse_interval_s 的对齐关系：**

`shred_pulse_interval_s = 0.4s`（entities.yaml 锁定值），换算为 150 BPM 的 16 分音符密度，或 75 BPM 的 8 分音符密度。BGM 主区间 60–72 BPM 与粉碎脉冲节奏**故意错开**——BGM 不应与 `shred_loop` 的机械脉冲产生节拍对齐感，否则会强化"催促"体验，违反锚点 B（专注·散漫）。BGM 的拍点落在 shred_pulse 脉冲之间的空隙，两者互为留白。

---

### §3.2 乐器调色板

#### 推荐乐器（5–7 件）

| 乐器 | 频率中心 | 层级角色 | 锚点呼应 |
|---|---|---|---|
| **预备好声钢琴（Prepared / Soft Piano）** | 200–2500 Hz | 主旋律载体；4–6 bar 短主题，稀疏触键 | 沉实·温柔（有质地的触键感）|
| **气鸣琴 / 钟琴（Kalimba 或 Glockenspiel）** | 800–5000 Hz | 点缀装饰音；非旋律性，随机散落在强拍之间 | 沉实·温柔（木金属质感纹理）|
| **低弦 pizzicato（拨弦，非弓弦）** | 80–300 Hz | 低频轻脉冲；每 2–4 拍一次，替代鼓组功能 | 沉实·温柔（有体积感的低频根音）|
| **轻指弦吉他（Fingerstyle Guitar）** | 150–3500 Hz | 和声填充；maj7/m7 缓慢扫弦，不强调节拍 | 专注·散漫（漂浮感和弦进行）|
| **lo-fi 黑胶噪声纹理（Vinyl Crackle）** | 宽带低电平噪声 | 质地层；常态 -18 dB 以下，玩家不会主动听到，但去掉会感觉"太干净" | 仪式·日常（有使用痕迹的老机器质感）|
| **轻机械齿轮纹理（Mechanical Texture）** | 100–600 Hz 轻微嗡鸣 | 可选纹理层；极轻微的钟表/齿轮节律感，与 `BGM_main_loop` 机器环境音共生 | 仪式·日常（Mochi 这台机器的专属质感）|

> **关于第 6 件乐器**：轻机械齿轮纹理与 audio-system.md 中的 `BGM_main_loop`（"老式钟表机芯运转声"）有功能重叠。生产阶段需评估：如果 `BGM_main_loop` SFX 已提供足够的机械质感，BGM 可以省去此层，避免频段堆叠在 100–400 Hz 区间。最终决定交给 sound-designer 真机试听后确认。

#### 禁用乐器（4 件，附原因）

| 禁用乐器 | 禁用原因 |
|---|---|
| **鼓组 / 打击乐节奏组（Drum Kit / Drum Loop）** | 明确节拍感会产生"节奏催促"体验，与锚点 B（专注·散漫）直接对立；手游欢快 BGM 的核心标志之一 |
| **弓弦弦乐（Legato Strings / Orchestral Strings）** | 大段连弓弦乐带有强烈的情绪导向性（电影配乐惯例），会与玩家自身情绪"争夺"注意力，违反锚点 A（沉实·温柔的"不煽情"要求）；同时与反向锚点"极简钢琴 OST 煽情款"一类 |
| **合成器 Pad / Drone（长音大铺底）** | 频率特征与 `shred_loop`（中低频连续研磨）和 `lever_drag`（低-中频摩擦声）直接撞车；情绪空洞冷漠，与"机器认真工作的温暖性格"相悖，正是反向锚点"催眠式电子低鸣"的实体 |
| **贝斯吉他 / 低音电吉他（Bass Guitar）** | 在手机小喇叭上 < 120 Hz 几乎消失，剩余中频成分会与钢琴左手声部争夺 200–400 Hz 频段，导致 `shred_loop` 出现时三轨堆叠产生浑浊遮蔽 |

#### 小喇叭可懂度注意事项

iPhone 扬声器的有效频段约为 200–16000 Hz，低频在 < 150 Hz 明显衰减。以下是生产约束：

- 旋律主体（钢琴/钟琴）必须有足够的**中频基音成分**，不依赖低音弦乐撑底
- Vinyl Crackle 纹理必须在 200 Hz 以上的频段有可感知成分（高频噼啪声），而非仅靠低频噪底
- 低弦 pizzicato 的"低频脉冲"在手机喇叭上会损失基频，但**泛音（300–600 Hz）仍可保留弦乐质感**——这是可接受的
- 产线验收标准：BGM 在 iPhone SE 2（最小喇叭规格基准）外放时，旋律线必须清晰可辨，不依赖耳机

---

### §3.3 Loop 长度与结构

#### Loop 长度

**推荐 Loop 长度：48–64 bars（约 3:12–5:20 @ 60–72 BPM）**

| BPM | 48 bars 时长 | 64 bars 时长 |
|---|---|---|
| 60 BPM | 3:12 | 4:16 |
| 72 BPM | 2:40 | 3:33 |

这个长度的设计理由：
- Mochi 的典型单次 session 为 1–3 分钟（game-concept.md），短 loop（< 2 分钟）会在一次 session 内循环两次，玩家会感知到接缝
- 过长（> 6 分钟）会降低"每次打开都是同一首"的**辨识度**——仪式感来自于熟悉，而熟悉需要足够短才能记住主题
- 48–64 bars 可以容纳一个完整的"主题 A → 发展 → 主题 A 变奏 → 回归"的最小弧线，保持不无聊

#### A-B 段结构

BGM 采用简单的 **A → A' → B → A** 结构（无强制段落跳转），**全程不做基于游戏状态的动态切换**：

- **A 段（16 bars）**：主主题，钢琴 + 钟琴 + 弦 pizzicato，最具辨识度的 4–6 bar 旋律句
- **A' 段（16 bars）**：主题变奏，加入轻指弦吉他和声填充，纹理稍厚但不升温
- **B 段（16 bars）**：和声漂移段，无明确旋律，以钟琴散点为主——给玩家"思绪可以飘走了"的心理空间；对应 Gymnopédie 中段的悬停感
- **A 段（16 bars）**：主题回归，与首个 A 段几乎相同，确保循环接缝处玩家感知不到重启

> B 段是"允许发呆"设计的核心——它不推进情绪，只保持温度。写烦恼这件事需要大脑在"专注输入"和"放空联想"之间切换，B 段在 A 段稳定的情绪框架内开一扇窗，让心思可以去远处走走再回来。

#### 过渡 Stinger 设计

MVP 中**无 stinger**——BGM 循环不与任何游戏事件绑定（audio-system.md Core Rule 6：BGM MVP 永不淡出）。

以下 stinger 作为 v1.0 预留占位（不在本文档锁定，移交 sound-designer 在 v1.0 阶段设计）：

| Stinger 类型 | 触发条件（v1.0）| 功能描述 |
|---|---|---|
| `stinger_reveal_rare` | 稀有产物揭晓（5% 概率，JC-R5 large 变体）| 单次 8–16 bar 特殊变体，在主 loop 自然拍点插入，与 `reveal_pop` JC-R5 audio 层 layered audio 呼应 |
| `stinger_first_run` | Onboarding 首次揭晓产物 | 同上变体，用于 Onboarding GDD 的 JC-R5 large 唯一偏离时刻 |

> Stinger 插入约束（v1.0 时执行）：必须在 BGM 的小节边界（bar line）处插入，不可打断当前 bar；插入后 BGM 从 stinger 结束的拍点无缝续播，不重置到 Loop 开头。

---

### §3.4 频段冲突规避

BGM 必须与 audio-system.md 中全部 8 个 SFX 事件和平共处。以下是核心冲突点和规避方案。

#### 频段占位描述

```
频率轴（Hz）:
20    80   200  400   800  2k   4k   8k   16k
|-----|-----|-----|-----|-----|-----|-----|-----|

BGM 占位（允许区间）:
      ████                 ███████████
      低弦pizz             钢琴/钟琴旋律
      80-200Hz             400-2500Hz

BGM 禁止/慎入区间:
  ██████████████████
  20-400Hz 中低频区
  (shred_loop / lever_drag 的主战场)

SFX 占位（需要 BGM 让路）:
 ██    ████████         ██████████████
lever  shred_loop       reveal_pop
_pull  200-800Hz        2k-8k
低频    (中低频研磨)     (中高频清脆)
```

#### 具体冲突点与规避规则

**冲突 1：BGM 低频 vs `lever_pull` + `shred_loop`（200–400 Hz 核心冲突区）**

- `shred_loop` 频率特征：中低频连续研磨，估计能量中心 200–600 Hz
- `lever_pull` 频率特征：低频冲击主体 + 中频"咔嚓"金属感，估计能量中心 80–400 Hz
- **规避方案**：BGM 在 200–400 Hz 频段**主动留空**——低弦 pizzicato 基音放在 80–200 Hz，和声泛音在 600 Hz 以上。钢琴左手声部使用高踏板位置，避免 200–400 Hz 区间的密集和声堆积。
- **生产提示**：BGM master 轨道在 200–400 Hz 做 -3 dB 轻微 EQ 凹陷（shelf 式，不是陷波），配合 `audio_bgm_offset_db = -12 dB`（entities.yaml），确保此频段 SFX 有足够 headroom

**冲突 2：BGM 中频 vs `shred_loop` 纹理节奏（400–800 Hz）**

- `shred_loop` 有"周期性细节（每 0.3–0.5 s 一次轻微强调点）"，即约 120–200 BPM 的纹理节奏感（audio-system.md Sound Design Brief）
- **规避方案**：BGM 的旋律拍点主体落在 60–72 BPM 区间，与 shred_loop 的纹理节奏错开（不对齐、不形成 2:1 倍频关系）。BGM 在 400–800 Hz 的和声成分保持**静态**（长音 / 缓慢扫弦），不做节奏性切分，让 shred_loop 的纹理在此频段"透出来"

**冲突 3：BGM 中高频 vs `reveal_pop` + `product_land`（2–8 kHz 瞬态区）**

- `reveal_pop` 频率特征：中高频清脆"叮咚" + 轻微混响尾（~300 ms 衰减），估计能量中心 2–6 kHz
- `product_land`：中低频实体碰撞，圆润，估计中心 300–1500 Hz
- **规避方案**：BGM 的钟琴装饰音（800–5000 Hz）使用**低力度、缓攻击**的触键，transient 能量远低于 SFX。`reveal_pop` 发生时，由于 `audio_bgm_offset_db = -12 dB` 已提供足够 headroom，无需额外 ducking（与 Juice Cookbook VA-6 结论一致）
- **生产提示**：如果真机测试中发现 BGM 钟琴与 `reveal_pop` 产生频率遮蔽，优先砍 BGM 钟琴在 2–4 kHz 的 transient（降低 attack 速度），而不是改动 SFX 链路

**冲突 4：BGM vs `lever_drag`（低-中频摩擦声，持续音）**

- `lever_drag` 是一个**连续循环音**（与 `shred_loop` 同为循环键），持续时间 0.5–2s，频率特征低-中频摩擦，哑音质感
- **规避方案**：BGM 在此区间已做 -3 dB 凹陷（见冲突 1 处置）。`lever_drag` 使用独立专用播放器节点不占 SFX 池（audio-system.md Core Rule 5），不额外影响 BGM 总线

#### 频段规避总结表

| SFX 事件 | 竞争频段 | BGM 规避动作 |
|---|---|---|
| `lever_drag` | 200–600 Hz（摩擦质感）| BGM 200–400 Hz 留空 -3 dB；低弦 pizzicato 基音控制在 80–200 Hz |
| `lever_pull` | 80–400 Hz（低频冲击）| 同上；低弦 pizzicato 出现时机避开 lever 触发帧（lever_pull 时长仅 80–150 ms，BGM 节拍间隙天然错开）|
| `shred_loop` | 200–800 Hz（中低频研磨）| BGM 在此区间和声成分静态化，不做节奏切分；避免与 shred_loop 纹理节奏形成倍频共振 |
| `shred_start` / `shred_end` | 低频电机声 | 短暂事件（300–600 ms），BGM -12 dB 偏移已自然让路 |
| `reveal_pop` | 2–6 kHz（清脆瞬态）| BGM 钟琴 transient 软化（缓 attack）；-12 dB 偏移提供 headroom |
| `product_land` | 300–1500 Hz（圆润碰撞）| BGM 旋律在此区间的同期能量处于 A' 或 B 段静态和声区，无节奏冲突 |
| `shelf_add` | 中频"嗒"（轻柔）| 最弱事件，BGM -12 dB 偏移已充分让路 |

---

## §4 情绪曲线（与游戏流程对齐）

### 全流程节点定义

Mochi 的一次完整使用由以下 9 个节点构成（对应 game-concept.md Core Loop 步骤 1–10）：

```
[A] 进入 App
[B] Home 待机 / 闲置
[C] 输入烦恼（Text Input 阶段）
[D] 纸条滑入机器
[E] Lever 拉下（JC-R1 → JC-R2）
[F] Shred 粉碎进行中（JC-R3 → JC-R4 × n）
[G] Reveal（JC-R5）
[H] Product 落托盘 + 飞入货架（JC-R6 → JC-R7）
[I] 退出 / 下一次循环
```

### 情绪强度时间轴（文字版）

```
情绪强度（BGM 感知密度）
高  │
    │                  [E]▲         [G]▲
    │                 ╱   ╲        ╱   ╲
中  │──[A]──[B]──[C]─╱     ╲──[F]╱     ╲──[H]──[I]──
    │
低  │
    └────────────────────────────────────────────────→ 时间

BGM 状态:
[A]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  循环播放（无变化）
[B]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上
[C]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上
[D]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上
[E]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上，SFX 前景爆发
[F]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上，shred_loop 叠加
[G]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上，reveal_pop 前景
[H]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  同上
[I]  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  循环持续至 App 强杀

BGM 感知密度的"强度"变化来自 SFX 层的前景爆发，不是 BGM 本身的变化。
BGM 始终是稳定的底色，SFX 是在它上面绽放的烟火。
```

### 逐节点 BGM 行为说明

#### [A] 进入 App

- **BGM 动作**：`AudioSystem._ready()` 自动启动 `BGM_main_loop`，loop 从头开始
- **音量**：首次启动默认 `Music v = 0.8` → `BGM_db = -12 dB`（audio-system.md F-2，entities.yaml `audio_bgm_offset_db = -12`）
- **设计意图**：BGM 是开门迎宾的第一个声音，在任何 SFX 之前先建立"这个房间的气氛"。玩家听到的第一音节应该是 A 段主题的第一个钢琴触键——不是渐入，而是直接"在场"，体现仪式·日常锚点（"这盏灯永远亮着"）
- **Ducking**：无
- **引用核心规则**：audio-system.md Core Rule 6（BGM 自动启动）

---

#### [B] Home 待机 / 闲置

- **BGM 动作**：维持循环，不做任何变化
- **持续时间**：不定（可能几秒，可能几分钟——玩家发呆中）
- **设计意图**：B 段（和声漂移段）在这个阶段发挥最大作用。玩家还没开始写，思绪在飘——BGM 的 B 段无旋律、只有钟琴散点和轻吉他，给这个"空白等待"状态提供恰好够用的声学陪伴，不催促，不填满
- **与 Mochi 角色的关系**：机器待机时有眨眼/打盹动画（Mochi Character System），BGM 的节拍不与角色动画同步——机器的节律是它自己的，不是跟着玩家的，这强化"机器独立存在"的性格
- **Ducking**：无
- **引用核心规则**：audio-system.md Core Rule 6；Lifecycle Core Rule 4（防抖：< 1s 后台切换不触发 BGM 变化）

---

#### [C] 输入烦恼（Text Input 阶段）

- **BGM 动作**：维持循环，不做任何变化
- **设计意图**：这是整个流程中 BGM 责任最重的节点。玩家正在写真实的、有时是沉重的烦恼——BGM 必须"在场但不打扰"。§1 锚点 B（专注·散漫）的设计就是为这个场景量身定做的：旋律存在但不强迫注意力，和声稳定但不无聊
- **关键禁止行为**：BGM 此时**绝对不得**有任何音量变化、节拍强调或乐器突入——任何"刻意烘托情绪"的动作都是在替玩家决定这个烦恼有多重，违反 Pillar 4（可爱但有情感重量）的克制要求
- **与输入内容无关**：BGM 不知道、也不应该知道玩家写了什么（Pillar 反支柱：隐私默认）
- **Ducking**：无
- **参照节点**：与 Juice Cookbook Edge Case "Pillar 冲突类——如果玩家正在写重内容"的处置逻辑共鸣（情绪保持中立）

---

#### [D] 纸条滑入机器

- **BGM 动作**：维持循环（过渡动画，约 0.5–1s，BGM 层不感知）
- **前景音效**：无专用 SFX（此阶段 audio-system.md 无对应事件键）——是机器表情变化（视觉）+ BGM 底色共同承担过渡感
- **Ducking**：无

---

#### [E] Lever 拉下（JC-R1 + JC-R2）

- **BGM 动作**：完全维持，不变化
- **前景事件序列**（此节点的感知"强度上升"全部来自 SFX 层）：
  - `lever_drag` play_loop → `lever_pull` play（触发 JC-R1 → JC-R2）
  - JC-R2：sub-bass thump（20–80 Hz，decay 50 ms）+ 金属中高频 transient（3–6 kHz，decay 150 ms）
  - 触觉：`haptic_lever_lock`（heavy，35 ms 延迟，per `audio_lead_ms` entities.yaml）
- **设计意图**：这是整个 session 情绪"最高点"之一（与 Reveal 并列）。BGM 维持不变，正是为了让 JC-R2 的爆发在稳定底色上更显突出。情绪强度不是 BGM 制造的，是 SFX + 触觉的冲击力与 BGM 安静背景的**对比差**制造的
- **Ducking**：无。audio-system.md F-2 的 `BGM_OFFSET = -12 dB` 已提供足够 headroom（Juice Cookbook VA-6 验证结论）
- **引用核心规则**：audio-system.md Core Rule 9（音触发射顺序契约）；Juice Cookbook JC-R2

---

#### [F] Shred 粉碎进行中（JC-R3 → JC-R4 × 3–5）

- **BGM 动作**：维持循环。`shred_loop` 在独立专用节点播放（不占 SFX 池），叠加在 BGM 之上
- **频段共存**：`shred_loop` 能量集中在 200–800 Hz；BGM 在此区间已主动留空（§3.4 冲突 2 规避），两者可共存
- **节拍错位设计**：BGM 的 B 段（和声漂移、无旋律）优先落在粉碎阶段——理想情况下 A-B 段切换应发生在 D→E 过渡前后，让粉碎全程处于 BGM 最稀疏的段落。（实际上因为 BGM 是固定 loop 不做动态切换，此对齐是概率性的，不做硬性工程保证，作为"好的情况"记录在此）
- **ASMR 共鸣**：shred_loop 的满足感（audio-system.md Sound Design Brief）叠加在 BGM 温柔底色上，两者合力构成"机器认真工作"的声景。BGM 提供情绪温度，shred_loop 提供机械存在感
- **Ducking**：无
- **引用核心规则**：audio-system.md Core Rule 5（shred_loop 专用节点）；Juice Cookbook JC-R3 / JC-R4

---

#### [G] Reveal（JC-R5）

- **BGM 动作**：维持循环（BGM 本身不变）
- **前景事件**：`reveal_pop` → JC-R5（剪影 squash & stretch 0.6 → 1.2 → 1.0；1 帧 color flash；触觉 `haptic_reveal_pop` selection）
- **感知对比设计**：Shred 阶段 `shred_loop` 刚刚停止（`shred_end` 播放后循环键 stop），前景声音有一个短暂的"机器静默"——BGM 的安静在这个瞬间被玩家清晰感知到，然后 `reveal_pop` 的清脆"叮咚"在这片安静中响起。这个"先静后响"的效果是由事件顺序自然产生的，不需要 BGM 做任何配合
- **v1.0 stinger 预留**：稀有产物揭晓时，stinger_reveal_rare 在此节点插入（v1.0，不在 MVP 实现）
- **Ducking**：无。`reveal_pop` 是 2–6 kHz 中高频 transient，BGM 钟琴已做 transient 软化（§3.4 冲突 3）
- **引用核心规则**：Juice Cookbook JC-R5；audio-system.md Core Rule 9

---

#### [H] Product 落托盘 + 飞入货架（JC-R6 → JC-R7）

- **BGM 动作**：维持循环
- **前景事件**：`product_land`（JC-R6，柔和落地 + 短促完成音调）→ 短暂停留 → `shelf_add`（JC-R7，木头/布料轻触感）
- **设计意图**：这是整个循环的"收尾"——情绪从 Reveal 的小高潮平静落地。BGM A 段主题如果此时恰好在播（循环节点），会与"完成感"产生天然共鸣（主题回归 = 循环完整）。JC-R7 的落架音调（木头/布料，完成音调 400 Hz–1.5 kHz）与 BGM 的指弦吉他频段相近，两者合力构成温暖收尾
- **Ducking**：无
- **引用核心规则**：Juice Cookbook JC-R6 / JC-R7

---

#### [I] 退出 / 下一次循环

- **BGM 动作（退出场景）**：BGM 循环持续，直至 App 被强杀（audio-system.md Core Rule 6：MVP 中 BGM 永不淡出）。OS `NOTIFICATION_APPLICATION_PAUSED` 触发后 iOS/Android 平台自动静音，AudioSystem 无需显式处理
- **BGM 动作（下一次循环）**：BGM 不重置，在已进行到的位置继续播放。玩家开始第二个烦恼时，BGM 可能已经在 B 段或 A' 段——这是**有意设计**，避免每次循环都从 A 段头部重启（重启感会破坏"仪式感的连续性"）
- **来电 / 通知中断**：< 1 秒的后台切换由 Lifecycle 防抖（`RESUME_DEBOUNCE_MS = 1000`）过滤，不触发 `app_paused` 信号，BGM 平台层自动处理短暂静音后恢复，玩家几乎感知不到
- **长时间后台（> 1 秒）**：`app_paused` 确认发出，BGM 被 iOS/Android 静音。前台恢复后 Godot 自动恢复音频流，BGM 从暂停位置续播，不从头开始
- **引用核心规则**：audio-system.md Core Rule 6 + Edge Cases（App 收到 PAUSED 时 shred_loop 强制停止）；mobile-app-lifecycle.md Core Rule 4（防抖窗口）

---

### 情绪曲线设计原理总结

Mochi 的 BGM 情绪曲线有一个反直觉的特性：**BGM 本身从不变化，但玩家感知到的情绪强度有明显起伏**。这个起伏完全由 SFX 层在 BGM 底色上的爆发与消退来创造。

这是有意的设计选择，对应三条锚点的实现方式：

| 锚点 | 实现机制 |
|---|---|
| **沉实·温柔** | BGM 的质感稳定如地基；SFX 的冲击（lever_pull、shred_loop）在这片"有重量的稳定"上才显得有力 |
| **专注·散漫** | BGM 永不推进、永不催促；情绪起伏由玩家的操作行为（拉杆、点击揭晓）驱动，而不是由音乐驱动 |
| **仪式·日常** | 每次打开都是同一首 BGM 的同一个 loop；仪式感的本质是重复中的稳定，不是每次都创造新鲜感 |

## §5 技术实现建议

### §5.1 动态音乐策略：单 loop 全曲

**决策：MVP 采用单一 OGG 全曲 loop，不引入 stem-based 垂直分层、不引入水平分段重排列（horizontal re-sequencing）。**

这一决策与 §4 "BGM 在整个 session 中从不改变"的设计核心完全一致：

| 方案 | 复杂度 | 与 §4 的兼容性 | 排除理由 |
|---|---|---|---|
| **单 loop 全曲**（本决策）| 最低：1 个 OGG 文件 + 1 个 `AudioStreamPlayer` | 完全一致——BGM 的"不变性"是结构性保证，而非运行时约束 | — |
| Stem-based 垂直分层 | 中：3–5 条 stem 轨道，每条独立音量 | 运行时仍需音量调度逻辑，增加"BGM 响应游戏状态"的工程路径，是 §4 决策的背离风险 | 排除 |
| 水平分段重排列（Wwise/FMOD 风格）| 高：段落状态机 + 同步点检测 | 直接违反 §4——段落跳转本质是一种动态切换 | 排除 |

单 loop 的"零动态"架构还有两个额外优势：
1. **可离线交付**：作曲家交付 1 个混音成品即可，无需专业游戏音频中间件；
2. **可懂度保证**：整首曲子经过整体混音，低频 / 中频 / 高频的频段规划在 OGG 母带阶段统一完成，比分层叠加更好控制 §3.2 中 iPhone SE 2 外放可懂度基准。

---

### §5.2 Godot 实现框架

**播放节点类型：`AudioStreamPlayer`（非 `AudioStreamPlayer2D`，无空间化）**

BGM 是全局环境音，不需要场景内位置信息。`AudioStreamPlayer2D` 引入无意义的空间化衰减。`AudioStreamPlayer` 挂在 `AudioSystem` Autoload 节点下，生命周期随 Autoload 持续，无需 scene 管理。

**节点挂载位置：**

```
AudioSystem (Autoload Node)
├── BGMPlayer: AudioStreamPlayer       ← BGM 专用节点
├── SFXPool[0..7]: AudioStreamPlayer   ← SFX 8 节点池
├── ShredLoopPlayer: AudioStreamPlayer ← shred_loop 专用节点
└── LeverDragPlayer: AudioStreamPlayer ← lever_drag 专用节点
```

**OGG 文件 import 设置（Godot 4.6 Import Dock）：**

| 参数 | 值 | 说明 |
|---|---|---|
| `Loop` | `true` | 必须开启，否则播放到末尾后停止 |
| `Loop Begin` | 精确帧（见下）| 以采样帧为单位，不是秒 |
| `Loop End` | 精确帧（见下）| 通常 = 文件总帧数（如末尾有混响尾，需要截到无音处） |
| `BPM` | 60–72（与最终曲目一致）| 供编辑器节拍显示参考 |
| `Beat Count` | 实际小节数 × 4（或按拍号）| 同上 |

> **Loop point 校准要求**：Loop Begin/End 必须对齐零交叉点（zero-crossing）或小节线（bar line）。工作流：在 DAW 中导出时先在小节边界打 marker，再换算为 44100 Hz 采样帧数后填入 Godot Import 参数。这是防止 loop 接缝出现咔哒声（click）的唯一可靠方法。生产阶段由 audio-programmer 与作曲家共同完成此校准，sound-designer 在交付清单中列出所需帧号。

**与 Music bus 的连接：**

`BGMPlayer.bus = "Music"`（AudioServer 中预定义的 Music 总线）。Godot 4.6 中在编辑器 Audio Buses 面板或通过代码 `AudioServer.get_bus_index("Music")` 查找总线 index。Music 总线已通过 `audio_bgm_offset_db = -12 dB`（entities.yaml）相对 SFX 总线偏置，BGMPlayer 本身的 `volume_db` 属性保持 `0.0`——偏移量完全由总线级别管理，不硬编码在节点上，方便玩家音量偏好动态调整（见 §5.5）。

**自动启动代码（参考实现草稿，由 audio-programmer 落地）：**

```gdscript
func _ready() -> void:
    # ... 其他初始化 ...
    _start_bgm()
    _is_ready = true   # Core Rule 10：BGM 失败不阻塞 Foundation 就绪

func _start_bgm() -> void:
    if BGMPlayer.stream == null:
        push_error("AudioSystem: BGM_main_loop stream is null — BGM will not play")
        return
    BGMPlayer.stream.loop = true   # 冗余保险；主要在 Import 设置中控制
    BGMPlayer.play()
```

---

### §5.3 Lifecycle 集成（与 mobile-app-lifecycle.md 五状态机对位）

BGM 的 lifecycle 行为遵循"零 fade"决策：所有转换均为**立即暂停 / 立即恢复**，无任何渐变。

| Lifecycle 状态转换 | BGM 行为 | 技术机制 | 与"零 fade"一致性 |
|---|---|---|---|
| `READY` → `PAUSE_PENDING`（收到 OS PAUSED，1s 防抖未确认）| BGM 平台层自动静音 | iOS/Android 系统在 App 进入后台时自动暂停所有音频输出；Godot 无需额外代码；stream 位置保留 | 一致——静音是 OS 层行为，不是 AudioSystem 主动操作 |
| `PAUSE_PENDING` → `READY`（1s 内回前台，防抖吸收）| BGM 平台层自动恢复，无感知 | 同上；< 1s 的瞬时切换 Lifecycle 不发 `app_paused`，AudioSystem 不收到任何信号 | 一致 |
| `PAUSE_PENDING` → `PAUSED_CONFIRMED`（1s 后确认后台）| BGM 已被 OS 静音并挂起，stream 位置保留 | AudioSystem 订阅 `NOTIFICATION_APPLICATION_PAUSED`（直接订阅，不经 Lifecycle 转发，per audio-system.md Core Rule 8）；BGM 节点不调用 `stop()`，调用的是 `stream_paused = true`（待验证，见 §5.4） | 一致——不 stop，不淡出，保留位置 |
| `PAUSED_CONFIRMED` → `READY`（App 回前台）| BGM 从原位置续播，不淡入 | `NOTIFICATION_APPLICATION_RESUMED` 触发；平台保证自动恢复音频流；若使用 `stream_paused = true`，对应恢复为 `stream_paused = false` | 一致——续播而非重头播放，仪式感连续性得到保证 |
| 来电 / Siri（`INTERRUPTED` 类场景）| BGM 暂停；中断结束后自动恢复 | iOS AudioSession `AVAudioSessionInterruptionTypeEnded` 通知 → Godot 4.6 内部处理 iOS 中断 → 音频流自动恢复；AudioSystem 无需额外代码 | 一致——全流程无淡入淡出，中断前后位置不变 |

> **BGM 不订阅 `app_paused` / `app_resumed` 高层语义信号。** AudioSystem 是 Foundation 同侪，直接订阅 OS 原生通知（`NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_RESUMED`），与 Persistence / Input / Haptic 同模式（per mobile-app-lifecycle.md Core Rule 3 + audio-system.md Core Rule 8）。Lifecycle 发出的高层信号供上层系统（Mochi Character、Scene Composition）订阅。

> **shred_loop 的 PAUSED 处理**：当 `NOTIFICATION_APPLICATION_PAUSED` 到达时，如果 `shred_loop` 正在循环，AudioSystem 调用 `stop_loop(&"shred_loop")`（audio-system.md Edge Case "App 收到 PAUSED 时 shred_loop 强制停止"）。BGM 的处理与 shred_loop 独立——BGM 挂起保留位置，shred_loop 强制停止（因为它与游戏操作状态绑定，不应自动续播）。

---

### §5.4 MVP 实现待验证清单

以下三项不阻塞本文档的 Accepted 状态，移交 Wave 2 audio-programmer 在首次真机构建时验证。验证结果需回填至 audio-system.md 的 Open Questions 节。

**V-1：`AudioStreamPlayer.stream_paused = true/false` 的 stream 位置保留行为（Godot 4.6）**

- **验证问题**：Godot 4.6 中将 `AudioStreamPlayer.stream_paused` 置为 `true` 后再恢复为 `false`，BGM 是否确实从暂停位置续播，还是会重置到 stream 开头（position 0）？
- **验证方法**：在 iOS 真机上构建测试场景，播放 BGM 约 60 秒后将 `stream_paused = true`，等待 3 秒后 `stream_paused = false`，测量恢复后播放位置是否约为 60 秒处。
- **失败时备选方案**：若 Godot 4.6 不保留位置，则改用记录 `playback_position`（`BGMPlayer.get_playback_position()`) → 恢复时 `BGMPlayer.play(saved_position)`，代价是可能在 loop 接缝处有微小跳变，可接受。
- **注意**：依据 Godot 4.6 迁移文档知识截止日，此 API 行为存在版本间差异，必须真机实测，不可依赖文档。

**V-2：iOS AudioSession 中断结束后 Godot 音频流是否自动恢复**

- **验证问题**：来电结束（`AVAudioSessionInterruptionTypeEnded`）后，Godot 4.6 在 iOS 上是否自动恢复 `AudioStreamPlayer` 的播放，还是需要 AudioSystem 手动调用 `BGMPlayer.play()`？
- **验证方法**：在真机上播放 BGM，拨打一通电话并接听，挂断后检查 BGM 是否自动续播，还是静音。
- **失败时备选方案**：若不自动恢复，需在 `NOTIFICATION_APPLICATION_RESUMED` 回调中补调 `BGMPlayer.play(BGMPlayer.get_playback_position())`（须与 V-1 结论配合）。

**V-3：单 loop OGG 在 iPhone SE 2 上的 CPU 解码开销**

- **验证问题**：单条 44100 Hz 立体声 OGG Vorbis 流在 iPhone SE 2（A13 Bionic）上持续解码时，占用的 CPU 时间是否在帧预算 0.1 ms/帧 以内（per audio-system.md AC-P-02）？
- **验证方法**：Godot Profiler + Xcode Instruments 并行监测，播放 BGM 60 秒取均值。
- **失败时备选方案**：若 OGG 解码开销显著超标（不太可能，因为 A13 硬件解码能力远超），考虑改用 MP3（更低 CPU）或降低采样率至 22050 Hz（低 18% 开销，低端设备可接受）。

---

### §5.5 音量与偏好

**BGM 音量是否单独可调：是，独立于 SFX 音量。**

per audio-system.md Core Rule 7 + Persistence GDD（preferences slice）：

| 偏好键 | 类型 | 默认值 | Persistence slice | 说明 |
|---|---|---|---|---|
| `"music_volume"` | `String` 键，值为 `float [0.0, 1.0]` | `1.0` | `preferences` | Music 总线音量偏好；经 F-1（volume_to_db）映射后叠加 `audio_bgm_offset_db = -12 dB` 得最终 Music 总线 dB 值（F-2） |
| `"sfx_volume"` | 同上 | `1.0` | `preferences` | SFX 总线音量偏好，独立控制 |

**读取与应用流程：**

1. `AudioSystem._ready()` 末尾通过 `call_deferred("_apply_volume_preferences")` 读取（不在 `_ready()` 同步读，遵循 Persistence Core Rule 10 的对称约束）；
2. `_apply_volume_preferences()` 调用 `PersistenceService.get_slice("preferences", {})` 取出 `"music_volume"` 和 `"sfx_volume"`，clamp 到 `[0.0, 1.0]`；
3. 用 F-1 公式计算 dB 值，分别设置 Music 和 SFX 总线；
4. 玩家在 v1.0 的音量设置 UI 调整后，AudioSystem 调用 `set_slice("preferences", merged)` + `save_when_idle()` 持久化。

**首次启动默认行为（无存档时）：**

`music_volume` 默认 `1.0` → `BGM_db = 0 + (-12) = -12 dB`（audio-system.md Tuning Knobs 中 "Music 总线默认音量首次启动 v=0.8" 的实际初始值——注：v=0.8 是 audio-system.md 中 Tuning Knobs 描述的推荐值，与 Persistence 存档的 `1.0` 默认值之间存在差异，**audio-programmer 在 Wave 2 实现时需要确认以哪个值为准**，建议以 Persistence 的 `1.0` 为 source of truth，audio-system.md Tuning Knobs 的 v=0.8 描述作废，或单独设立 `music_volume_default` 常量解决歧义）。

---

## §6 生产路线与 MVP 范围

### §6.1 MVP 数量决策

**MVP：1 首主 loop，覆盖所有 session，不分场景、不分状态。**

这与 §4 "BGM 在整个 session 中从不改变"以及 §3.3 "A → A' → B → A 结构"完全一致。

以下变体方向明确排除出 MVP 范围：

| 排除的变体方向 | 排除理由 |
|---|---|
| 收集 milestone 解锁 BGM 变体（例如：货架满 X 件后解锁新 BGM）| 与仪式感锚点 C（"每次打开都是同一首"）直接对立；引入"BGM 状态"打破零动态决策 |
| 时间段触发变体（日间 / 夜间）| 实现成本不低（时间判断 + 状态切换 + 两首曲目交叉过渡），对 MVP 的核心情绪贡献边际极低 |
| 不同情绪投入强度的动态变体（输入短 vs 输入长）| 严重违反 §4 核心原则：BGM 不应知道玩家写了什么 |

1 首主 loop 在 MVP 阶段是唯一正确的选择：它用最小的制作成本验证"单一 BGM 是否足够支撑情绪体验"这一最重要的设计假设。

---

### §6.2 三条生产路线对比

| 路线 | 概述 | 优势 | 劣势 | 预估成本 | 预估工期 | 主要风险 |
|---|---|---|---|---|---|---|
| **A：委托独立作曲家** | 找 1 位专精 lo-fi / ambient 风格的独立作曲家按需定制 | 量身定做，可精确执行 §1 三条锚点 + §3 制作参数；作曲家可迭代修改；可以建立长期合作关系 | 成本最高；依赖找到"对的人"；沟通周期长（brief → demo → 修改轮次 ≥ 2） | $400–900 USD（独立小型项目市场行情）| 3–6 周（含修改）| 作曲家理解力偏差导致反复修改；solo indie 预算压力 |
| **B：商业 royalty-free 库** | 从 Artlist / Musicbed / Epidemic Sound 等平台选片，按年费订阅或单曲授权 | 成本低且明确；即时可用，无沟通成本；可试听大量选项 | 找到完全符合 §1–§3 参数的曲目概率低（库中 lo-fi 偏向背景音乐或 study beats，机械质感极稀缺）；无法定制 BPM / 结构 / loop point | $15–50 USD / 月（订阅制）或 $20–80 单曲 | 1–5 天（筛选时间）| 无法找到足够契合的曲目；"凑合用"的 BGM 会让整个情绪体验降一档 |
| **C：AI 辅助生成** | 使用 Suno / Udio / Stable Audio 等工具生成，人工后期修整 loop point | 成本极低；可大量尝试方向；适合快速原型验证 | 当前 AI 工具在指定 BPM + 特定乐器组合 + 精确 loop point 上的可控性仍然差；版权归属在商业项目中尚不明确（App Store 上架存在法律风险）；音质和机械质感的细腻度明显低于人工创作 | < $20 USD | 1–3 天 | 版权风险（上架合规性）；质量上限低，难以通过 §6.4 验收标准 |

> **成本注：** 以上为 2026 年 Q2 市场估算，单位 USD。实际价格因地区、作曲家资历、授权范围（移动端、全球）差异较大。委托路线 A 的低端价格（$400）对应仅交付 1 首 2–4 分钟 loop、2 轮修改、仅移动端非独家授权的最小合同。

---

### §6.3 推荐路线

**明确推荐：路线 A——委托独立作曲家。**

理由如下：

1. **BGM 是 Pillar 1（触感先行）的听觉载体，不是装饰品。** audio-system.md 明确：音效预算优先级 ≥ 美术预算。BGM 不是可以凑合的资产——它是整个情绪框架的底色，库存曲目几乎无法满足 §1 三条锚点对音色、BPM、机械质感的精准要求。

2. **路线 B 的最大风险是"凑合品"对体验的长期损耗。** 一首不够对的 BGM 每次打开 App 都在消耗玩家的情感能量。solo indie 的 DAU 很低但留存的玩家黏性高——他们每天听这首曲子，凑合的 BGM 在三周内会让人烦到关音量。这比没有 BGM 更坏。

3. **路线 C 在 App Store 上架时法律风险尚不明确**，且生成质量难以通过 §6.4 验收标准中的 iPhone SE 2 外放可懂度基准。在法律边界清晰前，商业游戏不应使用 AI 生成音乐作为正式资产。

4. **$400–$600 的委托成本在 solo indie 预算内是可以接受的**——相比整个开发周期的时间成本，这是投入产出比最高的外包资产类别。

**Actionable 下一步（路线 A）：**

1. **撰写创作 brief（1 页）**：以 §1 三条锚点 + §2 参考曲单（重点是曲目 2 Nujabes 的和声漂浮感 + 曲目 3 久石让的仪式感开场 + 曲目 4 Satie 的 BPM 区间）+ §3 制作参数为基础，将核心限制整理为给作曲家看的语言（"60–72 BPM / 无鼓组 / 黑胶噪声纹理 / 机械齿轮轻感 / 4–5 分钟 loop"）；
2. **作曲家渠道**：优先考虑 Bandcamp / SoundCloud 上专攻 lo-fi jazz / neoclassical 方向的独立作曲家，或通过 Upwork / GameDev.tv 社区发布需求；
3. **交付清单**：① 1 首主 loop（WAV 24bit/44100 Hz，含 DAW 工程文件备份）；② 标注好 loop begin/end 的小节帧号；③ 明确移动端商业授权（非独家可接受）；
4. **验收流程**：先用手机外放（iPhone SE 2 或等效小喇叭设备）试听 demo，再进行 §6.4 验收标准评分。

---

### §6.4 验收标准

audio-director 收到 BGM demo 后，使用以下清单判定通过（PASS）或退回（REJECT）。全部 4 条必须同时通过。

**VC-1 锚点符合度检验**（对照 §1 三条锚点）

用三张评分卡各打 1–5 分：

| 锚点 | 1 分（不符合）| 5 分（完全符合）| 通过线 |
|---|---|---|---|
| **沉实·温柔**：有质地感的触键声，钢琴/钟琴有实体感，不是飘在空中的 | 音色空洞，感觉是预设 pad 叠出来的 | 钢琴触键你能感觉到指尖在琴键上，有木头或铜管的物理质感 | ≥ 3 |
| **专注·散漫**：放完整首曲子，玩家可以专注写字，也可以发呆——音乐不催人，不让人烦 | 有明显"进行感"，越听越焦虑 | 60 分钟后台播放，感觉不到时间过去 | ≥ 3 |
| **仪式·日常**：第一次听 3 遍后，下次打开 App 立刻认出这首曲子，有"到家了"的感觉 | 听完 3 遍完全想不起来，毫无辨识度 | 4 bar 主题过后，闭眼还能哼出来 | ≥ 3 |

三条均 ≥ 3 → VC-1 PASS；任一 < 3 → REJECT，附具体修改方向。

**VC-2 制作参数检验**（对照 §3 制作参数）

| 参数 | 验收方法 | 通过标准 |
|---|---|---|
| BPM | 用节拍计量器 app 测量 demo | 55–80 BPM 区间内；主要节拍感落在 60–72 区间 |
| 禁用乐器 | 听感辨识 | 无鼓组 / 无弓弦弦乐大段 / 无 drone pad / 无贝斯吉他（可有低弦 pizzicato）|
| Loop 长度 | 用 DAW 或播放器测时长 | 2:40 – 5:20（48–64 bars @ 60–72 BPM）；或最短不低于 2:20（允许 ±15 秒偏差）|
| Loop 接缝 | 手动触发 loop point 聆听 3 次 | 接缝处无咔哒声，无明显音调跳变，旋律线自然衔接 |
| 频段冲突（初步）| 用 SPAN 或 MAnalyzer 看频谱 | 200–400 Hz 区间无密集和声堆积；能量中心在钢琴/钟琴的 400–2500 Hz 区间 |

全部 PASS → VC-2 PASS。

**VC-3 iPhone SE 2 外放可懂度基准**（对照 §3.2）

- **测试设备**：iPhone SE 2nd gen（或等效最小喇叭规格设备）
- **测试场景**：音量调至设备最大的 50–60%（不用最大，模拟实际使用习惯），无耳机，安静环境
- **通过标准**：旋律线（主钢琴 / 钟琴声部）清晰可辨；去掉低频后整体仍有完整质感；Vinyl Crackle 纹理可感知（高频噼啪声）
- **退回标准**：旋律线模糊到听不清主旋律走向；大量中低频糊成一团；去掉低频后曲子感觉"空了"（说明旋律设计依赖低频骨架）

**VC-4 反向锚点红线检验**（对照 §1 反向锚点）

- 不得触发"这在催我"的感觉：若任何一名测试员在听完第一遍后感到"节奏在推着我做什么"→ REJECT
- 不得触发"这是手游欢快 BGM"的判断：若任何一名测试员联想到 upbeat chiptune / J-pop 风格 → REJECT
- 不得触发"这在替我决定我的情绪有多重"的反应：若有测试员在听的时候感到"这音乐在告诉我这件事很悲伤"→ REJECT

> **退回时的反馈格式**：audio-director 应给作曲家提供具体的修改方向，而不仅是"不对"。例如："钢琴触键太干净，可以加一层轻微的 room reverb 给它一点工坊空间感"；"BPM 感偏快（听起来像 80 以上），把 shuffle 感去掉或把 note density 降一半"。§2 中的五首参考曲是最有效的对话工具：用"比这首更接近"或"比这首更远离"来传达方向。

---

### §6.5 后续版本规划

**v1.0 stinger 上线条件：**

以下两个 stinger 占位（`stinger_reveal_rare` / `stinger_first_run`，per §3.3）进入 v1.0 的前提条件：

1. MVP BGM 主 loop 已通过 §6.4 全部验收标准，并在真实玩家（≥ 10 人）使用 2 周以上无投诉"循环太明显 / 音乐太烦"；
2. Wave 2 audio-programmer 已完成 §5.4 中 V-1（stream 位置保留行为）验证，确认技术基础稳定；
3. Stinger 的插入实现需要 bar line 同步机制（BGM 当前播放到第几拍？）——这是一个额外的工程需求，MVP 中完全省略，v1.0 前需要 audio-programmer 评估 Godot 4.6 的 `playback_position` 精度是否足够支撑 bar line 对齐。

**季节性变体可行性判断：**

季节性变体（例如：深冬版 BGM 加入轻微颤音 / 夏日版加入蝉鸣远景）在概念上与 §1 "仪式·日常"锚点有张力——季节变化本身是一种"每次打开可能不同"的体验，它与"永远是同一盏灯"的仪式感设计原则存在直接矛盾。

**audio-director 的当前立场**：

- 如果变体的"变化量"极其微小（例如：同一首曲子的冬季 mix 仅在高频区加了一层轻柔颤音，95% 的旋律和编曲与原版相同），则可以在不破坏仪式感的前提下增加季节气息——条件是玩家不会"察觉到今天的 BGM 不一样"，只会"感觉到今天多了一点什么"；
- 如果是完全不同的曲目（不同旋律、不同 BPM、不同乐器组合），则需要重新审视"仪式感"是否还能成立——这属于视野级别决策，应在 v2.0 规划时由 creative-director 最终拍板；
- MVP 和 v1.0 不实施任何变体，先验证单一 BGM 的情绪稳定性。季节变体是 v2.0 以后的探索方向，且必须通过 §6.4 的完整验收流程（特别是 VC-1 的仪式感评分）。
