extends Reference

var actor:Node = null;
var target = null;
func _init(_actor:Node, _target:Node = null):
	self.actor = _actor;
	self.target = _target;

func execute():
	return;
	
export(int) var priority = 0;
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

enum TargetMode {
	Alive, 
	Active,
	Fainted,
	All,
}

static func get_target_type():
	return TargetType.TargetNothing;

static func get_target_mode():
	return TargetMode.Alive;

static func mode_applies_to_target(target:Node, mode):
	match mode:
		TargetMode.Alive:
			if "fainted" in target:
				return !target.fainted;
			else:
				return false;
		TargetMode.Active:
			if target.has_method("is_active"):
				return target.is_active();
			else:
				return false;
		TargetMode.Fainted:
			if "fainted" in target:
				return target.fainted;
			else:
				return false;
		TargetMode.All:
			return true;
	return false;
	
static func _is_inside_tree(node:Node):
	return node && is_instance_valid(node) && node.is_inside_tree() && !node.is_queued_for_deletion();

func is_valid():
	if !_is_inside_tree(actor):
		return false;
	
	if !actor.is_active():
		return false;
	
	var target_type = get_target_type();
	if target_type != TargetType.TargetNothing:
		if !_is_inside_tree(target):
			return false;
		if !mode_applies_to_target(target, get_target_mode()):
			return false;
	
	return true;
