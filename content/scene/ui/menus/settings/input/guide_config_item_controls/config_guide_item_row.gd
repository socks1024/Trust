extends HBoxContainer
class_name ConfigGUIDEItemRow

@export var guide_config_item_button_scene: PackedScene

@onready var _name_label: Label = $NameLabel
@onready var _buttons_container: HBoxContainer = $ButtonsContainer


func setup_display_name(display_name: String) -> void:
	_name_label.text = display_name


func add_item_button(button: GUIDEConfigItemButton) -> void:
	_buttons_container.add_child(button)


func build_buttons(
	config_items: Array,
	remapper: GUIDERemapper,
	editable: bool,
	on_input_catched: Callable
) -> void:
	_clear_buttons()

	for grouped_item: Variant in config_items:
		var config_item: GUIDERemapper.ConfigItem = grouped_item as GUIDERemapper.ConfigItem
		if config_item == null:
			continue

		var button: GUIDEConfigItemButton = null
		if guide_config_item_button_scene != null:
			button = guide_config_item_button_scene.instantiate() as GUIDEConfigItemButton
		if button == null:
			continue

		var current_input: GUIDEInput = remapper.get_bound_input_or_null(config_item)
		button.setup(config_item, current_input)
		button.disabled = !editable
		button.input_catched.connect(on_input_catched.bind(config_item))
		add_item_button(button)


func set_buttons_editable(editable: bool) -> void:
	for child_node: Node in _buttons_container.get_children():
		var button: GUIDEConfigItemButton = child_node as GUIDEConfigItemButton
		if button != null:
			button.disabled = !editable


func _clear_buttons() -> void:
	for child: Node in _buttons_container.get_children():
		child.queue_free()
