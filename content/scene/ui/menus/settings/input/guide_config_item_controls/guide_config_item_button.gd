extends GUIDEInputButton
class_name GUIDEConfigItemButton

var _config_item: GUIDERemapper.ConfigItem

## 注入配置项和当前输入绑定
func setup(config_item: GUIDERemapper.ConfigItem, current_input: GUIDEInput) -> void:
	_config_item = config_item
	initial_text = _formatter.input_as_text(current_input)
	detect_value_type = _config_item.value_type
	_config_item.changed.connect(_set_text_by_input)
	_set_text_by_input(current_input)

func _set_text_by_input(input: GUIDEInput) -> void:
	if input == null:
		text = initial_text
		return
	text = _formatter.input_as_text(input)
