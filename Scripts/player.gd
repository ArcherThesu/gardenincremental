extends Node
static var instance: Node = null

# Each robot queue item groups all ordered actions for one tile.
signal robotmove(mvntarr: Array[Dictionary])
signal action_on_plot(action: ActionType, tile: Vector2i, seed_type: Crops)
signal apply_action_to_plot(action: ActionType, tile: Vector2i)
signal sell_crops(crop: Crops, amt: int)
signal buy_crops(crop: Crops, amt: int)

enum Direction {
	IDL,
	N,
	E,
	S,
	W
}

var dirstr = ["idle","N","E","S","W"]

enum ActionType {
	WATER_CROP,
	FERTILIZE_SOIL,
	IDLE,
	PLANT_SEED,
	HARVEST_CROP,
	DELETE_CROP,
	GROW_CROP,
	REMOVE_MODIFIER,
}

enum Crops {
	EMPTY,
	SOONNOTEMPTY,
	WHEAT,
	TOMATO
}

var cropstr := {
	Crops.EMPTY: "empty",
	Crops.SOONNOTEMPTY: "soonnotempty",
	Crops.WHEAT: "wheat",
	Crops.TOMATO: "tomato"
}

enum SoilState {
	WET,
	FERTILIZED,
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

var action_time_scale := 2

var tickspeed: float = 2 #seconds per tick
var growth_chance := .05
var water_growth_bonus := .05
var fertilizer_growth_bonus := .1
# change below to be a total modifier bonus, an extra multiplier based on total modifiers
var wetfertilizer_growth_bonus := water_growth_bonus + fertilizer_growth_bonus *(1+1.0/3.0) #1.33x multiplier for both water + fertilizer.
var water_robot_on := true
var fertilizer_robot_on := true
var plots := [] #filled with plot properties
var remove_modifier_chance := 0.3 #chance to remove modifier on tick, if modifier is present
var seed_bulk_buy := 1 # number of seeds to buy at once when buying seeds from seed selector
var sell_bulk_buy := 1
var currencies := {
	"money": 100.0,
	"seeds" : {
		Crops.WHEAT: 10,
		Crops.TOMATO: 0
	},
	"crops" : {
		Crops.WHEAT: 15,
		Crops.TOMATO: 0
	},
	"modifiers": {
		SoilState.WET: 10,
		SoilState.FERTILIZED: 10
	}

}


var robot_is_idle: bool = true


func _ready() -> void:
	set_empty_plot()
	action_on_plot.connect(do_action_on_plot)
	sell_crops.connect(sell_crop)
	buy_crops.connect(buy_seed)
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

func do_action_on_plot(action: ActionType, tile: Vector2i, seed_type: Crops) -> void:
	var tile_num := tile.x + tile.y * 5
	match (action):
		ActionType.PLANT_SEED:
			if seed_type == Crops.EMPTY or seed_type == Crops.SOONNOTEMPTY or not currencies["seeds"].has(seed_type):
				push_error("invalid seed type for queued planting: "+str(seed_type))
				return
			if currencies["seeds"][seed_type] <= 0:
				push_error("no seeds left")
				return
			if plots[tile_num]["crop"] != Crops.EMPTY && plots[tile_num]["crop"] != Crops.SOONNOTEMPTY:
				push_error("tile is already occupied")
				return
			currencies["seeds"][seed_type] -= 1
			print("planting seed (player.gd)")
			plots[tile_num]["crop"] = seed_type
			update_plot(tile_num, seed_type, 0, plots[tile_num]["soil"])
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
			var soil: Array[SoilState] = plots[tile_num]["soil"].duplicate()
			if soil.has(SoilState.WET):
				push_error("tile is already watered")
				return
			if currencies["modifiers"][SoilState.WET] <= 0:
				push_error("no wet modifiers left")
				return
			else:
				print("watering tile at "+str(tile))
				# Inventory and plot state change only when the action actually executes.
				soil.append(SoilState.WET)
				currencies["modifiers"][SoilState.WET] -= 1
				update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], soil)
		ActionType.FERTILIZE_SOIL:
			print("fertilizing soil (player.gd)")
			var soil: Array[SoilState] = plots[tile_num]["soil"].duplicate()
			if soil.has(SoilState.FERTILIZED):
				push_error("tile is already fertilized")
				return
			if currencies["modifiers"][SoilState.FERTILIZED] <= 0:
				push_error("no fertilizer modifiers left")
				return
			else:
				soil.append(SoilState.FERTILIZED)
				currencies["modifiers"][SoilState.FERTILIZED] -= 1
				update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], soil)
		ActionType.GROW_CROP:
			if plots[tile_num]["crop"] == Crops.EMPTY or plots[tile_num]["crop"] == Crops.SOONNOTEMPTY:
				return
			if plots[tile_num]["crop_state"] < 3:
				plots[tile_num]["crop_state"] += 1
				var soil: Array[SoilState] = plots[tile_num]["soil"].duplicate()
				if not soil.is_empty() and randf() < remove_modifier_chance:
					if soil.has(SoilState.FERTILIZED):
						soil.erase(SoilState.FERTILIZED)
					else:
						soil.erase(SoilState.WET)
					update_plot(tile_num, plots[tile_num]["crop"], plots[tile_num]["crop_state"], soil)
					apply_action_to_plot.emit(ActionType.REMOVE_MODIFIER, tile)

	apply_action_to_plot.emit(action, tile)
	print("action applied to plot: "+str(action)+" at tile: "+str(tile))

func set_empty_plot() -> void:
	for i in range(25):
		var soil: Array[SoilState] = []
		plots.append({
			"crop": Crops.EMPTY,
			"crop_state": 0,
			"soil": soil
		})

