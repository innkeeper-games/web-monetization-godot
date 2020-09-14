extends Node

var paying: bool
var poll: Timer

signal on_monetization_started
signal on_monetization_stopped

func _ready() -> void:
	if JavaScript.eval("(document.monetization !== null);"):
		poll = Timer.new()
		add_child(poll)
		poll.connect("timeout", self, "_on_poll_timeout")
		poll.one_shot = false
		poll.start(1)
		# you can also emit a "pending" signal here to indicate loading


func _on_poll_timeout() -> void:
	if JavaScript.eval("(document.monetization.state === 'started');"):
		if not paying:
			emit_signal("on_monetization_started")
			paying = true
	elif paying:
		paying = false
		emit_signal("on_monetization_stopped")


func is_paying() -> bool:
	return paying
