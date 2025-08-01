extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sound_player: AudioStreamPlayer = $SoundPlayer

var current_music: AudioStream
var music_fade_duration: float = 1.0

var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8

func _ready():
	music_player.bus = "Music"
	sound_player.bus = "SFX"
	
	create_sfx_pool()

func create_sfx_pool():
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

# === MUSIC FUNCTIONS ===
func play_music(music_stream: AudioStream, fade_in: bool = false):
	if not music_stream:
		return
	
	if fade_in and music_player.playing:
		fade_to_music(music_stream)
	else:
		music_player.stream = music_stream
		music_player.play()
		current_music = music_stream

func fade_to_music(new_music: AudioStream):
	if not new_music:
		return
	
	var tween = create_tween()
	var original_volume = music_player.volume_db
	
	tween.tween_property(music_player, "volume_db", -80.0, music_fade_duration * 0.5)
	tween.tween_callback(func():
		music_player.stream = new_music
		music_player.play()
		current_music = new_music
	)
	tween.tween_property(music_player, "volume_db", original_volume, music_fade_duration * 0.5)

func stop_music(fade_out: bool = false):
	if fade_out and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, music_fade_duration * 0.5)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()
	current_music = null

func pause_music():
	music_player.stream_paused = !music_player.stream_paused

func is_music_playing() -> bool:
	return music_player.playing and not music_player.stream_paused

# === SFX FUNCTIONS ===
func play_sfx(sound_stream: AudioStream, volume_db: float = 0.0):
	if not sound_stream:
		return
	
	var available_player = get_available_sfx_player()
	if available_player:
		available_player.stream = sound_stream
		available_player.volume_db = volume_db
		available_player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	return sfx_players[0]

func stop_all_sfx():
	for player in sfx_players:
		if player.playing:
			player.stop()

# === CONVENIENCE FUNCTIONS ===
func play_button_sound():
	sound_player.play()

func play_music_sound():
	music_player.play()

# === GAME-SPECIFIC AUDIO FUNCTIONS ===

#will add more 
func play_menu_music():
	pass

func play_game_music():
	pass

func play_pickup_sound():
	pass

func play_door_sound():
	pass

func play_footstep_sound():
	pass

func play_ui_select_sound():
	pass

func play_ui_back_sound():
	pass
