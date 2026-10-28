extends Area2D

# Shooter
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var damage: float
var knockback: float
var stun_time: float = 3.0

# Physic
var facing_dir: float = 0.0
var speed: float = 0.0

# Setup
var lifetime: float = 1.0
var immune_targets: Array[Node2D]
	
func _ready() -> void:
	add_to_group("map_attack")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
func _physics_process(delta: float) -> void:
	# Despawn timer
	lifetime -= delta
	if lifetime <= 0.0:
		call_deferred("queue_free")
		
	# Final Movement
	global_position.x += speed * delta
	
# Utility Function
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area)

# Hitbox Manager
func _hit_target(target: Node) -> void:
	if immune_targets.has(target):
		return
	# Damage
	if target.is_in_group("player"):
		if target.has_method("take_damage"):
			target.take_damage(damage, ATTACKER_ID, ATTACKER_TEAM)
			if target.has_method("apply_knockback"):
				if facing_dir == 0.0:
					facing_dir = signf(target.global_position.x - global_position.x)
				target.apply_knockback(facing_dir, knockback, stun_time)
				immune_targets.append(target)
