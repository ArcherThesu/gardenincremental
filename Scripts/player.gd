extends Node

signal robotmove(mvntarr: Array)
signal action_on_plot(action: Player.actionType, tile: Vector2i)
signal apply_action_to_plot(action: Player.actionType, tile: Vector2i)

enum direction {
	IDL,
	N,
	E,
	S,
	W
}

var dirstr = ["idle","N","E","S","W"]

enum actionType {
	PLANT_SEED,
	HARVEST_CROP,
	DELETE_CROP,
	WATER_CROP,
	FERTILIZE_SOIL
}

enum crops {
	EMPTY,
	WHEAT,
	TOMATO
}

enum soil_state {
	DRY,
	WET,
	FERTILIZED,
	WETFERTILIZED,
}


var current_seed := crops.WHEAT

var action_time_scale := 1.0

var plots := [] #filled with plot properties

func _ready() -> void:
	set_empty_plot()
	action_on_plot.connect(do_action_on_plot)

func do_action_on_plot(action: actionType, tile: Vector2i) -> void:
	update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], plots[tile.x + tile.y * 5]["soil"])

func set_empty_plot() -> void:
	for i in range(25):
		plots.append({
			"crop": crops.EMPTY,
			"crop_state": 0,
			"soil": soil_state.DRY
		})

func update_plot(plotNum: int, crop: crops, crop_state: int, soil: soil_state) -> void:
	plots[plotNum] = {
		"crop": crop,
		"crop_state": crop_state,
		"soil": soil
	}
