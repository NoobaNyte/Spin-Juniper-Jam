extends BasePrize

func _ready() -> void:
	super._ready()
	PlayerGlobals.invincibility_powerup_cost = price
	update_iframes_seconds() # used for starting with more lives by upping powerup amount in globals
	update_price()

func buy_prize():
	super.buy_prize()
	if bought:
		PlayerGlobals.invincibility_powerup_amount += 1

		update_iframes_seconds()

		quantity_owned += 1
		bought = false

func update_iframes_seconds():
	# get 0.5 extra i frames for every powerup
	PlayerGlobals.playertIFrameSeconds = (float(PlayerGlobals.invincibility_powerup_amount) / 2) + 0.5