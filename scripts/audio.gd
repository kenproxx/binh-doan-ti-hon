extends Node
## Original synthesized WAV assets; no third-party recording or network access.
var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var cursor: int = 0
var sounds: Dictionary = {}
func _ready() -> void:
 for i in range(6):
  var player: AudioStreamPlayer=AudioStreamPlayer.new()
  player.volume_db=-14
  add_child(player)
  players.append(player)
 music_player=AudioStreamPlayer.new()
 music_player.volume_db=-24
 add_child(music_player)
 for key in ["ui","deploy","attack","hit","skill","victory","defeat"]:
  sounds[key]=load("res://assets/audio/"+key+".wav")
 menu_music()
 apply_settings()
func cue(name: String) -> void:
 var p: Node=get_node_or_null("/root/Profile")
 if p and not p.data.get("settings",{}).get("sfx",true): return
 if not sounds.has(name): name="ui"
 players[cursor].stream=sounds.get(name)
 players[cursor].play()
 cursor=(cursor+1)%players.size()
 if name in ["hit","skill"] and p and p.data.settings.get("vibration",true) and OS.has_feature("android"):
  Input.vibrate_handheld(25 if name=="hit" else 60)
func apply_settings() -> void:
 var p: Node=get_node_or_null("/root/Profile")
 var settings: Dictionary=p.data.get("settings",{}) if p else {}
 music_player.stream_paused=not settings.get("music",true)
 Engine.max_fps=30 if settings.get("quality","high")=="low" else 60
func menu_music() -> void:
 _music("menu")
func battle_music() -> void:
 _music("battle")
func _music(name: String) -> void:
 var stream: AudioStreamWAV=load("res://assets/audio/"+name+".wav")
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_begin=0
 stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
 if music_player.stream!=stream:
  music_player.stream=stream
  music_player.play()
 apply_settings()
func _exit_tree() -> void:
 if music_player:
  music_player.stop()
  music_player.stream=null
 for player in players:
  player.stop()
  player.stream=null
 sounds.clear()
