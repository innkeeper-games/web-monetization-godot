extends KinematicBody2D

const SPEED = 150

var target: Vector2
var direction: Vector2 = Vector2(0, 0)
var move_vector: Vector2 = Vector2(0, 0)

var initial_position: Vector2


func _ready() -> void:
	target = position


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("interact"):
		var click_position: Vector2 = get_viewport().canvas_transform.affine_inverse().xform(get_viewport().get_mouse_position())
		move_and_slide(position.direction_to(click_position) * SPEED)
