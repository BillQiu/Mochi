# Haptic System

> **Status**: Revised (pending re-review) — addresses 2026-05-21 review's 13 BLOCKING items
> **Author**: game-designer (main) + godot-specialist consulted in spirit
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Pillar 1（Tactile First）— 与 Audio System 并列承载
> **Review mode**: Lean — `creative-director` / `systems-designer` / `qa-lead` 未在 authoring 期直接调用；移交 `/design-review` 阶段独立评审
> **Revision history**: 2026-05-22 — 13 BLOCKING revision per `design/gdd/reviews/haptic-system-review-log.md` (Groups 1–5: sfx_ prefix fixes, Formulas rewrite, API/State machine restructure, AC rewrite + rubric, Audio paired edit + Open Q upgrade)

## Summary

Haptic System 是 Mochi 触感层的输出引擎——一个 Godot Autoload 单例，向下游游戏系统暴露统一的语义触觉事件 API（`Haptic.play("lever_pull")`），通过 iOS UIImpactFeedbackGenerator 预设播放冲击与选择反馈。Foundation 层，零上游依赖；下游 4 个核心系统通过信号或直接方法调用触发它。MVP 触觉调色板 = 5 个 UIImpactFeedbackGenerator 预设（`selection / light / medium / heavy / rigid`），**不**支持自定义波形——CoreHaptics 波形调制是 P0 Open Question，移交 prototype 阶段验证。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (zero upstream)` · Pillar: `Tactile First (与 Audio System 并列承载)`

## Overview

Haptic System 是 Mochi 触感层的输出引擎——一个 Godot Autoload 单例，负责包装 iOS UIImpactFeedbackGenerator（通过 `kyoz/godot-haptics` plugin 作为 MVP 默认候选），向其他系统暴露一组类型化的语义触觉事件 API。它是 Foundation 层系统，无上游依赖；下游 4 个核心系统——Mochi Character (#6)、Lever Interaction (#8)、Shred Process (#9)、Silhouette Reveal (#11)——通过信号或直接方法调用触发它。

玩家永远不会打开一个"触觉系统菜单"——他们感受到的是：摇杆拉到底那一下"咔嚓"的硬碰撞、机器启动时手心的一震、揭晓瞬间的轻触脉冲。这些震动不是装饰，它们是 Pillar 1（触感先行）的物理凭证——概念文档明确："视觉漂亮可以让步，触感不能让步"。Audio System 提供"声音的重量"，Haptic System 提供"手感的重量"，二者缺一不可。

这个系统存在是因为 iOS Taptic Engine 给了 Mochi 一个低门槛但高密度的反馈通道：屏幕之外的肌肉记忆。下游系统**不应**直接调用 plugin——所有触觉触发必须经过 Haptic System 的语义事件目录，这样：(1) 全局静音 / 设备能力探测在一处实施；(2) 触觉键名与 Audio System 事件键对位，便于"音效 + 触觉"组合在 Juice Cookbook 中规范化；(3) 当未来 plugin 替换或升级到 CoreHaptics 自定义波形时，下游不需修改。

**平台契约（GDD 必读）**：
- **iOS-first MVP**——社区无成熟 CoreHaptics 自定义波形桥（仅有 UIImpactFeedbackGenerator 包装层）。MVP 触觉调色板被压缩到 **5 个 UIImpactFeedbackGenerator 预设**（`selection / light / medium / heavy / rigid`）。
- **Android 是免费搭车**——`kyoz/godot-haptics` plugin 双平台自动支持（一档基础 `vibrate`），但 MVP 不投入测试与调优精力。
- **"摇杆 3 秒持续触感是否需要 CoreHaptics 自定义波形"** 是 P0 Open Question——如果 prototype 测出 5 个预设无法承载摇杆爽感，需要追加 GDExtension 工作量。**这是 Wave 1 最大单点风险。**

## Player Fantasy

触觉是 Mochi 物理重量感的直接证据。玩家不会"想到触觉"——他们只会在没有触觉时感到机器是塑料假的，在触觉到位时感到"这台机器真的在工作"。

**目标情绪**：每一个手感动作都有真实的物理凭证。摇杆拉到底"咔嚓"一下顶住——不是软绵绵地停在那里。机器启动手心一震——而不是手机毫无回应。揭晓瞬间一阵轻触——像礼物盒里弹出的弹簧。这种感觉是直接的：玩家闭上眼睛也能"摸到"机器在运转。

玩家应该感受到的是：**这台机器是有重量的、有物理质感的、动作之间有清晰的力反馈分界**。触觉让 Mochi 从一组像素动画变成一个能被身体感知的物件。

**目标参考瞬间**：

| 时刻 | 玩家感受 | 触觉强度（预设） |
|---|---|---|
| 摇杆拉到底（`lever_lock`） | 硬碰撞，金属顶住 | `heavy` |
| 机器接收启动（`shred_start`） | 手心一震，确认动作 | `medium` |
| 粉碎进行中（`shred_pulse`） | 低频间歇脉冲，机器还在干活 | `light` × N |
| 揭晓瞬间（`reveal_pop`） | 清脆轻触，礼物盒打开 | `selection` |
| 产物入货架（`shelf_add`） | 柔和落地冲击 | `light` |

**不希望玩家感受到的（反面参考）**：
- ❌ 软绵无力的连续震动（典型 Android 廉价手机反例）——感觉手机在抖，而不是机器在工作
- ❌ 过度密集的冲击（< 100 ms 间隔）——产生疲劳感、降低边际效用
- ❌ 触觉与音频不同步——破坏"声触合一"的物理真实感（Pillar 1 同步要求）
- ❌ 持续震动（> 100 ms 不间断）——iOS 触觉哲学是离散冲击，不是连续震动

**Pillar 引用**：

> "粉碎机的物理反馈是这款游戏的灵魂。震动、齿轮声、机器抖动必须扎实——视觉漂亮可以让步，触感不能让步。"
> — Pillar 1（Tactile First），design/gdd/game-concept.md

> Design test：如果在"更精致的产物动画" vs "更扎实的摇杆震动"之间选——**选触感**。

**参考产品**（玩家可能熟悉的高质量 iOS 触觉）：
- iOS 自带相机快门（`heavy` 冲击参照）
- iPhone Apple Pay 完成（`success` selection 参照）
- Things 3 / Reminders 任务勾选（`selection` 轻触参照）
- 微信钱包"撕开"红包（中国玩家熟悉的高质量组合触觉）

*Authoring note: Lean review mode — `creative-director` 未直接调用；framing 与 Audio System Player Fantasy 章节对位以保持 Pillar 1 一致性。*

## Detailed Design

### Core Rules

1. **Autoload 单例**：Haptic 作为 Godot Autoload `Haptic` 全局可访问。下游通过 `Haptic.play(StringName)` 触发触觉。不允许任何系统直接调用 plugin。

2. **语义事件目录（封闭名字空间）**：所有触觉触发必须使用预定义事件键（见下方 Event Catalog）。未注册的键名 → debug build 触发 `assert(false)`；release build 静默 no-op + 单次 push_warning。

3. **iOS-first 真实播放**：iOS 通过 `kyoz/godot-haptics` plugin 映射到 UIImpactFeedbackGenerator 预设（`selection / light / medium / heavy / rigid`）。Android 由 plugin 提供基础 `vibrate` fallback，MVP 不测试不调优。

4. **设备能力一次性探测**：启动时调用 `plugin.is_available()`，结果缓存为 `_available: bool`。iPhone 6 及以下（无 Taptic Engine）→ `UNAVAILABLE` 永久状态，所有 `play()` no-op + init 日志一次。

5. **用户开关尊重 + 系统开关透明**：
   - 用户 app 内 `haptic_enabled: bool` 偏好（Persistence System `settings` 切片）= false → `MUTED` 状态，所有 `play()` no-op
   - iOS **系统级**触觉开关无法被 app 检测（Apple 政策）。系统关闭时 `play()` 仍执行 plugin 调用，但用户感受不到——这是预期行为，不报错

6. **Per-key debounce**：同一事件键在 `HAPTIC_DEBOUNCE_MS` 时间窗内重复调用 → 静默丢弃第二次及以后的调用（防止 60Hz `_process` 中误触发）。默认 50 ms。

7. **音触同步契约**：触觉发射必须在对应 Audio 事件发射后 **≤ 30 ms** 内（人类无法分辨此窗内的时序）。下游系统须在同一帧的同一回调中先 `AudioSystem.play()` 后 `Haptic.play()`，二者顺序与时间窗由 Juice Cookbook 标准化。

8. **同步非阻塞**：所有 API 返回 `void` 立即完成。不等待硬件 ack、不返回播放成功/失败状态、不抛错。失败安全是设计原则——一次触觉错失不应中断游戏循环。

9. **生命周期感知 — 自订 OS 通知**（与 Persistence / Input / Audio 三 Foundation 同侪同模式）：Haptic 在 `_ready()` 中通过 `_notification(NOTIFICATION_APPLICATION_PAUSED / NOTIFICATION_APPLICATION_RESUMED)` 覆写方法直接响应 OS lifecycle 通知，**不**通过 Mobile App Lifecycle 转发。后台期间所有 `play()` no-op（避免唤醒 Taptic Engine 浪费电）。这一架构决策的理由：Foundation 同侪间不应有跨节点的强耦合订阅链；每个 Foundation 自管自己的 OS 集成。详见 `mobile-app-lifecycle.md` § Dependencies "Cross-cutting" Haptic 行 + Core Rule 3（Lifecycle 不为四同侪转发 OS 通知）。

### Event Catalog

下游系统调用 `Haptic.play(key)` 时必须使用以下键名之一。键名采用 `<system>_<action>` 命名空间，与 Audio System 事件键（`sfx_*`）保持视觉上的命名独立。

| 事件键 | 触觉预设 | 触发场景 | Audio 对位（同时发射） | 调用方 |
|---|---|---|---|---|
| `lever_pull_start` | `selection` | 玩家手指首次按下摇杆 | (none) | Lever Interaction (#8) |
| `lever_pull_progress` | `light` | 摇杆拉过 50% / 75% 阈值 | (none) | Lever Interaction (#8) |
| `lever_lock` | `heavy` | 摇杆触底锁定 | `lever_pull` | Lever Interaction (#8) |
| `shred_start` | `medium` | 粉碎机器启动 | `shred_start` | Shred Process (#9) |
| `shred_pulse` | `light` | 粉碎循环中节奏脉冲 | (intra-loop, 见 F-2) | Shred Process (#9) |
| `shred_end` | `light` | 粉碎完成 | `shred_end` | Shred Process (#9) |
| `reveal_pop` | `selection` | 揭晓瞬间 | `reveal_pop` | Silhouette Reveal (#11) |
| `product_land` | `light` | 产物落到货架 | `product_land` | Silhouette Reveal (#11) |
| `shelf_add` | `light` | 产物正式入货架（柔和落地冲击，区分 `reveal_pop` 的 `selection` 清脆） | `shelf_add` | Shelf Collection (#12) |
| `mochi_blink` | `selection` | Mochi 角色反应（可选触发） | (none) | Mochi Character (#6) |

> **音触键约定**："Audio 对位"列填 Audio System 的 runtime 字符串键（无 `sfx_` 前缀）。Audio API 形如 `AudioSystem.play(&"lever_pull")`；Haptic API 形如 `Haptic.play(&"lever_lock")`。Registry 中 `sfx_*` 是实体名（追踪 ID），不是 runtime 键。下游写代码时切勿在调用字符串里加 `sfx_` 前缀。

**预设 → plugin 调用映射**：
- `selection` → `Haptics.selection()`（UIImpactFeedbackGenerator 选择反馈）
- `light` → `Haptics.light()` (UIImpactFeedbackGenerator light)
- `medium` → `Haptics.medium()`
- `heavy` → `Haptics.heavy()`
- `rigid` → `Haptics.rigid()`（保留：MVP 未使用，留给 Juice Cookbook 扩展）

### States and Transitions

> **修订 2026-05-21**：原 `_state: State` 单枚举无法表达"用户开关 vs 生命周期 vs 设备能力"三个**正交**维度——AC-S-4 "BACKGROUNDED → READY（除非用户在后台关了 toggle，则回 MUTED）" 在原数据结构下不可实现。修正：拆为三字段。

`play()` 行为由三个正交字段的组合决定：

| 字段 | 类型 | 来源 | 含义 |
|---|---|---|---|
| `_capability` | enum `{AVAILABLE, UNAVAILABLE}` | init 时 F-4 三层 gate 探测，终态不可变 | 硬件 / 编译期 / plugin 能力 |
| `_user_enabled` | bool | Persistence `settings.haptic_enabled`，默认 true | 玩家在 settings 中的开关 |
| `_lifecycle_state` | enum `{FOREGROUND, BACKGROUNDED}` | OS 通知 `application_paused`/`resumed` 切换 | app 当前是否在前台 |

**`play()` 派发规则**（短路）：

```
若 _capability == UNAVAILABLE   → no-op（首次 push_warning 一次）
否则若 _lifecycle_state == BACKGROUNDED → no-op（不报警，预期行为）
否则若 _user_enabled == false   → no-op（不报警，预期行为）
否则                              → 派发到 backend，发射 haptic_played
```

**逻辑视角下的"复合状态"**（仅用于 AC 与日志可读性，**不**是变量）：

| 复合状态名 | 字段组合 |
|---|---|
| `READY` | capability=AVAILABLE ∧ lifecycle=FOREGROUND ∧ user_enabled=true |
| `MUTED` | capability=AVAILABLE ∧ lifecycle=FOREGROUND ∧ user_enabled=false |
| `BACKGROUNDED` | capability=AVAILABLE ∧ lifecycle=BACKGROUNDED（user_enabled 不关心） |
| `UNAVAILABLE` | capability=UNAVAILABLE（其他不关心） |

状态机：

```
[init] → F-4 设备能力探测
       ├─ AVAILABLE → 进入正常派发；
       │              · application_paused  → lifecycle=BACKGROUNDED
       │              · application_resumed → lifecycle=FOREGROUND
       │              · set_user_enabled(b) → user_enabled=b（任何时刻可调）
       └─ UNAVAILABLE → 永久 no-op（capability 终态）
