extends Node2D

# Player
const PLAYER_SCENE = preload("res://scenes/game_scene/player/player.tscn")
var users: Array[String] = ["P1", "P2"]
var player_instances: Array[CharacterBody2D] = []
@export var PLAYER: Node2D
@export var DUMMY: Node2D

@onready var P1Spawn: Marker2D = $Player1SpawnPoint
@onready var P2Spawn: Marker2D = $Player2SpawnPoint

# Base
const BASE_SCENE = preload("res://scenes/game_scene/base/base.tscn")
var p1_base_instance: Node2D = null
var p2_base_instance: Node2D = null
@onready var P1Base: Marker2D = $P1Base
@onready var P2Base: Marker2D = $P2Base
@onready var CloneWheel: Marker2D = $CloneSpawnPoint

# Platform
@onready var platform1: TileMapLayer = $Platform1
@onready var platform2: TileMapLayer = $Platform2
@onready var platform12a: TileMapLayer = $Platform12a
@onready var platform12b: TileMapLayer = $Platform12b
@onready var platform21a: TileMapLayer = $Platform21a
@onready var platform21b: TileMapLayer = $Platform21b
@onready var platform12: TileMapLayer = $Platform12
var PLATFORM_LIFETIME: float = 2.0
var PLATFORM_VARIANCE: float = 0.0
var PLATFORM_TRANSITION_TIME: float = 2.0
var PLATFORM_OVERLAP_TIME: float = 2.0

var current_platform: int = 1
var next_platform: int
var transition_step: int = 3
var platform_timer: float = 0.0

# Rope
@onready var rope_tile: TileMapLayer = $RopeLayer
const ROPE_SCENE = preload("res://scenes/game_scene/rope/rope.tscn")

# Pickable Paint Bucket
const BUCKET_SCENE = preload("res://scenes/game_scene/paint_bucket/paint_bucket.tscn")
@onready var bucket_spawn_p1: Marker2D = $P1PaintBucketSpawnPoint
@onready var bucket_spawn_p2: Marker2D = $P2PaintBucketSpawnPoint
@onready var bucket_spawn_turret: Marker2D = $TurretPaintBucketSpawnPoint


func _ready() -> void:
	# Player
	DUMMY.player_eliminated.connect(player_killed)
	# Base
	p1_base_instance = BASE_SCENE.instantiate()
	p1_base_instance.TEAM_ID = 1
	p1_base_instance.defender = PLAYER
	p1_base_instance.score = Vector3(255,0,0)
	add_child(p1_base_instance)
	p1_base_instance.global_position = P1Base.global_position
	p1_base_instance.colorwheel_clone.global_position = CloneWheel.global_position
	p1_base_instance.hurtbox_clone.global_position = CloneWheel.global_position
	p1_base_instance.colorwheel_clone.scale = Vector2(0.5, 0.5)
	p1_base_instance.hurtbox_clone.scale = Vector2(0.5, 0.5)
	
	p2_base_instance = BASE_SCENE.instantiate()
	p2_base_instance.TEAM_ID = 2
	p2_base_instance.defender = DUMMY
	p2_base_instance.score = Vector3(0,0,255)
	add_child(p2_base_instance)
	p2_base_instance.global_position = P2Base.global_position
	p2_base_instance.colorwheel_clone.global_position = CloneWheel.global_position
	p2_base_instance.hurtbox_clone.global_position = CloneWheel.global_position
	p2_base_instance.colorwheel_clone.scale = Vector2(0.5, 0.5)
	p2_base_instance.hurtbox_clone.scale = Vector2(0.5, 0.5)
	
	# Setup rope
	var rope_instance_p1_base = ROPE_SCENE.instantiate()
	add_child(rope_instance_p1_base)
	rope_instance_p1_base.tilemap = rope_tile
	rope_instance_p1_base.setup_rope(Vector2i(27,-24), Vector2i(27,-20))
	var rope_instance_turret_left = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_left)
	rope_instance_turret_left.tilemap = rope_tile
	rope_instance_turret_left.setup_rope(Vector2i(31,-24), Vector2i(31,-19))
	var rope_instance_turret_right = ROPE_SCENE.instantiate()
	add_child(rope_instance_turret_right)
	rope_instance_turret_right.tilemap = rope_tile
	rope_instance_turret_right.setup_rope(Vector2i(129,-23), Vector2i(129,-20))
	var rope_instance_p2_base = ROPE_SCENE.instantiate()
	add_child(rope_instance_p2_base)
	rope_instance_p2_base.tilemap = rope_tile
	rope_instance_p2_base.setup_rope(Vector2i(140,-23), Vector2i(140,-20))
	
	#Setup Platform
	platform1.enabled = false
	platform2.enabled = false
	platform12a.enabled = false
	platform12b.enabled = false
	platform21a.enabled = false
	platform21b.enabled = false
	platform12.enabled = false
	
