## NEONLINE — Autoload: AdManager.
## Stub monetization layer (rewarded / interstitial / banner) with a clean API so a
## real SDK (AdMob / Unity Ads / AppLovin) can be dropped in behind one switch.
## In the editor it always grants rewards so designers can test flows.
extends Node

signal ad_rewarded(reward_id: String, amount: int)
signal ad_failed(reason: String)

var enabled_in_debug := true
var _last_shown_unix := -999999.0
const INTERSTITIAL_COOLDOWN_S := 180.0


func is_ready(_kind: String = "rewarded") -> bool:
	return true  # stub


func show_rewarded(reward_id: String = "boost", amount: int = 1) -> void:
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		pass  # mobile web has no ads; skip silently
	# TODO: replace with SDK call, e.g.:
	# MobileAds.load_rewarded("ca-app-pub-xxx"); on user earn -> emit signal
	await get_tree().create_timer(0.4).timeout  # simulate latency
	if _simulate_fail():
		ad_failed.emit("no_fill")
		return
	ad_rewarded.emit(reward_id, amount)


func maybe_show_interstitial() -> void:
	var now := Time.get_unix_time_from_system()
	if now - _last_shown_unix < INTERSTITIAL_COOLDOWN_S:
		return
	_last_shown_unix = now
	# TODO: SDK interstitial here.
	print("[AD] interstitial would show (stub)")


func _simulate_fail() -> bool:
	if OS.has_feature("editor"):
		return false
	return randf() < 0.05
