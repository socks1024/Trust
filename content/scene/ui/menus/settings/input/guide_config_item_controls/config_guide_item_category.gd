extends VBoxContainer
class_name ConfigGUIDEItemCategory

@export var config_item_row_scene: PackedScene

@onready var _title_label: Label = $TitleLabel
@onready var _rows_container: VBoxContainer = $RowsContainer


func setup_category_title(title: String) -> void:
	_title_label.text = title


func add_item_row(row: ConfigGUIDEItemRow) -> void:
	_rows_container.add_child(row)


func build_rows(
	category_groups: Dictionary,
	name_order: Array,
	remapper: GUIDERemapper,
	editable: bool,
	on_input_catched: Callable
) -> void:
	_clear_rows()

	for display_name_variant: Variant in name_order:
		var display_name: String = display_name_variant as String
		if display_name.is_empty():
			continue

		var row: ConfigGUIDEItemRow = config_item_row_scene.instantiate() as ConfigGUIDEItemRow

		add_item_row(row)
		row.setup_display_name(display_name)

		var grouped_list: Array = category_groups.get(display_name, []) as Array
		row.build_buttons(grouped_list, remapper, editable, on_input_catched)

func set_rows_editable(editable: bool) -> void:
	for child_node: Node in _rows_container.get_children():
		var row: ConfigGUIDEItemRow = child_node as ConfigGUIDEItemRow
		if row != null:
			row.set_buttons_editable(editable)


func _clear_rows() -> void:
	for child: Node in _rows_container.get_children():
		child.queue_free()
