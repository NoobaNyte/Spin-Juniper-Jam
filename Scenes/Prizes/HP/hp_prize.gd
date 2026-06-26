extends BasePrize

func _ready() -> void:
	super._ready()
	PlayerGlobals.hp_powerup_cost = price
	PlayerGlobals.playerCurrentHealth = PlayerGlobals.hp_powerup_amount + 1 # used for starting with more lives by upping powerup amount in globals
	update_price()

func buy_prize():
	super.buy_prize()
	if bought:
		PlayerGlobals.hp_powerup_amount += 1
		
		PlayerGlobals.playerCurrentHealth = PlayerGlobals.hp_powerup_amount + 1
		
		quantity_owned += 1
		bought = false
