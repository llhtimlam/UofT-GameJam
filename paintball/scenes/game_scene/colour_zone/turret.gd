extends StaticBody2D

signal can_capture

@onready var capture_bar: ProgressBar = $CaptureBar

const MAX_HP : float = 90
var hp : float = MAX_HP
var fallen : bool = false

var MAP_ATTACK_VERTICAL_CD: float = 4.0
var MAP_ATTACK_HORIZONTAL_CD: float = 15.0
var ATTACK_CD: float = 10.0
@export var SHOTGUN_PROJECTILE_DMG: float = 0.0
@export var SHOTGUN_PROJECTILE_SPEED: float = 300.0
@export var SHOTGUN_PROJECTILE_KNOCKBACK: float = 100.0
@export var RIFFLE_PROJECTILE_DMG: float = 0.0
@export var RIFFLE_PROJECTILE_SPEED: float = 300.0
@export var RIFFLE_PROJECTILE_KNOCKBACK: float = 400.0
@export var MAP_ATTACK_DMG: float = 0.0
@export var MAP_ATTACK_SPEED: float = 300.0
@export var MAP_ATTACK_KNOCKBACK: float = 600.0

var map_attack_vertical_cd: float = 2.0
var map_attack_horizontal_cd: float = 12.0
var map_attack_preset: int = 1
var attack_cd: float = 2.0
var attack_preset: int = 1

var vertical_x_preset1: Array[float] = [-432, -216, 0, 216, 432]
var vertical_x_preset2: Array[float] = [-360, -144, 72, 288]
var vertical_x_preset3: Array[float] = [-288, -72, 144, 360]
var horizontal_y_preset1: Array[float] = [-1056, -800, -200]
var horizontal_y_preset2: Array[float] = [-1090, -416]
var horizontal_y_preset3: Array[float] = [-1130, -300, -544]

var aimable_targets: Array[CharacterBody2D]
var aim_target: CharacterBody2D
var target_direction: Vector2
var target_angle: float
var shoot_angle: float
var facing_dir: float = 1.0

const SHOTGUN_SCENE = preload("res://scenes/game_scene/projectile/shotgun.tscn")
const RIFFLE_SCENE = preload("res://scenes/game_scene/projectile/riffle.tscn")
@onready var center: Marker2D = $Center
@onready var projectile: Marker2D = $Center/LaunchPoint
@onready var attack_detection: Area2D = $AttackZone

const MAP_ATTACK_VERTICAL_SCENE = preload("res://scenes/game_scene/colour_zone/map_attack/map_attack_vertical.tscn")
const MAP_ATTACK_HORIZONTAL_SCENE = preload("res://scenes/game_scene/colour_zone/map_attack/map_attack_horizontal.tscn")

func _ready() -> void:
	add_to_group("turret")
	capture_bar.max_value = MAX_HP
	capture_bar.value = hp
	attack_cd = ATTACK_CD
	attack_detection.body_entered.connect(_on_body_entered)
	attack_detection.area_entered.connect(_on_area_entered)
	attack_detection.body_exited.connect(_on_body_exited)
	attack_detection.area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	map_attack_vertical_cd = max(map_attack_vertical_cd - delta, 0.0)
	map_attack_horizontal_cd = max(map_attack_horizontal_cd - delta, 0.0)
	attack_cd = max(attack_cd - delta, 0.0)
	
	if map_attack_vertical_cd <= 0:
		_map_attack_vertical_preset()
		map_attack_vertical_cd = MAP_ATTACK_VERTICAL_CD
	if map_attack_horizontal_cd <= 0:
		_map_attack_horizontal_preset()
		map_attack_horizontal_cd = MAP_ATTACK_HORIZONTAL_CD
	
	# Random Aim target
	if aim_target != null and not aimable_targets.has(aim_target):
		_pick_random_target()
	if aim_target == null and aimable_targets.size() > 0:
		_pick_random_target()
	if aim_target != null:
		target_direction = center.global_position.direction_to(aim_target.global_position)
		facing_dir = signf(target_direction.x) 
		target_angle = target_direction.angle()
		center.rotation = target_angle
	
	if attack_cd <= 0:
		if aim_target != null and is_equal_approx(center.rotation, target_angle):
			if attack_preset == 1:
				shoot_shotgun_projectile(SHOTGUN_PROJECTILE_DMG, SHOTGUN_PROJECTILE_SPEED, SHOTGUN_PROJECTILE_KNOCKBACK, facing_dir, target_angle, -1 ,-1)
			elif attack_preset == 2:
				shoot_riffle_projectile(RIFFLE_PROJECTILE_DMG, RIFFLE_PROJECTILE_SPEED, RIFFLE_PROJECTILE_KNOCKBACK, facing_dir, aim_target, -1 ,-1)
			attack_cd = ATTACK_CD
			_pick_random_target()
			attack_preset = [1, 2].pick_random()

# Utility Function
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body, true)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area, true)

