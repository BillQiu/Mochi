extends Node2D

# PROTOTYPE - NOT FOR PRODUCTION
# Project: Mochi (concept prototype 1)
# Question: Does the pull-lever → crush → silhouette → tap-reveal micro-loop
#           feel theatrically satisfying with placeholder visuals + SFX?
# Date: 2026-05-20
# Engine: Godot 4.6
#
# Confirmed if: 3+ first-time testers spontaneously pull the lever again
# within 10s of the first reveal, with no prompting.

# ── Constants ──────────────────────────────────────────────────────────────

const SCREEN_W := 720.0
const SCREEN_H := 1280.0

const COLOR_BG := Color("#f6f1e7")             # milky white
const COLOR_MACHINE := Color("#c8d36b")        # 90s appliance yellow-green
const COLOR_MACHINE_DARK := Color("#94a342")
const COLOR_MACHINE_DARKER := Color("#5e6a23")
const COLOR_HOPPER := Color("#262626")
const COLOR_LEVER_ARM := Color("#3a3a3a")
const COLOR_LEVER_HANDLE := Color("#d97757")   # orange handle
const COLOR_EYE_WHITE := Color("#ffffff")
const COLOR_EYE_BLACK := Color("#1a1a1a")
const COLOR_OUTPUT_TRAY := Color("#a8a094")
const COLOR_SILHOUETTE := Color("#1a1a1a")
const COLOR_HINT := Color("#7a7468")
const COLOR_STATUS := Color("#3a3a3a")

const LEVER_REST_Y := 0.0
const LEVER_PULL_MAX := 220.0
const LEVER_TRIGGER_Y := 180.0          # must pull at least this much
const LEVER_HANDLE_RADIUS := 36.0

const PRODUCT_COLORS := [
	Color("#e88c30"),  # warm orange
	Color("#7ab8a8"),  # soft teal
	Color("#d96b8c"),  # rose pink
	Color("#e8c93a"),  # gold
	Color("#9988d4"),  # lavender
]

const PRODUCT_SHAPES := ["circle", "star", "heart"]

enum State { IDLE, DRAGGING, CRUSHING, REVEALING, COMPLETE }

# ── State ──────────────────────────────────────────────────────────────────

var state: State = State.IDLE
var lever_offset: float = LEVER_REST_Y      # 0 = rest, positive = pulled down
var dragging: bool = false
var drag_start_mouse_y: float = 0.0
var drag_start_lever_offset: float = 0.0
var pull_count: int = 0
var last_reveal_time_ms: int = -100000
var time_to_next_pull_ms: int = -1

# ── Nodes ──────────────────────────────────────────────────────────────────

var machine_body: Polygon2D
var machine_inner: Polygon2D
var hopper: Polygon2D
var eye_left_white: Node2D
var eye_left_pupil: Polygon2D
var eye_right_white: Node2D
var eye_right_pupil: Polygon2D
var lever_arm: Polygon2D
var lever_handle: Node2D                    # circle drawn manually
var lever_handle_visual: Polygon2D
var output_tray: Polygon2D
var silhouette_node: Node2D
var product_node: Node2D
var hint_label: Label
var status_label: Label
var pull_count_label: Label
var inner_flash: Polygon2D
var debris: Node2D

# ── Audio ──────────────────────────────────────────────────────────────────

var click_player: AudioStreamPlayer
var crush_player: AudioStreamPlayer
var ding_player: AudioStreamPlayer
var thunk_player: AudioStreamPlayer

# ── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_scene()
	_build_audio()
	_enter_idle()

func _process(_delta: float) -> void:
	_update_lever_visual()

# ── Scene construction ─────────────────────────────────────────────────────

