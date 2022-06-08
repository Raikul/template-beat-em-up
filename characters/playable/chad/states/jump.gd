extends "res://characters/playable/chad/states/chad_state.gd"

## Write your doc string for this file here

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

@export var JUMP_FORCE := -1200

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func enter(msg: = {}) -> void:
	super(msg)
	get_parent().enter(msg)
	_skin.transition_to(_skin.SkinStates.JUMP)
	if msg.has("velocity"):
		_character.velocity = msg.velocity
	
	_state_machine.set_physics_process(false)
	await get_tree().process_frame
	_character.velocity.y = JUMP_FORCE
	await get_tree().process_frame
	_state_machine.set_physics_process(true)


func unhandled_input(_event: InputEvent) -> void:
	return


func physics_process(delta: float) -> void:
	get_parent().physics_process(delta)


func exit() -> void:
	get_parent().exit()
	super()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------

