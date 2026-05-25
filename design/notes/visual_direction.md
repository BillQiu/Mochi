# Visual Direction — Mochi

*Created: 2026-05-24*
*Status: Draft — waiting on first Claude Design pass*

---

## 这份文件是什么

记录 Mochi 视觉方向的决策 + Claude Design 种子 prompt。
工作流：本文件 → Claude Design 跑出 UI mockup + 风格指南（已完成，见 `design/system/`）→ 风格指南作为 reference 喂 **nano-banana / gpt-image-2** 出 Mochi 主角、8 个产物、两只猫 → 资产塞回 Godot。

**两只猫 Lucky 和蓝胖的视觉规范**见 `design/notes/cats_spec.md`，与本文件平级。

**生图模型选型**：用 nano-banana / gpt-image-2 而非 Midjourney——前者支持原生多图参考输入，11 个角色风格统一是默认行为而不是赌博。

## 风格调性（已决策）

- **对标**：《Donut County》——暖色 + 厚阴影 + 圆润形状 + 拟人有性格角色 + 半立体卡通渲染
- **不要的**：等距视角（Mochi 是正视角竖屏）、写实、扁平 flat vector、赛博、暗黑
- **关键词**：warm, cozy, tactile, plush, slightly tactile-3D, hand-painted shading, soft contrast
- **氛围目标**：晚上 10 点躺床上打开，感觉"屏幕里有一个靠谱小角色在等我"

## 调色板（v0，待 Claude Design 精修）

| 用途 | 色 | 备注 |
|---|---|---|
| 主背景 | 暖米杏 #F5E6D3 | 天空色，不刺眼 |
| 主色 | 桃粉 #E8A598 | Mochi 身体可能用到 |
| 强调色 | 焦糖橙 #D17A52 | CTA / 摇杆球握把 |
| 深色 | 深棕蓝 #2D3B4F | 文字 / 货架阴影 |
| 跳色 | 薄荷绿 #9DCDB5 | 揭晓时的小惊喜 |

## Mochi 角色边界（重要）

Claude Design **不生成 Mochi 角色本身**——只在 UI mockup 里**留出 Mochi 的位置**（中央偏下，占屏幕高度 35%），并提供"角色应该长什么风格"的具体规范（轮廓圆润度、阴影深度、瞳孔大小比例、性格暗示词）作为后续 **nano-banana / gpt-image-2** 的输入。两只猫 Lucky / 蓝胖同此处理（见 `cats_spec.md`）。

## 需要 Claude Design 输出

1. **主界面 mockup**（输入区 + Mochi 居中占位 + 摇杆 + 货架入口图标）
2. **货架页面 mockup**（时间倒序网格 + 单项详情弹窗）
3. **隐私说明弹窗 / 首次启动引导**
4. **风格指南**（调色板精修 + 字体 + 间距 + 阴影规则 + 圆角规则 + 动效曲线推荐）
5. **App icon 探索 3-5 版**（关键：在 iOS 桌面 60x60 缩略图下还能辨识）

---

## 🚀 Claude Design 种子 Prompt（已跑过——保留为历史记录）

> **注意**：下方 prompt 中出现的 "Midjourney" 是当时的假设。**实际生图改用 nano-banana / gpt-image-2**——如需重跑或派生新 prompt，请等价替换"Midjourney" → "nano-banana / gpt-image-2"。
>
> Claude Design 的输出已落地为 `design/system/` 完整设计体系（5 屏 UI kit + colors_and_type.css + 25 个 preview 卡），无需重跑此 prompt 除非要做 v2 视觉迭代。

将下面整段贴进 claude.ai 的 Claude Design 工具（仅供 v2 迭代参考）：