func player_killed(player, attacker_id: int, attacker_team: int):
	#TODO: mobile spawn point once capture points exist
	if player.TEAM_ID == 1:
		if attacker_team == 2:
			p1_base_instance.lost_score_to(p2_base_instance)
		else:
			p1_base_instance.lost_score_to()
	else:
		if attacker_team == 1:
			p2_base_instance.lost_score_to(p1_base_instance)
		else:
			p2_base_instance.lost_score_to()
	await get_tree().create_timer(5.0).timeout
	match player.TEAM_ID:
		1: player.global_position = P1Spawn.global_position
		2: player.global_position = P2Spawn.global_position
	player.reset_physics_interpolation()
	player.reset_state()

func activate_player_base(team_id: int) -> void:
	match team_id:
		1: p1_base_instance.set_outpost(true)
		2: p2_base_instance.set_outpost(true)
	
func deactivate_player_base(team_id: int) -> void:
	match team_id:
		1: p1_base_instance.overthrown(p2_base_instance)
		2: p2_base_instance.overthrown(p1_base_instance)

func _physics_process(delta: float) -> void:
	# Timer
	platform_timer = max(platform_timer - delta, 0.0)
	# Platform Switching
	if platform_timer <= 0:
		match transition_step:
			0:
				_advance_transition()
				platform_timer = PLATFORM_TRANSITION_TIME
				transition_step = 1
			1:
				_advance_transition()
				platform_timer = PLATFORM_OVERLAP_TIME
				transition_step = 2
			2:
				_advance_transition()
				platform_timer = PLATFORM_TRANSITION_TIME
				transition_step = 3
			3:
				_advance_transition()
				_pick_next_platform()
				platform_timer = randf_range(
					PLATFORM_LIFETIME - PLATFORM_VARIANCE,
					PLATFORM_LIFETIME + PLATFORM_VARIANCE
				)
				transition_step = 0
	
func _pick_next_platform() -> void:
	var choices: Array[int] = [1, 2]
	choices.erase(current_platform)
	next_platform = choices.pick_random()

func _advance_transition() -> void:
	match current_platform:
		1:
			match next_platform:
				2:
					_transition_1_to_2()
		2:
			match next_platform:
				1:
					_transition_2_to_1()
	
func _transition_1_to_2() -> void:
	match transition_step:
		0:
			platform1.enabled = false
			platform12a.enabled = true
		1:
			platform12a.enabled = false
			platform12.enabled = true
		2:
			platform12.enabled = false
			platform12b.enabled = true
		3:
			platform12b.enabled = false
			platform2.enabled = true
			current_platform = next_platform

func _transition_2_to_1() -> void:
	match transition_step:
		0:
			platform2.enabled = false
			platform21a.enabled = true
		1:
			platform21a.enabled = false
			platform12.enabled = true
		2:
			platform12.enabled = false
			platform21b.enabled = true
		3:
			platform21b.enabled = false
			platform1.enabled = true
			current_platform = next_platform


func _on_player_player_ready(player: CharacterBody2D, player_id: int, player_team: int) -> void:
	pass # Replace with function body.
