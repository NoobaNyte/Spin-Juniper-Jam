extends BaseUIElement

@onready var ticket_count_label: RichTextLabel = $MarginContainer/TicketCountLabel

var _displayed_tickets: float = 0.0
var _tick_tween: Tween = null

func _ready() -> void:
	PlayerGlobals.update_tickets.connect(update_ticket_label)
	_displayed_tickets = PlayerGlobals.tickets
	update_ticket_label(PlayerGlobals.tickets)

func update_ticket_label(new_ticket_count: int) -> void:
	if new_ticket_count > PlayerGlobals.tickets:
		pass
		#play ching sfx
	if _tick_tween:
		_tick_tween.kill()
	_tick_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tick_tween.tween_method(_set_displayed_tickets, _displayed_tickets, float(new_ticket_count), 0.6)

func _set_displayed_tickets(value: float) -> void:
	_displayed_tickets = value
	ticket_count_label.text = "[img=90x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(int(value))