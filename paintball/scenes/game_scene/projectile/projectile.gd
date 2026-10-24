extends Area2D

# Shooter
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var velocity: Vector2
var damage: float
var knockback: float = 100.0

# Physic
var facing_dir: float = 0.0
var facing_angle: float = 0.0
var speed: float = 500.0

# Setup
var iframe: float = 0.15
var is_shot: bool = false
	
func _ready() -> void:
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# Intercept Logic
func take_damage(amount: float, attacker_id: int, attacker_team: int) -> void:
	if is_shot:
		return
	is_shot = true
	call_deferred("queue_free")

func _physics_process(delta: float) -> void:
	iframe = max(iframe - delta, 0.0)
	
	velocity = Vector2.from_angle(facing_angle) * speed
	# Final Movement
	global_position += velocity * delta
	global_rotation = facing_angle
	
# Utility Function
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area)

# Hitbox Manager
func _hit_target(target: Node) -> void:
	if is_shot:
		return
	
	# Player iframe
	if target.is_in_group("player"):
		if iframe > 0.0 and target.PLAYER_ID == ATTACKER_ID:
			return
	
	# Damage
	if target.has_method("take_damage"):
		is_shot = true
		target.take_damage(damage, ATTACKER_ID, ATTACKER_TEAM)
		target.apply_knockback(facing_dir, knockback)
		call_deferred("queue_free")
