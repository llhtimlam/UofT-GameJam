extends Node2D

# Handle the motion of both player cameras as well as communication with the
# SplitScreen shader to achieve the dynamic split screen effet
#
# Cameras are place on the segment joining the two players, either in the middle
# if players are close enough or at a fixed distance if they are not.
# In the first case, both cameras being at the same location, only the view of
# the first one is used for the entire screen thus allowing the players to play
# on a unsplit screen.
# In the second case, the screen is split in two with a line perpendicular to the
# segement joining the two players.
#
# The points of customization are:
#   max_separation: the distance between players at which the view starts to split
#   split_line_thickness: the thickness of the split line in pixels
#   split_line_color: color of the split line
#   adaptive_split_line_thickness: if true, the split line thickness will vary
#       depending on the distance between players. If false, the thickness will
#       be constant and equal to split_line_thickness

const MERGE_PROPORTION: float = 0.75
const SPLIT_PROPORTION: float = 0.75
const SCREEN_MERGE_DIST: float = 5.0
const SCREEN_MERGE_DIST_2D: float = 15.0

var combined: bool = false
var split_active: bool = false

@export var merge_distance: float = 750.0
@export var split_distance: float = 850.0

@export var max_separation: float = 20.0

@export var split_line_thickness: float = 3.0
@export var split_line_color: Color = Color.BLACK
@export var adaptive_split_line_thickness: bool = true

@export var player1: CharacterBody2D
@export var player2: CharacterBody2D
@onready var view = $View
@onready var viewport1 = $Viewport1
@onready var viewport2 = $Viewport2
@onready var camera1 = viewport1.get_node(^"Camera1")
@onready var camera2 = viewport2.get_node(^"Camera2")

var viewport_base_height = ProjectSettings.get_setting("display/window/size/viewport_height")

func _ready():
	viewport1.world_2d = get_viewport().world_2d
	viewport2.world_2d = get_viewport().world_2d
	print("Viewport1 World: ", viewport1.world_2d)
	print("Viewport2 World: ", viewport2.world_2d)
	print("Main World: ", get_viewport().world_2d)
	_on_size_changed()
	_update_splitscreen()

	get_viewport().size_changed.connect(_on_size_changed)
	
	view.material.set_shader_parameter("viewport1", viewport1.get_texture())
	view.material.set_shader_parameter("viewport2", viewport2.get_texture())

func _process(_delta):
	_update_splitscreen()
	_move_cameras(_delta)

func _move_cameras(delta: float):
	var p1 = player1.global_position
	var p2 = player2.global_position
	var center = (p1 + p2) * 0.5

	var direction = (p2 - p1).normalized()

	var correction_distance = viewport1.size.x * 0.25 / camera1.zoom.x
	var correction = direction * correction_distance

	var target1: Vector2
	var target2: Vector2

	if combined:
		target1 = center
		target2 = center
	else:
		target1 = p1
		target2 = p2
		# Correction doesnt work and sign is weird, one scenario (P2 -x P1 0) need viewport swap
		#if p1.x < p2.x:
			# P1 is left, P2 is right.
			#target1 = p1 - correction
			#target2 = p2 + correction
		#else:
			# P2 is left, P1 is right.
			#target1 = p1 + correction
			#target2 = p2 - correction

	var weight = 1.0 - exp(-8.0 * delta)

	camera1.global_position = camera1.global_position.lerp(target1, weight)
	camera2.global_position = camera2.global_position.lerp(target2, weight)

func _update_splitscreen():
	var screen_size = get_viewport().get_visible_rect().size

	# Player positions in screen proportions.
	var p1_prop = player1.get_global_transform_with_canvas().origin / screen_size
	var p2_prop = player2.get_global_transform_with_canvas().origin / screen_size
	
	var distance = player1.global_position.distance_to(player2.global_position)
	
	if combined and distance > split_distance:
		combined = false
		camera1.reset_physics_interpolation()
		camera2.reset_physics_interpolation()

	elif not combined and distance < merge_distance:
		combined = true
		camera1.reset_physics_interpolation()
		camera2.reset_physics_interpolation()

	split_active = not combined
	
	var thickness
	if adaptive_split_line_thickness:
		var position_difference = _compute_position_difference_in_world()
		#var distance = _compute_horizontal_length(position_difference)
		thickness = lerpf(0, split_line_thickness, (distance - max_separation) / max_separation)
		thickness = clampf(thickness, 0, split_line_thickness)
	else:
		thickness = split_line_thickness

	view.material.set_shader_parameter("split_active", split_active)
	view.material.set_shader_parameter("player1_position", p1_prop)
	view.material.set_shader_parameter("player2_position", p2_prop)
	view.material.set_shader_parameter("split_line_thickness", thickness)
	view.material.set_shader_parameter("split_line_color", split_line_color)

# Split screen is active if players are too far apart from each other.
# Only the horizontal components (x, z) are used for distance computation
func _get_split_state():
	var position_difference = _compute_position_difference_in_world()
	var separation_distance = _compute_horizontal_length(position_difference)
	return separation_distance > max_separation


func _on_size_changed():
	var screen_size = get_viewport().get_visible_rect().size

	$Viewport1.size = screen_size
	$Viewport2.size = screen_size
	print($Viewport1.size)
	view.material.set_shader_parameter("viewport_size", screen_size)


func _compute_position_difference_in_world():
	return player2.global_position - player1.global_position


func _compute_horizontal_length(vec):
	return Vector2(vec.x, vec.y).length()
