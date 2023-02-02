extends "battle_action.gd"

var msg:String = "";
var max_damage:float = 0;
var inpresicion:float = 5;
var type:String = "regular_blunt";

const default_attack_message = "{actor} attacked {target}"

func _init(actor, target, damage = null, 
	dmg_type:String = "regular_blunt", 
	message:String = default_attack_message).(actor, target):
		if damage == null:
			max_damage = actor.get_statistic("damage", 0);
		else:
			max_damage = float(damage);
		self.type = dmg_type;
		msg = message.format({
			"actor": actor.name,
			"target": target.name,
		});

const BattleAction = preload("battle_action.gd");

func execute():
	actor.get_tree().current_scene.write_text(msg);
	yield(target.get_node("Life").inflict_health(
		-max_damage,
		{
			"actor": actor,
			"type": type
		}
	), "completed");


static func get_alignment():
	return BattleAction.TargetAlignment.Attack;
	
static func get_target_type():
	return BattleAction.TargetType.TargetActor;
