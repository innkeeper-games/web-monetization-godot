extends Node2D

onready var initial_panel_position: Vector2 = $PanelContainer.rect_position

func _ready() -> void:
	var _error = WebMonetization.connect("on_monetization_started", self, "_on_monetization_started")
	$PanelContainer.rect_position -= $PanelContainer.rect_size
	hide()


func open() -> void:
	show()


func close() -> void:
	hide()


func is_open() -> bool:
	return visible


func _on_monetization_started() -> void:
	$PanelContainer/Label.text = """Thanks for supporting our
	work with Web Monetization!"""
