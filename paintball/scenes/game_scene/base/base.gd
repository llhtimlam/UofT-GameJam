extends Area2D

var team_id: int
var defender: CharacterBody2D

var normalized_base_color: Vector3
var normalized_enemy_color: Vector3
var normalized_turret_color: Vector3
var owner_normalized_color: Vector3
var display_self_score: Vector3 = Vector3.ZERO
var display_enemy_score: Vector3 = Vector3.ZERO
var display_turret_score: Vector3 = Vector3.ZERO
var progress_self_score: float
var progress_enemy_score: float
var progress_turret_score: float

var base_color: Color:
	set(value):
		base_color = value
		normalized_base_color = Vector3(base_color.r, base_color.g, base_color.b) / 255.0
var enemy_color: Color:
	set(value):
		enemy_color = value
		normalized_enemy_color = Vector3(enemy_color.r, enemy_color.g, enemy_color.b) / 255.0
var turret_color: Color:
	set(value):
		turret_color = value
		normalized_turret_color = Vector3(turret_color.r, turret_color.g, turret_color.b) / 255.0
var score: Vector3 = Vector3.ZERO: # Format: (P1, Turret, P2)
	set(value):
		score = value
		var normalized_score = score / 255.0
		if team_id == 1:
			progress_self_score = normalized_score.x * 100
			progress_enemy_score = normalized_score.z * 100
			progress_turret_score = normalized_score.y * 100
			display_self_score = normalized_base_color * normalized_score.x
			display_enemy_score = normalized_enemy_color * normalized_score.z
			display_turret_score = normalized_turret_color * normalized_score.y
		else:
			progress_self_score = normalized_score.z * 100
			progress_enemy_score = normalized_score.x * 100
			progress_turret_score = normalized_score.y * 100
			display_self_score = normalized_base_color * normalized_score.z
			display_enemy_score = normalized_enemy_color * normalized_score.x
			display_turret_score = normalized_turret_color * normalized_score.y

const MAX_HP: float = 40
var hp: float = MAX_HP

var REGEN_AMOUNT: = 0.1
var REGEN_CD: float = 0.2
var regen_timer : float = 0.0

var LOSS_PERCENTAGE: = 0.05

func _ready() -> void:
	add_to_group("base")
	
func _physics_process(delta: float) -> void:
	# Timer
	regen_timer = max(regen_timer - delta, 0.0)
	if regen_timer <= 0.0:
		_get_regen()
		regen_timer = REGEN_CD
	
func update_score(add_score: Vector3 = Vector3.ZERO) -> void:
	score += add_score
	score = score.clamp(Vector3.ZERO, Vector3(255.0, 255.0, 255.0))
	get_parent().update_color_wheel()
	
func take_damage(damage, attacker_id, _attacker_team) -> void:
	if attacker_id == team_id:
		return
	hp -= damage
	if hp <= 0:
		hp = MAX_HP
		Bucket.spawn(
				get_parent(),
				_get_spawnpoint(),
				score * 0.1
				)
		_get_hurt_animation()
		score -= score * 0.1
		score = score.max(Vector3.ZERO)
	
func _get_spawnpoint() -> Vector2:
	match team_id:
		1: return get_parent().bucket_spawn_p1.global_position
		_: return get_parent().bucket_spawn_p2.global_position

func _get_hurt_animation() -> void:
	match team_id:
		1: return get_parent().p1_base_hurt_animation()
		_: return get_parent().p2_base_hurt_animation()

func _get_regen() -> void:
	match team_id:
		1: score.x += REGEN_AMOUNT
		_: score.z += REGEN_AMOUNT
	score = score.clamp(Vector3.ZERO, Vector3(255.0, 255.0, 255.0))
	update_score()
	
func lost_score(attacker_base: Node = null) -> void:
	var amount_lost: Vector3 = self.score * LOSS_PERCENTAGE
	self.score -= amount_lost
	self.score = self.score.max(Vector3.ZERO)
	_get_hurt_animation()
	update_score()
	if attacker_base != null:
		attacker_base.update_score(amount_lost)