```

**关键性质**：`_lifecycle_state` 和 `_user_enabled` 互相**不相干**——后台时用户开/关 toggle 不影响 lifecycle；前台时 lifecycle 切换不影响 user_enabled。这是 AC-S-4 可实现的前提。

### Interactions with Other Systems

**下游（5 个核心系统直接调用 `Haptic.play()`）**：

| 系统 | 调用键 | 频率 |
|---|---|---|
| Lever Interaction (#8) | `lever_pull_start / lever_pull_progress / lever_lock` | 每次摇杆操作 1-3 次 |
| Shred Process (#9) | `shred_start / shred_pulse / shred_end` | 每次粉碎循环 1 + N + 1 次（N 见 Formula F-2） |
| Silhouette Reveal (#11) | `reveal_pop / product_land` | 每次揭晓 2 次 |
| Shelf Collection (#12) | `shelf_add` | 每次新产物入货架 1 次 |
| Mochi Character (#6) | `mochi_blink` | 偶发，由角色状态机决定 |

**跨切面依赖**：

| 系统 | 接口 | 数据方向 |
|---|---|---|
| Audio System (#3) | 协同发射；同一帧先 Audio 后 Haptic，Haptic 在 Audio 后 ≤ 30 ms | 时间约束（无数据） |
| Mobile App Lifecycle (#5) | **无直接关系**——Haptic 自订 OS `NOTIFICATION_APPLICATION_PAUSED/_RESUMED` 通知（与 Persistence/Input/Audio 同侪同模式）；详见 `mobile-app-lifecycle.md` § Dependencies "Cross-cutting" Haptic 行 + Core Rule 3 | (无) |
| Persistence (#1) | 读 `settings.haptic_enabled: bool` 切片；写回时通过 `Persistence.set_slice("settings", ...)` | 双向 |
| Juice Cookbook (#13) | 提供"音 + 触"标准组合 reference；明确每个事件的音触配对契约 | Cookbook → 实现规范 |

### API（伪 GDScript）

```gdscript
# Autoload: Haptic
class_name HapticSystem extends Node

const VALID_KEYS: Dictionary[StringName, StringName] = {
    &"lever_pull_start":    &"selection",
    &"lever_pull_progress": &"light",
    &"lever_lock":          &"heavy",
    &"shred_start":         &"medium",
    &"shred_pulse":         &"light",
    &"shred_end":           &"light",
    &"reveal_pop":          &"selection",
    &"product_land":        &"light",
    &"shelf_add":           &"light",
    &"mochi_blink":         &"selection",
}
const HAPTIC_DEBOUNCE_MS: int = 50

# ADR-0001 Decision 5: Persistence `settings` slice constants.
# MUST be `String` (not `StringName`) — JSON.parse_string() returns String-keyed Dictionaries.
# StringName literals (&"settings") would silently return null on get_slice() lookup.
const SETTINGS_SLICE          := "settings"
const SETTINGS_HAPTIC_ENABLED := "haptic_enabled"

signal haptic_played(key: StringName)  # 调试 + Juice Cookbook 验证

enum Capability { AVAILABLE, UNAVAILABLE }
enum LifecycleState { FOREGROUND, BACKGROUNDED }

var _capability: Capability = Capability.AVAILABLE  # F-4 终态
var _lifecycle_state: LifecycleState = LifecycleState.FOREGROUND
var _user_enabled: bool = true
var _last_emit_ms: Dictionary[StringName, int] = {}  # key → Time.get_ticks_msec()
var _backend: HapticBackend = null
var _warned_unavailable: bool = false

