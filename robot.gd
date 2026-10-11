extends AnimatedSprite2D

@export var spd: float = 16.0

var movement_queue: Array = [] #fill with arrays with tile coords and action info

# flow of robot mvt:
# something will signal the robot to move, sending tile info + action info, putting that into the queue
# _process will check queue and run everything inside the queue.
# When processing something in the queue, start by grabbing tile info to move to the tile (grab tile info -> calculate how to move it -> move), then process any actions to be done there. 
# Once last action is done for that queue, begin processing next action.
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(200,88)
	updated_animations(Vector2i.ZERO)
	pass

func _process(_delta) -> void:
	pass

func move_to_tile(tile: Vector2i) -> void:
	pass

func calc_mvt(tile: Vector2i) -> Vector2i: #outputs vector2i of x and y that robot needs to move
	return Vector2i.ONE #temp

func do_action(action: Player.actionType, tile: Vector2i) -> void:
	speed_scale = Player.action_time_scale
	play("Interact")
	await animation_finished
	
	#do action here
	Player.action_on_plot.emit(action, tile)

	speed_scale = -Player.action_time_scale
	play("Interact")
	await animation_finished
	updated_animations(Vector2i.ZERO)
	pass

func updated_animations(mvt: Vector2i) -> void:

	var dir: int = Player.direction.IDL #IDL, N, E, S, W
	if mvt != Vector2i.ZERO:
		if abs(mvt.x) > abs(mvt.y):
			dir = Player.direction.E if mvt.x > 0 else Player.direction.W
		else:
			dir = Player.direction.N if mvt.y > 0 else Player.direction.S
		play(Player.dirstr[dir]+"_Move")
	else:
		play("default")

	pass
