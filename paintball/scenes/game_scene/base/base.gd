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
			display_self_score = normalized_base_color * normalized_score.x
			display_enemy_score = normalized_enemy_color * normalized_score.z
			display_turret_score = normalized_turret_color * normalized_score.y
		else:
			display_self_score = normalized_base_color * normalized_score.z
			display_enemy_score = normalized_enemy_color * normalized_score.x
			display_turret_score = normalized_turret_color * normalized_score.y

const MAX_HP : float = 30
var hp : float = MAX_HP

func _ready() -> void:
	add_to_group("base")
	
func update_score(add_score: Vector3) -> void:
	score += add_score
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
				score * 0.5
				)
	
func _get_spawnpoint() -> Vector2:
	match team_id:
		1: return get_parent().bucket_spawn_p1.global_position
		_: return get_parent().bucket_spawn_p2.global_position
