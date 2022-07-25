class_name QuiverAttributes
extends Resource

## Resource to store characters or other objects attributes.
##
## The purpose of this is to separate Data from Animations/Behavior/Feedback as much as possible.
## When two characters are fighting we want the Character Scenes worry about the "how" while
## the data resources will take of the "what", and will be able to guide the scenes. 
## [br][br]
## It is also easier to pass resources around than nodes, or node references. So for example,
## with resources a HitBox that is nested deeply on character skin to follow it's animation can
## collide with a deeply nested HurtBox of another charater and they can just trade attribute
## resources to resolve the damage, and the resource will notify the appropriate node.
## [br][br]
## It is a more modular way of architecturing the game, where you can use the best of nodes
## and node hierarchies without worrying about complex structures making your life harder as
## the most important logic can happen between simple resources.

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal health_changed
signal health_depleted
signal hurt_requested(knockback: QuiverKnockback)
signal knockout_requested(knockback: QuiverKnockback)
signal grab_requested(grabbed_character: QuiverAttributes)
signal grabbed

#--- enums ----------------------------------------------------------------------------------------

enum WeightClass { LIGHT, MEDIUM, HEAVY }

#--- constants ------------------------------------------------------------------------------------

# move this to the function that will calculate jump force when you refactor
const WEIGHT_MULTIPLIER = {
	WeightClass.LIGHT: 1.0,
	WeightClass.MEDIUM: 2.0,
	WeightClass.HEAVY: 4.0,
}

const KNOCKBACK_BY_STRENGTH = {
	QuiverCyclicHelper.KnockbackStrength.NONE: 0,
	QuiverCyclicHelper.KnockbackStrength.WEAK: 60, # Doesn't launch the target, but builds up
	QuiverCyclicHelper.KnockbackStrength.MEDIUM: 600, # Should launch target
	QuiverCyclicHelper.KnockbackStrength.STRONG: 1200,
	QuiverCyclicHelper.KnockbackStrength.MASSIVE: 2400,
}

#--- public variables - order: export > normal var > onready --------------------------------------

@export var display_name := ""

## Max health for the character, when their life bar is full.
@export_range(0, 1, 1, "or_greater") var health_max := 100

## Max movement speed for the character.
@export_range(0, 1000, 1, "or_greater") var speed_max := 600

## Character's jump force. The heavier the character more jump force they'll need to reach the
## same jump height as a lighter character.
@export_range(0, 0, 1, "or_lesser") var jump_force := -1200

## If you need to make the hit lanes broader or narrower for a specifi character you can use
## this property. Positive values will add to the default hit lane size defined in the Project
## Setting, while negative values will subtract from it. 
## [br][br]
## Note that the hit lane size is how many pixels the character should still be able to receive
## a hit from, so a value of 60 for example, means that they will be hurt by any attacks 
## from another character whose base is between 60 pixels above or 60 pixels below 
## this character's y position.
@export var hit_lane_offset := 0

## Character's weight. Influences jump and things like if the character can be thrown or not.[br]
## Heavier character will only be able to be thrown by stronger characters.
@export var weight: WeightClass = WeightClass.MEDIUM

## This can be toggled on or off in animations to create invincibility frames.
@export var is_invulnerable := false:
	set(value):
		var has_changed = value != is_invulnerable
		is_invulnerable = value
		if has_changed and is_invulnerable:
			knockback_amount = 0

## This can be toggled on or off in animations to create animations that can't be interrupted
## but still should allow damage to be received.
@export var has_superarmor := false:
	set(value):
		var has_changed = value != has_superarmor
		has_superarmor = value
		if has_changed and has_superarmor:
			knockback_amount = 0

@export var can_be_grabbed := true

## Character's current health. What the health bar will be showing.
var health_current := health_max:
	set(value):
		var has_changed = value != health_current
		health_current = clamp(value, 0, health_max)
		if has_changed:
			if health_current > 0:
				health_changed.emit()
			else:
				health_depleted.emit()

var is_alive: bool:
	get:
		return get_health_as_percentage() > 0

## Amount of knockback character has received, will be used to calculate bounce the next time
## it hits a wall or the ground.
var knockback_amount := 0:
	set(value):
		knockback_amount = max(0, value)

## This character's current y value that represents their current ground level.
var ground_level := 0.0

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _init() -> void:
	Events.characters_reseted.connect(reset)

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func add_knockback(strength: QuiverCyclicHelper.KnockbackStrength) -> void:
	knockback_amount += KNOCKBACK_BY_STRENGTH[strength]


func should_knockout() -> bool:
	var has_enough_knockback: bool = \
			knockback_amount >= KNOCKBACK_BY_STRENGTH[QuiverCyclicHelper.KnockbackStrength.MEDIUM]
	return not is_alive or (not has_superarmor and has_enough_knockback)


## Returns the character's current health as percentage.
func get_health_as_percentage() -> float:
	var value := health_current / float(health_max)
	return value


func get_hit_lane_limits() -> HitLaneLimits:
	var limits = HitLaneLimits.new(hit_lane_offset, ground_level)
	return limits


func reset() -> void:
	health_current = health_max
	is_invulnerable = false
	has_superarmor = false
	can_be_grabbed = true

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------

class HitLaneLimits:
	extends RefCounted
	
	var lane_size: int = ProjectSettings.get_setting(QuiverCyclicHelper.SETTINGS_DEFAULT_HIT_LANE_SIZE)
	
	var upper_limit := 0
	var lower_limit := 0
	
	func _init(p_increment, p_ground_level):
		upper_limit = p_ground_level - lane_size - p_increment
		lower_limit = p_ground_level + lane_size + p_increment
	
	
	func is_value_inside_lane(y_position: float) -> bool:
		var value := y_position >= upper_limit and y_position <= lower_limit
		return value
