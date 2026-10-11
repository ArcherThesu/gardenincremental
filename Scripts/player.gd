extends Node
static var instance: Node = null

signal robotmove(mvntarr: Array[Dictionary]) #[{"tile_coords": Vector2i,"action": Player.ActionType}]
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
	FERTILIZE_SOIL,
	GROW_CROP
}

enum Crops {
	EMPTY,
	SOONNOTEMPTY,
	WHEAT,
	TOMATO
}

enum SoilState {
	DRY,
	WET,
	FERTILIZED,
	WETFERTILIZED,
}

var crop_values := {
	Crops.WHEAT: 5,
	Crops.TOMATO: 15
}

var seed_costs := {
	Crops.WHEAT: 3,
	Crops.TOMATO: 10
}

var current_seed := Crops.WHEAT

var action_time_scale := 5

var tickspeed: float = 2 #seconds per tick
var growth_chance := .05
var water_growth_bonus := .05
var fertilizer_growth_bonus := .1
var wetfertilizer_growth_bonus := water_growth_bonus + fertilizer_growth_bonus *(1+1.0/3.0) #1.33x multiplier for both water + fertilizer.

var plots := [] #filled with plot properties


var currencies := {
	"money": 100.0,
	"water": 3,
	"fertilizer": 5,
	"seeds" : {
		Crops.WHEAT: 166,
		Crops.TOMATO: 0
	},
	"crops" : {
		Crops.WHEAT: 0,
		Crops.TOMATO: 0
	}

}


var robot_is_idle: bool = true


func _ready() -> void:
	set_empty_plot()
	action_on_plot.connect(do_action_on_plot)
	tick_loop()

var loop_on: bool = true

func tick_loop() -> void:
	await get_tree().create_timer(tickspeed).timeout
	tick()

	if loop_on:
		tick_loop()


func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		# If a second one tries to spawn, destroy it immediately to prevent stale references
		queue_free() 

func print_plots() -> void:
	for i in range(25):
		print("plot "+str(i)+": "+str(plots[i]))

func print_currencies() -> void:
	print("currencies: "+str(currencies))

func do_action_on_plot(action: ActionType, tile: Vector2i) -> void:
	var tile_num := tile.x + tile.y * 5
	match (action):
		ActionType.PLANT_SEED:
			if currencies["seeds"][current_seed] <= 0:
				push_error("no seeds left")
				return
			if plots[tile_num]["crop"] != Crops.EMPTY && plots[tile_num]["crop"] != Crops.SOONNOTEMPTY:
				push_error("tile is already occupied")
				return
			currencies["seeds"][current_seed] -= 1
			print("planting seed (player.gd)")
			plots[tile_num]["crop"] = current_seed
			update_plot(tile_num, current_seed, 0, plots[tile_num]["soil"])
		ActionType.HARVEST_CROP:
			if plots[tile_num]["crop"] == Crops.EMPTY || plots[tile_num]["crop"] == Crops.SOONNOTEMPTY:
				push_error("no crop to harvest")
				return
			print("harvesting crop (player.gd)")
			# add logic to give player crops based on crop type and state
			currencies["crops"][plots[tile_num]["crop"]] += 1
			plots[tile_num]["crop"] = Crops.EMPTY
			update_plot(tile_num, Crops.EMPTY, 0, plots[tile_num]["soil"])
		ActionType.DELETE_CROP:
			if plots[tile_num]["crop"] == Crops.EMPTY || plots[tile_num]["crop"] == Crops.SOONNOTEMPTY:
				push_error("no crop to delete")
				return
			print("deleting crop (player.gd)")
			plots[tile_num]["crop"] = Crops.EMPTY
			update_plot(tile_num, Crops.EMPTY, 0, plots[tile_num]["soil"])
		ActionType.WATER_CROP:
			print("watering crop (player.gd)")
			if plots[tile_num]["soil"] == SoilState.WET or plots[tile_num]["soil"] == SoilState.WETFERTILIZED:
				push_error("tile is already watered")
			else:
				if plots[tile_num]["soil"] == SoilState.FERTILIZED:
					plots[tile_num]["soil"] = SoilState.WETFERTILIZED
					update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], SoilState.WETFERTILIZED)
				else:
					plots[tile_num]["soil"] = SoilState.WET
					update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], SoilState.WET)
		ActionType.FERTILIZE_SOIL:
			print("fertilizing soil (player.gd)")
			if plots[tile_num]["soil"] == SoilState.FERTILIZED or plots[tile_num]["soil"] == SoilState.WETFERTILIZED:
				push_error("tile is already fertilized")
			else:
				if plots[tile_num]["soil"] == SoilState.WET:
					plots[tile_num]["soil"] = SoilState.WETFERTILIZED
					update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], SoilState.WETFERTILIZED)
				else:
					plots[tile_num]["soil"] = SoilState.FERTILIZED
					update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], SoilState.FERTILIZED)

	apply_action_to_plot.emit(action, tile)
	print("action applied to plot: "+str(action)+" at tile: "+str(tile))
	print_plots()
	print_currencies()

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