```
I'm building "Mochi", a solo-indie iOS game that helps people decompress
by feeding written worries into a cute cartoon shredder machine. Core loop
is 22-30s: type worry → pull lever → Mochi crushes it → silhouette reveals
a small treasure (flower, butterfly, star) → shelf collection.

Help me design the full visual system. I need UI mockups + a style guide,
NOT character art (the Mochi machine character itself will be generated
later in Midjourney — your job is to design everything *around* the
character and define the visual language it must fit into).

## Style direction
- Reference game: *Donut County* — warm palette, thick soft shadows, rounded
  organic shapes, hand-painted shading, charming character-driven feel.
- NOT isometric (Mochi is vertical portrait-view), NOT realistic, NOT flat
  vector, NOT cyberpunk, NOT dark.
- Mood: cozy bedtime app, tactile, plush, slightly 3D-ish but stylized 2D.
- Target user: 18-35, stressed knowledge workers, opens this at 10pm in bed.

## Palette starting point (refine if you have better ideas)
- Background: warm cream #F5E6D3
- Primary: peach pink #E8A598
- Accent: caramel orange #D17A52
- Dark: deep brown-blue #2D3B4F
- Pop: mint #9DCDB5

## Deliverables (please produce all of these)

1. **Main screen mockup** (iOS 390x844 portrait)
   - Top: text input area for typing the worry (multi-line, soft rounded card)
   - Center: a placeholder rectangle labeled "Mochi character (Midjourney
     will fill)" — occupies ~35% screen height, centered horizontally
   - Below Mochi: lever / joystick that user pulls down to trigger crush
   - Top-right or top-left corner: small shelf icon (taps to shelf screen)
   - Settings gear in opposite corner

2. **Shelf screen mockup** (iOS 390x844 portrait)
   - Grid of collected treasures, newest first
   - Each cell shows: silhouette (locked) or small illustration (collected)
   - Tap → modal detail view showing: which day, original worry text
     (optional reveal), the treasure illustration
   - Empty state (no treasures yet) — friendly, encouraging

3. **Privacy / first-run onboarding sheet**
   - Bottom sheet style, friendly Chinese copy (this app's UI is Chinese)
   - Key points: all data local, no cloud, no account, no ads
   - Single CTA button to start

4. **Style guide** (1 page)
   - Final refined palette with hex + role
   - Typography (system font for Chinese; suggested English pairing)
   - Spacing scale (4/8/12/16/24/32/48)
   - Shadow rules (soft, 2-layer: tight contact shadow + diffuse ambient)
   - Corner radius rules (small UI 8px, cards 16px, large surfaces 24px)
   - Recommended motion easing (something playful, e.g., easeOutBack /
     easeOutElastic for celebration moments)
   - **Character spec for the Mochi machine** (handoff doc for Midjourney):
     - Silhouette weight: roundness 80%, machinery elements 20%
     - Personality cue keywords (warm, earnest, slightly mischievous)
     - Recommended scale ratio relative to screen
     - Required states/poses (idle, receiving, shaking, crushing, revealing)

5. **App icon exploration** (3-5 variants)
   - 1024x1024, but design must still read at 60x60
   - Variants exploring: pure Mochi face vs. abstract symbol vs. lever icon

## Important constraints

- All UI text in Chinese (Simplified). I'll write the actual copy — for
  mockups use placeholder Chinese like "把今天的烦恼写下来…"
- Mobile portrait only. Not designing tablet or landscape.
- Must work in light mode only for MVP. Dark mode is v1.1.
- Don't add features beyond what's listed (no social, no sharing, no badges,
  no streaks). The product philosophy is intentional minimalism.
- The shelf icon and lever shape are CRITICAL — they're the only
  always-visible interactive elements besides Mochi itself. Spend
  proportionally more design care on them.

## Output format
Generate an interactive prototype I can click through (main → shelf → detail
modal → privacy sheet). Export the style guide as a separate page.
```

---

## 你跑完之后回来给我什么

只要回来一件东西：**风格指南页（含调色板精修 + 角色规范段落）**。
有了它我就能：
1. 把调色板写进 Godot 主题资源 ✅ 已完成（见 `godot/scripts/autoload/design_tokens.gd`）
2. 用"角色规范段落"作为 **nano-banana / gpt-image-2** prompt 的基底，跑 Mochi 主视觉 + Lucky + 蓝胖 + 8 产物
3. 同时开始写 W1 代码（视觉用临时占位，但布局比例与你的 UI mockup 对齐）

UI mockup 截图 + interactive prototype URL 也可以一起带回来，我看过整体后再调整 Godot 场景的节点结构。

**生图工作流细节**见 `design/notes/cats_spec.md` 的"nano-banana / gpt-image-2 生图工作流"章节——同样的多图参考方法适用于 Mochi 主角和 8 产物。
