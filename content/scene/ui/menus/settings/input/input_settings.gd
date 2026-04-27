extends Control


func _on_config_item_buttons_config_changed(new_config: GUIDERemappingConfig) -> void:
	SettingsManager.set_guide_remapping_config(new_config)

## 1 输入UI的场景嵌套结构与 GUIDERemapper 类型的结构对应。

## 1.1 SettingsManager 的 Input 部分需要维护一个 GUIDERemappingConfig 对象来存储当前的输入重映射配置。
## 1.1.1 该对象在初始化时通过 Config 中的 GuideRemappingConfig 构建。
## 1.1.2 该对象在输入绑定发生变化时被 1.3 中的 GUIDERemapper 对象更新。

## 1.2 在嵌套结构中，ConfigItem 对应实现为 GUIDEConfigItemButton。
## 1.2.1 该场景是一个根节点继承于 GUIDEInputButton 的场景，该场景负责显示和编辑这个 ConfigItem 相关的输入绑定
## 1.2.1.1 变更通过 GUIDEInputButton 的 input_catched 信号发送给上级节点，上级节点绑定信号时，会额外 bind 当前 ConfigItem 以便上级节点能够更新对应的 ConfigItem 的输入绑定。
## 1.2.2 该场景是可实例化的子场景，运行时会根据 ConfigItem 被动态创建。
## 1.2.3 该场景被实例化时，上级节点会传入 GUIDERemapper 对象及与自身相对应的 ConfigItem。

## 1.3 在嵌套结构中，GUIDERemapper 本身对应实现为一个根节点继承于 ConfigControl 的场景，根节点脚本命名为 ConfigGUIDEItemButtons。
## 1.3.1 该节点负责根据 ConfigItem 动态创建多个 GUIDEConfigItemButton 子节点。
## 1.3.1.1 具有相同 DisplayName 和 DisplayCategory 的子节点会被排列在同一行，使用 HorizontalBox 来排列。
## 1.3.1.2 具有不同 DisplayName 或 DisplayCategory 的子节点组会被排列在不同行，使用 VerticalBox 来排列。
## 1.3.1.3 同 DisplayCategory 的按钮子节点组之间会有一个标题标签显示 DisplayCategory 的名称，插在 VerticalBox 中分界的位置。
## 1.3.1.4 同 DisplayName 的按钮子节点组前面会有一个标题标签显示 DisplayName 的名称，插在 HorizontalBox 开头。
## 1.3.1.5 实例化 GUIDEConfigItemButton 子节点时，根节点为每个子节点注入从 GUIDERemapper 中获取的对应的 ConfigItem，并连接信号从而获取玩家要调整的输入。
## 1.3.2 该节点继承于 ConfigControl，因此需要实现该类所有的抽象方法。
## 1.3.2.1 需要在场景中配置该节点的 export 变量。ConfigSection 为 "Input"，ConfigKey 为 "GuideRemappingConfig"。
## 1.3.3 该节点负责收集和监听所有子节点的输入绑定变化.
## 1.3.3.1 该节点需要实现一个 _on_config_item_button_input_catched(input: GUIDEInput, config_item: GUIDERemapper.ConfigItem) 函数，用于连接到 input_catched 信号。
## 1.3.3.2 创建 GUIDEConfigItemButton 时，会将 input_catched 信号连接到 _on_config_item_button_input_catched 函数，并使用 bind 传入当前 ConfigItem 以便函数能够知道哪个 ConfigItem 的输入发生了变化。
## 1.3.3.3 _on_config_item_button_input_catched 函数中，会调用 ConfigControl 的 _set_config_value 函数，写入配置文件并发出 config_changed 信号通知上级节点（Input）输入配置发生了变化。
## 1.3.4 该场景会被静态实例化在 SettingsMenu 场景中，路径为 SettingsMenu/MarginContainer/TabContainer/Input/MarginContainer/ConfigGUIDEItemButtons。

## 1.4 在嵌套结构中，Input 节点已经被静态创建在 SettingsMenu 场景中，挂载了input_settings.gd脚本。
## 1.4.1 ConfigGUIDEItemButtons 的 config_changed 信号会被静态连接到 Input 节点中的 _on_config_item_buttons_config_changed 函数。
