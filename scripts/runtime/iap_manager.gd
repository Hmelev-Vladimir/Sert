## NEONLINE — Autoload: IAPManager.
## Store-purchase stub: "remove_ads", "chrome_pack", "credit_packs".
## Replace `purchase` internals with Godot's Android/iOS in-app billing plugin.
extends Node

signal purchase_succeeded(sku: String)
signal purchase_failed(sku: String, reason: String)

const SKUS := {
	"remove_ads": {"price": "$3.99", "kind": "one_time"},
	"starter_chrome": {"price": "$1.99", "kind": "consumable", "implants": ["optics_mk1"]},
	"credit_5k": {"price": "$0.99", "kind": "consumable", "credits": 5000},
	"credit_20k": {"price": "$3.99", "kind": "consumable", "credits": 20000},
}

var ad_free := false


func owns(sku: String) -> bool:
	if SKUS.get(sku, {}).get("kind", "") == "one_time":
		return sku == "remove_ads" and ad_free
	return false


func purchase(sku: String) -> void:
	if not SKUS.has(sku):
		purchase_failed.emit(sku, "unknown_sku")
		return
	await get_tree().create_timer(0.5).timeout  # simulated checkout
	# TODO: real billing bridge here.
	var def: Dictionary = SKUS[sku]
	match sku:
		"remove_ads":
			ad_free = true
		_:
			if def.has("credits"):
				GameState.add_credits(int(def["credits"]))
			for iid in def.get("implants", []):
				GameState.buy_implant(iid)
	purchase_succeeded.emit(sku)


func refund_hook(_sku: String) -> void:
	pass
