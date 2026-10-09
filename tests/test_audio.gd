extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var audio=root.get_node("Audio")
 var p=root.get_node("Profile")
 var original: Dictionary=p.data.settings.duplicate(true)
 audio.menu_music()
 if audio.music_player.stream.loop_mode!=AudioStreamWAV.LOOP_FORWARD:
  printerr("FAIL music must loop across whole menu session")
  audio.music_player.stop()
  audio.music_player.stream=null
  await create_timer(.1).timeout
  quit(1)
  return
 audio.battle_music()
 assert(audio.music_player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
 p.data.settings.music=false
 audio.apply_settings()
 assert(audio.music_player.stream_paused)
 p.data.settings.quality="low"
 audio.apply_settings()
 assert(Engine.max_fps==30)
 p.data.settings=original
 audio.apply_settings()
 audio.music_player.stop()
 audio.music_player.stream=null
 for player in audio.players:
  player.stop()
  player.stream=null
 await create_timer(.1).timeout
 print("AUDIO TESTS PASS")
 quit(0)
