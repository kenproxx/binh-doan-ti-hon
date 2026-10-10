extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var p=root.get_node("Profile")
 p.storage_root="user://pointer_tests/"
 DirAccess.make_dir_recursive_absolute(p.storage_root)
 p.reset_profile()
 var main=load("res://main.tscn").instantiate()
 root.add_child(main)
 await create_timer(.4).timeout
 var flag=FileAccess.open("res://build/pointer-ready-final",FileAccess.WRITE)
 flag.store_string("ready")
 flag.close()
 await create_timer(7).timeout
 var ok: bool=main.screen=="battle" and main.sim.statistics.deployed==1 and main.sim.skill_cooldown>0 and main.paused
 print("POINTER SMOKE ","PASS" if ok else "FAIL", " screen=",main.screen," paused=",main.paused)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/screens/11-pointer-pause.png")
 main.free()
 var audio=root.get_node("Audio")
 audio.music_player.stop()
 audio.music_player.stream=null
 for player in audio.players:
  player.stop()
  player.stream=null
 await create_timer(.1).timeout
 quit(0 if ok else 1)

