extends Node
## Mochi 设计令牌 — Godot 端单一信源
##
## 把 design/system/project/colors_and_type.css 的所有 CSS variable 翻译成 GDScript 常量。
## 任何 UI 代码读颜色/字号/间距/圆角/阴影/动效时长时，必须从这里读，不要在 .tscn 或 .gd 里硬编码。
##
## CSS 端是 single source of truth — 修改时先改 CSS（活参考），再同步过来。
## 不要把这套 token 写进 Theme 资源然后再读 Theme，那是双源。Theme 资源应该 *引用* 这里的常量。

# ---------------------------------------------------------------------------
# Colors — 暖奶油主调，5 色锁定 + 派生
# ---------------------------------------------------------------------------

const C_CREAM: Color      = Color("#F5E6D3")  # primary background — the stage
const C_CREAM_50: Color   = Color("#FBF4E8")  # lifted surface (cards on cream)
const C_CREAM_100: Color  = Color("#F0DCC2")  # pressed cream, divider tint
const C_CREAM_200: Color  = Color("#E6CFB1")  # shelf wood-tone shadow

const C_PEACH: Color      = Color("#E8A598")  # primary — Mochi body hint, key chips
const C_PEACH_50: Color   = Color("#F4D2CB")  # peach surface, soft tag bg
const C_PEACH_700: Color  = Color("#C97F70")  # peach pressed / icon

const C_CARAMEL: Color    = Color("#D17A52")  # accent — CTAs, lever, joystick ball
const C_CARAMEL_50: Color = Color("#EFC8B6")
const C_CARAMEL_700: Color = Color("#A85B36") # caramel pressed

const C_INK: Color        = Color("#2D3B4F")  # primary text & hard outlines
const C_INK_80: Color     = Color("#4A576B")  # secondary text
const C_INK_60: Color     = Color("#7B8597")  # tertiary text, placeholder
const C_INK_30: Color     = Color("#BCC2CC")  # disabled, dividers on dark

const C_MINT: Color       = Color("#9DCDB5")  # pop — reveal moment, mint highlight
const C_MINT_50: Color    = Color("#CFE6DB")
const C_MINT_700: Color   = Color("#6FA189")

const C_GOLD: Color       = Color("#E8B86E")  # rare-reveal only (v1.0+)
const C_GOLD_GLOW: Color  = Color("#F7D89A")

# Semantic surfaces
const BG_APP: Color       = C_CREAM
const BG_SURFACE: Color   = C_CREAM_50
const BG_ELEVATED: Color  = Color("#FFFDF7")  # whitest the system goes; sparingly
const BG_INPUT: Color     = Color("#FFFBF1")
const BG_PRESSED: Color   = C_CREAM_100
const BG_SHELF: Color     = Color("#ECD6B7")  # warm wood tone for the shelf board
const BG_OVERLAY: Color   = Color(0.176, 0.231, 0.310, 0.32)  # modal dim
const BG_SCRIM: Color     = Color(0.176, 0.231, 0.310, 0.08)  # faint divider scrim

# Semantic text
const FG: Color           = C_INK
const FG_MUTED: Color     = C_INK_80
const FG_SOFT: Color      = C_INK_60
const FG_ON_DARK: Color   = Color("#FBF4E8")
const FG_ON_ACCENT: Color = Color("#FFFBF1")
const FG_PLACEHOLDER: Color = C_INK_60

# Strokes & dividers — 永远暖色，不用纯灰
const STROKE_SOFT: Color   = Color(0.176, 0.231, 0.310, 0.08)
const STROKE: Color        = Color(0.176, 0.231, 0.310, 0.14)
const STROKE_STRONG: Color = Color(0.176, 0.231, 0.310, 0.22)
const STROKE_INK: Color    = C_INK

# ---------------------------------------------------------------------------
# Typography — 字号校准在 iPhone 390×844 画布上
# ---------------------------------------------------------------------------

const FS_DISPLAY_XL: int = 44  # onboarding hero, first-run wordmark
const FS_DISPLAY_LG: int = 32
const FS_DISPLAY_MD: int = 24
const FS_H1: int         = 22  # sheet titles, modal titles
const FS_H2: int         = 18  # shelf section header
const FS_BODY: int       = 16  # default UI body
const FS_CALLOUT: int    = 15  # secondary, microcopy intro
const FS_FOOTNOTE: int   = 13  # timestamps, hint copy
const FS_CAPTION: int    = 11  # meta, very small labels

const LH_TIGHT: float = 1.15
const LH_SNUG: float  = 1.30
const LH_BODY: float  = 1.55
const LH_LOOSE: float = 1.70

const FW_REGULAR: int  = 400
const FW_MEDIUM: int   = 500
const FW_SEMIBOLD: int = 600
const FW_BOLD: int     = 700

const FONT_DISPLAY_PATH: String = "res://assets/fonts/Fredoka-Variable.ttf"
## Chinese body copy 走 iOS 系统字体（PingFang SC），Godot 端
## 用 SystemFont fallback 链。系统字体不能写成常量路径，由 Theme 资源
## 或运行时 SystemFont.font_names 处理。

# ---------------------------------------------------------------------------
# Spacing — 4pt rhythm
# ---------------------------------------------------------------------------

