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
			change_crop_tile(tile, tile_data["crop"])
		Player.ActionType.HARVEST_CROP:
			print("harvesting crop (garden.gd)")
			change_crop_tile(tile, Player.Crops.EMPTY)
		Player.ActionType.DELETE_CROP:
			print("deleting crop (garden.gd)")
			change_crop_tile(tile, Player.Crops.EMPTY)
		Player.ActionType.WATER_CROP:
			print("watering crop (garden.gd)")
			change_soil_tile(tile, tile_data["soil"])
		Player.ActionType.FERTILIZE_SOIL:
			print("fertilizing soil (garden.gd)")
			change_soil_tile(tile, tile_data["soil"])
		Player.ActionType.GROW_CROP:
			print("growing crop (garden.gd)")
			if tile_data["crop"] == Player.Crops.EMPTY:
				push_error("no crop to grow")
			else:
				change_crop_tile(tile, tile_data["crop"], tile_data["crop_state"])
				print("crop at tile "+str(tile)+" has grown to state "+str(tile_data["crop_state"]))
				if tile_data["crop_state"] >= 3:
					print("crop at tile "+str(tile)+" is ready to harvest. Sending signal to robot to harvest.")
					# Keep harvest requests in the same per-tile action-bundle format as tick plans.
					Player.robotmove.emit([{ "tile_coords": tile, "actions": [Player.ActionType.HARVEST_CROP] }])

		Player.ActionType.REMOVE_MODIFIER:
			print("removing modifier from soil (garden.gd)")
			change_soil_tile(tile, tile_data["soil"])
		_:
			push_error("invalid action: "+str(action))

func change_crop_tile(tile_pos: Vector2i, tile_enum: Player.Crops, crop_state: int = 0) -> void:
	if tile_enum == Player.Crops.EMPTY:
		erase_cell(tile_pos)
	else:
		set_cell(tile_pos, 1, Vector2i(crop_state+1, tile_enum-2))

func change_soil_tile(tile_pos: Vector2i, soil: Array[Player.SoilState]) -> void:
	# Modifier rendering is centralized here; WATER_CROP, FERTILIZE_SOIL, and
	# REMOVE_MODIFIER all call this. For separate modifier layers, add aligned
	# TileMapLayers under "plots", then replace the combined tile below with
	# per-layer set_cell/erase_cell calls based on soil.has(WET/FERTILIZED).
	var tile_state := 0
	if soil.has(Player.SoilState.WET):
		tile_state += 1
	if soil.has(Player.SoilState.FERTILIZED):
		tile_state += 2
	self.get_parent().set_cell(tile_pos, 4, Vector2i(tile_state,0))
	print("soil tile at "+str(tile_pos)+" changed to "+str(soil))
