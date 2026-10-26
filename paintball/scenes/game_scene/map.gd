extends Node2D

@export var PLAYER1: Node2D
@export var PLAYER2: Node2D
var player1Colour : Color = Color(0,0,0)
var player2Colour : Color = Color(0,0,0)
@onready var P1Spawn: Marker2D = $Player1SpawnPoint
@onready var P2Spawn: Marker2D = $Player2SpawnPoint

# Platform
@onready var platform_tile: TileMapLayer = $TileMapLayer
@onready var platform1_tile: TileMapLayer = $BreakablePlatform1
@onready var platform2_tile: TileMapLayer = $BreakablePlatform2
@onready var platform3_tile: TileMapLayer = $BreakablePlatform3
const PLATFORM_ATLAS: Vector2i = Vector2i(1,0)
var platform_spawn_interval: float = 0.0
var platform_lifetime: float = 0.0

var PLATFORM_LIFETIME: float = 8.0
var PLATFORM_VARIANCE: float = 1.0
var PLATFORM_OVERLAP_TIME: float = 5.0

var BREAKABLE_BOUND_TOP: int = -25
var BREAKABLE_BOUND_BOTTOM: int = -10
var BREAKABLE_BOUND_LEFT: int = -11
var BREAKABLE_BOUND_RIGHT: int = 11
var BREAKABLE_LENGTH_LOWEST: int = 4
var BREAKABLE_LENGTH_HIGHEST: int = 20
var BREAKABLE_MARGIN: int = 2

var platform_storage: Array[Array] = []
var break_preset1: bool = false
var break_preset2: bool = false
var break_preset3: bool = false
var preset: int = 3

# Rope
@onready var rope_tile: TileMapLayer = $RopeLayer
const ROPE_SCENE = preload("res://scenes/game_scene/rope/rope.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PLAYER1.player_eliminated.connect(player_killed)
	PLAYER2.player_eliminated.connect(player_killed)
	# Setup rope
	var rope_instance_p1_base = ROPE_SCENE.instantiate()
	add_child(rope_instance_p1_base)
	rope_instance_p1_base.tilemap = rope_tile
	rope_instance_p1_base.setup_rope(Vector2i(-23,-28), Vector2i(-23,-9))
	var rope_instance_turret_left = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_left)
	rope_instance_turret_left.tilemap = rope_tile
	rope_instance_turret_left.setup_rope(Vector2i(-23,-28), Vector2i(-23,-9))
	var rope_instance_turret_right = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_right)
	rope_instance_turret_right.tilemap = rope_tile
	rope_instance_turret_right.setup_rope(Vector2i(23,-28), Vector2i(23,-9))
	var rope_instance_p2_base = ROPE_SCENE.instantiate()
	add_child(rope_instance_p2_base)
	rope_instance_p2_base.tilemap = rope_tile
	rope_instance_p2_base.setup_rope(Vector2i(23,-28), Vector2i(23,-9))
	# Setup Platform for spawning
	platform1_tile.enabled = false
	platform2_tile.enabled = false
	platform3_tile.enabled = false
	
func player_killed(player):
	#TODO: mobile spawn point once capture points exist
	var spawnpoint
	if player.TEAM_ID == 1:
		spawnpoint = P1Spawn.position
	else:
		spawnpoint = P2Spawn.position
	player.position = spawnpoint
	player.reset_physics_interpolation()
	player.reset_state()

func _physics_process(delta: float) -> void:
	# Timer
	platform_spawn_interval = max(platform_spawn_interval - delta, 0.0)
	platform_lifetime = max(platform_lifetime - delta, 0.0)
	
	if platform_spawn_interval <= 0.0:
		platform_spawn_interval = randf_range(
							PLATFORM_LIFETIME - PLATFORM_VARIANCE,
							PLATFORM_LIFETIME + PLATFORM_VARIANCE
						)
						
		platform_lifetime = PLATFORM_OVERLAP_TIME # Must be smaller than platform_spawn_interval
		var current_preset = _get_platform(preset)
		current_preset.enabled = true
		break_preset1 = (preset != 1)
		break_preset2 = (preset != 2)
		break_preset3 = (preset != 3)
		preset = (preset % 3) + 1
	
	if platform_lifetime <= 0.0:
		if break_preset1:
			platform1_tile.enabled = false
		if break_preset2:
			platform2_tile.enabled = false
		if break_preset3:
			platform3_tile.enabled = false
	
func _get_platform(id: int) -> TileMapLayer:
	match id:
		1: return platform1_tile
		2: return platform2_tile
		_: return platform3_tile
	
func change_platform() -> void:
	for attempt in 100:
		var spawn_length: int = randi_range(BREAKABLE_LENGTH_LOWEST, BREAKABLE_LENGTH_HIGHEST)
		var spawn_tile: Vector2i = Vector2i(
								randi_range(
									BREAKABLE_BOUND_LEFT,
									BREAKABLE_BOUND_RIGHT - spawn_length - 1
								),
								randi_range(
									BREAKABLE_BOUND_TOP,
									BREAKABLE_BOUND_BOTTOM
								)
								)
		if check_spawn(spawn_tile, spawn_length):
			print()

func check_spawn(spawn_tile: Vector2i, spawn_length: int) -> bool:
	var left_tile_x: int = spawn_tile.x
	var tile_y: int = spawn_tile.y
	var right_tile_x: int = spawn_tile.x + spawn_length - 1
	for platform in platform_storage:
		var existing_left_tile_x: Vector2i = platform[0].x
		var existing_tile_y: Vector2i = platform[0].y
		var existing_right_tile_x: Vector2i = platform[1].x
	return true
	

func set_platform(left_cell: Vector2i, right_cell: Vector2i, source_id: int) -> void:
	var length: int = right_cell.x - left_cell.x + 1
	for i in range(length):
		platform_tile.set_cell(left_cell + Vector2i(i, 0), source_id, PLATFORM_ATLAS)
