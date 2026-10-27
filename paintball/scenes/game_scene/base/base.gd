extends Area2D

var team_id: int
var defender: CharacterBody2D

var color: Vector3 = Vector3.ZERO
const MAX_HP : float = 30
var hp : float = MAX_HP

func _ready() -> void:
	add_to_group("base")

func take_damage(damage, attacker_id, attacker_team) -> void:
	if attacker_id == team_id:
		return
	hp -= damage
	if hp <= 0:
		hp = MAX_HP
		Bucket.spawn(
				get_parent(),
				_get_spawnpoint(),
				color * 0.5
				)
	
func _get_spawnpoint() -> Vector2:
	match team_id:
		1: return get_parent().bucket_spawn_p1.global_position
		_: return get_parent().bucket_spawn_p2.global_position
