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
const BASE_SCENE = preload("res://scenes/game_scene/base/base.tscn")
var p1_base_instance: Node2D = null
var p2_base_instance: Node2D = null
var p1_spin_tween: Tween
var p2_spin_tween: Tween
var p1_zoom_tween: Tween
var p2_zoom_tween: Tween

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
@onready var p1_score_progress_self: TextureProgressBar = $Player1ColorWheel/P1SelfScore
@onready var p1_score_progress_enemy: TextureProgressBar = $Player1ColorWheel/P1EnemyScore
@onready var p1_score_progress_turret: TextureProgressBar = $Player1ColorWheel/P1TurretScore
@onready var p2_score_progress_self: TextureProgressBar = $Player2ColorWheel/P2SelfScore
@onready var p2_score_progress_enemy: TextureProgressBar = $Player2ColorWheel/P2EnemyScore
@onready var p2_score_progress_turret: TextureProgressBar = $Player2ColorWheel/P2TurretScore

# Platform
@onready var platform1: TileMapLayer = $Platform1
@onready var platform2: TileMapLayer = $Platform2
@onready var platform3: TileMapLayer = $Platform3
@onready var platform12: TileMapLayer = $Platform12
@onready var platform23: TileMapLayer = $Platform23
@onready var platform31: TileMapLayer = $Platform31
@onready var platform12a: TileMapLayer = $Platform12a
@onready var platform12b: TileMapLayer = $Platform12b
@onready var platform21a: TileMapLayer = $Platform21a
@onready var platform21b: TileMapLayer = $Platform21b
@onready var platform13a: TileMapLayer = $Platform13a
@onready var platform13b: TileMapLayer = $Platform13b
@onready var platform31a: TileMapLayer = $Platform31a
@onready var platform31b: TileMapLayer = $Platform31b
@onready var platform23a: TileMapLayer = $Platform23a
@onready var platform23b: TileMapLayer = $Platform23b
@onready var platform32a: TileMapLayer = $Platform32a
@onready var platform32b: TileMapLayer = $Platform32b
var PLATFORM_LIFETIME: float = 8.0
var PLATFORM_VARIANCE: float = 2.0
var PLATFORM_TRANSITION_TIME: float = 3.0
var PLATFORM_OVERLAP_TIME: float = 5.0

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
	#Display
	if p1_color_wheel and p1_color_wheel.material:
		p1_color_wheel.material = p1_color_wheel.material.duplicate()
	if p2_color_wheel and p2_color_wheel.material:
		p2_color_wheel.material = p2_color_wheel.material.duplicate()
	if turret_color_wheel and turret_color_wheel.material:
		turret_color_wheel.material = turret_color_wheel.material.duplicate()
	p1_score_progress_self.self_modulate = p1_color
	p1_score_progress_enemy.self_modulate = p2_color
	p1_score_progress_turret.self_modulate = turret_color
	p2_score_progress_self.self_modulate = p2_color
	p2_score_progress_enemy.self_modulate = p1_color
	p2_score_progress_turret.self_modulate = turret_color
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
	p1_base_instance.score = Vector3(64,0,0)
	add_child.call_deferred(p1_base_instance)
	p1_base_instance.global_position = p1_color_wheel.global_position
	
	p2_base_instance = BASE_SCENE.instantiate()
	p2_base_instance.defender = PLAYER2
	p2_base_instance.team_id = 2
	p2_base_instance.base_color = p2_color
	p2_base_instance.enemy_color = p1_color
	p2_base_instance.turret_color = turret_color
	p2_base_instance.score = Vector3(0,0,64)
	add_child.call_deferred(p2_base_instance)
	p2_base_instance.global_position = p2_color_wheel.global_position
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
	
	#Setup Platform
	platform1.enabled = false
	platform2.enabled = false
	platform3.enabled = false
	platform12.enabled = false
	platform23.enabled = false
	platform31.enabled = false
	platform12a.enabled = false
	platform12b.enabled = false
	platform21a.enabled = false
	platform21b.enabled = false
	platform13a.enabled = false
	platform13b.enabled = false
	platform31a.enabled = false
	platform31b.enabled = false
	platform23a.enabled = false
	platform23b.enabled = false
	platform32a.enabled = false
	platform32b.enabled = false
	
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
		turret_color_wheel.material.set_shader_parameter("custom_color_left", Vector3(1, 1 ,1)) # Scale with Capture Point
		turret_color_wheel.material.set_shader_parameter("custom_color_right", Vector3(1, 1, 1)) # Scale with Capture Point
	p1_score_progress_self.value = p1_base_instance.progress_self_score
	p1_score_progress_enemy.value = p1_base_instance.progress_enemy_score
	p1_score_progress_turret.value = p1_base_instance.progress_turret_score
	p2_score_progress_self.value = p2_base_instance.progress_self_score
	p2_score_progress_enemy.value = p2_base_instance.progress_enemy_score
	p2_score_progress_turret.value = p2_base_instance.progress_turret_score

