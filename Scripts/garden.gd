extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.apply_action_to_plot.connect(apply_action_to_tile)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func apply_action_to_tile(action: Player.ActionType, tile: Vector2i) -> void:
	var plot_num = tile.x + tile.y * 5
	var tile_data = Player.plots[plot_num]
	match (action):
		Player.ActionType.PLANT_SEED:
			print("planting seed (garden.gd)")
			change_crop_tile(tile, Player.current_seed)
		Player.ActionType.HARVEST_CROP:
			print("harvesting crop (garden.gd)")
			change_crop_tile(tile, Player.Crops.EMPTY)
		Player.ActionType.DELETE_CROP:
			print("deleting crop (garden.gd)")
			change_crop_tile(tile, Player.Crops.EMPTY)
		Player.ActionType.WATER_CROP:
			print("watering crop (garden.gd)")
			if tile_data["soil"] == Player.SoilState.WETFERTILIZED:
				change_soil_tile(tile, Player.SoilState.WETFERTILIZED)
			else:
				change_soil_tile(tile, Player.SoilState.WET)
		Player.ActionType.FERTILIZE_SOIL:
			print("fertilizing soil (garden.gd)")
			if tile_data["soil"] == Player.SoilState.WETFERTILIZED:
				change_soil_tile(tile, Player.SoilState.WETFERTILIZED)
			else:
				change_soil_tile(tile, Player.SoilState.FERTILIZED)
		Player.ActionType.GROW_CROP:
			print("growing crop (garden.gd)")
			if tile_data["crop"] == Player.Crops.EMPTY:
				push_error("no crop to grow")
			else:
				change_crop_tile(tile, tile_data["crop"], tile_data["crop_state"])
				print("crop at tile "+str(tile)+" has grown to state "+str(tile_data["crop_state"]))
				if tile_data["crop_state"] >= 3:
					print("crop at tile "+str(tile)+" is ready to harvest. Sending signal to robot to harvest.")
					Player.robotmove.emit([{ "tile_coords": tile, "action": Player.ActionType.HARVEST_CROP }])

		Player.ActionType.REMOVE_MODIFIER:
			print("removing modifier from soil (garden.gd)")
			if tile_data["soil"] == Player.SoilState.DRY:
				change_soil_tile(tile, Player.SoilState.DRY)
			elif tile_data["soil"] == Player.SoilState.WET:
				change_soil_tile(tile, Player.SoilState.WET)
		_:
			push_error("invalid action: "+str(action))

func change_crop_tile(tile_pos: Vector2i, tile_enum: Player.Crops, crop_state: int = 0) -> void:
	if tile_enum == Player.Crops.EMPTY:
		erase_cell(tile_pos)
	else:
		set_cell(tile_pos, 1, Vector2i(crop_state+1, tile_enum-2))

func change_soil_tile(tile_pos: Vector2i, tile_enum: Player.SoilState) -> void:
	self.get_parent().set_cell(tile_pos, 4, Vector2i(tile_enum,0))
	print("soil tile at "+str(tile_pos)+" changed to "+str(tile_enum))
