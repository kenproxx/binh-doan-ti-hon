extends SceneTree
var main
func _initialize() -> void:
 call_deferred("run")
func snap(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 image.save_png("res://build/screens/"+name+".png")
 print("SCREEN ",name)
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://build/screens")
 var p=root.get_node("Profile")
 p.storage_root="user://visual_tests/"
 DirAccess.make_dir_recursive_absolute(p.storage_root)
 p.reset_profile()
 main=load("res://main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.3).timeout
 await snap("01-main")
 main.show_campaign()
 await snap("02-campaign")
 main.show_detail(1)
 await snap("03-detail")
 main.show_prepare(1)
 await snap("04-prepare")
 main.start_battle()
 await create_timer(0.5).timeout
 main.paused=true
 await snap("05-tutorial")
 main.paused=false
 p.data.unlocked=["blade","guard","archer","bomber","medic","siege"]
 main.selected=["blade","guard","archer","bomber"]
 main.show_prepare(24)
 p.data.stars={}
 for i in range(1,24): p.data.stars[str(i)]=3
 main.start_battle()
 main.paused=true
 await process_frame
 await process_frame
 for i in range(650):
  for id in main.sim.loadout:
   main.sim.deploy(0,id,main.sim.map.base_positions[0]+Vector2(0,-100))
  main.sim.step(0.1)
 main.field.center_on(Vector2(384,620))
 main._update_hud()
 await snap("06-island-battle")
 main.paused=false
 main._pause()
 await snap("07-pause")
 main.sim.finished=true
 main.sim.won=true
 main.sim.stars=3
 main.show_result()
 await snap("08-result")
 main.show_army()
 await snap("09-army")
 main.show_settings()
 await snap("10-settings")
 main.free()
 var a=root.get_node("Audio")
 a.music_player.stop()
 a.music_player.stream=null
 for player in a.players:
  player.stop()
  player.stream=null
 await create_timer(0.1).timeout
 quit(0)
