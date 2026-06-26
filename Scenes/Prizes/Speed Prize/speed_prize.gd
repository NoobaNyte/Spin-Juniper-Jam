extends BasePrize

func _ready() -> void:
	super._ready()
	PlayerGlobals.speed_powerup_cost = price
	update_price()

func buy_prize():
	super.buy_prize()
	if bought:
		PlayerGlobals.speed_powerup_amount += 1
		
		if(PlayerGlobals.speedPrizeAccel):
			PlayerGlobals.increase_acceleration.emit(2)
			PlayerGlobals.increase_rotation_speed.emit(1.5)
			PlayerGlobals.speedPrizeAccel = !PlayerGlobals.speedPrizeAccel
		else:
			PlayerGlobals.increase_move_speed.emit(1)
			PlayerGlobals.increase_friction.emit(1)
			PlayerGlobals.speedPrizeAccel = !PlayerGlobals.speedPrizeAccel

		quantity_owned += 1
		bought = false
