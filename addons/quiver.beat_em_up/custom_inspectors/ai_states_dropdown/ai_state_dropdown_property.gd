extends EditorProperty

## Write your doc string for this file here

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _node: Node = null
var _ai_state_machine: QuiverAiStateMachine = null
var _options: OptionButton = null

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready() -> void:
	_node = get_edited_object()
	
	if _node is QuiverAiState or _node is QuiverStateSequence:
		_ai_state_machine = _node._state_machine as QuiverAiStateMachine
	elif _node is QuiverAiStateMachine:
		_ai_state_machine = _node as QuiverAiStateMachine
	
	_add_property_scene()
	_inititalize_property()


func _update_property() -> void:
	_inititalize_property()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _add_property_scene() -> void:
	_options = OptionButton.new()
	_options.clip_text = true
	add_child(_options, true)
	QuiverEditorHelper.connect_between(_options.item_selected, _on_options_item_selected)
	add_focusable(_options)


func _inititalize_property() -> void:
	var current_value := _node.get(get_edited_property()) as String
	var list := _get_list_of_ai_states()
	var item_id := 0
	_options.clear()
	_options.add_item("Choose State")
	for path in list:
		item_id += 1
		_options.add_item(path)
		if (path as String) == current_value:
			_options.set_item_disabled(0, true)
			_options.selected = item_id


func _get_list_of_ai_states() -> Array:
	var list := []
	
	if _ai_state_machine == null:
		list = ["Not a child of an AiStateMachine"]
	else:
		for child in _ai_state_machine.get_children():
			if child is QuiverAiState or child is QuiverStateSequence:
				list.append(_ai_state_machine.get_path_to(child))
	
	return list


func _on_options_item_selected(index: int) -> void:
	if index != 0:
		var new_value := _options.get_item_text(index)
		emit_changed(get_edited_property(), new_value)

### -----------------------------------------------------------------------------------------------
