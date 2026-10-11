extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.apply_action_to_plot.connect(apply_action_to_tile)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func apply_action_to_tile(action: Player.actionType, tile: Vector2i) -> void:
	var tile_data: TileData = get_cell_tile_data(tile)
	match (action):
		Player.actionType.PLANT_SEED:
			print("planting seed")
			change_crop_tile(tile, Player.current_seed)
		Player.actionType.HARVEST_CROP:
			print("harvesting crop")
			change_crop_tile(tile, Player.crops.EMPTY)
		Player.actionType.DELETE_CROP:
			print("deleting crop")
			change_crop_tile(tile, Player.crops.EMPTY)
		Player.actionType.WATER_CROP:
			print("watering crop")
			if tile_data.watered:
				push_error("tile is already watered")
			else:
				if tile_data.fertilized:
					change_soil_tile(tile, Player.soil_state.WETFERTILIZED)
				else:
					change_soil_tile(tile, Player.soil_state.WET)
		Player.actionType.FERTILIZE_SOIL:
			print("fertilizing soil")
			if tile_data.fertilized:
				push_error("tile is already fertilized")
			else:
				if tile_data.watered:
					change_soil_tile(tile, Player.soil_state.WETFERTILIZED)
				else:
					change_soil_tile(tile, Player.soil_state.FERTILIZED)
		_:
			push_error("invalid action: "+str(action))

func change_crop_tile(tile_pos: Vector2i, tile_enum: Player.crops, crop_state: int = 0) -> void:
	if tile_enum == Player.crops.EMPTY:
		erase_cell(tile_pos)
	else:
		set_cell(tile_pos, 1, Vector2i(tile_enum,crop_state+1))

func change_soil_tile(tile_pos: Vector2i, tile_enum: Player.soil_state) -> void:
	set_cell(tile_pos, 4, Vector2i(tile_enum,0))
