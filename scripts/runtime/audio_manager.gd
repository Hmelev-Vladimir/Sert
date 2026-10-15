## NEONLINE — Autoload: AudioManager.
## Three buses (Music / SFX / UI) with persisted volumes and a built-in synth,
## so the template makes sound even before real audio assets are imported.
extends Node

const BUSES := ["Master", "Music", "SFX", "UI"]

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var _prefs := ConfigFile.new()
var _tween_music: Tween


func _ready() -> void:
	for i in range(1, BUSES.size()):
		if AudioServer.get_bus_index(BUSES[i]) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, BUSES[i])
	# route Music/SFX/UI to Master explicitly
	for name in ["Music", "SFX", "UI"]:
		var bi := AudioServer.get_bus_index(name)
		if bi != -1:
			AudioServer.set_bus_send(bi, "Master")
	var err := _prefs.load("user://audio.cfg")
	if err == OK:
		music_volume = _prefs.get_value("volumes", "music", 0.8)
		sfx_volume = _prefs.get_value("volumes", "sfx", 0.9)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_ensure_synth()


func _set_bus(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i != -1:
		AudioServer.set_bus_volume_db(i, linear_to_db(clampf(v, 0.0001, 1.0)))


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0, 1)
	_set_bus("Music", music_volume)
	_persist()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0, 1)
	_set_bus("SFX", sfx_volume)
	_persist()


func _persist() -> void:
	_prefs.set_value("volumes", "music", music_volume)
	_prefs.set_value("volumes", "sfx", sfx_volume)
	_prefs.save("user://audio.cfg")


## Play an imported sample if present; otherwise fall back to the synth.
func play_sfx(id: String) -> void:
	match id:
		"tap": _beep(660.0, 0.05, 0.25)
		"confirm": _chord([523.25, 659.25, 784.0], 0.18, 0.2)
		"error": _beep(140.0, 0.22, 0.3)
		"levelup": _chord([440.0, 554.37, 659.25, 880.0], 0.3, 0.22)
		"cash": _beep(1200.0, 0.08, 0.2)
		_: _beep(440.0, 0.06, 0.2)
	# Hook for real assets:
	# var p: AudioStreamPlayer = pool.pop_available()
	# p.stream = load("res://assets/audio/sfx/%s.ogg" % id); p.play()


func play_music(track: String = "menu") -> void:
	# Replace with streamed music files when available:
	# $MusicPlayer.stream = load("res://assets/audio/music/%s.ogg" % track)
	_beep(220.0, 0.4, 0.05)


func stop_music(_fade: float = 1.0) -> void:
	pass


func duck_music(amount_db: float = 8.0, duration: float = 1.2) -> void:
	var i := AudioServer.get_bus_index("Music")
	if i == -1:
		return
	if _tween_music != null and _tween_music.is_valid():
		_tween_music.kill()
	var base := linear_to_db(maxf(music_volume, 0.0001))
	_tween_music = create_tween()
	_tween_music.tween_method(func(v): AudioServer.set_bus_volume_db(i, v), base, base - amount_db, 0.15)
	_tween_music.tween_interval(duration)
	_tween_music.tween_method(func(v): AudioServer.set_bus_volume_db(i, v), base - amount_db, base, 0.4)


# --- Minimal synth fallback (no assets required) ---
var _synth_player: AudioStreamPlayer


func _ensure_synth() -> void:
	_synth_player = AudioStreamPlayer.new()
	_synth_player.bus = "SFX"
	add_child(_synth_player)


func _beep(freq: float, dur: float, gain: float) -> void:
	if _synth_player == null:
		return
	var rate := AudioServer.get_mix_rate()
	var n := int(rate * dur)
	var frames := PackedFloat32Array()
	frames.resize(n)
	for i in range(n):
		var t := float(i) / float(rate)
		var env := 1.0 - float(i) / float(n)
		frames[i] = sin(TAU * freq * t) * env * gain
	_synth_player.stream = _make_wav(rate, frames)
	_synth_player.play()


func _chord(freqs: Array, dur: float, gain: float) -> void:
	var rate := AudioServer.get_mix_rate()
	var n := int(rate * dur)
	var frames := PackedFloat32Array()
	frames.resize(n)
	for i in range(n):
		var t := float(i) / float(rate)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * f * t)
		frames[i] = s / freqs.size() * (1.0 - float(i) / float(n)) * gain
	_synth_player.stream = _make_wav(rate, frames)
	_synth_player.play()


func _make_wav(rate: int, samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := clampf(samples[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	wav.data = data
	return wav
