extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_currency_list()

func update_currency_list() -> void:
	%mainCurrencyLabel.text = "Money: $"+str(Player.currencies["money"])+"\nWater: "+str(Player.currencies["modifiers"][Player.SoilState.WET])+"x\nFertilizer: "+str(Player.currencies["modifiers"][Player.SoilState.FERTILIZED])+"x"
