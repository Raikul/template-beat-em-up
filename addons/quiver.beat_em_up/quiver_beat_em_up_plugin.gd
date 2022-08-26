@tool
extends EditorPlugin
## Write your doc string for this file here

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

const PATH_CUSTOM_INSPECTORS = "res://addons/quiver.beat_em_up/custom_inspectors/"

var SETTINGS = {
	QuiverCyclicHelper.SETTINGS_DEFAULT_HIT_LANE_SIZE:{
			value = 60,
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0,1,1,or_greater"
	},
	QuiverCyclicHelper.SETTINGS_LOGGING: {
			value = true,
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			hint_string = "",
	},
	QuiverCyclicHelper.SETTINGS_FALL_GRAVITY_MODIFIER: {
			value = 1.0,
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0,2.0,0.01,or_greater"
	},
}

#--- private variables - order: export > normal var > onready -------------------------------------

var _loaded_inspectors := {}

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _enter_tree() -> void:
	_add_custom_inspectors()


func _exit_tree() -> void:
	_remove_custom_inspectors()


func _enable_plugin() -> void:
	_add_plugin_settings()


func _disable_plugin() -> void:
	_remove_plugin_settings()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _add_custom_inspectors() -> void:
	var dir := Directory.new()
	var error := dir.open(PATH_CUSTOM_INSPECTORS)
	
	if error == OK:
		dir.list_dir_begin()
		var folder_name := dir.get_next()
		while not folder_name.is_empty():
			if dir.current_is_dir(): 
				_load_custom_inspector_from(folder_name)
			folder_name = dir.get_next()
	else:
		var error_msg = "Error code: %s | Something went wrong trying to open %s"%[
			error, PATH_CUSTOM_INSPECTORS
		]
		push_error(error_msg)


func _load_custom_inspector_from(folder: String) -> void:
	const PATH_SCRIPT = "inspector_plugin.gd"
	var full_path := PATH_CUSTOM_INSPECTORS.plus_file(folder).plus_file(PATH_SCRIPT)
	if ResourceLoader.exists(full_path):
		var custom_inspector := load(full_path).new() as EditorInspectorPlugin
		add_inspector_plugin(custom_inspector)
		if "undo_redo" in custom_inspector:
			custom_inspector.undo_redo = get_undo_redo()
		_loaded_inspectors[folder] = custom_inspector


func _remove_custom_inspectors() -> void:
	for inspector in _loaded_inspectors.values():
		remove_inspector_plugin(inspector)


func _add_plugin_settings() -> void:
	for setting in SETTINGS:
		if not ProjectSettings.has_setting(setting):
			var dict: Dictionary = SETTINGS[setting]
			ProjectSettings.set_setting(setting, dict.value)
			ProjectSettings.add_property_info({
				"name": setting,
				"type": dict.type,
				"hint": dict.hint,
				"hint_string": dict.hint_string,
			})
	
	if Engine.is_editor_hint():
		ProjectSettings.save()


func _remove_plugin_settings() -> void:
	for setting in SETTINGS:
		if ProjectSettings.has_setting(setting):
			ProjectSettings.set_setting(setting, null)
	
	if Engine.is_editor_hint():
		ProjectSettings.save()

### -----------------------------------------------------------------------------------------------
