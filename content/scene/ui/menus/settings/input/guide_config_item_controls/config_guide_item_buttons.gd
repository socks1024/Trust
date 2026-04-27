extends ConfigControl
class_name ConfigGUIDEItemButtons

@export var config_item_category_scene: PackedScene
@export var remappable_contexts: Array[GUIDEMappingContext] = []

@onready var _content: VBoxContainer = $Content

var _remapper: GUIDERemapper = GUIDERemapper.new()
var _editable: bool = true


func get_default_value() -> Variant:
	return GUIDERemappingConfig.new()


func set_control_editable(editable: bool) -> void:
	_editable = editable
	for category_node: Node in _content.get_children():
		var category_controller: ConfigGUIDEItemCategory = category_node as ConfigGUIDEItemCategory
		if category_controller != null:
			category_controller.set_rows_editable(editable)


func set_control_value(value: Variant) -> void:
	var remapping_config: GUIDERemappingConfig = value as GUIDERemappingConfig
	if remapping_config == null:
		remapping_config = GUIDERemappingConfig.new()

	_remapper.initialize(remappable_contexts, remapping_config)
	_rebuild_item_buttons()


func connect_control_input() -> void:
	pass


func _rebuild_item_buttons() -> void:
	_clear_content()

	var items: Array[GUIDERemapper.ConfigItem] = _remapper.get_remappable_items()
	if items.is_empty():
		return

	var grouped_items: Dictionary = {}
	var category_order: Array[String] = [] # Order of categories
	var name_order_by_category: Dictionary = {} # Order of names within each category

	# Group items by category and display name
	for item: GUIDERemapper.ConfigItem in items:
		var category: String = item.display_category
		var display_name: String = item.display_name

		if not grouped_items.has(category):
			grouped_items[category] = {}
			category_order.append(category)
			name_order_by_category[category] = []

		var category_groups: Dictionary = grouped_items[category]
		var name_order: Array = name_order_by_category[category]

		if not category_groups.has(display_name):
			category_groups[display_name] = []
			name_order.append(display_name)

		var grouped_list: Array = category_groups[display_name]
		grouped_list.append(item)
		category_groups[display_name] = grouped_list
		grouped_items[category] = category_groups
		name_order_by_category[category] = name_order

	# Build rows for each category
	for category_name: String in category_order:
		var category: ConfigGUIDEItemCategory = config_item_category_scene.instantiate() as ConfigGUIDEItemCategory

		_content.add_child(category)
		category.setup_category_title(category_name)

		category.build_rows(
			grouped_items[category_name],
			name_order_by_category[category_name],
			_remapper,
			_editable,
			_on_config_item_button_input_catched
		)
		
		category.set_rows_editable(_editable)


func _clear_content() -> void:
	for child: Node in _content.get_children():
		child.queue_free()


func _on_config_item_button_input_catched(input: GUIDEInput, config_item: GUIDERemapper.ConfigItem) -> void:
	_remapper.set_bound_input(config_item, input)
	var remapping_config: GUIDERemappingConfig = _remapper.get_mapping_config()
	_set_config_value(remapping_config)
