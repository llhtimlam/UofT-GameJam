extends Area2D


const MAP_ATTACK_HORIZONTAL_SCENE = preload("res://scenes/tutorial/entity/tutorial_map_attack.tscn")

var map_attack_horizontal_cd: float = 0.0

var aimable_targets: Array[CharacterBody2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	body_exited.connect(_on_body_exited)
	area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	map_attack_horizontal_cd = max(map_attack_horizontal_cd - delta, 0.0)
	if map_attack_horizontal_cd <= 0 and aimable_targets.size() > 0 :
		map_attack_horizontal_cd = 3.0
		var map_attack_horizontal_instance = MAP_ATTACK_HORIZONTAL_SCENE.instantiate()
		# Map Attack Collision 2
		map_attack_horizontal_instance.ATTACKER_ID = -1
		map_attack_horizontal_instance.ATTACKER_TEAM = -1
		map_attack_horizontal_instance.damage = 0
		map_attack_horizontal_instance.knockback = 100
		add_child(map_attack_horizontal_instance)

# Utility Function
func _on_body_entered(body: Node2D) -> void:
	_hit_target(body, true)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area, true)

func _on_body_exited(body: Node2D) -> void:
	_hit_target(body, false)

func _on_area_exited(area: Area2D) -> void:
	_hit_target(area, false)

func _hit_target(target: Node, hit: bool) -> void:
	if target.is_in_group("player"):
		if hit:
			if not aimable_targets.has(target):
				aimable_targets.append(target)
		else:
			aimable_targets.erase(target)
