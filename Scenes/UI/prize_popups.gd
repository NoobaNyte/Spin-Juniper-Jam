extends BaseUIElement

var you_have_text
var prize_name_text
var prize_description_text

func _ready() -> void:
	you_have_text = find_child("YouHaveText", true, false)
	prize_name_text = find_child("PrizeNameText", true, false)
	prize_description_text = find_child("PrizeDescriptionText", true, false)
	fade_out(self, 0)

func update_text_boxes(quantity_owned: int, item_name: String, item_description: String):
	you_have_text.text = "YOU HAVE: " + str(quantity_owned)
	prize_name_text.text = item_name
	prize_description_text.text = item_description