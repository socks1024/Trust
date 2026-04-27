extends Node

@export_file("*.tscn") var game_world_path: String
@export_file("*.tscn") var loading_scene_path: String
## 全局背景音乐事件
@export var bgm_event: AudioEvent = null

@onready var world: Node = $World
@onready var ui: CanvasLayer = $UI

@onready var start_menu: Control = $UI/StartMenu
@onready var settings_menu: Control = $UI/SettingsMenu
@onready var credit_menu: Control = $UI/CreditMenu
@onready var pause_menu: Control = $UI/PauseMenu

var _game_root: Node


func _ready() -> void:
	# 播放全局背景音乐
	if bgm_event != null:
		AudioManager.play_music(bgm_event, &"bgm")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _game_root != null:
			if get_tree().paused:
				_resume_game()
			else:
				_pause_game()

func _show_only_menu(menu:Control) -> void:
	ui.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_menu.hide()
	settings_menu.hide()
	credit_menu.hide()
	menu.show()


func _on_goto_settings() -> void:
	_show_only_menu(settings_menu)


func _on_goto_credits() -> void:
	_show_only_menu(credit_menu)


func _on_back_to_start() -> void:
	_show_only_menu(start_menu)


func _on_new_game() -> void:
	if game_world_path == null or game_world_path == "":
		CLog.e("Game World Path not assigned!")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.hide()
	_game_root = await SceneUtils.instantiate_scene_by_load_control(world,game_world_path,loading_scene_path)
	# 连接游戏场景的重新开始和返回主菜单信号
	if _game_root.has_signal("restart_requested"):
		_game_root.restart_requested.connect(_on_game_restart)
	if _game_root.has_signal("back_to_menu_requested"):
		_game_root.back_to_menu_requested.connect(_on_game_back_to_start)


## 暂停游戏并显示暂停菜单
func _pause_game() -> void:
	get_tree().paused = true
	ui.show()
	pause_menu.show()
	pause_menu._show_main_panel()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## 恢复游戏并隐藏暂停菜单
func _resume_game() -> void:
	get_tree().paused = false
	pause_menu.hide()
	ui.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## 暂停菜单 - 返回主菜单
func _on_pause_back_to_start() -> void:
	get_tree().paused = false
	_game_root.queue_free()
	_game_root = null
	pause_menu.hide()
	_on_back_to_start()


func _on_exit_clicked() -> void:
	get_tree().quit()


## 游戏中重新开始
func _on_game_restart() -> void:
	if _game_root:
		_game_root.queue_free()
		_game_root = null
	_on_new_game()


## 游戏中返回主菜单
func _on_game_back_to_start() -> void:
	if _game_root:
		_game_root.queue_free()
		_game_root = null
	_on_back_to_start()
