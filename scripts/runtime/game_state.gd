## NEONLINE — Autoload: GameState.
## The living simulation: one character aging year by year in the Sprawl.
## Owns stats, credits, occupation, implants, relationships and the RNG seed.
## UI never mutates fields directly — it calls intent methods (age_year, do_activity…).
extends Node

const P := preload("res://scripts/runtime/palette.gd")

# --- Identity ---
var character_name: String = ""
var district: String = ""
var sex: String = "F"           # F | M | X
var age: int = 0
var alive: bool = true
var cause_of_death: String = ""

# --- Core stats (0..100) ---
var stats: Dictionary = {}      # id -> float
# --- Resources ---
var credits: int = 0
var karma: int = 0              # -100..100 street reputation
var happiness: float = 50.0

# --- Progression ---
var education_level: int = 0    # 0 none … 4 docent
var enrolled_in: String = ""
var job_id: String = ""         # "" = unemployed
var job_title: String = "Unemployed"
var job_level: int = 1
var job_performance: float = 50.0
var retired: bool = false
var traits: Array = []          # ids
var implants: Array = []        # ids
var cooldowns: Dictionary = {}  # activity_id -> years remaining
var history: Array = []         # [{age, text, kind}]
var people: Array = []          # [{id,name,type,affinity}]

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = hash(Time.get_datetime_string_from_system() + str(OS.get_unique_id()))


# ---------- Lifecycle ----------

