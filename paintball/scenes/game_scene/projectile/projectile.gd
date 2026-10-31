extends Area2D

# Shooter
var ATTACKER_ID: int
var ATTACKER_TEAM: int

# Stat
var velocity: Vector2
var damage: float
var knockback: float
var stun_time: float = 1.0

# Physic
var facing_dir: float = 0.0
var facing_angle: float = 0.0
var speed: float = 500.0

# Setup
var lifetime: float = 1.0
var iframe: float = 0.0
var is_shot: bool = false

var sprites: Array[Node] = []

# Audio
@onready var ranged_audio: AudioStreamPlayer = $RangedAudio
var volume: float = -7

func _ready() -> void:
	add_to_group("projectile")
	ranged_audio.volume_db = volume
	ranged_audio.play()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	sprites = find_children("*", "AnimatedSprite2D", true, false)
	sprites = sprites.filter(
		func(node: Node):
			return not "shadow" in node.name.to_lower()
	)
	update_color()
	
func _physics_process(delta: float) -> void:
	iframe = max(iframe - delta, 0.0)
	# Despawn timer
	lifetime -= delta
	if lifetime <= 0.0:
		call_deferred("queue_free")
		
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
	# iframe
	if is_shot or iframe > 0:
		return
	# Turret and projectile immunity to projectile
	if target.is_in_group("projectile"):
		return
	# No friendly fire
	if target.is_in_group("player") or target.is_in_group("turret"):
		if target.TEAM_ID == ATTACKER_TEAM:
			return
	# Damage
	if target.has_method("take_damage"):
		is_shot = true
		target.take_damage(damage, ATTACKER_ID, ATTACKER_TEAM)
		if target.has_method("apply_knockback"):
			target.apply_knockback(facing_dir, knockback, stun_time)
	call_deferred("queue_free")

func update_color() -> void:
	for sprite in sprites:
		if sprite:
			sprite.self_modulate = Color.WHITE
			var base_color: Color
			match ATTACKER_TEAM:
				1: base_color = Globals.p1_color
				2: base_color = Globals.p2_color
				-1: base_color = Globals.turret_color
				_: base_color = Color.WHITE
			sprite.self_modulate = base_color.lerp(Color.WHITE, Globals.white_blend_intensity)
