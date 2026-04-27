extends Panel
## 教程弹窗 - 多页翻页弹窗
##
## 显示多页教程文本，支持翻页和关闭。
## 通过信号通知外部弹窗已关闭。

## 滑动方向枚举
enum SlideDirection {
	LEFT,   ## 从左侧滑入
	RIGHT,  ## 从右侧滑入
	UP,     ## 从上方滑入
	DOWN,   ## 从下方滑入
}

## 弹窗关闭时发出
signal popup_closed

## 滑动偏移量（像素）
@export var slide_offset: float = 300.0
## 动画时长（秒）
@export var anim_duration: float = 0.35
## 滑入滑出方向
@export var slide_direction: SlideDirection = SlideDirection.RIGHT
## 滑入缓动类型
@export var slide_in_ease: Tween.EaseType = Tween.EASE_OUT
## 滑入过渡类型
@export var slide_in_trans: Tween.TransitionType = Tween.TRANS_CUBIC
## 滑出缓动类型
@export var slide_out_ease: Tween.EaseType = Tween.EASE_IN
## 滑出过渡类型
@export var slide_out_trans: Tween.TransitionType = Tween.TRANS_CUBIC

## 下一步按钮
@onready var _next_btn: CommonButton = %NextBtn
## 内容标签
@onready var _content_label: RichTextLabel = %ContentLabel
## 页码标签
@onready var _page_label: Label = %PageLabel
## 标题标签
@onready var _title_label: Label = %PopupTitle
## 内部面板（用于滑动动画）
@onready var _inner_panel: PanelContainer = %InnerPanel

## 当前页面列表
var _pages: Array[String] = []
## 当前页索引
var _current_page: int = 0
## 最后一页按钮文本
var _finish_text: String = "开始工作 →"
## 当前活跃的动画Tween
var _anim_tween: Tween = null


func _ready() -> void:
	_next_btn.pressed.connect(_on_next_pressed)
	hide()


## 显示弹窗，传入页面内容数组
func show_pages(pages: Array[String], title: String = "教程", finish_text: String = "开始工作 →") -> void:
	_pages = pages
	_current_page = 0
	_finish_text = finish_text
	_title_label.text = title
	_update_page()
	show()
	_play_slide_in()


## 更新当前页面显示
func _update_page() -> void:
	if _current_page >= _pages.size():
		return
	_content_label.clear()
	_content_label.append_text(_pages[_current_page])
	_page_label.text = "%d / %d" % [_current_page + 1, _pages.size()]
	# 最后一页显示完成按钮文本
	if _current_page >= _pages.size() - 1:
		_next_btn.text = _finish_text
	else:
		_next_btn.text = "下一步 →"


## 下一步按钮回调
func _on_next_pressed() -> void:
	_current_page += 1
	if _current_page >= _pages.size():
		# 所有页面已看完，播放滑出动画后关闭弹窗
		_next_btn.disabled = true
		_play_slide_out()
	else:
		_update_page()


## --- 动画方法 ---

## 播放滑入动画（面板从右侧滑入 + 背景淡入）
func _play_slide_in() -> void:
	# 终止之前的动画
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	# 初始状态：面板偏移到屏幕外，背景透明
	var is_horizontal: bool = _is_horizontal()
	var offset: float = _get_slide_offset()
	if is_horizontal:
		_inner_panel.position.x += offset
	else:
		_inner_panel.position.y += offset
	modulate.a = 0.0
	# 记录目标位置
	var target: float = (_inner_panel.position.x if is_horizontal else _inner_panel.position.y) - offset
	var prop: String = "position:x" if is_horizontal else "position:y"
	# 创建动画
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.set_ease(slide_in_ease).set_trans(slide_in_trans)
	_anim_tween.tween_property(_inner_panel, prop, target, anim_duration)
	_anim_tween.tween_property(self, "modulate:a", 1.0, anim_duration)


## 播放滑出动画（面板向右侧滑出 + 背景淡出），结束后关闭弹窗
func _play_slide_out() -> void:
	# 终止之前的动画
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	# 创建动画
	var is_horizontal: bool = _is_horizontal()
	var offset: float = _get_slide_offset()
	var current: float = _inner_panel.position.x if is_horizontal else _inner_panel.position.y
	var target: float = current + offset
	var prop: String = "position:x" if is_horizontal else "position:y"
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.set_ease(slide_out_ease).set_trans(slide_out_trans)
	_anim_tween.tween_property(_inner_panel, prop, target, anim_duration)
	_anim_tween.tween_property(self, "modulate:a", 0.0, anim_duration)
	# 动画结束后关闭弹窗
	_anim_tween.chain().tween_callback(_on_slide_out_finished)


## 滑出动画完成回调
func _on_slide_out_finished() -> void:
	hide()
	_next_btn.disabled = false
	# 重置偏移和透明度
	var offset: float = _get_slide_offset()
	if _is_horizontal():
		_inner_panel.position.x -= offset
	else:
		_inner_panel.position.y -= offset
	modulate.a = 1.0
	popup_closed.emit()


## 判断是否为水平方向滑动
func _is_horizontal() -> bool:
	return slide_direction == SlideDirection.LEFT or slide_direction == SlideDirection.RIGHT


## 获取带符号的滑动偏移量
func _get_slide_offset() -> float:
	match slide_direction:
		SlideDirection.LEFT, SlideDirection.UP:
			return -slide_offset
		_:
			return slide_offset