func _build_scene() -> void:
	# Status bar (top)
	var top_panel := ColorRect.new()
	top_panel.color = COLOR_BG
	top_panel.size = Vector2(SCREEN_W, 120)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_panel)

	status_label = Label.new()
	status_label.position = Vector2(40, 40)
	status_label.size = Vector2(640, 40)
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_color_override("font_color", COLOR_STATUS)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_label)

	pull_count_label = Label.new()
	pull_count_label.position = Vector2(40, 78)
	pull_count_label.add_theme_font_size_override("font_size", 18)
	pull_count_label.add_theme_color_override("font_color", COLOR_HINT)
	pull_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pull_count_label)

	# Machine body (centered)
	machine_body = _make_rect_polygon(
		Vector2(120, 320),
		Vector2(480, 540),
		COLOR_MACHINE
	)
	add_child(machine_body)

	# Machine bottom panel (slightly darker)
	var machine_floor := _make_rect_polygon(
		Vector2(120, 800),
		Vector2(480, 60),
		COLOR_MACHINE_DARK
	)
	add_child(machine_floor)

	# Inner viewing window (dark) — where crush happens
	machine_inner = _make_rect_polygon(
		Vector2(180, 480),
		Vector2(360, 240),
		COLOR_MACHINE_DARKER
	)
	add_child(machine_inner)

	# Inner flash (transparent, brightens during crush)
	inner_flash = _make_rect_polygon(
		Vector2(180, 480),
		Vector2(360, 240),
		Color(1.0, 0.95, 0.6, 0.0)
	)
	add_child(inner_flash)

	# Debris (children created during crush)
	debris = Node2D.new()
	debris.position = Vector2(360, 600)
	add_child(debris)

	# Hopper (mouth on top)
	hopper = _make_rect_polygon(
		Vector2(240, 280),
		Vector2(240, 50),
		COLOR_HOPPER
	)
	add_child(hopper)

	# Eyes (left + right)
	var eye_y := 380.0
	eye_left_white = _make_circle(Vector2(240, eye_y), 32, COLOR_EYE_WHITE)
	add_child(eye_left_white)
	eye_left_pupil = _make_rect_polygon(
		Vector2(230, eye_y - 8), Vector2(18, 18), COLOR_EYE_BLACK)
	add_child(eye_left_pupil)

	eye_right_white = _make_circle(Vector2(480, eye_y), 32, COLOR_EYE_WHITE)
	add_child(eye_right_white)
	eye_right_pupil = _make_rect_polygon(
		Vector2(470, eye_y - 8), Vector2(18, 18), COLOR_EYE_BLACK)
	add_child(eye_right_pupil)

	# Output tray (bottom)
	output_tray = _make_rect_polygon(
		Vector2(180, 880),
		Vector2(360, 90),
		COLOR_OUTPUT_TRAY
	)
	add_child(output_tray)

	# Silhouette + product containers (under tray plane)
	silhouette_node = Node2D.new()
	silhouette_node.position = Vector2(360, 920)
	silhouette_node.visible = false
	add_child(silhouette_node)

	product_node = Node2D.new()
	product_node.position = Vector2(360, 920)
	product_node.visible = false
	add_child(product_node)

	# Lever arm (right side of machine)
	# Pivot at top, hangs down. Origin = pivot point.
	var lever_pivot := Node2D.new()
	lever_pivot.position = Vector2(640, 420)
	add_child(lever_pivot)

	lever_arm = _make_rect_polygon(
		Vector2(-10, 0), Vector2(20, 180), COLOR_LEVER_ARM)
	lever_pivot.add_child(lever_arm)

	lever_handle = Node2D.new()
	lever_handle.position = Vector2(0, 180)
	lever_pivot.add_child(lever_handle)

	lever_handle_visual = _make_circle(Vector2.ZERO, LEVER_HANDLE_RADIUS, COLOR_LEVER_HANDLE)
	lever_handle.add_child(lever_handle_visual)

	# Hint label (bottom)
	hint_label = Label.new()
	hint_label.position = Vector2(40, 1180)
	hint_label.size = Vector2(640, 60)
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", COLOR_HINT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)

# ── Helpers: drawing primitives ────────────────────────────────────────────

func _make_rect_polygon(top_left: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(size.x, 0),
		top_left + size,
		top_left + Vector2(0, size.y),
	])
	return p

func _make_circle(center: Vector2, radius: float, color: Color, segments: int = 32) -> Node2D:
	var wrapper := Node2D.new()
	wrapper.position = center
	var p := Polygon2D.new()
	p.color = color
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	wrapper.add_child(p)
	return wrapper

# ── Audio synthesis ────────────────────────────────────────────────────────

func _build_audio() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = _make_tone(880.0, 0.07, "click")
	add_child(click_player)

	thunk_player = AudioStreamPlayer.new()
	thunk_player.stream = _make_tone(180.0, 0.18, "thunk")
	add_child(thunk_player)

	crush_player = AudioStreamPlayer.new()
	crush_player.stream = _make_tone(0.0, 1.4, "noise")
	add_child(crush_player)

	ding_player = AudioStreamPlayer.new()
	ding_player.stream = _make_tone(1568.0, 0.6, "ding")
	add_child(ding_player)

