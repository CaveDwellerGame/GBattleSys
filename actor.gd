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
		for status in get_status_effects(true):
			turn = status._play_turn(turn);
	return turn;

# If all actors are inactive in a team, said team loses. 
func is_active() -> bool:
	var res = true;
	for status in get_status_effects(true):
		var result = status.call("is_crippling");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		res = res && !result;
	
	if has_method("_is_active"):
		var result = call("_is_active");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
		res = res && result;
	return res; 



const maximum_status_effect = 3;
	
# Get status Effects
func get_status_effects(base_effects = false) -> Array:
	# Append Base Effects seperatly to prevent cap.
	var base_effectslist = [];
	if base_effects:
		for effect in get_children(): 
			if effect as StatusEffect && effect.is_base_effect():
				base_effectslist.append(effect);
	
	
	# Append regular effects.
	var status_effects = []
	for effect in get_children():
		if effect as StatusEffect:
			if effect.is_base_effect():
				continue;
			
			status_effects.append(effect);
			if status_effects.size() > maximum_status_effect:
				status_effects[0].queue_free();
				remove_child(status_effects[0]);
				status_effects.remove(0);
	status_effects.append_array(base_effectslist);
	for i in range(status_effects.size() - 1, -1, -1):
		if !status_effects[i].enabled:
			status_effects.remove(i);
	return status_effects;

func get_base_stats():
	return {
		"max_health": 100, # Max health of the player.
		'damage':  10, # Max damage of the player.
		'endurance': 5, # Maximum resistance to damage.
		'charisma': 0, # How well actions work.
		'strong_willed': false, # True if Boss or Player.
	}
export(Dictionary) var stats_override = {}


func get_statistic(id:String, default=null) -> float:
	var base_stats = get_base_stats();
	base_stats.merge(stats_override, true);
	
	var stat = default;
	if base_stats.has(id):
		stat = base_stats[id];
	for effect in get_status_effects(true):
		effect = effect as StatusEffect;
		effect._effect_stat(id, stat);
	return stat;



func _ready():
	if get_parent().has_method("get_actor_position") && has_method("set_position"):
		set("position:x", get_parent().get_actor_position(get_index()));
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
	for status in get_status_effects(true):
		var result = status._post_action(action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func post_turn():
	if has_method("_post_turn"):
		var result = call("_post_turn");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects(true):
		var result = status._post_turn();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
			
func pre_action(action):
	if has_method("_pre_action"):
		var result = call("_pre_action", action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects(true):
		var result = status._pre_action(action);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func pre_turn():
	if has_method("_pre_turn"):
		var result = call("_pre_turn");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	for status in get_status_effects(true):
		var result = status._pre_turn();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func post_battle(battle_result):
	for status in get_status_effects(true):
		var result = status._post_battle(battle_result);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	if has_method("_post_battle"):
		var result = call("_post_battle", battle_result);
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

func pre_battle():
	for status in get_status_effects(true):
		var result = status._pre_battle();
		if result is GDScriptFunctionState:
			result = yield(result, "completed");
	if has_method("_pre_battle"):
		var result = call("_pre_battle");
		if result is GDScriptFunctionState:
			result = yield(result, "completed");

#func pack() -> Dictionary:
#	var packed_data = {
#		"scene": filename,
#		"stats_override": stats_override,
#		"health": health
#	};
#	if has_method("_pack"):
#		var pack = call("_pack");
#		if pack is Dictionary:
#			packed_data.merge(pack, true);
#	if has_method("_pack"):
#		var pack = call("_pack");
#		if pack is Dictionary:
#			packed_data.merge(pack, true);
#
#
#	return packed_data;
#
#
#func unpack(data:Dictionary):
#	health = data.get("max_health", get_statistic("max_health"));
#	if has_method("_unpack"):
#		call("_unpack", data)
#	return packed_data;
