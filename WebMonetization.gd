extends Node

var _paying: bool
var _poll: Timer

signal on_monetization_started
signal on_monetization_stopped

func _ready() -> void:
	if JavaScript.eval("(document.monetization !== undefined);"):
		_poll = Timer.new()
		add_child(_poll)
		var _error = _poll.connect("timeout", self, "_on_poll_timeout")
		_poll.one_shot = false
		_poll.start(1)
		# you can also emit a "pending" signal here to indicate loading


func _on_poll_timeout() -> void:
	if JavaScript.eval("(document.monetization.state === 'started');"):
		if not _paying:
			emit_signal("on_monetization_started")
			_paying = true
			#_poll.queue_free()
	elif _paying:
		_paying = false
		emit_signal("on_monetization_stopped")


func is_paying() -> bool:
	return _paying
