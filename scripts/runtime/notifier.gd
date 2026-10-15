## NEONLINE — Autoload: Notifier.
## Local notifications ("your character grew up!") via the platform backend when
## available, safe no-op elsewhere. Rate-limited to avoid spamming users.
extends Node

var last_sent_unix := 0.0
const MIN_GAP_S := 6 * 3600.0


func schedule_life(id: int, title: String, body: String, delay_sec: float) -> void:
	if Time.get_unix_time_from_system() - last_sent_unix < MIN_GAP_S and delay_sec < 60.0:
		return
	last_sent_unix = Time.get_unix_time_from_system()
	if OS.has_feature("mobile_android") or OS.has_feature("ios"):
		# With godot-android / ios plugins installed:
		# AndroidNotifications.schedule_notification(id, title, body, delay_sec*1000)
		print("[NOTIFY] scheduled #%d: %s — %s (in %.0fs)" % [id, title, body, delay_sec])
	else:
		print("[NOTIFY] (desktop preview) #%d: %s — %s" % [id, title, body])


func notify_now(title: String, body: String) -> void:
	schedule_life(randi() % 100000, title, body, 0.0)