func _ready() -> void:
    _backend = _create_backend()  # 注入接缝，见下
    _capability = _backend.detect_capability()
    # ADR-0001 Decision 5: read user toggle via String-keyed `settings` slice.
    # Per Persistence Core Rule 10 Carve-out 例外清单 #1：
    # HapticService #4 在 _ready() 同步读取 settings.haptic_enabled，
    # 因 PersistenceService #1 已完成 _ready() 并进入 READY_*。
    var s: Dictionary = PersistenceService.get_slice(SETTINGS_SLICE, {})
    _user_enabled = s.get(SETTINGS_HAPTIC_ENABLED, true)
    # 自订 OS 通知（不通过 Lifecycle 转发，对齐 Foundation 同侪模式）
    # 由 _notification(what) 覆写方法处理 NOTIFICATION_APPLICATION_PAUSED / _RESUMED。

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_APPLICATION_PAUSED:  _on_app_paused()
        NOTIFICATION_APPLICATION_RESUMED: _on_app_resumed()

func play(key: StringName) -> void:
    assert(key in VALID_KEYS, "Haptic: unknown key %s" % key)
    if _capability == Capability.UNAVAILABLE:
        if not _warned_unavailable:
            push_warning("Haptic: Taptic Engine unavailable on this device (model: %s)" % OS.get_model_name())
            _warned_unavailable = true
        return
    if _lifecycle_state == LifecycleState.BACKGROUNDED: return
    if not _user_enabled: return
    var now: int = Time.get_ticks_msec()
    var prev: int = _last_emit_ms.get(key, -10000)
    if now - prev < HAPTIC_DEBOUNCE_MS: return
    _last_emit_ms[key] = now
    _backend.dispatch(VALID_KEYS[key])  # 派发预设字符串到 backend
    haptic_played.emit(key)

func set_user_enabled(enabled: bool) -> void:
    """玩家在 settings 中切换；与 lifecycle/capability 正交。"""
    _user_enabled = enabled
    # ADR-0001 Decision 5: write via String-keyed `settings` slice.
    # READ-MODIFY-WRITE pattern — per Persistence Edge Case C, domain wrapper owns merge.
    # 防止未来 settings slice 加入其他键时被本调用静默清空。
    var s: Dictionary = PersistenceService.get_slice(SETTINGS_SLICE, {})
    s[SETTINGS_HAPTIC_ENABLED] = enabled
    PersistenceService.set_slice(SETTINGS_SLICE, s)
    PersistenceService.save_when_idle()

func is_available() -> bool:
    return _capability == Capability.AVAILABLE

func is_ready() -> bool:
    ## Foundation Autoload contract (ADR-0001 Decision 1).
    ## True when _ready() has completed and capability check has settled.
    ## True for both AVAILABLE and UNAVAILABLE — settled state, not output guarantee.
    ## _ready() is fully synchronous; is_node_ready() is a sufficient guard.
    return is_node_ready()

func _on_app_paused() -> void:
    _lifecycle_state = LifecycleState.BACKGROUNDED

func _on_app_resumed() -> void:
    _lifecycle_state = LifecycleState.FOREGROUND

func _create_backend() -> HapticBackend:
    """注入接缝。Production 用 PluginHapticBackend；GUT 测试覆盖此方法返回 MockHapticBackend。"""
    return PluginHapticBackend.new()


# --- HapticBackend 抽象接口（Godot 4.5+ @abstract，替换接缝） ---
@abstract class_name HapticBackend extends RefCounted

@abstract func detect_capability() -> HapticSystem.Capability
@abstract func dispatch(preset: StringName) -> void


# --- Production backend：kyoz/godot-haptics plugin 包装 ---
class_name PluginHapticBackend extends HapticBackend

func detect_capability() -> HapticSystem.Capability:
    if not OS.has_feature("ios"): return HapticSystem.Capability.UNAVAILABLE
    if not _device_has_taptic_engine(): return HapticSystem.Capability.UNAVAILABLE
    if not Engine.has_singleton("Haptics"): return HapticSystem.Capability.UNAVAILABLE  # plugin 未加载
    var plugin := Engine.get_singleton("Haptics")
    if not plugin.is_available(): return HapticSystem.Capability.UNAVAILABLE
    return HapticSystem.Capability.AVAILABLE

func dispatch(preset: StringName) -> void:
    var plugin := Engine.get_singleton("Haptics")
    match preset:
        &"selection": plugin.selection()
        &"light":     plugin.light()
        &"medium":    plugin.medium()
        &"heavy":     plugin.heavy()
        &"rigid":     plugin.rigid()

func _device_has_taptic_engine() -> bool:
    # F-4 model whitelist — 详见 Formulas 章节
    var model: String = OS.get_model_name()
    return _model_in_taptic_whitelist(model)
```

**实现注记**：
- `Time.get_ticks_msec()` 是 Godot 4.4+ 必需写法（4.4 起 `OS.get_ticks_msec()` 弃用）
- `VALID_KEYS: Dictionary` 同时担任白名单 + 事件→预设映射，O(1) 查找（替代原 `Array[StringName]`，避免 O(n) `in` 查询）
- `assert` 仅在 debug build 触发，release build 自动剥离
- `HapticBackend` 是 Godot 4.5+ `@abstract` 抽象类——GUT 测试可注入 `MockHapticBackend` 验证 `dispatch()` 被调用次数与参数
- `set_user_enabled()`（原 `set_enabled()`）只动 `_user_enabled`，**不**动 lifecycle/capability——这是 AC-S-4 可实现的关键
- 后续切换到 CoreHaptics 自定义波形 → 实现 `CoreHapticsBackend extends HapticBackend`，零改 Haptic System 主类
- `_capability` 一旦在 `_ready()` 中设定，**永不可变**——这是终态语义，AC-S-5 保证

## Formulas

Haptic System 的"公式"主要是技术参数推导和音触同步约束，非 balance 曲线。共 4 条。

### F-1：音触感知到达同步（Audio-Haptic Perceptual Arrival Sync）

> **修订 2026-05-21**：原公式度量 `|t_audio_emit − t_haptic_emit|`（API 调用时刻），但 iOS 音频管线延迟约 35–65 ms，Taptic Engine 延迟约 3–10 ms。API 同时调用 → 玩家**先摸后听**滞后 30–60 ms，穿越同步窗口。F-1 改为度量**感知到达**时刻差，并引入 `AUDIO_LEAD_MS` 让 Haptic 延迟发射以补偿管线差。

同帧内连续调用 `AudioSystem.play()` → `Haptic.play()` 必须保证人类感知层两通道到达时刻同步：

```
t_audio_arrive  = t_audio_emit_ms + AUDIO_PIPELINE_LATENCY_MS
t_haptic_arrive = t_haptic_emit_ms + HAPTIC_PIPELINE_LATENCY_MS

|t_audio_arrive − t_haptic_arrive| ≤ AUDIO_HAPTIC_PERCEPTUAL_WINDOW_MS
```

等价工程实现：调用方在同帧先 `AudioSystem.play()`，**延迟 `AUDIO_LEAD_MS` 后**再 `Haptic.play()`：

```
AUDIO_LEAD_MS = AUDIO_PIPELINE_LATENCY_MS − HAPTIC_PIPELINE_LATENCY_MS
```

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|---|---|---|---|---|
| Audio API 发射时刻 | `t_audio_emit_ms` | int | 0 — ∞ | `AudioSystem.play()` 调用瞬间 `Time.get_ticks_msec()` |
| Haptic API 发射时刻 | `t_haptic_emit_ms` | int | 0 — ∞ | `Haptic.play()` 调用瞬间 `Time.get_ticks_msec()` |
| Audio 管线延迟 | `AUDIO_PIPELINE_LATENCY_MS` | int 常量 | 默认 40（真机校准） | iOS AVAudioPlayer 从 `play()` 到耳机听到声音的耳机/扬声器延迟 |
| Haptic 管线延迟 | `HAPTIC_PIPELINE_LATENCY_MS` | int 常量 | 默认 5（真机校准） | Taptic Engine 从 plugin call 到触感发生延迟 |
| 补偿提前量 | `AUDIO_LEAD_MS` | int 常量 | 默认 35（= 40 − 5，真机校准后回填） | Haptic.play() 相对 Audio.play() 的延迟发射量 |
| 感知到达同步窗口 | `AUDIO_HAPTIC_PERCEPTUAL_WINDOW_MS` | int 常量 | 默认 30（人因学硬约束） | 触听感知同步阈值 |

**输出范围：** 在 `AUDIO_LEAD_MS = 35` 默认校准下，调用方同帧顺序 `Audio→ wait 35ms →Haptic` → 感知到达时刻差 |ΔT| ≤ 5 ms（远小于 30 ms 窗口），玩家感受为"同时"。

**例：** Lever lock 触发 → 同帧调用 `AudioSystem.play(&"lever_pull")` 在 t=12345 ms；调度 35 ms 后 `Haptic.play(&"lever_lock")` 在 t=12380 ms。Audio 到达耳机时刻 = 12345 + 40 = 12385 ms；Haptic 到达手指时刻 = 12380 + 5 = 12385 ms。差 0 ms ✓ 感知同步成立。

**调用方实现约定：**
- 推荐：调用方调度一个 `AUDIO_LEAD_MS` 延迟的定时器再调 `Haptic.play()`，**不**由 Haptic System 内部延迟（避免下游"我没看见 haptic 发射"的调试困惑）。
- 替代：Audio System 暴露 `play_with_haptic(audio_key, haptic_key)` 一体 API，由 Audio System 内部处理调度。**v1.0 待评估**（涉及 Juice Cookbook 标准化）。
- MVP：调用方在 `await get_tree().create_timer(AUDIO_LEAD_MS / 1000.0).timeout` 后调 Haptic，或在调用方自己的状态机中安排。

**依据**：
- Spence (2007) "Crossmodal Temporal Binding" 实验阈值 ≈ ±30 ms（感知同步上限）。
- iOS Audio Pipeline 延迟在 iPhone XS/13/14/15 实测 25–65 ms（依赖路由：扬声器 vs AirPods 蓝牙路径差异极大；MVP 默认值假定有线/扬声器路径）。
- Taptic Engine 延迟 3–10 ms（Apple 文档未明示，社区测量值）。
- `AUDIO_LEAD_MS` 默认 35 是中位数估计，**Production Sprint 1 必须真机校准**（详见 Q-1）。

### F-2：shred_pulse 节奏调度（Shred Pulse Schedule）

粉碎进行中的 `shred_pulse` 触觉必须形成"机器在持续工作"的节奏感。F-2 同时定义"几次"和"什么时候"。

**脉冲数：**

```
pulse_count = floor((shred_duration_s − shred_pulse_offset_s) / shred_pulse_interval_s) + 1
```

**脉冲时刻表**（Shred Process #9 调用方据此调度 `Haptic.play(&"shred_pulse")`）：

```
pulse_schedule[i] = shred_start_time_ms + (shred_pulse_offset_s + i × shred_pulse_interval_s) × 1000
                    for i ∈ [0, pulse_count − 1]
