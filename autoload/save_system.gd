extends Node

const SAVE_PATH := "user://station_g7_save.json"
const SAVE_VERSION := 3
const VALID_CHECKPOINTS := [88.0, 1250.0, 1940.0, 2420.0, 3450.0, 5100.0, 5900.0, 6550.0, 7350.0]

func save_game(data: Dictionary) -> bool:
	var payload := data.duplicate(true)
	payload["version"] = SAVE_VERSION
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("No se pudo guardar el progreso de Estación G-7")
		return false
	save_file.store_string(JSON.stringify(payload))
	save_file.close()
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {}
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if not parsed is Dictionary:
		return {}
	return _validate_and_migrate(parsed)

func erase_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _validate_and_migrate(parsed: Dictionary) -> Dictionary:
	var version := int(parsed.get("version", 0))
	if not [1, 2, 3].has(version):
		return {}
	var checkpoint_value: Variant = parsed.get("checkpoint_x", 88.0)
	if not (checkpoint_value is int or checkpoint_value is float):
		return {}
	var checkpoint_x := float(checkpoint_value)
	if not VALID_CHECKPOINTS.has(checkpoint_x):
		return {}
	var boss_defeated := parsed.get("boss_defeated", false) == true
	if version == 1 and boss_defeated and checkpoint_x == 2420.0:
		checkpoint_x = 6550.0
	var result := {
		"version": SAVE_VERSION,
		"checkpoint_x": checkpoint_x,
		"boss_defeated": boss_defeated,
		"secret_collected": parsed.get("secret_collected", false) == true,
		"route_rewards": [],
		"visited": [],
		"station_complete": parsed.get("station_complete", false) == true,
		"score": 0,
		"audio_enabled": parsed.get("audio_enabled", true) == true,
	}
	for reward in parsed.get("route_rewards", []):
		if reward in ["workshop", "reactor"] and not result["route_rewards"].has(str(reward)):
			result["route_rewards"].append(str(reward))
	for cell in parsed.get("visited", []):
		if (cell is int or cell is float) and int(cell) >= 0 and int(cell) < 9 and not result["visited"].has(int(cell)):
			result["visited"].append(int(cell))
	var saved_score: Variant = parsed.get("score", 0)
	if saved_score is int or saved_score is float:
		result["score"] = maxi(0, int(saved_score))
	return result
