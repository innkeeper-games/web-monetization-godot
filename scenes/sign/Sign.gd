extends StaticBody2D

var delay_timer

func _on_Area2D_body_entered(body) -> void:
	if body is KinematicBody2D:
		$DelayTimer.start()


func _on_Area2D_body_exited(body) -> void:
	$PopupMessage.close()


func _on_DelayTimer_timeout() -> void:
	if not $PopupMessage.is_open():
		$PopupMessage.open()
