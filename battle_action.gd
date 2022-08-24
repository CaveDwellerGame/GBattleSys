extends Reference

var actor:Node = null;
var target = null;
func _init(_actor:Node, _target:Node = null):
	self.actor = _actor;
	self.target = _target;

func execute():
	return;
export(float) var speed = 0;
enum TargetAlignment {
	Attack = -1,
	Neutal = 0,
	Heal,
	Defend,
};

static func get_alignemnt():
	return TargetAlignment.Neutal;

enum TargetType {
	TargetNothing = 0,
	TargetActor,
	TargetTeam,
}

static func get_target_type():
	return TargetType.TargetNothing;
	
static func _is_inside_tree(node:Node):
	return node && is_instance_valid(node) && node.is_inside_tree();

func is_valid():
	var valid = _is_inside_tree(actor);
	if !valid:
		return valid;
	var target_type = get_target_type();
	if target_type != TargetType.TargetNothing:
		valid = valid && _is_inside_tree(target);
	return valid;
