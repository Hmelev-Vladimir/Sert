## Global signal hub so UI screens can react to game events without hard
## dependencies on the gameplay autoloads (keeps systems decoupled & testable).
extends Node

# Life loop
signal year_advanced(age: int)
signal life_ended(cause: String, age: int)
signal stat_changed(key: String, old_value: float, new_value: float)
signal credits_changed(delta: int, total: int)

# Events / choices
signal event_emitted(event_id: String)
signal choice_made(option_id: String, outcome: Dictionary)

# Meta
signal screen_requested(screen: String, args: Dictionary)
signal toast_requested(message: String, kind: String)
