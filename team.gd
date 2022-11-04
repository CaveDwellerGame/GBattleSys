extends Node



func _ready():
	add_to_group("GBattleTeam");


# repeat the turn of the last actor if one turn does not return a result.
export(bool) var continous = false;


func play_turn():
	var turns = [];
	var i = 0;
	while i < get_child_count():
		var child = get_child(i);
		if !child.is_active():
			i += 1;
			continue;
			
		var turn = child.play_turn();
		if turn is GDScriptFunctionState:
			turn = yield(turn, "completed");
		if turn is preload("battle_action.gd"):
			turns.append(turn);
		elif continous:
			if (i > 0):
				turns.remove(i -1);
				i -= 1;
			continue;
		i += 1;
	return turns;
	
func is_active():
	for child in get_children():
		if child.is_active():
			return true;
	return false;


func pre_turn():
	for child in get_children():
		if child.has_method("pre_turn"):
			var ret = child.pre_turn();
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;

func pre_action(action):
	for child in get_children():
		if child.has_method("pre_action"):
			var ret = child.pre_action(action);
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;

func post_turn():
	for child in get_children():
		if child.has_method("post_turn"):
			var ret = child.post_turn();
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;

func post_action(action):
	for child in get_children():
		if child.has_method("post_action"):
			var ret = child.post_action(action);
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;

func post_battle(result):
	var rets = [];
	for child in get_children():
		if child.has_method("post_battle"):
			var ret = child.post_battle(result);
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;
			if ret:
				rets.append(ret);
	return rets;

# Who is this teams Enemy?
export(NodePath) var enemy = NodePath();

# The Teams score
export(int) var score = 0 setget _set_score;
signal score_changed(last_score);
func _set_score(_score):
	if score != _score:
		var lastscore = score;
		score = _score;
		if score > 9999999999999:
			score = 9999999999999;
		elif score < 0:
			score = 0;
		emit_signal("score_changed", lastscore);
