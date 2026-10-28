extends Node2D

# Shooter
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var velocity: Vector2
var damage: float
var knockback: float
var stun_time: float = 0.4
var SHOTGUN_NUMBER: int = 3
var WAVE_NUMBER: int = 3
var SHOTGUN_ANGLE_VARIANCE: float = 0.02
var WAVE_CD: float = 0.05

# Physic
var facing_dir: float
var facing_angle: float
var speed: float

# Setup
var lifetime: float
var local_lifeime: float
var wave_timer: float = 0.0
var wave: int = 0
var shotgun_number: int = SHOTGUN_NUMBER
const PROJECTILE_SCENE = preload("res://scenes/game_scene/projectile/projectile.tscn")
	
func _ready() -> void:
	add_to_group("projectile")
	local_lifeime = 2 * lifetime
	
func _physics_process(delta: float) -> void:
	# Despawn timer
	local_lifeime -= delta
	if local_lifeime <= 0:
		call_deferred("queue_free")
	# Shotgun wave
	wave_timer = max(wave_timer - delta, 0.0)
	if wave >= WAVE_NUMBER:
		return
	if wave_timer <= 0:
		shoot_projectile(damage, speed, knockback, facing_dir, facing_angle, ATTACKER_ID, ATTACKER_TEAM)
		for i in range(shotgun_number + 1):
			shoot_projectile(damage, speed, knockback, facing_dir, facing_angle + SHOTGUN_ANGLE_VARIANCE * i, ATTACKER_ID, ATTACKER_TEAM)
			shoot_projectile(damage, speed, knockback, facing_dir, facing_angle - SHOTGUN_ANGLE_VARIANCE * i, ATTACKER_ID, ATTACKER_TEAM)
		wave += 1
		shotgun_number -= 1
		wave_timer = WAVE_CD
	
func shoot_projectile(base_damage: float, p_speed: float, p_knockback: float, p_facing_dir: float, angle: float, attacker_id: int, attacker_team: int) -> void:
	var projectile_instance = PROJECTILE_SCENE.instantiate()
	# Projectile Collision 2
	projectile_instance.ATTACKER_ID = attacker_id
	projectile_instance.ATTACKER_TEAM = attacker_team
	projectile_instance.position = Vector2.ZERO
	projectile_instance.facing_angle = angle
	projectile_instance.facing_dir = p_facing_dir
	projectile_instance.damage = base_damage
	projectile_instance.speed = p_speed
	projectile_instance.knockback = p_knockback
	projectile_instance.stun_time = stun_time
	projectile_instance.lifetime = lifetime
	add_child.call_deferred(projectile_instance)
