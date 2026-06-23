extends BaseUIElement

@onready var ticket_count_label: RichTextLabel = $MarginContainer/TicketCountLabel

func _ready() -> void:
	PlayerGlobals.update_tickets.connect(update_ticket_label)
	update_ticket_label(PlayerGlobals.tickets)

func update_ticket_label(new_ticket_count: int):
	ticket_count_label.text = "[img=90x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(new_ticket_count)
