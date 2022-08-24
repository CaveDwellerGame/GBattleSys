extends Node

func is_curse():
	return false;


func _play_turn(turn):
	return turn;
	
func _post_turn():
	pass;
	
func _effect_stat(stat:String, current:float) -> float:
	return current;

func _effect_inflic(inflcition:float, metadata:Dictionary) -> float:
	return inflcition;

func _faint() -> bool:
	return true;

func get_icon() -> Texture:
	return preload("res://game/treasure/placeholder_treasure.png");
	
