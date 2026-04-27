extends Control
## 审核工作台 - 纯UI层
##
## 只负责显示和用户交互，不包含任何游戏逻辑。
## 通过信号通知外部用户的操作，通过公开方法接收外部数据并更新显示。

## --- 用户操作信号 ---

## 玩家点击了批准按钮
signal approve_pressed
## 玩家点击了拒绝按钮
signal reject_pressed
## 玩家请求重新开始游戏
signal restart_requested
## 玩家请求返回主菜单
signal back_to_menu_requested
## 玩家调整了利率（参数：实际利率百分比整数，如 10 表示 10%）
signal rate_changed(rate_percent: int)

## --- 顶部状态栏 ---
@onready var year_label: Label = %YearLabel
@onready var applicant_progress_label: Label = %ApplicantProgressLabel
## --- 左侧 - 详细说明面板 ---
@onready var info_title: Label = %InfoTitle
@onready var info_label: RichTextLabel = %InfoLabel

## --- 左侧 - 对话区域（申请人陈述） ---
@onready var statement_label: RichTextLabel = %StatementLabel

## --- 右侧 - 申请表面板 ---
@onready var name_label: Label = %NameLabel
@onready var profession_label: Label = %ProfessionLabel
@onready var income_label: Label = %IncomeLabel
@onready var residence_label: Label = %ResidenceLabel
## 资产列表容器（动态填充）
@onready var asset_list: VBoxContainer = %AssetList
@onready var asset_total_label: Label = %AssetTotalLabel
## 负债列表容器（动态填充）
@onready var debt_list: VBoxContainer = %DebtList
@onready var debt_total_label: Label = %DebtTotalLabel
## 净资产
@onready var net_worth_label: Label = %NetWorthLabel
## 贷款信息
@onready var loan_amount_label: Label = %LoanAmountLabel
@onready var purpose_label: Label = %PurposeLabel
@onready var period_label: Label = %PeriodLabel
@onready var rate_label: Label = %RateLabel
@onready var interest_label: Label = %InterestLabel
@onready var repayment_label: Label = %RepaymentLabel

## --- 操作按钮 ---
@onready var approve_btn: CommonButton = %ApproveBtn
@onready var reject_btn: CommonButton = %RejectBtn

## --- ⓘ 信息按钮（场景中静态配置） ---
@onready var profession_info_btn: Button = %ProfessionInfoBtn
@onready var residence_info_btn: Button = %ResidenceInfoBtn
## --- 底部状态栏 ---
@onready var fund_label: Label = %FundLabel
@onready var total_loan_label: Label = %TotalLoanLabel
@onready var profit_label: Label = %ProfitLabel

## --- 审批条件区 ---
## 审批条件区容器（教程年隐藏）
@onready var approval_conditions_section: VBoxContainer = %ApprovalConditionsSection
## 利率滑动条
@onready var rate_slider: HSlider = %RateSlider
## 利率百分比标签（显示 "10%"）
@onready var rate_percent_label: Label = %RatePercentLabel
## 利率挡位标签（显示 "标准"）
@onready var rate_tier_label: Label = %RateTierLabel
## 抵押物列表容器（动态填充CheckBox）
@onready var collateral_list: VBoxContainer = %CollateralList
## 无资产时的提示标签
@onready var no_asset_hint: Label = %NoAssetHint
## 抵押覆盖率标签
@onready var collateral_ratio_label: Label = %CollateralRatioLabel

## 当前选中的利率百分比（0~30）
var _selected_rate_percent: int = 10
## 当前申请者数据（用于利率联动计算）
var _current_applicant: ApplicantData = null
## 当前周期乘数（缓存，避免重复计算）
var _current_period_multiplier: float = 1.0

## 配置资源引用（用于获取描述信息）
var _config: RandomApplicantConfig = null

func _ready() -> void:
	approve_btn.pressed.connect(approve_pressed.emit)
	reject_btn.pressed.connect(reject_pressed.emit)
	# 利率滑动条连接
	rate_slider.value_changed.connect(_on_rate_slider_changed)
	# 为滑动条创建终端风格的grabber纹理
	_setup_slider_grabber()


## 设置配置资源引用
func set_config(config: RandomApplicantConfig) -> void:
	_config = config


## --- 供外部调用的显示方法 ---

