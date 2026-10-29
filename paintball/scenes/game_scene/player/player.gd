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
@export var MELEE_DMG: float = 40.0
@export var MELEE_KNOCKBACK: float = 600.0
@export var PROJECTILE_DMG: float = 50.0
@export var PROJECTILE_SPEED: float = 800.0
@export var PROJECTILE_KNOCKBACK: float = 800.0
const JUMP_VELOCITY = -1200.0
var SLOWNESS_MODIFIER: float = 0.6
@export var DASH_CD: float = 0.8
var DASH_DURATION: float = 0.5
var DASH_DISTANCE: float = 5.0
@export var MELEE_CD: float = 0.8
var AIM_CD: float = 0.0
@export var SHOOT_CD: float = 4.0
var DIAL_SPEED: float = 2.0
var FINE_DIAL_SPEED: float = 0.5
var IFRAME: float = 3.0

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
var input_finedial: bool = false

var stun_cd: float = 0.0
var climb_cd: float = 0.0
var dash_cd: float = 0.0
var dash_duration: float = 0.0
var melee_cd: float = 0.0
var aim_cd: float = 0.0
var shoot_cd: float = 0.0
var dir: float
var dash_dir: float

var held_bucket: Node2D = null
@onready var bucket_slot: Marker2D = $BucketPosition

var is_dead: bool = false
var iframe: float = 1.0

# Crouching
var is_crouching: bool = false
@onready var hurtbox: CollisionShape2D = $Hurtbox

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
var is_slow: bool = false

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
const Y_BOUNDARY = 200

# Camera
const MIN_SCREEN_HEIGHT = 550
const CAMERA_MIN_X = -848
const CAMERA_MAX_X = 864
const CAMERA_Y = -648.5
@onready var camera: Camera2D = $Camera2D
@onready var camera_pos: Vector2 = position.clamp(Vector2(CAMERA_MIN_X,CAMERA_Y),Vector2(CAMERA_MAX_X,CAMERA_Y))
var camera_i: Vector2 = Vector2.ZERO
var screens_merging = false
var camera_target = Vector2.ZERO

# UI
const INDICATOR_Y = -60
const INDICATOR_BUCKET_Y = -90
@onready var StunBar: TextureProgressBar = $StunBar
@onready var DashBar: TextureProgressBar = $DashBar
var stun_max: float = 1.

# User Input Mapping
#func _input(event: InputEvent) -> void:
#	if !is_spawned:
#		return
	
func _read_player_input(a_up: String, a_down: String, a_left: String, a_right: String, a_jump: String, a_dash: String, a_melee: String, a_shoot: String) -> void:
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
	
	if is_stun:
		input_up = false
		input_down = false
		input_left = Input.is_action_pressed(a_left)
		input_right = Input.is_action_pressed(a_right)
		input_jump = false
		input_dash = Input.is_action_just_pressed(a_dash)
		input_melee = false
		input_shoot = false
		input_dialup = false
		input_dialdown = false
		return
	
	input_up = Input.is_action_pressed(a_up)
	input_down = Input.is_action_pressed(a_down)
	input_left = Input.is_action_pressed(a_left)
	input_right = Input.is_action_pressed(a_right)
	input_jump = Input.is_action_just_pressed(a_jump)
	input_dash = Input.is_action_just_pressed(a_dash)
	input_melee = Input.is_action_just_pressed(a_melee)
	input_shoot = Input.is_action_pressed(a_shoot)
	input_dialup = false
	input_dialdown = false
	
	if is_aiming:
		input_up = false
		input_down = false
		input_left = Input.is_action_pressed(a_left)
		input_right = Input.is_action_pressed(a_right)
		input_jump = false
		input_dash = false
		input_melee = Input.is_action_just_pressed(a_melee)
		input_shoot = Input.is_action_just_released(a_shoot)
		input_dialup = Input.is_action_pressed(a_up)
		input_dialdown = Input.is_action_pressed(a_down)
		input_finedial = Input.is_action_pressed(a_jump)
	
	if input_left and input_right:
		input_left = false
		input_right = false
	
