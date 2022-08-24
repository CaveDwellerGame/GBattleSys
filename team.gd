extends Node


func play_turn():
	var turns = [];
	for child in get_children():
		if child.has_method("play_turn"):
			var turn = child.play_turn();
			turn = yield(turn, "completed") if turn is GDScriptFunctionState else turn;
			if turn:
				turns.append(turn);
	return turns;



func has_lost():
	var lost = true;
	for child in get_children():
		if child.has_method("is_active") && child.is_active():
			return false;
	return lost;

func post_turn():
	var rets = [];
	for child in get_children():
		for status in child.get_status_effects():
			var ret = status._post_turn();
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;
			if ret:
				rets.append(ret);

		if child.has_method("_post_turn"):
			var ret = child._post_turn();
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;
			if ret:
				rets.append(ret);
	return rets;

func post_action():
	var rets = [];
	for child in get_children():
		if child.has_method("_post_action"):
			var ret = child.post_action();
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;
			if ret:
				rets.append(ret);
	return rets;

func post_battle(result):
	var rets = [];
	for child in get_children():
		if child.has_method("_post_battle"):
			var ret = child._post_battle(result);
			ret = yield(ret, "completed") if ret is GDScriptFunctionState else ret;
			if ret:
				rets.append(ret);
	return rets;
	
# Tells 
func __battle_team():
	pass
