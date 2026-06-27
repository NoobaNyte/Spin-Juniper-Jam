extends Sprite3D

var level_text: RichTextLabel
var reward_text: RichTextLabel

func _ready() -> void:
	level_text = find_child("LevelText", true, false)
	reward_text = find_child("RewardText", true, false)
	PlayerGlobals.update_selected_level.connect(update_text)
	update_text()

func update_text():
	match PlayerGlobals.selected_level:
		# default font size: 193
		1:
			level_text.text = "Carnival Fun"
			level_text.add_theme_font_size_override("normal_font_size", 135)
			reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_1_jackpot_amount)
		2:
			level_text.text = "Carnivorous Fun"
			level_text.add_theme_font_size_override("normal_font_size", 105)
			reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_2_jackpot_amount)
		3:
			level_text.text = "Wave Ride"
			level_text.add_theme_font_size_override("normal_font_size", 150)
			reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_3_jackpot_amount)
		4:
			level_text.text = "Midnight Festival"
			level_text.add_theme_font_size_override("normal_font_size", 100)
			reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_4_jackpot_amount)
		5:
			level_text.text = "Flammable"
			level_text.add_theme_font_size_override("normal_font_size", 145)
			reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_5_jackpot_amount)
