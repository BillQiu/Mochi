# Input System

> **Status**: Revised — pending re-review
> **Author**: game-designer (main)
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Pillar 1 (Tactile First) + Pillar 2 (Every Pull Is a Theatre)

## Overview

Input System 是 Mochi 的触摸事件路由层 —— 一个 Foundation 层服务，负责接收 iOS 和 Android 的原始 OS touch 事件，将其解析为游戏语义手势（tap、drag、long-press），并为系统 IME（输入法键盘）提供焦点桥接。它是所有玩家屏幕交互的唯一入口：摇杆拖拽、剪影点击揭晓、文字输入框激活，全部经由 Input System 路由到各自的游戏系统。该系统不拥有任何游戏逻辑 —— 它只负责将"玩家做了什么动作"传达给"需要响应该动作的系统"，使每个下游系统（Text Input、Lever Interaction、Silhouette Reveal）可以各自处理属于自己的手势，而无需相互感知对方的存在。Mochi 是纯触控游戏：无手柄支持、无悬停状态、无右键，所有交互均为单手拇指可达范围内的 touch 操作。

## Player Fantasy

Input System 是完全透明的基础设施 —— 玩家永远不会感知到它的存在。他们感受到的是摇杆在拇指下移动、剪影在点击后弹出、文字在键盘上流淌 —— 这些体验属于各自的下游系统；Input System 的贡献是让这些体验感觉**即时且自然**，不存在"手指到反馈"之间的空隙感。

这个系统是 Pillar 1（触感先行）的物质基础：振动、动画、音效要让玩家感觉是"对我的动作的真实回应"，Input System 必须以零察觉延迟传递意图。哪怕实际响应发生在 16ms 后，玩家也不应感到"我的手指和屏幕之间有一层东西"。

**成功标准**：玩家在整场游玩中，不会有一次"我的输入没有被接收到"的疑惑。

*`creative-director` 未咨询 —— Lean 模式，Section B 不触发专家派发。生产前手动复审。*

## Detailed Design

### Core Rules

1. **单例服务**：Input System 以 Autoload 单例 `InputService` 运行于 Foundation 层，在 Autoload 列表中位于 `PersistenceService` 之后（紧随其后）。完整五服务注册顺序：`PersistenceService → InputService → AudioSystem → HapticService → LifecycleService`（per ADR-0001）。它是全局的触摸手势识别器和模式控制器。

2. **三种支持手势**（互斥识别，同一触摸序列只归属一种）：
   - **tap**：触摸按下 + 移动 < 12 px + 在 300 ms 内释放 → 发出 `tap_occurred(position)`
   - **drag**：触摸按下 + 移动 ≥ 12 px → 激活 drag，发出 `drag_started`；之后每帧发出 `drag_updated(delta, total_delta)`；释放时发出 `drag_ended`
   - **long-press**：触摸按下 + 静止（移动 < 12 px）持续 ≥ 500 ms → 发出 `long_press_occurred(position)`。long-press 激活后若手指开始移动，后续移动视为 drag（发出 `drag_started` / `drag_updated` / `drag_ended`）
   - 互斥规则：移动超过 12 px 时，取消 tap 和 long-press 计时；long-press 激活后，tap 判定永久取消。

3. **单点触摸**：Mochi 不支持多点触摸（无缩放、无双指手势）。追踪第一个按下的手指；后续按下的手指被忽略（不消耗事件，允许 OS 处理）。

4. **信号发送规则**：仅在 `GESTURE_MODE` 下，`tap_occurred` / `drag_*` / `long_press_occurred` 才会发出。`TEXT_MODE` 下这些信号全部压制。`input_mode_changed` 和 `back_gesture_intercepted` 在任何模式下均可发出。

5. **事件消耗策略**：当 Input System 识别出完整手势后，调用 `get_viewport().set_input_as_handled()` 消耗原始 `InputEventScreenTouch` / `InputEventScreenDrag`，防止 Godot UI 节点（ScrollContainer 等）误响应。TEXT_MODE 下 touch 事件**不消耗**，传递给 OS 原生路径（让键盘外点击收起 IME）。

6. **IME 焦点桥接**：Input System 本身不调用 `LineEdit.grab_focus()` / `release_focus()`。TextInput System 负责调用，并在之后通知 Input System 模式切换（`request_text_mode()` / `release_text_mode()`）。Input System 是被动的模式状态机。

