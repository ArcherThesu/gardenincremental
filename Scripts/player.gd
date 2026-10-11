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
var seeds := {
	Crops.WHEAT: 10,
	Crops.TOMATO: 5
}
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
	match (action):
		ActionType.PLANT_SEED:
			if seeds[current_seed] <= 0:
				push_error("no seeds left")
				return
			if plots[tile.x + tile.y * 5]["crop"] != Crops.EMPTY:
				push_error("tile is already occupied")
				return
			seeds[current_seed] -= 1
			print("planting seed (player.gd)")
			update_plot(tile.x + tile.y * 5, current_seed, 0, plots[tile.x + tile.y * 5]["soil"])
		ActionType.HARVEST_CROP:
			if plots[tile.x + tile.y * 5]["crop"] == Crops.EMPTY:
				push_error("no crop to harvest")
				return
			print("harvesting crop (player.gd)")
			update_plot(tile.x + tile.y * 5, Crops.EMPTY, 0, plots[tile.x + tile.y * 5]["soil"])
		ActionType.DELETE_CROP:
			if plots[tile.x + tile.y * 5]["crop"] == Crops.EMPTY:
				push_error("no crop to delete")
				return
			print("deleting crop (player.gd)")
			update_plot(tile.x + tile.y * 5, Crops.EMPTY, 0, plots[tile.x + tile.y * 5]["soil"])
		ActionType.WATER_CROP:
			print("watering crop (player.gd)")
			if plots[tile.x + tile.y * 5]["soil"] == SoilState.WET or plots[tile.x + tile.y * 5]["soil"] == SoilState.WETFERTILIZED:
				push_error("tile is already watered")
			else:
				if plots[tile.x + tile.y * 5]["soil"] == SoilState.FERTILIZED:
					update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], SoilState.WETFERTILIZED)
				else:
					update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], SoilState.WET)
		ActionType.FERTILIZE_SOIL:
			print("fertilizing soil (player.gd)")
			if plots[tile.x + tile.y * 5]["soil"] == SoilState.FERTILIZED or plots[tile.x + tile.y * 5]["soil"] == SoilState.WETFERTILIZED:
				push_error("tile is already fertilized")
			else:
				if plots[tile.x + tile.y * 5]["soil"] == SoilState.WET:
					update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], SoilState.WETFERTILIZED)
				else:
					update_plot(tile.x + tile.y * 5, plots[tile.x + tile.y * 5]["crop"], plots[tile.x + tile.y * 5]["crop_state"], SoilState.FERTILIZED)


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
