extends CharacterBody2D

# User
@export_enum("P1", "P2", "AI") var control_type: String = "P1"
@export var TEAM_ID: int = 1
@export var PLAYER_ID: int = 1
@export var character_id: int = 0
var player_name: String = ""
signal player_eliminated(player: CharacterBody2D)

# Animation
var is_spawned: bool = false
var facing_dir: float = 1.0
var aim_angle: float
var shoot_angle : float

# Physics
var GRAVITY: float = 4800.0
var MAX_SPEED: float = 400.0
var GROUND_ACCELERATION: float = 50.0
var JUMP_ACCELERATION: float = 6.0
var GROUND_DECELERATION: float = 20.0
var JUMP_DECELERATION: float = 10.0
var CLIMB_SPEED: float = 400.0
var CLIMB_ACCELERATION: float = 50.0
var CLIMB_DECELERATION: float = 50.0

# Stat
@export var HEALTH: float = 100.0
@export var MELEE_DMG: float = 30.0
@export var MELEE_KNOCKBACK: float = 600.0
@export var PROJECTILE_DMG: float = 3.0
@export var PROJECTILE_KNOCKBACK: float = 800.0
const JUMP_VELOCITY = -1200.0
@export var DASH_CD: float = 10.0
var DASH_DURATION: float = 0.5
var DASH_DISTANCE: float = 5.0
@export var MELEE_CD: float = 1.0
var AIM_CD: float = 1.0
@export var SHOOT_CD: float = 3.0
var DIAL_SPEED: float = 2.5

# Initialize
var damage_reduction: float = 1.0
var base_velocity: float = 0.0
var knockback_velocity: float = 0.0
var input_up: bool = false
var input_down: bool = false
var input_left: bool = false
var input_right: bool = false
var input_jump: bool = false
var input_dash: bool = false
var input_melee: bool = false
var input_shoot: bool = false
var input_dialup: bool = false
var input_dialdown: bool = false

var stun_cd: float = 0.0
var climb_cd: float = 0.0
var dash_cd: float = 0.0
var dash_duration: float = 0.0
var melee_cd: float = 0.0
var aim_cd: float = 0.0
var shoot_cd: float = 0.0
var dir: float
var dash_dir: float

var is_dead: bool = false

# Climbing
@onready var climbup_hitbox: Area2D = $ClimbUpDetector
@onready var climbdown_hitbox: Area2D = $ClimbDownDetector
var can_climb_up: bool = false
var can_climb_down: bool = false
var can_climb: bool = false
var is_climbing: bool = false
var was_climbing: bool = false
var active_rope: Line2D = null
var JUMPOFF_SPEED_X: float = 300.0
var JUMPOFF_SPEED_Y: float = -800.0
var CLIMB_CD: float = 0.2

# Debuff
var is_stun: bool = false
var STUN_CD: float = 1.0

# Melee
@onready var melee_hitbox: Marker2D = $Melee
const MELEE_SCENE = preload("res://scenes/game_scene/melee/melee.tscn")

# Projectile
var is_aiming: bool = false
@onready var center: Marker2D = $Center
@onready var projectile: Marker2D = $Center/LaunchPoint
@onready var aim_dot: Sprite2D = $Center/LaunchPoint/AimDot
const PROJECTILE_SCENE = preload("res://scenes/game_scene/projectile/projectile.tscn")

# World Boundary
const Y_BOUNDARY = 1500

# Camera
const MIN_SCREEN_HEIGHT = 520
const CAMERA_MIN_X = -800
const CAMERA_MAX_X = 800
const CAMERA_Y = -648.5
@onready var camera: Camera2D = $Camera2D
@onready var camera_pos: Vector2 = position.clamp(Vector2(CAMERA_MIN_X,CAMERA_Y),Vector2(CAMERA_MAX_X,CAMERA_Y))
var camera_i: Vector2 = Vector2.ZERO

# User Input Mapping
func _input(event: InputEvent) -> void:
	if !is_spawned:
		return
	
