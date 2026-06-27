extends Sprite3D

var level_text: RichTextLabel
var reward_text: RichTextLabel

func _ready() -> void:
	level_text = find_child("LevelText", true, false)
	reward_text = find_child("RewardText", true, false)
	PlayerGlobals.update_selected_level.connect(update_text)
	update_text()

func update_text():
	level_text.text = "LEVEL " + str(PlayerGlobals.selected_level)
	match PlayerGlobals.selected_level:
		1: reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_1_jackpot_amount)
		2: reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_2_jackpot_amount)
		3: reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_3_jackpot_amount)
		4: reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_4_jackpot_amount)
		5: reward_text.text = "+[img=150x0]res://Assets/2D/Ticket Black Stroke.png[/img] " + str(WheelGlobals.level_5_jackpot_amount)