func reset_state():
	is_stun = false
	is_crouching = false
	is_climbing = false
	if is_aiming:
		exit_aiming()
	is_slow = false
	if is_instance_valid(held_bucket):
		held_bucket.queue_free()
	held_bucket = null
	is_dead = false
	HEALTH = 100.0
	base_velocity = 0.0
	knockback_velocity = 0.0
	velocity = Vector2.ZERO
	dash_cd = 0
	melee_cd = 0
	shoot_cd = 0
	climb_cd = 0
	stun_cd = 0
	iframe = IFRAME
	self.visible = true
	set_physics_process(true)
	hurtbox.set_deferred("disabled", false)
	
func _ready() -> void:
	add_to_group("player")
	if hurtbox and hurtbox.shape:
		hurtbox.shape = hurtbox.shape.duplicate()
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
	
	# UI
	StunBar.value = stun_cd/stun_max
	StunBar.Scale = camera.zoom.x
	DashBar.value = dash_cd/DASH_CD
	DashBar.Scale = camera.zoom.x
	if is_instance_valid(held_bucket):
		StunBar.Location = Vector2(0,INDICATOR_BUCKET_Y)
		DashBar.Location = Vector2(0,INDICATOR_BUCKET_Y)
	else:
		StunBar.Location = Vector2(0,INDICATOR_Y)
		DashBar.Location = Vector2(0,INDICATOR_Y)
	
	
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
	# Crouching
	if not is_aiming and not is_stun and not is_climbing and grounded and input_down:
		is_crouching = true
	else:
		is_crouching = false
	if is_crouching:
		hurtbox.shape.size = Vector2(52,36)
		if facing_dir == -1.0:
			hurtbox.position = Vector2(-10,14)
			bucket_slot.position = Vector2(-20,-20)
		else:
			hurtbox.position = Vector2(10,14)
			bucket_slot.position = Vector2(20,-20)
	else:
		hurtbox.shape.size = Vector2(32,64)
		hurtbox.position = Vector2.ZERO
		bucket_slot.position = Vector2(0,-48)
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
	if is_slow or is_crouching:
		dir *= SLOWNESS_MODIFIER
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
	if not is_aiming and not is_stun and not is_climbing:
		# Dash
		if input_dash and dash_cd <= 0:
				dash_dir = facing_dir
				dash_cd = DASH_CD
				dash_duration = DASH_DURATION
		
		if dash_duration > 0:
			var dash_progress : float = (dash_duration / DASH_DURATION) ** 3
			var dash_distance : float = dash_dir * DASH_DISTANCE * sin(dash_progress * PI)
			if dash_duration > DASH_DURATION / 2:
				velocity.y = 0.0
			move_and_collide(Vector2(dash_distance, 0))
		# Melee
		if input_melee and melee_cd <= 0 and not is_aiming:
			melee_cd = MELEE_CD
			melee(MELEE_DMG, MELEE_KNOCKBACK, facing_dir, PLAYER_ID ,TEAM_ID)
	
	if not is_climbing:
		# Range
		if input_shoot and shoot_cd <= 0 and not is_aiming:
			if aim_cd <= 0:
				aim_angle = 0
			aim_cd = AIM_CD
			enter_aiming()
		
		elif is_aiming:
			if input_dialup:
				if input_finedial:
					aim_angle -= delta * FINE_DIAL_SPEED
				else:
					aim_angle -= delta * DIAL_SPEED
			if input_dialdown:
				if input_finedial:
					aim_angle += delta * FINE_DIAL_SPEED
				else:
					aim_angle += delta * DIAL_SPEED
			aim_angle = clamp(aim_angle, -PI/2, PI/2)
		
			if facing_dir == -1.0:
				shoot_angle = PI - aim_angle
			else:
				shoot_angle = aim_angle
			center.rotation = shoot_angle
			
			if input_shoot and aim_cd <= 0:
				shoot_projectile(PROJECTILE_DMG, PROJECTILE_SPEED, PROJECTILE_KNOCKBACK, facing_dir, shoot_angle, PLAYER_ID ,TEAM_ID)
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
	iframe = max(iframe - delta, 0.0)
	
	# World Boundary
	if position.y > Y_BOUNDARY:
		take_damage(100,0,0)
	
	# Camera
	move_and_scale_camera()
	