func update_plot(plotNum: int, crop: Crops, crop_state: int, soil: Array[SoilState]) -> void:
	plots[plotNum] = {
		"crop": crop,
		"crop_state": crop_state,
		"soil": soil
	}

#runs on a timer, every few seconds tehre's a chance for a crop to grow a stage, more chance when watered and/or fertilized
func tick() -> void:
	print("growing crops...")
	queue_tick_actions()

	for i in range(plots.size()):
		if plots[i]["crop"] != Crops.EMPTY && plots[i]["crop"] != Crops.SOONNOTEMPTY:
			var calc_growth_chance := growth_chance
			var soil: Array[SoilState] = plots[i]["soil"]
			if soil.has(SoilState.WET) and soil.has(SoilState.FERTILIZED): # change later for a multiplier on total modifiers
				calc_growth_chance += wetfertilizer_growth_bonus
			elif soil.has(SoilState.WET):
				calc_growth_chance += water_growth_bonus
			elif soil.has(SoilState.FERTILIZED):
				calc_growth_chance += fertilizer_growth_bonus
			if randf() < calc_growth_chance:
				if plots[i]["crop_state"] < 3:
					# Route growth through the same action handler that owns plot mutations.
					action_on_plot.emit(ActionType.GROW_CROP, Vector2i(i % 5, int(i / 5.0)), Crops.EMPTY)

func queue_tick_actions() -> void:
	if not robot_is_idle:
		return

	# Local counts reserve inventory during planning without spending it before execution.
	# Snapshot the selection so queued planting keeps its intended crop if the UI changes it later.
	var queued_seed: Crops = current_seed
	if not currencies["seeds"].has(queued_seed):
		push_error("cannot queue planting for invalid current seed: "+str(queued_seed))
		return
	var remaining_seeds: int = currencies["seeds"][queued_seed]
	var remaining_modifiers: Dictionary = currencies["modifiers"].duplicate()
	var actions_by_tile: Array[Dictionary] = []
	for i in range(plots.size()):
		var tile := Vector2i(i % 5, int(i / 5.0))
		var plot: Dictionary = plots[i]
		var soil: Array[SoilState] = plot["soil"]
		var actions: Array[int] = []

		# Seed planting is only planned for empty plots; modifiers may also target occupied plots.
		if plot["crop"] == Crops.EMPTY and remaining_seeds > 0:
			actions.append(ActionType.PLANT_SEED)
			remaining_seeds -= 1

		if water_robot_on and remaining_modifiers[SoilState.WET] > 0 and not soil.has(SoilState.WET):
			actions.append(ActionType.WATER_CROP)
			remaining_modifiers[SoilState.WET] -= 1
		if fertilizer_robot_on and remaining_modifiers[SoilState.FERTILIZED] > 0 and not soil.has(SoilState.FERTILIZED):
			actions.append(ActionType.FERTILIZE_SOIL)
			remaining_modifiers[SoilState.FERTILIZED] -= 1

		if not actions.is_empty():
			# One queue entry means the robot travels to this tile only once.
			var tile_actions := {"tile_coords": tile, "actions": actions}
			if actions.has(ActionType.PLANT_SEED):
				tile_actions["seed_type"] = queued_seed
			actions_by_tile.append(tile_actions)

	if not actions_by_tile.is_empty():
		print("sending grouped actions for "+str(actions_by_tile.size())+" plots")
		robotmove.emit(actions_by_tile)

func find_all_empty_plots() -> Array:
	var empty_plots = []
	for i in range(plots.size()):
		if plots[i]["crop"] == Crops.EMPTY:
			empty_plots.append(Vector2i(i % 5, int(i / 5.0)))
	return empty_plots

func change_current_seed(new_seed: Crops) -> void:
	if currencies["seeds"].has(new_seed):
		current_seed = new_seed
		print("current seed changed to: "+str(current_seed))
	else:
		push_error("invalid seed type: "+str(new_seed))

func sell_crop(crop_type: Crops, amount: int) -> void:
	if not crop_values.has(crop_type) or not currencies["crops"].has(crop_type):
		push_error("invalid crop type: "+str(crop_type))
		return
	if amount <= 0:
		push_error("sell amount must be greater than zero")
		return
	if currencies["crops"][crop_type] < amount:
		push_error("not enough crops to sell")
		return
	
	var actual_value = crop_values[crop_type] * amount #adding multipliers to selling crops would go here
	currencies["crops"][crop_type] -= amount
	currencies["money"] += actual_value

	create_floating_text("+$"+str(actual_value),Vector2(-256,172))
	print("sold "+str(amount)+" "+str(crop_type)+" for "+str(crop_values[crop_type] * amount)+" money")

func buy_seed(seed_type: Crops, amount: int) -> void:
	if not seed_costs.has(seed_type) or not currencies["seeds"].has(seed_type):
		push_error("invalid seed type: "+str(seed_type))
		return
	if amount <= 0:
		push_error("seed amount must be greater than zero")
		return
	var cost = seed_costs[seed_type] * amount
	if currencies["money"] < cost: #add sfx when not enough money...
		push_error("not enough money to buy seeds")
		return
	currencies["money"] -= cost
	currencies["seeds"][seed_type] += amount
	
	create_floating_text("+"+str(amount)+" " +cropstr[seed_type].capitalize()+" Seeds", Vector2(-256,172))
	print("bought "+str(amount)+" "+str(seed_type)+" seeds for "+str(cost)+" money")

func set_current_seed(seed_type: Crops) -> void:
	current_seed = seed_type

@onready var floating_txt_scene = preload("res://Scenes/floating_text.tscn")
func create_floating_text(txt: String, global_pos: Vector2) -> void:
	var new_txt = floating_txt_scene.instantiate()
	new_txt.play_text(txt,global_pos)
	get_tree().current_scene.add_child(new_txt)