func _read_player_input(up: String, down: String, left: String, right: String, jump: String, dash: String, melee: String, shoot: String) -> void:
	if !is_spawned:
		input_up = false
		input_down = false
		input_left = false
		input_right = false
		input_jump = false
		input_dash = false
		input_melee = false
		input_shoot = false
		input_dialup = false
		input_dialdown = false
		return
	
	var final_up = up
	var final_down = down
	var final_left = left
	var final_right = right
	
	if is_stun:
		input_up = false
		input_down = false
		input_left = Input.is_action_pressed(final_left)
		input_right = Input.is_action_pressed(final_right)
		input_jump = false
		input_dash = Input.is_action_just_pressed(dash)
		input_melee = false
		input_shoot = false
		input_dialup = false
		input_dialdown = false
		return
	
	input_up = Input.is_action_pressed(final_up)
	input_down = Input.is_action_pressed(final_down)
	input_left = Input.is_action_pressed(final_left)
	input_right = Input.is_action_pressed(final_right)
	input_jump = Input.is_action_just_pressed(jump)
	input_dash = Input.is_action_just_pressed(dash)
	input_melee = Input.is_action_just_pressed(melee)
	input_shoot = Input.is_action_just_pressed(shoot)
	input_dialup = false
	input_dialdown = false
	
	if is_aiming:
		input_up = false
		input_down = false
		input_left = Input.is_action_pressed(final_left)
		input_right = Input.is_action_pressed(final_right)
		input_jump = false
		input_dash = false
		input_melee = Input.is_action_just_pressed(melee)
		input_shoot = Input.is_action_just_pressed(shoot)
		input_dialup = Input.is_action_pressed(up)
		input_dialdown = Input.is_action_pressed(down)
	
func reset_state():
	is_stun = false
	if is_aiming:
		exit_aiming()
	is_dead = false
	is_climbing = false
	HEALTH = 100.0
	base_velocity = 0.0
	knockback_velocity = 0.0
	velocity = Vector2.ZERO
	dash_cd = 0
	melee_cd = 0
	shoot_cd = 0
	climb_cd = 0
	