## 更新顶部状态栏
func update_top_bar(year: int, current_index: int, total_count: int) -> void:
	year_label.text = "第 %d 年" % year
	applicant_progress_label.text = "申请 %d/%d" % [current_index, total_count]


## 显示申请者的基本信息
func show_applicant_info(data: ApplicantData) -> void:
	_current_applicant = data
	# 重置说明面板
	_show_info("详细说明", "点击申请表中的 ⓘ 按钮查看详细说明。")

	name_label.text = "%s  %s  %d岁" % [
		data.applicant_name,
		data.gender,
		data.age,
	]

	# 职业行：更新ⓘ按钮回调，年均收入显示在同一行右侧
	profession_label.text = data.profession
	var prof_desc: String = data.profession_description if not data.profession_description.is_empty() else _get_profession_description(data.profession)
	_bind_info_button(
		profession_info_btn,
		data.profession,
		prof_desc
	)

	income_label.text = "年均收入：%s" % _format_currency(data.annual_income)

	# 居住地行：添加ⓘ按钮（显示居住地+居住类型的组合说明）
	var loc_name: String = data.get_residence_location_name()
	var type_name: String = data.get_residence_type_name()
	residence_label.text = "%s    %s" % [loc_name, type_name]
	# 自定义角色优先使用自定义居住地描述
	var loc_desc: String = data.custom_residence_description if not data.custom_residence_description.is_empty() else _get_residence_location_description(data.residence_location)
	var residence_desc: String = "[b]%s[/b]\n%s\n\n[b]%s[/b]\n%s" % [
		loc_name,
		loc_desc,
		type_name,
		_get_residence_type_description(data.residence_type),
	]
	_bind_info_button(
		residence_info_btn,
		"%s · %s" % [loc_name, type_name],
		residence_desc
	)

	# 填充资产列表
	_populate_asset_list(data)

	# 填充负债列表
	_populate_debt_list(data)

	# 净资产
	net_worth_label.text = _format_currency(data.get_net_worth())

	# 贷款信息
	loan_amount_label.text = _format_currency(data.loan_amount)
	purpose_label.text = data.loan_purpose
	period_label.text = "%d 年" % data.loan_period

	# 申请人陈述
	statement_label.text = data.statement

	# 审批条件区：使用申请者贷款用途对应的默认利率
	var default_percent: int = _tier_to_default_percent(data.interest_rate_tier)
	rate_slider.set_value_no_signal(float(default_percent))
	_on_rate_slider_changed(float(default_percent))
	# 审批条件区：填充抵押物列表
	_populate_collateral_list(data)
	# 初始无勾选，更新覆盖率显示
	_update_collateral_ratio()


## 显示利率计算结果
func show_rate_info(rate_text: String, interest: int, repayment: int) -> void:
	rate_label.text = rate_text
	interest_label.text = _format_currency(interest)
	repayment_label.text = _format_currency(repayment)


## 清空陈述区域
func clear_statement() -> void:
	statement_label.text = ""


## 更新底部状态栏
func update_bottom_bar(fund: int, total_loaned: int, total_profit: int, profit_percent: int) -> void:
	fund_label.text = "🪙 资金池：%s" % _format_currency(fund)
	total_loan_label.text = "💳 在贷总额：%s" % _format_currency(total_loaned)
	var sign: String = "+" if total_profit >= 0 else ""
	profit_label.text = "📈 利润：%s%s（%+d%%）" % [sign, _format_currency(total_profit), profit_percent]


## 设置操作按钮的可用状态
func set_buttons_enabled(enabled: bool) -> void:
	approve_btn.disabled = not enabled
	reject_btn.disabled = not enabled


## 在陈述区域显示文本（支持BBCode，用于审批结果提示）
func show_dialogue(text: String) -> void:
	statement_label.text = text


## 设置审批条件区的可见性（教程年隐藏）
func set_conditions_visible(is_visible: bool) -> void:
	approval_conditions_section.visible = is_visible


## 获取玩家选择的利率百分比（0~30）
func get_selected_rate_percent() -> int:
	return _selected_rate_percent


## 获取玩家选择的利率挡位（根据百分比自动判断）
func get_selected_rate_tier() -> ApplicantData.InterestRateTier:
	return _percent_to_tier(_selected_rate_percent)


