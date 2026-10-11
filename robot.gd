extends AnimatedSprite2D

@export var spd: float = 16.0

var movement_queue: Array = [] #fill with Vector2 objs of tile coords


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(_delta) -> void:
	pass

func move_to_tile(tile: Vector2) -> void:
	pass

func calc_mvt(tile: Vector2) -> void:
	pass

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