func start_new_life(seed_value: int = 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	alive = true
	cause_of_death = ""
	age = 0
	history.clear()
	cooldowns.clear()
	traits.clear()
	implants.clear()
	credits = 0
	karma = 0
	job_id = ""
	job_title = "Unemployed"
	job_level = 1
	education_level = 0
	enrolled_in = ""
	retired = false
	stats.clear()
	for s in DataService.stats:
		stats[s["id"]] = clampf(float(s.get("default", 50)) + rng.randf_range(-18, 18), 5, 95)
	character_name = DataService.random_name(rng)
	var dlist: Array = DataService.world.get("districts", [])
	if dlist.is_empty() or typeof(dlist[0]) != TYPE_DICTIONARY:
		district = String(_pick(["Neon Row"]))
	else:
		district = String((dlist[rng.randi_range(0, dlist.size() - 1)] as Dictionary).get("name", "Neon Row"))
	sex = ["F", "M"][rng.randi_range(0, 1)]
	_spawn_family()
	log_event("Born in %s." % district, "life")
	SignalBus.year_advanced.emit(age)


func _spawn_family() -> void:
	people.clear()
	for p in DataService.relationships:
		if p.get("family", false):
			people.append({
				"id": p["id"],
				"name": "%s %s" % [p.get("name", "Parent"), character_name.get_slice(" ", -1)],
				"type": p.get("type", "family"),
				"affinity": clampi(int(p.get("affinity", 60)) + rng.randi_range(-20, 20), 0, 100),
			})


# ---------- Main loop ----------

## Advance exactly one year. Returns a summary dict for the UI feed.
func age_year() -> Dictionary:
	if not alive:
		return {}
	_age_stats_drift()
	_paycheck()
	_tick_cooldowns()
	_progress_education()
	_social_drift()
	age += 1
	roll_health_chance()
	SignalBus.year_advanced.emit(age)
	SaveSystem.save_game()
	return {"age": age, "alive": alive}


func _age_stats_drift() -> void:
	# Aging curve: peak in the 20s, decline after 35.
	var decay := 0.0
	if age > 35:
		decay = clampf((age - 35) * 0.35, 0.0, 6.0)
	for key in stats.keys():
		if key in ["happiness", "karma"]:
			continue
		var v: float = stats[key]
		v -= decay * rng.randf_range(0.4, 1.2)
		# implants offset physical decay
		if has_implant_slot("body"):
			v += 0.6
		stats[key] = clampf(v, 0, 100)
		SignalBus.stat_changed.emit(key, v, stats[key])
	happiness = clampf(happiness + rng.randf_range(-3, 3) - (decay * 0.3), 0, 100)


func _paycheck() -> void:
	if job_id == "" or retired:
		return
	var job := DataService.job_by_id(job_id)
	var salary := int(job.get("salary", 0)) * job_level
	var bonus := int(salary * 0.25 * (job_performance / 100.0))
	var total := salary + bonus
	add_credits(total)
	log_event("Earned ₢%s as %s." % [_fmt(total), job_title], "money")
	if job_level < int(job.get("max_level", 5)) and job_performance > 75.0 and rng.chances(1, 4):
		job_level += 1
		job_performance = 50.0
		log_event("Promoted to level %d at %s!" % [job_level, job_title], "career")
		AudioManager.play_sfx("levelup")
	job_performance = clampf(job_performance + rng.randf_range(-8, 10), 0, 100)


func _tick_cooldowns() -> void:
	for k in cooldowns.keys():
		cooldowns[k] = int(cooldowns[k]) - 1
		if cooldowns[k] <= 0:
			cooldowns.erase(k)


func _social_drift() -> void:
	for p in people:
		p["affinity"] = clampi(int(p["affinity"]) + rng.randi_range(-4, 3), 0, 100)


func _progress_education() -> void:
	if enrolled_in == "":
		return
	var school := _school_by_id(enrolled_in)
	if school.is_empty():
		return
	school["years_left"] = int(school.get("years_left", school.get("years", 2))) - 1
	if int(school["years_left"]) <= 0:
		enrolled_in = ""
		education_level = maxi(education_level, int(school.get("grad_level", 1)))
		log_event("Graduated from %s." % school.get("name", "Academy"), "education")
		AudioManager.play_sfx("levelup")


func roll_health_chance() -> void:
	if age < 12:
		return
	# Death check scaled by health & age. Simple, tunable curve.
	var health: float = stats.get("health", 50.0)
	var risk := clampf((age - 60) * 0.012 + (100.0 - health) * 0.0016, 0.0, 0.55)
	if rng.randf() < risk:
		die("Natural causes / organ failure")


# ---------- Intents (called by UI) ----------

func apply_activity(id: String) -> Dictionary:
	if cooldowns.has(id):
		return {"ok": false, "reason": "cooldown"}
	var act := DataService.activity_by_id(id)
	if act.is_empty():
		return {"ok": false, "reason": "unknown"}
	var cost := int(act.get("cost", 0))
	if credits < cost:
		return {"ok": false, "reason": "credits"}
	add_credits(-cost)
	apply_effects(act.get("effects", {}))
	if int(act.get("cooldown", 0)) > 0:
		cooldowns[id] = int(act["cooldown"])
	log_event(act.get("log", "Did %s." % act.get("name", id)), act.get("tag", "self"))
	AudioManager.play_sfx("confirm")
	return {"ok": true, "effects": act.get("effects", {})}


func buy_implant(id: String) -> Dictionary:
	var item := DataService.implant_by_id(id)
	if item.is_empty():
		return {"ok": false, "reason": "unknown"}
	if implants.has(id):
		return {"ok": false, "reason": "owned"}
	var cost := int(item.get("cost", 0))
	if credits < cost:
		return {"ok": false, "reason": "credits"}
	add_credits(-cost)
	implants.append(id)
	apply_effects(item.get("effects", {}))
	if rng.randf() < float(item.get("risk", 0.0)):
		adjust("health", -12)
		log_event("The %s rejected at first. Surgery scar aches." % item.get("name", id), "medical")
	else:
		log_event("Installed %s at a back-alley clinic." % item.get("name", id), "medical")
	AudioManager.play_sfx("cash")
	return {"ok": true}


func try_job(id: String) -> Dictionary:
	var job := DataService.job_by_id(id)
	if job.is_empty():
		return {"ok": false, "reason": "unknown"}
	if age < int(job.get("min_age", 16)):
		return {"ok": false, "reason": "too_young"}
	for req in job.get("req_stats", []):
		if float(stats.get(req["id"], 0)) < float(req["min"]):
			return {"ok": false, "reason": "stats", "need": req}
	if int(job.get("min_edu", 0)) > education_level:
		return {"ok": false, "reason": "education"}
	if rng.randf() < float(job.get("hire_chance", 0.85)):
		job_id = id
		job_title = job.get("name", id)
		job_level = 1
		job_performance = 50.0
		log_event("Hired as %s in the %s sector." % [job_title, job.get("sector", "general")], "career")
		AudioManager.play_sfx("confirm")
		return {"ok": true}
	log_event("Rejected for the %s posting." % job_title, "career")
	AudioManager.play_sfx("error")
	return {"ok": false, "reason": "rejected"}


func quit_job() -> void:
	if job_id == "":
		return
	log_event("Walked out of %s." % job_title, "career")
	job_id = ""
	job_title = "Unemployed"
	job_level = 1


func enroll_school(id: String) -> Dictionary:
	var school := _school_by_id(id)
	if school.is_empty():
		return {"ok": false, "reason": "unknown"}
	var tuition := int(school.get("tuition", 0))
	if credits < tuition:
		return {"ok": false, "reason": "credits"}
	if age < int(school.get("min_age", 18)):
		return {"ok": false, "reason": "too_young"}
	add_credits(-tuition)
	enrolled_in = id
	school["years_left"] = int(school.get("years", 2))
	log_event("Enrolled at %s." % school.get("name", id), "education")
	return {"ok": true}


func retire() -> void:
	retired = true
	job_id = ""
	job_title = "Retired"
	log_event("Cashed out and retired to a quiet arcology.", "career")


func add_credits(delta: int) -> void:
	credits = maxi(0, credits + delta)
	SignalBus.credits_changed.emit(delta, credits)


func adjust(key: String, delta: float) -> void:
	var old: float = stats.get(key, 50.0)
	var nv: float = clampf(old + delta, 0, 100)
	stats[key] = nv
	SignalBus.stat_changed.emit(key, old, nv)


func apply_effects(effects: Dictionary) -> void:
	for k in effects.keys():
		match k:
			"credits": add_credits(int(effects[k]))
			"happiness": happiness = clampf(happiness + float(effects[k]), 0, 100)
			"karma": karma = clampi(karma + int(effects[k]), -100, 100)
			_: adjust(k, float(effects[k]))


func die(cause: String) -> void:
	if not alive:
		return
	alive = false
	cause_of_death = cause
	log_event("Died at %d. Cause: %s." % [age, cause], "death")
	SignalBus.life_ended.emit(cause, age)


func has_implant_slot(slot: String) -> bool:
	for iid in implants:
		if DataService.implant_by_id(iid).get("slot", "") == slot:
			return true
	return false


func log_event(text: String, kind: String = "info") -> void:
	history.append({"age": age, "text": text, "kind": kind})
	if history.size() > 400:
		history.pop_front()


func can_do(id: String) -> bool:
	if cooldowns.has(id):
		return false
	var act := DataService.activity_by_id(id)
	return credits >= int(act.get("cost", 0))


func _school_by_id(id: String) -> Dictionary:
	for s in DataService.schools:
		if s.get("id", "") == id:
			return s
	return {}


func _pick(arr: Array):
	if arr.is_empty():
		return "Neon Row"
	return arr[rng.randi_range(0, arr.size() - 1)]


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
