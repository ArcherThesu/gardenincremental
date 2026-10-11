extends AnimatedSprite2D

@export var spd: float = 1 #tiles per second


var movement_queue: Array = [[Vector2i(0, 3),Player.ActionType.PLANT_SEED],[Vector2i(1, 3),Player.ActionType.HARVEST_CROP]] #fill with arrays with tile coords and action info
@onready var tile_map_plots := get_node("../backgroundgrass/plots")
var idle_position: Vector2 = Vector2(200,88)
# flow of robot mvt:
# something will signal the robot to move, sending tile info + action info, putting that into the queue
# _process will check queue and run everything inside the queue.
# When processing something in the queue, start by grabbing tile info to move to the tile (grab tile info -> calculate how to move it -> move), then process any actions to be done there. 
# Once last action is done for that queue, begin processing next action.
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = idle_position
	update_animations(Vector2i.ZERO)
	Player.robotmove.connect(add_to_movement_queue)
	pass

func _process(_delta) -> void:
	await process_movement_queue()

func add_to_movement_queue(mvntarr: Array) -> void:
	movement_queue.append_array(mvntarr)

var queue_processing: bool = false
func process_movement_queue() -> void:
	if queue_processing:
		return
	queue_processing = true
	if movement_queue.size() > 0:
		var next_move = movement_queue[0]
		await move_to_tile(next_move[0])
		await do_action(next_move[1], next_move[0])
		movement_queue.remove_at(0)
	else:
		if position != idle_position:
			await move_to_tile(tile_map_plots.local_to_map(tile_map_plots.to_local(idle_position)))
	update_animations(Vector2i.ZERO)
	queue_processing = false


func move_to_tile(tile: Vector2i) -> void:
	var new_position = tile_map_plots.to_global(tile_map_plots.map_to_local(tile))
	update_animations(new_position-position)

	#getting current tile to calculate distance to new tile, then using that to calculate duration of movement based on speed
	var current_tile = tile_map_plots.local_to_map(tile_map_plots.to_local(global_position))
	var duration = Vector2(current_tile).distance_to(Vector2(tile)) / spd

	var newtween = create_tween()
	newtween.tween_property(self, "position", new_position, duration).set_trans(Tween.TRANS_LINEAR)
	await newtween.finished

	print("finished moving to tile: "+str(tile))
	return



func do_action(action: Player.ActionType, tile: Vector2i) -> void:
	if action == Player.ActionType.IDLE:
		return
	speed_scale = Player.action_time_scale
	play("Interact")
	await animation_finished
	
	#do action here
	Player.action_on_plot.emit(action, tile)

	speed_scale = -Player.action_time_scale
	play("Interact")
	await animation_finished
	update_animations(Vector2i.ZERO)

func update_animations(mvt: Vector2i) -> void:
	print("updating animations with mvt: "+str(mvt))
	var dir: int = Player.Direction.IDL #IDL, N, E, S, W
	if mvt != Vector2i.ZERO:
		if abs(mvt.x) > abs(mvt.y):
			dir = Player.Direction.E if mvt.x > 0 else Player.Direction.W
		else:
			dir = Player.Direction.N if mvt.y > 0 else Player.Direction.S
		play(Player.dirstr[dir]+"_Move")
	else:
		play("default")

	pass
