# Cats Spec — Lucky & 蓝胖

*Created: 2026-05-25*
*Status: v0 — first spec, 待 nano-banana 出图后迭代*

---

## 这份文件是什么

Mochi 游戏中两只猫的视觉规范——交给 **nano-banana / gpt-image-2** 出图的 brief。
不规定她俩在游戏机制里出现的时机（那是后续 BUILD_PLAN / gameplay 决策），**只规定她俩的视觉形态**。

**关系定位**：Mochi 主角的两个小伙伴。**Mochi 仍是绝对主角**，两只猫的视觉重量不超过 Mochi 的 60%。她俩在场时是配角，不抢戏。

## 风格继承

完全继承 `design/system/` 的 Cozy Mechanical / Donut County 风格：
- painted plush，hand-painted shading
- 厚而柔的 ink outline（1.5-2pt）
- 双层 plush shadow（contact + ambient）
- 圆润形状，无锐角
- 与 Mochi 同光源、同笔触、同色温

**核心生图原则**：先有 Mochi reference，再以 Mochi reference 作为视觉锚生成两只猫。两只猫**不能独立设计**，必须从 Mochi 的视觉语言里长出来。

---

## Lucky（美短橘）

**真实原型**：用户家的美国短毛猫，橘色虎斑，性格好动活泼。

### 视觉规范

| 维度 | 描述 |
|---|---|
| 品种特征 | 美短虎斑——修长肌肉感（非英短的圆滚），鼻梁直，杏仁眼 |
| 主色 | 暖橘 + 米白虎斑纹（落在现有色板的 Peach `#E8A598` + Caramel `#D17A52` 系，天然契合）|
| 轮廓 | 圆润中带肌肉线条，体型修长 |
| 眼睛 | 圆瞳、明亮、好奇感（**与 Mochi 同样的"焦点眼"处理**——只画一只关键眼传达情绪）|
| 比例 | 头 : 身 = 1 : 1.5（成猫，不是大头娃娃）|
| 性格暗示 | 灵动、好奇、随时准备扑跃 |

### 姿态库（nano-banana 出图清单）

1. **idle-curious**：坐姿，前爪并拢，头略歪，看向 Mochi 方向
2. **idle-walking**：侧面行走，尾巴上翘
3. **playful-crouch**：弓背扑跃前的低伏姿态（"屁股翘高"）
4. **lying-soft**：侧躺，肚子贴地，放松状态
5. **looking-up**：仰头，眼睛圆睁

### 尺寸 / 占位

参考 Mochi 230×268 的 60-65%：约 **150×170 painted PNG**，透明边缘。

---

## 蓝胖（英短蓝）

**真实原型**：用户家的英国短毛猫，蓝灰色，性格慵懒但关键时刻一点不怂。

### 视觉规范

| 维度 | 描述 |
|---|---|
| 品种特征 | 英短经典圆球感——下巴鼓、脸盘圆、四肢短粗 |
| 主色 | 蓝灰 + 雾白毛端（**注意：当前 design system 5 色板里没有蓝灰，需要扩展**——见下方"色板调整 flag"）|
| 轮廓 | 圆球——几乎是个带耳朵的椭圆 |
| 眼睛 | 大且圆，琥珀/黄铜色（英短经典），半眯眼传达慵懒 |
| 比例 | 头 : 身 = 1 : 1.2（更圆滚）|
| 性格暗示 | 平时慵懒躺平，但视线锐利；坐直时变成沉甸甸的存在感 |

### 姿态库（nano-banana 出图清单）

1. **idle-loaf**：经典"面包"姿态——四脚全部收起趴卧
2. **idle-sit-half-eye**：坐姿，半眯眼
3. **alert-sit-up**：关键时刻——坐直，眼睛圆睁，剪影变方
4. **stretching-paw**：伸懒腰，前爪前伸
5. **sleeping-spread**：完全摊开睡姿

### 尺寸 / 占位

参考 Mochi 230×268 的 55-60%（视觉重量略小于 Lucky，因为体形圆球感本身已经"重"）：约 **140×130 painted PNG**，透明边缘。

---

## ⚠️ 色板调整 flag

蓝胖的蓝灰色当前**不在** design system 的 5 色 palette 里。处理方案二选一：

| 方案 | 做法 | 影响 |
|---|---|---|
| **A. 扩展色板**（推荐） | 在 `colors_and_type.css` 新增 `--c-mist: #A8B5C2` 作为"角色专属冷色锚"，仅用于蓝胖 + 可能的 v1.1 夜间模式 | 色板从 5 色变 6 色；新增一个冷色平衡现有暖色系 |
| **B. 折中调色** | 让蓝胖偏暖灰（接近 Ink `#2D3B4F` 浅化），完全留在现有色板内 | 失去蓝胖品种特征的辨识度；不像英短 |

**建议走 A**——蓝胖的蓝灰是她的灵魂特征，妥协掉就不是她了。新增一个色 token 对 design system 是非破坏性扩展。

---

## 视觉关系图

```
        Mochi (230×268, 100% 视觉重量)
        ████████████████
        ████████████████
        ████████████████
        ████████████████
        
Lucky (150×170, ~60%)   蓝胖 (140×130, ~55%)
   ██████████              ████████
   ██████████              ████████
   ██████████              ████████  
```

两只猫**不同时与 Mochi 同框**作为视觉默认（同框会喧宾夺主）。各自单独 painted PNG，使用时按场景选用。

---

## 🚀 nano-banana / gpt-image-2 生图工作流

### Step 1: 生成 Mochi 主角 reference

按 `visual_direction.md` 的 Mochi character spec，迭代生成 5-10 张，选定**一张作为永久视觉锚**。这张 Mochi 决定后续所有角色的笔触、阴影、色温、画风。

### Step 2: 生成两只猫

**关键技巧**：nano-banana / gpt-image-2 支持多图输入。每次生成时：
- 喂入 Mochi 主角 reference（锁定 painted plush 风格）
- 喂入对应猫的**真实照片**（锁定猫本人的样貌特征）
- 用自然语言描述要的姿态

### Step 3: prompt 模板（中文 / 英文都行）

```
Reference 1: [Mochi 主角 painted PNG]
Reference 2: [Lucky 真实照片]

Generate: 
A painted plush-style cat, same brush stroke and shading as Reference 1.
The cat should preserve the orange tabby markings, eye color, 
and facial features of Reference 2.
Pose: [姿态库里的一条 — e.g., "sitting curious, front paws together, head slightly tilted"]
Background: transparent / pure cream (#F5E6D3).
Style: hand-painted, soft contact + ambient shadow, 1.5pt ink outline,
warm rounded organic shapes, NOT flat vector, NOT realistic.
Output size: 150×170 with transparent edges.
```

蓝胖用同样模板，替换 Reference 2 + 描述。

### Step 4: 风格一致性验证

把 Mochi + Lucky + 蓝胖 三张图并排，肉眼检查：
- 笔触是否一致？
- 阴影深度是否一致？
- 色温是否一致？
- ink outline 粗细是否一致？

如果有任一不一致，把生成出的"对的"那张作为新 reference，重新跑"错的"那张。**不要一开始就追求完美，先跑通迭代闭环。**

---

## TODO（不在本文件解决）

- [ ] 两只猫在 BUILD_PLAN 里的具体出现时机（gameplay 决策）
- [ ] 是否替换或补充 8 个 treasure 设计中的部分（猫毛球 / 猫玩具？）
- [ ] 货架展示中两只猫是否常驻"镇店"
- [ ] App icon 是否包含猫元素
- [ ] 是否需要猫的"声音"作为音效彩蛋
