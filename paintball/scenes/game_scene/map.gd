extends Node2D

# Player
const PLAYER_SCENE = preload("res://scenes/game_scene/player/player.tscn")
var users: Array[String] = ["P1", "P2"]
var player_instances: Array[CharacterBody2D] = []
@export var PLAYER1: Node2D
@export var PLAYER2: Node2D

@onready var P1Spawn: Marker2D = $Player1SpawnPoint
@onready var P2Spawn: Marker2D = $Player2SpawnPoint

# Base
@onready var base_p1: Marker2D = $P1BaseSpawnPoint
@onready var base_p2: Marker2D = $P2BaseSpawnPoint
const BASE_SCENE = preload("res://scenes/game_scene/base/base.tscn")
var p1_base_instance: Node2D = null
var p2_base_instance: Node2D = null

# Display color
@export var p1_color : Color = Color(255,0,0)
@export var p2_color : Color = Color(0,0,255)
@export var turret_color : Color = Color(0,255,0):
	set(value):
		turret_color = value
		turret_normalized_color = Vector3(turret_color.r, turret_color.g, turret_color.b) / 255.0 * Vector3(0,1,0)
@onready var turret_normalized_color: Vector3 = Vector3(turret_color.r, turret_color.g, turret_color.b) / 255.0 * Vector3(0,1,0)
@onready var p1_color_wheel: Sprite2D = $Player1ColorWheel
@onready var p2_color_wheel: Sprite2D = $Player2ColorWheel
@onready var turret_color_wheel: Sprite2D = $TurretColorWheel

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

# Pickable Paint Bucket
const BUCKET_SCENE = preload("res://scenes/game_scene/paint_bucket/paint_bucket.tscn")
@onready var bucket_spawn_p1: Marker2D = $P1PaintBucketSpawnPoint
@onready var bucket_spawn_p2: Marker2D = $P2PaintBucketSpawnPoint
@onready var bucket_spawn_turret: Marker2D = $TurretPaintBucketSpawnPoint

func _ready() -> void:
	#Display
	if p1_color_wheel and p1_color_wheel.material:
		p1_color_wheel.material = p1_color_wheel.material.duplicate()
	if p2_color_wheel and p2_color_wheel.material:
		p2_color_wheel.material = p2_color_wheel.material.duplicate()
	if turret_color_wheel and turret_color_wheel.material:
		turret_color_wheel.material = turret_color_wheel.material.duplicate()
	# Player
	PLAYER1.player_eliminated.connect(player_killed)
	PLAYER2.player_eliminated.connect(player_killed)
	# Load User
	"""
	var player1_instance = PLAYER_SCENE.instantiate()
	player1_instance.TEAM_ID = 1
	player1_instance.PLAYER_ID = 1
	player1_instance.control_type = "P1"
	player1_instance.global_position = P1Spawn.global_position
	player1_instance.player_eliminated.connect(player_killed)
	player_instances.append(player1_instance)
	add_child.call_deferred(player1_instance)
	
	var player2_instance = PLAYER_SCENE.instantiate()
	player2_instance.TEAM_ID = 2
	player2_instance.PLAYER_ID = 2
	player2_instance.control_type = "P2"
	player2_instance.global_position = P2Spawn.global_position
	player2_instance.player_eliminated.connect(player_killed)
	player_instances.append(player2_instance)
	add_child.call_deferred(player2_instance)
	"""
	# Base
	p1_base_instance = BASE_SCENE.instantiate()
	p1_base_instance.defender = PLAYER1
	p1_base_instance.team_id = 1
	p1_base_instance.base_color = p1_color
	p1_base_instance.enemy_color = p2_color
	p1_base_instance.turret_color = turret_color
	p1_base_instance.score = Vector3(255,0,0)
	add_child.call_deferred(p1_base_instance)
	p1_base_instance.global_position = base_p1.global_position
	
	p2_base_instance = BASE_SCENE.instantiate()
	p2_base_instance.defender = PLAYER2
	p2_base_instance.team_id = 2
	p2_base_instance.base_color = p2_color
	p2_base_instance.enemy_color = p1_color
	p2_base_instance.turret_color = turret_color
	p2_base_instance.score = Vector3(0,0,255)
	add_child.call_deferred(p2_base_instance)
	p2_base_instance.global_position = base_p2.global_position
	update_color_wheel()
	
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

	# Debug
	Bucket.spawn(
		self,
		bucket_spawn_p1.global_position,
		Vector3(0, 64, 0)
		)
	
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
	
func update_color_wheel() -> void:
	if p1_color_wheel and p1_color_wheel.material is ShaderMaterial:
		p1_color_wheel.material.set_shader_parameter("custom_color_middle", p1_base_instance.display_self_score)
		p1_color_wheel.material.set_shader_parameter("custom_color_left", p1_base_instance.display_enemy_score)
		p1_color_wheel.material.set_shader_parameter("custom_color_right", p1_base_instance.display_turret_score)
	if p2_color_wheel and p2_color_wheel.material is ShaderMaterial:
		p2_color_wheel.material.set_shader_parameter("custom_color_middle", p2_base_instance.display_self_score)
		p2_color_wheel.material.set_shader_parameter("custom_color_left", p2_base_instance.display_turret_score)
		p2_color_wheel.material.set_shader_parameter("custom_color_right", p2_base_instance.display_enemy_score)
	if turret_color_wheel and turret_color_wheel.material is ShaderMaterial:
		turret_color_wheel.material.set_shader_parameter("custom_color_middle", turret_normalized_color)
		turret_color_wheel.material.set_shader_parameter("custom_color_left", Vector3(0, 0 ,0))
		turret_color_wheel.material.set_shader_parameter("custom_color_right", Vector3(0, 0, 0))
	
func _get_platform(id: int) -> TileMapLayer:
	match id:
		1: return platform1_tile
		2: return platform2_tile
		_: return platform3_tile
	
#func change_platform() -> void:
	#for attempt in 100:
		#var spawn_length: int = randi_range(BREAKABLE_LENGTH_LOWEST, BREAKABLE_LENGTH_HIGHEST)
		#var spawn_tile: Vector2i = Vector2i(
								#randi_range(
									#BREAKABLE_BOUND_LEFT,
									#BREAKABLE_BOUND_RIGHT - spawn_length - 1
								#),
								#randi_range(
									#BREAKABLE_BOUND_TOP,
									#BREAKABLE_BOUND_BOTTOM
								#)
								#)
		#if check_spawn(spawn_tile, spawn_length):
			#print()
#
#func check_spawn(spawn_tile: Vector2i, spawn_length: int) -> bool:
	#var left_tile_x: int = spawn_tile.x
	#var tile_y: int = spawn_tile.y
	#var right_tile_x: int = spawn_tile.x + spawn_length - 1
	#for platform in platform_storage:
		#var existing_left_tile_x: Vector2i = platform[0].x
		#var existing_tile_y: Vector2i = platform[0].y
		#var existing_right_tile_x: Vector2i = platform[1].x
	#return true
	#

func set_platform(left_cell: Vector2i, right_cell: Vector2i, source_id: int) -> void:
	var length: int = right_cell.x - left_cell.x + 1
	for i in range(length):
		platform_tile.set_cell(left_cell + Vector2i(i, 0), source_id, PLATFORM_ATLAS)
