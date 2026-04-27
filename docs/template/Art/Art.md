# Art 艺术

## 音频系统

音频系统由三个核心类组成：`AudioEvent`（音频事件资源）、`AudioEventPlayer`（音频播放器）和 `AudioManager`（音频管理器）。
音频系统不与程序的其他部分（如音量设置）耦合，如果需要换用其他音频系统（如 FMOD for Godot），仅需禁用 AutoLoad 中的 AudioManager。

### AudioEvent

`AudioEvent` 是一个资源类，用于定义音频事件的各种属性。

**核心属性：**

- `name` - 音频事件的唯一名称，用于标识和查询播放器
- `audio_stream` - 基础的 AudioStream 资源
- `is_loop` - 是否循环播放
- `priority` - 优先级（0-100，数值越小优先级越高）
- `bus` - 音频总线名称，用于音量控制和效果链
- `volume` - 音量（相对于总线的偏移，单位 dB）
- `random_volume_range` - 音量随机范围，产生变化效果
- `pitch` - 音调缩放（0.01-4）
- `random_pitch_range` - 音调随机范围
- `variants` - 变体列表，用于播放不同的音频资源

**核心方法：**

- `get_random_audio_stream()` - 返回一个随机的 AudioStream 资源（从变体列表或基础资源中随机选择）
- `get_random_volume_db()` - 返回应用随机范围后的最终音量
- `get_random_pitch_scale()` - 返回应用随机范围后的最终音调

### AudioEventPlayer

`AudioEventPlayer` 是 `AudioStreamPlayer` 的增强版本，专门用于播放 `AudioEvent` 资源。它不保存音频数据，而是通过 AudioEvent 资源来配置播放参数。

**核心方法：**
- `play_audio(event: AudioEvent = null)` - 播放音频事件，自动应用 AudioEvent 中配置的所有参数
- `pause_audio()` - 暂停播放，保持当前位置
- `continue_audio() -> void` — 恢复暂停的播放（会重新随机音量）
- `stop_audio(clear_event: bool = false)` - 停止播放，可选清除配置的事件
- `fade_in(fade_time: float, callback = null)` - 淡入播放，可指定淡入时间和完成回调
- `fade_out(fade_time: float, callback = null)` - 淡出停止，可指定淡出时间和完成回调

### AudioManager

`AudioManager` 是一个全局管理器，负责协调所有音频的播放。它维护两个播放器池：

1. **音效池（Sound Pool）** - 用于播放音效，有容量限制（默认16个），超出时会移除优先级最低的
2. **音乐轨道（Music Tracks）** - 用于管理多个音乐轨道，支持交叉淡入淡出

**核心方法：**
- `play_sound(event: AudioEvent)` - 播放音效
  
- `play_music(event: AudioEvent, track_name: StringName, fade_time: float = 1.0, cross_fade: bool = false)` - 播放音乐
  - `track_name` - 音乐轨道名称（用于区分不同的音乐层或背景音）
  - `fade_time` - 淡入/淡出时间
  - `cross_fade` - 是否使用交叉淡入淡出效果
  
- `pause_music(track_name: StringName, fade_time: float = 0.5)` — 暂停指定音乐轨道，支持淡出效果（`fade_time <= 0` 时立即暂停）

- `continue_music(track_name: StringName, fade_time: float = 0.5)` — 恢复指定音乐轨道的播放
  
- `get_player_by_event_name(event_name: StringName) -> AudioEventPlayer` - 根据事件名称查找正在播放的播放器

---

## 视觉特效库

### 精灵图效果

精灵图效果是作用于单个节点（Sprite2D、TextureRect 等）的 Shader，通过 `ShaderMaterial` 挂载使用。

#### Color — 基础颜色

将精灵所有不透明像素替换为指定的纯色，适用于角色死亡剪影、远景层叠、前景遮挡、隐藏在障碍物后的角色轮廓显示等场景。

**参数：**

- `base_color` : Color = 黑色 (0,0,0,1) — 着色颜色
- `color_amount` : float (0.0 ~ 1.0) = 1.0 — 着色强度。0.0 = 原始颜色，1.0 = 完全着色

#### Dissolve — 溶解

使用噪声纹理驱动的溶解效果，可实现角色消失、场景切换等过渡动画。

**参数：**

- `dissolve_texture` : Sampler2D = 白色 — 溶解噪声纹理（推荐使用 NoiseTexture2D 或自定义灰度噪声图）
- `dissolve_amount` : float (0.0 ~ 1.0) = 0.0 — 溶解进度。0.0 = 完全显示，1.0 = 完全溶解
- `edge_color` : Color = 白色 (1,1,1,1) — 溶解边缘发光颜色
- `edge_width` : float (0.0 ~ 0.2) = 0.05 — 溶解边缘宽度，值越大发光边缘越宽
- `invert` : bool = false — 是否反转溶解方向。true = 从亮到暗溶解，false = 从暗到亮溶解

