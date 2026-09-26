extends SentinelPhase
class_name SentinelPhaseTwo

func windup_duration() -> float:
	return 0.95

func exposed_duration() -> float:
	return 1.7

func fan_offsets() -> Array:
	return [-0.48, -0.24, 0.0, 0.24, 0.48]

func fan_speed() -> float:
	return 295.0

func wave_speed() -> float:
	return 390.0

func rain_offsets() -> Array:
	return [-150.0, -75.0, 0.0, 75.0, 150.0]