func take_damage(amount: float, attacker_id: int, attacker_team: int) -> void:
	if is_dead:
		return
	if iframe > 0 and attacker_team != 0:
		return
		
	HEALTH -= amount * damage_reduction
	if HEALTH <= 0.0:
		if is_instance_valid(held_bucket):
			held_bucket.transfer(attacker_id, attacker_team)
		is_dead = true
		velocity = Vector2.ZERO
		base_velocity = 0.0
		knockback_velocity = 0.0
		self.visible = false
		set_physics_process(false)
		hurtbox.set_deferred("disabled", true)
		player_eliminated.emit(self, attacker_id, attacker_team)

func apply_knockback(k_dir: float, knockback: float, stun_time: float = STUN_CD) -> void:
	if iframe > 0:
		return
	if is_climbing == true:
		is_climbing = false
	is_crouching = false
	exit_aiming()
	is_stun = true
	if stun_cd < stun_time:
		stun_cd = stun_time
		stun_max = stun_time
	knockback_velocity += k_dir * knockback
	
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
		
func melee(base_damage: float, knockback: float, m_facing_dir: float, attacker_id: int, attacker_team: int) -> void:
	var melee_instance = MELEE_SCENE.instantiate()
	# Melee Collision 3
	melee_instance.ATTACKER_ID = attacker_id
	melee_instance.ATTACKER_TEAM = attacker_team
	melee_instance.facing_dir = m_facing_dir
	melee_instance.damage = base_damage
	melee_instance.knockback = knockback
	melee_hitbox.position.x = abs(melee_hitbox.position.x) * facing_dir
	melee_hitbox.reset_physics_interpolation()
	melee_hitbox.add_child(melee_instance)
	
func enter_aiming() -> void:
	is_aiming = true
	aim_dot.visible = true

func exit_aiming() -> void:
	is_aiming = false
	aim_dot.visible = false
	
func shoot_projectile(base_damage: float, speed: float, knockback: float, p_facing_dir: float, angle: float, attacker_id: int, attacker_team: int) -> void:
	var projectile_instance = PROJECTILE_SCENE.instantiate()
	# Projectile Collision 2
	projectile_instance.ATTACKER_ID = attacker_id
	projectile_instance.ATTACKER_TEAM = attacker_team
	projectile_instance.global_position = projectile.global_position
	projectile_instance.facing_angle = angle
	projectile_instance.facing_dir = p_facing_dir
	projectile_instance.damage = base_damage
	projectile_instance.speed = speed
	projectile_instance.knockback = knockback
	get_parent().get_parent().add_child(projectile_instance)

func enemy_ai() -> void:
	pass

func move_and_scale_camera():
	if not screens_merging: #let ui.gd override the target if merging
		camera_target = Vector2(clamp(position.x,CAMERA_MIN_X,CAMERA_MAX_X),CAMERA_Y)
	if get_viewport().size.y > MIN_SCREEN_HEIGHT:
		camera.zoom = Vector2.ONE * .5 * floor(get_viewport().size.y/MIN_SCREEN_HEIGHT)
	else:
		var covered_area = MIN_SCREEN_HEIGHT - get_viewport().size.y
		camera.zoom = Vector2.ONE * .5
		if not screens_merging:
			camera_target.y = clamp(position.y,CAMERA_Y-covered_area,CAMERA_Y+covered_area)
	var P = camera_target - camera_pos
	camera_i += P
	camera_pos += P * .08 + camera_i * .0007
	camera.global_position = camera_pos
	
