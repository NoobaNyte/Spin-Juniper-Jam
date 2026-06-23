extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerGlobals.show_prize_prices.emit()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerGlobals.hide_prize_prices.emit()