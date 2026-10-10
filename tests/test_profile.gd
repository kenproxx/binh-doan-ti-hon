extends SceneTree
var failures: int = 0
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  printerr("FAIL: ",message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var p = root.get_node_or_null("Profile")
 check(p != null,"profile system exists")
 if p == null:
  quit(1)
  return
 p.storage_root = "user://automated_tests/"
 DirAccess.make_dir_recursive_absolute(p.storage_root)
 check(p.reset_profile(),"reset persisted")
 check(p.stage_unlocked(1) and not p.stage_unlocked(2),"initial campaign lock")
 var initial: int = p.data.coins
 var reward: int = p.settle(1,true,3,"unique-test-result")
 check(reward>0 and p.data.coins==initial+reward,"first reward")
 check(p.settle(1,true,3,"unique-test-result")==0,"duplicate result no reward")
 check(p.stage_unlocked(2),"win opens next stage")
 check(p.data.unlocked.has("archer"),"first win unlocks archer")
 var replay: int = p.settle(1,true,3,"replay-test1")
 check(replay==15,"replay reward separate")
 p.settle(1,true,3,"replay-test2")
 p.settle(1,true,3,"replay-test3")
 check(p.settle(1,true,3,"replay-test4")==0,"replay capped")
 var cost: int = p.upgrade_cost("blade")
 var before: int = p.data.coins
 var hp_before: float = root.get_node("GameDB").unit("blade",0).hp
 check(p.upgrade("blade"),"upgrade accepted")
 check(p.data.coins==before-cost,"upgrade cost deducted")
 check(root.get_node("GameDB").unit("blade",1).hp>hp_before,"upgrade affects battle stat")
 var expected: int = p.data.coins
 check(p.load_profile() and p.data.coins==expected,"progress survives reload")
 check(p.settle(30,true,3,"locked-exploit")==0,"locked stage reward rejected")
 check(not p.upgrade("siege"),"locked unit cannot upgrade")
 p.save_profile()
 var f=FileAccess.open(p.storage_root+"profile.json",FileAccess.WRITE)
 f.store_string("corrupt")
 f.close()
 check(p.load_profile(),"backup recovered")
 check(p.data.coins==expected,"recovered coins")
 check(p.notice!="","recovery explained")
 var good_root: String=p.storage_root
 p.storage_root="user://absent_notice_folder/absent/"
 check(not p.upgrade("blade"),"failed upgrade exposes failure")
 check(p.notice!="","failed save notice")
 p.storage_root=good_root
 check(p.upgrade("blade"),"successful upgrade after storage repair")
 check(p.notice=="","successful transaction clears old failure notice")
 print("PROFILE TESTS: ","PASS" if failures==0 else "FAIL", " failures=",failures)
 var a=root.get_node("Audio")
 a.music_player.stop()
 a.music_player.stream=null
 for player in a.players:
  player.stop()
  player.stream=null
 await create_timer(0.1).timeout
 quit(1 if failures else 0)

