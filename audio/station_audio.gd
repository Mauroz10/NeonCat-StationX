extends Node

var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var tracks: Dictionary = {}
var current_track := ""
var next_voice := 0
var sound_aliases := {
	"sentinel_charge": "alarm",
	"sentinel_shot": "enemy_shot",
	"sentinel_hit": "hit",
	"sentinel_phase2": "alarm",
	"sentinel_death_fault": "hurt",
	"sentinel_death_impact": "hit",
}

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -15.0
	add_child(music)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -13.0
		add_child(voice)
		effects.append(voice)
	for name in ["shot", "jump", "dash", "hit", "hurt", "pickup", "victory", "alarm", "enemy_shot"]:
		sounds[name] = load("res://assets/audio/" + name + ".wav")
	for name in ["station", "boss"]:
		var track: AudioStreamWAV = load("res://assets/audio/" + name + ".wav")
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_begin = 0
		track.loop_end = track.data.size() / 2
		tracks[name] = track

func update_music(boss_fight: bool, enabled: bool) -> void:
	if DisplayServer.get_name() == "headless": return
	music.volume_db = -15.0 if enabled else -80.0
	var target: String = "boss" if boss_fight else "station"
	if target != current_track:
		current_track = target
		music.stream = tracks[target]
		music.play()

func play_effect(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var resolved_name: String = str(sound_aliases.get(name, name))
	if not sounds.has(resolved_name): return
	var voice: AudioStreamPlayer = effects[next_voice]
	voice.stream = sounds[resolved_name]
	voice.play()
	next_voice = (next_voice + 1) % effects.size()

func set_paused(paused: bool) -> void:
	music.stream_paused = paused
	if paused:
		for voice in effects: voice.stop()

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	for voice in effects:
		voice.stop()
		voice.stream = null
	sounds.clear()
	tracks.clear()
