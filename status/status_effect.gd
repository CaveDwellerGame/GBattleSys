extends Node

func is_curse():
	return false;

func is_crippling():
	return false;

func _play_turn(turn):
	return turn;
	
func _pre_turn():
	pass;
	
func _post_turn():
	pass;
	
func _pre_action(_action):
	pass;
	
func _post_action(_action):
	pass;

func _post_battle(battle_result):
	pass;
	
func _effect_stat(_stat:String, _current):
	return _current;

func _faint() -> bool:
	return true;

func get_icon() -> Texture:
	return preload("placeholder_status.png");
	
# Does not show in Viewer, is not effected by status effect limit.
func is_base_effect():
	return false;
