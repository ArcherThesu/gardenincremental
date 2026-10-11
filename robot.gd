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
	pass

func _process(_delta) -> void:
	pass

func move_to_tile(tile: Vector2) -> void:
	pass

func calc_mvt(tile: Vector2) -> Vector2: #outputs vector2 of x and y that robot needs to move
	return Vector2.ONE #temp

func do_action(action: Player.actionType) -> void:
	
	pass

func updated_animations(mvt: Vector2) -> void:

	var dir: int = Player.direction.IDL #IDL, N, E, S, W
	if mvt != Vector2.ZERO:
		if abs(mvt.x) > abs(mvt.y):
			dir = Player.direction.E if mvt.x > 0 else Player.direction.W
		else:
			dir = Player.direction.N if mvt.y > 0 else Player.direction.S
		play(Player.dirstr[dir]+"_Move")
	else:
		play("default")

	pass
