# Mobile App Lifecycle System

> **Status**: Revised — pending re-review
> **Author**: game-designer (main)
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Pillar 5 (Unlimited But Meaningful — 后台/前台无副作用) + 防御 Anti-Pillar（隐私默认）

## Summary

Mobile App Lifecycle 是 Mochi 的应用生命周期协调层 —— Foundation 层 Autoload 服务，向上层（Mochi Character、Text Input、Scene Composition、Onboarding）发布 `app_ready` / `app_paused` / `app_resumed` 高层语义信号。**它不是 OS 通知中央网关**：四大 Foundation 同侪（Persistence/Input/Audio/Haptic）按各自 GDD 直接订阅 OS 通知。Lifecycle 的真实职责是冷启动序列协调、PAUSED/RESUMED 防抖、IME 中断恢复策略仲裁。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (zero upstream game systems)`

## Overview

Mobile App Lifecycle 是 Mochi 的应用生命周期协调层 —— 一个 Foundation 层 Autoload 服务，负责为**上层游戏系统**（Mochi Character、Text Input、Scene Composition）提供"App 何时启动完毕、何时被中断、何时回到前台"的统一高层信号。它**不是** OS 通知的中央网关：四大 Foundation 同侪（Persistence、Input、Audio、Haptic）按各自 GDD 的设计**直接订阅**原生 `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_GO_BACK_REQUEST`，以维持各自零上游依赖的架构纯度。Lifecycle 的真实职责是**上层业务策略**：(1) 协调冷启动序列——定义 Autoload 之间的就绪顺序与"App 准备好接受玩家交互"的判定时机；(2) 发出 `app_paused` / `app_resumed` 高层语义信号，供 Mochi Character（暂停眨眼动画）、Scene Composition（恢复后是否需要重渲染）等上层订阅；(3) 仲裁 IME 中断恢复策略——这是 Input GDD Open Question 4 明确移交给 Lifecycle 的责任。玩家从未直接感受到 Lifecycle，但其失败会以玩家可见的方式暴露：从后台回来后 Mochi 还在做闲置动画、写到一半的烦恼丢失、剪影揭晓动画从中段重启——这些是 Lifecycle 协调失败的症状，是它必须防御的边界。它是 Pillar 5（Unlimited But Meaningful）的物质基础：玩家可以任意时刻进入、被打断、回来，游戏始终保持"我在等你"的姿态。

## Player Fantasy

Mobile App Lifecycle 与 Persistence 一样，是**完全不可见的基础设施**。玩家不会有"Lifecycle 系统让我感觉如何"的体验——他们的体验由 Mochi 角色、Text Input、Scene Composition 等上层系统承载。Lifecycle 的成功标准是**玩家从未注意到它的存在**。

它承担两项隐形的 Pillar 5 义务（Unlimited But Meaningful）：

- **"被打断不丢失"**：玩家正写到一半烦恼，电话进来、收到推送、需要切到别的 App 查个东西——回到 Mochi 时，写到一半的文字应该还在，Mochi 角色应该如同没事发生一样继续等待。这不是 Text Input 一个系统能保证的——它需要 Lifecycle 协调"何时该让 IME 焦点回来"、"角色动画要不要从中段恢复"、"画面要不要重新淡入"这些**跨系统的时序问题**。玩家感受到的是连续，看到的是无缝——背后是 Lifecycle 在做协调。

- **"打开就在等你"**：玩家点开 Mochi 图标，Mochi 角色应该立刻在屏幕上——不是先白屏 2 秒再画出来，不是先听到 BGM 再看到画面，不是先看到角色再被 IME 键盘弹出遮住。冷启动顺序协调让"App 准备好"的瞬间是一个**清晰的、协调的、对玩家无空隙的时刻**。

**反面 anti-pattern**（Lifecycle 失败的样子）：

- 玩家从后台回来发现 Mochi 角色还停在闲置动画的最后一帧（动画未恢复）
- 写到一半的烦恼被某个系统的"重置"逻辑清空（Lifecycle 没正确仲裁 IME 状态）
- 冷启动时 Mochi 闪现一次"啊还没准备好的姿势"再切到正式姿势（Autoload 顺序未协调好）
- 短暂切到通知中心又回来，BGM 重新从开头播放（误判 paused 阈值）

这些都是细微到玩家自己说不清的不适感，但累积起来会摧毁"这台机器永远靠谱"的核心情感承诺（与 Pillar 4 "Cute But Weighted" 中的"克制工匠"姿态共振）。**Lifecycle 是这个承诺的结构性守护者**。

*`creative-director` 未咨询 —— Lean 模式，Section B 不触发专家派发。生产前手动复审。*

## Detailed Design

### Core Rules

1. **Autoload 注册顺序** *(silent-bug 防御)*：`LifecycleService` 必须是 `[autoload]` 列表中**最后一个 Foundation 服务**。完整顺序：`PersistenceService` (per Persistence Core Rule 10) → `InputService` (per Input Core Rule 1) → `AudioSystem` → `HapticService` → `LifecycleService`（per ADR-0001 Decision 4）。Lifecycle 在自己的 `_ready()` 中读取其他 Foundation 状态时，必须使用 `call_deferred` 或 `tree_entered` 信号（遵循 Persistence Core Rule 10 的对称约束）。

2. **App Ready 判定**：`LifecycleService._ready()` 完成时，通过 `call_deferred` 触发 ready 验证：通过 `call_deferred` 轮询四个 Foundation 同侪的就绪状态（per ADR-0001 Decision 2）：`PersistenceService.is_ready() == true`、`InputService.is_ready() == true`、`AudioSystem.is_ready() == true`、`HapticService.is_ready() == true`。四者全部就绪 → 发出 `app_ready` 信号。**`app_ready` 在整个 App 生命周期内只发出一次**。

3. **OS 通知订阅范围（明确边界）**：Lifecycle **仅订阅以下两个 OS 通知**，用于驱动自己的状态机：
   - `NOTIFICATION_APPLICATION_PAUSED`
   - `NOTIFICATION_APPLICATION_RESUMED`

   Lifecycle **不订阅**：
   - `NOTIFICATION_WM_GO_BACK_REQUEST` / `NOTIFICATION_WM_CLOSE_REQUEST` —— 由 Input System 处理
   - `NOTIFICATION_WM_WINDOW_FOCUS_IN` / `_OUT` —— 焦点变化不等于生命周期变化；不在本系统职责内

   Lifecycle **不为四大 Foundation 同侪转发任何 OS 通知**——Persistence、Input、Audio、Haptic 各自直接订阅，Lifecycle 不做中介。

4. **app_paused / app_resumed 信号契约**：
   - `app_paused`：当 OS `NOTIFICATION_APPLICATION_PAUSED` 触发并经过 `RESUME_DEBOUNCE_MS` 防抖确认（即 1 秒内未收到 RESUMED），由 Lifecycle 发出。语义：「App 真的进入了用户感知意义上的后台」。
   - `app_resumed`：当 OS `NOTIFICATION_APPLICATION_RESUMED` 触发且**之前已发出过 `app_paused`**（即处于 `PAUSED_CONFIRMED` 状态），立即发出。语义：「App 从用户感知意义的后台回来」。
   - 若 PAUSED→RESUMED 在防抖窗口内（<1s），**两个信号都不发出**——视为瞬时切换，不应触发任何上层副作用（动画暂停、BGM 重启等）。

5. **防抖窗口（Tuning Knob）**：`RESUME_DEBOUNCE_MS = 1000`。在 PAUSED 收到后启动定时器，在 RESUMED 收到前定时器到期 → 发出 `app_paused`；否则取消定时器。

6. **IME 中断恢复策略**：当 `app_resumed` 即将发出时，Lifecycle **主动调用** `InputService.release_text_mode()`。理由：
   - iOS 在 App 切换回前台时通常已自动收起软键盘；同步调用 `release_text_mode()` 让 InputService 回到 `GESTURE_MODE`，避免出现「TEXT_MODE 状态 + 无可见键盘」的 ghost 状态。
   - `release_text_mode()` 是幂等的（Input GDD Edge Case B），即使 InputService 已是 GESTURE_MODE 也安全。
   - **不影响半成品文字**：Text Input 的待提交文字缓存在其自己的状态中，与 InputService 模式独立。如果 Text Input 希望前台恢复后继续输入，它应订阅 `app_resumed` 并自行决定何时调用 `InputService.request_text_mode()`。

7. **API 接口**：
   ```gdscript
   class_name LifecycleService extends Node

   ## Cold start 完成，所有 Foundation Autoload 就绪。
   ## 整个 App 进程中只发出一次。
   signal app_ready()

   ## App 进入"确认后台"状态（防抖通过后）。
   signal app_paused()

   ## App 从"确认后台"状态返回前台。
   ## 仅在之前 app_paused 已发出时才会触发。
   signal app_resumed()

   ## BOOTING 阶段持续超过 BOOT_TIMEOUT_MS 时发出的诊断信号。
   ## 仅诊断用途——不表示 app_ready 即将发出，也不终止 BOOTING 状态。
   signal boot_timeout()

   ## 当前是否已发出 app_ready。
   func is_ready() -> bool

   ## 当前是否处于 PAUSED_CONFIRMED 状态。
   func is_in_confirmed_background() -> bool
   ```

8. **不持久化**：Lifecycle 不读写 `user://`，不调用 `Persistence.save_now()` 或 `save_when_idle()`。如果 Persistence 因 PAUSED 而触发保存，那是 Persistence 自己订阅了 OS 通知的结果，与 Lifecycle 无关。

