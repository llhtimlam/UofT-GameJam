extends Node2D

@export var PLAYER1: Node2D
@export var PLAYER2: Node2D
@onready var P1Spawn: Marker2D = $Player1SpawnPoint
@onready var P2Spawn: Marker2D = $Player2SpawnPoint

# Platform
@onready var platform_tile: TileMapLayer = $TileMapLayer
const PLATFORM_ATLAS: Vector2i = Vector2i(1,0)
var platform_spawn_interval: float = 0.0
var platform_lifetime: float = 0.0

var PLATFORM_LIFETIME: float = 5.0
var PLATFORM_VARIANCE: float = 2.0
var PLATFORM_OVERLAP_TIME: float = 2.0

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
	rope_instance_p1_base.setup_rope(Vector2i(-21,-23), Vector2i(-21,-9))
	var rope_instance_turret_left = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_left)
	rope_instance_turret_left.tilemap = rope_tile
	rope_instance_turret_left.setup_rope(Vector2i(-14,-27), Vector2i(-14,-9))
	var rope_instance_turret_right = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_right)
	rope_instance_turret_right.tilemap = rope_tile
	rope_instance_turret_right.setup_rope(Vector2i(14,-27), Vector2i(14,-9))
	var rope_instance_p2_base = ROPE_SCENE.instantiate()
	add_child(rope_instance_p2_base)
	rope_instance_p2_base.tilemap = rope_tile
	rope_instance_p2_base.setup_rope(Vector2i(21,-23), Vector2i(21,-9))
	# Setup Platform for spawning
	platform_spawn_interval = PLATFORM_LIFETIME - PLATFORM_VARIANCE
	
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
		var preset: int = randi_range(1, 3)
		if preset == 1:
			set_platform(Vector2i(-11, -15), Vector2i(-5, -15), 0)
			set_platform(Vector2i(-3, -18), Vector2i(3, -18), 0)
			set_platform(Vector2i(5, -16), Vector2i(11, -16), 0)
			break_preset1 = false
			break_preset2 = true
			break_preset3 = true
		if preset == 2:
			set_platform(Vector2i(-11, -9), Vector2i(-5, -9), 0)
			set_platform(Vector2i(-3, -18), Vector2i(3, -18), 0)
			set_platform(Vector2i(5, -16), Vector2i(11, -16), 0)
			break_preset1 = true
			break_preset2 = false
			break_preset3 = true
		if preset == 3:
			set_platform(Vector2i(-11, -20), Vector2i(-5, -20), 0)
			set_platform(Vector2i(-3, -19), Vector2i(3, -19), 0)
			set_platform(Vector2i(5, -21), Vector2i(11, -21), 0)
			break_preset1 = true
			break_preset2 = true
			break_preset3 = false
	
	if platform_lifetime <= 0.0:
		if break_preset1:
			set_platform(Vector2i(-11, -15), Vector2i(-5, -15), -1)
			set_platform(Vector2i(-3, -18), Vector2i(3, -18), -1)
			set_platform(Vector2i(5, -16), Vector2i(11, -16), -1)
		if break_preset2:
			set_platform(Vector2i(-11, -9), Vector2i(-5, -9), -1)
			set_platform(Vector2i(-3, -17), Vector2i(3, -17), -1)
			set_platform(Vector2i(5, -16), Vector2i(11, -16), -1)
		if break_preset3:
			set_platform(Vector2i(-11, -20), Vector2i(-5, -20), -1)
			set_platform(Vector2i(-3, -19), Vector2i(3, -19), -1)
			set_platform(Vector2i(5, -21), Vector2i(11, -21), -1)
	
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
