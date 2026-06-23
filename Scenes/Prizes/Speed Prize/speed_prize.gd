extends BasePrize

func _ready() -> void:
	super._ready()
	PlayerGlobals.speed_powerup_cost = price
	update_price()

func buy_prize():
	super.buy_prize()
	if bought:
		PlayerGlobals.speed_powerup_amount += 1
		quantity_owned += 1
		bought = false