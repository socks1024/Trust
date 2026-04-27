extends MarginContainer
## 滚动新闻组件
##
## 在裁剪区域内持续滚动显示随机新闻。
## 动态创建足够多的 Label 填满可视区域，滚出左侧后回收到右侧继续使用。

const NEWS_POOL: Array[String] = [
	"📰 星港区新航线开通，贸易量预计增长15%",
	"📰 殖民地议会通过新税法，小型企业税率下调",
	"📰 矿业公司发现新矿脉，矿石价格应声下跌",
	"📰 星际运输联盟罢工进入第三天，物流成本飙升",
	"📰 边境海盗活动频繁，商船保险费率上涨20%",
	"📰 新型农业技术推广成功，粮食产量创历史新高",
	"📰 中央银行宣布维持基准利率不变",
	"📰 科技园区扩建计划获批，预计创造5000个就业岗位",
	"📰 外星区发生小规模冲突，当局呼吁居民保持冷静",
	"📰 殖民地人口突破50万，城市规划面临新挑战",
	"📰 知名商人陈氏集团宣布破产，债务高达数百万",
	"📰 飞船燃料价格本月上涨8%，运输业叫苦不迭",
	"📰 殖民地信用评级获上调，外资信心增强",
	"📰 医疗物资短缺问题持续，黑市价格翻倍",
	"📰 本季度房地产交易量下降12%，市场观望情绪浓厚",
]

## 新闻间距（像素）
@export var news_gap: float = 120.0
## 滚动速度（像素/秒）
@export var news_speed: float = 80.0
## Label 使用的字体设置（在场景中配置）
@export var label_settings: LabelSettings
## Label 字体大小
@export var font_size: int = 13

## Label 的实际父容器（不受 MarginContainer 布局控制）
@onready var _label_container: Control = $LabelContainer

## 活跃的 Label 列表，按从左到右排列
var _labels: Array[Label] = []
## 上一条新闻索引（避免连续重复）
var _last_index: int = -1
## 是否已初始化
var _initialized: bool = false


func _ready() -> void:
	# 等一帧让布局生效
	await get_tree().process_frame
	_initialize_labels()
	_initialized = true


func _process(delta: float) -> void:
	if not _initialized:
		return
	var move: float = news_speed * delta
	# 所有 Label 同步左移
	for lbl: Label in _labels:
		lbl.position.x -= move
	# 检查最左侧的 Label 是否已完全滚出
	_recycle_offscreen_labels()
	# 检查右侧是否需要补充新 Label
	_fill_right_side()


## 初始化：创建足够多的 Label 填满容器
func _initialize_labels() -> void:
	var clip_w: float = size.x
	var next_x: float = clip_w  # 从容器右侧开始排列
	# 持续创建直到填满 "容器宽度 + 一个屏幕" 的范围
	while next_x < clip_w * 2.0:
		var lbl: Label = _create_label()
		lbl.position.x = next_x
		next_x = lbl.position.x + lbl.size.x + news_gap
		_labels.append(lbl)


## 回收已滚出左侧的 Label
func _recycle_offscreen_labels() -> void:
	while _labels.size() > 0:
		var first: Label = _labels[0]
		if first.position.x + first.size.x > 0.0:
			break
		# 已完全滚出左侧，移除并回收
		_labels.remove_at(0)
		first.queue_free()


## 在右侧补充 Label，确保无缝
func _fill_right_side() -> void:
	var clip_w: float = size.x
	# 找到当前最右侧的边缘
	var right_edge: float = 0.0
	if _labels.size() > 0:
		var last: Label = _labels[_labels.size() - 1]
		right_edge = last.position.x + last.size.x + news_gap
	# 如果右侧边缘还在可视区域内，就需要补充
	while right_edge < clip_w + news_gap:
		var lbl: Label = _create_label()
		lbl.position.x = right_edge
		right_edge = lbl.position.x + lbl.size.x + news_gap
		_labels.append(lbl)


## 创建一个新的 Label 节点
func _create_label() -> Label:
	var lbl: Label = Label.new()
	lbl.text = _pick_random_news()
	lbl.add_theme_font_size_override("font_size", font_size)
	if label_settings != null:
		lbl.label_settings = label_settings
	_label_container.add_child(lbl)
	# 立即计算尺寸
	lbl.size = lbl.get_minimum_size()
	# 纵向居中
	lbl.position.y = (_label_container.size.y - lbl.size.y) / 2.0
	return lbl


## 随机选一条不重复的新闻
func _pick_random_news() -> String:
	var idx: int = randi() % NEWS_POOL.size()
	if NEWS_POOL.size() > 1:
		while idx == _last_index:
			idx = randi() % NEWS_POOL.size()
	_last_index = idx
	return NEWS_POOL[idx]
