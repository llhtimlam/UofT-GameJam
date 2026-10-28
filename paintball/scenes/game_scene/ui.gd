extends CanvasLayer

# Color labels
@onready var P1Cols: ColorRect = $P1Cols
@onready var P2Cols: ColorRect = $P2Cols
@export var red: Color = Color.RED
@export var green: Color = Color.GREEN
@export var blue: Color = Color.BLUE
@export var player_1_color: Vector3 = Vector3.ZERO
@export var player_2_color: Vector3 = Vector3.ZERO

# Split screen
const MERGE_PROPORTION = .75
const SPLIT_PROPORTION = .75
const SCREEN_MERGE_DIST = 5
const SCREEN_MERGE_DIST_2D = 15
@onready var container1: SubViewportContainer = $SubViewportContainer1
@onready var container2: SubViewportContainer = $SubViewportContainer2
@onready var viewport1: SubViewport = $SubViewportContainer1/Viewport1
@onready var viewport2: SubViewport = $SubViewportContainer2/Viewport2
@onready var player1: CharacterBody2D = viewport1.get_node("Map/Player1")
@onready var player2: CharacterBody2D = viewport1.get_node("Map/Player2")
var combined: bool = false

# UI
@onready var healthbar1: ColorRect = $PlayerUI1/ProgressBar
@onready var healthbar2: ColorRect = $PlayerUI2/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Color labels
	var r = red.srgb_to_linear()
	var g = green.srgb_to_linear()
	var b = blue.srgb_to_linear()
	var col_matrix = Basis(Vector3(r.r, r.g, r.b),Vector3(g.r, g.g, g.b),Vector3(b.r, b.g, b.b))
	P1Cols.material.set_shader_parameter("colors", col_matrix)
	P2Cols.material.set_shader_parameter("colors", col_matrix)
	
	# Split screen
	var camera1 = player1.get_node("Camera2D")
	var camera2 = player2.get_node("Camera2D")
	
	viewport2.world_2d = viewport1.world_2d
	camera1.custom_viewport = viewport1
	camera1.make_current()
	camera2.custom_viewport = viewport2
	camera2.make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Color labels
	P1Cols.material.set_shader_parameter("cur_col", player_1_color/255.)
	P2Cols.material.set_shader_parameter("cur_col", player_2_color/255.)
	
	# Split screen
	var p1_prop = player1.get_screen_transform().get_origin()/Vector2(get_window().size)
	var p2_prop = player2.get_screen_transform().get_origin()/Vector2(get_window().size)
	var diff = (p1_prop - p2_prop).abs()
	
	var center = (player1.position + player2.position)*.5
	var merge_dist = SCREEN_MERGE_DIST
	if get_window().size.y < player1.MIN_SCREEN_HEIGHT: #camera moves in y
		var covered_area = player1.MIN_SCREEN_HEIGHT - get_viewport().size.y
		center.y = clamp(center.y,player1.CAMERA_Y-covered_area,player1.CAMERA_Y+covered_area)
		merge_dist = SCREEN_MERGE_DIST_2D
	else:
		center.y = player1.CAMERA_Y
		diff.y = 0
	
	# Health
	healthbar1.anchor_right = player1.HEALTH/100.
	healthbar2.anchor_right = player2.HEALTH/100.
	
	if not combined and max(diff.x, diff.y) < MERGE_PROPORTION:
		var screen_correction = Vector2(get_window().size.x*.25,0) / player1.camera.zoom
		player1.screens_merging = true
		player1.camera_target = center - screen_correction
		player2.screens_merging = true
		player2.camera_target = center + screen_correction
		if (player1.camera_pos - player2.camera_pos + 2 * screen_correction).length() < merge_dist:
			combine_cameras(center)
			combined = true
	elif max(diff.x, diff.y) > SPLIT_PROPORTION:
		player1.screens_merging = false
		player2.screens_merging = false
		if combined:
			split_cameras()
			combined = false
	elif combined:
		player1.camera_target = center
		player2.camera_target = center + Vector2(get_window().size.x*.25,0) / player1.camera.zoom

func combine_cameras(center):
	player1.camera.reset_physics_interpolation()
	player1.camera_target = center
	player1.camera_pos = center
	player1.camera_i = Vector2.ZERO
	container1.anchor_right = 1.
	container2.anchor_left = 1.

func split_cameras():
	var screen_correction = Vector2(get_window().size.x*.25,0) / player1.camera.zoom
	player1.camera.reset_physics_interpolation()
	player1.camera_target = player1.camera_target - screen_correction
	player1.camera_pos = player1.camera_pos - screen_correction
	player1.camera_i = Vector2.ZERO
	container1.anchor_right = 0.499
	container2.anchor_left = 0.501