7. **应用后台中断**：当 `NOTIFICATION_APPLICATION_PAUSED` 触发时，Input System 强制取消所有进行中的手势（若 drag 进行中，发出 `drag_ended` 并清空追踪状态；若 long-press 计时中，取消计时）。**InputService 不订阅 `NOTIFICATION_APPLICATION_RESUMED`**，不自动重置模式。前台恢复由 LifecycleService 驱动：LifecycleService 在发出 `app_resumed` 信号之前主动调用 `InputService.release_text_mode()`（per Lifecycle Core Rule 6），将 InputService 重置为 `GESTURE_MODE`；若应用恢复后 IME 仍需保持，TextInput System 再重新调用 `request_text_mode()`。

8. **系统返回手势处理**：拦截 `NOTIFICATION_WM_GO_BACK_REQUEST`（含 Android 13+ 的 `NOTIFICATION_WM_CLOSE_REQUEST`）。
   - 若当前 `TEXT_MODE` 且 `_has_pending_text == true` → 发出 `back_gesture_intercepted` 信号，**不传递给 OS**。TextInput System 订阅此信号，弹出确认对话框。
   - 其他情况 → 不拦截，传递给 OS。

9. **API 接口**：

```gdscript
class_name InputService extends Node

enum InputMode { GESTURE_MODE, TEXT_MODE }

signal tap_occurred(position: Vector2)
signal drag_started(position: Vector2)
signal drag_updated(delta: Vector2, total_delta: Vector2)
signal drag_ended(position: Vector2, total_delta: Vector2)
signal long_press_occurred(position: Vector2)
signal input_mode_changed(mode: InputMode)
signal back_gesture_intercepted()

func is_ready() -> bool               # ADR-0001 Foundation 就绪接口；_ready() 完成后始终返回 true
func request_text_mode() -> void      # 合法调用方：TextInput System（IME 将弹出时）
func release_text_mode() -> void      # 合法调用方：TextInput System（IME 已收起时）+ LifecycleService（前台恢复时，per Core Rule 7）
func set_has_pending_text(has: bool) -> void  # TextInput 系统同步未提交文字状态
func current_mode() -> InputMode
```

### States and Transitions

| 状态 | 进入条件 | 退出条件 | 行为 |
|------|----------|----------|------|
| `GESTURE_MODE` | Autoload `_ready()` 完成；或 `release_text_mode()` 调用 | `request_text_mode()` 调用 | 正常识别并发出 tap / drag / long-press 信号；不拦截系统返回（无未提交文字时） |
| `TEXT_MODE` | `request_text_mode()` 调用 | `release_text_mode()` 调用 | 压制游戏信号；touch 事件传递给 OS；系统返回 + 有未提交文字时发出 `back_gesture_intercepted` |

**进行中手势的中断规则**：

| 触发 | 结果 |
|------|------|
| `request_text_mode()` 在 drag 进行中调用 | 发出 `drag_ended(current_pos, total_delta)` 并切换到 TEXT_MODE |
| `NOTIFICATION_APPLICATION_PAUSED` 在 drag 进行中 | 同上，然后清空追踪状态 |
| 第二根手指按下（多点触摸） | 忽略新手指；当前手势继续 |

### Interactions with Other Systems

| 系统 | 方向 | Input System 提供 | Input System 期望 |
|------|------|-------------------|-------------------|
| **Text Input** | 双向 | 接收 `request_text_mode()` / `release_text_mode()` / `set_has_pending_text()`；发出 `back_gesture_intercepted`（TextInput 订阅） | TextInput 在 IME 生命周期中正确调用模式切换 |
| **Lever Interaction** | Input → Lever | `drag_started`, `drag_updated`, `drag_ended` 信号 | 无 |
| **Silhouette Reveal** | Input → Silhouette | `tap_occurred` 信号 | 无 |
| **Accessibility System** | Accessibility → Input | 未来可能请求调整 touch 目标尺寸；MVP 无接口 | `tap_occurred`（v1.0 无障碍层可订阅） |
| **Mobile App Lifecycle** | Lifecycle → Input（单向） | Input System 直接订阅 `NOTIFICATION_APPLICATION_PAUSED`，不通过 Lifecycle 中间层。但 LifecycleService 在前台恢复时主动调用 `InputService.release_text_mode()`（per Lifecycle Core Rule 6） | `release_text_mode()` 必须幂等（当前已是 GESTURE_MODE 时无操作） |

