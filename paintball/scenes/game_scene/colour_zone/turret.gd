extends StaticBody2D

signal can_capture

@onready var capture_bar: ProgressBar = $CaptureBar

const MAX_HP : float = 10
var hp : float = MAX_HP
var fallen : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	capture_bar.max_value = MAX_HP
	capture_bar.value = hp

#
#func _on_hurtbox_area_entered(area: Area2D) -> void:
	#if area.is_in_group("attack"):
		#hp -= area.damage
		#take_damage(area.ATTACKER_TEAM)
func apply_knockback(_facing_dir, _knockback) -> void:
	pass


func take_damage(damage, _attacker_id, attacker_team) -> void:
	hp -= damage
	capture_bar.value = hp
	if hp <= 0:
		fallen = true
		can_capture.emit(attacker_team)
