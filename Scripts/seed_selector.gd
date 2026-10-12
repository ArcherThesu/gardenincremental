extends Control

@onready var seed_button_template := preload("res://Scenes/seed_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()

	for crop in Player.Crops.values():
		if crop != Player.Crops.EMPTY && crop != Player.Crops.SOONNOTEMPTY:
			var seed_button = seed_button_template.instantiate()
			seed_button.name = str(crop)
			seed_button.set_meta("crop_type", crop)
			seed_button.get_node("seedBuyButtonContainer/Button").pressed.connect(_on_buy_button_click.bind(crop))
			seed_button.get_node("seedButtonContainer/Button").pressed.connect(_on_select_seed_button_click.bind(crop))
			set_seed(seed_button, crop)
			$ScrollContainer/VBoxContainer.add_child(seed_button)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_seed_buttons()
	pass

func set_seed(seed_button_instance: HBoxContainer, crop: Player.Crops) -> void:
	seed_button_instance.get_node("seedButtonContainer/Button").text = Player.cropstr[crop].capitalize()+" Seeds - "+str(Player.currencies["seeds"][crop])+"x"
	if Player.current_seed == crop:
		seed_button_instance.get_node("seedButtonContainer/Button").text += " (Selected)"
	seed_button_instance.get_node("seedBuyButtonContainer/Button").text = "Buy "+str(Player.seed_bulk_buy)+" Seeds ($"+str(Player.seed_costs[crop] * Player.seed_bulk_buy)+")"

func update_seed_buttons() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		var crop: Player.Crops = child.get_meta("crop_type")
		set_seed(child, crop)

func _on_select_seed_button_click(crop: Player.Crops) -> void:
	if Player.currencies["seeds"].has(crop) and Player.currencies["seeds"][crop] > 0:
		Player.change_current_seed(crop)

func _on_buy_button_click(crop: Player.Crops) -> void:
	if not Player.seed_costs.has(crop):
		push_error("no seed cost configured for crop: "+str(crop))
		return
	var buy_count: int = Player.seed_bulk_buy
	var seed_cost: int = Player.seed_costs[crop]
	if seed_cost > 0 and buy_count * seed_cost > Player.currencies["money"]:
		buy_count = int(Player.currencies["money"] / seed_cost)
	if buy_count > 0:
		Player.buy_crops.emit(crop, buy_count)