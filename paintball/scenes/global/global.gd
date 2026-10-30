extends Node

var normalized_p1_color : Vector3 = Vector3(1., 0., 0.)
var normalized_turret_color : Vector3 = Vector3(0., 1., 0.)
var normalized_p2_color : Vector3 = Vector3(0., 0., 1.)

var p1_color : Color = Color(255,0,0):
	set(value):
		p1_color = value
		normalized_p1_color = Vector3(value.r, value.g, value.b)
var turret_color : Color = Color(0,255,0):
	set(value):
		turret_color = value
		normalized_turret_color = Vector3(value.r, value.g, value.b)
var p2_color : Color = Color(0,0,255):
	set(value):
		p2_color = value
		normalized_p2_color = Vector3(value.r, value.g, value.b)

var white_blend_intensity : float = 0.99
