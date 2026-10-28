extends TextureProgressBar

var Scale: float = 1
var Location: Vector2 = Vector2(0,0)
const BASE_SCALE: float = 40

func _process(_delta: float) -> void:
	texture_progress.height = Scale * BASE_SCALE
	texture_progress.width = Scale * BASE_SCALE
	scale = Vector2.ONE/Vector2(Scale, Scale)
	
	position = BASE_SCALE*Vector2(-.5,-.5) + Location