```

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|---|---|---|---|---|
| 粉碎总时长 | `shred_duration_s` | float | 2.5 — 4.0 | 来自 Shred Process #9（待写） |
| 脉冲首次偏移 | `shred_pulse_offset_s` | float | 0.2 — 0.4 | `shred_start` 触觉后到首个 `shred_pulse` 的间隔；默认 0.3（给 shred_start 重击留呼吸） |
| 脉冲间隔 | `shred_pulse_interval_s` | float | 0.3 — 0.5 | Haptic 调节旋钮，默认 0.4 |
| `shred_start` 时刻 | `shred_start_time_ms` | int | 0 — ∞ | Shred Process 触发 `shred_start` 的 `Time.get_ticks_msec()` |
| 输出脉冲数 | `pulse_count` | int | 4 — 11 | 粉碎过程中触觉脉冲总次数 |

**输出范围：** 默认参数（duration=3.0, offset=0.3, interval=0.4）→ pulse_count = floor((3.0 − 0.3) / 0.4) + 1 = floor(6.75) + 1 = 7。安全范围 5–10 次。

**例：** Shred 开始 t=10000 ms → `shred_start` 触觉立即发射；7 个 `shred_pulse` 在 10300, 10700, 11100, 11500, 11900, 12300, 12700 ms 发射；`shred_end` 触觉在 13000 ms 发射。

**依据**：
- 间隔 ≥ 300 ms 保持离散冲击感（< 200 ms 进入"震动"感知，破坏 iOS 触觉哲学）。
- 间隔 ≤ 500 ms 由 Apple HIG 连续性阈值约束（> 600 ms 失去"机器在工作"感）。原 F-2 范围上界 0.6 收紧为 0.5。
- `shred_pulse_offset_s` 引入是为了让 `shred_start` 的 `medium` 重击与首个 `shred_pulse` 的 `light` 之间有清晰分隔（人耳/手在 < 200 ms 内会把两者合并感知）。

### F-3：per-key debounce 窗口（Per-Key Debounce）

防止 60Hz `_process` 循环或物理碰撞回调中同一事件被误触发多次。

`should_emit(key, now_ms) = (now_ms − last_emit_ms[key]) ≥ HAPTIC_DEBOUNCE_MS`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|---|---|---|---|---|
| 当前时刻 | `now_ms` | int | 0 — ∞ | `Time.get_ticks_msec()` |
| 该键上次发射时刻 | `last_emit_ms[key]` | int | 0 — ∞ | Dictionary 缓存；首次为 −10000（远古） |
| Debounce 阈值 | `HAPTIC_DEBOUNCE_MS` | int 常量 | 默认 50 | 单位毫秒 |

**输出：** bool — true 则发射，false 则静默丢弃。
**例：** `lever_pull_progress` 在 `_process` 中误判触发两次，间隔 16 ms（一帧）→ should_emit 返回 false，第二次被丢弃。

**依据**：50 ms 略大于一帧（16.6 ms），略小于 UIImpactFeedbackGenerator 的最小可感知间隔（约 60–80 ms）。这确保单帧误触发被滤除，但不影响有意的快速连发（如 `lever_pull_progress` 50% → 75% 阈值连续越过）。

> **修订 2026-05-21**：原 Tuning Knobs 写 `< 16` 临界值不发射，与代码 `≥ HAPTIC_DEBOUNCE_MS` 含义错位（16 ms 是临界，应包含发射）。Tuning Knobs 安全范围下界改 `≤ 16`；上界 `100` 收紧为 `80`——`lever_pull_progress` 50% / 75% 阈值在真机上 60–90 ms 内连发是常态，> 80 ms 会丢失第二个里程碑触觉。安全范围 = [16, 80] ms。

### F-4：设备能力探测决策（Device Capability Gate）

启动时一次性探测 Taptic Engine 可用性，结果决定 init 后的状态。F-4 改用三层 gate：编译期 + 平台 + 设备型号 + plugin。

```
is_available = OS.has_feature("ios")
               AND _device_has_taptic_engine()
               AND plugin.is_available()
```

**`_device_has_taptic_engine()` 决策：**

```
func _device_has_taptic_engine() -> bool:
    var model: String = OS.get_model_name()  # 例: "iPhone13,4" / "iPad8,9"
    # iPhone：7（"iPhone9,*"）及以上有 Taptic Engine
    # iPad：仅 iPad Pro 第三代+ 11" / 12.9"（"iPad8,*" 及以上的 Pro 系列）
    return _model_in_taptic_whitelist(model)