> ⚠️ **Provisional Contract**：Lever、Silhouette、Text Input 的 GDD 尚未编写。当设计时，它们必须引用本 GDD 中定义的信号名称和参数格式。任何偏差通过 `/consistency-check` 标记。

*专家代理未咨询 —— Lean 模式，Section C 不触发专家派发。生产前由 `systems-designer` + `gameplay-programmer` 手动复审。*

## Formulas

### Formula 1 — 手势分类谓词

给定一个触摸序列，gesture_type 按以下优先顺序确定：

```
gesture_type = classify(touch_sequence)

在手指按下时开始追踪：
  start_pos    = 初始触摸位置 (Vector2)
  start_time   = 触摸开始时间 (ms)
  gesture_state = PENDING

每帧（或每次 touch_moved 事件）：
  delta_from_start = distance(current_pos, start_pos)

  IF gesture_state == PENDING AND delta_from_start >= TAP_DRAG_THRESHOLD_PX:
    gesture_state = DRAGGING
    emit drag_started(start_pos)

  IF gesture_state == DRAGGING:
    emit drag_updated(frame_delta, total_delta)

  IF gesture_state == PENDING AND (now - start_time) >= LONG_PRESS_THRESHOLD_MS:
    gesture_state = LONG_PRESSING
    emit long_press_occurred(start_pos)
    # 若手指之后移动 >= TAP_DRAG_THRESHOLD_PX → 转为 DRAGGING（drag_started 从当前帧起）

手指抬起时：
  PENDING   → emit tap_occurred(start_pos)
  LONG_PRESSING → 无额外 emit（long_press 已发出；未发生 drag）
  DRAGGING  → emit drag_ended(current_pos, total_delta_from_start)
```

**变量**：

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| `TAP_DRAG_THRESHOLD_PX` | d_tap | int | 8–24 | tap 与 drag 的切换距离（单位：逻辑像素） |
| `LONG_PRESS_THRESHOLD_MS` | t_lp | int | 400–700 | long-press 激活等待时长（ms） |
| `delta_from_start` | d | float | 0–∞ | 当前帧触摸点与初始触摸点的距离（px） |
| `total_delta` | Δ_total | Vector2 | — | 当前帧触摸点相对于 `start_pos` 的位移向量 |

**默认值**（标准移动端阈值）：`TAP_DRAG_THRESHOLD_PX = 12`，`LONG_PRESS_THRESHOLD_MS = 500`

**输出**：gesture_type ∈ { tap, drag, long_press }，每个触摸序列恰好归属一种。

**示例（正常路径）**：
- 玩家按下摇杆区域，0.3s 内移动 20px → delta_from_start(20) ≥ 12 → DRAGGING，`drag_started` 发出
- 玩家按下空白区域静止 500ms → `long_press_occurred` 发出
- 玩家轻触剪影 150ms 后抬起，移动 3px → `tap_occurred` 发出

---

### Formula 2 — 最小触摸目标尺寸推荐值

