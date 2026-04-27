class_name GUIDEInputButton extends CommonButton

@export var initial_text: String
@export var waiting_text: String
@export var detect_value_type: GUIDEAction.GUIDEActionValueType = GUIDEAction.GUIDEActionValueType.BOOL

signal input_catched(input: GUIDEInput)

@onready var _input_detector: GUIDEInputDetector = $InputDetector

var _formatter: GUIDEInputFormatter = GUIDEInputFormatter.new()

func _ready() -> void:
	super._ready()
	button_anim_finish.connect(_start_catch_input)
	_input_detector.input_detected.connect(_on_input_detected)
	text = initial_text

func _start_catch_input() -> void:
	text = waiting_text
	_input_detector.detect(detect_value_type)

func _on_input_detected(input: GUIDEInput) -> void:
	if input == null:
		text = initial_text
		return
	text = _formatter.input_as_text(input)
	input_catched.emit(input)
