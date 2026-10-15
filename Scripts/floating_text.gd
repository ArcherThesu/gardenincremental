extends Control

var default_font_size := 14
var min_font_size := 8
var floating_time := .5

var max_allowed_width = self.size.x



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func play_text(txt: String, global_pos: Vector2) -> void:
	var label = %txt
	print(self.global_position)
	self.global_position = global_pos
	label.text = txt
	print(self.global_position)

	var font: Font = label.get_theme_font("font")
	var current_size := default_font_size

	var text_width := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, current_size).x

	while current_size > min_font_size and text_width > max_allowed_width:
		current_size -= 1
		text_width = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, current_size).x

	label.add_theme_font_size_override("font_size", current_size)

	var float_tween = create_tween().set_parallel(true)
	float_tween.tween_property(self, "global_position", global_pos+ Vector2(0,-10),floating_time)
	float_tween.tween_property(self, "modulate:a", 0, max(floating_time-.1,0)).set_delay(.2)
	float_tween.chain().tween_callback(queue_free)
