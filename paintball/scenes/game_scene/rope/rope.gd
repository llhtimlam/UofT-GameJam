extends Line2D

@onready var HITBOX: CollisionShape2D = $Area2D/CollisionShape2D
@onready var ROPE_AREA: Area2D = $Area2D

var tilemap: TileMapLayer

func _ready() -> void:
	add_to_group("rope")
	
func setup_rope(top_cell: Vector2i, bottom_cell: Vector2i) -> void:
	# Request global coordinate
	var top := tilemap.to_global(tilemap.map_to_local(top_cell))
	var bottom := tilemap.to_global(tilemap.map_to_local(bottom_cell))
	# top.y cover whole tile, bottom.y cover top half tile (center)
	var tile_height: float = tilemap.tile_set.tile_size.y * tilemap.scale.y
	var top_y: float = top.y - tile_height / 2.0
	var bottom_y: float = bottom.y
	# top.x should equal to bottom.x
	var top_pos := Vector2(top.x, top_y)
	var bottom_pos := Vector2(bottom.x, bottom_y)
	# Line2D origin at top point
	global_position = top_pos
	# Set Line2D (local coordinate)
	clear_points()
	add_point(Vector2.ZERO) # Top point
	add_point(to_local(bottom_pos)) # Bottom point
	
	var rope_length := top_pos.distance_to(bottom_pos)
	# Area2D origin at center (local coordinate)
	ROPE_AREA.position = (Vector2.ZERO + to_local(bottom_pos)) / 2.0
	# CollisionShape2D origin at center (local coordinate)
	var shape := HITBOX.shape.duplicate() as SegmentShape2D
	HITBOX.shape = shape
	HITBOX.position = Vector2.ZERO
	shape.a = Vector2(0, -rope_length / 2.0)
	shape.b = Vector2(0, rope_length / 2.0)

func get_center_x() -> float:
	return global_position.x
	
func get_top_y() -> float:
	return to_global(get_point_position(0)).y

func get_bottom_y() -> float:
	return to_global(get_point_position(1)).y
