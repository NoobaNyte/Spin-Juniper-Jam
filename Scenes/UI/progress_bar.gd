extends BaseUIElement

@export var slide_distance: float = 200.0
@export var slide_duration: float = 0 # set this after hide progress bar method call in ready

var ticket_point_template: PathFollow2D
var _tween: Tween = null
var _hidden_y: float = 0.0
var _shown_y: float = 0.0

var progress_bar: TextureProgressBar
var _progress_tween: Tween = null

func _ready() -> void:
	ticket_point_template = find_child("TicketPointTemplate", true, false)
	ticket_point_template.hide()
	progress_bar = find_child("TextureProgressBar", true, false)
	ProgressBarGlobals.add_ticket_point.connect(add_ticket_point)
	ProgressBarGlobals.show_progress_bar.connect(show_progress_bar)
	ProgressBarGlobals.hide_progress_bar.connect(hide_progress_bar)

	_hidden_y = position.y - slide_distance
	_shown_y = position.y
	hide_progress_bar()
	slide_duration = 1.2
	

func add_ticket_point(progress_ratio: float = 0):
	var new_point := ticket_point_template.duplicate() as PathFollow2D
	ticket_point_template.get_parent().add_child(new_point)
	new_point.progress_ratio = progress_ratio
	new_point.show()

func show_progress_bar():
	_play_tween(_shown_y)
	start_progress_bar()

func hide_progress_bar():
	_play_tween(_hidden_y)

func _play_tween(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", target_y, slide_duration)


func start_progress_bar():
	if _progress_tween:
		_progress_tween.kill()
	progress_bar.value = 0
	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_progress_tween.tween_property(progress_bar, "value", 94.0, ProgressBarGlobals.selected_level_length_in_seconds)