## 获取玩家勾选的抵押物列表（返回资产字典数组）
func get_selected_collaterals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child: Node in collateral_list.get_children():
		if child is CheckBox and (child as CheckBox).button_pressed:
			var asset: Dictionary = child.get_meta("asset_data", {}) as Dictionary
			if not asset.is_empty():
				result.append(asset)
	return result


## 获取玩家勾选的抵押物总估值
func get_selected_collateral_value() -> int:
	var total: int = 0
	for asset: Dictionary in get_selected_collaterals():
		total += asset.get("value", 0) as int
	return total


## 更新抵押覆盖率显示
func _update_collateral_ratio() -> void:
	if _current_applicant == null:
		collateral_ratio_label.text = ""
		collateral_ratio_label.hide()
		return
	var col_value: int = get_selected_collateral_value()
	var ratio: float = float(col_value) / float(_current_applicant.loan_amount) * 100.0
	collateral_ratio_label.text = "抵押估值 / 贷款金额：%s / %s = %d%%" % [
		_format_currency(col_value),
		_format_currency(_current_applicant.loan_amount),
		int(ratio),
	]
	collateral_ratio_label.show()


## --- 私有辅助方法 ---

## 填充资产列表
func _populate_asset_list(data: ApplicantData) -> void:
	# 清空现有子节点
	for child: Node in asset_list.get_children():
		child.queue_free()

	if data.assets.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "（无）"
		asset_list.add_child(empty_label)
	else:
		for asset: Dictionary in data.assets:
			var row: HBoxContainer = HBoxContainer.new()
			var category: String = asset.get("category", "") as String
			var name_lbl: Label = Label.new()
			name_lbl.text = asset.get("name", "") as String
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var value_lbl: Label = Label.new()
			value_lbl.text = _format_currency(asset.get("value", 0) as int)
			value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(name_lbl)
			row.add_child(value_lbl)
			# ⓘ 按钮放在行尾
			var info_btn: Button = _create_info_button(
				category,
				_get_asset_description(category)
			)
			row.add_child(info_btn)
			asset_list.add_child(row)

	asset_total_label.text = _format_currency(data.get_total_assets())


## 填充负债列表
func _populate_debt_list(data: ApplicantData) -> void:
	# 清空现有子节点
	for child: Node in debt_list.get_children():
		child.queue_free()

	if data.debts.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "（无）"
		debt_list.add_child(empty_label)
	else:
		for debt: Dictionary in data.debts:
			var row: HBoxContainer = HBoxContainer.new()
			var category: String = debt.get("category", "") as String
			var name_lbl: Label = Label.new()
			name_lbl.text = debt.get("name", "") as String
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var amount_lbl: Label = Label.new()
			amount_lbl.text = _format_currency(debt.get("amount", 0) as int)
			var status_lbl: Label = Label.new()
			var status_val: int = debt.get("status", 0) as int
			status_lbl.text = ApplicantData.get_debt_status_name(status_val as ApplicantData.DebtStatus)
			# 逾期标红
			if status_val == ApplicantData.DebtStatus.OVERDUE:
				status_lbl.add_theme_color_override("font_color", Color("#ff6b6b"))
			elif status_val == ApplicantData.DebtStatus.SETTLED:
				status_lbl.add_theme_color_override("font_color", Color("#5ee8e8"))
			row.add_child(name_lbl)
			row.add_child(status_lbl)
			row.add_child(amount_lbl)
			# ⓘ 按钮放在行尾
			var info_btn: Button = _create_info_button(
				category,
				_get_debt_description(category)
			)
			row.add_child(info_btn)
			debt_list.add_child(row)

	debt_total_label.text = _format_currency(data.get_total_debts())


## 填充抵押物列表（CheckBox）
func _populate_collateral_list(data: ApplicantData) -> void:
	# 立即移除现有子节点（不用queue_free，避免旧CheckBox影响覆盖率计算）
	for child: Node in collateral_list.get_children():
		collateral_list.remove_child(child)
		child.queue_free()

	if data.assets.is_empty():
		no_asset_hint.show()
		collateral_list.hide()
	else:
		no_asset_hint.hide()
		collateral_list.show()
		for asset: Dictionary in data.assets:
			var cb: CheckBox = CheckBox.new()
			cb.text = "%s  %s" % [
				asset.get("name", "") as String,
				_format_currency(asset.get("value", 0) as int),
			]
			cb.set_meta("asset_data", asset)
			# 隐藏勾选图标：用空纹理覆盖
			var empty_tex: ImageTexture = ImageTexture.new()
			cb.add_theme_icon_override("checked", empty_tex)
			cb.add_theme_icon_override("unchecked", empty_tex)
			cb.add_theme_icon_override("checked_disabled", empty_tex)
			cb.add_theme_icon_override("unchecked_disabled", empty_tex)
			# 设置未勾选时的默认样式
			_apply_collateral_style(cb, false)
			# 勾选变化时更新覆盖率和样式
			cb.toggled.connect(_on_collateral_toggled.bind(cb))
			collateral_list.add_child(cb)


