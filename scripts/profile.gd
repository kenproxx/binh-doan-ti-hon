extends Node
## Durable atomic profile with validated backup and idempotent result transactions.
signal changed
const VERSION: int = 1
var storage_root: String = "user://"
var data: Dictionary = {}
var notice: String = ""
func _ready() -> void:
 load_profile()
func fresh() -> Dictionary:
 return {"version":VERSION,"coins":200,"unlocked":["blade"],"upgrades":{},"stars":{},"first_rewards":[],"replays":{},"transactions":[],"settings":{"music":true,"sfx":true,"vibration":true,"quality":"high"},"last_stage":1,"tutorial":[]}
func _valid(d: Variant) -> bool:
 if not d is Dictionary: return false
 var expected: Dictionary=fresh()
 for key in expected:
  if not d.has(key) or typeof(d[key])!=typeof(expected[key]):
   # JSON represents every number as float.
   if not (expected[key] is int and d.get(key) is float): return false
 if int(d.version)!=VERSION or float(d.coins)<0 or float(d.coins)>1000000 or floorf(float(d.coins))!=float(d.coins): return false
 if int(d.last_stage)<1 or int(d.last_stage)>30: return false
 var db: Node=get_node_or_null("/root/GameDB")
 for id in d.unlocked:
  if not id is String or db==null or not db.units.has(id): return false
 if not d.unlocked.has("blade"): return false
 for id in d.upgrades:
  if not id is String or not db.units.has(id) or not _integer_range(d.upgrades[id],0,5): return false
 for id in d.stars:
  if not id is String or not id.is_valid_int() or int(id)<1 or int(id)>30 or not _integer_range(d.stars[id],0,3): return false
 for id in d.first_rewards:
  if not _integer_range(id,1,30): return false
 for id in d.replays:
  if not id is String or not id.is_valid_int() or int(id)<1 or int(id)>30 or not _integer_range(d.replays[id],0,3): return false
 for token in d.transactions:
  if not token is String or token.is_empty(): return false
 for key in ["music","sfx","vibration"]:
  if not d.settings.get(key) is bool: return false
 if not d.settings.get("quality") in ["high","low"]: return false
 for key in d.tutorial:
  if not key is String: return false
 return true
func _integer_range(value: Variant, minimum: int, maximum: int) -> bool:
 return (value is int or value is float) and float(value)>=minimum and float(value)<=maximum and floorf(float(value))==float(value)
func _read(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var parser: JSON=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
 var wrapper: Variant=parser.data
 if not wrapper is Dictionary or not wrapper.get("payload") is String or not wrapper.get("checksum") is String: return {}
 if wrapper.payload.sha256_text()!=wrapper.checksum: return {}
 if parser.parse(wrapper.payload)!=OK: return {}
 var decoded: Variant=parser.data
 if not _valid(decoded): return {}
 return decoded
func load_profile() -> bool:
 notice=""
 var primary: Dictionary=_read(storage_root+"profile.json")
 if not primary.is_empty():
  data=primary
  changed.emit()
  return true
 var backup: Dictionary=_read(storage_root+"profile.backup.json")
 if not backup.is_empty():
  data=backup
  notice="Hồ sơ chính bị lỗi. Đã khôi phục bản dự phòng."
  var success: bool=save_profile()
  changed.emit()
  return success
 data=fresh()
 if FileAccess.file_exists(storage_root+"profile.json"):
  notice="Không thể đọc hồ sơ; đã tạo hồ sơ mới. Bản lỗi được giữ để kiểm tra."
  DirAccess.rename_absolute(storage_root+"profile.json",storage_root+"profile.corrupt.json")
 var success: bool=save_profile()
 changed.emit()
 return success
func save_profile() -> bool:
 if not _valid(data):
  notice="Hồ sơ không hợp lệ, không ghi dữ liệu."
  return false
 var path: String=storage_root+"profile.json"
 var temp: String=storage_root+"profile.tmp.json"
 var payload: String=JSON.stringify(data)
 var f: FileAccess=FileAccess.open(temp,FileAccess.WRITE)
 if f==null:
  notice="Không thể lưu tiến độ. Kiểm tra dung lượng và quyền lưu."
  return false
 f.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
 f.flush()
 var write_error: Error=f.get_error()
 f.close()
 if write_error!=OK:
  notice="Ghi hồ sơ thất bại. Chưa áp dụng giao dịch."
  return false
 if not _read(path).is_empty():
  if DirAccess.copy_absolute(path,storage_root+"profile.backup.json")!=OK:
   notice="Không thể tạo bản dự phòng. Chưa áp dụng giao dịch."
   return false
 if DirAccess.rename_absolute(temp,path)!=OK:
  notice="Không thể hoàn tất lưu hồ sơ. Chưa áp dụng giao dịch."
  return false
 return true
func _commit(previous: Dictionary) -> bool:
 if not save_profile():
  data=previous
  changed.emit()
  return false
 notice=""
 changed.emit()
 return true
func reset_profile() -> bool:
 var previous: Dictionary=data.duplicate(true)
 data=fresh()
 if not _commit(previous): return false
 # Replace backup too so intentional reset cannot resurrect old progress.
 DirAccess.copy_absolute(storage_root+"profile.json",storage_root+"profile.backup.json")
 notice=""
 return true
func stage_unlocked(id: int) -> bool:
 return id>=1 and id<=30 and (id==1 or int(data.get("stars",{}).get(str(id-1),0))>0)
func upgrade_cost(id: String) -> int:
 var db: Node=get_node("/root/GameDB")
 if not db.upgrades.has(id): return -1
 var level: int=int(data.get("upgrades",{}).get(id,0))
 if level>=5: return -1
 return int(db.upgrades[id][level])
func upgrade(id: String) -> bool:
 var cost: int=upgrade_cost(id)
 if cost<0 or not data.unlocked.has(id) or int(data.coins)<cost: return false
 var previous: Dictionary=data.duplicate(true)
 data.coins=int(data.coins)-cost
 data.upgrades[id]=int(data.upgrades.get(id,0))+1
 return _commit(previous)
func settle(stage_id: int, won: bool, earned_stars: int, token: String) -> int:
 if token.is_empty() or data.transactions.has(token) or not stage_unlocked(stage_id): return 0
 var previous: Dictionary=data.duplicate(true)
 data.transactions.append(token)
 data.last_stage=stage_id
 var reward: int=0
 if won:
  var stage_data: Dictionary=get_node("/root/GameDB").stage(stage_id)
  var old_stars: int=int(data.stars.get(str(stage_id),0))
  var new_stars: int=clampi(earned_stars,1,3)
  reward=maxi(0,new_stars-old_stars)*20
  data.stars[str(stage_id)]=maxi(old_stars,new_stars)
  if not data.first_rewards.has(stage_id):
   reward+=int(stage_data.reward_first)
   data.first_rewards.append(stage_id)
  elif int(data.replays.get(str(stage_id),0))<3:
   reward+=int(stage_data.reward_replay)
   data.replays[str(stage_id)]=int(data.replays.get(str(stage_id),0))+1
  var unlock: String=str(stage_data.get("unlock_unit",""))
  if not unlock.is_empty() and not data.unlocked.has(unlock): data.unlocked.append(unlock)
  data.coins=int(data.coins)+reward
  data.last_stage=mini(stage_id+1,30)
 if not _commit(previous): return 0
 return reward
func mark_tutorial(key: String) -> void:
 if data.tutorial.has(key): return
 var previous: Dictionary=data.duplicate(true)
 data.tutorial.append(key)
 _commit(previous)