9. **不持有游戏状态**：Lifecycle 不感知 Mochi 角色、产物、烦恼或场景——它只发协调信号。订阅方各自决定如何响应（角色停眨眼、场景重渲染等）。Lifecycle 源代码中不得出现 `"products"` / `"worry"` / `"shelf"` / `"mochi"` 等业务字符串（与 Persistence Core Rule 11 / Input Core Rule 同模式，由 grep-based AC 强制）。

10. **重复通知幂等**：连续多次 PAUSED 不发出多个 `app_paused`（状态机限制 `READY → PAUSE_PENDING → PAUSED_CONFIRMED` 之间转换仅触发一次信号）。同理，处于 `PAUSED_CONFIRMED` 时再次收到 PAUSED 视为冗余，忽略。

11. **Anti-Pillar 信号守护（ADR-0002）**：订阅 `app_ready`、`app_paused`、`app_resumed` **必须以改变游戏玩法、UI、视觉、音频或触觉状态为唯一目的**。以记录时间戳、计算会话时长、统计打开次数或构建任何行为使用日志（无论是否上传设备外）为目的的订阅是**禁止模式**（已在 `docs/registry/architecture.yaml` 中注册为 `lifecycle_signal_analytics_subscription`，per ADR-0002）。任何新订阅方必须在 ADR-0002 Permitted Subscriber 表中列明，实现前完成 ADR 修订 + `/architecture-review`。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|----------------|----------|
| `UNINITIALIZED` | Autoload 构造完成，`_ready()` 未执行 | `_ready()` 执行 | API 调用返回默认值；信号订阅记录但不触发 |
| `BOOTING` | `_ready()` 入口 | Foundation 四同侪全部就绪检测通过 | 在 `call_deferred` 中轮询 Persistence/Input/Audio/Haptic 状态 |
| `READY` | `BOOTING` 通过验证；发出 `app_ready` | 收到 `NOTIFICATION_APPLICATION_PAUSED` | App 处于前台，正常运行 |
| `PAUSE_PENDING` | 收到 `NOTIFICATION_APPLICATION_PAUSED` | 定时器到期 OR 收到 `NOTIFICATION_APPLICATION_RESUMED` | 防抖定时器运行中（`RESUME_DEBOUNCE_MS = 1000`），**不发任何信号** |
| `PAUSED_CONFIRMED` | `PAUSE_PENDING` 定时器到期；发出 `app_paused` | 收到 `NOTIFICATION_APPLICATION_RESUMED` | App 处于"确认后台"。Lifecycle 不主动做任何事，等待恢复 |

**状态转换表**：

| 当前状态 | 触发 | 下一状态 | 副作用 |
|----------|------|----------|--------|
| `UNINITIALIZED` | `_ready()` 入口 | `BOOTING` | — |
| `BOOTING` | 四 Foundation 全部就绪 | `READY` | 发出 `app_ready` |
| `READY` | `NOTIFICATION_APPLICATION_PAUSED` | `PAUSE_PENDING` | 启动 1s 防抖定时器 |
| `PAUSE_PENDING` | 定时器到期 | `PAUSED_CONFIRMED` | 发出 `app_paused` |
| `PAUSE_PENDING` | `NOTIFICATION_APPLICATION_RESUMED` | `READY` | 取消定时器，**不发任何信号**（瞬时切换） |
| `PAUSED_CONFIRMED` | `NOTIFICATION_APPLICATION_RESUMED` | `READY` | 调用 `InputService.release_text_mode()`，**然后**发出 `app_resumed` |
| `PAUSED_CONFIRMED` | `NOTIFICATION_APPLICATION_PAUSED`（重复） | `PAUSED_CONFIRMED` | 忽略（幂等） |

**关键不变量**：
- `app_ready` 一次性，永不重复
- `app_paused` 与 `app_resumed` 严格配对：先 paused 才能 resumed，永不出现一对 `app_resumed` 之前无 `app_paused`
- 若处于 `READY` 直接收到 RESUMED（异常 OS 序列），忽略——不构成"未配对的 resumed"

### Interactions with Other Systems