## 抵押物勾选变化回调
func _on_collateral_toggled(pressed: bool, cb: CheckBox) -> void:
	_apply_collateral_style(cb, pressed)
	_update_collateral_ratio()


## 应用抵押物CheckBox的选中/未选中样式（与利率按钮风格一致）
func _apply_collateral_style(cb: CheckBox, selected: bool) -> void:
	if selected:
		# 勾选：绿底黑字，hover时只变字色
		var pressed_style: StyleBoxFlat = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.18, 0.78, 0.44, 0.9)
		pressed_style.border_color = Color(0.04, 0.06, 0.08, 1)
		pressed_style.set_border_width_all(1)
		pressed_style.set_content_margin_all(4.0)
		pressed_style.set_corner_radius_all(2)
		cb.add_theme_stylebox_override("normal", pressed_style)
		cb.add_theme_stylebox_override("hover", pressed_style)
		cb.add_theme_stylebox_override("pressed", pressed_style)
		cb.add_theme_stylebox_override("hover_pressed", pressed_style)
		cb.add_theme_stylebox_override("normal_pressed", pressed_style)
		cb.add_theme_color_override("font_color", Color(0.03, 0.05, 0.07, 1))
		cb.add_theme_color_override("font_hover_color", Color(0.1, 0.15, 0.12, 1))
		cb.add_theme_color_override("font_pressed_color", Color(0.03, 0.05, 0.07, 1))
		cb.add_theme_color_override("font_hover_pressed_color", Color(0.1, 0.15, 0.12, 1))
	else:
		# 未勾选：深色背景绿字，hover时只变字色
		var normal_style: StyleBoxFlat = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.04, 0.06, 0.08, 0.85)
		normal_style.border_color = Color(0.18, 0.78, 0.44, 0.7)
		normal_style.set_border_width_all(1)
		normal_style.set_content_margin_all(4.0)
		normal_style.set_corner_radius_all(2)
		cb.add_theme_stylebox_override("normal", normal_style)
		cb.add_theme_stylebox_override("hover", normal_style)
		cb.add_theme_stylebox_override("pressed", normal_style)
		cb.add_theme_stylebox_override("hover_pressed", normal_style)
		cb.add_theme_stylebox_override("normal_pressed", normal_style)
		cb.add_theme_color_override("font_color", Color(0.18, 0.78, 0.44, 1))
		cb.add_theme_color_override("font_hover_color", Color(0.3, 0.9, 0.55, 1))
		cb.add_theme_color_override("font_pressed_color", Color(0.18, 0.78, 0.44, 1))
		cb.add_theme_color_override("font_hover_pressed_color", Color(0.3, 0.9, 0.55, 1))


## 创建ⓘ信息按钮
func _create_info_button(title: String, description: String) -> Button:
	var btn: Button = Button.new()
	btn.text = "ⓘ"
	btn.custom_minimum_size = Vector2(28, 28)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_show_info.bind(title, description))
	return btn


## 绑定ⓘ按钮的回调（用于场景中静态配置的按钮）
func _bind_info_button(btn: Button, title: String, description: String) -> void:
	# 断开旧回调
	for conn: Dictionary in btn.pressed.get_connections():
		btn.pressed.disconnect(conn["callable"])
	# 连接新回调
	btn.pressed.connect(_show_info.bind(title, description))


## 在左侧说明面板中显示信息
func _show_info(title: String, description: String) -> void:
	info_title.text = "ℹ️ %s" % title
	info_label.text = description


