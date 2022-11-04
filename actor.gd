extends Node

const StatusEffect = preload("status/status_effect.gd");
const BattleAction = preload("battle_action.gd");

func play_turn() -> BattleAction:
	var turn = null;
	if has_method("_play_turn"):
		turn = self.call("_play_turn");
		if turn is GDScriptFunctionState:
			turn = yield(turn, "completed");
		else:
			yield(get_tree(), "idle_frame");
	if turn:
		for status in get_status_effects():
			turn = status._play_turn(turn);
	return turn;

# If all actors are inactive in a team, said team loses. 
func is_active() -> bool:
	var res = true;
	for status in get_status_effects():
		var result = status.call("is_crippling");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		res = res && !result;
	
	if has_method("_is_active"):
		var result = call("_is_active");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		res = res && result;
	if res:
		return !fainted;
	return res; 

var fainted = false;
func faint():
	if !shouldfaint():
		return;
		
	fainted = true;
	yield(get_tree(), "idle_frame");
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
	
var health = 0;

signal inflcit_health(infliction, metadata);
func inflict_health(infliction:float, metadata:Dictionary = {}):
	if !metadata.get("ignore_endurance", false):
		var endurance = get_statistic('endurance', 0);
		if infliction < 0:
			infliction += round(clamp(rand_range(endurance - 5, endurance), 0, INF));
			infliction = clamp(infliction, -INF, 0);
	
	for effect in get_status_effects():
		effect = effect as StatusEffect;
		var ret = effect._effect_inflic(
			infliction, metadata);
		if ret is GDScriptFunctionState:
			infliction = yield(ret, "completed");
		else:
			infliction = ret;
		
	health += infliction;
	if health > 0 && fainted:
		revive();
	
	if metadata.has("actor") && infliction < 0:
		metadata["actor"].get_parent().score += abs(infliction);
	
	
	emit_signal("inflcit_health", infliction, metadata);
	yield(get_tree().create_timer(0.7), "timeout");
	return infliction;
	
func shouldfaint():
	return self.health <= 0 && !fainted; 


signal revived()
func revive():
	if !fainted:
		return;
	fainted = false;
	if has_method("_revive"):
		var result = call("_revive");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		if !result:
			return;
	emit_signal("revived");
	return 0;

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

func get_base_stats():
	return {
		"max_health": 100, # Max health of the player.
		'damage':  10, # Max damage of the player.
		'endurance': 5, # Maximum resistance to damage.
		'charisma': 0, # How well actions work.
		'strong_willed': false, # True if Boss or Player.
	}

func get_statistic(id:String, default=null) -> float:
	var base_stats = get_base_stats();
	var stat = default;
	if base_stats.has(id):
		stat = base_stats[id];
	for effect in get_status_effects():
		effect = effect as StatusEffect;
		effect._effect_stat(id, stat);
	return stat;



func _ready():
	health = get_statistic("max_health", 1);
	if get_parent().has_method("get_actor_position") && has_method("set_position"):
		call("set_position", get_parent().get_actor_position(get_index()));
		call("set_scale", Vector2.ZERO);
		var tween = create_tween();
		tween.tween_interval(0.2);
		tween.tween_property(self, "scale", Vector2.ONE, 1);
		
func __battle__actor():
	pass


func post_action(action):
	if has_method("_post_action"):
		var result = call("_post_action", action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects():
		var result = status._post_action(action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func post_turn():
	if has_method("_post_turn"):
		var result = call("_post_turn");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects():
		var result = status._post_turn();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
			
func pre_action(action):
	if has_method("_pre_action"):
		var result = call("_pre_action", action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects():
		var result = status._pre_action(action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func pre_turn():
	if has_method("_pre_turn"):
		var result = call("_pre_turn");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects():
		var result = status._pre_turn();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func post_battle(battle_result):
	for status in get_status_effects():
		var result = status._post_battle(battle_result);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	if has_method("_post_battle"):
		var result = call("_post_battle", battle_result);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
