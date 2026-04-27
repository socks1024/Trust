# Core 核心系统

## 场景管理器

场景管理器由 `SceneUtils` 工具类和 `LoadControl` 加载界面基类组成，提供场景切换和带加载界面的异步加载功能。

### SceneUtils

`SceneUtils` 是处理场景相关逻辑的静态工具类。

**核心方法：**

- `quick_instantiate(parent: Node, p_scene: PackedScene, init_callable = null)` - 快速实例化场景，具有可选的初始化回调函数，接收一个 Node 作为参数

- `switch_scene_by_path(from_scene: Node, to_scene_path: String)` - 直接切换场景

- `switch_scene_by_load_control(from_scene: Node, to_scene_path: String, load_scene_path: String, min_load_time: float = -1, confirm_time: float = -1)` - 通过加载界面切换场景
  - `from_scene` - 当前场景节点，将被释放
  - `to_scene_path` - 目标场景的资源路径
  - `load_scene_path` - 加载界面场景的资源路径（需要继承 `LoadControl`）
  - `min_load_time` - 最小加载时间（秒），用于确保加载界面至少显示一定时间
  - `confirm_time` - 加载完成后的确认等待时间（秒）

### LoadControl

`LoadControl` 是加载界面的抽象基类，使用 Godot 的多线程资源加载功能实现异步加载。

**核心信号：**

- `load_finish(res)` - 加载完成时发出，携带加载好的 PackedScene 资源

**抽象方法：**

- `_init_progress_control()` - 初始化进度显示控件（如进度条）
- `_update_progress_control(value: float)` - 更新进度显示（value 范围 0.0 ~ 1.0）
- `_free_progress_control()` - 释放进度控件/加载界面

---

## 存读档系统

### Config 存档 & 读档

配置存档系统由 `ConfigUtils` 工具类和 `SettingsManager` 管理器组成，用于持久化存储游戏设置。

#### ConfigUtils

`ConfigUtils` 是一个静态工具类，封装了 Godot 的 `ConfigFile` API。
该工具类默认将config文件存储在 user://config.cfg 位置。

**核心方法：**

- `save_setting(section: String, key: String, default = null)` - 将设置保存到配置文件

- `load_setting(section: String, key: String, default = null) -> Variant` - 从配置文件加载设置

- `has_section(section: String) -> bool` - 检查是否存在某个配置分类

- `has_section_key(section: String, key: String) -> bool` - 检查是否存在某个配置项

- `erase_config()` - 删除整个配置文件

- `erase_section(section: String)` - 删除某个配置分类

- `erase_section_key(section: String, key: String)` - 删除某个配置项

- `get_keys_by_section(section: String) -> PackedStringArray` - 获取某个分类下的所有配置项名称

#### SettingsManager

`SettingsManager` 是一个 AutoLoad 单例，负责管理所有游戏设置的加载、保存和重置。

**支持的配置分类：**

1. **Audio：** - 音频设置
   - 管理所有音频总线的音量
   - `get_bus_volume_db(bus_name: String) -> float` - 获取总线音量
   - `set_bus_volume_db(bus_name: String, volume_db: float)` - 设置总线音量
   - `mute_bus(bus_name: String, mute: bool)` - 静音/取消静音

2. **Input：** - 输入设置（GUIDE）
   - 保存和加载 GUIDE 输入动作的按键映射配置
   - `set_guide_remapping_config(remapping_config: GUIDERemappingConfig)` - 应用 GUIDE 输入重映射配置
   - `get_guide_remapping_config() -> GUIDERemappingConfig` - 读取 GUIDE 输入重映射配置

3. **Video：** - 视频设置
   - `toggle_full_screen(value: bool)` - 切换全屏模式

4. **Game：** - 游戏设置
   - `set_locale_by_lang(lang: LocalizationUtils.Lang)` - 设置游戏语言

**其他核心方法**

- `reset_all_settings()` - 删除配置文件并重置所有设置为默认值

---

## 本地化配置框架

目前的本地化配置框架采用 Godot 内置的本地化翻译框架，以 csv 文件作为本地化资源。

### LocalizationUtils

`LocalizationUtils` 是一个静态工具类，提供与本地化相关的逻辑支持。

**语言枚举**

**核心方法：**

- `get_default_lang() -> Lang` - 根据系统语言获取默认语言

- `get_lang_by_locale(locale: String) -> Lang` - 将 Godot 本地化代码转换为语言枚举

- `get_locale_by_lang(lang: Lang) -> String` - 将语言枚举转换为 Godot 本地化代码

### 扩展语言支持

如需添加新语言：

1. 在 `LocalizationUtils.Lang` 枚举中添加新值
2. 在 `LANG_LOCALE` 常量字典中添加新的语言代码和本地化代码的映射
3. 重新导入 csv 文件，确保 Godot 本地化系统识别到了新语言