const S_0: int  = 0
const S_1: int  = 4
const S_2: int  = 8
const S_3: int  = 12
const S_4: int  = 16   # default gutter for stacks
const S_5: int  = 20   # horizontal app gutter
const S_6: int  = 24
const S_7: int  = 32
const S_8: int  = 40
const S_9: int  = 48
const S_10: int = 64

const GUTTER: int = S_5

# ---------------------------------------------------------------------------
# Radii — clay/plush, 永远不锐
# ---------------------------------------------------------------------------

const R_XS: int  = 6    # tiny pills, tag chips
const R_SM: int  = 10   # small buttons, icons
const R_MD: int  = 14   # inputs, secondary cards
const R_LG: int  = 20   # cards, sheets
const R_XL: int  = 28   # hero surfaces, onboarding
const R_2XL: int = 36   # full-bleed sheets
const R_PILL: int = 999

# ---------------------------------------------------------------------------
# Shadows — plush 两层叠加
# ---------------------------------------------------------------------------
## Godot StyleBoxFlat 只支持单层 shadow_color/shadow_size/shadow_offset，
## 二层叠加在 UI 端需用嵌套 PanelContainer（contact + ambient 各一层）。
## 这里只暴露分层参数；Theme 资源里用 shadow-1/2/3/4 作为 ambient 层默认值。

const SHADOW_INK: Color = C_INK  # 所有 shadow 都用 ink hue 染色

const SHADOW_1_OFFSET: Vector2 = Vector2(0, 2)
const SHADOW_1_BLUR: int       = 6
const SHADOW_1_ALPHA: float    = 0.10

const SHADOW_2_OFFSET: Vector2 = Vector2(0, 6)
const SHADOW_2_BLUR: int       = 14
const SHADOW_2_ALPHA: float    = 0.14

const SHADOW_3_OFFSET: Vector2 = Vector2(0, 14)
const SHADOW_3_BLUR: int       = 28
const SHADOW_3_ALPHA: float    = 0.20

const SHADOW_4_OFFSET: Vector2 = Vector2(0, 24)
const SHADOW_4_BLUR: int       = 48
const SHADOW_4_ALPHA: float    = 0.28

# Inner shadow for 输入框这种 “pocket” 表面 — Godot StyleBoxFlat 没有原生 inset，
# 用 1px ink stroke + 1.5 度边框做近似（在 Theme 里实现）。

# Glow — 揭晓时刻唯一发光
const GLOW_MINT: Color = Color(0.616, 0.804, 0.710, 0.45)
const GLOW_GOLD: Color = Color(0.969, 0.847, 0.604, 0.55)

# ---------------------------------------------------------------------------
# Motion — easeOutQuart 日常 / easeOutBack & Elastic 庆祝
# ---------------------------------------------------------------------------
## Godot 4 Tween 没有原生 cubic-bezier，用 TRANS_*/EASE_* 近似：
##   easeOutQuart  ≈ Tween.TRANS_QUART  + Tween.EASE_OUT
##   easeOutBack   ≈ Tween.TRANS_BACK   + Tween.EASE_OUT
##   easeOutElastic≈ Tween.TRANS_ELASTIC+ Tween.EASE_OUT
## 调用约定写在下方 helper。

const DUR_FAST: float       = 0.14  # press, hover
const DUR_BASE: float       = 0.24  # normal UI
const DUR_SLOW: float       = 0.48  # sheet slide, card lift
const DUR_CELEBRATE: float  = 0.78  # reveal fill + bounce

## 在 tween 上挂"日常"过渡曲线（sheets opening, tab swaps, input focus）。
## 用法：`DesignTokens.apply_everyday(tw)`
static func apply_everyday(tw: Tween) -> Tween:
	return tw.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

## 在 tween 上挂"庆祝"过渡曲线（silhouette reveal, lever snap-back, treasure landing）。
## 用法：`DesignTokens.apply_celebrate(tw)`
static func apply_celebrate(tw: Tween) -> Tween:
	return tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## 弹簧效果更夸张的版本（弹性 elastic），用在揭晓发光环、剪影 morph 等。
static func apply_elastic(tw: Tween) -> Tween:
	return tw.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------------------
# Layout — iPhone 390×844 portrait 单视口
# ---------------------------------------------------------------------------

const DEVICE_W: int    = 390
const DEVICE_H: int    = 844
const SAFE_TOP: int    = 47   # notch area
const SAFE_BOTTOM: int = 34   # home indicator
const CONTENT_W: int   = DEVICE_W - GUTTER * 2  # 350px

# Z layers（在 .tscn 里用 z_index 或场景树顺序对齐）
const Z_BASE: int  = 1
const Z_SHELF: int = 5
const Z_INPUT: int = 10
const Z_LEVER: int = 20
const Z_SHEET: int = 100
const Z_MODAL: int = 110
const Z_TOAST: int = 120

# ---------------------------------------------------------------------------
# Press / Disabled 视觉规范
# ---------------------------------------------------------------------------
## 任何可交互组件的 press 状态：缩到 ~98%、shadow 沉到 pressed、不变颜色。
## Disabled：fill 40% 透明、无 shadow。

const PRESS_SCALE: float       = 0.985
const DISABLED_ALPHA: float    = 0.40
