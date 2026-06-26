extends BaseUIElement

@onready var ticket_count_label: RichTextLabel = $MarginContainer/TicketCountLabel

var _displayed_tickets: float = 0.0
var _tick_tween: Tween = null
var _color_tween: Tween = null
var _current_color: Color = Color.WHITE

func _ready() -> void:
	PlayerGlobals.update_tickets.connect(update_ticket_label)
	_displayed_tickets = PlayerGlobals.tickets
	_set_displayed_tickets(PlayerGlobals.tickets)

func update_ticket_label(new_ticket_count: int) -> void:
	if new_ticket_count > int(_displayed_tickets):
		play_win_sfx_after_pause()
   		

	var going_up := new_ticket_count > _displayed_tickets
	var target_color := Color.GREEN if going_up else Color.RED

	if _tick_tween:
		_tick_tween.kill()
	_tick_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tick_tween.tween_method(_set_displayed_tickets, _displayed_tickets, float(new_ticket_count), 0.9)

	if _color_tween:
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.tween_method(_set_text_color, _current_color, target_color, 0.15)
	_color_tween.tween_interval(0.6)
	_color_tween.tween_method(_set_text_color, target_color, Color.WHITE, 0.5)

func play_win_sfx_after_pause():
	await get_tree().create_timer(0.1).timeout
	AudioGlobals.play_win_tickets_sfx.emit()

func _set_text_color(color: Color) -> void:
	_current_color = color
	_set_displayed_tickets(_displayed_tickets)

func _set_displayed_tickets(value: float) -> void:
	_displayed_tickets = value
	var hex := _current_color.to_html(false)
	ticket_count_label.text = "[img=90x0]res://Assets/2D/Ticket Black Stroke.png[/img] [color=#" + hex + "]" + str(int(value)) + "[/color]"
