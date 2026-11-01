extends CanvasLayer

const UI_SCENE = preload("res://scenes/game_scene/ui.tscn")
var ui_instance: CanvasLayer

# Color labels
@export var red: Color = Color.RED
@export var green: Color = Color.GREEN
@export var blue: Color = Color.BLUE
@export var player_1_color: Vector3 = Vector3.ZERO
@export var player_2_color: Vector3 = Vector3.ZERO

# Split screen
@onready var container1: SubViewportContainer = $SubViewportContainer1
@onready var container2: SubViewportContainer = $SubViewportContainer2
@onready var viewport1: SubViewport = $SubViewportContainer1/Viewport1
@onready var viewport2: SubViewport = $SubViewportContainer2/Viewport2
@onready var player1: CharacterBody2D = viewport1.get_node("Map1/Player")
@onready var player2: CharacterBody2D = viewport2.get_node("Map2/Player")
var combined: bool = false

# UI
#@onready var healthbar1: ColorRect = $PlayerUI1/ProgressBar
#@onready var healthbar2: ColorRect = $PlayerUI2/ProgressBar

var p1_ready: bool = false
var p2_ready: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Split screen
	var camera1 = player1.get_node("Camera2D")
	var camera2 = player2.get_node("Camera2D")

	camera1.custom_viewport = viewport1
	camera2.custom_viewport = viewport2

	camera1.make_current()
	camera2.make_current()

	player1.player_ready.connect(start_game)
	player2.player_ready.connect(start_game)
	
func start_game(player: CharacterBody2D, player_id: int, player_team: int) -> void:
	if player_team == 1:
		p1_ready = true
	elif player_team == 2:
		p2_ready = true
	if p1_ready and p2_ready:
		ui_instance = UI_SCENE.instantiate()
		add_child(ui_instance)
		container1.queue_free()
		container2.queue_free()


func _on_player_player_ready(player: CharacterBody2D, player_id: int, player_team: int) -> void:
	pass # Replace with function body.
