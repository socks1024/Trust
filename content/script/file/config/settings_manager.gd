# Generated Class Name SettingsManager
extends Node

func _ready() -> void:
	_load_audio_config()
	_load_input_config()
	_load_video_config()
	_load_game_config()

func reset_all_settings() -> void:
	ConfigUtils.erase_config()
	_reset_audio_config()
	_reset_input_config()
	_reset_video_config()
	_reset_game_config()

#region Audio

func _load_audio_config() -> void:
	for bus_index in AudioServer.get_bus_count():
		var bus_name = AudioServer.get_bus_name(bus_index)
		if ConfigUtils.has_section_key("Audio", bus_name + "Volume"):
			var volume_db = ConfigUtils.load_setting("Audio", bus_name + "Volume", 0.0)
			set_bus_volume_db(bus_name, volume_db)

func _reset_audio_config() -> void:
	for bus_index in AudioServer.get_bus_count():
		var bus_name = AudioServer.get_bus_name(bus_index)
		set_bus_volume_db(bus_name, 0.0)

## 获取总线音量
func get_bus_volume_db(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(bus_index)

## 设定总线音量
func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, volume_db)

## 设定总线静音
func mute_bus(bus_name: String, mute: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus_index, mute)

#endregion

#region Input

const INPUT_REMAPPING_CONFIG_KEY: String = "GuideRemappingConfig"

func _load_input_config() -> void:
	var remapping_config: GUIDERemappingConfig = get_guide_remapping_config()
	set_guide_remapping_config(remapping_config)

func _reset_input_config() -> void:
	ConfigUtils.erase_section_key("Input", INPUT_REMAPPING_CONFIG_KEY)
	set_guide_remapping_config(GUIDERemappingConfig.new())

## 应用 GUIDE 输入重映射配置
func set_guide_remapping_config(remapping_config: GUIDERemappingConfig) -> void:
	if remapping_config == null:
		CLog.e("Invalid remapping config! Cannot apply null config.")
		return
	GUIDE.set_remapping_config(remapping_config)

## 从 ConfigFile 读取 GUIDE 输入重映射配置
func get_guide_remapping_config() -> GUIDERemappingConfig:
	if !ConfigUtils.has_section_key("Input", INPUT_REMAPPING_CONFIG_KEY):
		return GUIDERemappingConfig.new()
	
	var remapping_config: GUIDERemappingConfig = ConfigUtils.load_setting("Input", INPUT_REMAPPING_CONFIG_KEY, null)
	
	if remapping_config == null:
		CLog.e("Failed to load remapping config from config.")
		return GUIDERemappingConfig.new()
	
	return remapping_config


#endregion

#region Video

func _load_video_config() -> void:
	var b = ConfigUtils.load_setting("Video","Fullscreen",false)
	toggle_full_screen(b)

func _reset_video_config() -> void:
	toggle_full_screen(false)

## 切换全屏
func toggle_full_screen(value: bool) -> void:
	if value: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

#endregion

#region Game

func _load_game_config() -> void:
	var lang:LocalizationUtils.Lang = ConfigUtils.load_setting("Game","Language", LocalizationUtils.get_default_lang())
	set_locale_by_lang(lang)

func _reset_game_config() -> void:
	TranslationServer.set_locale(OS.get_locale())

## 根据本地化枚举设置地区
func set_locale_by_lang(lang:LocalizationUtils.Lang) -> void:
	var locale_lang = LocalizationUtils.get_locale_by_lang(lang)
	TranslationServer.set_locale(locale_lang)

#endregion
