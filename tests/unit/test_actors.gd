extends GutTest



func test_faint():
	var actor = partial_double(BattleSystem.Actor).new();
	actor.health = 100;
	autofree(actor);
	add_child(actor);
	actor.inflict_health(-actor.health, {"ignore_endurance": true});
	assert_true(actor.shouldfaint(), "Actor should faint if they have no health");
	var result = actor.faint();
	assert_true(actor.fainted, "After calling faint(), actor should have fainted.");
	assert_false(actor.is_active(), "Actor should be inactive due to fainting");
	return actor;
	

func test_revive():
	var actor = test_faint();
	if actor is GDScriptFunctionState:
		return actor;
	
	actor.inflict_health(20, {"ignore_endurance": true});
	assert_called(actor, "_revive");
	assert_false(actor.fainted, "After an actor is revived, they should no longer be fainting");
	assert_true(actor.is_active(), "After an actor is revived, actor should be active");

class StatusCrippleTest extends BattleSystem.StatusEffect:
	func is_crippling():
		return true;
		
func test_crippple():
	# initialize actor
	var actor = partial_double(BattleSystem.Actor).new();
	actor.health = 100;
	autofree(actor);
	add_child(actor);
	
	# initialize status effect
	var cripple_status = partial_double(get_script(), "StatusCrippleTest").new();
	actor.add_child(cripple_status);
	assert_true(actor.get_status_effects().has(cripple_status));
	
	#check if active
	var active = actor.is_active();
	assert_called(cripple_status, "is_crippling");
	assert_false(active, "After an actor is crippled, they should not be active");
	