func _ready() -> void:
	add_to_group("player")
	aim_dot.visible = false
	is_spawned = true
	camera.position = camera_pos
	climbup_hitbox.area_entered.connect(_on_climb_up_area_entered)
	climbup_hitbox.area_exited.connect(_on_climb_up_area_exited)
	climbdown_hitbox.area_entered.connect(_on_climb_down_area_entered)
	climbdown_hitbox.area_exited.connect(_on_climb_down_area_exited)
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	match control_type:
		"P1":
			_read_player_input("Player1_UP", "Player1_DOWN",
							   "Player1_LEFT", "Player1_RIGHT",
							   "Player1_JUMP", "Player1_DASH",
							   "Player1_MELEE", "Player1_SHOOT")
		"P2":
			_read_player_input("Player2_UP", "Player2_DOWN",
							   "Player2_LEFT", "Player2_RIGHT",
							   "Player2_JUMP", "Player2_DASH",
							   "Player2_MELEE", "Player2_SHOOT")
	
	var grounded = is_on_floor()
	# Climbing start action
	if can_climb:
		if not is_aiming or not is_stun:
			if not is_climbing and climb_cd <= 0:
				if input_up and can_climb_up:
					set_climbing(true)
				elif input_down and can_climb_down:
					set_climbing(true)
	else:
		set_climbing(false)
	# Snapping to rope center
	if is_climbing and not was_climbing:
		if active_rope != null:
			global_position.x = active_rope.get_center_x()
			
			base_velocity = 0.0
			velocity.x = 0.0
			
	was_climbing = is_climbing
	# Climbing action
	if is_climbing:
		if input_up:
			velocity.y = move_toward(velocity.y, -CLIMB_SPEED, CLIMB_ACCELERATION)
		elif input_down:
			velocity.y = move_toward(velocity.y, CLIMB_SPEED, CLIMB_ACCELERATION)
		else:
			velocity.y = move_toward(velocity.y, 0, CLIMB_DECELERATION)
		base_velocity = 0
		grounded = false
	else:
		# Gravity
		if not grounded:
			velocity.y += GRAVITY * delta
	# Horizontal movement
	if input_right:
		facing_dir = 1.0
		dir = 1.0
	elif input_left:
		facing_dir = -1.0
		dir = -1.0
	else:
		dir = 0.0
	# Debuff override
	if is_aiming or is_stun or is_climbing:
		dir = 0.0
	# Jumping action
	if input_jump and is_on_floor() and not is_aiming:
		velocity.y = JUMP_VELOCITY

	# Velocity.x checkout
	if grounded:
		base_velocity = move_toward(base_velocity, dir * MAX_SPEED, GROUND_ACCELERATION)
		knockback_velocity = move_toward(knockback_velocity, 0, GROUND_DECELERATION)
	else:
		base_velocity = move_toward(base_velocity, dir * MAX_SPEED, JUMP_ACCELERATION)
		knockback_velocity = move_toward(knockback_velocity, 0, JUMP_DECELERATION)
	# Rope escape jump
	if input_jump and is_climbing:
		if input_right:
			set_climbing(false)
			velocity.y = JUMPOFF_SPEED_Y
			base_velocity = facing_dir * JUMPOFF_SPEED_X
			climb_cd = CLIMB_CD
		elif input_left:
			set_climbing(false)
			velocity.y = JUMPOFF_SPEED_Y
			base_velocity = facing_dir * JUMPOFF_SPEED_X
			climb_cd = CLIMB_CD
	
	velocity.x = base_velocity + knockback_velocity
	move_and_slide()
	if not is_aiming and not is_climbing:
		# Dash
		if input_dash and dash_cd <= 0:
				dash_dir = facing_dir
				dash_cd = DASH_CD
				dash_duration = DASH_DURATION
		
		if dash_duration > 0:
			var dash_progress : float = (dash_duration / DASH_DURATION) ** 3
			var dash_distance : float = dash_dir * DASH_DISTANCE * sin(dash_progress * PI)
			can_climb = false
			velocity.y = 0.0
			move_and_collide(Vector2(dash_distance, 0))
		# Melee
		if input_melee and melee_cd <= 0 and not is_aiming:
			melee_cd = MELEE_CD
			melee(MELEE_DMG, MELEE_KNOCKBACK, facing_dir, PLAYER_ID ,TEAM_ID)
			print(is_climbing)
	
	if not is_climbing:
		# Range
		if input_shoot and shoot_cd <= 0 and not is_aiming:
			shoot_cd = SHOOT_CD
			aim_cd = AIM_CD
			aim_angle = randf_range(-PI/2, PI/2)
			enter_aiming()
		
		elif is_aiming:
			if input_dialup:
				aim_angle -= delta * DIAL_SPEED
			if input_dialdown:
				aim_angle += delta * DIAL_SPEED
			aim_angle = clamp(aim_angle, -PI/2, PI/2)
		
			if facing_dir == -1.0:
				shoot_angle = PI - aim_angle
			else:
				shoot_angle = aim_angle
			center.rotation = shoot_angle
			
			if input_shoot and aim_cd <= 0:
				shoot_projectile(PROJECTILE_DMG, PROJECTILE_KNOCKBACK, shoot_angle, PLAYER_ID ,TEAM_ID)
				exit_aiming()
				shoot_cd = SHOOT_CD
			if input_melee:
				exit_aiming()
	# Cooldown
	if stun_cd <= 0:
		is_stun = false
	stun_cd = max(stun_cd - delta, 0.0)
	climb_cd = max(climb_cd - delta, 0.0)
	dash_cd = max(dash_cd - delta, 0.0)
	dash_duration = max(dash_duration - delta, 0.0)
	melee_cd = max(melee_cd - delta, 0.0)
	aim_cd = max(aim_cd - delta, 0.0)
	shoot_cd = max(shoot_cd - delta, 0.0)
	
	# World Boundary
	if position.y > Y_BOUNDARY:
		take_damage(100,0,0)
	
	# Camera
	move_and_scale_camera()
	
