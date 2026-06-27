extends BaseUIElement

@export var slide_distance: float = 200.0
@export var slide_duration: float = 0 # set this after hide progress bar method call in ready

var ticket_point_template: PathFollow2D
var _tween: Tween = null
var _hidden_y: float = 0.0
var _shown_y: float = 0.0

var progress_bar: TextureProgressBar
var _progress_tween: Tween = null
var _active_ticket_points: Array = []

var _stopped: bool = false

func _ready() -> void:
	ticket_point_template = find_child("TicketPointTemplate", true, false)
	ticket_point_template.hide()
	progress_bar = find_child("TextureProgressBar", true, false)
	ProgressBarGlobals.add_ticket_point.connect(add_ticket_point)
	ProgressBarGlobals.show_progress_bar.connect(show_progress_bar)
	ProgressBarGlobals.hide_progress_bar.connect(hide_progress_bar)
	ProgressBarGlobals.start_progress_bar.connect(start_progress_bar)
	PlayerGlobals.game_over.connect(stop_progress_bar)
	_hidden_y = position.y - slide_distance
	_shown_y = position.y
	hide_progress_bar()
	slide_duration = 1.2
	
func add_ticket_point(progress_ratio: float = 0):
	var new_point := ticket_point_template.duplicate() as PathFollow2D
	ticket_point_template.get_parent().add_child(new_point)
	new_point.progress_ratio = progress_ratio
	new_point.show()
	_active_ticket_points.append(new_point)

func show_progress_bar():
	_play_tween(_shown_y)

func hide_progress_bar():
	_play_tween(_hidden_y)

func _play_tween(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", target_y, slide_duration)

func start_progress_bar():
	_stopped = false

	# Instantly clear old points without tween so nothing is visible when bar slides down
	for point in _active_ticket_points:
		point.queue_free()
	_active_ticket_points.clear()

	show_progress_bar()
	for ticket_point in ProgressBarGlobals.current_level_ticket_points:
		add_ticket_point(ticket_point.point_on_progress_bar_from_0_to_1)
	
	if _progress_tween:
		_progress_tween.kill()
	progress_bar.value = 0
	_progress_tween = create_tween().set_parallel(true)
	_progress_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	var total: float = ProgressBarGlobals.selected_level_length_in_seconds
	_progress_tween.tween_property(progress_bar, "value", 94.0, total)

	for ticket_point in ProgressBarGlobals.current_level_ticket_points:
		var ticket_reward_amount: int = ticket_point.ticket_reward_amount
		var ratio: float = ticket_point.point_on_progress_bar_from_0_to_1
		var delay: float = total * ratio
		_progress_tween.tween_callback(give_reward.bind(ticket_reward_amount)).set_delay(delay)

func stop_progress_bar() -> void:
	_stopped = true
	if _progress_tween:
		_progress_tween.kill()
		_progress_tween = null


func give_reward(ticket_reward_amount) -> void:
	if _stopped: return
	print("rewarding ", ticket_reward_amount, " tickets!")
	PlayerGlobals.tickets += ticket_reward_amount

	for point in _active_ticket_points:
		var sprite: Node = point.get_child(0)
		if sprite and sprite.has_method("remove"):
			sprite.remove()
			_active_ticket_points.erase(point)
			break
