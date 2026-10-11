extends Node
static var instance: Node = null

signal robotmove(mvntarr: Array)
signal action_on_plot(action: ActionType, tile: Vector2i)
signal apply_action_to_plot(action: ActionType, tile: Vector2i)

enum Direction {
	IDL,
	N,
	E,
	S,
	W
}

var dirstr = ["idle","N","E","S","W"]

enum ActionType {
	IDLE,
	PLANT_SEED,
	HARVEST_CROP,
	DELETE_CROP,
	WATER_CROP,
	FERTILIZE_SOIL
}

enum Crops {
	EMPTY,
	WHEAT,
	TOMATO
}

enum SoilState {
	DRY,
	WET,
	FERTILIZED,
	WETFERTILIZED,
}


var current_seed := Crops.WHEAT

var action_time_scale := 1.0

var plots := [] #filled with plot properties

func _ready() -> void:
	set_empty_plot()
	action_on_plot.connect(do_action_on_plot)

func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		# If a second one tries to spawn, destroy it immediately to prevent stale references
		queue_free() 
		
func do_action_on_plot(action: ActionType, tile: Vector2i) -> void:
	update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], plots[tile.x + tile.y * 5]["soil"])
	apply_action_to_plot.emit(action, tile)

func set_empty_plot() -> void:
	for i in range(25):
		plots.append({
			"crop": Crops.EMPTY,
			"crop_state": 0,
			"soil": SoilState.DRY
		})

func update_plot(plotNum: int, crop: Crops, crop_state: int, soil: SoilState) -> void:
	plots[plotNum] = {
		"crop": crop,
		"crop_state": crop_state,
		"soil": soil
	}