#### Outline — 轮廓线

在精灵边缘绘制描边/轮廓线效果，适用于角色选中高亮、卡通风格描边等场景。

**参数：**

- `enabled` : bool = false — 是否启用轮廓线效果
- `outline_color` : Color = 白色 (1,1,1,1) — 轮廓线颜色
- `outline_width` : float (0.0 ~ 10.0, 步长 0.5) = 1.0 — 轮廓线宽度（像素数），值越大描边越粗

#### InnerOutline — 内轮廓线

**说明：** 在精灵不透明区域的**内侧**边缘绘制描边效果（与已有的 Outline 外轮廓线互补）。原理是采样周围像素的 alpha 值，如果当前像素不透明但周围存在透明像素，则判定为边缘内侧。

**参数：**
- `enabled` : bool — 是否启用
- `outline_color` : Color — 轮廓线颜色
- `outline_width` : float (0.0 ~ 10.0) — 轮廓线宽度
- `alpha_threshold` : float (0.0 ~ 1.0) — 边缘判定的 alpha 阈值

#### DropShadow — 投影

在精灵下方绘制一个偏移的半透明投影副本，模拟投射阴影效果。

**参数：**

- `enabled` : bool = false — 是否启用投影效果
- `shadow_color` : Color = 半透明黑色 (0,0,0,0.5) — 投影颜色
- `shadow_offset` : Vector2 = (3.0, 3.0) — 投影偏移量（像素数）。x 正方向为右，y 正方向为下

#### Curtain — 幕布飘动

**说明：** 模拟布料/幕布的飘动效果，包含多层波浪形变、褶皱阴影和边缘柔化。

**参数：**
- 波浪：`wave_amplitude`、`wave_frequency`、`wave_speed`、`vertical_amplitude`
- 褶皱：`fold_intensity`、`fold_frequency`、`fold_shadow_color`、`fold_highlight_color`
- 悬挂：`top_weight`、`pin_top`

### 后处理效果

后处理效果系统提供一套基于 2D Shader 的全屏后处理效果框架。

控制器脚本 `PostProcessController` 是一个工具脚本，挂载在后处理场景中的 `CanvasLayer` 根节点（layer=127，确保在最顶层渲染）上。

根节点会自动获取子节点上的所有后处理 shader，从而可以快速调节相关参数。

#### 内置效果一览

- **ChromaticAberration** — 色差偏移，模拟镜头色散
  - `chromatic_aberration`：偏移强度（0.0 ~ 10.0，默认 1.0）

- **Scanline** — 扫描线，模拟 CRT 显示器
  - `scanline_density`：扫描线密度（1.0 ~ 2000.0，默认 200.0）
  - `scanline_strength`：强度（0.0 ~ 1.0，默认 0.3）
  - `scroll_speed`：滚动速度（0.0 ~ 50.0，默认 3.0）

- **Flicker** — 屏幕闪烁，模拟老旧显示器
  - `flicker_strength`：闪烁强度（0.0 ~ 0.2，默认 0.02）
  - `flicker_speed`：闪烁速度（0.0 ~ 30.0，默认 8.0）

- **Brightness** — 整体亮度调节
  - `brightness`：亮度倍率（0.5 ~ 1.5，默认 1.0）

- **Vignette** — 暗角效果，画面边缘变暗
  - `vignette_strength`：暗角强度（0.0 ~ 2.0，默认 0.4）
  - `vignette_radius`：暗角半径（0.0 ~ 1.5，默认 0.8）

- **Bloom** — 泛光/辉光，提取高亮区域并高斯模糊后叠加，模拟光晕效果
  - `threshold`：亮度阈值（0.0 ~ 2.0，默认 0.8），高于此亮度的像素才会产生辉光
  - `intensity`：辉光强度（0.0 ~ 2.0，默认 0.5）
  - `blur_size`：模糊扩散范围（0.0 ~ 5.0，默认 1.5）
  - `blur_samples`：模糊采样数（1 ~ 12，默认 6），越高越平滑，性能消耗越大

