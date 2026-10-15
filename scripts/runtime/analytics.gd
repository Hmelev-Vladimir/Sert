## NEONLINE — Autoload: Analytics.
## Funnel + retention tracking with a pluggable sink (console by default).
## Wire to Firebase/Amplitude/GameAnalytics by implementing `flush()` below.
extends Node

var _buffer: Array = []
var session_id := ""
var enabled := true


func _ready() -> void:
	session_id = "%s-%d" % [Time.get_datetime_string_from_system(false, true), randi() % 100000]
	track("session_start", {"app_version": "0.1.0"})


func track(event: String, props: Dictionary = {}) -> void:
	if not enabled:
		return
	var row := props.duplicate(true)
	row["_event"] = event
	row["_age"] = GameState.age
	row["_credits"] = GameState.credits
	row["_session"] = session_id
	row["_t"] = Time.get_unix_time_from_system()
	_buffer.append(row)
	if _buffer.size() >= 20:
		flush()


func flush() -> void:
	if _buffer.is_empty():
		return
	# Default sink: console. Replace with HTTPS POST to your endpoint.
	for row in _buffer:
		print("[ANALYTICS] ", JSON.stringify(row))
	_buffer.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush()