func p1_base_hurt_animation() -> void:
	if p1_spin_tween and p1_spin_tween.is_valid():
		p1_spin_tween.kill()
	p1_spin_tween = create_tween()
	p1_spin_tween.set_trans(Tween.TRANS_QUAD)
	p1_spin_tween.set_ease(Tween.EASE_IN_OUT)
	var target_rotation: float = p1_color_wheel.rotation + (6 * PI)
	p1_spin_tween.tween_property(p1_color_wheel, "rotation", target_rotation, 1.0)

func p2_base_hurt_animation() -> void:
	if p2_spin_tween and p2_spin_tween.is_valid():
		p2_spin_tween.kill()
	p2_spin_tween = create_tween()
	p2_spin_tween.set_trans(Tween.TRANS_QUAD)
	p2_spin_tween.set_ease(Tween.EASE_IN_OUT)
	var target_rotation: float = p2_color_wheel.rotation + (6 * PI)
	p2_spin_tween.tween_property(p2_color_wheel, "rotation", target_rotation, 1.0)
	
func p1_base_zoom_animation() -> void:
	if p1_zoom_tween and p1_zoom_tween.is_valid():
		p1_zoom_tween.kill()
	p1_color_wheel.scale = Vector2.ONE
	p1_zoom_tween = create_tween()
	p1_zoom_tween.tween_property(p1_color_wheel, "scale", Vector2(1.3, 1.3), 0.15)
	p1_zoom_tween.tween_property(p1_color_wheel, "scale", Vector2.ONE, 0.15)
	
func p2_base_zoom_animation() -> void:
	if p2_zoom_tween and p2_zoom_tween.is_valid():
		p2_zoom_tween.kill()
	p2_color_wheel.scale = Vector2.ONE
	p2_zoom_tween = create_tween()
	p2_zoom_tween.tween_property(p2_color_wheel, "scale", Vector2(1.3, 1.3), 0.15)
	p2_zoom_tween.tween_property(p2_color_wheel, "scale", Vector2.ONE, 0.15)
	
func p1_base_flip_animation() -> void:
	if p1_zoom_tween and p1_zoom_tween.is_valid():
		p1_zoom_tween.kill()
	p1_color_wheel.scale = Vector2.ONE
	p1_zoom_tween = create_tween()
	p1_zoom_tween.tween_property(p1_color_wheel, "scale", Vector2(-1.0, -1.0), 0.15)
	p1_zoom_tween.tween_property(p1_color_wheel, "scale", Vector2.ONE, 0.15)
	
func p2_base_flip_animation() -> void:
	if p2_zoom_tween and p2_zoom_tween.is_valid():
		p2_zoom_tween.kill()
	p2_color_wheel.scale = Vector2.ONE
	p2_zoom_tween = create_tween()
	p2_zoom_tween.tween_property(p2_color_wheel, "scale", Vector2(-1.0, -1.0), 0.15)
	p2_zoom_tween.tween_property(p2_color_wheel, "scale", Vector2.ONE, 0.15)
	
func _pick_next_platform() -> void:
	var choices: Array[int] = [1, 2, 3]
	choices.erase(current_platform)
	next_platform = choices.pick_random()

func _advance_transition() -> void:
	match current_platform:
		1:
			match next_platform:
				2:
					_transition_1_to_2()
				3:
					_transition_1_to_3()
		2:
			match next_platform:
				1:
					_transition_2_to_1()
				3:
					_transition_2_to_3()
		3:
			match next_platform:
				1:
					_transition_3_to_1()
				2:
					_transition_3_to_2()
	
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

func _transition_1_to_3() -> void:
	match transition_step:
		0:
			platform1.enabled = false
			platform13a.enabled = true
		1:
			platform13a.enabled = false
			platform31.enabled = true
		2:
			platform31.enabled = false
			platform13b.enabled = true
		3:
			platform13b.enabled = false
			platform3.enabled = true
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

func _transition_2_to_3() -> void:
	match transition_step:
		0:
			platform2.enabled = false
			platform23a.enabled = true
		1:
			platform23a.enabled = false
			platform23.enabled = true
		2:
			platform23.enabled = false
			platform23b.enabled = true
		3:
			platform23b.enabled = false
			platform3.enabled = true
			current_platform = next_platform

func _transition_3_to_1() -> void:
	match transition_step:
		0:
			platform3.enabled = false
			platform31a.enabled = true
		1:
			platform31a.enabled = false
			platform31.enabled = true
		2:
			platform31.enabled = false
			platform31b.enabled = true
		3:
			platform31b.enabled = false
			platform1.enabled = true
			current_platform = next_platform

func _transition_3_to_2() -> void:
	match transition_step:
		0:
			platform3.enabled = false
			platform32a.enabled = true
		1:
			platform32a.enabled = false
			platform23.enabled = true
		2:
			platform23.enabled = false
			platform32b.enabled = true
		3:
			platform32b.enabled = false
			platform2.enabled = true
			current_platform = next_platform

func _on_player_2_player_eliminated(player: CharacterBody2D) -> void:
	pass # Replace with function body.
