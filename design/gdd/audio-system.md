# Audio System

> **Status**: Revised — pending re-review
> **Author**: audio-director + sound-designer + game-designer (main)
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Pillar 1（Tactile First）+ Pillar 2（Every Pull Is a Theatre）

## Summary

Audio System 是 Mochi 的音频输出层——管理音频总线（Master → Music / SFX）、8 个 SFX 事件目录（含 1 个 BGM 环境音）和 BGM ambient loop，向下游 5 个系统暴露 `AudioSystem.play()` 接口。Foundation 层，零上游依赖；Pillar 1 指定音效预算优先级 ≥ 美术预算。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (zero upstream)`

## Overview

Audio System 是 Mochi 的音频输出层——一个 Godot Autoload 单例，负责管理所有音频总线（Master → Music / SFX / UI），维护 8 个 SFX 事件（含 1 个 BGM 环境音）目录，并向其他系统暴露类型化 API。它是 Foundation 层系统，无上游依赖；下游 5 个核心系统（摇杆、粉碎、揭晓、Mochi 角色、Juice Cookbook）通过信号或直接方法调用触发它。

玩家永远不会打开一个"音频系统菜单"——他们感受到的是：每次拉摇杆时那声沉实的"咔嚓"、机器运转的齿轮嗡鸣、碎屑旋转的"哗啦哗啦"、揭晓瞬间那声清脆的"叮咚"。这些声音不是装饰，它们是 22-30 秒核心循环的情绪标点符号。没有音频，摇杆只是一个滑动动作；有了音频，它变成一场仪式。

这个系统存在是因为 Pillar 1（触感先行）把音频和触觉并列为游戏灵魂——概念文档明确：音效预算优先级 ≥ 美术预算。Audio System 是"机器有重量感"的技术基础，也是 Juice Cookbook 所有音频义务规范的上游依据。

## Player Fantasy

音频是 Mochi 核心循环的情绪骨架。玩家不会"想到音频"——他们只会在无声时感到空洞，在声音到位时感到"对，就是这样"。

**目标情绪**：每一个操作动作都有真实重量。摇杆拉下去是"咔嚓"，不是"叮"。机器运转是低沉的"嗡嗡嗡"，不是循环噪声。粉碎是绵延的"哗啦啦啦"，揭晓是一声清脆的"叮咚"——像精心制作的小礼物被打开的瞬间。这套声音序列是 22-30 秒核心循环的情绪标点，缺一不可。

玩家应该感受到的是：**这台机器是真实存在的、有重量的、在认真工作的**。声音让 Mochi 从一堆像素变成一个有性格的工匠。

**目标参考瞬间**：
- *ASMR 碎纸机视频*：连续机械研磨声本身就令人满足，与结果无关——过程本身即享受
- *扭蛋机出球*：转动机械声 → 咔哒一声 → 球滚出来——仪式感音序的参考对象
- *Wall-E 机械音*：金属感但温暖，有性格，不是冷漠工厂机器

**反参考**：不能像手游泛用 UI 音效——那种轻飘飘的"叮"或"哔"声。每个事件的声音要让玩家本能地感到"这是 Mochi，不是别的游戏"。

## Detailed Design

### Core Rules

1. **Autoload 单例**：Audio System 作为 Godot Autoload 注册为 `AudioSystem`，项目启动时自动加载，全局可访问。

2. **SFX 事件目录（MVP）**

   | 事件键 | 触发时机 | 循环 | Haptic 对位（同时发射） | 所有者系统 |
   |--------|---------|------|---|-----------|
   | `lever_drag` | 摇杆开始拖拽（下压起点，未越阈值）| 否 | none（拖拽无触觉配对） | Lever Interaction |
   | `lever_pull` | 摇杆越过触发阈值（拉下） | 否 | `lever_lock` | Lever Interaction |
   | `shred_start` | 粉碎机开始运转 | 否 | `shred_start` | Shred Process |
   | `shred_loop` | 粉碎过程中持续音 | **是** | (intra-loop: `shred_pulse` 按 F-2 调度，见 haptic-system.md) | Shred Process |
   | `shred_end` | 粉碎完毕 | 否 | `shred_end` | Shred Process |
   | `reveal_pop` | 剪影弹出并填色 | 否 | `reveal_pop` | Silhouette Reveal |
   | `product_land` | 产物落入托盘 | 否 | `product_land` | Silhouette Reveal |
   | `shelf_add` | 产物飞入货架 | 否 | `shelf_add` | Shelf Collection |
   | `BGM_main_loop` | App 启动后自动播放 | **是** | (none) | AudioSystem 自管理 |

   > **Haptic 对位列说明**：列出 `Haptic.play(key)` 中相应的 haptic 事件键。镜像 `design/gdd/haptic-system.md` Event Catalog 的 "Audio 对位" 列。音触配对的发射顺序与时间窗由 Core Rule 9（下方）约束。

3. **总线架构**

   ```
   Master
   ├── Music（BGM，默认音量 -12dB，低于 SFX 层）
   └── SFX（所有事件音效）
   ```
   - 保留 `UI` 总线占位，MVP 中无 UI 音效，v1.0 加入
   - 每条总线独立音量控制，互不影响

4. **API 接口（外部系统调用方式）**

   ```gdscript
   # 静态类型签名（项目规范，对位 Haptic.play 用 StringName）
   func play(key: StringName) -> void
   func play_loop(key: StringName) -> void
   func stop_loop(key: StringName) -> void

   # 调用示例
   AudioSystem.play(&"lever_pull")
   AudioSystem.play_loop(&"shred_loop")
   AudioSystem.stop_loop(&"shred_loop")
   ```
   - `play()` / `play_loop()` / `stop_loop()` 形参类型 = `StringName`，与 `Haptic.play(key: StringName)` 对位
   - 调用方传 `&"lever_pull"` 字面量（Godot StringName 字面前缀）
   - **有效键白名单**：实现层持有 `_valid_sfx_keys: Dictionary[StringName, bool]`，在 `_ready()` 时从 Event Catalog 初始化（包含 `lever_drag`、`lever_pull`、`shred_start`、`shred_loop`、`shred_end`、`reveal_pop`、`product_land`、`shelf_add`、`BGM_main_loop` 共 9 键）。`play()` 调用时先查此字典——未命中者记为"未知键"，静默忽略 + `push_warning()`，不 crash。

   ```gdscript
   # 内部键名白名单（实现参考）
   var _valid_sfx_keys: Dictionary[StringName, bool] = {
       &"lever_drag": true, &"lever_pull": true, &"shred_start": true,
       &"shred_loop": true, &"shred_end": true, &"reveal_pop": true,
       &"product_land": true, &"shelf_add": true, &"BGM_main_loop": true,
   }
   ```

5. **并发 SFX**：使用对象池（8 个 `AudioStreamPlayer` 节点）处理并发；shred_loop 使用独立的专用播放器节点，不参与池分配。

6. **BGM 管理**：`AudioSystem._ready()` 时自动开始 `BGM_main_loop`。MVP 中 BGM 永不淡出——F-3 淡出公式预留给 v1.0 场景切换，MVP 阶段 BGM 循环直到 App 强杀。App 进入后台时平台自动静音；返回前台后 iOS/Android 自动恢复音频流，AudioSystem 无需显式重启 BGM。

7. **音量持久化**：Music/SFX 音量设置由 **Persistence System** 负责存储（写入 `preferences` slice，MVP 键名：`"sfx_volume"` 和 `"music_volume"`，均为 `String` 类型，`float [0.0, 1.0]`，默认 `1.0`，per ADR-0001 Decision 3）；AudioSystem 通过 `call_deferred` 在 `_ready()` 后读取并应用，不自己写文件。注意：键必须为 `String` 常量（非 `StringName`），因 JSON 解析后 Dictionary 键类型为 `String`。

8. **iOS Ring/Silent 开关**：遵守 iOS 物理静音开关——开关拨到静音时，BGM 和所有 SFX 均静音，与系统默认行为一致。Godot 在 iOS 上默认遵守此开关，无需额外代码。`play_loop(&"non_shred_event")` 降级为单次 `play()`，打印警告日志；MVP 中 `play_loop` 的合法键只有 `&"shred_loop"`。

   **OS 通知订阅方式**（per ADR-0002 pattern）：AudioSystem 通过 `_notification(what)` 覆写方法直接响应 OS `NOTIFICATION_APPLICATION_PAUSED` 和 `NOTIFICATION_APPLICATION_FOCUS_IN`，**不通过 LifecycleService 信号订阅**。这与 Persistence / Input / Haptic 的同侪模式一致——Foundation Autoloads 各自直接订阅 OS 通知，不通过 Lifecycle 转发。

9. **音触发射顺序契约（镜像 haptic-system.md F-1）**：当一个 Audio 事件键在上方目录的 "Haptic 对位" 列存在配对触觉时，下游系统必须在同一回调中先调 `AudioSystem.play()`，**延迟 `AUDIO_LEAD_MS`（默认 35 ms，真机校准后回填）后**再调 `Haptic.play()`，使两者**感知到达**时刻差落入 ±30 ms 窗口。理由：iOS 音频管线延迟（~40 ms）远大于 Taptic Engine 延迟（~5 ms），API 同时调用会导致玩家"先摸后听"。MVP 实现建议在调用方用 `await get_tree().create_timer(AUDIO_LEAD_MS / 1000.0).timeout`。完整公式 / 变量见 `design/gdd/haptic-system.md` Formulas F-1；调用方约定由 Juice Cookbook (#13) 在 Wave 2 标准化。

   ```gdscript
   # 标准调用模式（下游系统）
   AudioSystem.play(&"lever_pull")
   await get_tree().create_timer(AUDIO_LEAD_MS / 1000.0).timeout
   Haptic.play(&"lever_lock")
   ```

10. **`is_ready()` 公开方法**（per ADR-0001 Foundation Autoload 接口契约）：暴露 `func is_ready() -> bool`，在 `_ready()` 完成后返回 `true`，供 LifecycleService 在 App Ready 判定中查询（Core Rule 2）。此契约由 ADR-0001 Decision 1 锁定，不得移除或改名。实现：内部持有 `var _is_ready: bool = false`，在 `_ready()` 末尾无条件设为 `true`——**BGM 资源为 null 或 BGM 启动失败不阻塞 Foundation 就绪**，BGM 失败仅影响音效体验，不应阻止整个 App 启动。若 BGM 资源为 null，`push_error()` 后继续执行，`_is_ready = true` 照常设置。

### Sound Design Brief（Per-Event 音色规格）

> 此节是声音设计师（或 AI 工具）生成每个 SFX 资产的最低规格。每个字段均为必填——不允许"待定"。

| 事件键 | 时长估算 | 频率特征 | 情感目标 | 参考音源 |
|--------|---------|---------|---------|---------|
| `lever_drag` | 连续音（随拖拽持续）~0.5–2s | 低-中频摩擦声；轻微哑音质感 | 张力渐增；"这台机器在抵抗，但在屈服" | 慢速拉开抽屉的木制摩擦声 |
| `lever_pull` | 短促，~80–150ms | 低频冲击主体 + 中频"咔嚓"金属机械感 | 决定性一击；"到达了" | 老式打孔机下压感；机械键盘底触感 |
| `shred_start` | ~300–500ms | 低频电机启动"嗡嗡"从无到有 | 机器苏醒；"工作开始了" | 旧式搅拌机启动；收音机管加热 |
| `shred_loop` | 无限循环（至 shred_end） | 中低频连续研磨；有纹理节奏感，非单调白噪声 | ASMR 满足感；机器认真工作；过程即享受 | 碎纸机连续工作音；石磨研磨声 |
| `shred_end` | ~400–600ms | 低频电机减速消失 + 轻微金属余震 | 完工；"机器可以歇息了" | 搅拌机停止后的惯性转动 |
| `reveal_pop` | 短促，~120–200ms | 中高频清脆"叮咚"；轻微混响尾巴（~300ms 衰减）| 惊喜揭晓；"小礼物被打开的瞬间" | 精钢餐具轻敲；风铃单音 |
| `product_land` | 短促，~100–200ms | 中低频实体碰撞感；圆润而不刺耳 | 产物真实存在；有重量 | 小木块轻落桌面；豆包入盘 |
| `shelf_add` | 短促，~80–150ms | 轻柔中频"嗒"；比 product_land 更轻 | 收纳满足感；"整齐地放好了" | 书本入书架；精装卡带入盒 |
| `BGM_main_loop` | 无限循环 | 低频环境嗡鸣 + 轻微机械齿轮纹理；非旋律性 | 机器"存在感"环境音；玩家不会主动注意，但去掉会感觉空洞 | 工坊环境音；老式钟表机芯运转声 |

**生产注意**：`lever_drag` 为连续音，需要可无缝循环的音频资产（loop point 在摩擦质感稳定后）。`shred_loop` 的纹理节奏感是关键——单调白噪声不接受，需要有周期性细节（每 0.3–0.5s 一次轻微强调点）。

### States and Transitions

| 状态 | 描述 | 进入条件 | 退出条件 |
|------|------|---------|---------|
| `IDLE` | 无 SFX 播放，BGM 循环中 | 初始状态 | 任意 `play()` 调用 |
| `SFX_ACTIVE` | 一个或多个 SFX 正在播放 | `play()` 调用 | 所有 SFX `finished` 信号触发 |
| `SHREDDING` | shred_loop 正在循环 | `play_loop(&"shred_loop")` | `stop_loop(&"shred_loop")` |
| `PAUSED` | App 已进入后台，所有音频挂起 | `NOTIFICATION_APPLICATION_PAUSED`（OS 直接通知） | `NOTIFICATION_APPLICATION_FOCUS_IN`；恢复后回到 IDLE（shred_loop 已强制停止，不自动重启） |

> BGM 状态独立于 SFX 状态，始终在 Music 总线上循环，不受 SFX 状态影响。PAUSED 状态下 iOS/Android 平台自动静音；返回前台后 Godot 自动恢复音频流，BGM 无需 AudioSystem 显式重启。

### Interactions with Other Systems

| 调用方 | 调用的方法 | 触发时机 |
|--------|-----------|---------|
| Lever Interaction | `play(&"lever_drag")` → `play(&"lever_pull")` | 摇杆开始拖拽 → 越过触发阈值 |
| Shred Process | `play(&"shred_start")` → `play_loop(&"shred_loop")` → `stop_loop(&"shred_loop")` → `play(&"shred_end")` | 粉碎序列 |
| Silhouette Reveal | `play(&"reveal_pop")` → `play(&"product_land")` | 揭晓动画帧点 |
| Shelf Collection | `play(&"shelf_add")` | 产物飞入货架动画起点 |
| Persistence System | 提供 Music/SFX 音量偏好（读取） | AudioSystem `_ready()` 时初始化 |

> 所有调用均为单向——AudioSystem 不向调用方发回信号，不影响游戏逻辑。

## Formulas

### F-1：Volume Preference → dB 映射

`dB = 20 × log₁₀(v)`，当 v > 0；当 v = 0，dB = -80（静音哨兵值）

**变量表：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 音量偏好 | v | float | [0.0, 1.0] | 玩家滑块原始值，0.0=静音，1.0=最大 |
| dB 增益 | dB | float | [-80, 0] | 传入 `AudioServer.set_bus_volume_db()` 的实际值 |

**输出范围**：-80dB 到 0dB
- v=1.0 → 0dB；v=0.5 → -6dB；v=0.1 → -20dB；v=0.0 → -80dB

**示例**：玩家把 SFX 滑块拉到 0.7 → dB = 20×log₁₀(0.7) = -3.1dB

**理由**：人耳感知遵循对数律（韦伯-费希纳定律）；线性映射会让滑块后半段"无用"。-80dB 静音哨兵值避免 log₁₀(0)=-∞ 数学异常，是 Godot/FMOD 的通用惯例。

---

### F-2：BGM 默认音量偏移

> **前置**：先用玩家音量偏好值 `v` 代入 F-1，得到 `SFX_preference_db`，再代入本公式。两步顺序不可颠倒。

`BGM_db = SFX_preference_db + BGM_OFFSET`，BGM_OFFSET = -12dB（Tuning Knob）

**变量表：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| SFX 偏好 dB | SFX_preference_db | float | [-80, 0] | 由 F-1 映射的 SFX 总线实际值 |
| BGM 音量偏移 | BGM_OFFSET | float | 固定 -12 | Music 总线相对 SFX 总线的 dB 差值 |
| BGM 实际 dB | BGM_db | float | [-80, -12] | 传入 Music 总线的最终值，clamp -80 |

**输出范围**：clamp(-80, -12)

**示例**（首次启动，SFX 滑块=1.0）：BGM_db = 0 + (-12) = -12dB

**理由**：-12dB 差值（约 25% 感知音量比）是 ambient/BGM 处于 SFX 背景层的工程常见窗口（-10 到 -15dB）。让 BGM 作为"机器运转环境音"存在，不与 SFX 争夺注意力。安全 Tuning 范围：[-10, -18dB]。

---

### F-3：BGM 淡出时长（v1.0 — MVP 不实现）

> **⚠️ v1.0 范围**：MVP 中 BGM 永不淡出（Core Rule 6），本公式预留给 v1.0 场景切换。MVP 实现不需要 F-3。详见 Open Questions 节。

---

### F-4：SFX 对象池大小验证

`POOL_SIZE = 8`（固定常量，已验证充裕）

**并发时间轴分析（单次完整循环）：**

| 时间点 | 事件 | 累计并发 |
|--------|------|---------|
| T=0s | `lever_pull` | 1 |
| T=0.1s | `shred_start` | 1（lever_pull 已结束） |
| T=0.1–3s | `shred_loop`（专用节点，不占池） | 0 |
| T=3s | `shred_end` | 1 |
| T=3.1s | `reveal_pop` | 1 |
| T=3.3s | `product_land` | **2**（reveal_pop 可能仍在播） |
| T=4s | `shelf_add` | 1 |

**变量表：**

| 变量 | 值 | 说明 |
|------|-----|------|
| POOL_SIZE | 8 | AudioStreamPlayer 节点数量 |
| 正常最大并发 | 2 | 标准单循环峰值 |
| 极端异常并发 | ≤5 | 玩家快速重复操作 |
| 安全余量 | 3 | v1.0 UI 音效及扩展预留 |

**结论**：POOL_SIZE=8 已验证充裕，无需调整。shred_loop 使用独立专用节点是池保持 8 的关键——最长持续音效不占池资源。

池耗尽时回退策略（Edge Cases 章节记录）：LRU 抢占最早播放的节点。

## Edge Cases

- **如果 SFX 池耗尽（8 节点全占用）**：抢占最早开始播放的节点（LRU），用新音效覆盖。短 SFX（<500ms）的即时性优于"让旧音效播完"——玩家在快速操作时感受不到抢占，但会感受到新事件无响应。

- **如果调用 `AudioSystem.play("nonexistent_event")`**：静默忽略，打印编辑器警告日志（`push_warning()`），不 crash。防止键名拼写错误导致 App 崩溃；警告在开发期可见，发布包仍静默。

- **如果 `play_loop(&"shred_loop")` 在循环已在播放时再次调用**：忽略第二次调用，继续当前循环，不叠加。防止音量倍增失控。

- **如果 `stop_loop(&"shred_loop")` 在 shred_loop 未播放时调用**：静默忽略，不报错。调用方可能因时序原因在已停止后再调用 stop，此为正常防御性清理。

- **如果 `BGM_main_loop` 的 AudioStream 资源在 `_ready()` 时为 null**：打印错误日志，不播放 BGM，SFX 照常工作。BGM 缺失不应阻断核心循环。

- **如果 Persistence System 读回的音量偏好 v 超出 [0.0, 1.0]**：clamp 到 [0.0, 1.0] 后再传入 F-1 公式，打印警告日志，不覆盖存档（Persistence 负责修复）。

- **如果 App 收到 `NOTIFICATION_APPLICATION_PAUSED` 时 shred_loop 正在循环**：调用 `stop_loop(&"shred_loop")`。iOS/Android 后台不播音频，强制清除状态，避免前台恢复时出现孤立循环节点。前台恢复后由 Shred Process 自行决定是否重启粉碎序列，AudioSystem 不自动重启。

## Dependencies

**上游（本系统依赖）**：无——Foundation 层，零上游依赖。

**下游（依赖本系统的系统）**：

| 系统 | 方向 | 依赖性质 | 接口 |
|------|------|---------|------|
| Lever Interaction System | 下游依赖本系统 | 硬依赖（无音频则摇杆无反馈） | `play(&"lever_pull")` |
| Shred Process System | 下游依赖本系统 | 硬依赖（粉碎序列音效） | `play("shred_start/end")`, `play_loop/stop_loop(&"shred_loop")` |
| Silhouette Reveal System | 下游依赖本系统 | 硬依赖（揭晓叮咚） | `play(&"reveal_pop")`, `play(&"product_land")` |
| Shelf Collection System | 下游依赖本系统 | 硬依赖（入架音效） | `play(&"shelf_add")` |
| Mochi Character System | 下游依赖本系统 | 软依赖（角色反应音，MVP 待定） | TBD（MVP 中可能不调用） |
| Game Feel / Juice Cookbook | 下游引用本系统 | 规范依赖（引用 SFX 事件目录作为 Juice 义务依据） | 只读引用，不调用 API |
| Persistence System | 双向 | 软依赖（提供音量偏好数据） | AudioSystem 读取 preferences slice；Persistence 不调用 AudioSystem |

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 过高影响 | 过低影响 |
|------|--------|---------|---------|---------|
| `BGM_OFFSET` | -12dB | [-10, -18dB] | BGM 抢占 SFX 注意力，喧宾夺主 | BGM 几乎不可察觉，失去环境氛围 |
| `FADE_DURATION` | 800ms | [400, 1500ms] | 淡出过长，用户离开上下文后还在淡出 | 淡出过短，听感像"切断" |
| `SFX_POOL_SIZE` | 8 | [6, 12] | 占用更多内存/节点（可接受范围大） | <6 时并发 SFX 有丢失风险 |
| Music 总线默认音量（首次启动） | v=0.8 | [0.5, 1.0] | 无（已由 BGM_OFFSET 控制上限） | BGM 初次体验太静，失去环境感 |
| SFX 总线默认音量（首次启动） | v=1.0 | [0.8, 1.0] | 无（已是最大） | SFX 初次体验偏弱 |
| 单个 SFX 音量（per-event 资产调整） | 由音频资产 import 设置控制 | Godot 导入设置中调整 | 个别 SFX 过响，淹没其他事件 | 个别 SFX 过轻，玩家感知不到 |

### Juice 义务（引用 Juice Cookbook，Wave 2 填充后回填）

每个 SFX 事件是 Juice Cookbook 音频义务的具体实现点。Juice Cookbook 设计后，需回填以下内容：
- `lever_pull`：Cookbook 要求什么层次的声音"重量感"？（预期：低频冲击成分）
- `reveal_pop`：Cookbook 要求什么层次的"惊喜感"？（预期：明亮高频 + 轻微混响尾）
- `shred_loop`：Cookbook 要求粉碎音的 ASMR 质量标准是什么？（预期：连续、有纹理、不单调）

## Visual/Audio Requirements

本系统即音频基础设施，无视觉反馈需求；音频要求即本 GDD 全部内容。视觉层面：`AudioSystem` Autoload 节点无场景表示，不出现在任何场景树中，不需要 VFX 或美术资产。

## Acceptance Criteria

### 功能验证（可自动化）

- **AC-F-01**（Autoload 单例）：GIVEN 项目已配置 `AudioSystem` 为 Godot Autoload，WHEN 任意场景节点调用 `AudioSystem.play(&"lever_pull")`，THEN 调用不抛出 null reference 错误，`AudioSystem` 实例存在且可访问。

- **AC-F-02**（SFX 目录完整性）：GIVEN `AudioSystem` 已初始化，WHEN 依次调用 `play(&"lever_pull")`, `play(&"shred_start")`, `play(&"shred_end")`, `play(&"reveal_pop")`, `play(&"product_land")`, `play(&"shelf_add")`，THEN 每次调用无异常，对应事件键被识别，对应播放器节点 `playing == true`。

- **AC-F-03**（`play_loop` / `stop_loop` 往返）：GIVEN `shred_loop` 资源已加载，WHEN 调用 `AudioSystem.play_loop(&"shred_loop")`，THEN 专用节点开始循环播放（`playing == true`）；随后调用 `stop_loop(&"shred_loop")`，THEN 专用节点停止（`playing == false`）。

- **AC-F-04**（shred_loop 不占 SFX 池）：GIVEN `AudioSystem` 已初始化，WHEN `play_loop(&"shred_loop")` 被调用并且池中有其他 SFX 在播放，THEN 池的空闲节点数量不因 `play_loop` 调用而减少；shred_loop 节点独立于 8 节点池之外。

- **AC-F-05**（BGM 自动启动）：GIVEN 项目启动，WHEN `AudioSystem._ready()` 执行完毕，THEN `BGM_main_loop` 专用播放器自动开始循环播放（`playing == true`，`stream.loop == true`）。

- **AC-F-06**（总线独立）：GIVEN `AudioSystem` 已初始化，WHEN 将 Music 总线音量设为 -80dB，THEN SFX 总线不受影响，`play(&"lever_pull")` 仍在 SFX 总线上正常播放。

### 边界与防御（可自动化）

- **AC-B-01**（未知键静默警告）：GIVEN `AudioSystem` 已初始化，WHEN 调用 `play(&"nonexistent_event_xyz")`，THEN 不抛出异常；`push_warning()` 被调用；无播放器节点开始播放。

- **AC-B-02**（`play_loop` 重复调用忽略）：GIVEN `shred_loop` 已在循环中，WHEN 再次调用 `play_loop(&"shred_loop")`，THEN 专用节点仍只有一个播放实例，音量不叠加。

- **AC-B-03**（`stop_loop` 未播放时调用）：GIVEN `shred_loop` 未在播放，WHEN 调用 `stop_loop(&"shred_loop")`，THEN 不抛出异常，静默返回。

- **AC-B-04**（BGM 资源缺失不 crash）：GIVEN `BGM_main_loop` 的 AudioStream 资源故意设为 null（测试夹具），WHEN `_ready()` 执行，THEN 不抛出未处理异常；`push_error()` 被调用；`play(&"lever_pull")` 仍正常执行。

- **AC-B-05**（音量越界 clamp——上界）：GIVEN Persistence System 返回 `v = 1.5`，WHEN AudioSystem 读取并传入 F-1，THEN 实际使用值被 clamp 为 1.0；`push_warning()` 被调用；SFX 总线 dB 不超过 0dB。

- **AC-B-06**（音量越界 clamp——下界）：GIVEN Persistence System 返回 `v = -0.2`，WHEN AudioSystem 读取并传入 F-1，THEN 实际使用值被 clamp 为 0.0；SFX 总线 dB 设为 -80dB。

- **AC-B-07**（后台暂停强制停止 shred_loop）：GIVEN `shred_loop` 正在循环，WHEN `AudioSystem` 收到 `NOTIFICATION_APPLICATION_PAUSED`，THEN `shred_loop` 专用节点 `playing` 变为 `false`；前台恢复后 AudioSystem 不自动重启 `shred_loop`。

- **AC-B-08**（SFX 池 LRU 抢占）：GIVEN 8 个池节点全部 `playing == true`（测试夹具），WHEN 调用 `play(&"reveal_pop")`，THEN 最早开始播放的节点被抢占；无异常抛出；`reveal_pop` 开始播放。

- **AC-B-09**（F-1：v=0 静音哨兵值）：GIVEN v=0.0，WHEN 执行 F-1 计算，THEN 返回 -80.0dB（不产生 -∞ 或 NaN）。

- **AC-B-10**（F-1：边界值正确性）：GIVEN v=1.0，WHEN 执行 F-1，THEN 返回 0.0dB（误差 ≤ 0.01dB）；GIVEN v=0.5，THEN 返回约 -6.02dB；GIVEN v=0.1，THEN 返回约 -20.0dB。

- **AC-B-11**（F-2：BGM_OFFSET 应用）：GIVEN SFX 音量偏好 v=1.0，WHEN AudioSystem 初始化并应用 F-2，THEN Music 总线 dB = -12dB（误差 ≤ 0.01dB）；GIVEN v=0.0，THEN Music 总线 dB = -80dB（clamp 下限）。

- **AC-B-12**（`play_loop` 降级处理）：GIVEN `AudioSystem` 已初始化，WHEN 调用 `play_loop(&"lever_pull")`（非 shred_loop 键），THEN 降级为单次 `play(&"lever_pull")` 执行（播放器节点 `playing == true`，`stream.loop == false`）；`push_warning()` 被调用。

- **AC-B-13**（F-4：池大小验证）：GIVEN `AudioSystem` 已初始化，WHEN 检查 SFX 节点池，THEN 池中恰好有 8 个 `AudioStreamPlayer` 节点；shred_loop 专用节点不计入此 8 个。

### 音量与混音（手动测试）

- **AC-M-01**（F-1：对数感知线性度）：GIVEN 已连接监听耳机或外置音箱，WHEN 将 SFX 滑块从 0.0 匀速拖动到 1.0，THEN 感知音量变化速率均匀，无"前段无变化、后段骤增"现象；测试员签字确认。

- **AC-M-02**（F-2：BGM 不抢占 SFX）：GIVEN SFX 和 BGM 以默认音量播放，WHEN 触发 `lever_pull`、`reveal_pop`、`shred_loop` 等核心事件，THEN BGM 退入背景，SFX 清晰可辨；测试员确认 BGM 无喧宾夺主感。

- **AC-M-03**（首次启动默认混音）：GIVEN 全新安装，无存档（SFX v=1.0，Music v=0.8），WHEN 完成一次完整核心循环（写烦恼→拉杆→粉碎→揭晓→入架），THEN 所有 8 个 SFX 事件清晰可辨（含 `lever_drag`）；BGM 作为环境背景存在不抢戏；测试员确认整体混音合格。

- **AC-M-04**（SFX 静音时 BGM 独立播放）：GIVEN 玩家将 SFX 音量滑块拉至 0（v=0.0），WHEN 触发任意 SFX 事件，THEN 测试员听不到任何 SFX 声音；BGM 仍在 Music 总线独立播放。

- **AC-M-05**（iOS 静音开关遵守）：GIVEN 测试设备为 iOS，WHEN 将物理 Ring/Silent 开关拨到 Silent，THEN BGM 和所有 SFX 均静音；拨回 Ring 后声音恢复。

### 性能（手动/Profiler 辅助）

- **AC-P-01**（并发 SFX 峰值）：GIVEN Profiler 已挂接，WHEN 完整核心循环运行，THEN 正常循环下 SFX 池并发峰值 ≤ 2；快速重复操作压力测试峰值 ≤ 5；均不超过 POOL_SIZE=8。

- **AC-P-02**（BGM 帧预算）：GIVEN BGM 循环播放、60 FPS 目标，WHEN Godot Profiler 监测 `_process` 耗时，THEN BGM 播放期间帧预算占用 ≤ 0.1ms/帧。

- **AC-P-03**（AudioSystem 冷启动耗时）：GIVEN 项目冷启动，WHEN `AudioSystem._ready()` 执行完毕（含 BGM 启动、池初始化），THEN 耗时 ≤ 50ms；Profiler 记录存档。

- **AC-B-14**（`play_loop(&"BGM_main_loop")` 调用保护）：GIVEN `BGM_main_loop` 已在 AudioSystem 自管理中循环播放，WHEN 外部系统调用 `play_loop(&"BGM_main_loop")`，THEN 不叠加第二个播放实例；`push_warning()` 被调用，提示该键不应由外部系统调用；BGM 继续按原节奏播放。

- **AC-State-01**（PAUSED 状态进入）：GIVEN `shred_loop` 正在循环且 SFX 池有节点在播放，WHEN `NOTIFICATION_APPLICATION_PAUSED` 触发，THEN AudioSystem 进入 PAUSED 状态；`shred_loop` 专用节点 `playing == false`；iOS/Android 平台音频自动静音。

- **AC-State-02**（PAUSED → IDLE 恢复）：GIVEN AudioSystem 在 PAUSED 状态，WHEN `NOTIFICATION_APPLICATION_FOCUS_IN` 触发，THEN AudioSystem 返回 IDLE 状态；BGM 自动恢复（平台保证）；`shred_loop` 不自动重启（由 Shred Process 自主决定）。

## Open Questions

| 问题 | 责任方 | 待解时机 |
|------|--------|---------|
| 音量偏好持久化写入时机——调整后 App 被强杀，数据是否丢失？已由 Persistence Core Rule 7（后台自动保存订阅 OS 通知）隐式解决——关闭此问题，无需再追踪。 | ~~Persistence System GDD~~ | ✅ 已关闭 |
| F-2 BGM_OFFSET 调优时 clamp 上界语义：建议改为 `max(-80, SFX_db + BGM_OFFSET)` 取消固定上限，避免 Tuning 时的隐性截断 | 本 GDD design-review 时确认 | `/design-review` 独立 session |
| **F-3 BGM 淡出（v1.0 待实现）**：MVP 不实现，v1.0 场景切换时需要。公式定义见下：`FADE_DURATION = 800ms`，`dB_step = (BGM_db − (-80)) / (FADE_DURATION / frame_ms)`。安全 Tuning 范围 [400ms, 1500ms]。线性 dB 步进（对数感知下均匀）。示例（BGM=-12dB，60fps）：48 帧 × 1.42dB/帧 → 淡至 -80dB。 | v1.0 Audio GDD 修订 | v1.0 Sprint 规划时 |
