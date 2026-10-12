extends AnimatedSprite2D

@export var spd: float = 5 #tiles per second

# Each queue item contains one tile and its ordered actions:
# {"tile_coords": Vector2i, "actions": Array[Player.ActionType]}
var movement_queue: Array[Dictionary] = []
@onready var tile_map_plots := get_node("../backgroundgrass/plots")
var idle_position: Vector2i = Vector2i(216,88)
# flow of robot mvt:
# something will signal the robot to move, sending tile info + action info, putting that into the queue
# _process will check queue and run everything inside the queue.
# When processing something in the queue, start by grabbing tile info to move to the tile (grab tile info -> calculate how to move it -> move), then process any actions to be done there. 
# Once last action is done for that queue, begin processing next action.
# Called when the node enters the scene tree for the first time.

# to be implemented: if robot is moving to idle position and a new action pops up to movement queue, do it immediately.
func _ready() -> void:
	position = idle_position
	update_animations(Vector2i.ZERO)
	Player.robotmove.connect(add_to_movement_queue)
	pass

func _process(_delta) -> void:
	await process_movement_queue()

func add_to_movement_queue(mvntarr: Array) -> void:
	movement_queue.append_array(mvntarr)
	if not movement_queue.is_empty():
		Player.robot_is_idle = false

func validate_movement_process(movement_action: Dictionary) -> bool:
	# Validate a whole tile bundle once before moving, rather than validating each action.
	if not movement_action.has("tile_coords") or not movement_action.has("actions"):
		push_error("movement_action is missing tile_coords or actions: "+str(movement_action))
		return false
	var tile: Variant = movement_action["tile_coords"]
	var actions: Variant = movement_action["actions"]
	if not tile is Vector2i or not actions is Array or actions.is_empty():
		push_error("movement_action has invalid tile_coords or actions: "+str(movement_action))
		return false
	if tile.x < 0 or tile.x >= 5 or tile.y < 0 or tile.y >= 5:
		push_error("movement_action tile is outside the garden: "+str(movement_action))
		return false
	for action in actions:
		if not Player.ActionType.values().has(action):
			push_error("movement_action contains invalid action: "+str(movement_action))
			return false
	if actions.has(Player.ActionType.PLANT_SEED):
		var seed_type: Variant = movement_action.get("seed_type", null)
		if seed_type == null or not Player.currencies["seeds"].has(seed_type):
			push_error("planting movement_action is missing a valid seed_type: "+str(movement_action))
			return false
	return true

var queue_processing: bool = false
func process_movement_queue() -> void:
	if queue_processing:
		return
	queue_processing = true
	if movement_queue.size() > 0:
		var next_move = movement_queue[0]
		if not validate_movement_process(next_move):
			movement_queue.remove_at(0)
			queue_processing = false
			Player.robot_is_idle = movement_queue.is_empty()
			return
		var tile: Vector2i = next_move["tile_coords"]
		await move_to_tile(tile)
		# Execute all planned work at this stop before advancing to the next tile.
		for action in next_move["actions"]:
			var seed_type: Player.Crops = next_move.get("seed_type", Player.Crops.EMPTY)
			await do_action(action, tile, seed_type)
		movement_queue.remove_at(0)
	else:
		Player.robot_is_idle = true
		if Vector2i(position) != idle_position:
			print("robot is not at idle position, moving to idle position")
			var idle_tile = tile_map_plots.local_to_map(tile_map_plots.to_local(get_parent().to_global(idle_position)))
			await move_to_tile(idle_tile)
			update_animations(Vector2i.ZERO)
	Player.robot_is_idle = movement_queue.is_empty()
	queue_processing = false


func move_to_tile(tile: Vector2i) -> void:
	var target_global_position = tile_map_plots.to_global(tile_map_plots.map_to_local(tile))
	var new_position = get_parent().to_local(target_global_position)
	update_animations(new_position-position)

	#getting current tile to calculate distance to new tile, then using that to calculate duration of movement based on speed
	var current_tile = tile_map_plots.local_to_map(tile_map_plots.to_local(global_position))
	var duration = Vector2(current_tile).distance_to(Vector2(tile)) / spd

	var newtween = create_tween()
	newtween.tween_property(self, "position", new_position, duration).set_trans(Tween.TRANS_LINEAR)
	
	await newtween.finished

	return



func do_action(action: Player.ActionType, tile: Vector2i, seed_type: Player.Crops) -> void:
	if action == Player.ActionType.IDLE:
		return
	speed_scale = Player.action_time_scale
	play("Interact")
	await animation_finished
	
	#do action here
	Player.action_on_plot.emit(action, tile, seed_type)

	speed_scale = -Player.action_time_scale
	play("Interact")
	await animation_finished
	update_animations(Vector2i.ZERO)

func update_animations(mvt: Vector2i) -> void:
	speed_scale = spd
	var dir: int = Player.Direction.IDL #IDL, N, E, S, W
	if mvt != Vector2i.ZERO:
		if abs(mvt.x) > abs(mvt.y):
			dir = Player.Direction.E if mvt.x > 0 else Player.Direction.W
		else:
			dir = Player.Direction.S if mvt.y > 0 else Player.Direction.N
		play(Player.dirstr[dir]+"_Move")
	else:
		play("default")

	pass