func _make_tone(freq: float, duration: float, kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) + 12345

	for i in samples:
		var t := float(i) / float(sample_rate)
		var env: float
		var v: float
		match kind:
			"click":
				env = exp(-t * 30.0)
				v = sin(t * freq * TAU) * env
			"thunk":
				env = exp(-t * 8.0)
				v = sin(t * freq * TAU) * env + 0.3 * sin(t * freq * 0.5 * TAU) * env
			"noise":
				# Crush rumble: filtered noise + low rumble + small attack peak
				var attack := clamp(t / 0.05, 0.0, 1.0)
				var decay := 1.0 - clamp((t - 0.05) / max(duration - 0.05, 0.001), 0.0, 1.0)
				env = attack * decay
				var noise := rng.randf_range(-1.0, 1.0)
				var rumble := sin(t * 80.0 * TAU) * 0.6
				v = (noise * 0.5 + rumble * 0.5) * env
			"ding":
				env = exp(-t * 5.0)
				var harmonic := sin(t * freq * TAU) + 0.5 * sin(t * freq * 2.0 * TAU)
				v = harmonic * env * 0.6
			_:
				v = 0.0
		var sample := int(clamp(v, -1.0, 1.0) * 32000)
		bytes.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

# ── State machine ──────────────────────────────────────────────────────────

func _set_state(s: State) -> void:
	state = s

func _enter_idle() -> void:
	_set_state(State.IDLE)
	dragging = false
	lever_offset = LEVER_REST_Y
	status_label.text = "IDLE — pull the lever"
	hint_label.text = "Drag the orange handle ↓ down ↓"
	silhouette_node.visible = false
	product_node.visible = false
	_clear_children(silhouette_node)
	_clear_children(product_node)
	_clear_children(debris)
	_update_pull_count_label()

