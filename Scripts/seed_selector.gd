extends Control

@onready var seed_button_template := preload("res://scenes/seed_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()

	for crop in Player.Crops.values():
		if crop != Player.Crops.EMPTY && crop != Player.Crops.SOONNOTEMPTY:
			var seed_button = seed_button_template.instantiate()
			set_seed(seed_button, crop)
			$ScrollContainer/VBoxContainer.add_child(seed_button)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_seed_buttons()
	pass

func set_seed(seed_button_instance: HBoxContainer, crop: Player.Crops) -> void:
	seed_button_instance.get_node("seedButtonContainer/Button").text = Player.cropstr[crop].capitalize()+" Seeds - "+str(Player.currencies["seeds"][crop])+"x"
	seed_button_instance.get_node("seedBuyButtonContainer/Button").text = "Buy "+str(Player.seed_bulk_buy)+" Seeds ($"+str(Player.seed_costs[crop] * Player.seed_bulk_buy)+")"

func update_seed_buttons() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		var crop = Player.Crops.values()[child.get_index()+2]
		set_seed(child, crop)