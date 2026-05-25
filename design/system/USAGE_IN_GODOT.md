# 在 Godot 4.6 里消费 Mochi 设计体系

这份文档是给 Mochi 项目（Godot 端）的桥接说明——把 `design/system/` 里的设计体系翻译成 Godot 代码端可直接消费的形式。

## 三处入口

| 来源 | 形式 | 在哪里用 |
|---|---|---|
| `design/system/project/colors_and_type.css` | CSS variable 单一信源 | **不直接被 Godot 读** —— 是设计真值，改动从这里发起 |
| `godot/scripts/autoload/design_tokens.gd` | GDScript autoload 常量 | 任何 .gd 脚本里：`DesignTokens.C_CARAMEL`、`DesignTokens.S_5`、`DesignTokens.DUR_BASE` |
| `godot/assets/theme/mochi_theme.tres` | Godot Theme 资源 | 自动挂在所有 Control 上（已在 `project.godot` 配置）；提供 Button/LineEdit/Panel/Label 默认样式 |

**约定**：硬编码颜色/字号/间距是错的。任何 .tscn 或 .gd 里用到颜色，必须读 `DesignTokens.*` 或继承 Theme。两个来源就是双源——不要再加第三处。

## 颜色 / 字号 / 间距

```gdscript
# 直接读常量
var bg: Color = DesignTokens.BG_APP
var gutter: int = DesignTokens.GUTTER
var body_size: int = DesignTokens.FS_BODY

# 应用到节点
$Title.add_theme_color_override("font_color", DesignTokens.C_INK)
$Title.add_theme_font_size_override("font_size", DesignTokens.FS_H1)
```

## 字体

- **Body / UI 中文**：默认 Theme 已挂 `SystemFont` fallback 链（PingFang SC → Hiragino Sans GB → Noto Sans SC → Microsoft YaHei）。Label/Button/LineEdit 不用再指定字体。
- **Display（英文 wordmark "mochi"、大数字、首启 hero）**：Fredoka，路径 `res://assets/fonts/Fredoka-Variable.ttf`。按需 override：

```gdscript
const FREDOKA: FontFile = preload("res://assets/fonts/Fredoka-Variable.ttf")

func _ready() -> void:
    $Wordmark.add_theme_font_override("font", FREDOKA)
    $Wordmark.add_theme_font_size_override("font_size", DesignTokens.FS_DISPLAY_XL)
```

## 动效曲线 / 时长

Godot 4 Tween 没有原生 cubic-bezier。DesignTokens 提供等价 helper：

```gdscript
# 日常过渡（sheet open, input focus, tab swap）
var tw := create_tween()
DesignTokens.apply_everyday(tw)
tw.tween_property($Sheet, "position:y", 0.0, DesignTokens.DUR_SLOW)

# 庆祝（lever snap-back, treasure landing, silhouette morph）
var tw2 := create_tween()
DesignTokens.apply_celebrate(tw2)
tw2.tween_property($Knob, "scale", Vector2.ONE, DesignTokens.DUR_CELEBRATE)

# 弹性更夸张（reveal glow ring 抖动）
DesignTokens.apply_elastic(create_tween()).tween_property(...)
```

## 双层 plush shadow

CSS 的 `--shadow-2`（`contact 0 2px 0 + ambient 0 6px 14px`）Godot StyleBoxFlat 不支持原生双层。在 .tscn 里实现方式：

1. **简单场景**：用 Theme 默认 Panel 的 ambient 层（已挂 shadow-2 的 ambient 部分）。略糙但能用。
2. **要双层**：嵌套两个 PanelContainer——外层挂 ambient (`SHADOW_2_OFFSET/BLUR/ALPHA`)，内层挂 contact (`Vector2(0,2)`, blur=0, alpha=0.06)。内层 bg 才是实际可见的卡片。

## Press / Disabled 状态规范

`DesignTokens.PRESS_SCALE = 0.985`、`DesignTokens.DISABLED_ALPHA = 0.40`。任何自定义按钮组件按这个对齐：

```gdscript
func _on_button_down() -> void:
    var tw := create_tween()
    DesignTokens.apply_everyday(tw)
    tw.tween_property(self, "scale", Vector2.ONE * DesignTokens.PRESS_SCALE, DesignTokens.DUR_FAST)

func _on_button_up() -> void:
    var tw := create_tween()
    DesignTokens.apply_everyday(tw)
    tw.tween_property(self, "scale", Vector2.ONE, DesignTokens.DUR_FAST)
```

## 图标

Lucide 风格 SVG 已拷到 `godot/assets/icons/`：
- `chevron-left.svg` / `chevron-right.svg` — 返回 / 前进
- `close.svg` — 关闭弹窗
- `settings.svg` — 齿轮
- `shelf.svg` — **bespoke 自绘**（货架，主屏永远可见的两个交互元素之一）
- `wordmark.svg` — "mochi" 品牌字

读法：`var tex: Texture2D = preload("res://assets/icons/shelf.svg")`，挂到 TextureRect 或 BaseButton.icon。

## 规格查询路径

- 想动设计令牌？→ 改 `design/system/project/colors_and_type.css`（真值），再同步到 `design_tokens.gd` 和 `mochi_theme.tres`
- 想知道某条规则背后的意图（voice/iconography/shadow stack）→ 读 `design/system/project/README.md`
- 想看 microcopy 中文文案库 → `design/system/project/README.md` 的 **Sample copy library** 章节

> HTML 组件预览卡（preview/）和 React UI Kit（ui_kits/）已按用户要求移除。组件视觉规格仍由 `colors_and_type.css` + project/README.md 完整定义；如需可视化卡片，到 claude.ai 重跑 Claude Design 即可重生。

## Microcopy / 中文文案库

中文 UI 文案已经写好——见 `design/system/project/README.md` 的 **Sample copy library** 章节。直接照抄，不要自己另写。每条都已经过调性把关（"calm, slightly off-beat shopkeeper"）。

## Mochi 角色 / 8 个产物的位置

主角、8 个产物以及两只猫（Lucky / 蓝胖，见 `design/notes/cats_spec.md`）由 **nano-banana / gpt-image-2 后续生成**（利用多图参考输入保证风格统一），目前所有 mockup 用占位：
- Mochi：230×268 的桃粉/奶油斜纹矩形 + 虚线框，居中略上
- 8 产物：4 种几何占位形状（bloom / leaf / star / pebble），见 `kit.css` 的 `.treasure--*` 规则

实际开发时，先在 Godot 端用对应尺寸的占位 ColorRect/TextureRect 跑通逻辑；painted PNG 落地后 1:1 替换贴图，布局不动。

## 修改流程

发现设计令牌需要调整时：

1. 改 `design/system/project/colors_and_type.css`（真值）
2. 同步到 `godot/scripts/autoload/design_tokens.gd`（GDScript 常量）
3. 如果影响 Theme 默认样式，同步改 `godot/assets/theme/mochi_theme.tres`
4. 不要跳过任何一步，否则三处会漂移

如果改的是组件视觉（按钮形状、卡片阴影等），先改对应的 `.jsx`/`.html` preview，让设计稿和代码同步。
