# UI 用户界面

TODO 需要优化

## 基本界面

模板提供了以下预制界面：

**开始游戏界面：** - `content/scene/ui/menus/start/`
- 游戏入口界面，包含开始游戏、设置、退出等按钮

**设置界面：** - `content/scene/ui/menus/settings/`
- 包含音频、视频、输入等设置选项卡
- 输入设置自动生成所有自定义动作的按键配置控件

**制作者名单界面：** - `content/scene/ui/menus/credit/`
- 显示游戏制作团队信息

## 通用 UI 组件

### Common Button

`CommonButton` 是一个带有按下动画和音效的增强按钮。

**核心属性：**

- `duration: float` - 动画持续时间
- `ease_curve: Curve` - 动画缓动曲线
- `press_sound: AudioEvent` - 按下时播放的音效

**核心信号：**

- `button_anim_finish` - 按钮动画播放完成时发出

TODO CommonTextureButton

### InputButton

`InputButton` 是一个输入捕获按钮，继承自 `CommonButton`，新增了捕获输入并显示在按钮上的功能。不会捕捉鼠标移动输入。

**核心属性：**

- `initial_text: String` - 初始显示文本
- `waiting_text: String` - 等待输入时显示的文本
- `catch_mouse_move: bool` - 是否捕获鼠标移动
- `joypad_motion_deadzone: float` - 手柄摇杆死区（0-1）
- `mouse_motion_deadzone: float` - 鼠标移动死区

**核心信号：**

- `input_catched(event: InputEvent)` - 捕获到输入时发出

### ConfigControl

`ConfigControl` 是配置控件的抽象基类。
加入场景树时，控件会加载默认值并显示。
用户修改控件时，新的值会被自动保存到配置，并发出 `config_changed` 信号。可以通过该类的派生类来创建具体的配置控件，如绑定音量的滑动条。

**核心属性：**

- `config_section: String` - 配置分类
- `config_key: String` - 配置项名称

**核心信号：**

- `config_changed(value)` - 配置更改时发出

**抽象方法：**

- `get_default_value() -> Variant` - 获取默认值
- `set_control_value(value: Variant)` - 更新控件显示的值
- `set_control_editable(editable: bool)` - 设置控件是否可编辑
- `connect_control_input()` - 连接控件的输入信号