## 为滑动条创建终端风格的grabber纹理（纯色小方块）
func _setup_slider_grabber() -> void:
	var grabber_img: Image = Image.create(12, 16, false, Image.FORMAT_RGBA8)
	grabber_img.fill(Color(0.18, 0.78, 0.44, 1))
	var grabber_tex: ImageTexture = ImageTexture.create_from_image(grabber_img)
	var grabber_hl_img: Image = Image.create(12, 16, false, Image.FORMAT_RGBA8)
	grabber_hl_img.fill(Color(0.3, 0.9, 0.55, 1))
	var grabber_hl_tex: ImageTexture = ImageTexture.create_from_image(grabber_hl_img)
	rate_slider.add_theme_icon_override("grabber", grabber_tex)
	rate_slider.add_theme_icon_override("grabber_highlight", grabber_hl_tex)


## 利率滑动条值变化回调
func _on_rate_slider_changed(value: float) -> void:
	_selected_rate_percent = int(value)
	# 更新百分比标签
	rate_percent_label.text = "%d%%" % _selected_rate_percent
	# 更新挡位标签
	var tier: ApplicantData.InterestRateTier = _percent_to_tier(_selected_rate_percent)
	rate_tier_label.text = _tier_to_name(tier)
	# 通知外部重新计算利率
	if _current_applicant != null:
		rate_changed.emit(_selected_rate_percent)


## 根据利率百分比判断所属挡位
func _percent_to_tier(percent: int) -> ApplicantData.InterestRateTier:
	if percent < 8:
		return ApplicantData.InterestRateTier.LOW
	elif percent < 13:
		return ApplicantData.InterestRateTier.MEDIUM
	elif percent < 18:
		return ApplicantData.InterestRateTier.HIGH
	else:
		return ApplicantData.InterestRateTier.USURY


## 挡位枚举转默认百分比（用于初始化滑动条位置）
func _tier_to_default_percent(tier: ApplicantData.InterestRateTier) -> int:
	match tier:
		ApplicantData.InterestRateTier.LOW:
			return 5
		ApplicantData.InterestRateTier.MEDIUM:
			return 10
		ApplicantData.InterestRateTier.HIGH:
			return 15
		ApplicantData.InterestRateTier.USURY:
			return 20
		_:
			return 10


## 挡位枚举转显示名称
func _tier_to_name(tier: ApplicantData.InterestRateTier) -> String:
	match tier:
		ApplicantData.InterestRateTier.LOW:
			return "低息"
		ApplicantData.InterestRateTier.MEDIUM:
			return "标准"
		ApplicantData.InterestRateTier.HIGH:
			return "高息"
		ApplicantData.InterestRateTier.USURY:
			return "高利贷"
		_:
			return "标准"


## --- 描述查找辅助方法 ---

## 从配置中查找职业描述
func _get_profession_description(profession_name: String) -> String:
	if _config != null:
		for prof: ProfessionConfig in _config.professions:
			if prof.profession_name == profession_name:
				return prof.description if not prof.description.is_empty() else "暂无该职业的详细说明。"
	return "暂无该职业的详细说明。"


## 从配置中查找资产类别描述
func _get_asset_description(category: String) -> String:
	if _config != null:
		for asset: AssetTemplateConfig in _config.general_assets:
			if asset.category == category:
				return asset.description if not asset.description.is_empty() else "暂无该资产类别的详细说明。"
	return "暂无该资产类别的详细说明。"


## 从配置中查找负债类别描述
func _get_debt_description(category: String) -> String:
	if _config != null:
		for debt: DebtTemplateConfig in _config.debt_templates:
			if debt.category == category:
				return debt.description if not debt.description.is_empty() else "暂无该负债类别的详细说明。"
	return "暂无该负债类别的详细说明。"


## 从配置中查找居住地描述
func _get_residence_location_description(location: ApplicantData.ResidenceLocation) -> String:
	if _config != null:
		var idx: int = location as int
		if idx >= 0 and idx < _config.residence_location_descriptions.size():
			return _config.residence_location_descriptions[idx]
	return "暂无说明。"


## 从配置中查找居住类型描述
func _get_residence_type_description(res_type: ApplicantData.ResidenceType) -> String:
	if _config != null:
		var idx: int = res_type as int
		if idx >= 0 and idx < _config.residence_type_descriptions.size():
			return _config.residence_type_descriptions[idx]
	return "暂无说明。"


## 格式化货币显示
func _format_currency(amount: int) -> String:
	var negative: bool = amount < 0
	var abs_amount: int = absi(amount)
	var text: String = str(abs_amount)
	var result: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		result = text[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	if negative:
		result = "-" + result
	return result