```

**变量：**

| 变量 | 类型 | 来源 |
|---|---|---|
| `OS.has_feature("ios")` | bool | Godot 内置；编译时常量 |
| `OS.get_model_name()` | String | Godot 4.4+ 运行时返回 |
| `_model_in_taptic_whitelist(model)` | bool | 本系统维护的 iPhone/iPad Taptic Engine 设备清单 |
| `plugin.is_available()` | bool | `kyoz/godot-haptics` plugin 提供 |

**输出：**
- 三层全 true → init 状态 = `READY`
- 任一层 false → init 状态 = `UNAVAILABLE`（不可逆）

**例：**
- iPhone XS（"iPhone11,2"，A12，Taptic Engine 2）→ ios=true, whitelist=true, plugin=true → READY。
- iPad Air 4（"iPad13,1"，无 Taptic Engine，仅 Linear Vibration）→ ios=true, whitelist=false（未在 Pro 清单中）→ UNAVAILABLE。
- iPad Pro 11" 第三代（"iPad13,4"，有 Taptic Engine）→ ios=true, whitelist=true, plugin=true → READY。
- iPhone 6（"iPhone7,2"，无 Taptic Engine）→ ios=true, whitelist=false → UNAVAILABLE。
- Android 编译版本 → ios=false → UNAVAILABLE。

**依据**：单靠 plugin 探测在某些越狱机型或老 iOS 上可能返回不可靠值。Apple 没有公开 API 直接查询 Taptic Engine 存在性，业内通行做法是维护 model name 白名单。三层 gate 是防御性写法。MVP 白名单初始版本：**Production Sprint 1 真机校准**，按 Apple 设备清单回填。

> **修订 2026-05-21**：原 F-4 只双重 gate（`plugin AND ios`）与 Edge Case A "所有 iPad 都 UNAVAILABLE" 矛盾——iPad Pro 11" 第三代+ 实际有 Taptic Engine 2，plugin.is_available() 会返回 true。F-4 增加 `_device_has_taptic_engine()` 显式判断，Edge Case A 改述为"无 Taptic Engine 设备（含 iPhone 6 及以下、iPad Air/mini 系列、所有非 Pro iPad、Android）"。

---

*Authoring note: Revised 2026-05-21 to address review BLOCKING #3 / #4 / #10 / #11. F-1 改为感知到达约束；F-2 补脉冲调度公式；F-3 边界 off-by-one + 上限收紧；F-4 加 model whitelist。`systems-designer` 评审同步以上修订。*

## Edge Cases

### A. 设备能力边界

- **若设备不支持 Taptic Engine**（iPhone 6 及以下、iPad Air / mini / 任何非 Pro 系列、iPad Pro 第二代及以前；详见 F-4 model whitelist）：init 时探测一次，`_state` 永久设为 `UNAVAILABLE`。所有 `play()` 调用静默 no-op，首次调用时 `push_warning("Haptic: Taptic Engine unavailable on this device (model: %s)" % OS.get_model_name())` 仅一次。游戏循环不中断。**iPad Pro 11" 第三代及以上** 有 Taptic Engine 2，进入 `READY` 路径。
- **若 plugin 加载失败 / 缺失**：`OS.has_feature("ios") AND plugin == null` → 同 UNAVAILABLE 路径。debug build 在 `_ready()` 中 `assert(plugin != null)`，release build 静默 no-op。
- **若运行在 Android 编译版本上**：`OS.has_feature("ios")` 返回 false → 强制 UNAVAILABLE，即便 plugin 提供 Android `vibrate()` 实现也不调用。MVP 契约：Android 不投触觉精力。

### B. 用户偏好与系统级开关

- **若用户在 settings 中关闭 `haptic_enabled`**：状态 `MUTED`，所有 `play()` no-op。`Persistence.set_slice("settings", {"haptic_enabled": false})` 持久化。重启后状态恢复。
- **若 iOS 系统级"系统触感"开关被用户关闭**：app **无法**检测此状态（Apple 政策）。`play()` 仍调用 plugin，但 iOS 不响应——这是预期行为，**不上报错误、不静音 Audio**。玩家在系统设置中的选择是 OS 主权。
- **若 settings 切片在 Persistence 中不存在（首次启动）**：默认 `haptic_enabled = true`。首次启动即可感受到触觉。
- **若用户在玩到一半时切换 toggle**：`set_user_enabled()` 调用后**当前帧**生效（写 `_user_enabled` 字段）。已发射但未完成的触觉不试图取消（UIImpactFeedbackGenerator 是 fire-and-forget）。
- **若 settings 切片被外部篡改成无效值（非 bool）**：`Persistence.get_slice("settings").get("haptic_enabled", true)` 默认 true，错误值视为缺失。

### C. 生命周期边界

- **若 app 在触觉播放过程中收到 `application_paused` OS 通知**：当前已派发的触觉由 iOS 自然完成（plugin 不可取消），新进入的 `play()` 调用因 `_lifecycle_state = BACKGROUNDED` 进入 no-op 分支。
- **若 app 从 BACKGROUNDED 恢复（`application_resumed` OS 通知）**：`_lifecycle_state = FOREGROUND`，派发恢复。**不**补播后台期间被丢弃的触觉调用（"丢失的反馈不补"原则）。**若用户在后台期间关了 toggle**：`_user_enabled` 已是 false，恢复前台后 `play()` 仍走 MUTED 分支（AC-S-4）。
- **若 app 在 `READY` 状态收到 phone call、Siri 等系统中断**：iOS 自动屏蔽自定义触觉，app 无须处理。系统中断结束后 iOS 自动恢复。
- **若用户在游戏中接到来电、播放期间触觉调用**：底层 plugin 调用照常完成，但 UIImpactFeedbackGenerator 在 system audio session interrupted 状态下不响应——同上预期行为。

### D. 重入与同步边界

- **若同一事件键在 `HAPTIC_DEBOUNCE_MS=50ms` 窗口内被多次触发**：第一次发射，后续静默丢弃（per-key debounce，F-3）。每个 key 独立计时。
- **若不同事件键在同一帧被多次触发（如 `lever_lock` + `shelf_add` 同帧）**：全部按调用顺序串行派发到 plugin。UIImpactFeedbackGenerator 不存在"并发上限"——iOS 内部合并/排队。但 **不应**：Juice Cookbook 应规范"同帧 ≤ 2 个触觉事件"以避免感知混淆。
- **若 `Haptic.play()` 在 Audio.play() **之前** 发射（顺序错误）**：触觉先到，听觉后到——人类对"摸先于听"更宽容（≤30ms 仍同步），但调用约定要求 Audio 先。下游违反约定时不报错，仅在 Juice Cookbook 测试中标记。
- **若 Audio 失败但 Haptic 成功（不同步局部）**：Haptic 仍按计划执行，**不**回滚或重试 Audio。"反馈宁可单通道，不能同时失声"原则。

### E. 设备运行时边界

- **若 iOS 处于 Low Power Mode**：UIImpactFeedbackGenerator **不**受影响（仅 CoreHaptics 自定义波形被限速）。MVP 路径无需特殊处理。**Open Question**：未来如升级到 CoreHaptics，需重新评估此边界。
- **若设备静音键开启**：触觉**不**受影响（与 Audio 完全独立通道）。这是 Haptic 价值的一部分——静音场景中仍能传达反馈。
- **若设备温度过高 / Taptic Engine 过载（极罕见）**：iOS 自动降级到一档振动或不响应，plugin 不可见此状态，app 行为同"系统级开关关闭"路径。
- **若设备进入横屏 / 锁屏方向变化**：触觉与方向无关，无需处理。

## Dependencies

### 上游 — 本系统依赖

**无。** Haptic System 是 Foundation 层零上游依赖系统。Godot 4.6 引擎 + `kyoz/godot-haptics` plugin 是运行时依赖，不属于 GDD 依赖图。

### 下游 — 依赖本系统

5 个核心系统调用 `Haptic.play()`：

| # | 系统 | GDD 状态 | 调用的事件键 | 调用频率 |
|---|---|---|---|---|
| 6 | Mochi Character System | Not Started | `mochi_blink` | 角色状态机决定，偶发 |
| 8 | Lever Interaction System | Not Started | `lever_pull_start / lever_pull_progress / lever_lock` | 每次摇杆操作 1-3 次 |
| 9 | Shred Process System | Not Started | `shred_start / shred_pulse / shred_end` | 每次粉碎循环 1 + N（4-13） + 1 次 |
| 11 | Silhouette Reveal System | Not Started | `reveal_pop / product_land` | 每次揭晓 2 次 |
| 12 | Shelf Collection System | Not Started | `shelf_add` | 每次新产物入货架 1 次 |

### 跨切面依赖

非"上下游"关系，但需要协调或读取数据：

| 系统 | GDD 状态 | 关系类型 | 数据流 |
|---|---|---|---|
| Audio System (#3) | ✅ Designed | 协同发射 | 同帧先 Audio 后 Haptic，时间窗 ≤ 30 ms（F-1） |
| Mobile App Lifecycle (#5) | ✅ Designed | **无直接订阅** | Haptic 自订 OS 通知；Lifecycle 仅作为同侪存在（详见 Core Rule 9） |
| Persistence System (#1) | ✅ Designed | 偏好读写 | 读 `settings.haptic_enabled: bool`；通过 `Persistence.set_slice()` 写回 |
| Juice Cookbook (#13) | Not Started | 规范引用 | Cookbook 定义"音 + 触"标准组合，本 GDD 实现 |

### 双向一致性 — 待确认项

下游 GDD 编写时，必须在各自的 Dependencies 章节列入 "**depends on Haptic System (#4)**"，并明确：

| 下游 GDD | 必须列出 | 协议契约 |
|---|---|---|
| `lever-interaction.md` | "depends on Haptic — calls 3 keys" | `lever_pull_start / progress / lock` 触发时机 |
| `shred-process.md` | "depends on Haptic — calls 3 keys" | 粉碎循环中 `shred_pulse` 节奏由 F-2 计算 |
| `silhouette-reveal.md` | "depends on Haptic — calls 2 keys" | `reveal_pop` 在 silhouette tap 后 ≤ 30 ms 内 |
| `shelf-collection.md` | "depends on Haptic — calls 1 key" | `shelf_add` 在产物入位动画完成时 |
| `mochi-character.md` | "depends on Haptic — calls 1 key (optional)" | `mochi_blink` 由角色情绪状态机决定 |
| `juice-cookbook.md` | "standardises Haptic event pairing with Audio" | 引用本 GDD Event Catalog 作为权威清单 |

下游 GDD 写作时若发现需要的事件键不在 Event Catalog 中——**不允许扩充**事件键，必须先回到本 GDD 提出 PR 增加新键，由 game-designer + audio-director + Mochi 主理人评审通过后才能加入。这是为了控制触觉调色板规模、防止设计漂移。

### Plugin / 运行时依赖

虽不属 GDD 依赖，记录在此供 Architecture 阶段参考：

- `kyoz/godot-haptics` plugin（默认候选，活跃维护，显式支持 Godot 4.5.2 / 4.6.1）
- iOS Taptic Engine（iPhone 7 及以上 / iPad Pro 11" 第三代及以上）
- 备选：`extrawurst/godot-ios-impact-plugin`（API 较少，仅 iOS）
- 备选：自建 GDExtension 桥（仅当 CoreHaptics 自定义波形被 prototype 验证为必需时——见 Open Questions）

## Tuning Knobs

### 玩家面向（settings UI 可见）

| 旋钮 | 类型 | 默认值 | 范围 | 持久化位置 |
|---|---|---|---|---|
| `haptic_enabled` | bool | `true` | true / false | `Persistence.settings.haptic_enabled` |

唯一面向玩家的旋钮。设置界面在 v1.0 加入；MVP 仅暴露代码 API（默认 true，开发期手动改 plugin 直接关闭测试）。

### 设计师 / 开发者面向（代码常量或 config）

| 旋钮 | 单位 | 默认值 | 安全范围 | 极端行为 |
|---|---|---|---|---|
| `HAPTIC_DEBOUNCE_MS` | 毫秒 | 50 | [16, 80] | ≤ 16：单帧多次触发不再被过滤，性能下降；> 80：`lever_pull_progress` 50%/75% 阈值在真机 60–90 ms 内连发会被错误丢弃 |
| `AUDIO_HAPTIC_PERCEPTUAL_WINDOW_MS` | 毫秒 | 30 | [10, 50] | 受 Spence (2007) 人因学硬约束，超出 50ms 触听同步感破坏；< 10ms 工程上不可达（_process tick 粒度限制） |
| `AUDIO_LEAD_MS` | 毫秒 | 35（真机校准后回填） | [0, 80] | Haptic 相对 Audio 的延迟发射量，补偿 iOS Audio 管线 vs Taptic Engine 延迟差。Production Sprint 1 真机校准；不同设备代际可能有差异（AirPods 路径差异大，MVP 假定扬声器/有线） |
| `AUDIO_PIPELINE_LATENCY_MS` | 毫秒 | 40（真机校准） | [25, 65] | iOS AVAudioPlayer 从 `play()` 到耳/扬声器响声延迟；真机校准 |
| `HAPTIC_PIPELINE_LATENCY_MS` | 毫秒 | 5（真机校准） | [3, 10] | Taptic Engine 从 plugin call 到触感发生延迟；真机校准 |
| `shred_pulse_interval_s` | 秒 | 0.4 | [0.3, 0.5] | < 0.3：连续震动感取代离散冲击；> 0.5：失去"机器在工作"存在感（Apple HIG 连续性阈值） |
| `shred_pulse_offset_s` | 秒 | 0.3 | [0.2, 0.4] | < 0.2：与 `shred_start` 重击合并感知（破坏离散冲击哲学）；> 0.4：脉冲启动太晚，"机器没启动"假象 |

### 事件 → 预设映射表（数据驱动 config）

以下映射在 MVP 编码为常量，v1.0 可移到 `data/haptic_events.tres` 让设计师无需改代码即可调音：

| 事件键 | MVP 默认预设 | 备选（v1.0+） |
|---|---|---|
| `lever_pull_start` | `selection` | `light` |
| `lever_pull_progress` | `light` | `selection` |
| `lever_lock` | `heavy` | `rigid`（iOS 13+ 更"硬质"感） |
| `shred_start` | `medium` | `heavy` |
| `shred_pulse` | `light` | `selection` |
| `shred_end` | `light` | `selection` |
| `reveal_pop` | `selection` | `light` |
| `product_land` | `light` | `selection` |
| `shelf_add` | `light` | `selection`（仅当 `reveal_pop` 改为 `light` 时） |
| `mochi_blink` | `selection` | (none — 角色系统自定) |

### Juice 关联

以下旋钮的"正确值"由 Juice Cookbook（#13，待写）锁定后回填本 GDD：
- `shred_pulse_interval_s` 必须与 Audio 的 shred_loop BPM 协调（同步节拍而非自由节奏）
- 事件→预设映射表必须与 Juice Cookbook 的 "音 + 触" 标准组合表一致
- `AUDIO_HAPTIC_SYNC_WINDOW_MS` 是 Juice Cookbook 强约束，本 GDD 仅记录默认值

### 明确不是旋钮（拒绝调节理由）

| 项 | 为什么不可调 |
|---|---|
| 10 个事件键名称（`lever_pull_start` 等） | 跨系统 API 契约。改名需要同步改 5 个下游 GDD + 所有调用代码 |
| iOS-first 平台契约 | 项目级决策，写入 technical-preferences.md |
| Per-key debounce 算法 | 实现细节，无设计语义 |
| iOS 系统级触觉开关检测 | Apple iOS 18+ 隐私政策禁止 app 读取此状态 |
| Taptic Engine 设备探测决策（F-4） | 双重 gate（plugin + OS feature）是防御性写法，松动会引入运行时不确定性 |
| Android 触觉行为 | MVP 契约：免费搭车不投资 |
| 音触发射顺序（Audio 先 Haptic 后） | 同步窗口设计前提，不允许下游反向 |

### 隐私不可调

| 项 | 状态 |
|---|---|
| 触觉事件日志包含玩家输入内容 | **永远不**。日志只含事件键名（如 `lever_lock`），不含玩家输入的烦恼文本 |
| 触觉调用次数统计上报 | **永远不**。MVP 无远程遥测；本地 debug log 仅在 dev build 启用 |

## Visual/Audio Requirements

Haptic System 本身无视觉表现——玩家不"看见"触觉。**音频协调**是关键：

- **音触强同步**：所有 Audio + Haptic 配对事件须在 ≤ 30 ms 内（F-1）。下游系统调用约定：先 `AudioSystem.play()` 后 `Haptic.play()`，同帧 / 同回调内
- **音触配对清单**：见 Section C 的 Event Catalog "Audio 对位"列，由 Juice Cookbook (#13) 最终规范
- **Visual 提示玩家关 / 开**：Settings UI（v1.0）切换 `haptic_enabled` 时，应同时播放一次 `selection` 触觉作为"你正在调整触觉"的元反馈——但当用户关闭时不播放（避免悖论）

无独立 VFX、动画、shader 要求。

## UI Requirements

**MVP 阶段无 UI**。MVP 仅暴露代码 API（`Haptic.set_user_enabled()`）；开发期通过 plugin 直接调试，无玩家可见控件。

**v1.0 阶段 UI**（待 `/ux-design` 出 Settings 屏幕 spec）：

- Settings 屏幕中 "**触觉反馈**" toggle（默认开）
- 当设备为 `UNAVAILABLE`：toggle 显示为禁用灰态 + 一行说明文字"此设备不支持高级触觉"
- 当 iOS 系统级触觉关闭时：app 无法检测，toggle 仍正常显示开（玩家在 iOS 设置中关，应在 iOS 设置中开——app 不传递此信息以免越权暗示）

> **📌 UX Flag — Haptic System**: 当 Settings UI（v1.0）启动 UX 设计时，运行 `/ux-design design/ux/settings.md`。Stories 引用该 UX 文件，不直接引用本 GDD 的 UI Requirements 章节。

## Acceptance Criteria

每条均为可独立验证的 Given-When-Then；分类标注自动化可达性。**AC-Q-* 为手动测试**——触觉品质验证是 Pillar 1 强制要求，自动化不能替代真机感受；评分须按 `production/qa/haptic-quality-rubric.md` 量表执行。

### 功能验证（可自动化 — GUT）

- **AC-F-1** | **GIVEN** Haptic Autoload 初始化完成 **WHEN** 调用 `Haptic.play(&"lever_pull_start")` **THEN** `haptic_played` 信号发射一次，载荷 = `&"lever_pull_start"`，且 backend `dispatch(&"selection")` 被调用一次。
- **AC-F-2** | **GIVEN** Haptic 复合状态 = `READY` **WHEN** 在 `HAPTIC_DEBOUNCE_MS=50ms` 窗口内连续调用 `Haptic.play(&"lever_lock")` 两次（间隔 16ms） **THEN** 仅第一次发射 `haptic_played` 信号，第二次被静默丢弃。
- **AC-F-3** | **GIVEN** Haptic 复合状态 = `READY` **WHEN** 在同帧调用 `lever_lock` + `shelf_add`（不同键） **THEN** 两次 `haptic_played` 信号均发射，backend `dispatch` 被调用两次（`heavy`、`light`）（per-key debounce 独立计时）。
- **AC-F-4** | **GIVEN** Haptic 复合状态 = `READY` **WHEN** 调用 `Haptic.play(&"未注册的键")` **THEN** debug build 触发 `assert(false)`；release build 静默 no-op + **整个进程生命周期仅一次** `push_warning`（重复未知键不重复 warn）。可通过测试钩子读取 `_unknown_key_warned: Dictionary[StringName, bool]` 验证去重。
- **AC-F-5** | **GIVEN** Haptic 已初始化 **WHEN** 读取 `VALID_KEYS.keys()` **THEN** 包含且仅包含 Event Catalog 列出的 10 个键，无遗漏无超额；每个键映射到 5 预设字符串之一。

### 状态机切换（可自动化）

- **AC-S-1** | **GIVEN** 复合状态 = `READY` **WHEN** `Haptic.set_user_enabled(false)` **THEN** `_user_enabled = false`，复合状态 = `MUTED`，且 `Persistence.get_slice(&"settings").get(&"haptic_enabled")` = `false`。
- **AC-S-2** | **GIVEN** 复合状态 = `MUTED` **WHEN** 调用 `Haptic.play(任意键)` **THEN** `haptic_played` 信号**不**发射，backend `dispatch` 调用次数 = 0。
- **AC-S-3** | **GIVEN** 复合状态 = `READY` **WHEN** OS 发出 `application_paused` 通知 **THEN** `_lifecycle_state = BACKGROUNDED`，复合状态 = `BACKGROUNDED`。
- **AC-S-4** | **GIVEN** 复合状态 = `BACKGROUNDED` 且 `_user_enabled = true` **WHEN** OS 发出 `application_resumed` 通知 **THEN** `_lifecycle_state = FOREGROUND`，复合状态 = `READY`。
- **AC-S-4b**（"除非"分支） | **GIVEN** `_lifecycle_state = BACKGROUNDED` 期间调用 `set_user_enabled(false)`（即 `_user_enabled` 在后台被切为 false） **WHEN** OS 发出 `application_resumed` 通知 **THEN** `_lifecycle_state = FOREGROUND`，但 `_user_enabled` 仍为 false，复合状态 = `MUTED`（不回到 `READY`）。
- **AC-S-5** | **GIVEN** Haptic init 时 `_backend.detect_capability()` 返回 `UNAVAILABLE` **WHEN** 任意 `Haptic.play()` 调用 **THEN** `_capability = UNAVAILABLE` 永久（即便后续 `set_user_enabled` / lifecycle 变化都不改变它），首次调用 `push_warning` 一次，后续静默。
- **AC-S-6**（MUTED → READY） | **GIVEN** 复合状态 = `MUTED`（前台 + user_enabled=false） **WHEN** 调用 `set_user_enabled(true)` **THEN** `_user_enabled = true`，复合状态 = `READY`，下一次 `play()` 派发到 backend。
- **AC-S-7**（MUTED → BACKGROUNDED） | **GIVEN** 复合状态 = `MUTED` **WHEN** OS 发出 `application_paused` **THEN** `_lifecycle_state = BACKGROUNDED`，复合状态 = `BACKGROUNDED`，`_user_enabled` 不变。
- **AC-S-8**（BACKGROUNDED → MUTED） | **GIVEN** 复合状态 = `BACKGROUNDED` 且 `_user_enabled = true` **WHEN** 调用 `set_user_enabled(false)` **THEN** `_user_enabled = false`，复合状态 = `BACKGROUNDED`（不立即变 MUTED——lifecycle 仍 BACKGROUNDED）；OS `application_resumed` 之后 → MUTED。

### 偏好持久化（可自动化）

- **AC-P-1** | **GIVEN** 首次启动 app（settings 切片不存在） **WHEN** 读取 `haptic_enabled` 偏好 **THEN** 返回默认值 `true`，`_user_enabled = true`，复合状态 = `READY`。
- **AC-P-2** | **GIVEN** 用户调用 `set_user_enabled(false)` 后关闭 app **WHEN** 重新启动 app **THEN** `_user_enabled = false`，复合状态 = `MUTED`，`Persistence` 中 `haptic_enabled = false`。
- **AC-P-3** | **GIVEN** settings 切片 `haptic_enabled` 被外部篡改为非 bool 值 **WHEN** Haptic 启动读取 **THEN** 安全降级到默认 `true`，不抛错；`Persistence.set_slice` 错误路径（写入失败）以 `push_warning` 报告，不影响内存中 `_user_enabled` 的当前值。

### 音触同步（半自动 + 手动）

- **AC-Y-1**（可自动化） | **GIVEN** Lever Interaction 触发 `lever_lock` 同帧调用 `AudioSystem.play(&"lever_pull")`，并按 F-1 调度延迟 `AUDIO_LEAD_MS` ms 后 `Haptic.play(&"lever_lock")` **WHEN** 测试钩子记录两个发射的 `Time.get_ticks_msec()` **THEN** `|(t_audio_emit + AUDIO_PIPELINE_LATENCY_MS) − (t_haptic_emit + HAPTIC_PIPELINE_LATENCY_MS)| ≤ AUDIO_HAPTIC_PERCEPTUAL_WINDOW_MS`（即感知到达时刻差 ≤ 30 ms）。
- **AC-Y-2**（手动 - 真机，rubric 维度"节奏感"评分） | **GIVEN** 真机 iPhone XS/13/14/15 上玩家拉摇杆到锁定 **WHEN** 主观感受 **THEN** "咔嚓"音 + 硬碰撞触觉感觉为**同时**事件，rubric "节奏感"维度 ≥ 4 / 5；若 ≤ 3，回到 F-1 真机校准 `AUDIO_LEAD_MS`。

### 设备能力探测（半自动 + 手动）

- **AC-D-1**（可自动化 - 单元） | **GIVEN** GUT 测试注入 `MockHapticBackend.detect_capability() → UNAVAILABLE`（通过覆写 `HapticSystem._create_backend()`） **WHEN** Haptic `_ready()` 执行完成 **THEN** `_capability = UNAVAILABLE`，第一次 `Haptic.play(任意键)` 触发恰好一次 `push_warning`；测试钩子读取 mock backend 上的 `dispatch_call_count == 0`。
- **AC-D-2**（手动 - 真机） | **GIVEN** 真机 iPad Air 4（"iPad13,1"，无 Taptic Engine） **WHEN** 进入摇杆场景 **THEN** F-4 model whitelist 命中 false → `_capability = UNAVAILABLE`；游戏循环正常运行，无崩溃，backend `dispatch` 不被调用。
- **AC-D-2b**（手动 - 真机） | **GIVEN** 真机 iPhone 7（"iPhone9,1"，Taptic Engine 1） **WHEN** 完整核心循环 **THEN** `_capability = AVAILABLE`，所有触觉正常播放（Taptic Engine 1 与 2 在 UIImpactFeedbackGenerator 层差异不可感知）。
- **AC-D-3**（手动 - 真机） | **GIVEN** Android 编译版本 **WHEN** Haptic `_ready()` 执行 **THEN** `OS.has_feature("ios") = false` 路径，`_capability = UNAVAILABLE`，plugin Android 实现**不**被调用。

### 触觉品质（手动 — Pillar 1 真机感受）

> ⚠️ 这一组是 Pillar 1 强制验证，**自动化不可替代**。验收需要 build 装到至少 2 台真机（iPhone XS 最低支持 + iPhone 13/14/15 之一最新代），开发者本人 + 至少 1 名外部测试者完成。所有 AC-Q-* 按 `production/qa/haptic-quality-rubric.md` 5 维度量表评分；通过门槛 = 平均分 ≥ 4.0。Evidence 文件存档于 `production/qa/evidence/haptic-quality-[YYYY-MM-DD]-[device].md`。

- **AC-Q-1** | **GIVEN** 玩家拉摇杆到锁定 **WHEN** 主观感受触觉 **THEN** rubric "物理真实感"维度 ≥ 4 / 5（"金属/木头碰撞"明确，类比真实物件）；反面参考"廉价手机连续振动"自动判 1 分。
- **AC-Q-2** | **GIVEN** 粉碎过程中 `shred_pulse` 按 F-2 默认参数（offset=0.3s, interval=0.4s）触发 7 次 **WHEN** 主观感受 **THEN** rubric "节奏感" + "疲劳度" 两维度均 ≥ 4 / 5；30 秒后无不适。
- **AC-Q-3** | **GIVEN** 揭晓瞬间 `reveal_pop`（`selection` 预设）触发 **WHEN** 主观感受 **THEN** rubric "物理真实感"维度 ≥ 4 / 5（"清脆轻触，礼物盒打开"，**不是**沉重感）。
- **AC-Q-4**（多触觉可分辨性） | **GIVEN** 完整一次核心循环（30 秒摇杆 → 揭晓 → 入货架），rubric 闭眼识别测试 **WHEN** ≥ 3 名外部测试者各执行一次 **THEN** 每人 3/3 正确识别 `lever_lock`（`heavy`）/ `reveal_pop`（`selection`）/ `shelf_add`（`light`）三个节点；总通过率 ≥ 90%（9/9 中允许 1 次失败）。
- **AC-Q-5** | **GIVEN** 设备静音键开启 **WHEN** 完整核心循环 **THEN** 触觉仍完整传达节奏，rubric 5 维度均 ≥ 3 / 5，单通道反馈足以承载基本爽感。
- **AC-Q-6**（Q-1 Prototype Gate — 阻塞 Production 启动） | **GIVEN** Production Sprint 1 完成"5 预设方案" + "CoreHaptics 自定义波形草稿"对照原型 **WHEN** ≥ 3 名外部测试者按 rubric "Q-1 Prototype Gate 评分"盲测 **THEN** 5 预设方案"物理真实感"维度 ≥ 3.5 / 5 → 维持 MVP 方案，关闭 Q-1；否则启动 CoreHaptics GDExtension 工作量，本 GDD 触发再修订（影响 backend 实现路径但不影响 API 契约）。

### 性能与电耗（手动 / Profiler 辅助）

- **AC-Perf-1** | **GIVEN** `Haptic.play()` 在 60 FPS `_process` 中调用 **WHEN** Godot Profiler 测量 **THEN** 单次 `play()` 主线程时间 ≤ 0.5 ms（含 Dictionary 查找 + debounce 检查 + backend dispatch 入栈）；0.5 ms 上限来自 Godot Profiler 分辨率（~0.1 ms 是噪声底，0.5 ms 是可信测量阈）。
- **AC-Perf-2** | **GIVEN** 真机 iPhone 上分别执行：(a) idle 30 秒（无 Haptic）；(b) 30 秒核心循环（约 15 次触觉事件） **WHEN** Xcode Instruments Energy Log 测量两段电耗 **THEN** (b) 相对 (a) 增量 ≤ 1% 电池（参照 idle 基线对比；原 ≤ 0.1% 阈值低于 Energy Log 分辨率，不可测）。
- **AC-Perf-3** | **GIVEN** app `_lifecycle_state = BACKGROUNDED` **WHEN** 后台 30 秒，Xcode Instruments Haptic Engine 通道监控 **THEN** Haptic Engine 唤醒次数 = 0，backend `dispatch` 调用次数 = 0。

### 隐私（grep + 代码审查）

- **AC-Priv-1** | **GIVEN** Haptic System 代码库 **WHEN** `grep -r "Haptic" src/` **THEN** **不**出现玩家输入文本字段（如 `worry_text`、`user_input` 等）作为参数。
- **AC-Priv-2** | **GIVEN** Haptic debug 日志启用 **WHEN** 一次完整核心循环 **THEN** 日志仅包含事件键名（`lever_lock`、`shelf_add` 等），无玩家文本、无设备标识、无用户名。
- **AC-Priv-3** | **GIVEN** release build **WHEN** `grep -rE "\b(print|printerr|printraw|print_rich|debug_log)\s*\(" src/haptic/` **THEN** 所有匹配项被 `if OS.is_debug_build():` / `assert(...)` 守卫，或在 release 编译期被剥离；命中未守卫调用 → CI 阻断。

---

*Authoring note: Revised 2026-05-21 to address review BLOCKING #5 / #12 / #13 + Recommended R7 / R8 / R9 / R10. AC-S-* 重写基于三正交字段模型；AC-Q-* 引用新建 `production/qa/haptic-quality-rubric.md`；AC-D-* 引入 MockHapticBackend；AC-Priv-3 修正 grep 扩展正则。手动测试为 Pillar 1 强制要求，无 rubric evidence 不可合并到 main。*

## Open Questions

### P0 — 必须在 Production 启动前解决（**BLOCKING** Production 启动 + AC-Q-6 gate）

- **Q-1: 摇杆 3 秒触感是否需要 CoreHaptics 自定义波形？**
  - **背景**：MVP 默认用 UIImpactFeedbackGenerator 5 个预设，无法对摇杆 3 秒的拉力曲线做渐进调制（只能在关键时刻打离散冲击点）。
  - **风险**：如果 prototype 测出 5 个预设不足以承载 Pillar 1 期望的"扎实手感曲线"，需要追加 GDExtension 工作量自写 CoreHaptics 桥（社区无现成方案）。这是 Wave 1 最大单点风险。
  - **何时验证**：Production Sprint 1 开发"摇杆触觉对照原型"（5 预设方案 vs CoreHaptics 桥草稿），≥ 3 名外部测试者按 `production/qa/haptic-quality-rubric.md` 的 Q-1 Prototype Gate 评分盲测。**通过条件 = AC-Q-6**：5 预设方案 "物理真实感"维度 ≥ 3.5 / 5 平均分。
  - **解决前可继续的**：本 GDD 的 Event Catalog、三正交字段状态机、`HapticBackend` API 接口不受 Q-1 结果影响——若改 CoreHaptics 仅替换 `PluginHapticBackend` → `CoreHapticsBackend`，主类不动。
  - **Owner**：game-designer + godot-gdextension-specialist
  - **决议 deadline**：Production 启动前（**AC-Q-6 不通过则不可进 Production**）
  - **关联**：Q-7（若决议为 CoreHaptics → 影响 Audio System 是否合并接口）

- **Q-2: `kyoz/godot-haptics` plugin 真机核实**（升级自原 P1，按 review BLOCKING #6）
  - **背景**：原 GDD 在未验证情况下选择 `kyoz/godot-haptics` 作为 MVP 默认。godot-specialist 评审指出：plugin 存在性 / 版本兼容性（Godot 4.6.1） / 许可证 / GDExtension vs GDScript 包装方式 / iOS XCFramework 支持均未在真机核实。
  - **风险**：若 plugin 实际不存在或不兼容 Godot 4.6 / iOS 17+，整个 backend 实现路径需要替换（自建 GDExtension 或换 plugin）。等同 Q-1 同级风险。
  - **何时验证**：与 Q-1 prototype spike 合并执行——同一 Production Sprint 1 任务。验证产物：(a) plugin 仓库与许可证记录；(b) `kyoz/godot-haptics` 在真机 iPhone XS + iOS 18 上 `Engine.has_singleton("Haptics")` 返回 true；(c) 5 预设调用各播放一次成功。
  - **何时触发再修订**：plugin spike 完成。若不通过，启动 `extrawurst/godot-ios-impact-plugin` 或自建 GDExtension 路径，本 GDD `_create_backend()` 实现回填新 backend。
  - **Owner**：godot-specialist + godot-gdextension-specialist
  - **决议 deadline**：Production 启动前（与 Q-1 同 gate）

### P1 — 在 v1.0 前解决（不阻塞 MVP）

- **Q-3: `shred_pulse_interval_s` 与 Audio `shred_loop` BPM 是否对齐节拍？**
  - **背景**：F-2 默认 0.4 s 间隔 = 2.5 Hz。Audio System 的 `shred_loop` BGM 节奏未定（等 Audio Director 在 Wave 2 写 Juice Cookbook）。"音 + 触" 节拍若不对齐，会产生第三种节奏感（非预期）。
  - **何时回评**：Juice Cookbook 写完。本 GDD 的 `shred_pulse_interval_s` 默认值届时回填修正。
  - **Owner**：audio-director + game-designer
  - **决议 deadline**：Juice Cookbook 完成时

- **Q-4: Settings 中"触觉反馈" toggle 的视觉/交互细节**
  - **背景**：UI Requirements 仅给出概要。设备 `UNAVAILABLE` 时的灰态说明文案、toggle 切换瞬间是否播放一次 `selection` 触觉作为元反馈、辅助功能屏幕阅读器如何描述此控件——均未定。
  - **何时解决**：v1.0 Settings 屏幕设计期，`/ux-design design/ux/settings.md` 阶段。
  - **Owner**：ux-designer + accessibility-specialist
  - **决议 deadline**：v1.0 Settings UI 实现前

### P2 — 长期跟踪（v1.5+ 或政策变化触发）

- **Q-5: iOS 18+ 系统级触觉开关检测的 Apple 政策是否会松动？**
  - **背景**：当前 app 无法读取 iOS 系统设置中的"系统触感"开关状态。若 Apple 未来开放此 API，可在 UNAVAILABLE 路径中加入"系统级触觉已关"的明确提示。
  - **何时回评**：每年 WWDC 后 + iOS Major Release 后。
  - **Owner**：lead-programmer
  - **决议 deadline**：（持续追踪，无固定 deadline）

- **Q-6: Android 触觉是否值得在 v1.5+ 投资调优？**
  - **背景**：MVP 契约 = Android 免费搭车不投精力。如果项目商业表现超预期，Android 玩家比例上升，可能值得为 Android 写自定义 `VibrationEffect.createWaveform` 包装。
  - **何时回评**：v1.0 上线后 3 个月，看 Android 用户比例和留存数据。
  - **Owner**：producer + lead-programmer
  - **决议 deadline**：v1.5 规划阶段

- **Q-7: 如果 Q-1 决议为"需要 CoreHaptics 自定义波形"，是否影响 Audio System 的事件目录设计？**
  - **背景**：CoreHaptics 支持触觉与音频在 .ahap 文件中一体定义。若走这条路，Audio System 与 Haptic System 在 `lever_pull / shred_*` 等强同步事件上可能需要重新接口设计——合并为单一 "tactile event" 接口而非两个独立 play()。
  - **何时回评**：仅当 Q-1 决议为"需要 CoreHaptics"时触发。
  - **Owner**：audio-director + game-designer + creative-director
  - **决议 deadline**：CoreHaptics 路径启动前
