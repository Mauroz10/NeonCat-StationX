extends RefCounted
class_name SentinelPhase

func windup_duration() -> float:
	return 1.2

func exposed_duration() -> float:
	return 2.2

func fan_offsets() -> Array:
	return [-0.3, 0.0, 0.3]

func fan_speed() -> float:
	return 255.0

func wave_speed() -> float:
	return 340.0

func rain_offsets() -> Array:
	return [-85.0, 0.0, 85.0]
