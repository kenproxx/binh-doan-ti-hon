extends Node
## Data-only catalogue. Unit snapshots prevent upgrades mutating a live battle.
var units: Dictionary = {}
var stages: Array = []
var upgrades: Dictionary = {}
var strings: Dictionary = {}
var error: String = ""
func _ready() -> void:
 TranslationServer.set_locale("vi")
 units = _read("units",{})
 stages = _read("stages",[])
 upgrades = _read("upgrades",{})
 strings = _read("strings",{})
 if units.size()!=6 or stages.size()!=30:
  error="Dữ liệu chiến dịch thiếu hoặc hỏng. Hãy cài lại game; hồ sơ được giữ nguyên."
func _read(name: String, fallback: Variant) -> Variant:
 var path: String="res://data/"+name+".json"
 if not FileAccess.file_exists(path):
  error="Thiếu dữ liệu: "+name
  return fallback
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
 if typeof(parsed)!=typeof(fallback):
  error="Dữ liệu không hợp lệ: "+name
  return fallback
 return parsed
func unit(id: String, level: int=0) -> Dictionary:
 if not units.has(id): return {}
 var result: Dictionary=units[id].duplicate(true)
 var factor: float=1.0+0.12*clampi(level,0,5)
 for key in ["hp","damage","heal"]:
  result[key]=roundf(float(result.get(key,0))*factor)
 result["level"]=clampi(level,0,5)
 return result
func stage(id: int) -> Dictionary:
 if id<1 or id>stages.size(): return {}
 return stages[id-1].duplicate(true)
func text(key: String) -> String:
 var language: String=TranslationServer.get_locale().substr(0,2)
 var table: Dictionary=strings.get(language,strings.get("vi",{}))
 return str(table.get(key,strings.get("en",{}).get(key,key)))
