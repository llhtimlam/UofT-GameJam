extends Area2D

# Wielder
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var damage: float
var knockback: float = 500.0

# Setup
var lifetime: float = 0.1
var facing_dir: float = 1.0
@onready var HIT_VISUAL: Sprite2D = $Sprite2D
@onready var HITBOX: CollisionShape2D = $CollisionShape2D
	
func _ready() -> void:
	add_to_group("melee")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	HIT_VISUAL.flip_h = (facing_dir == -1.0)
	HITBOX.position.x *= facing_dir
	
func _physics_process(delta: float) -> void:
	# Despawn timer
	lifetime -= delta
	if lifetime <= 0.0:
		call_deferred("queue_free")
	
# Utility Function
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area)

# Hitbox Manager
func _hit_target(target: Node) -> void:
	# Player iframe
	if target.is_in_group("player"):
		if target.PLAYER_ID == ATTACKER_ID:
			return
	
	# Damage
	if target.has_method("take_damage"):
		target.take_damage(damage, ATTACKER_ID, ATTACKER_TEAM)
		target.apply_knockback(facing_dir, knockback)
		call_deferred("queue_free")
