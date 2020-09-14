extends Node2D

func _ready():
	#$Opening/CollisionShape2D.disabled = false
	pass


func _on_Area2D_body_entered(_body: CollisionObject2D):
	if WebMonetization.is_paying():
		$Opening/CollisionShape2D.set_deferred("disabled", true)
		$Left.play("open")
		$Right.play("open")


func _on_Area2D_body_exited(_body: CollisionObject2D):
	if WebMonetization.is_paying():
		$Opening/CollisionShape2D.set_deferred("disabled", false)
		$Left.play("close")
		$Right.play("close")

