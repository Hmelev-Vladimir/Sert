## NEONLINE — Autoload: EventEngine.
## Data-driven event cards from res://data/events.json. Filters by age / stat
## thresholds / karma / owned implants, rolls weighted picks per year, applies
## choice outcomes and returns a presentation-ready dict for the event card UI.
##
## Event schema (JSON):
## {
##   "id": "street_doc_offer",
##   "min_age": 16, "max_age": 99, "weight": 3,
##   "once": true,                     # fires at most once per life
##   "requires": {"stat": {"health": [0, 40]}},   # ranges checked against stats
##   "text": "A ripperdoc under the overpass offers you a deal…",
##   "tag": "medical",
##   "options": [
##     {"id":"accept","label":"Take the chrome","effects":{"health":-8,"cool":6,"credits":-1200},
##      "log":"You got street chrome installed."},
##     {"id":"walk","label":"Walk away","effects":{"happiness":-2},"log":"You kept your flesh."}
##   ]
## }
extends Node

var fired_once: Array = []        # ids consumed this life
var _last_event: Dictionary = {}


func reset_for_new_life() -> void:
	fired_once.clear()
	_last_event.clear()


## Roll one eligible event for the current state. Returns {} when nothing fits.
func roll_event() -> Dictionary:
	var pool: Array = []
	for ev in DataService.events:
		if not is_eligible(ev):
			continue
		pool.append(ev)
	if pool.is_empty():
		return {}
	# weighted pick
	var total_w := 0
	for ev in pool:
		total_w += maxi(1, int(ev.get("weight", 1)))
	var pick := GameState.rng.randi_range(1, total_w)
	for ev in pool:
		pick -= maxi(1, int(ev.get("weight", 1)))
		if pick <= 0:
			_last_event = ev
			if bool(ev.get("once", false)):
				fired_once.append(ev["id"])
			SignalBus.event_emitted.emit(ev["id"])
			return ev
	return {}


func is_eligible(ev: Dictionary) -> bool:
	if bool(ev.get("once", false)) and ev.get("id", "") in fired_once:
		return false
	if GameState.age < int(ev.get("min_age", 0)):
		return false
	if GameState.age > int(ev.get("max_age", 999)):
		return false
	if ev.has("karma_min") and GameState.karma < int(ev["karma_min"]):
		return false
	if ev.has("karma_max") and GameState.karma > int(ev["karma_max"]):
		return false
	if ev.has("requires"):
		var req: Dictionary = ev["requires"]
		for sid in req.get("stat", {}).keys():
			var range_arr: Array = req["stat"][sid]
			var v: float = GameState.stats.get(sid, 0.0)
			if v < float(range_arr[0]) or v > float(range_arr[1]):
				return false
		for flag in req.get("flags", []):
			match flag:
				"has_job":
					if GameState.job_id == "": return false
				"no_job":
					if GameState.job_id != "": return false
				"in_school":
					if GameState.enrolled_in == "": return false
				_:
					if String(flag).begins_with("implant:") and not GameState.implants.has(flag.get_slice(":", 1)):
						return false
	return true


## Apply a chosen option; returns outcome summary for the result card.
func resolve_option(option: Dictionary) -> Dictionary:
	if option.is_empty():
		return {}
	GameState.apply_effects(option.get("effects", {}))
	var log := option.get("log", _fallback_log(option))
	if log != "":
		GameState.log_event(log, _last_event.get("tag", "event"))
	AudioManager.play_sfx("confirm")
	var outcome := {
		"log": log,
		"effects": option.get("effects", {}),
		"risk_roll": {},
	}
	# optional risky branch: {"chance":0.25,"fail":{"effects":{...},"log":"..."}}
	if option.has("risky"):
		var risky: Dictionary = option["risky"]
		if GameState.rng.randf() < float(risky.get("chance", 0.2)):
			GameState.apply_effects(risky.get("fail", {}).get("effects", {}))
			outcome["risk_roll"] = risky.get("fail", {})
			GameState.log_event(risky.get("fail", {}).get("log", "It went sideways."), "bad")
			AudioManager.play_sfx("error")
	SignalBus.choice_made.emit(option.get("id", ""), outcome)
	return outcome


func _fallback_log(o: Dictionary) -> String:
	return "You chose: %s" % o.get("label", "?")


static func effect_line(effects: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in effects.keys():
		var v = effects[k]
		match k:
			"credits": parts.append("₢%s" % GameState._fmt(int(v)))
			_: parts.append("%s %+d" % [k.capitalize(), int(v)])
	return " · ".join(parts)
