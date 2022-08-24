extends Node

const StatusEffect = preload("status_effect.gd");
const BattleAction = preload("battle_action.gd")

func play_turn() -> BattleAction:
	var turn = null;
	if has_method("_play_turn"):
		turn = self.call("_play_turn");
		if turn is GDScriptFunctionState:
			turn = yield(turn, "completed");
		else:
			yield(get_tree(), "idle_frame");
	for status in get_status_effects():
		turn = status._play_turn(turn);
	return turn if (turn as BattleAction) else BattleAction.new(self);

# If all actors are inactive in a team, said team loses. 
func is_active() -> bool:
	# I'll allow this to edited by status effects later
	return true; 


func faint():
	yield(get_tree(), "idle_frame");
	get_tree().current_scene.write_text(name + " fainted");
	for status in get_status_effects():
		if status.has_method("_faint"):
			var result = status.call("_faint");
			if result is GDScriptFunctionState:
				result = yield(result, "completed");
			if !result:
				return;
	
	if has_method("_faint"):
		var result = call("_faint");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		if !result:
			return;
		
	yield(get_tree(), "idle_frame");
	get_parent().remove_child(self);
	queue_free();
	
export(float) var health;

signal inflcit_health(infliction, metadata);
func inflict_health(infliction:float, metadata:Dictionary = {}):
	for effect in get_status_effects():
		effect = effect as StatusEffect;
		var ret = effect._effect_inflic(
			infliction, metadata);
		if ret is GDScriptFunctionState:
			infliction = yield(ret, "completed");
		else:
			infliction = ret;
		
	health += infliction;
	emit_signal("inflcit_health", infliction, metadata);
	yield(get_tree().create_timer(0.7), "timeout");
	
func shouldfaint():
	return self.health < 0; 
	
const maximum_status_effect = 3;
	
# Get status Effects
func get_status_effects() -> Array:
	var status_effects = []
	for child in get_children():
		if child as StatusEffect:
			status_effects.append(child);
			if status_effects.size() > 3:
				status_effects[0].queue_free();
				remove_child(status_effects[0]);
				status_effects.remove(0);
	return status_effects;
	
export(Dictionary) var base_stats := {
	"max_health": 100
};

func get_statistic(id:String) -> float:
	var stat = base_stats.get(id, 0);
	for effect in get_status_effects():
		effect = effect as StatusEffect;
		effect._effect_stat(id, stat);
	return stat;


func _actor_ready():
	pass


func _ready():
	_actor_ready();
	health = get_statistic("max_health");
	if get_parent().has_method("get_actor_position") && has_method("set_position"):
		call("set_position", get_parent().get_actor_position(get_index()));
		call("set_scale", Vector2.ZERO);
		var tween = create_tween();
		tween.tween_interval(0.2);
		tween.tween_property(self, "scale", Vector2.ONE, 1);
		
func __battle__actor():
	pass
