extends BaseUIElement


func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().get_root().focus_exited.connect(_on_focus_lost)

func _on_focus_lost() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$RecaptureButton.show()

func _on_recapture_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$RecaptureButton.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$RecaptureButton.show()
