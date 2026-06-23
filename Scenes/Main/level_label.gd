extends Sprite3D

var level_text: RichTextLabel

func _ready() -> void:
	level_text = find_child("LevelText", true, false)
	PlayerGlobals.update_selected_level.connect(update_level_text)

func update_level_text():
	level_text.text = "LEVEL " + str(PlayerGlobals.selected_level)
