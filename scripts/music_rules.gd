class_name MusicRules
extends RefCounted

const TRACK_IDS:=["hangar_signal","title_vector","steel_vector","salt_wake","furnace_alarm","machine_pressure","dead_factory","ghost_signal","black_sky","thin_blue","ark_descent","after_action"]
const SECTOR_TRACKS := [
	["steel_vector", "salt_wake", "furnace_alarm"],
	["machine_pressure", "dead_factory", "ghost_signal"],
	["black_sky", "thin_blue", "ark_descent"]
]
static func sanitize_tracks(raw:Variant)->Array:
	var tracks:Array=[]
	if typeof(raw)!=TYPE_ARRAY:return tracks
	for item in raw:
		if typeof(item)!=TYPE_DICTIONARY:continue
		var id:=str(item.get("id",""))
		if not id in TRACK_IDS:continue
		var track:Dictionary=item.duplicate(true);track["bpm"]=clampi(int(track.get("bpm",120)),72,168);track["root"]=clampi(int(track.get("root",40)),24,60)
		var valid:=true
		for key in ["lead","bass","kick","snare"]:valid=valid and typeof(track.get(key))==TYPE_ARRAY and track.get(key).size()==16
		if typeof(track.get("chords"))!=TYPE_ARRAY or track.get("chords").size()!=4:valid=false
		if valid:tracks.append(track)
	tracks.sort_custom(func(a:Dictionary,b:Dictionary):return TRACK_IDS.find(str(a.get("id")))<TRACK_IDS.find(str(b.get("id"))))
	return tracks
static func valid_tracker_voice(value:Variant)->bool:
	if typeof(value)!=TYPE_DICTIONARY:return false
	for key in ["lead","bass","kick","snare"]:
		if typeof(value.get(key))!=TYPE_ARRAY or value.get(key).size()!=16:return false
	return typeof(value.get("chords"))==TYPE_ARRAY and value.get("chords").size()==4
static func track_id_for(phase:int,mission_index:int)->String:
	if phase==2:return "after_action"
	if phase!=1:return "hangar_signal"
	var safe_index := maxi(0, mission_index)
	var sector := clampi(int(safe_index / 10), 0, SECTOR_TRACKS.size() - 1)
	return str(SECTOR_TRACKS[sector][safe_index % SECTOR_TRACKS[sector].size()])
static func midi_frequency(note:int)->float:return 440.0*pow(2.0,(float(note)-69.0)/12.0) if note>=0 else 0.0