func _on_body_exited(body: Node2D) -> void:
	_hit_target(body, false)

func _on_area_exited(area: Area2D) -> void:
	_hit_target(area, false)

# Hitbox Manager
func _hit_target(target: Node, hit: bool) -> void:
	if target.is_in_group("player"):
		if hit:
			if not aimable_targets.has(target):
				aimable_targets.append(target)
		else:
			aimable_targets.erase(target)
	
func _pick_random_target() -> void:
	if aimable_targets.size() > 0:
		aim_target = aimable_targets.pick_random()
	else:
		aim_target = null

func shoot_shotgun_projectile(base_damage: float, speed: float, knockback: float, facing_dir: float, angle: float, attacker_id: int, attacker_team: int) -> void:
	var shotgun_instance = SHOTGUN_SCENE.instantiate()
	# Projectile Collision 2
	shotgun_instance.ATTACKER_ID = attacker_id
	shotgun_instance.ATTACKER_TEAM = attacker_team
	shotgun_instance.global_position = projectile.global_position
	shotgun_instance.facing_angle = angle
	shotgun_instance.facing_dir = facing_dir
	shotgun_instance.damage = base_damage
	shotgun_instance.speed = speed
	shotgun_instance.knockback = knockback
	shotgun_instance.lifetime = 4.0
	get_parent().get_parent().add_child.call_deferred(shotgun_instance)

func shoot_riffle_projectile(base_damage: float, speed: float, knockback: float, facing_dir: float, target: CharacterBody2D, attacker_id: int, attacker_team: int) -> void:
	var riffle_instance = RIFFLE_SCENE.instantiate()
	# Projectile Collision 2
	riffle_instance.ATTACKER_ID = attacker_id
	riffle_instance.ATTACKER_TEAM = attacker_team
	riffle_instance.global_position = projectile.global_position
	riffle_instance.target = target
	riffle_instance.facing_dir = facing_dir
	riffle_instance.damage = base_damage
	riffle_instance.speed = speed
	riffle_instance.knockback = knockback
	riffle_instance.lifetime = 2.5
	get_parent().get_parent().add_child.call_deferred(riffle_instance)

func _map_attack_vertical_preset() -> int:
	var vertical_map_attack_preset = [1,2,3].pick_random()
	for i in _get_vertical_preset(vertical_map_attack_preset):
		_generate_vertical_map_attack(i)
	return vertical_map_attack_preset
	
func _map_attack_horizontal_preset() -> int:
	var horizontal_map_attack_preset = [1,2,3].pick_random()
	for i in _get_horizontal_preset(horizontal_map_attack_preset):
		_generate_horizontal_map_attack(i - self.global_position.y)
	return horizontal_map_attack_preset
	
func _get_vertical_preset(id: int) -> Array[float]:
	match id:
		1: return vertical_x_preset1
		2: return vertical_x_preset2
		_: return vertical_x_preset3
	
func _get_horizontal_preset(id: int) -> Array[float]:
	match id:
		1: return horizontal_y_preset1
		2: return horizontal_y_preset2
		_: return horizontal_y_preset3
	
func _generate_vertical_map_attack(x: float) -> void:
	var map_attack_vertical_instance = MAP_ATTACK_VERTICAL_SCENE.instantiate()
	# Map Attack Collision 2
	map_attack_vertical_instance.ATTACKER_ID = -1
	map_attack_vertical_instance.ATTACKER_TEAM = -1
	map_attack_vertical_instance.global_position = Vector2(x, 0)
	map_attack_vertical_instance.facing_dir = signf(x)
	map_attack_vertical_instance.damage = MAP_ATTACK_DMG
	map_attack_vertical_instance.knockback = MAP_ATTACK_KNOCKBACK
	map_attack_vertical_instance.lifetime = 0.8
	add_child.call_deferred(map_attack_vertical_instance)
	
func _generate_horizontal_map_attack(y: float) -> void:
	var map_attack_horizontal_instance = MAP_ATTACK_HORIZONTAL_SCENE.instantiate()
	# Map Attack Collision 2
	map_attack_horizontal_instance.ATTACKER_ID = -1
	map_attack_horizontal_instance.ATTACKER_TEAM = -1
	map_attack_horizontal_instance.global_position = Vector2(0, y)
	map_attack_horizontal_instance.damage = MAP_ATTACK_DMG
	map_attack_horizontal_instance.knockback = MAP_ATTACK_KNOCKBACK
	map_attack_horizontal_instance.lifetime = 0.8
	add_child.call_deferred(map_attack_horizontal_instance)
	
func take_damage(damage, _attacker_id, attacker_team) -> void:
	hp -= damage
	capture_bar.value = hp
	if hp <= 0:
		hp = MAX_HP
		Bucket.spawn(
				get_parent().get_parent(),
				get_parent().get_parent().bucket_spawn_turret.global_position,
				Vector3(0, 64, 0)
				)
		fallen = true
		#can_capture.emit(attacker_team)
