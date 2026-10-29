extends Area2D

# Wielder
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var damage: float
var knockback: float
var stun_time: float = 0.2

# Setup
var lifetime: float = 0.1
var facing_dir: float = 1.0
@onready var HIT_VISUAL: Sprite2D = $Sprite2D
@onready var HITBOX: CollisionShape2D = $CollisionShape2D
var damaged_targets: Array[Node2D] = []

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
	if damaged_targets.has(target):
		return
	# No friendly fire
	if target.is_in_group("player") or target.is_in_group("turret"):
		if target.TEAM_ID == ATTACKER_TEAM:
			return
	damaged_targets.append(target)
	# Damage
	var giving_damage = false #silly way to do it probably, but damage needs to be applied before knockback
	if target.has_method("take_damage"):
		giving_damage = true
		if target.has_method("apply_knockback"):
			target.apply_knockback(facing_dir, knockback, stun_time)
	if giving_damage:
		target.take_damage(damage, ATTACKER_ID, ATTACKER_TEAM)