func _enter_crushing() -> void:
	_set_state(State.CRUSHING)
	pull_count += 1
	_update_pull_count_label()
	status_label.text = "CRUSHING..."
	hint_label.text = ""
	thunk_player.play()
	crush_player.play()
	_spawn_debris()
	_flash_inner()
	_shake_machine()
	# Lever auto-resets while crushing
	var spring := create_tween()
	spring.tween_property(self, "lever_offset", LEVER_REST_Y, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Crush duration
	await get_tree().create_timer(1.4).timeout
	_enter_revealing()

func _enter_revealing() -> void:
	_set_state(State.REVEALING)
	status_label.text = "Tap the silhouette to reveal"
	hint_label.text = ""
	ding_player.play()
	last_reveal_time_ms = Time.get_ticks_msec()
	# Pick a random shape + color (deferred to product reveal)
	var shape_idx := randi() % PRODUCT_SHAPES.size()
	var color_idx := randi() % PRODUCT_COLORS.size()
	silhouette_node.set_meta("shape_idx", shape_idx)
	silhouette_node.set_meta("color_idx", color_idx)
	_draw_silhouette(shape_idx)
	silhouette_node.visible = true
	silhouette_node.scale = Vector2(0.2, 0.2)
	silhouette_node.position = Vector2(360, 870)  # spawn slightly above tray
	var pop := create_tween()
	pop.tween_property(silhouette_node, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.parallel().tween_property(silhouette_node, "position",
		Vector2(360, 920), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _enter_complete() -> void:
	_set_state(State.COMPLETE)
	status_label.text = "★ REVEALED — collected"
	hint_label.text = "Coming back to IDLE..."
	ding_player.play()
	silhouette_node.visible = false
	var shape_idx: int = silhouette_node.get_meta("shape_idx", 0)
	var color_idx: int = silhouette_node.get_meta("color_idx", 0)
	_draw_product(shape_idx, PRODUCT_COLORS[color_idx])
	product_node.visible = true
	product_node.scale = Vector2(0.2, 0.2)
	product_node.modulate.a = 0.0
	var pop := create_tween()
	pop.tween_property(product_node, "scale", Vector2(1.2, 1.2), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(product_node, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(product_node, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.4).timeout
	_enter_idle()
	# Track "time to next pull" measurement starts now
	time_to_next_pull_ms = 0

# ── Animations ─────────────────────────────────────────────────────────────

func _shake_machine() -> void:
	# Each node gets its own tween so the steps chain sequentially per node,
	# while all nodes shake concurrently with each other.
	var amp := 8.0
	var freq := 28.0
	var dur := 1.2
	var steps := int(dur * freq)
	var step_dur := 1.0 / freq
	var nodes := [machine_body, machine_inner, hopper, output_tray,
		eye_left_white, eye_left_pupil, eye_right_white, eye_right_pupil]

	for n in nodes:
		var node: Node2D = n
		var original: Vector2 = node.position
		var t := create_tween()
		for i in steps:
			var fade := 1.0 - float(i) / float(steps)
			var offset := Vector2(
				randf_range(-amp, amp),
				randf_range(-amp, amp) * 0.6
			) * fade
			t.tween_property(node, "position", original + offset, step_dur)
		t.tween_property(node, "position", original, step_dur)

func _flash_inner() -> void:
	var t := create_tween()
	t.tween_property(inner_flash, "color:a", 0.5, 0.05)
	t.tween_property(inner_flash, "color:a", 0.0, 0.4)
	t.set_loops(3)

func _spawn_debris() -> void:
	# A few small white "paper" rectangles tumbling in the inner window
	for i in 18:
		var d := _make_rect_polygon(
			Vector2(-6, -10), Vector2(12, 20),
			Color("#ffffff").lerp(Color("#dcd2b5"), randf())
		)
		d.position = Vector2(
			randf_range(-150.0, 150.0),
			randf_range(-100.0, 80.0)
		)
		d.rotation = randf_range(0.0, TAU)
		debris.add_child(d)
		var t := create_tween()
		var spin := randf_range(-12.0, 12.0)
		t.tween_property(d, "rotation", d.rotation + spin, 1.3)
		t.parallel().tween_property(d, "position",
			d.position + Vector2(randf_range(-60, 60), randf_range(60, 140)),
			1.3).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(d, "modulate:a", 0.0, 1.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _draw_silhouette(shape_idx: int) -> void:
	_clear_children(silhouette_node)
	silhouette_node.add_child(_draw_shape(PRODUCT_SHAPES[shape_idx], COLOR_SILHOUETTE))

func _draw_product(shape_idx: int, color: Color) -> void:
	_clear_children(product_node)
	product_node.add_child(_draw_shape(PRODUCT_SHAPES[shape_idx], color))

func _draw_shape(shape: String, color: Color) -> Node2D:
	var wrap := Node2D.new()
	match shape:
		"circle":
			wrap.add_child(_make_circle(Vector2.ZERO, 40, color))
		"star":
			var p := Polygon2D.new()
			p.color = color
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var r: float = 44.0 if i % 2 == 0 else 18.0
				pts.append(Vector2(cos(a), sin(a)) * r)
			p.polygon = pts
			wrap.add_child(p)
		"heart":
			# Approximate heart with two circles + triangle
			var c1 := _make_circle(Vector2(-15, -8), 22, color)
			var c2 := _make_circle(Vector2(15, -8), 22, color)
			wrap.add_child(c1)
			wrap.add_child(c2)
			var tri := Polygon2D.new()
			tri.color = color
			tri.polygon = PackedVector2Array([
				Vector2(-32, 0),
				Vector2(32, 0),
				Vector2(0, 38),
			])
			wrap.add_child(tri)
	return wrap

# ── Input ──────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_press(mb.position)
			else:
				_on_release()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if dragging and state == State.DRAGGING:
			var delta := mm.position.y - drag_start_mouse_y
			lever_offset = clamp(
				drag_start_lever_offset + delta,
				LEVER_REST_Y,
				LEVER_PULL_MAX
			)

func _on_press(pos: Vector2) -> void:
	match state:
		State.IDLE:
			# Hit-test lever handle
			var handle_world: Vector2 = _lever_handle_world_position()
			if pos.distance_to(handle_world) < LEVER_HANDLE_RADIUS * 1.6:
				dragging = true
				drag_start_mouse_y = pos.y
				drag_start_lever_offset = lever_offset
				_set_state(State.DRAGGING)
				click_player.play()
				status_label.text = "DRAGGING — pull all the way down"
				hint_label.text = ""
				if pull_count > 0 and time_to_next_pull_ms >= 0:
					var ms := Time.get_ticks_msec() - last_reveal_time_ms
					print("[METRIC] seconds_to_next_pull=", float(ms) / 1000.0)
					time_to_next_pull_ms = -1
		State.REVEALING:
			# Test if user tapped silhouette
			var s_pos: Vector2 = silhouette_node.position
			if pos.distance_to(s_pos) < 80.0:
				_enter_complete()

func _on_release() -> void:
	if state != State.DRAGGING:
		return
	dragging = false
	if lever_offset >= LEVER_TRIGGER_Y:
		_enter_crushing()
	else:
		# Not pulled far enough — spring back
		click_player.play()
		_set_state(State.IDLE)
		var t := create_tween()
		t.tween_property(self, "lever_offset", LEVER_REST_Y, 0.4) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		status_label.text = "IDLE — pull harder, all the way down"
		hint_label.text = "Drag the orange handle ↓ down ↓"

# ── Visual updates ─────────────────────────────────────────────────────────

func _update_lever_visual() -> void:
	if not is_instance_valid(lever_handle):
		return
	# Move lever handle relative to its pivot
	lever_handle.position.y = 180.0 + lever_offset
	# Stretch the arm visually so it stays connected
	lever_arm.scale.y = (180.0 + lever_offset) / 180.0

func _lever_handle_world_position() -> Vector2:
	# Pivot is at (640, 420). Handle relative position is (0, 180+lever_offset).
	return Vector2(640, 420 + 180.0 + lever_offset)

func _update_pull_count_label() -> void:
	pull_count_label.text = "Pulls: %d" % pull_count

# ── Utilities ──────────────────────────────────────────────────────────────

func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()