- **Transition** — 场景过渡效果，使用灰度遮罩纹理实现各种过渡动画（圆形擦除、菱形过渡、像素溶解等）
  - `progress`：过渡进度（0.0 ~ 1.0，默认 0.0），0 = 完全显示原画面，1 = 完全覆盖
  - `smoothness`：过渡边缘柔和度（0.0 ~ 0.5，默认 0.05），值越大边缘越柔和
  - `cover_texture`：覆盖纹理，过渡完成后显示的图片（默认黑色；如需纯色过渡，指定一张纯色纹理即可）
  - `edge_color`：边缘发光颜色（默认透明），设置 alpha > 0 启用边缘发光
  - `edge_width`：边缘宽度（0.0 ~ 0.2，默认 0.03）
  - `invert`：反转过渡方向（0 或 1，默认 0）
  - `transition_texture`：灰度遮罩纹理，在检查器面板中直接设置即可，不同的灰度图产生不同的过渡效果
  
  **使用方式**：在检查器面板中设置 `transition_texture` 灰度遮罩图，然后通过 Tween 控制 `progress` 参数从 0→1 实现渐入，1→0 实现渐出。不同的灰度图可以产生不同的过渡效果（如径向擦除、水平擦除、菱形过渡、噪声溶解等）。

#### 运行时 API

`PostProcessController` 提供以下公共方法：

**开关控制：**

- `enable_all()` - 启用所有后处理效果
- `disable_all()` - 禁用所有后处理效果
- `enable_effect(effect_name: String)` - 启用指定效果（传入节点名，如 `"Vignette"`）
- `disable_effect(effect_name: String)` - 禁用指定效果

**参数控制：**

- `set_effect_param(effect_name: String, shader_param: String, value: Variant)` - 设置指定效果的 shader 参数
- `get_effect_param(effect_name: String, shader_param: String) -> Variant` - 获取指定效果的 shader 参数

**恢复默认值：**

- `reset_effect_param(effect_name: String, shader_param: String)` - 恢复指定效果的单个参数到默认值
- `reset_effect_params(effect_name: String)` - 恢复指定效果的所有参数到默认值
- `reset_all_params()` - 恢复所有效果的所有参数到默认值

**查询：**

- `get_effect_material(effect_name: String) -> ShaderMaterial` - 获取指定效果的 ShaderMaterial
- `get_effect_names() -> Array` - 获取所有效果名列表

#### 添加新效果

添加一个新的后处理效果只需两步：

**第 1 步：编写 Shader**

在 `shaders/` 目录下创建新的 `.gdshader` 文件。

**第 2 步：在场景中添加节点**

每个效果由一对节点组成：`BackBufferCopy`（用于拷贝屏幕内容）+ `ColorRect`（用于应用 Shader）。

打开 `post_processing.tscn`，在末尾添加一对节点：

1. 添加一个 `BackBufferCopy` 节点（`copy_mode` 设为 `Viewport`）
2. 添加一个 `ColorRect` 节点，命名为效果名称（如 `MyEffect`）
   - 为其创建 `ShaderMaterial`，赋予刚才编写的 Shader
   - 将 `anchors_preset` 设为全屏（Full Rect）
   - 将 `mouse_filter` 设为 `Ignore`

完成后控制器会自动扫描新节点，在检查器面板中生成对应的开关和参数，无需修改任何 GDScript 代码。

---

## 动画库

### Spring 弹簧动画系统

**路径：** `content/script/animation/spring_variant/`

**说明：** 基于阻尼弹簧振荡器的弹性运动系统，提供 `SpringFloat`、`SpringVector2`、`SpringVector3` 三个变体，适用于位置、缩放、旋转等任何需要"弹弹的"手感的场景。

**核心 API：**
- `bump(amount)` — 给弹簧一个瞬间冲量
- `move_to(target)` — 弹性过渡到新目标值
- `move_to_additive(delta)` — 在当前目标上叠加偏移
- `restore_initial()` — 弹性回归初始值
- `stop()` / `finish()` / `reset()` — 停止/跳到目标/完全重置

**适用场景：** 受击反馈、UI 按钮弹性、跳跃挤压拉伸、相机跟随等。

---

## 编辑器工具

### BitMask 生成工具脚本

**路径：** `res://editor/texture_processing/generate_bitmask.gd`

**类型：** `@tool` EditorScript（编辑器内运行）

**说明：** 批量扫描指定目录下的所有图片文件，根据透明度通道（alpha）生成对应的 BitMap 资源（`.tres`），保存在图片同目录下，文件名为 `原文件名_bitmask.tres`。已存在同名文件时自动跳过，不会覆盖。

**使用方法：** 在 Godot 编辑器中打开此脚本，修改 `SOURCE_DIR` 常量为目标目录路径，点击右上角"运行"按钮即可。

**可配置常量：**
- `SOURCE_DIR` : String — 要扫描的目录路径
- `ALPHA_THRESHOLD` : float (0.0 ~ 1.0) — 透明度阈值，低于此值的像素视为透明
- `IMAGE_EXTENSIONS` : Array[String] — 支持的图片扩展名列表

**适用场景：** 为 TextureButton 等需要点击区域检测的节点批量生成 BitMask，实现基于图片形状的精确点击判定。

---