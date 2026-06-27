extends BaseUIElement

var level_complete_label
var earnings_label
var earnings_text

var _win_tween: Tween = null
var _tick_tween: Tween = null
var _displayed_earnings: float = 0.0

@export var pop_peak_duration: float = 0.6
var _shake_tween: Tween = null
var _base_position: Vector2

@export var shake_intensity: float = 10.0 # max pixel offset on x
@export var shake_vertical_ratio: float = 0.5 # y shake relative to x (0=no vertical, 1=equal)
@export var shake_speed: float = 0.5 # seconds per shake step

func _ready() -> void:
	WheelGlobals.start_win_screen.connect(start_win_screen)
	level_complete_label = find_child("LevelCompleteLabel", true, false)
	earnings_label = find_child("EarningsLabel", true, false)
	earnings_text = find_child("EarningsText", true, false)
	_reset()

func _reset() -> void:
	if _win_tween:
		_win_tween.kill()
	if _tick_tween:
		_tick_tween.kill()
	_displayed_earnings = 0.0
	level_complete_label.pivot_offset = level_complete_label.size / 2.0
	earnings_label.pivot_offset = earnings_label.size / 2.0
	level_complete_label.scale = Vector2.ZERO
	earnings_label.scale = Vector2.ONE
	earnings_label.modulate.a = 0.0
	earnings_label.scale = Vector2(0.85, 0.85)
	_set_earnings_text(0.0)
	fade_out(self, 0.0)


func start_win_screen() -> void:
	_reset()
	fade_in(self, 0.5)

	_win_tween = create_tween()

	# Scale in level complete label
	_win_tween.tween_property(level_complete_label, "scale", Vector2.ONE, 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Pause then begin earnings sequence
	_win_tween.tween_interval(0.1)
	_win_tween.tween_callback(_start_earnings_sequence)

func _start_earnings_sequence() -> void:
	if _tick_tween:
		_tick_tween.kill()

	var earnings: int
	match PlayerGlobals.selected_level:
		1: earnings = WheelGlobals.level_1_jackpot_amount
		2: earnings = WheelGlobals.level_2_jackpot_amount
		3: earnings = WheelGlobals.level_3_jackpot_amount
		4: earnings = WheelGlobals.level_4_jackpot_amount
		5: earnings = WheelGlobals.level_5_jackpot_amount

	earnings_label.pivot_offset = earnings_label.size / 2.0
	earnings_label.modulate.a = 0.0
	earnings_label.scale = Vector2(0.35, 0.35)

	_tick_tween = create_tween().set_parallel(true)
	_tick_tween.tween_property(earnings_label, "modulate:a", 1.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tick_tween.tween_property(earnings_label, "scale", Vector2.ONE, 3.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tick_tween.tween_method(_set_earnings_text, 0.0, float(earnings), 2.8) \
		.set_delay(0.0)
	_tick_tween.tween_callback(_pop_earnings.bind(earnings)).set_delay(3.0)

func _pop_earnings(earnings) -> void:
	if _tick_tween:
		_tick_tween.kill()
	_tick_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tick_tween.tween_property(earnings_label, "scale", Vector2(1.2, 1.2), 0.2)
	_tick_tween.tween_callback(_start_peak_shake)
	_tick_tween.tween_interval(pop_peak_duration)
	_tick_tween.tween_property(earnings_label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tick_tween.tween_callback(func():
		if _shake_tween:
			_shake_tween.kill()
			_shake_tween = null
		earnings_label.position = _base_position
)
	_tick_tween.tween_callback(func():
		await get_tree().create_timer(0.5).timeout
		fade_out(self, 0.5)
		await get_tree().create_timer(2.75).timeout
		PlayerGlobals.tickets += earnings
)

func _start_peak_shake() -> void:
	_base_position = earnings_label.position
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_method(_apply_shake, 0.0, 1.0, shake_speed)

func _apply_shake(_t: float) -> void:
	earnings_label.position = _base_position + Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity * shake_vertical_ratio, shake_intensity * shake_vertical_ratio)
	)

func _set_earnings_text(value: float) -> void:
	_displayed_earnings = value
	earnings_text.text = " " + str(int(value))