#runs on a timer, every few seconds tehre's a chance for a crop to grow a stage, more chance when watered and/or fertilized
func tick() -> void:
	print("growing crops...")
	if currencies["seeds"][Crops.WHEAT] > 0:
		if robot_is_idle:
			var tiles = find_all_empty_plots()
			if tiles.size() > 0:
				if tiles.size() > currencies["seeds"][Crops.WHEAT]:
					tiles = tiles.slice(0, currencies["seeds"][Crops.WHEAT])
				var tiles_to_plant := []
				for tile in tiles:
					tiles_to_plant.append({ "tile_coords": tile, "action": ActionType.PLANT_SEED })
					if plots[tile.x + tile.y * 5]["soil"] == SoilState.DRY:
						if currencies["water"] > 0:
							tiles_to_plant.append({ "tile_coords": tile, "action": ActionType.WATER_CROP })
							currencies["water"] -= 1
						if currencies["fertilizer"] > 0:
							tiles_to_plant.append({ "tile_coords": tile, "action": ActionType.FERTILIZE_SOIL })
							currencies["fertilizer"] -= 1
				print("using "+str(tiles.size())+" seeds to plant wheat seeds at tiles: "+str(tiles))
				robotmove.emit(tiles_to_plant)
		else:
			print("robot is busy, cannot plant seeds now")
	for i in range(plots.size()):
		if plots[i]["crop"] != Crops.EMPTY && plots[i]["crop"] != Crops.SOONNOTEMPTY:
			var calc_growth_chance := growth_chance
			if plots[i]["soil"] == SoilState.WET:
				calc_growth_chance += water_growth_bonus
			elif plots[i]["soil"] == SoilState.FERTILIZED:
				calc_growth_chance += fertilizer_growth_bonus
			elif plots[i]["soil"] == SoilState.WETFERTILIZED:
				calc_growth_chance += wetfertilizer_growth_bonus
			if randf() < calc_growth_chance:
				if plots[i]["crop_state"] < 3:
					plots[i]["crop_state"] += 1
					apply_action_to_plot.emit(ActionType.GROW_CROP, Vector2i(i % 5, int(i / 5.0)))
					print("crop at plot "+str(i)+" has grown to state "+str(plots[i]["crop_state"]))

func find_all_empty_plots() -> Array:
	var empty_plots = []
	for i in range(plots.size()):
		if plots[i]["crop"] == Crops.EMPTY:
			empty_plots.append(Vector2i(i % 5, int(i / 5.0)))
	return empty_plots

func change_current_seed(new_seed: Crops) -> void:
	if new_seed in Crops:
		current_seed = new_seed
		print("current seed changed to: "+str(current_seed))
	else:
		push_error("invalid seed type: "+str(new_seed))

func sell_crop(crop_type: Crops, amount: int) -> void:
	if crop_type in Crops and crop_type != Crops.EMPTY and crop_type != Crops.SOONNOTEMPTY:
		if currencies["crops"][crop_type] >= amount:
			currencies["crops"][crop_type] -= amount
			currencies["money"] += crop_values[crop_type] * amount
			print("sold "+str(amount)+" "+str(crop_type)+" for "+str(crop_values[crop_type] * amount)+" money")
		else:
			push_error("not enough crops to sell")
	else:
		push_error("invalid crop type: "+str(crop_type))

func buy_seed(seed_type: Crops, amount: int) -> void:
	if seed_type in Crops and seed_type != Crops.EMPTY and seed_type != Crops.SOONNOTEMPTY:
		var cost = seed_costs[seed_type] * amount
		if currencies["money"] >= cost:
			currencies["money"] -= cost
			currencies["seeds"][seed_type] += amount
			print("bought "+str(amount)+" "+str(seed_type)+" seeds for "+str(cost)+" money")
		else:
			push_error("not enough money to buy seeds")
	else:
		push_error("invalid seed type: "+str(seed_type))