extends "res://external/GBattleSys/status/status_effect.gd"

signal revived()
signal fainted(metadata);
signal inflict_health(infliction, metadata);

var fainted = false;
var last_infliction_data = {};

export(bool) var reset_on_ready = true;
var health = 0;

func should_faint():
	return health <= 0 && !fainted;

func should_revive():
	return health > 0 && fainted;


func _ready():
	if reset_on_ready:
		fainted = false;
		health = get_parent().get_statistic("max_health", 1);
		last_infliction_data = {};

func is_crippling():
	return fainted;

func _faint():
	health = 0.0;
	fainted = true;
	yield(get_tree(), "idle_frame");
	for status in get_parent().get_status_effects():
		if status.has_method("_faint"):
			var result = status.call("_faint");
			if result is GDScriptFunctionState:
				result = yield(result, "completed");
			if !result:
				return;
	
	var should_delete = true;
	if get_parent().has_method("_faint"):
		should_delete = get_parent().call("_faint");
		if should_delete is GDScriptFunctionState:
			should_delete = yield(should_delete, "completed");
	
	emit_signal("fainted");
	yield(get_tree(), "idle_frame");
	if should_delete:
		get_parent().queue_free();
	
func _pre_action(_action):
	yield(faint_check(), "completed");
func _post_action(_action):
	yield(faint_check(), "completed");
		
		
func faint_check():
	yield(get_tree(), "idle_frame");
	if should_faint():
		yield(_faint(), "completed");
		

func inflict_health(infliction:float, metadata:Dictionary = {}):
	if !metadata.get("ignore_endurance", false) && infliction < 0:
		var endurance = get_parent().get_statistic('endurance', 0);
		infliction += round(clamp(rand_range(endurance - 5, endurance), 0, INF));
		infliction = clamp(infliction, -INF, 0);
	
	health += infliction;
	health = clamp(health, 0, get_parent().get_statistic("max_health", 1));
	last_infliction_data = metadata;
	
	if should_revive():
		yield(_revive(), "completed");
	
	if metadata.has("actor") && infliction < 0:
		metadata["actor"].get_parent().score += abs(infliction);
		
	emit_signal("inflict_health", infliction, metadata);
	yield(get_tree().create_timer(0.7), "timeout");
	return infliction;

func _revive():
	if !fainted:
		return;
	fainted = false;
	if get_parent().has_method("_revive"):
		var result = get_parent().call("_revive");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		if !result:
			return;
	emit_signal("revived");
	return 0;

func is_base_effect():
	return true;
