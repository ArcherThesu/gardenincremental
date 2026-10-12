extends Control

@onready var crop_button_template = preload("res://Scenes/crops_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()

	for crop in Player.currencies["crops"]:
		if crop == Player.Crops.EMPTY or crop == Player.Crops.SOONNOTEMPTY:
			continue
		var crop_button = crop_button_template.instantiate()
		crop_button.name = str(crop)
		crop_button.set_meta("crop_type", crop)
		crop_button.get_node("cropSellButtonContainer/Button").pressed.connect(_on_sell_button_click.bind(crop))
		crop_button.get_node("cropButtonContainer/Button").pressed.connect(_on_crop_button_click.bind(crop))
		set_crop(crop_button, crop)
		$ScrollContainer/VBoxContainer.add_child(crop_button)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_crop_buttons()
	pass

func set_crop(crop_button_instance: HBoxContainer, crop: Player.Crops) -> void:
	crop_button_instance.get_node("cropButtonContainer/Button").text = Player.cropstr[crop].capitalize()+" - "+str(Player.currencies["crops"][crop])+"x"
	var sellCount = Player.sell_bulk_buy
	if sellCount > Player.currencies["crops"][crop]:
		sellCount = Player.currencies["crops"][crop]
	crop_button_instance.get_node("cropSellButtonContainer/Button").text = "Sell "+str(sellCount)+" crops ($"+str(Player.crop_values[crop] * sellCount)+")"

func update_crop_buttons() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		var crop: Player.Crops = child.get_meta("crop_type")
		set_crop(child, crop)

func _on_sell_button_click(crop: Player.Crops) -> void:
	if not Player.currencies["crops"].has(crop):
		push_error("no crop inventory configured for crop: "+str(crop))
		return
	var sell_count: int = min(Player.sell_bulk_buy, Player.currencies["crops"][crop])
	if sell_count > 0:
		Player.sell_crops.emit(crop, sell_count)

func _on_crop_button_click(_crop: Player.Crops) -> void:
	pass
