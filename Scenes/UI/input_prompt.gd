extends BaseUIElement

var prompt_text: RichTextLabel

func _ready() -> void:
	prompt_text = find_child("BuyText", true, false)
	fade_out(self, 0)

func change_input_text_to(new_text: String):
	prompt_text.text = new_text