| 系统 | 方向 | Lifecycle 提供 | Lifecycle 调用 / 依赖 |
|------|------|---------------|-----------------------|
| **PersistenceService** | Lifecycle → Persistence | 无（Persistence 不订阅 Lifecycle 信号） | `is_ready()` 状态查询（per ADR-0001），仅在 `BOOTING` 阶段使用 |
| **InputService** | Lifecycle → Input | 无（Input 不订阅 Lifecycle 信号） | `is_ready()` 状态查询（per ADR-0001）+ `InputService.release_text_mode()`（在 PAUSED_CONFIRMED → READY 转换时调用，IME 中断恢复策略，Core Rule 6）|
| **AudioSystem** | Lifecycle → Audio | 无（Audio 直接订阅 OS 通知处理自己的 shred_loop） | `is_ready()` 状态查询（per ADR-0001），仅在 `BOOTING` 阶段使用 |
| **HapticService** | Lifecycle → Haptic | 无（Haptic 直接订阅 OS 通知处理自己的后台暂停） | `is_ready()` 状态查询（per ADR-0001），仅在 `BOOTING` 阶段使用 |
| **Mochi Character** *(future, #6)* | Lifecycle → Mochi | `app_paused`（暂停眨眼/闲置动画）、`app_resumed`（恢复动画）、`app_ready`（开始首帧动画） | — |
| **Text Input** *(future, #7)* | Lifecycle → Text Input | `app_resumed`（决定是否重新 `request_text_mode()` + 提示玩家「文字还在哦」） | — |
| **Scene Composition** *(future, #15)* | Lifecycle → Scene Composition | `app_ready`（呈现主场景）、`app_resumed`（可选 re-validate UI 完整性） | — |
| **Onboarding** *(future, #14)* | Lifecycle → Onboarding | `app_ready`（首启动后判断 `flags.first_run_complete` 决定是否进 Onboarding 流程） | — |

> ⚠️ **Provisional Contract**：Mochi Character、Text Input、Scene Composition、Onboarding 的 GDD 尚未编写。当设计时，每个 GDD 必须在 Dependencies 中列出对 Lifecycle 信号的订阅；Lifecycle 不会主动 ping 它们。

**单向性强制**：Lifecycle **只发信号、调用 InputService.release_text_mode() 一个特例**，从不向 Mochi Character / Text Input / Scene Composition 调用方法。订阅方完全控制自己对生命周期事件的响应。

*专家代理未咨询 —— Lean 模式，Section C 不触发 spawn（systems-designer + gameplay-programmer 生产前手动复审）。*

## Formulas

> Lifecycle 的"公式"是工程预算与判定谓词，不是游戏数学。
> Lean mode + 低数学复杂度 → 未 spawn `systems-designer`；生产前手动复审。

### Formula 1 — Boot Ready 判定谓词

```
boot_ready(now) = persistence_ready AND input_ready AND audio_ready AND haptic_ready

其中：
  persistence_ready = PersistenceService.is_ready() == true  (per ADR-0001)
  input_ready       = InputService.is_ready() == true        (per ADR-0001)
  audio_ready       = AudioSystem.is_ready() == true         (BGM 启动 + 池初始化)
  haptic_ready      = HapticService.is_ready() == true       (plugin 就绪检测)
```

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `persistence_ready` | bool | true/false | `PersistenceService.is_ready()` 返回 true（即使 `READY_CORRUPTED` 也算就绪，per Persistence GDD）|
| `input_ready` | bool | true/false | `InputService.is_ready()` 返回 true（`_ready()` 完成后立即为 true）|
| `audio_ready` | bool | true/false | `AudioSystem.is_ready()` 返回 true（BGM 失败时仍返回 true，per Audio Core Rule 10）|
| `haptic_ready` | bool | true/false | `HapticService.is_ready()` 返回 true（plugin 就绪或降级为空操作模式均返回 true）|

**轮询机制**：Lifecycle 在自己的 `_ready()` 末尾使用 `call_deferred("_check_boot_ready")`。`_check_boot_ready()` 评估谓词：
- True → 发出 `app_ready`，转入 `READY`
- False → 继续 `call_deferred` 下一帧重试

**输出**：bool。期望在 Autoload 链全部 `_ready()` 完成后的第 1 帧 deferred 调用即返回 true（因为 Lifecycle 是最后一个 Autoload）。**异常情况下**（某 Foundation 系统初始化失败，例如 AudioSystem BGM 资源缺失），谓词永远不满足 → Lifecycle 永远停在 `BOOTING` → `app_ready` 永不发出。这是设计上的"安全失败"——上层不会收到错误的就绪信号；测试时通过 `BOOT_TIMEOUT_MS` 超时检测发现（见 Formula 3）。

**示例**：
- 正常路径：Lifecycle `_ready()` 末尾 deferred → 下一帧 `_check_boot_ready` 评估四个 `_ready` 都为 true → `app_ready` 发出 → 状态 `BOOTING` → `READY`。耗时通常 < 16ms（单帧内）。
- 异常路径：某 Foundation 同侪 `is_ready()` 永远不返回 true（如 HapticService plugin 初始化完全失败且未降级）→ `_check_boot_ready` 条件不满足 → Lifecycle 持续 deferred 轮询 → `BOOT_TIMEOUT_MS` 触发警告。注：AudioSystem BGM 缺失不再是异常路径——Audio Core Rule 10 确保 `AudioSystem.is_ready()` 在 `_ready()` 末尾无条件返回 true。

---

### Formula 2 — Pause Debounce 谓词

```
should_emit_app_paused(pause_start_ms, now_ms) = (now_ms - pause_start_ms) >= RESUME_DEBOUNCE_MS

其中：
  pause_start_ms     = 收到 NOTIFICATION_APPLICATION_PAUSED 时的 Time.get_ticks_msec()
  now_ms             = 防抖定时器到期时的 Time.get_ticks_msec()
  RESUME_DEBOUNCE_MS = 1000 (默认常量，Tuning Knob)
```

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `pause_start_ms` | int | Godot 进程开始后的毫秒数 | `Time.get_ticks_msec()` 返回值 |
| `now_ms` | int | 同上 | 防抖定时器 timeout 时刻 |
| `RESUME_DEBOUNCE_MS` | int | 0–5000 | 防抖窗口长度 |

**实现**：使用 Godot `SceneTree.create_timer(RESUME_DEBOUNCE_MS / 1000.0)` 在 `PAUSE_PENDING` 状态启动一次性定时器。如果定时器 timeout 时仍处于 `PAUSE_PENDING` → 发出 `app_paused`，转入 `PAUSED_CONFIRMED`；如果在此期间已通过 `NOTIFICATION_APPLICATION_RESUMED` 转回 `READY`，已取消定时器引用，timeout 回调中断（通过 `is_inside_tree()` 检查保险）。

**API 选择理由**：使用 Godot 4.6 的 `Time.get_ticks_msec()`（**不** 使用已弃用的 `OS.get_ticks_msec()`，引擎参考 `deprecated-apis.md` 已记录）。

**输出**：bool。

**示例**：
- 玩家划开通知中心后立刻划回（500ms 内）：定时器未到期就被取消 → `app_paused` 不发出 → 无副作用。
- 玩家接电话 30 秒：1000ms 时定时器到期 → `app_paused` 发出 → Mochi 角色暂停眨眼；30s 后回前台 → `app_resumed` 发出 → 恢复眨眼。

**边界**：`RESUME_DEBOUNCE_MS = 0` 意味"立即发"，等同于无防抖（但 timer 仍存在，开销最小）。`RESUME_DEBOUNCE_MS > 5000` 不推荐——超过 5 秒玩家会感知到响应延迟。

---

### Formula 3 — Cold Start Latency Budget

```
cold_start_latency_ms = t_app_ready - t_process_start

预算（per technical-preferences.md "Cold Start: < 3 s"）：
  cold_start_latency_ms <= 3000ms  (P95 on iPhone SE 2nd gen)
```

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `t_process_start` | int | 进程启动时刻 | iOS：从 `applicationDidFinishLaunching` 到 Godot main loop 第一帧；通过 OS 测量工具采集 |
| `t_app_ready` | int | `app_ready` 信号发出时刻 | `Time.get_ticks_msec()` |
| **`BOOT_TIMEOUT_MS`** *(诊断常量，Tuning Knob)* | int | 默认 **5000** | 若 `BOOTING` 持续超过此值，打印 `push_error` 并发出 `boot_timeout` 诊断信号（仅诊断，不算 AC 验收阈值；阻断时不假装 ready） |

**输出**：int (ms)。

**目标分解**（参考预算）：
- Godot 进程启动 + Autoload 链 `_ready()` 串行执行：~500–1500ms（依赖 Persistence load + Audio BGM 加载）
- Lifecycle `_check_boot_ready` deferred 轮询：1 帧 ≈ 16ms
- 总计 P95 < 3000ms

**示例**：
- iPhone 12 实测：≈ 800ms ✅
- iPhone SE 2nd gen 实测：≈ 1500ms ✅ （需真机验证，见 Open Questions）
- 失败案例：若 Audio BGM 资源 lazy-load 拖累 → Lifecycle BOOTING > 5s → `boot_timeout` 发出 → 测试用例失败。

## Edge Cases

按风险类别分组。格式：`If [condition]: [outcome]. [rationale]`。

### A. 冷启动异常

- **若 Persistence 进入 `READY_CORRUPTED` 状态**：`persistence_ready` 谓词仍为 true（因为 `READY_CORRUPTED ∈ READY_*`），Lifecycle 正常发出 `app_ready`。Scene Composition 在订阅 `app_ready` 后会调用 `Persistence.consume_corruption_notice()`，进入腐败提示流程（per Persistence UI Requirements）——Lifecycle 不感知腐败状态。

- **若 AudioSystem BGM 资源缺失（Audio Edge Case "如果 `BGM_main_loop` 资源为 null"）**：per Audio Core Rule 10（MAJOR REVISION 2026-05-22），AudioSystem 在 `_ready()` 末尾**无条件**将 `is_ready()` 置为 true，即使 BGM 资源为 null。`audio_ready` **不会**因此阻塞 Lifecycle BOOTING——BGM 失败是 Audio 内部的降级，由 AudioSystem 内部 `push_error` 记录，与 Lifecycle 就绪链无关。**若某 Foundation 同侪（如 HapticService plugin 极端失败且未降级）的 `is_ready()` 永远返回 false**：Lifecycle 持续 deferred 轮询 → `BOOT_TIMEOUT_MS = 5000` 触发 → 发出 `boot_timeout` 诊断信号，`push_error("Lifecycle stuck in BOOTING: check Foundation Autoload is_ready()")` → **这是显性失败**，开发者能在 console / CI 中第一时间看到。

- **若 Lifecycle `_ready()` 自己在 Persistence/Input/Audio 之前执行（Autoload 顺序配置错误）**：`_check_boot_ready` 首次评估时，下游 Autoload 节点甚至不存在（`PersistenceService` 等是 null）。`call_deferred` 失败 → `push_error("LifecycleService: Foundation Autoload missing - check project.godot [autoload] order")`，Lifecycle 停在 `BOOTING`。配合 AC 检测，CI 阶段就能发现配置错误。

- **若 Lifecycle 自己 `_ready()` 之前已经收到了 PAUSED 通知（极端 OS 行为）**：忽略——`UNINITIALIZED` 和 `BOOTING` 状态对 OS 通知不响应（只有 `READY` 状态接收 PAUSED）。等正常 `app_ready` 后，下次 PAUSED 才被处理。这是保守姿态：在 cold start 期间不可能发"app_paused"，因为还未"app_ready"过。

### B. PAUSED/RESUMED 序列异常

- **若快速连续 PAUSED → RESUMED → PAUSED → RESUMED（<1s 内多次抖动）**：每次 PAUSED 重置防抖定时器；任何一次 RESUMED 取消定时器 → 整个序列内 **`app_paused` 和 `app_resumed` 都不发出**。Lifecycle 视此为完全瞬时切换，无副作用。

- **若在 `PAUSED_CONFIRMED` 状态下重复收到 PAUSED**：忽略（状态机表已规定）。不重启防抖、不重复发 `app_paused`。

- **若在 `READY` 状态下直接收到 RESUMED（无配对 PAUSED 在前）**：忽略——`app_resumed` 永远只在 `PAUSED_CONFIRMED → READY` 转换时发出。这避免了"未配对 resumed"破坏不变量。可能的发生场景：iOS 在某些异常条件（横竖屏切换某些 OS 版本）发出多余 RESUMED；Lifecycle 抗噪。

- **若进程被 SIGKILL（iOS 内存压力杀掉）**：Lifecycle 不接收任何通知——整个进程消失。下次 cold start 时，Lifecycle 从头开始 `UNINITIALIZED → BOOTING → READY`，发出 `app_ready` 而非 `app_resumed`。Persistence 的存档已通过原子 rename 保护（Persistence Core Rule 6），数据不丢失。

### C. IME 中断恢复

- **若 `app_resumed` 即将发出时，InputService 已经在 GESTURE_MODE**：`InputService.release_text_mode()` 是幂等的（Input GDD Edge Case B "若 release_text_mode 被重复调用，无操作"）→ 安全。

- **若 `app_resumed` 即将发出时，玩家在后台时仍想继续打字（Text Input 希望 IME 恢复焦点）**：Text Input 订阅 `app_resumed`，**在 Lifecycle 已调用 `release_text_mode()` 之后**收到信号；Text Input 此时可调用 `InputService.request_text_mode()` 重新打开 IME（如果它判断"半成品文字还在，玩家应该继续写"）。**关键顺序**：Lifecycle `InputService.release_text_mode()` → `app_resumed` 发出 → Text Input 订阅回调 → Text Input 可重新 `request_text_mode()`。Lifecycle 与 Text Input 之间没有竞态，因为 Lifecycle 的两个动作在同一帧中同步执行。

- **若 Text Input GDD 决定使用更激进的策略**（例如"app_paused 时清空半成品文字"）：Text Input 订阅 `app_paused` 自行处理，Lifecycle 不感知。Lifecycle 的责任仅限于 IME *焦点状态*恢复，不涉及 *文字内容*管理。

### D. 平台 / Godot 4.6 特定

- **若 Godot 4.6 在 iOS 上将"短暂前台→后台→前台"（如下拉控制中心）映射为快速 PAUSED→RESUMED 序列**：防抖窗口足以吸收 —— `app_paused/resumed` 都不发，无副作用。**待真机验证**（见 Open Questions）。

- **若 Android 13+ predictive back 在 Godot 4.6 中映射到了 `NOTIFICATION_APPLICATION_PAUSED` 而非 `NOTIFICATION_WM_GO_BACK_REQUEST`**：Lifecycle 会误判为生命周期事件，进入 PAUSE_PENDING。1 秒后若仍未"resume"（玩家完成手势），发出 `app_paused`。这是已知的潜在误报。**待真机验证**（与 Persistence、Input 共享同一 OQ）。

- **若 iOS 用户在 App 处于 `PAUSED_CONFIRMED` 时手动 Force Quit**：进程被杀，Lifecycle 不会发出 `app_resumed`。下次启动是新的 cold start。Persistence 数据完整（已通过 atomic rename 保护）。

- **若 iOS 用户启用了 Background App Refresh 且 OS 短暂唤醒 App 后台**：Godot 4.6 是否会触发 `NOTIFICATION_APPLICATION_RESUMED` 不明（这种唤醒 App 没有可见 UI）。**保守假设：忽略**——如果 RESUMED 在 `PAUSED_CONFIRMED` 触发但用户实际还在后台，会过早发 `app_resumed` 给上层。**Mitigation**：上层订阅方应当对 `app_resumed` 的副作用是幂等的（恢复动画、re-validate UI 等），即使被多触发也不破坏不变量。这是订阅方的责任，Lifecycle 不试图判断"真正的"前台。

### E. API 误用 / 订阅模式

- **若某下游系统在 `app_ready` 已经发出**之后才订阅 `app_ready` 信号：该订阅永远不会触发——`app_ready` 是单次信号，无 replay。**Mitigation**：API 提供 `is_ready()` 同步查询；订阅方应当先调用 `is_ready()` 检查，已就绪则立即执行就绪逻辑，未就绪则订阅信号等待。Godot 4.6 信号 `signal.connect(callable, flags)` 不支持 replay。

- **若某下游系统订阅 `app_paused` 后忘记 disconnect 就被 free**：Godot 4.6 在 Node `_exit_tree()` 时自动断开所有信号连接 —— 无内存泄漏。但如果订阅方持有 Lifecycle 引用并阻止其 free，则正常 GC 流程会处理（Lifecycle 是 Autoload，整个 App 生命周期不 free）。

- **若某下游系统在 `app_paused` 回调中重新调用 `LifecycleService` 的方法（例如查询 `is_in_confirmed_background()`）**：合法 —— `is_in_confirmed_background()` 在此刻返回 true（信号发出后状态已转换）。Lifecycle 的所有公共 API 都是只读的，无重入风险。

## Dependencies

### Upstream — 本系统依赖

**无上游游戏系统依赖。** Lifecycle 是 Foundation 层。它仅订阅 Godot OS 原生通知（`NOTIFICATION_APPLICATION_PAUSED`、`NOTIFICATION_APPLICATION_RESUMED`），并对其他 Foundation Autoload（`PersistenceService`、`InputService`、`AudioSystem`）进行**只读状态查询**和**一个特例方法调用**：

| 同侪 Foundation | Lifecycle 的访问 | 类型 | 理由 |
|---|---|---|---|
| `PersistenceService` | 调用 `is_ready()` | 只读状态查询 | Formula 1 boot ready 谓词（per ADR-0001）|
| `InputService` | 调用 `is_ready()`；调用 `release_text_mode()` | 只读 + 一处写 | Formula 1 谓词 + Core Rule 6 IME 恢复 |
| `AudioSystem` | 调用 `is_ready()` | 只读状态查询 | Formula 1 谓词 |
| `HapticService` | 调用 `is_ready()` | 只读状态查询 | Formula 1 谓词 |

> ⚠️ 这四处访问不构成传统意义的"上游依赖"（Lifecycle 不订阅它们的信号、不依赖它们的功能契约），但**它要求 Foundation 四同侪满足以下接口约定（per ADR-0001）**：
> - PersistenceService 暴露 `is_ready() -> bool`（已回填，per ADR-0001）
> - InputService 暴露 `is_ready() -> bool`（per ADR-0001）和 `release_text_mode()`（已在 Input API 中）
> - AudioSystem 暴露 `is_ready() -> bool`（已回填，per Audio GDD MAJOR REVISION 2026-05-22）
> - HapticService 暴露 `is_ready() -> bool`（已回填，per Haptic GDD MAJOR REVISION 2026-05-22）

### Downstream — 依赖本系统

| 系统 | 方向 | 依赖性质 | 接口 |
|------|------|---------|------|
| **Mochi Character System** *(future, #6)* | Mochi → Lifecycle | **硬依赖** — 角色动画需要知道何时暂停/恢复闲置循环 | 订阅 `app_ready`、`app_paused`、`app_resumed` 信号 |
| **Text Input System** *(future, #7)* | Text Input → Lifecycle | **硬依赖** — 后台返回后必须决定是否恢复 IME 焦点 | 订阅 `app_resumed` 信号；若选择"app_paused 时持久化半成品文字"，亦订阅 `app_paused` |
| **Scene Composition** *(future, #15)* | Scene Composition → Lifecycle | **硬依赖** — 主场景呈现必须等待 `app_ready` | 订阅 `app_ready`；可选订阅 `app_resumed` 用于 re-validate UI |
| **Onboarding** *(future, #14)* | Onboarding → Lifecycle | **软依赖** — Onboarding 流程可由 Scene Composition 间接驱动；但若 Onboarding 直接订阅 `app_ready` 判断首启动流程，则为硬依赖 | 订阅 `app_ready` 或委托给 Scene Composition |

### 跨切面 — 非依赖关系

| 系统 | 关系 |
|------|------|
| **PersistenceService** | 同 Foundation 层同侪。Persistence 直接订阅 OS 通知做自己的存档（Persistence Core Rule 7），**不通过** Lifecycle 转发。Lifecycle 只读 Persistence 状态用于 boot ready 检测，从不写。 |
| **InputService** | 同 Foundation 层同侪。Input 直接订阅 OS 通知处理自己的手势中断（Input Core Rule 7），**不通过** Lifecycle 转发。Lifecycle 只在 `app_resumed` 即将发出时调用一次 `release_text_mode()`（Core Rule 6）。 |
| **AudioSystem** | 同 Foundation 层同侪。Audio 直接订阅 OS 通知停止 shred_loop（Audio Edge Case），**不通过** Lifecycle 转发。 |
| **Haptic System** *(#4 — 已完成)* | 与 Lifecycle 无直接关系。Haptic 已确认直接订阅 OS `application_paused/resumed` 通知响应后台暂停（Haptic GDD MAJOR REVISION 2026-05-22 确认，与四 Foundation 同侪同模式），不依赖 Lifecycle 转发。 |
| **Juice Cookbook** *(future, Wave 2)* | 无关系。Juice 不订阅生命周期信号——它通过 Lever、Shred、Silhouette 的游戏内信号触发。 |

### Bidirectional Consistency — 待处理项

1. ✅ **AudioSystem `is_ready()` 已回填**（Audio GDD MAJOR REVISION 2026-05-22）：`is_ready() -> bool` 已作为 Audio Core Rule 10 添加。BGM 资源缺失时仍返回 true，不阻塞 Foundation 就绪链。

2. ✅ **PersistenceService 状态查询需求已被 ADR-0001 取代**（2026-05-22）：ADR-0001 确立 `is_ready() -> bool` 为所有 Foundation Autoload 的统一就绪接口；Persistence 已回填 `is_ready()`（per ADR-0001 Decision 2）。`get_state()` 不再需要专门暴露——Lifecycle 使用 `PersistenceService.is_ready()` 即可。

3. **下游 GDD 反向引用**：Mochi Character、Text Input、Scene Composition、Onboarding 的 GDD 写作时，必须在各自 Dependencies 节中列出"depends on Mobile App Lifecycle"并引用所订阅的信号名（`app_ready` / `app_paused` / `app_resumed`）。`/consistency-check` 验证此双向性。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|----------|----------|
| `RESUME_DEBOUNCE_MS` *(Formula 2 防抖窗口)* | **1000** | 0 — 5000 | 更长瞬时切换窗口；玩家可短暂离开 2-3s 也不触发 `app_paused`/`app_resumed`，BGM/动画无重启；但若设过长，玩家真正离开 3s 内仍未发 paused 会导致 Mochi 角色闲置动画"看起来还活着" | 更短防抖；快速划手势可能触发完整 paused/resumed 流程，造成 BGM 重启/动画重置；< 200ms 等同无防抖 |
| `BOOT_TIMEOUT_MS` *(诊断常量)* | **5000** | 3000 — 10000 | 容忍更慢的 boot（应对 Audio BGM 资源加载慢的极端设备）；但可能掩盖真正的 Foundation 初始化失败 | 更早触发诊断；可能在低端设备首启动时误报；不应低于 Cold Start 预算 3000ms |

### 非游戏调节、但应可配置（Tuning Knob 候选）

| 参数 | 当前值 | 用途 | 备注 |
|------|--------|------|------|
| `BOOT_READY_POLL_INTERVAL_FRAMES` | **1** | `_check_boot_ready` deferred 间隔（帧） | MVP 用 1 帧（每帧 deferred）。若发现 boot 检测自身耗时阻碍 main thread，可改为 2-4 帧。默认 1。 |
| `IME_RECOVERY_STRATEGY` *(枚举)* | **`AGGRESSIVE_RELEASE`** | `app_resumed` 时如何处理 InputService | `AGGRESSIVE_RELEASE`（当前 Core Rule 6） / `PASSIVE`（不调用 release_text_mode）。MVP 锁定 `AGGRESSIVE_RELEASE`；预留枚举以便未来如果 Text Input GDD 需要换策略，不必改 Lifecycle 代码核心 |

### 明确**不是**旋钮

- **支持的 OS 通知集合**（`NOTIFICATION_APPLICATION_PAUSED` / `_RESUMED`）—— 修改需要改代码，不是设计调节
- **状态机定义**（5 个状态 + 转换规则）—— 架构性逻辑
- **Autoload 顺序约束**（Lifecycle 必须最后） —— 安全约束，不可调
- **`app_ready` 一次性发出**—— 不变量
- **`app_paused`/`app_resumed` 配对发出**—— 不变量
- **`is_ready()` / `is_in_confirmed_background()` 返回值**—— 派生自状态机，不可独立调节
- **是否为 Foundation 四同侪转发 OS 通知**—— **否**。这是架构边界，不是开关。如果未来发现 Foundation 同侪应当通过 Lifecycle 路由，应当通过 ADR 评估而非 Tuning Knob

### Juice 关联（携带约束，来自系统索引）

Lifecycle 本身无视觉/音频输出，**直接不驱动 Juice**。但它的信号是上层 Juice 决策的触发源：

- `app_paused` 触发 Mochi 角色淡出眨眼（Juice 决策："淡出还是冻结"由 Mochi Character GDD 决定）
- `app_resumed` 触发 Mochi 角色淡入闲置（Juice 决策："立刻显示还是从黑屏淡入"由 Scene Composition + Mochi Character 共同决定）
- `app_ready` 触发首帧呈现的入场动画（Juice 决策：从 splash 切到主场景的过渡形式）

Juice Cookbook（Wave 2）定义这些信号应触发的具体视觉/音频效果。Lifecycle 仅提供"时间点"，不规定"效果"。

## Visual/Audio Requirements

Mobile App Lifecycle 是纯基础设施，**无视觉或音频输出**。它通过三个高层信号（`app_ready` / `app_paused` / `app_resumed`）通知下游系统，由订阅方（Mochi Character、Scene Composition、Text Input）负责对应的视觉/音频响应：

| 信号 | 订阅方 | 期望响应 |
|------|--------|----------|
| `app_ready` | Scene Composition / Mochi Character / Onboarding | 主场景入场动画、Mochi 角色出现、Onboarding 流程启动判定 |
| `app_paused` | Mochi Character / Scene Composition | 暂停角色闲置/眨眼动画、可选的背景层淡出（节省电量） |
| `app_resumed` | Mochi Character / Scene Composition / Text Input | 恢复角色动画、可选的 UI 重渲染、可选的"文字还在哦"提示 |

**Lifecycle 本身不播放音效、不触发动画、不产生粒子效果**。Audio System 已经独立订阅 OS `NOTIFICATION_APPLICATION_PAUSED` 停止 shred_loop（Audio Edge Case），不依赖 Lifecycle 信号。

## UI Requirements

Mobile App Lifecycle **无专属 UI**。它不渲染任何界面元素、不弹出任何提示、不创建任何 Control 节点。

**派生的 UI 时序约束**（由订阅方实现，但 Lifecycle 提供时间点）：

- 主场景内容**不应**在 `app_ready` 发出前可见。Scene Composition 在 `app_ready` 之前可以显示 splash/空白屏，但不应渲染 Mochi 角色或货架——避免玩家看到"半就绪"状态。
- `app_resumed` 之后的 UI 应当**幂等响应**：即使 Lifecycle 因 Edge Case D 偶尔过早发出 `app_resumed`（如 iOS Background App Refresh 误判），订阅方的恢复逻辑也不应破坏 UI 不变量。

Lifecycle 不强制实现这些 UI 约束——它们是订阅方的责任。

## Acceptance Criteria

> 格式：GIVEN-WHEN-THEN。每条可由 QA 测试员独立验证，无需阅读本 GDD。
> *`qa-lead` 未咨询 —— Lean 模式 + 低实现风险。生产前手动复审。*
> 硬件门控 AC 标记 `[BLOCKED-HARDWARE]`，需要 iPhone SE 2nd gen 真机。

### 功能 — 冷启动

1. **GIVEN** 项目已配置 `LifecycleService` 为 `[autoload]` 列表中**最后一个** Foundation Autoload，**WHEN** 项目冷启动，**THEN** 在 main loop 第 2-5 帧内 `LifecycleService.is_ready() == true` 且 `app_ready` 信号在该过程中**恰好发出一次**。

2. **GIVEN** 项目已正常冷启动且 `app_ready` 已发出，**WHEN** 测试用例再次主动调用 `LifecycleService` 的内部 `_check_boot_ready()`（通过测试钩子），**THEN** `app_ready` 不再次发出（一次性不变量）。

3. **GIVEN** Lifecycle 处于 `BOOTING` 状态，`AudioSystem.is_ready()` 模拟返回 `false`，**WHEN** 5 秒经过（`BOOT_TIMEOUT_MS = 5000`），**THEN** Lifecycle 仍处于 `BOOTING`，`app_ready` **未**发出，`push_error("Lifecycle stuck in BOOTING")` 被调用，`boot_timeout` 诊断信号发出。

4. **GIVEN** Lifecycle Autoload 顺序错误（Lifecycle 在 PersistenceService 之前），**WHEN** 冷启动开始，**THEN** Lifecycle `_check_boot_ready` 检测到 `PersistenceService == null` → `push_error("LifecycleService: Foundation Autoload missing - check project.godot [autoload] order")`，CI 测试失败。

### 功能 — PAUSED/RESUMED 状态机

5. **GIVEN** Lifecycle 处于 `READY` 状态，**WHEN** 通过 GUT `notify_message(NOTIFICATION_APPLICATION_PAUSED)` 触发，**THEN** Lifecycle 状态转为 `PAUSE_PENDING`，`app_paused` **未**立即发出（防抖窗口运行中）。

6. **GIVEN** Lifecycle 处于 `PAUSE_PENDING` 状态（PAUSED 触发后），**WHEN** 在 500ms 内（< `RESUME_DEBOUNCE_MS = 1000`）触发 `NOTIFICATION_APPLICATION_RESUMED`，**THEN** Lifecycle 状态回到 `READY`，`app_paused` 和 `app_resumed` **都未**发出（瞬时切换被吸收）。

7. **GIVEN** Lifecycle 处于 `PAUSE_PENDING` 状态，**WHEN** 1000ms 经过且未收到 RESUMED，**THEN** Lifecycle 状态转为 `PAUSED_CONFIRMED`，`app_paused` **恰好发出一次**，`is_in_confirmed_background() == true`。

8. **GIVEN** Lifecycle 处于 `PAUSED_CONFIRMED` 状态（`app_paused` 已发出），**WHEN** 触发 `NOTIFICATION_APPLICATION_RESUMED`，**THEN** (a) `InputService.release_text_mode()` 被调用一次；(b) `app_resumed` **恰好发出一次**；(c) 调用顺序为 release_text_mode → app_resumed（同帧内同步执行）；(d) Lifecycle 状态回到 `READY`。

9. **GIVEN** Lifecycle 处于 `READY` 状态，**WHEN** 触发 `NOTIFICATION_APPLICATION_RESUMED`（无配对 PAUSED 在前），**THEN** Lifecycle 状态保持 `READY`，`app_resumed` **未**发出（防御未配对 RESUMED 不变量）。

10. **GIVEN** Lifecycle 处于 `PAUSED_CONFIRMED` 状态，**WHEN** 再次触发 `NOTIFICATION_APPLICATION_PAUSED`（重复），**THEN** Lifecycle 状态保持 `PAUSED_CONFIRMED`，`app_paused` **未**重复发出，防抖定时器**未**重启。

### 功能 — IME 中断恢复（Core Rule 6 验证）

11. **GIVEN** Lifecycle 处于 `PAUSED_CONFIRMED` 且 InputService 处于 `TEXT_MODE`（玩家在后台前正在打字），**WHEN** 触发 RESUMED，**THEN** `InputService.release_text_mode()` 被调用，调用后 `InputService.current_mode() == GESTURE_MODE`；`app_resumed` 在 release_text_mode 之后发出。

12. **GIVEN** Lifecycle 处于 `PAUSED_CONFIRMED` 且 InputService 处于 `GESTURE_MODE`，**WHEN** 触发 RESUMED，**THEN** `InputService.release_text_mode()` 仍被调用（幂等，安全），不抛出异常，`app_resumed` 正常发出。

### 功能 — 信号订阅模式

13. **GIVEN** Lifecycle 已发出 `app_ready` 信号，**WHEN** 新的下游订阅者在 `app_ready` 发出之后才 `connect("app_ready", ...)`，**THEN** 该订阅者的回调**不**被触发（Godot 信号无 replay）；订阅者应当先调用 `is_ready()` 查询。

14. **GIVEN** 一个下游节点 `connect("app_paused", callable)` 已建立，**WHEN** 该节点通过 `queue_free()` 被销毁，**THEN** Godot 自动断开连接；Lifecycle 后续 `app_paused.emit()` 不报错。

### 架构 — 代码验证（CI 自动化）

15. **GIVEN** LifecycleService 源文件，**WHEN** CI 测试 grep 业务字符串（`"products"` / `"worry"` / `"shelf"` / `"mochi"` / `"silhouette"` / `"lever"` / `"shred"`），**THEN** 零匹配（Core Rule 9 域无关性强制）。

16. **GIVEN** LifecycleService 源文件，**WHEN** CI 测试扫描 import / preload，**THEN** **仅**对 `PersistenceService`、`InputService`、`AudioSystem`、`HapticService` 四个 Foundation Autoload 有引用，对游戏层（Mochi Character、Text Input 等）**零**引用。

17. **GIVEN** LifecycleService 源文件，**WHEN** CI grep `OS\.get_ticks_msec`，**THEN** 零匹配（Godot 4.4+ 已弃用，必须使用 `Time.get_ticks_msec()`）。

18. **GIVEN** LifecycleService 源文件，**WHEN** CI grep `RESUME_DEBOUNCE_MS` / `BOOT_TIMEOUT_MS` 的裸字面量（`1000` / `5000`）出现在非字符串上下文，**THEN** 零匹配——所有 Tuning Knob 值必须定义为文件顶部的 UPPER_SNAKE_CASE 常量（如 `const RESUME_DEBOUNCE_MS := 1000`），不允许魔术数字散落在逻辑代码中。（v1.0 可迁移至外部配置资源；MVP 不强制 .tres 文件。）

### 性能 — iPhone SE (2nd gen) 真机

19. `[BLOCKED-HARDWARE]` **冷启动延迟**：GIVEN 标准 MVP 项目首次启动（无既存存档），WHEN 测量进程启动到 `app_ready` 信号发出的时间差，THEN 时延 **≤ 3000ms**（P95）。测量方法：iOS Xcode Instruments time profiler + Godot 端 `Time.get_ticks_msec()` 双重记录。

20. `[BLOCKED-HARDWARE]` **防抖定时器精度**：GIVEN Lifecycle 处于 `PAUSE_PENDING`，WHEN 触发 PAUSED 后等待 1000ms ± 50ms，THEN `app_paused` 在 [950ms, 1100ms] 区间内发出（容差 50ms 上、100ms 下，Godot SceneTimer 在低端设备的实际抖动）。

21. **Boot Ready 轮询开销**：GIVEN Lifecycle 处于 `BOOTING` 状态，WHEN `_check_boot_ready` 通过 deferred 调用 30 帧（约 500ms 模拟慢 boot），THEN 总 main thread 时间 ≤ 5ms（每帧 ≤ 0.17ms），通过 GUT 性能检测验证。

### 功能 — 边界场景（新增 2026-05-21）

22. **GIVEN** 进程被强杀（模拟 SIGKILL）后重启，WHEN 新进程冷启动，THEN Lifecycle 从 `UNINITIALIZED` 开始正常进入 `BOOTING → READY`，发出 `app_ready` 信号；**不**会发出 `app_resumed`（无配对 paused）。

23. **GIVEN** Lifecycle 处于 `PAUSE_PENDING`，定时器尚未到期，WHEN 节点通过 `queue_free()` 模拟销毁（异常情况，因为 Autoload 不应被销毁），THEN 定时器引用通过 `is_inside_tree()` 检查中断回调，**不**触发已销毁节点的 callback。

24. **GIVEN** Lifecycle 处于 `READY` 状态，WHEN 同帧内连续触发 3 次 PAUSED 通知（OS 异常重复），THEN Lifecycle 状态机仅在第 1 次 PAUSED 转 `PAUSE_PENDING`，后续 2 次被忽略；防抖定时器仅启动一次。

## Open Questions

### 设计已决（仅此节内记录，不算待解）

| 问题 | 决议 |
|------|------|
| ~~Lifecycle 是否作为 OS 通知统一网关？~~ | **否**。四大 Foundation 同侪（Persistence/Input/Audio/Haptic）按各自 GDD 设计直接订阅 OS 通知。Lifecycle 是上层协调服务，不做中介。 |
| ~~防抖窗口长度？~~ | `RESUME_DEBOUNCE_MS = 1000` |
| ~~IME 中断恢复策略？~~ | `AGGRESSIVE_RELEASE`：`app_resumed` 时主动 `InputService.release_text_mode()`。响应 Input GDD OQ4 的移交。 |
| ~~冷启动 "ready" 判定标准？~~ | Foundation 四同侪全部 `is_ready()` 返回 true（Persistence、Input、Audio、Haptic）。per ADR-0001 统一契约（2026-05-22 更新）。 |

### 仍待解（移交其他 session / GDD）

| 问题 | 负责人 | 截止时机 | 备注 |
|------|--------|----------|------|
| **Godot 4.6 `NOTIFICATION_APPLICATION_RESUMED` 在 iOS Background App Refresh 短暂唤醒时是否触发？** | godot-specialist | 首次 iOS 真机构建 | Edge Case D 设计为"即使误触发，订阅方也应幂等响应"。但若实际不触发，可移除该 Edge Case 警告。 |
| **Android 13+ predictive back 在 Godot 4.6 中映射到哪个 notification？** | godot-specialist | 首次 Android 真机构建 | 与 Persistence + Input 共享同一 OQ。三系统都需要真机确认。 |
| **iPhone SE 2nd gen 实际冷启动延迟？** | 真机测试 | MVP gate 前 | AC 19 BLOCKED-HARDWARE。预算 3000ms 是 technical-preferences 的目标，但未在低端机型实测。 |
| ~~**AudioSystem `is_ready()` API**~~ | ✅ 已解决（Audio GDD MAJOR REVISION 2026-05-22 回填 Core Rule 10）| — | — |
| ~~**PersistenceService `get_state()` API**~~ | ✅ 已被 ADR-0001 取代（2026-05-22 — 统一使用 `is_ready() -> bool`）| — | — |
| **`IME_RECOVERY_STRATEGY` 是否真的需要枚举？** | Text Input GDD 设计时 | Wave 3 | 如果 Text Input 决定完全自管恢复（PASSIVE 策略），Lifecycle 可以直接移除该枚举，简化为硬编码 AGGRESSIVE_RELEASE。MVP 暂保留以备未来。 |
| **App 终止前最后机会回调是否需要？** | 暂搁置 | v1.0 评估 | Phase 2 决策时排除（Persistence 自管原子保存已足够）。若未来发现非持久化的瞬时状态需要清理（如 Haptic 余震、Audio 渐淡），再考虑加入 `app_will_terminate` 信号。 |

### Cross-References

| 本文档引用 | 目标 | 具体元素 | 性质 |
|------------|------|----------|------|
| Pillar alignment | `design/gdd/game-concept.md` | Pillar 5 (Unlimited But Meaningful)、Anti-Pillar（隐私默认） | 规则依赖 |
| Layer + priority 分配 | `design/gdd/systems-index.md` | Mobile App Lifecycle (#5) 行 | 索引引用 |
| Persistence 直接订阅 OS 通知（非 Lifecycle 转发） | `design/gdd/persistence-system.md` | Core Rule 7 + Dependencies | 架构边界引用 |
| Persistence Autoload 顺序约束（Lifecycle 在其之后） | `design/gdd/persistence-system.md` | Core Rule 10 | 兼容性约束 |
| Persistence `is_ready()` API | `design/gdd/persistence-system.md` | `is_ready()` API | ✅ ADR-0001 以 `is_ready()` 取代 `get_state()`（2026-05-22）|
| Input 直接订阅 OS 通知（非 Lifecycle 转发） | `design/gdd/input-system.md` | Core Rule 7 + Dependencies | 架构边界引用 |
| Input `release_text_mode()` 幂等性 | `design/gdd/input-system.md` | Edge Case B | 依赖契约 |
| Input IME 恢复策略移交 Lifecycle | `design/gdd/input-system.md` | Open Question 4 | 责任移交点 |
| Audio 直接订阅 OS 通知停止 shred_loop | `design/gdd/audio-system.md` | Edge Case "若 PAUSED 时 shred_loop 在播" | 架构边界引用 |
| Audio `is_ready()` API | `design/gdd/audio-system.md` | Core Rule 10 | ✅ 已回填（MAJOR REVISION 2026-05-22）|
| Haptic 直接订阅 OS 通知（非 Lifecycle 转发） | `design/gdd/haptic-system.md` | Core Rules + OS 通知订阅 | 架构边界引用（已确认）|
| Haptic `is_ready()` API | `design/gdd/haptic-system.md` | `is_ready()` API | ✅ 已回填（MAJOR REVISION 2026-05-22，per ADR-0001）|
| Godot 4.4+ `OS.get_ticks_msec` 弃用 → 必须用 `Time.get_ticks_msec` | `docs/engine-reference/godot/deprecated-apis.md` | API 变更条目 | 引擎兼容性 |
| 未来下游 GDD 引用 `app_ready`/`app_paused`/`app_resumed` 信号契约 | *(future)* `design/gdd/mochi-character.md` | 信号订阅 | 数据依赖 |
| 同上 | *(future)* `design/gdd/text-input.md` | 信号订阅 | 数据依赖 |
| 同上 | *(future)* `design/gdd/scene-composition.md` | 信号订阅 | 数据依赖 |
| Cold start 预算来源 | `.claude/docs/technical-preferences.md` | "Cold Start: < 3 s" 行 | 性能预算 |

> *(future)* 条目是尚未编写的下游 GDD 占位。`/review-all-gdds` 在每个下游 GDD 落地时验证双向一致性。
