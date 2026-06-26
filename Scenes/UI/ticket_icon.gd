extends Sprite2D

@export var swing_degrees: float = 20.0
@export var swing_duration: float = 1.5
@export var swing_pause: float = 0 # base pause at each end
@export var swing_randomness: float = 0.25 # how much degrees/duration can vary

var _swing_tween: Tween = null
var _remove_tween: Tween = null
var _swinging_right: bool = true

func _ready() -> void:
	_swing_once()

func _swing_once() -> void:
	if _remove_tween:
		return

	var degrees := swing_degrees + randf_range(-swing_randomness * swing_degrees, swing_randomness * swing_degrees)
	var duration := swing_duration + randf_range(-swing_randomness * swing_duration, swing_randomness * swing_duration)
	var pause := swing_pause + randf_range(0.0, swing_pause * 0.5)
	var target := degrees if _swinging_right else -degrees
	_swinging_right = !_swinging_right

	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing_tween.tween_property(self, "rotation_degrees", target, duration)
	_swing_tween.tween_interval(pause)
	_swing_tween.tween_callback(_swing_once)

func remove() -> void:
	if _swing_tween:
		_swing_tween.kill()
	if _remove_tween:
		_remove_tween.kill()
	_remove_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_remove_tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
	_remove_tween.tween_callback(queue_free)