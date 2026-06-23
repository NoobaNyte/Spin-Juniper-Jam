extends BasePrize

func _ready() -> void:
	super._ready()
	PlayerGlobals.hp_powerup_cost = price
	update_price()

func buy_prize():
	super.buy_prize()