```
min_touch_target_px = LOGICAL_TOUCH_TARGET_PT × SCREEN_SCALE_FACTOR
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| `LOGICAL_TOUCH_TARGET_PT` | t_pt | int | 常量 **44** | iOS HIG 推荐最小触摸目标（points）；WCAG 2.5.5 Level AAA 同值 |
| `SCREEN_SCALE_FACTOR` | s | float | 1.0 – 3.0 | 设备屏幕像素密度倍率（iPhone SE 2x，Pro Max 3x） |

**输出范围**：44px（1x）→ 88px（2x）→ 132px（3x）

**在 Godot 中的实践**：以 2x Retina（iPhone SE）为设计基准，触摸目标逻辑尺寸 ≥ 88px（设计分辨率坐标系）。剪影、按钮、摇杆等所有可交互元素的点击区域（含不可见扩展区域）必须满足此下限。此值不是游戏设计可调参数——它是无障碍基准线，由 Accessibility System（v1.0）强制审查。

## Edge Cases

### A. 手势识别边界

- **若触摸在 `TAP_DRAG_THRESHOLD_PX`（12px）内且持续时长 > `LONG_PRESS_THRESHOLD_MS`（500ms）后释放**：long-press 已在 500ms 时发出，释放时不再发出 tap。玩家看到 long-press 效果（若有），无第二次事件。

- **若 long-press 激活后手指开始移动超过 12px**：从该帧起 `gesture_state` 切换为 DRAGGING，发出 `drag_started(current_pos)`（start_pos 使用发生移动时的当前位置，不是原始按下位置——long-press 的 start_pos 已被消耗）。

- **若玩家快速连击（< 100ms 间隔的多次 tap）**：每次 tap 独立追踪，每次发出 `tap_occurred`。Input System 不做 double-tap 识别（MVP 无 double-tap 交互）。

- **若 OS 中断取消了 touch_up 事件**（系统弹窗、来电等）：Input System 通过 `NOTIFICATION_APPLICATION_PAUSED` 强制清理追踪状态（发出 `drag_ended` 或取消 long-press 计时）。若无 PAUSED 通知（极罕见的 OS 行为差异），追踪状态在下次 touch_down 时重置。

### B. 模式切换边界

- **若 `request_text_mode()` 在 drag 进行中被调用**：立即发出 `drag_ended(current_pos, total_delta)` 关闭当前 drag 序列，再切换到 TEXT_MODE。Lever Interaction System 收到 `drag_ended` 后执行 spring-back 动画，如同正常释放。

- **若 `request_text_mode()` 在 long-press 计时中被调用**：取消计时器，不发出 `long_press_occurred`，直接切换到 TEXT_MODE。

- **若 `release_text_mode()` 被重复调用（当前已是 GESTURE_MODE）**：无操作，不重复发出 `input_mode_changed`。

- **若 `request_text_mode()` 被重复调用（当前已是 TEXT_MODE）**：无操作，幂等。

### C. 系统返回手势边界

- **若系统返回手势触发时正在进行 drag**：先发出 `drag_ended`（终止 drag），再评估是否拦截返回。评估顺序固定：手势清理在前，返回处理在后。

- **若 Android 13+ predictive back 手势启动但用户取消（未完成返回动作）**：Android 系统在用户取消时不发出 `NOTIFICATION_WM_GO_BACK_REQUEST`，Input System 不收到通知，无动作。若系统错误发出通知后又取消，TextInput 的确认弹窗已弹出，用户手动取消即可，不造成数据丢失。

- **若返回手势触发时 `_has_pending_text == false`（TextInput 内容为空或已提交）**：不拦截，传递给 OS 正常处理（收起 IME 或退出 App）。

### D. 应用生命周期边界

- **若应用进入后台时处于 TEXT_MODE**：Input System 不自动切换回 GESTURE_MODE。应用恢复前台后，若 IME 已被 OS 收起，TextInput System 须调用 `release_text_mode()`；若 IME 仍开放，维持 TEXT_MODE。Input System 不主动轮询 IME 状态。

- **若应用进入后台时处于 `LONG_PRESSING` 状态**（long-press 已激活，`long_press_occurred` 已发出，手指仍按住）：与 drag 中断对称处理 —— 不发出任何额外信号（`long_press_occurred` 已在计时触发时发出，不重复；无 `drag_ended`，因 drag 从未开始），清空内部追踪状态。后续新 touch_down 可正常开始新手势序列。与 Core Rule 7 中"若 long-press 计时中 → 取消计时"的 `PENDING` 分支正交：本规则覆盖 long-press 已激活进入 `LONG_PRESSING` 后的中断路径。

- **若第二根手指在 drag 进行中按下**：忽略第二根手指的事件（不消耗）；第一根手指追踪的 drag 继续。摇杆拖拽期间双指缩放 → 缩放被忽略（符合"无缩放"设计约束）。

## Dependencies

### 上游 — 本系统依赖

**无上游依赖。** Input System 是 Foundation 层。它仅订阅 Godot OS 原生通知（`NOTIFICATION_APPLICATION_PAUSED`、`NOTIFICATION_WM_GO_BACK_REQUEST`、`NOTIFICATION_WM_CLOSE_REQUEST`），不依赖任何其他游戏系统。可在其他系统存在之前独立实现和测试。

### 下游 — 依赖本系统

| 系统 | 方向 | 强度 | 接口 |
|------|------|------|------|
| **Text Input System** (#7) | Text Input → Input | **硬依赖** — 没有 IME 模式切换接口，文字输入期间手势会误触发 | `request_text_mode()` / `release_text_mode()` / `set_has_pending_text()` / `back_gesture_intercepted` 信号 |
| **Lever Interaction System** (#8) | Input → Lever | **硬依赖** — 摇杆拖拽的全部物理输入来自 Input | `drag_started` / `drag_updated` / `drag_ended` 信号 |
| **Silhouette Reveal System** (#11) | Input → Silhouette | **硬依赖** — 剪影揭晓由 tap 事件触发 | `tap_occurred` 信号 |
| **Accessibility System** (#16, v1.0) | Accessibility → Input | **软依赖** — Accessibility 在 v1.0 阶段审查触摸目标尺寸合规性；MVP 无接口 | `tap_occurred`（可订阅，v1.0 审查用） |

### 跨切面

| 系统 | 关系 |
|------|------|
| **Mobile App Lifecycle** (#5) | 单向依赖：Lifecycle → Input。Input System 直接订阅 OS 通知（`NOTIFICATION_APPLICATION_PAUSED`），不通过 Lifecycle 中间层。但 LifecycleService 在前台恢复时调用 `InputService.release_text_mode()`（per Lifecycle Core Rule 6），因此 Lifecycle 单向依赖 Input 的 `release_text_mode()` 接口。 |

### 双向一致性——待确认项

以上 3 个硬依赖 GDD 尚未编写。当设计时，每个 GDD 必须在其 Dependencies 节列出"depends on Input System"并引用所用信号名。`/consistency-check` 验证此双向性。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|----------|----------|
| `TAP_DRAG_THRESHOLD_PX` | **12** | 8–24 | 更大的"死区"——手指轻微抖动不触发 drag，更有利于稳定 tap 检测；但摇杆拖拽反应感觉迟钝 | 更灵敏的 drag 起始——但容易把轻触误判为 drag，tap 识别率下降 |
| `LONG_PRESS_THRESHOLD_MS` | **500** | 400–700 | long-press 更难触发，减少误激活；摇杆长按待机场景感觉更好 | long-press 更容易触发——对于长按后移动启动摇杆的玩法，可能在玩家开始 drag 前就先意外触发 long-press |

### Juice 关联（携带约束，来自系统索引）

Input System 本身无视觉/音频输出，不直接驱动 Juice。但它的信号是所有下游 Juice 事件的触发源：`drag_started` 触发摇杆开始动画，`tap_occurred` 触发剪影弹出，`drag_ended` 触发 spring-back。Juice Cookbook（Wave 2）定义这些信号应触发的具体 Juice 效果——Input System 不做 Juice 实现，但其信号精度（起始位置、delta 向量精度）直接影响 Juice 动画的视觉质量。

### 明确不是旋钮

- **支持的手势类型集合**（tap / drag / long-press）—— 修改需要改代码，不是设计调节
- **输入模式状态机**（GESTURE_MODE / TEXT_MODE）—— 架构性逻辑，不可配置
- **最小触摸目标尺寸（88px）**—— 无障碍基准线，由 iOS HIG 规定；修改需要专项无障碍审查
- **信号名称和参数格式**—— 是下游 3 个系统的接口契约；修改需要同步更新所有订阅方，不能单独调

## Visual/Audio Requirements

Input System 是纯基础设施，无视觉或音频输出。它通过信号通知下游系统，由下游系统（Lever Interaction、Silhouette Reveal、Juice Cookbook）负责对应的视觉和音频响应。

Input System 本身不播放音效、不触发动画、不产生粒子效果。

## UI Requirements

Input System 无专属 UI。它是路由层，不渲染任何界面元素。

**最小触摸目标尺寸约束**（衍生自 Formula 2）：所有接收 `tap_occurred` 信号的可交互 UI 节点（剪影、按钮等），其实际可点击区域（含不可见热区扩展）必须 ≥ 88px（2x Retina 基准下的逻辑像素）。此约束由各 UI 节点的所属系统（Silhouette Reveal、Scene Composition 等）在实现时自行保证；Accessibility System（v1.0）在审查阶段验证合规性。

## Acceptance Criteria

> 格式：GIVEN-WHEN-THEN。每条可由 QA 测试员独立验证，无需阅读本 GDD。
> *`qa-lead` 未咨询 —— Lean 模式 + 低实现风险。生产前手动复审。*

### 功能 — 手势识别

1. **GIVEN** 玩家按下屏幕后在 150ms 内释放，移动距离 < 12px，**WHEN** touch 序列完成，**THEN** `tap_occurred(position)` 发出一次，`drag_started` / `long_press_occurred` 均不发出。

2. **GIVEN** 玩家按下屏幕后移动 20px（超过 12px 阈值），**WHEN** 移动超过阈值的帧，**THEN** `drag_started(start_pos)` 发出；之后每帧发出 `drag_updated`；手指释放时发出 `drag_ended(release_pos, total_delta)`；全程 `tap_occurred` 不发出。

3. **GIVEN** 玩家按下屏幕后保持静止（移动 < 12px）超过 500ms，**WHEN** 500ms 计时触发，**THEN** `long_press_occurred(start_pos)` 发出，且在此之前 `tap_occurred` 和 `drag_started` 均未发出。

4. **GIVEN** long-press 已激活（500ms 静止），玩家随后移动手指 20px，**WHEN** 移动超过 12px 阈值，**THEN** `drag_started` 从移动发生帧开始发出（使用当前位置而非原始按下位置），之后正常发出 `drag_updated` / `drag_ended`。

5. **GIVEN** 玩家快速连续点击屏幕同一区域（间隔 < 100ms），**WHEN** 每次点击完成，**THEN** 每次 tap 各自独立发出 `tap_occurred`，无合并或 double-tap 识别。

6. **GIVEN** 玩家先按下第一根手指（drag 中），再按下第二根手指，**WHEN** 第二根手指按下，**THEN** 第一根手指的 drag 序列继续不中断；第二根手指的 InputEvent 不被消耗（传递给 OS）。

### 功能 — 模式切换

7. **GIVEN** InputService 处于 `GESTURE_MODE`，**WHEN** `request_text_mode()` 被调用，**THEN** (a) `current_mode()` 返回 `TEXT_MODE`；(b) `input_mode_changed(TEXT_MODE)` 发出；(c) 之后的 touch 事件不触发 `tap_occurred` / `drag_*` / `long_press_occurred` 信号。

8. **GIVEN** InputService 处于 `TEXT_MODE`，**WHEN** `release_text_mode()` 被调用，**THEN** (a) `current_mode()` 返回 `GESTURE_MODE`；(b) `input_mode_changed(GESTURE_MODE)` 发出；(c) 之后的 touch 事件正常触发手势信号。

9. **GIVEN** InputService 处于 `GESTURE_MODE` 且 drag 正在进行，**WHEN** `request_text_mode()` 被调用，**THEN** `drag_ended` 先于 `input_mode_changed` 发出；`drag_ended` 包含调用时刻的 current_pos 和 total_delta。

10. **GIVEN** InputService 处于 `GESTURE_MODE`，**WHEN** `release_text_mode()` 被重复调用，**THEN** `input_mode_changed` **不**发出（幂等）。

### 功能 — 系统返回手势

11. **GIVEN** InputService 处于 `TEXT_MODE` 且 `_has_pending_text == true`，**WHEN** `NOTIFICATION_WM_GO_BACK_REQUEST` 触发，**THEN** `back_gesture_intercepted` 发出；应用**不**退出或关闭 IME。

12. **GIVEN** InputService 处于 `TEXT_MODE` 且 `_has_pending_text == false`，**WHEN** `NOTIFICATION_WM_GO_BACK_REQUEST` 触发，**THEN** `back_gesture_intercepted` **不**发出；事件传递给 OS 正常处理。

13. **GIVEN** InputService 处于 `GESTURE_MODE`，**WHEN** `NOTIFICATION_WM_GO_BACK_REQUEST` 触发，**THEN** `back_gesture_intercepted` **不**发出（无论 `_has_pending_text` 状态）。

### 功能 — 生命周期

14. **GIVEN** drag 正在进行（已发出 `drag_started`），**WHEN** `NOTIFICATION_APPLICATION_PAUSED` 触发，**THEN** `drag_ended` 发出，内部追踪状态清空，后续新 touch_down 可正常开始新手势序列。

14b. **GIVEN** long-press 计时中（已按下静止，500ms 计时尚未触发），**WHEN** `NOTIFICATION_APPLICATION_PAUSED` 触发，**THEN** long-press 计时取消，`long_press_occurred` **不**发出；内部追踪状态清空，后续新 touch_down 可正常开始新手势序列。

14c. **GIVEN** long-press 已激活（`gesture_state == LONG_PRESSING`，`long_press_occurred` 已发出，手指仍按住未移动），**WHEN** `NOTIFICATION_APPLICATION_PAUSED` 触发，**THEN** **不**发出任何额外信号（不重复 `long_press_occurred`，无 `drag_ended`，无 `drag_started`）；内部追踪状态清空（`gesture_state` 重置为 PENDING），后续新 touch_down 可正常开始新手势序列。与 AC-14b 互补：14b 覆盖 PENDING（计时中）路径，14c 覆盖 LONG_PRESSING（计时已触发）路径。

### 性能

15. `[BLOCKED-HARDWARE]` **GIVEN** 一个标准的 tap 手势（touch_down → touch_up 在 2 帧内），**WHEN** 在 iPhone SE 2nd gen 上测量从 `InputEventScreenTouch` 到 `tap_occurred` 的信号发出时延，**THEN** 时延 ≤ **16ms**（单帧内完成）。

16. **GIVEN** `drag_updated` 在 60fps 下每帧发出，**WHEN** 连续拖拽 10 秒（600 次 drag_updated），**THEN** 无 GDScript 堆内存持续增长（通过 `OS.get_static_memory_usage()` 前后对比验证，增量 < 512 KB）。

### 架构 — 代码验证

17. **GIVEN** InputService 源文件，**WHEN** CI 扫描其 import / 依赖列表，**THEN** 零对 Foundation 层外模块的 `preload` / `load` / `class_name` 引用（零上游依赖强制）。

18. **GIVEN** InputService 源文件，**WHEN** CI grep 扫描 `TAP_DRAG_THRESHOLD_PX`、`LONG_PRESS_THRESHOLD_MS` 的裸字面量（`12`、`500`），**THEN** 零匹配——所有阈值必须以 `UPPER_SNAKE_CASE` 具名常量定义（MVP 要求，零魔术数字）。v1.0 可将常量迁移至外部 `.tres` 配置资源；MVP 阶段代码级 const 即可通过此 AC。

## Open Questions

| 问题 | 负责人 | 截止时机 | 备注 |
|------|--------|----------|------|
| **iOS 边缘滑动返回 vs. 摇杆拖拽冲突**：iOS 左边缘右滑是系统手势（UIKit 返回），与摇杆从左向右拖拽路径重叠。Godot 4.6 是否透明传递还是拦截此手势？ | godot-specialist | Wave 4（Lever GDD 设计前）| 若 Godot 不拦截，摇杆起始区需避开边缘约 20px 的 iOS 手势识别区 |
| **`NOTIFICATION_WM_GO_BACK_REQUEST` 在 Android 13+ predictive back 中的行为**：Persistence GDD 已记录此疑问（Edge Case D）。Input System 同样依赖此通知拦截返回手势。真机测试 Godot 4.6 在 Android 13+ 设备上的实际映射行为。 | godot-specialist | 首次 Android 设备构建前 | 本系统与 Persistence 均订阅 `NOTIFICATION_WM_CLOSE_REQUEST` 作为防御措施 |
| ✅ **long-press 的 MVP 实现策略**（已决议，2026-05-22） | — | — | **决议：完整实现 long-press**（含 AC 3/4）。成本极低（一个计时器），避免 Wave 4+ 改接口。AC 3（long-press 触发）和 AC 4（long-press 后转 drag）均为 MVP 必须通过的验收项。 |
| ✅ **前台恢复后 IME 状态同步**（已解决，2026-05-22） | — | — | **由 Lifecycle Core Rule 6 解决**：LifecycleService 在发出 `app_resumed` 前主动调用 `InputService.release_text_mode()`，无需 TextInput 轮询 IME 状态。TextInput 若需维持 TEXT_MODE，在 `app_resumed` 信号后重新调用 `request_text_mode()` 即可。 |