func take_damage(amount: float, attacker_id: int, attacker_team: int) -> void:
	if is_dead:
		return
	
	HEALTH -= amount * damage_reduction
	if HEALTH <= 0.0:
		is_dead = true
		velocity = Vector2.ZERO
		base_velocity = 0.0
		knockback_velocity = 0.0
		
		player_eliminated.emit(self)

func apply_knockback(dir: float, knockback: float) -> void:
	if is_climbing == true:
		is_climbing = false
	exit_aiming()
	is_stun = true
	stun_cd = STUN_CD
	knockback_velocity += dir * knockback
	
# Utility Function

func _on_climb_up_area_entered(area: Area2D) -> void:
	_climb_target(area, true, true)

func _on_climb_up_area_exited(area: Area2D) -> void:
	_climb_target(area, false, true)

func _on_climb_down_area_entered(area: Area2D) -> void:
	_climb_target(area, true, false)

func _on_climb_down_area_exited(area: Area2D) -> void:
	_climb_target(area, false, false)
	
# Climbing Hitbox
func _climb_target(target: Node, hit: bool, is_up_detector: bool) -> void:
	var rope: Node = target
	# ClimbDetector Collision 4
	if target is Area2D:
		rope = target.get_parent()
	if not (rope is Line2D and rope.is_in_group("rope")):
		return
	# Enter
	if hit and not is_stun:
		active_rope = rope
		# Smaller Detector Hitbox for climbing up
		if is_up_detector:
			can_climb_up = true
		# Larger Detector Hitbox for climbing down
		else:
			can_climb_down = true
	# Exit
	else:
		# Clear the rope
		set_climbing(false)
		active_rope = null
		can_climb_up = false
		can_climb_down = false
		can_climb = false

	can_climb = can_climb_up or can_climb_down
	
func set_climbing(state: bool) -> void:
	is_climbing = state
	# Disable platform Collision 1 for passthrough
	set_collision_mask_value(1, not state)
		
func melee(base_damage: float, knockback: float, facing_dir: float, attacker_id: int, attacker_team: int) -> void:
	var melee_instance = MELEE_SCENE.instantiate()
	# Melee Collision 3
	melee_instance.ATTACKER_ID = attacker_id
	melee_instance.ATTACKER_TEAM = attacker_team
	melee_instance.facing_dir = facing_dir
	melee_instance.damage = base_damage
	melee_instance.knockback = knockback
	melee_hitbox.position.x = abs(melee_hitbox.position.x) * facing_dir
	melee_hitbox.add_child(melee_instance)
	
func enter_aiming() -> void:
	is_aiming = true
	aim_dot.visible = true

func exit_aiming() -> void:
	is_aiming = false
	aim_dot.visible = false
	
func shoot_projectile(base_damage: float, knockback: float, angle: float, attacker_id: int, attacker_team: int) -> void:
	var projectile_instance = PROJECTILE_SCENE.instantiate()
	# Projectile Collision 2
	projectile_instance.ATTACKER_ID = attacker_id
	projectile_instance.ATTACKER_TEAM = attacker_team
	projectile_instance.global_position = projectile.global_position
	projectile_instance.facing_angle = angle
	projectile_instance.facing_dir = facing_dir
	projectile_instance.damage = base_damage
	projectile_instance.knockback = knockback
	get_parent().add_child(projectile_instance)

func enemy_ai() -> void:
	pass

func move_and_scale_camera():
	var camera_target = Vector2(clamp(position.x,CAMERA_MIN_X,CAMERA_MAX_X),CAMERA_Y)
	if get_viewport().size.y > MIN_SCREEN_HEIGHT:
		camera.zoom = Vector2.ONE * .5 * floor(get_viewport().size.y/MIN_SCREEN_HEIGHT)
	else:
		var covered_area = MIN_SCREEN_HEIGHT - get_viewport().size.y
		camera.zoom = Vector2.ONE * .5
		camera_target.y = clamp(position.y,CAMERA_Y-covered_area,CAMERA_Y+covered_area)
	var P = camera_target - camera_pos
	camera_i += P
	camera_pos += P * .08 + camera_i * .0007
	camera.global_position = camera_pos
	
