extends CanvasLayer

@onready var P1Cols: ColorRect = $P1Cols
@onready var P2Cols: ColorRect = $P2Cols

@export var red: Color = Color.RED
@export var green: Color = Color.GREEN
@export var blue: Color = Color.BLUE

@export var player_1_color: Vector3 = Vector3.ZERO
@export var player_2_color: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var r = red.srgb_to_linear()
	var g = green.srgb_to_linear()
	var b = blue.srgb_to_linear()
	var col_matrix = Basis(Vector3(r.r, r.g, r.b),Vector3(g.r, g.g, g.b),Vector3(b.r, b.g, b.b))
	P1Cols.material.set_shader_parameter("colors", col_matrix)
	P2Cols.material.set_shader_parameter("colors", col_matrix)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	P1Cols.material.set_shader_parameter("cur_col", player_1_color/255.)
	P2Cols.material.set_shader_parameter("cur_col", player_2_color/255.)
